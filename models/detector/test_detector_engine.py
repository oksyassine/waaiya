"""Parity: C detector front end + ONNX Runtime (build/test-detector) vs the PyTorch training code.
Usage: test_detector_engine.py detector.onnx [audio file]"""
import os, subprocess, sys, tempfile
import numpy as np, soundfile as sf, torch, torchaudio.functional as AF

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
from mobilenet import N_FFT, HOP, FRAMES, MelFrontEnd  # noqa: E402


def main():
    onnx_path = sys.argv[1]
    src = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "evalset", "singing_F_3.flac")
    x, sr = sf.read(src, dtype="float32", always_2d=True)
    x = AF.resample(torch.from_numpy(x.mean(1)), sr, 48000).numpy()
    K = 2 * FRAMES  # frames pushed; multiple of the classification interval (25)
    L = N_FFT + (K - 1) * HOP
    x = np.resize(x, L).astype(np.float32) * 0.5
    with tempfile.TemporaryDirectory() as t:
        wav, pw = os.path.join(t, "in.wav"), os.path.join(t, "pw.bin")
        sf.write(wav, x, 48000, subtype="FLOAT")
        r = subprocess.run([os.path.join(ROOT, "build", "test-detector"), onnx_path, wav, pw], capture_output=True, text=True)
        print(r.stdout.strip(), r.stderr.strip())
        c_power = np.fromfile(pw, np.float32).reshape(N_FFT // 2 + 1, FRAMES)
    c_probs = np.array([float(v) for v in r.stdout.split("probs=")[1].split()[:4]])
    # reference: pre-emphasis with x[-1] = 0, frames k*HOP .. k*HOP+N_FFT, keep the last FRAMES
    y = x - 0.97 * np.concatenate([[0.0], x[:-1]]).astype(np.float32)
    win = MelFrontEnd().window.numpy().astype(np.float64)
    frames = np.stack([y[k * HOP:k * HOP + N_FFT] * win for k in range(K)])
    ref = (np.abs(np.fft.rfft(frames.astype(np.float64), axis=1)) ** 2).T[:, -FRAMES:]
    rel = np.max(np.abs(c_power - ref)) / np.max(ref)
    print(f"power window: max rel err {rel:.2e}")
    import onnxruntime as ort
    sess = ort.InferenceSession(onnx_path, providers=["CPUExecutionProvider"])
    py_probs = sess.run(None, {"power": ref[None].astype(np.float32)})[0][0]
    print("probs C:", np.round(c_probs, 5), " python:", np.round(py_probs, 5))
    ok = rel < 1e-4 and np.max(np.abs(c_probs - py_probs)) < 1e-3
    print("PASS" if ok else "FAIL")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
