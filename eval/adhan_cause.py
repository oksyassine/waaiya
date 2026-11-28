"""Why the default filter (dfn3) mutes adhan: one factor at a time on dry studio recitation, and a level sweep on
muted adhan clips. Kept = output - input level (dB) over the loud 1 s windows, as in adhan_filter.py.

    python eval/adhan_cause.py --out /srv/build/music/adhan/cause.jsonl [--jobs 2]
"""
import argparse, json, os, sys
from concurrent.futures import ProcessPoolExecutor

import numpy as np
import soundfile as sf
from scipy.signal import butter, sosfilt

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from adhan_filter import SR, run, measure, db  # noqa: E402

SET = "/srv/build/music/set2"


def level(x, target):
    return x * 10 ** ((target - db(x)) / 20)


def reverb(x, rt60, wet_db, seed=0):
    """wet_db: echo level relative to the direct voice (DRR = -wet_db). Far from a minaret, the echo dominates."""
    rng = np.random.default_rng(seed)
    n = int(rt60 * SR)
    t = np.arange(n) / SR
    ir = rng.standard_normal(n) * np.exp(-6.9 * t / rt60)
    ir[: int(0.01 * SR)] *= np.linspace(0, 1, int(0.01 * SR))
    wet = np.convolve(x, ir)[: len(x)]
    y = x + level(wet, db(x) + wet_db)
    return level(y, db(x)).astype(np.float32)


def speaker(x, lo=300, hi=3400, drive=0.0):
    """A loudspeaker horn: band-limited, optionally overdriven."""
    y = sosfilt(butter(4, [lo, hi], btype="band", fs=SR, output="sos"), x)
    if drive:
        g = 10 ** (drive / 20)
        y = np.tanh(y * g) / g
    return level(y, db(x)).astype(np.float32)


def noise(x, snr, seed=0):
    rng = np.random.default_rng(seed)
    n = sosfilt(butter(2, 2000, fs=SR, output="sos"), rng.standard_normal(len(x)))
    return (x + level(n, db(x) - snr)).astype(np.float32)


VARIANTS = {
    "dry": lambda x: x,
    "hall_wet-5": lambda x: reverb(x, 2.5, -5),
    "far_wet+0": lambda x: reverb(x, 2.5, 0),
    "far_wet+6": lambda x: reverb(x, 2.5, 6),
    "far_wet+12": lambda x: reverb(x, 2.5, 12),
    "speaker": lambda x: speaker(x),
    "speaker_drive12": lambda x: speaker(x, drive=12),
    "speaker_far+6": lambda x: reverb(speaker(x, drive=6), 2.5, 6),
    "noise_snr10": lambda x: noise(x, 10),
    "speaker_far+6_noise10": lambda x: noise(reverb(speaker(x, drive=6), 2.5, 6), 10),
    "level-30": lambda x: level(x, -30),
    "level-40": lambda x: level(x, -40),
    "level-12": lambda x: level(x, -12),
}
ADHAN_VARIANTS = {"as_is": lambda x: x, "level+10": lambda x: x * 10 ** 0.5, "level-10": lambda x: x * 10 ** -0.5,
                  "highpass300": lambda x: sosfilt(butter(4, 300, "high", fs=SR, output="sos"), x).astype(np.float32)}


def one(job):
    cid, kind, var, model = job
    x = sf.read(f"{SET}/clips/{cid}.flac", dtype="float32")[0]
    if x.ndim > 1:
        x = x.mean(1)
    x = (VARIANTS if kind == "rec" else ADHAN_VARIANTS)[var](x)
    x = np.clip(x, -1, 1).astype(np.float32)
    return dict(id=cid, kind=kind, variant=var, model=model, **measure(x, run(model, x)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--jobs", type=int, default=2)
    ap.add_argument("--models", default="dfn3_stream_int8,voice_v1_fp16")
    a = ap.parse_args()
    rows = list({r["id"]: r for r in map(json.loads, open(f"{SET}/manifest.jsonl"))}.values())
    rec, seen = [], set()
    for r in sorted(rows, key=lambda r: r["id"]):         # one clip per reciter, 6 reciters
        if r["group"] == "recitation" and r.get("codec") == "none" and r.get("source") not in seen and len(rec) < 6:
            rec.append(r["id"]); seen.add(r.get("source"))
    adhan = ["adhan_fs417865_1", "adhan_fs44465_1", "adhan_fs677581_0", "adhan_fs144432_0"]
    jobs = [(c, "rec", v, m) for c in rec for v in VARIANTS for m in a.models.split(",")]
    jobs += [(c, "adhan", v, m) for c in adhan for v in ADHAN_VARIANTS for m in a.models.split(",")]
    print(len(jobs), "runs;", rec, flush=True)
    with open(a.out, "w") as f, ProcessPoolExecutor(a.jobs) as ex:
        for res in ex.map(one, jobs):
            f.write(json.dumps(res) + "\n"); f.flush()
    print("done", flush=True)


if __name__ == "__main__":
    main()
