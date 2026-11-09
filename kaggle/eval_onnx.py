"""Score streaming ONNX voice models on the evaluation set with ONNX Runtime (Python version of
eval/evaluate.py, for machines without the C engine, e.g. Kaggle). Same metrics, same test set.

Usage: python kaggle/eval_onnx.py name=model.onnx [name2=model2.onnx ...]
"""
import json, os, sys, time
from collections import defaultdict

import numpy as np
import onnxruntime as ort
import soundfile as sf

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "eval"))
from evaluate import MIX, si_sdr, stft_pow  # noqa: E402


def load(path):
    so = ort.SessionOptions()
    so.intra_op_num_threads = 1
    s = ort.InferenceSession(path, so, providers=["CPUExecutionProvider"])
    m = s.get_modelmeta().custom_metadata_map
    init_p = path[:-5] + ".state_init.bin"
    init = np.fromfile(init_p, "<f4") if os.path.exists(init_p) else np.zeros(int(m["im.state_size"]), np.float32)
    return s, int(m["im.hop"]), int(m["im.latency_samples"]), init


def run(model, x):
    sess, hop, lat, init = model
    T, C = x.shape
    pad = np.concatenate([x, np.zeros((lat + hop, C), np.float32)])
    out = np.zeros_like(pad)
    for c in range(C):
        st = init.copy()
        for k in range(0, len(pad) - hop + 1, hop):
            y, st = sess.run(None, {"audio_in": np.ascontiguousarray(pad[k:k + hop, c]), "state_in": st})
            out[k:k + hop, c] = y
    return out[lat:lat + T]


def score(model, items):
    rows = []
    for it in items:
        mus = sf.read(os.path.join(MIX, f"{it['id']}_music.flac"), dtype="float32", always_2d=True)[0]
        vp = os.path.join(MIX, f"{it['id']}_voice.flac")
        voice = sf.read(vp, dtype="float32", always_2d=True)[0] if os.path.exists(vp) else None
        mix = mus + voice if voice is not None else mus
        y = run(model, mix).mean(1)
        xm = mix.mean(1)
        r = {"id": it["id"], "category": it["category"], "mvr_db": it["mvr_db"]}
        if voice is None:
            r["leak_db"] = float(10 * np.log10((y ** 2).sum() / ((xm ** 2).sum() + 1e-12) + 1e-12))
        else:
            vm, mm = voice.mean(1), mus.mean(1)
            V, M, X, Y = stft_pow(vm), stft_pow(mm), stft_pow(xm), stft_pow(y)
            r["inst_supp_db"] = float(10 * np.log10(X[M > V * 10].sum() / (Y[M > V * 10].sum() + 1e-12)))
            r["voice_ret_db"] = float(10 * np.log10(Y[V > M * 10].sum() / (X[V > M * 10].sum() + 1e-12)))
            r["sisdr_gain_db"] = float(si_sdr(y, vm) - si_sdr(xm, vm))
        rows.append(r)
    return rows


def main():
    items = json.load(open(os.path.join(MIX, "manifest.json")))
    lines = ["| model | group | n | instrument suppression dB | voice retention dB | SI-SDR gain dB | music-only leak dB |",
             "|---|---|---|---|---|---|---|"]
    results = {}
    for spec in sys.argv[1:]:
        name, path = spec.split("=", 1)
        t0 = time.time()
        rows = score(load(path), items)
        results[name] = rows
        groups = defaultdict(list)
        for r in rows:
            groups[r["category"]].append(r)
        for g, rs in sorted(groups.items()):
            m = lambda k: f"{np.mean([r[k] for r in rs if k in r]):.2f}" if any(k in r for r in rs) else ""
            lines.append(f"| {name} | {g} | {len(rs)} | {m('inst_supp_db')} | {m('voice_ret_db')} | {m('sisdr_gain_db')} | {m('leak_db')} |")
        print(f"{name}: scored in {time.time() - t0:.0f} s", flush=True)
    text = "\n".join(lines)
    print(text)
    out = os.environ.get("EVAL_OUT", ".")
    open(os.path.join(out, "eval_summary.md"), "w").write(text + "\n")
    json.dump(results, open(os.path.join(out, "eval_rows.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
