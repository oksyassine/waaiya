"""Parity check of the app's "Check for music" path (engine/src/im_music.c through build/im-music-scan) against the
evaluation's tags (eval/music_check_features.py on branch music-check): writes a copy of the evaluation features
where tag_mix and lin come from the C path, so eval/music_check_eval.py scores what the phone computes.

    python models/music/eval_scan.py --set /srv/build/music/set2 --feat /srv/build/music/feat --out /srv/build/music/feat_c
"""
import argparse, json, os, subprocess, sys, tempfile
from concurrent.futures import ProcessPoolExecutor

import numpy as np
import soundfile as sf

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SCAN = os.path.join(ROOT, "build/im-music-scan")
MODEL = os.path.join(ROOT, "models/music/tagger_mn04.onnx")


def one(job):
    clip, feat, out = job
    if os.path.exists(out):
        return out, None
    z = dict(np.load(feat))
    x, sr = sf.read(clip, dtype="float32", always_2d=True)
    with tempfile.TemporaryDirectory() as d:
        sf.write(d + "/i.wav", x, sr, subtype="FLOAT")
        p = subprocess.run([SCAN, MODEL, d + "/i.wav", d + "/o"], capture_output=True, text=True)
        if p.returncode:
            return out, p.stderr[-200:]
        tags = np.fromfile(d + "/o.tags", np.float32).reshape(-1, 527)
        lvl = np.fromfile(d + "/o.lvl", np.float32)
    n = min(len(tags), len(z["t"]))
    for k, v in list(z.items()):
        if isinstance(v, np.ndarray) and v.ndim >= 1 and len(v) == len(z["t"]):
            z[k] = v[:n]
    z["tag_mix_py"] = z["tag_mix"]
    z["tag_mix"] = tags[:n].astype(np.float16)
    z["lin"] = lvl[:n]
    np.savez_compressed(out, **z)
    return out, None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--set", default="/srv/build/music/set2")
    ap.add_argument("--feat", default="/srv/build/music/feat")
    ap.add_argument("--out", default="/srv/build/music/feat_c")
    ap.add_argument("--jobs", type=int, default=2)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    rows = list({r["id"]: r for r in map(json.loads, open(os.path.join(a.set, "manifest.jsonl")))}.values())
    jobs = [(os.path.join(a.set, "clips", r["id"] + ".flac"), os.path.join(a.feat, r["id"] + ".npz"),
             os.path.join(a.out, r["id"] + ".npz")) for r in rows]
    jobs = [j for j in jobs if os.path.exists(j[0]) and os.path.exists(j[1])]
    print(len(jobs), "clips", flush=True)
    diffs = []
    with ProcessPoolExecutor(a.jobs) as ex:
        for k, (out, err) in enumerate(ex.map(one, jobs, chunksize=8)):
            if err:
                print("FAIL", out, err, flush=True)
                continue
            z = np.load(out)
            loud = z["lin"] > -45
            if loud.any():
                d = np.abs(z["tag_mix"].astype(np.float32) - z["tag_mix_py"].astype(np.float32))[loud]
                diffs.append((d.max(), d[:, 137].mean(), np.abs(z["lin"] - np.load(jobs[k][1])["lin"][:len(z["lin"])])[loud].max()))
            if k % 200 == 0:
                print(f"  {k}/{len(jobs)}", flush=True)
    d = np.array(diffs)
    print(f"tags |C - eval|: max over clips median {np.median(d[:, 0]):.3f}, 90% {np.percentile(d[:, 0], 90):.3f}; "
          f"'Music' class mean diff median {np.median(d[:, 1]):.4f}; level diff max median {np.median(d[:, 2]):.2f} dB")


if __name__ == "__main__":
    main()
