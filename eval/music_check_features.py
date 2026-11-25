"""Per-window measurements for the "check for music" evaluation (docs/MUSIC_CHECK.md), saved once per clip so the
decision rules can be tuned without running the engine again.

    python eval/music_check_features.py --set /srv/build/music/set --out /srv/build/music/feat [--jobs 4]

For each clip: the engine (voice_v1, the model that keeps every voice and removes instruments) gives the voice; the
residual is input minus voice. Per 1 s window every 0.5 s:
  lin, lres        input and residual level, dBFS
  tag_res, tag_mix AudioSet tagger (EfficientAT mn04, 527 classes) on the residual and on the input
  harm, tonal      approach A: harmonic share of the residual (median-filter HPSS) and peak persistence of its
                   harmonic part (sustained spectral peaks = melodic instruments)
  rhythm           approach A: periodicity of the residual's percussive onsets (autocorrelation at 60-200 BPM, 4 s)
"""
import argparse, json, os, subprocess, sys, tempfile
from concurrent.futures import ProcessPoolExecutor

import numpy as np
import soundfile as sf

SR = 48000
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DET = next(p for p in (os.path.join(ROOT, "models/detector"), "/srv/build/wt-recite/models/detector")
           if os.path.exists(os.path.join(p, "weights/mn04_as_mAP_432.pt")))
IMP = next(p for p in (os.path.join(ROOT, "build/im-process"), "/srv/projects/islamic_mute/build/im-process") if os.path.exists(p))
MODEL = next(p for p in (os.path.join(ROOT, "models/voice/v3/voice_v1_fp16.onnx"),
                         "/srv/projects/islamic_mute/models/voice/v3/voice_v1_fp16.onnx") if os.path.exists(p))
WIN, STEP = SR, SR // 2

_tag = None


def tagger():
    global _tag
    if _tag is None:
        import torch
        torch.set_num_threads(1)
        sys.path.insert(0, DET)
        from mobilenet import load_pretrained, MelFrontEnd
        _tag = (load_pretrained(os.path.join(DET, "weights/mn04_as_mAP_432.pt"), 0.4).eval(),
                MelFrontEnd(32000, 1024, 800, 320, center=True))
    return _tag


def tag(sig, starts):
    import torch, torchaudio.functional as AF
    m, mel = tagger()
    out = []
    for k in range(0, len(starts), 32):
        w = torch.from_numpy(np.stack([sig[i:i + WIN] for i in starts[k:k + 32]]).astype(np.float32))
        with torch.no_grad():
            out.append(torch.sigmoid(m(mel(AF.resample(w, SR, 32000)))).numpy())
    return np.concatenate(out).astype(np.float16)


def engine(x):
    with tempfile.TemporaryDirectory() as d:
        sf.write(d + "/i.wav", x, SR, subtype="FLOAT")
        p = subprocess.run([IMP, "-m", MODEL, d + "/i.wav", d + "/o.wav"], capture_output=True, text=True)
        if p.returncode:
            raise RuntimeError(p.stderr[-300:])
        y = sf.read(d + "/o.wav", dtype="float32")[0]
    return np.pad(y[: len(x)], (0, max(0, len(x) - len(y))))


def db(a):
    return 10 * np.log10(np.mean(np.asarray(a, np.float64) ** 2) + 1e-12)


def approach_a(r, starts):
    """Harmonic share, peak persistence and onset periodicity of the residual, per window."""
    from scipy.ndimage import median_filter
    from scipy.signal import stft
    n_fft, hop = 2048, 480                       # 23 Hz bins, 10 ms frames
    _, _, Z = stft(r, SR, nperseg=n_fft, noverlap=n_fft - hop, boundary=None, padded=False)
    S = np.abs(Z[: int(5000 / (SR / n_fft))])    # up to 5 kHz
    if S.shape[1] < 3:
        z = np.zeros(len(starts))
        return z, z, z
    H = median_filter(S, size=(1, 17))           # smooth in time: sustained
    P = median_filter(S, size=(17, 1))           # smooth in frequency: hits
    Hm, Pm = H ** 2 / (H ** 2 + P ** 2 + 1e-12), P ** 2 / (H ** 2 + P ** 2 + 1e-12)
    Sh, Sp = S * Hm, S * Pm
    # spectral peaks of the harmonic part: local maxima within 30 dB of the frame's maximum, from 80 Hz
    L = 20 * np.log10(Sh + 1e-9)
    lo = int(80 / (SR / n_fft))
    pk = np.zeros_like(L, dtype=bool)
    pk[lo + 1:-1] = (L[lo + 1:-1] > L[lo:-2]) & (L[lo + 1:-1] >= L[lo + 2:]) & (L[lo + 1:-1] > L.max(0) - 30)
    # a peak that stays (+-1 bin) for 20 frames (200 ms)
    near = pk | np.roll(pk, 1, 0) | np.roll(pk, -1, 0)
    run = np.zeros_like(pk, dtype=np.int32)
    for t in range(1, pk.shape[1]):
        run[:, t] = np.where(near[:, t], run[:, t - 1] + 1, 0)
    sustained = (run >= 20) & pk
    flux = np.maximum(0, np.diff(np.log1p(Sp * 100), axis=1)).sum(0)
    flux = np.concatenate([[0], flux])
    harm, tonal, rhythm = [], [], []
    for i in starts:
        a, b = i // hop, (i + WIN) // hop
        e_h, e_p = (Sh[:, a:b] ** 2).sum(), (Sp[:, a:b] ** 2).sum()
        harm.append(e_h / (e_h + e_p + 1e-12))
        npk = pk[:, a:b].sum()
        tonal.append(sustained[:, a:b].sum() / npk if npk else 0.0)
        c = (a + b) // 2
        f = flux[max(0, c - 200): c + 200]
        if len(f) < 200 or f.std() < 1e-6:
            rhythm.append(0.0)
            continue
        f = (f - f.mean()) / f.std()
        ac = np.correlate(f, f, "full")[len(f) - 1:] / len(f)
        rhythm.append(float(ac[30:101].max()))     # lags 0.3-1.0 s = 200-60 BPM
    return np.array(harm), np.array(tonal), np.array(rhythm)


def one(args):
    path, out = args
    if os.path.exists(out):
        return out
    x = sf.read(path, dtype="float32")[0]
    y = engine(x)
    r = x - y
    starts = list(range(0, max(1, len(x) - WIN + 1), STEP))
    if len(x) < WIN:
        x, r = np.pad(x, (0, WIN - len(x))), np.pad(r, (0, WIN - len(r)))
    lin = np.array([db(x[i:i + WIN]) for i in starts])
    lres = np.array([db(r[i:i + WIN]) for i in starts])
    harm, tonal, rhythm = approach_a(r, starts)
    np.savez_compressed(out, t=np.array(starts) / SR, lin=lin, lres=lres, tag_res=tag(r, starts), tag_mix=tag(x, starts),
                        harm=harm, tonal=tonal, rhythm=rhythm)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--set", default="/srv/build/music/set")
    ap.add_argument("--out", default="/srv/build/music/feat")
    ap.add_argument("--jobs", type=int, default=4)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    rows = [json.loads(l) for l in open(os.path.join(a.set, "manifest.jsonl"))]
    rows = list({r["id"]: r for r in rows}.values())
    jobs = [(os.path.join(a.set, "clips", r["id"] + ".flac"), os.path.join(a.out, r["id"] + ".npz")) for r in rows]
    jobs = [j for j in jobs if os.path.exists(j[0]) and not os.path.exists(j[1])]
    print(f"{len(jobs)} clips to measure (model {os.path.basename(MODEL)})", flush=True)
    with ProcessPoolExecutor(a.jobs) as ex:
        for k, _ in enumerate(ex.map(one, jobs, chunksize=4)):
            if k % 50 == 0:
                print(f"  {k}/{len(jobs)}", flush=True)
    print("done", flush=True)


if __name__ == "__main__":
    main()
