"""Delay of recording 2 relative to recording 1 on the shared clock.
time of sample n = fit(n -> t - latency) ; also report uncorrected (t only) and naive (sample index) lags."""
import sys, numpy as np
p = sys.argv[1]; R = 48000
d1, s1 = np.load(p + "_s1.npy").mean(1), np.load(p + "_s1_ts.npy")
d2, s2 = np.load(p + "_s2.npy").mean(1), np.load(p + "_s2_ts.npy")
def fit(st, corr):
    n, t, l = st[:, 0], st[:, 1], st[:, 2]
    y = t - l if corr else t
    # sample n was captured at y (ideal clock: slope 1/R); robust intercept = median of y - n/R
    return np.median(y - n / R), np.polyfit(n, y, 1)[0] * R
def lag_samples(a, b, maxlag=240000):
    n = 1 << int(np.ceil(np.log2(len(a) + len(b))))
    cc = np.fft.irfft(np.fft.rfft(b, n) * np.conj(np.fft.rfft(a, n)), n)
    c = np.concatenate([cc[-maxlag:], cc[:maxlag]]); i = int(np.argmax(c))
    # parabolic sub-sample refine
    if 0 < i < len(c) - 1:
        y0, y1, y2 = c[i - 1], c[i], c[i + 1]; frac = 0.5 * (y0 - y2) / (y0 - 2 * y1 + y2)
    else: frac = 0
    return i - maxlag + frac, c[i] / (np.sqrt((a**2).sum() * (b**2).sum()) + 1e-20)
lag, ncc = lag_samples(d1, d2)
o1, r1 = fit(s1, True); o2, r2 = fit(s2, True); u1, _ = fit(s1, False); u2, _ = fit(s2, False)
delay = lag / R + (o2 - o1)
print(f"naive lag {lag/R*1e3:.2f} ms | start offset (corr) {1e3*(o2-o1):.2f} ms -> DELAY {1e3*delay:.2f} ms | "
      f"(uncorrected {1e3*(lag/R+u2-u1):.2f}) | mean lat s1 {1e3*s1[:,2].mean():.2f} s2 {1e3*s2[:,2].mean():.2f} ms | "
      f"clock ratio {r1:.5f} {r2:.5f} | ncc {ncc:.2f} | rms {np.sqrt((d1**2).mean()):.4f} {np.sqrt((d2**2).mean()):.4f}")
# windowed delays (2 s windows) on the shared clock: a dropout/underrun shows up as a jump
off = o2 - o1; W = 2 * R; ds = []
import os, subprocess, soundfile as sf
SEARCH = int(float(os.environ.get("IM_ALIGN_SEARCH_MS", "25")) * R / 1000)
if len(sys.argv) > 2 and sys.argv[2] == "ref":   # compare against the offline engine output of the dry recording
    RP = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    sf.write(p + "_dry.wav", np.load(p + "_s1.npy"), R, subtype="FLOAT")
    subprocess.run([RP + "/build/im-process", "-m", RP + "/models/dfn3/dfn3_stream.onnx", p + "_dry.wav", p + "_ref.wav"],
                   env=dict(os.environ, LD_LIBRARY_PATH=RP + "/build"), check=True, stdout=subprocess.DEVNULL)
    d1 = sf.read(p + "_ref.wav", dtype="float32", always_2d=True)[0].mean(1); os.remove(p + "_dry.wav"); os.remove(p + "_ref.wav")
    lag, _ = lag_samples(d1, d2)
g = int(round(lag))
for st in range(0, len(d1) - W - abs(g), W):
    a = d1[st:st + W]
    if np.sqrt((a**2).mean()) < 0.003: continue
    if SEARCH <= 1200:  # default: circular search within +-25 ms of the global lag
        b = d2[max(0, st + g - 2400): st + g - 2400 + W + 4800]
        if len(b) < W + 4800: continue
        l, c = lag_samples(a, b[2400:2400 + W], 1200)
    else:  # IM_ALIGN_SEARCH_MS > 25: linear search, follows delay steps larger than 25 ms
        if st + g - SEARCH < 0: continue
        b = d2[st + g - SEARCH: st + g + W + SEARCH]
        if len(b) < W + 2 * SEARCH: continue
        l, c = lag_samples(a, b, 2 * SEARCH)
        l -= SEARCH
    if c > 0.5: ds.append(1e3 * ((g + l) / R + off))
ds = np.array(ds)
# also residual check: wet vs dry energy in silent dropouts (zero runs > 5 ms inside active output)
z = np.abs(d2) < 1e-7; runs = 0; cur = 0; act = np.convolve(np.abs(d2) > 1e-3, np.ones(4800), "same") > 0
for i in np.flatnonzero(act & z)[:0]: pass
dz = np.diff(np.concatenate([[0], (z & act).astype(np.int8), [0]])); st_, en_ = np.flatnonzero(dz == 1), np.flatnonzero(dz == -1)
gaps = int(((en_ - st_) > 240).sum())
print("   windows:", np.round(ds,1).tolist()) if len(sys.argv) > 3 else None
print(f"   windowed delay{' (vs offline engine output)' if len(sys.argv) > 2 else ''} over {len(ds)} windows: min {ds.min():.2f} median {np.median(ds):.2f} max {ds.max():.2f} ms | zero-gaps>5ms inside active output: {gaps}")
