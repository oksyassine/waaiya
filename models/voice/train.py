"""Fine-tune DeepFilterNet3 so that ALL voice is kept (speech, Quran recitation, singing/nasheed)
and only musical instruments are removed.

Data: folders of audio files (wav/flac/mp3, any rate; resampled to 48 kHz on load).
  --voice DIR[:weight]   clean voice: speech, recitation, singing (target = this signal)
  --music DIR[:weight]   instrumental music / instrument stems (removed)
  --synth-music P        share of music examples generated on the fly by testset/build_testset.synth_music
Mixtures are made on the fly: random crop, random gain, music-to-voice ratio in [mvr_min, mvr_max] dB,
plus voice-only (keep everything) and music-only (output silence) examples.

Runs on GPU (Kaggle/Colab T4 is enough) or CPU for smoke tests:
  python models/voice/train.py --voice data/voice --music data/music --steps 20000 --out runs/v1
Export the result with:  python models/dfn3/export_stream.py --checkpoint runs/v1/last.pt --out voice_v1.onnx
"""
import argparse, glob, math, os, random, subprocess, sys, time

import numpy as np
import soundfile as sf
import torch
import torch.nn.functional as F

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "models", "dfn3"))
sys.path.insert(0, os.path.join(ROOT, "testset"))
import df_compat  # noqa: E402,F401  (newer torchaudio)
from export_stream import norm_alpha  # noqa: E402

SR = 48000
AUDIO_EXT = (".wav", ".flac", ".mp3", ".ogg", ".m4a", ".opus")


# ---------------------------------------------------------------- data
def list_audio(spec):
    path, _, w = spec.partition(":")
    files = [f for f in glob.glob(os.path.join(path, "**", "*"), recursive=True) if f.lower().endswith(AUDIO_EXT)]
    return files, float(w or 1.0)


def load_48k_mono(path):
    if path.lower().endswith((".wav", ".flac", ".ogg")):
        x, sr = sf.read(path, dtype="float32", always_2d=True)
        x = x.mean(1)
        if sr != SR:
            x = torch.from_numpy(x)
            import torchaudio
            x = torchaudio.functional.resample(x, sr, SR).numpy()
        return x
    out = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"],
                         check=True, capture_output=True).stdout
    return np.frombuffer(out, np.float32).copy()


class Pool:
    """Weighted file pool. 48 kHz wav/flac files are read partially (fast); other files are
    decoded fully and cached (prepare data with kaggle/prepare_data.py to avoid that)."""

    def __init__(self, specs, cache=64):
        self.groups = [list_audio(s) for s in specs]
        self.groups = [(f, w) for f, w in self.groups if f]
        self.cache, self.max = {}, cache
        self.info = {}

    def __bool__(self):
        return bool(self.groups)

    def sample(self, n, rng):
        files, _ = rng.choices(self.groups, weights=[w for _, w in self.groups])[0]
        f = rng.choice(files)
        if f.lower().endswith((".wav", ".flac")):
            if f not in self.info:
                i = sf.info(f)
                self.info[f] = (i.frames, i.samplerate)
            frames, sr = self.info[f]
            if sr == SR and frames >= n:
                s = rng.randint(0, frames - n)
                x, _ = sf.read(f, start=s, frames=n, dtype="float32", always_2d=True)
                return x.mean(1)
        if f not in self.cache:
            if len(self.cache) >= self.max:
                self.cache.pop(next(iter(self.cache)))
            self.cache[f] = load_48k_mono(f)
        x = self.cache[f]
        if len(x) < n:
            x = np.tile(x, int(math.ceil(n / max(len(x), 1))) + 1)
        s = rng.randint(0, len(x) - n)
        return x[s:s + n]


def rms(x):
    return float(np.sqrt(np.mean(x ** 2) + 1e-10))


def make_batch(voice, music, args, rng):
    n = int(args.seconds * SR)
    xs, ys = [], []
    for _ in range(args.batch):
        r = rng.random()
        v = voice.sample(n, rng) if r > args.p_music_only else np.zeros(n, np.float32)
        if r > 1 - args.p_voice_only:
            m = np.zeros(n, np.float32)
        else:
            if music and rng.random() > args.synth_music:
                m = music.sample(n, rng)
            else:
                from build_testset import synth_music
                m = synth_music(args.seconds, rng.randint(0, 10 ** 9), lead=rng.random() < 0.6).mean(1)[:n]
            if v.any():
                m = m / rms(m) * rms(v) * 10 ** (rng.uniform(args.mvr_min, args.mvr_max) / 20)
        mix = v + m
        g = 10 ** (rng.uniform(-30, -6) / 20) / (np.max(np.abs(mix)) + 1e-6)  # random level, never clipping
        xs.append(mix * g)
        ys.append(v * g)
    return torch.from_numpy(np.stack(xs)).float(), torch.from_numpy(np.stack(ys)).float()


class Batches(torch.utils.data.IterableDataset):
    """Endless stream of (mixture, voice) batches, built in DataLoader worker processes."""

    def __init__(self, args):
        self.args = args

    def __iter__(self):
        info = torch.utils.data.get_worker_info()
        wid = info.id if info else 0
        rng = random.Random(self.args.seed * 1000 + wid + int(time.time()))
        voice, music = Pool(self.args.voice), Pool(self.args.music)
        while True:
            yield make_batch(voice, music, self.args, rng)


# ---------------------------------------------------------------- DFN front end (batched, matches libDF / the streaming export)
class FrontEnd(torch.nn.Module):
    def __init__(self, df_state, nb_df, device):
        super().__init__()
        self.hop, self.n_fft = df_state.hop_size(), df_state.fft_size()
        self.nb_df = nb_df
        self.alpha = norm_alpha(SR, self.hop, 1.0)
        n = torch.arange(self.n_fft, dtype=torch.float64)
        self.win = torch.sin(0.5 * math.pi * torch.sin(math.pi * (n + 0.5) / self.n_fft) ** 2).float().to(device)
        self.wnorm = 1.0 / (self.n_fft ** 2 / (2 * self.hop))
        widths = df_state.erb_widths()
        nf = self.n_fft // 2 + 1
        fb = torch.zeros(nf, len(widths))
        s = 0
        for i, w in enumerate(widths.tolist()):
            fb[s:s + w, i] = 1.0 / w
            s += w
        self.erb_fb = fb.to(device)
        self.erb_init = torch.linspace(-60.0, -90.0, len(widths), device=device)
        self.unit_init = torch.linspace(0.001, 0.0001, nb_df, device=device)

    def stft(self, x):  # x [B, T] -> complex [B, frames, F]; frame k = samples [(k-1)hop, (k+1)hop)
        x = F.pad(x, (self.hop, 0))
        fr = x.unfold(-1, self.n_fft, self.hop) * self.win
        return torch.fft.rfft(fr, dim=-1) * self.wnorm

    def istft(self, spec, length):
        fr = torch.fft.irfft(spec, n=self.n_fft, dim=-1) * self.n_fft * self.win  # unnormalised inverse like libDF
        b, t, _ = fr.shape
        out = F.fold(fr.transpose(1, 2), output_size=(1, (t + 1) * self.hop), kernel_size=(1, self.n_fft),
                     stride=(1, self.hop)).reshape(b, -1)
        return out[:, self.hop:self.hop + length]

    def features(self, spec):
        a = self.alpha
        erb = 10 * torch.log10((spec.abs() ** 2) @ self.erb_fb + 1e-10)  # [B,T,E]
        mag = spec[..., : self.nb_df].abs()
        st_e = self.erb_init.expand(spec.shape[0], -1)
        st_u = self.unit_init.expand(spec.shape[0], -1)
        fe, fu = [], []
        for t in range(spec.shape[1]):
            st_e = erb[:, t] * (1 - a) + st_e * a
            st_u = mag[:, t] * (1 - a) + st_u * a
            fe.append((erb[:, t] - st_e) / 40.0)
            fu.append(spec[:, t, : self.nb_df] / torch.sqrt(st_u))
        feat_erb = torch.stack(fe, 1).unsqueeze(1)  # [B,1,T,E]
        feat_spec = torch.view_as_real(torch.stack(fu, 1)).unsqueeze(1)  # [B,1,T,F',2]
        return feat_erb, feat_spec


# ---------------------------------------------------------------- losses (DeepFilterNet-style)
def spec_loss(est, ref, gamma=0.3):
    em, rm = est.abs().clamp_min(1e-12), ref.abs().clamp_min(1e-12)
    l_mag = F.mse_loss(em ** gamma, rm ** gamma)
    ec = em ** gamma * est / em
    rc = rm ** gamma * ref / rm
    l_cpx = F.mse_loss(torch.view_as_real(ec), torch.view_as_real(rc))
    return l_mag + l_cpx


def multires_loss(est_wav, ref_wav, ffts=(256, 512, 1024, 2048)):
    loss = 0.0
    for n in ffts:
        w = torch.hann_window(n, device=est_wav.device)
        e = torch.stft(est_wav, n, n // 4, window=w, return_complex=True)
        r = torch.stft(ref_wav, n, n // 4, window=w, return_complex=True)
        loss = loss + spec_loss(e, r)
    return loss / len(ffts)


# ---------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--voice", action="append", default=[])
    ap.add_argument("--music", action="append", default=[])
    ap.add_argument("--synth-music", type=float, default=0.3)
    ap.add_argument("--steps", type=int, default=20000)
    ap.add_argument("--batch", type=int, default=16)
    ap.add_argument("--seconds", type=float, default=3.0)
    ap.add_argument("--lr", type=float, default=5e-5)
    ap.add_argument("--mvr-min", type=float, default=-15.0)
    ap.add_argument("--mvr-max", type=float, default=10.0)
    ap.add_argument("--p-voice-only", type=float, default=0.1)
    ap.add_argument("--p-music-only", type=float, default=0.1)
    ap.add_argument("--out", default="runs/voice")
    ap.add_argument("--resume", default="")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--log-every", type=int, default=50)
    ap.add_argument("--save-every", type=int, default=1000)
    ap.add_argument("--hours", type=float, default=0, help="stop and save after this much wall time (0 = no limit)")
    ap.add_argument("--workers", type=int, default=4)
    args = ap.parse_args()

    from df.enhance import init_df
    device = "cuda" if torch.cuda.is_available() else "cpu"
    model, df_state, _ = init_df(log_level="ERROR")  # pretrained DeepFilterNet3 = starting point
    model = model.to(device).train()

    def freeze_bn():  # keep pretrained BatchNorm statistics; small fine-tuning batches would corrupt them
        for m in model.modules():
            if isinstance(m, torch.nn.modules.batchnorm._BatchNorm):
                m.eval()

    freeze_bn()
    if args.resume:
        model.load_state_dict(torch.load(args.resume, map_location=device)["model"])
    fe = FrontEnd(df_state, model.nb_df, device)
    if not Pool(args.voice):
        sys.exit("no voice files found (--voice DIR)")
    loader = iter(torch.utils.data.DataLoader(Batches(args), batch_size=None, num_workers=args.workers,
                                              prefetch_factor=4 if args.workers else None,
                                              persistent_workers=bool(args.workers)))
    opt = torch.optim.AdamW(model.parameters(), lr=args.lr, weight_decay=1e-4)

    def lr_at(step, elapsed):
        """Warmup, then cosine decay over whichever ends first: the step budget or the time budget."""
        frac = step / args.steps
        if args.hours:
            frac = max(frac, elapsed / (args.hours * 3600))
        frac = min(frac, 1.0)
        warm = min(1.0, step / max(1, min(500, args.steps // 20)))
        return args.lr * warm * (0.05 + 0.95 * 0.5 * (1 + math.cos(math.pi * frac)))
    os.makedirs(args.out, exist_ok=True)
    t0, run = time.time(), 0.0
    for step in range(1, args.steps + 1):
        x, y = next(loader)
        x, y = x.to(device, non_blocking=True), y.to(device, non_blocking=True)
        X, Y = fe.stft(x), fe.stft(y)
        feat_erb, feat_spec = fe.features(X)
        out = model(torch.view_as_real(X).unsqueeze(1), feat_erb, feat_spec)[0]
        E = torch.view_as_complex(out.squeeze(1).contiguous())
        e_wav = fe.istft(E, y.shape[-1])
        loss = spec_loss(E, Y) * 1000 + multires_loss(e_wav, y) * 500
        opt.zero_grad(set_to_none=True)
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
        lr = lr_at(step, time.time() - t0)
        for g in opt.param_groups:
            g["lr"] = lr
        opt.step()
        run = 0.98 * run + 0.02 * loss.item() if step > 1 else loss.item()
        if step % args.log_every == 0 or step == 1:
            print(f"step {step}/{args.steps} loss {run:.4f} lr {lr:.2e} {time.time()-t0:.0f}s", flush=True)
        out_of_time = args.hours and time.time() - t0 > args.hours * 3600
        if step % args.save_every == 0 or step == args.steps or out_of_time:
            torch.save({"model": model.state_dict(), "step": step, "args": vars(args)}, os.path.join(args.out, "last.pt"))
        if out_of_time:
            print(f"time budget reached at step {step}", flush=True)
            break
    print("done:", os.path.join(args.out, "last.pt"))


if __name__ == "__main__":
    main()
