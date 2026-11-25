"""How much of chanted voice (adhan, recitation) the shipped filters keep. Per clip and per 1 s window: input and
output level (dBFS), kept = output - input (dB). A window counts when the input is louder than -45 dBFS.

    python eval/adhan_filter.py --set /srv/build/music/set2 --groups adhan,recitation --models dfn3_stream_int8,voice_v1_fp16 \
        --out /srv/build/music/adhan/kept.jsonl [--jobs 2] [--clips a,b]
"""
import argparse, json, os, subprocess, tempfile
from concurrent.futures import ProcessPoolExecutor

import numpy as np
import soundfile as sf

SR = 48000
IMP = "/srv/projects/islamic_mute/build/im-process"
MODELS = {
    "dfn3_stream_int8": "/srv/projects/islamic_mute/models/dfn3/dfn3_stream_int8.onnx",
    "dfn3_stream_fp16": "/srv/projects/islamic_mute/models/dfn3/dfn3_stream_fp16.onnx",
    "dfn3_stream": "/srv/projects/islamic_mute/models/dfn3/dfn3_stream.onnx",
    "voice_v1_fp16": "/srv/projects/islamic_mute/models/voice/v3/voice_v1_fp16.onnx",
    "voice_v1_int8": "/srv/projects/islamic_mute/models/voice/v3/voice_v1_int8.onnx",
}


def db(a):
    return float(10 * np.log10(np.mean(np.asarray(a, np.float64) ** 2) + 1e-12))


def run(model, x):
    with tempfile.TemporaryDirectory(dir="/srv/build/tmp") as d:
        sf.write(d + "/i.wav", x, SR, subtype="FLOAT")
        p = subprocess.run([IMP, "-m", MODELS.get(model, model), d + "/i.wav", d + "/o.wav"], capture_output=True, text=True)
        if p.returncode:
            raise RuntimeError(p.stderr[-300:])
        y = sf.read(d + "/o.wav", dtype="float32")[0]
    if y.ndim > 1:
        y = y.mean(1)
    return np.pad(y[: len(x)], (0, max(0, len(x) - len(y))))


def measure(x, y):
    win, step = SR, SR // 2
    w = []
    for i in range(0, max(1, len(x) - win + 1), step):
        a, b = db(x[i:i + win]), db(y[i:i + win])
        if a > -45:
            w.append(b - a)
    w = np.array(w) if w else np.array([0.0])
    return dict(lin=db(x), lout=db(y), kept=db(y) - db(x), win_med=float(np.median(w)), win_p10=float(np.percentile(w, 10)),
                muted_share=float(np.mean(w < -20)))


def one(job):
    path, cid, group, model = job
    x = sf.read(path, dtype="float32")[0]
    if x.ndim > 1:
        x = x.mean(1)
    y = run(model, x)
    return dict(id=cid, group=group, model=model, **measure(x, y))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--set", default="/srv/build/music/set2")
    ap.add_argument("--groups", default="adhan")
    ap.add_argument("--models", default="dfn3_stream_int8,voice_v1_fp16")
    ap.add_argument("--clips", default="")
    ap.add_argument("--out", required=True)
    ap.add_argument("--jobs", type=int, default=2)
    a = ap.parse_args()
    rows = list({r["id"]: r for r in map(json.loads, open(os.path.join(a.set, "manifest.jsonl")))}.values())
    groups = set(a.groups.split(","))
    clips = set(a.clips.split(",")) if a.clips else None
    done = set()
    if os.path.exists(a.out):
        done = {(r["id"], r["model"]) for r in map(json.loads, open(a.out))}
    jobs = [(os.path.join(a.set, "clips", r["id"] + ".flac"), r["id"], r["group"], m) for r in rows for m in a.models.split(",")
            if (r["group"] in groups or (clips and r["id"] in clips)) and (r["id"], m) not in done]
    print(len(jobs), "runs", flush=True)
    with open(a.out, "a") as f, ProcessPoolExecutor(a.jobs) as ex:
        for k, res in enumerate(ex.map(one, jobs)):
            f.write(json.dumps(res) + "\n"); f.flush()
            if k % 25 == 0:
                print(k, flush=True)
    print("done", flush=True)


if __name__ == "__main__":
    main()
