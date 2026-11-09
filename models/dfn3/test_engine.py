"""C engine (im-process) vs PyTorch streaming model, stereo, odd block size."""
import subprocess, sys, tempfile, os
import numpy as np, soundfile as sf, torch
from export_stream import build

root = os.path.dirname(os.path.abspath(__file__))
cli = os.path.join(root, "../../build/im-process")
model = os.path.join(root, "dfn3_stream.onnx")
s, _, _ = build()
sr, hop = s.sr, s.hop
rng = np.random.default_rng(3)
t = np.arange(int(2.5 * sr)) / sr
L = 0.2 * np.sin(2 * np.pi * 300 * t) + 0.05 * rng.standard_normal(t.size)
R = 0.1 * np.sin(2 * np.pi * 500 * t) + 0.08 * rng.standard_normal(t.size)
x = np.stack([L, R], 1).astype(np.float32)
with tempfile.TemporaryDirectory() as d:
    i, o = os.path.join(d, "in.wav"), os.path.join(d, "out.wav")
    sf.write(i, x, sr, subtype="FLOAT")
    r = subprocess.run([cli, "-m", model, "--block", "333", i, o], capture_output=True, text=True)
    print(r.stdout.strip(), r.stderr.strip())
    y, _ = sf.read(o, dtype="float32")
worst = 1e9
for c in range(2):
    st = s.state_init.clone(); outs = []
    sig = np.concatenate([x[:, c], np.zeros(s.latency_samples + hop, np.float32)])
    with torch.no_grad():
        for k in range(len(sig) // hop):
            yy, st = s(torch.from_numpy(sig[k * hop:(k + 1) * hop]), st)
            outs.append(yy.numpy())
    ref = np.concatenate(outs)[s.latency_samples:s.latency_samples + len(y)]
    n = min(len(ref), len(y))
    a, b = ref[:n], y[:n, c]
    snr = 10 * np.log10(np.sum(a ** 2) / (np.sum((a - b) ** 2) + 1e-30))
    print(f"channel {c}: max abs err {np.abs(a - b).max():.2e}, match {snr:.1f} dB")
    worst = min(worst, snr)
assert worst > 80, "C engine diverges"
print("ENGINE PARITY OK")
