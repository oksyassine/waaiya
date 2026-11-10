"""ONNX Runtime vs PyTorch parity and single-thread speed for the streaming export.

Usage: python test_onnx.py [model.onnx] [checkpoint.pt]   (look-ahead read from the model's latency)"""
import sys, time
import numpy as np
import onnxruntime as ort
import torch
from export_stream import build

path = sys.argv[1] if len(sys.argv) > 1 else "dfn3_stream.onnx"
so = ort.SessionOptions()
so.intra_op_num_threads = 1
so.inter_op_num_threads = 1
so.execution_mode = ort.ExecutionMode.ORT_SEQUENTIAL
sess = ort.InferenceSession(path, so, providers=["CPUExecutionProvider"])
meta = sess.get_modelmeta().custom_metadata_map
hop, sr = int(meta["im.hop"]), int(meta["im.sample_rate"])
print("metadata:", meta)

n_fft = 2 * hop
la = (int(meta["im.latency_samples"]) - (n_fft - hop)) // hop
s, _, _ = build(sys.argv[2] if len(sys.argv) > 2 else "", la)
assert s.latency_samples == int(meta["im.latency_samples"]) and s.state_size == int(meta["im.state_size"])
rng = np.random.default_rng(1)
sig = (0.1 * rng.standard_normal(sr * 4)).astype(np.float32)
st_o = s.state_init.numpy().copy()
st_t = s.state_init.clone()
yo, yt = [], []
t_ort = 0.0
with torch.no_grad():
    for i in range(len(sig) // hop):
        x = sig[i * hop:(i + 1) * hop]
        t0 = time.perf_counter()
        y, st_o = sess.run(None, {"audio_in": x, "state_in": st_o})
        t_ort += time.perf_counter() - t0
        yo.append(y)
        y2, st_t = s(torch.from_numpy(x), st_t)
        yt.append(y2.numpy())
yo, yt = np.concatenate(yo), np.concatenate(yt)
err = float(np.abs(yo - yt).max())
print(f"look-ahead {la}: ort vs torch max abs err {err:.2e}")
assert err < 1e-3, "ONNX export diverges from the PyTorch streaming model"
audio_s = len(yo) / sr
print(f"ORT single thread: {1000 * t_ort / (len(yo) // hop):.2f} ms per {1000*hop/sr:.0f} ms hop, RTF {t_ort / audio_s:.3f}")
