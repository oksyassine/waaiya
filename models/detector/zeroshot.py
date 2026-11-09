"""Zero-shot check: how well does an AudioSet-pretrained tagger separate women's singing from men's
singing, speech and recitation on short windows?  Usage: zeroshot.py mn04|mn10 [win_s ...]"""
import json, os, sys
import numpy as np, soundfile as sf, torch, torchaudio.functional

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from mobilenet import load_pretrained, MelFrontEnd  # noqa: E402


def resample(x, up, down):
    return torchaudio.functional.resample(torch.from_numpy(np.ascontiguousarray(x, dtype=np.float32)), down, up).numpy()


W = {"mn04": ("mn04_as_mAP_432.pt", 0.4), "mn10": ("mn10_as_mAP_471.pt", 1.0)}
SPEECH, MSP, FSP, SING, CHOIR, MSING, FSING, CSING = 0, 1, 2, 27, 28, 32, 33, 34


def auc(pos, neg):
    pos, neg = np.asarray(pos), np.asarray(neg)
    if not len(pos) or not len(neg):
        return float("nan")
    r = np.argsort(np.argsort(np.concatenate([pos, neg]))) + 1
    return (r[: len(pos)].sum() - len(pos) * (len(pos) + 1) / 2) / (len(pos) * len(neg))


def windows(x, win, hop_s=0.5, sr=32000):
    n, hop = int(win * sr), int(hop_s * sr)
    segs = [x[i:i + n] for i in range(0, max(1, len(x) - n + 1), hop)]
    return [s for s in segs if len(s) == n and np.sqrt(np.mean(s ** 2)) > 1e-3]


def main():
    name = sys.argv[1]
    wins = [float(a) for a in sys.argv[2:]] or [0.5, 1.0, 2.0]
    f, w = W[name]
    sr = int(os.environ.get("ZS_SR", "48000"))
    m = load_pretrained(os.path.join(HERE, "weights", f), w)
    mel = MelFrontEnd() if sr == 48000 else MelFrontEnd(32000, 1024, 800, 320, center=True)
    global SR_RUN
    SR_RUN = sr
    lab = json.load(open(os.path.join(HERE, "evalset", "labels.json")))
    for win in wins:
        rows = []
        for k, v in lab.items():
            x, sr = sf.read(os.path.join(HERE, "evalset", k + ".flac"), dtype="float32")
            segs = windows(resample(x, SR_RUN, sr).astype(np.float32), win, sr=SR_RUN)
            if not segs:
                continue
            with torch.no_grad():
                p = torch.sigmoid(m(mel(torch.from_numpy(np.stack(segs))))).numpy()
            rows += [(v["style"], v["gender"], q) for q in p]
        cls = lambda st, g: [r[2] for r in rows if r[0] == st and r[1] == g]  # noqa: E731
        fs, ms = cls("singing", "F"), cls("singing", "M")
        sp = cls("speech", "F") + cls("speech", "M")
        rec = cls("recitation", "M")
        sc = lambda qs, fn: [fn(q) for q in qs]  # noqa: E731
        f1 = lambda q: q[FSING]  # noqa: E731
        f2 = lambda q: q[FSING] / (q[FSING] + q[MSING] + 1e-6) * max(q[SING], q[FSING], q[MSING])  # noqa: E731
        print(f"\n{name} window {win}s: windows FS={len(fs)} MS={len(ms)} speech={len(sp)} recitation={len(rec)}")
        for nm, fn in (("P(female singing)", f1), ("gender-ratio*singing", f2)):
            print(f"  {nm:22s} AUC FS-vs-MS {auc(sc(fs, fn), sc(ms, fn)):.3f} | FS-vs-speech "
                  f"{auc(sc(fs, fn), sc(sp, fn)):.3f} | FS-vs-recitation {auc(sc(fs, fn), sc(rec, fn)):.3f} | "
                  f"FS-vs-all {auc(sc(fs, fn), sc(ms + sp + rec, fn)):.3f}")
        for thr in (0.1, 0.2, 0.3, 0.5):
            tp = np.mean(np.array(sc(fs, f1)) > thr)
            fp = {nm: np.mean(np.array(sc(g, f1)) > thr) for nm, g in (("MS", ms), ("speech", sp), ("rec", rec)) if g}
            print(f"  thr {thr}: female singing caught {tp:.0%}; false mutes " +
                  ", ".join(f"{a} {b:.0%}" for a, b in fp.items()))
        sing = lambda q: max(q[SING], q[FSING], q[MSING])  # noqa: E731
        print(f"  singing-vs-speech AUC {auc(sc(fs + ms, sing), sc(sp, sing)):.3f}, "
              f"singing-vs-recitation AUC {auc(sc(fs + ms, sing), sc(rec, sing)):.3f}")


if __name__ == "__main__":
    main()
