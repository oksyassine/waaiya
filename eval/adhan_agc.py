"""Cheapest fix to try: raise quiet input to a set level before the default filter (and back after), as an AGC in front
of the model would. Kept is measured against the raised input (the gain cancels out).

    python eval/adhan_agc.py --groups adhan,speech_room --target -16 --out /srv/build/music/adhan/agc.jsonl
"""
import argparse, json, os, sys
from concurrent.futures import ProcessPoolExecutor

import numpy as np
import soundfile as sf

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from adhan_filter import run, measure, db  # noqa: E402

SET = "/srv/build/music/set2"


def active_db(x, sr=48000):
    w = [db(x[i:i + sr]) for i in range(0, max(1, len(x) - sr + 1), sr // 2)]
    w = [v for v in w if v > -60] or [db(x)]
    return float(np.percentile(w, 75))


def one(job):
    cid, group, target, model = job
    x = sf.read(f"{SET}/clips/{cid}.flac", dtype="float32")[0]
    if x.ndim > 1:
        x = x.mean(1)
    g = min(10 ** ((target - active_db(x)) / 20), 10 ** (30 / 20))   # at most +30 dB, never quieter
    g = max(g, 1.0)
    y = np.clip(x * g, -1, 1).astype(np.float32)
    return dict(id=cid, group=group, target=target, gain_db=round(20 * np.log10(g), 1), model=model, **measure(y, run(model, y)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--groups", default="adhan,speech_room")
    ap.add_argument("--target", type=float, default=-16)
    ap.add_argument("--model", default="dfn3_stream_int8")
    ap.add_argument("--out", required=True)
    ap.add_argument("--jobs", type=int, default=2)
    a = ap.parse_args()
    rows = list({r["id"]: r for r in map(json.loads, open(f"{SET}/manifest.jsonl"))}.values())
    jobs = [(r["id"], r["group"], a.target, a.model) for r in rows if r["group"] in a.groups.split(",")]
    with open(a.out, "a") as f, ProcessPoolExecutor(a.jobs) as ex:
        for res in ex.map(one, jobs):
            f.write(json.dumps(res) + "\n"); f.flush()


if __name__ == "__main__":
    main()
