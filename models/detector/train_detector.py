"""Fine-tune the women's-singing detector: EfficientAT mn04 (AudioSet-pretrained, MIT) + a small head.

Outputs per 1 s window of the *separated voice*: P(a female voice is present), and P(style) over
{speech, singing, recitation}.  The app mutes when P(female) * P(singing) stays above a threshold
(chosen here on held-out singers for a target catch rate).

python train_detector.py --data /kaggle/tmp/det --init weights/mn04_as_mAP_432.pt --out out --minutes 60
"""
import argparse, glob, json, math, os, random, sys, time

import numpy as np
import soundfile as sf
import torch
import torch.nn as nn
import torch.nn.functional as F

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from mobilenet import MN, MelFrontEnd, WINDOW_SAMPLES, SR, N_FFT, WIN, HOP, N_MELS, FRAMES  # noqa: E402

STYLES = ["speech", "singing", "recitation"]
OUT_NAMES = ["female", "speech", "singing", "recitation"]


# ----------------------------------------------------------------------------- data
class Pool:
    def __init__(self, files):
        self.files = files
        self.frames = [sf.info(f).frames for f in files]

    def __len__(self):
        return len(self.files)

    def crop(self, rng, n):
        for _ in range(10):
            i = rng.randrange(len(self.files))
            if self.frames[i] >= n:
                o = rng.randrange(self.frames[i] - n + 1)
                x, _ = sf.read(self.files[i], start=o, frames=n, dtype="float32", always_2d=True)
                x = x.mean(1)
                if np.sqrt(np.mean(x ** 2)) > 1e-3:
                    return x
        x, _ = sf.read(self.files[rng.randrange(len(self.files))], dtype="float32", always_2d=True)
        x = np.resize(x.mean(1), n)
        return x


def pools(root):
    out = {}
    for d in glob.glob(os.path.join(root, "*_*")):
        style, g = os.path.basename(d).split("_")
        fs = sorted(glob.glob(d + "/*.wav"))
        if fs and style in STYLES:
            out[(style, g)] = Pool(fs)
    return out


def rms(x):
    return np.sqrt(np.mean(x ** 2) + 1e-12)


def lowpass(x, rng):
    X = np.fft.rfft(x)
    fc = rng.uniform(4000, 14000)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    X *= 1 / (1 + (f / fc) ** 8)
    return np.fft.irfft(X, len(x)).astype(np.float32)


def reverb(x, rng):
    t60 = rng.uniform(0.2, 1.2)
    n = int(t60 * SR)
    ir = rng_noise(rng, n) * np.exp(-6.9 * np.arange(n) / n)
    ir[0] = 1.0
    y = np.fft.irfft(np.fft.rfft(x, len(x) + n) * np.fft.rfft(ir, len(x) + n))[: len(x)]
    return (y / (rms(y) + 1e-9) * rms(x)).astype(np.float32)


def rng_noise(rng, n):
    return np.random.default_rng(rng.randrange(1 << 30)).standard_normal(n).astype(np.float32)


class Batches(torch.utils.data.IterableDataset):
    """Random 1 s examples with labels (female, style)."""

    def __init__(self, root, music_dir, seed, mix_p=0.25):
        self.root, self.music_dir, self.seed, self.mix_p = root, music_dir, seed, mix_p

    def __iter__(self):
        wi = torch.utils.data.get_worker_info()
        rng = random.Random(self.seed + (wi.id if wi else 0) * 7919)
        P = pools(self.root)
        music = Pool(sorted(glob.glob(self.music_dir + "/*.wav"))) if self.music_dir else None
        n = WINDOW_SAMPLES
        style_p = {"speech": 0.35, "singing": 0.45, "recitation": 0.20}
        styles = [s for s in STYLES if any(k[0] == s for k in P)]
        while True:
            style = rng.choices(styles, [style_p[s] for s in styles])[0]
            gs = [g for g in "FM" if (style, g) in P]
            g = rng.choice(gs)
            x = P[(style, g)].crop(rng, n)
            x = x / (rms(x) + 1e-9) * 0.1
            female = g == "F"
            if rng.random() < self.mix_p:  # a second voice: duets, backing vocals, overlapping speech
                g2 = rng.choice([h for h in "FM" if (style, h) in P])
                y = P[(style, g2)].crop(rng, n)
                y = y / (rms(y) + 1e-9) * 0.1 * 10 ** (rng.uniform(-12, 0) / 20)
                x = x + y
                female = female or g2 == "F"
            if rng.random() < 0.3:
                x = lowpass(x, rng)
            if rng.random() < 0.25:
                x = reverb(x, rng)
            if music is not None and rng.random() < 0.7:  # imperfect separation leaves some instruments
                m = music.crop(rng, n)
                x = x + m / (rms(m) + 1e-9) * rms(x) * 10 ** (-rng.uniform(10, 35) / 20)
            if rng.random() < 0.1:
                x = x + rng_noise(rng, n) * rms(x) * 10 ** (-rng.uniform(25, 50) / 20)
            x = x * 10 ** (rng.uniform(-35, 0) / 20) / (np.max(np.abs(x)) + 1e-9)
            if rng.random() < 0.2:  # voice onset after silence: the streaming window is partly empty
                x[: int(rng.uniform(0, 0.75) * n)] = 0.0
            yield torch.from_numpy(x.astype(np.float32)), torch.tensor(float(female)), torch.tensor(STYLES.index(style))


def fixed_set(root, per_class, seed=1):
    """Deterministic validation windows: (audio, female, style, group)."""
    rng = random.Random(seed)
    xs, fe, st, grp = [], [], [], []
    for (style, g), pool in sorted(pools(root).items()):
        for _ in range(per_class):
            x = pool.crop(rng, WINDOW_SAMPLES)
            xs.append(x / (np.max(np.abs(x)) + 1e-9) * 0.5)
            fe.append(float(g == "F"))
            st.append(STYLES.index(style))
            grp.append(f"{style}_{g}")
    return torch.from_numpy(np.stack(xs)), torch.tensor(fe), torch.tensor(st), grp


# ----------------------------------------------------------------------------- model
class Detector(nn.Module):
    """power spectrogram (B, 769, 100) -> (B, 4) probabilities [female, speech, singing, recitation]."""

    def __init__(self, width=0.4):
        super().__init__()
        self.front = MelFrontEnd()
        self.net = MN(width)
        c = self.net.classifier[2].in_features
        self.head = nn.Sequential(nn.Linear(c, 128), nn.Hardswish(), nn.Dropout(0.2), nn.Linear(128, 4))

    def logits_from_power(self, power):
        mel = (torch.log(self.front.fb @ power + 1e-5) + 4.5) / 5.0
        e = self.net.features(mel.unsqueeze(1)).mean((2, 3))
        return self.head(e)

    def power(self, audio):
        x = audio[:, 1:] - 0.97 * audio[:, :-1]
        X = torch.stft(x, N_FFT, HOP, N_FFT, self.front.window, center=False, return_complex=True)
        return X.real ** 2 + X.imag ** 2

    def forward(self, audio):
        return self.logits_from_power(self.power(audio))


class Exported(nn.Module):
    def __init__(self, det):
        super().__init__()
        self.det = det

    def forward(self, power):
        z = self.det.logits_from_power(power)
        return torch.cat([torch.sigmoid(z[:, :1]), torch.softmax(z[:, 1:], 1)], 1)


def auc(pos, neg):
    pos, neg = np.asarray(pos), np.asarray(neg)
    if not len(pos) or not len(neg):
        return float("nan")
    r = np.argsort(np.argsort(np.concatenate([pos, neg]))) + 1
    return float((r[: len(pos)].sum() - len(pos) * (len(pos) + 1) / 2) / (len(pos) * len(neg)))


@torch.no_grad()
def evaluate(model, vs, dev, target_catch=0.95):
    model.eval()
    x, fe, st, grp = vs
    probs = torch.cat([Exported(model)(model.power(x[i:i + 128].to(dev))).cpu() for i in range(0, len(x), 128)])
    model.train()
    score = (probs[:, 0] * probs[:, 2]).numpy()  # P(female) * P(singing)
    grp = np.array(grp)
    fs = score[grp == "singing_F"]
    neg = score[grp != "singing_F"]
    res = {"auc_female_singing_vs_rest": auc(fs, neg),
           "auc_female_vs_male_singing": auc(fs, score[grp == "singing_M"]),
           "gender_acc": float(((probs[:, 0] > 0.5).float() == fe).float().mean()),
           "style_acc": float((probs[:, 1:].argmax(1) == st).float().mean())}
    if len(fs):
        thr = float(np.quantile(fs, 1 - target_catch))
        res["threshold"] = thr
        res["false_mute_rate_by_group"] = {g: float(np.mean(score[grp == g] >= thr)) for g in sorted(set(grp)) if g != "singing_F"}
        res["catch_at_threshold"] = float(np.mean(fs >= thr))
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True)
    ap.add_argument("--init", default=os.path.join(HERE, "weights", "mn04_as_mAP_432.pt"))
    ap.add_argument("--out", required=True)
    ap.add_argument("--minutes", type=float, default=60)
    ap.add_argument("--steps", type=int, default=100000)
    ap.add_argument("--batch", type=int, default=64)
    ap.add_argument("--lr", type=float, default=5e-4)
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--val-per-class", type=int, default=200)
    ap.add_argument("--eval-every", type=int, default=1000)
    ap.add_argument("--target-catch", type=float, default=0.95)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    dev = "cuda" if torch.cuda.is_available() else "cpu"
    torch.manual_seed(0)
    model = Detector()
    sd = torch.load(a.init, map_location="cpu", weights_only=True)
    missing, _ = model.net.load_state_dict(sd, strict=False)
    assert not [k for k in missing if "num_batches" not in k], missing
    model.to(dev).train()
    vs = fixed_set(os.path.join(a.data, "val"), a.val_per_class)
    ext = fixed_set(os.path.join(a.data, "ext"), a.val_per_class) if glob.glob(os.path.join(a.data, "ext", "*_*")) else None
    music = os.path.join(a.data, "music")
    dl = torch.utils.data.DataLoader(Batches(os.path.join(a.data, "train"), music if os.path.isdir(music) else None, 0),
                                     batch_size=a.batch, num_workers=a.workers, persistent_workers=a.workers > 0)
    opt = torch.optim.AdamW([{"params": model.net.parameters(), "lr": a.lr * 0.3},
                             {"params": model.head.parameters(), "lr": a.lr}], weight_decay=1e-4)
    base = [g["lr"] for g in opt.param_groups]
    t0, best, log = time.time(), -1.0, []
    for step, (x, fe, st) in enumerate(dl):
        frac = min(1.0, max(step / a.steps, (time.time() - t0) / (a.minutes * 60)))
        if frac >= 1.0:
            break
        warm = min(1.0, step / 300)
        for g, b in zip(opt.param_groups, base):
            g["lr"] = b * warm * (0.05 + 0.95 * 0.5 * (1 + math.cos(math.pi * frac)))
        z = model(x.to(dev))
        loss = F.binary_cross_entropy_with_logits(z[:, 0], fe.to(dev)) + F.cross_entropy(z[:, 1:], st.to(dev))
        opt.zero_grad(set_to_none=True)
        loss.backward()
        nn.utils.clip_grad_norm_(model.parameters(), 5.0)
        opt.step()
        if step % 100 == 0:
            print(f"step {step} loss {loss.item():.4f} {(time.time() - t0) / 60:.1f} min", flush=True)
        if step and step % a.eval_every == 0:
            r = evaluate(model, vs, dev, a.target_catch)
            r["step"] = step
            log.append(r)
            print(json.dumps(r), flush=True)
            if r["auc_female_singing_vs_rest"] > best:
                best = r["auc_female_singing_vs_rest"]
                torch.save(model.state_dict(), os.path.join(a.out, "best.pt"))
    torch.save(model.state_dict(), os.path.join(a.out, "last.pt"))
    if os.path.exists(os.path.join(a.out, "best.pt")):
        model.load_state_dict(torch.load(os.path.join(a.out, "best.pt"), map_location=dev, weights_only=True))
    final = {"val": evaluate(model, vs, dev, a.target_catch)}
    if ext:
        final["ext_opensinger"] = evaluate(model, ext, dev, a.target_catch)
        thr = final["val"].get("threshold")
        if thr is not None:  # how the val-chosen threshold transfers to unseen singers/language
            x, fe, st, grp = ext
            model.eval()
            with torch.no_grad():
                p = torch.cat([Exported(model)(model.power(x[i:i + 128].to(dev))).cpu() for i in range(0, len(x), 128)])
            s = (p[:, 0] * p[:, 2]).numpy()
            grp = np.array(grp)
            final["ext_opensinger"]["at_val_threshold"] = {
                "catch_female_singing": float(np.mean(s[grp == "singing_F"] >= thr)),
                "false_mute_male_singing": float(np.mean(s[grp == "singing_M"] >= thr))}
    final["train_log"] = log
    json.dump(final, open(os.path.join(a.out, "detector_eval.json"), "w"), indent=1)
    print(json.dumps({k: v for k, v in final.items() if k != "train_log"}, indent=1))
    export(model.cpu(), os.path.join(a.out, "detector_v1.onnx"), final["val"].get("threshold", 0.5))


def export(model, path, threshold):
    import onnx
    model.eval()
    ex = Exported(model).eval()
    power = torch.rand(1, N_FFT // 2 + 1, FRAMES)
    torch.onnx.export(ex, (power,), path, input_names=["power"], output_names=["probs"], opset_version=17,
                      dynamic_axes=None)
    m = onnx.load(path)
    meta = {"im.detector": "1", "im.det_sample_rate": str(SR), "im.det_n_fft": str(N_FFT), "im.det_win": str(WIN),
            "im.det_hop": str(HOP), "im.det_frames": str(FRAMES), "im.det_mels": str(N_MELS), "im.det_preemph": "0.97",
            "im.det_window": "hann_symmetric_centered", "im.det_outputs": ",".join(OUT_NAMES),
            "im.det_threshold": f"{threshold:.4f}", "im.det_eval_every_hops": "25", "im.det_release_s": "2.0",
            "im.model_name": "detector_v1 (EfficientAT mn04 fine-tuned)",
            "im.licence": "MIT (EfficientAT weights); trained on CC BY 4.0 data (LibriSpeech, FLEURS, VocalSet) + Quran recitations"}
    for k, v in meta.items():
        e = m.metadata_props.add()
        e.key, e.value = k, v
    onnx.save(m, path)
    print("exported", path, os.path.getsize(path) // 1024, "KB")
    try:
        import onnxruntime as ort
        sess = ort.InferenceSession(path, providers=["CPUExecutionProvider"])
        p = torch.rand(4, 1, N_FFT // 2 + 1, FRAMES) * 10 ** torch.empty(4, 1, 1, 1).uniform_(-6, 1)
        err = max(float(np.max(np.abs(sess.run(None, {"power": q.numpy()})[0] - ex(q).detach().numpy()))) for q in p)
        print(f"ONNX Runtime vs PyTorch max abs diff {err:.2e}")
        assert err < 1e-4, err
    except ImportError:
        pass


if __name__ == "__main__":
    main()
