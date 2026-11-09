"""Helpers for linux/test_sink.sh: build a test mix, then score a live recording of the filter."""
import os, sys
import numpy as np
import soundfile as sf

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "eval"))
from evaluate import MIX, stft_pow  # noqa: E402

cmd, item, path = sys.argv[1:4]
voice = sf.read(os.path.join(MIX, f"{item}_voice.flac"), dtype="float32")[0]
music = sf.read(os.path.join(MIX, f"{item}_music.flac"), dtype="float32")[0]
mix = voice + music
if cmd == "make":
    sf.write(path, mix, 48000, subtype="FLOAT")
    sys.exit(0)
rec = sf.read(path, dtype="float32", always_2d=True)[0].mean(1)
v, m, x = voice.mean(1), music.mean(1), mix.mean(1)
n = 1 << int(np.ceil(np.log2(len(rec) + len(v))))
cc = np.fft.irfft(np.fft.rfft(rec, n) * np.conj(np.fft.rfft(v, n)), n)
lag = int(np.argmax(cc[: len(rec)]))
y = rec[lag:lag + len(v)]
if len(y) < len(v):
    y = np.pad(y, (0, len(v) - len(y)))
V, M, X, Y = stft_pow(v), stft_pow(m), stft_pow(x), stft_pow(y)
supp = 10 * np.log10(X[M > V * 10].sum() / (Y[M > V * 10].sum() + 1e-12))
ret = 10 * np.log10(Y[V > M * 10].sum() / (X[V > M * 10].sum() + 1e-12))
print(f"live: instrument suppression {supp:.1f} dB, voice retention {ret:.1f} dB, recording offset {lag} samples")
print("LIVE OK" if supp > 10 and ret > -6 else "LIVE CHECK FAILED")
