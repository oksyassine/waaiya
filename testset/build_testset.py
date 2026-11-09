"""Build the evaluation set: licensed voice clips mixed with synthesised instrumental music.

Music is generated procedurally (plucked strings, bass, pad, piano, drums, frame
drum and an optional voice-like lead melody), so every mixture has exact voice
and music references and nothing copyrighted is involved.

Output: data/mixtures/<id>_{voice,music}.flac (48 kHz stereo, 24-bit; mix = voice + music) and
data/mixtures/manifest.json. Also music-only items (expected output: silence).
"""
import json, os, subprocess, tempfile

import numpy as np
import soundfile as sf

SR = 48000
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "data", "sources")
OUT = os.path.join(HERE, "data", "mixtures")
MVR_DB = [-10.0, -3.0, 3.0]  # music-to-voice level ratios
MAX_SECONDS = 10.0


def load_48k(path):
    with tempfile.TemporaryDirectory() as d:
        dst = os.path.join(d, "o.wav")
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", path, "-ac", "1", "-ar", str(SR), "-c:a", "pcm_f32le", dst], check=True)
        x, _ = sf.read(dst, dtype="float32")
    return x


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def env_adsr(n, a, d, s, r):
    e = np.ones(n) * s
    A, D, R = int(a * SR), int(d * SR), int(r * SR)
    A, D = max(A, 1), max(D, 1)
    e[:A] = np.linspace(0, 1, A)[: n] if n >= A else np.linspace(0, 1, n)
    if n > A:
        e[A:A + D] = np.linspace(1, s, D)[: max(0, min(D, n - A))]
    if R > 0 and n > R:
        e[-R:] *= np.linspace(1, 0, R)
    return e


def karplus(f, dur, rng, bright=0.5):
    n = int(dur * SR)
    p = max(int(SR / f), 2)
    buf = rng.uniform(-1, 1, p)
    out = np.empty(n)
    for i in range(n):
        out[i] = buf[i % p]
        buf[i % p] = 0.5 * (buf[i % p] + buf[(i + 1) % p]) * (0.990 + 0.009 * bright)
    return out


def saw(f, n, phase=0.0):
    t = np.arange(n) / SR
    return 2 * ((f * t + phase) % 1.0) - 1


def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def onepole_lp_vec(x, cutoff):
    # vectorised enough for long pads: apply twice for 12 dB/oct
    from math import exp
    a = exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc = (1 - a) * x[i] + a * acc
        y[i] = acc
    return y


def place(track, sig, start, pan):
    s = int(start * SR)
    e = min(s + len(sig), track.shape[0])
    if e <= s:
        return
    l, r = np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)
    track[s:e, 0] += sig[: e - s] * l
    track[s:e, 1] += sig[: e - s] * r


def synth_music(seconds, seed, lead=True):
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    tr = np.zeros((n, 2))
    bpm = rng.uniform(78, 128)
    beat = 60.0 / bpm
    root = int(rng.integers(45, 57))
    hijaz = rng.random() < 0.5
    scale = [0, 1, 4, 5, 7, 8, 10] if hijaz else [0, 2, 3, 5, 7, 8, 10]
    progs = [[0, 5, 3, 4], [0, 3, 4, 0], [0, 6, 5, 4], [0, 4, 5, 3]]
    prog = progs[int(rng.integers(len(progs)))]
    bars = int(np.ceil(seconds / (4 * beat))) + 1
    for b in range(bars):
        deg = prog[b % 4]
        chord = [root + scale[(deg + k) % 7] + 12 * ((deg + k) // 7) for k in (0, 2, 4)]
        t0 = b * 4 * beat
        # pad (detuned saws, slow attack)
        pn = int(4 * beat * SR)
        pad = sum(saw(midi(c + 12), pn, rng.random()) + saw(midi(c + 12) * 1.004, pn, rng.random()) for c in chord)
        pad = onepole_lp_vec(pad, 1800) * env_adsr(pn, 0.3, 0.2, 0.8, 0.4) * 0.05
        place(tr, pad, t0, rng.uniform(-0.6, 0.6))
        # bass
        for k in range(4):
            bn = int(beat * SR * 0.9)
            bs = saw(midi(chord[0] - 12), bn)
            bs = onepole_lp_vec(bs, 400) * env_adsr(bn, 0.005, 0.1, 0.6, 0.05) * 0.35
            place(tr, bs, t0 + k * beat, 0.0)
        # plucked arpeggio (guitar / oud-like)
        for k in range(8):
            note = chord[k % 3] + 12 * (k // 3 % 2) + 12
            pl = karplus(midi(note), beat * 1.5, rng, rng.random()) * 0.25
            place(tr, pl, t0 + k * beat / 2, rng.uniform(-0.8, 0.8))
        # piano-ish chord stabs on beats 1 and 3
        for k in (0, 2):
            m = int(beat * 1.8 * SR)
            t = np.arange(m) / SR
            pi_ = sum(np.sin(2 * np.pi * midi(c + 12) * h * t) / h ** 1.3 for c in chord for h in range(1, 7))
            place(tr, pi_ * np.exp(-t * 3.0) * 0.04, t0 + k * beat, rng.uniform(-0.4, 0.4))
        # drums
        for k in range(4):
            tk = t0 + k * beat
            m = int(0.35 * SR)
            t = np.arange(m) / SR
            if k % 2 == 0:  # kick
                f = 50 + 90 * np.exp(-t * 30)
                place(tr, np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 9) * 0.6, tk, 0.0)
            else:  # snare / frame-drum slap
                sn = rng.standard_normal(m) * np.exp(-t * 18) * 0.25 + np.sin(2 * np.pi * 190 * t) * np.exp(-t * 20) * 0.2
                place(tr, sn, tk, 0.1)
            for h in range(2):  # hats
                hm = int(0.05 * SR)
                hh = np.diff(rng.standard_normal(hm + 1)) * np.exp(-np.arange(hm) / SR * 80) * 0.06
                place(tr, hh, tk + h * beat / 2, -0.3)
        # lead melody (flute/violin-like with vibrato: the voice-like hard case)
        if lead:
            for k in range(4):
                note = root + 12 + scale[int(rng.integers(7))] + 12 * int(rng.integers(0, 2))
                m = int(beat * SR)
                t = np.arange(m) / SR
                f = midi(note) * (1 + 0.006 * np.sin(2 * np.pi * 5.5 * t))
                ph = np.cumsum(f) / SR
                ld = (np.sin(2 * np.pi * ph) + 0.5 * np.sin(4 * np.pi * ph) + 0.25 * np.sin(6 * np.pi * ph))
                place(tr, ld * env_adsr(m, 0.05, 0.1, 0.8, 0.1) * 0.12, t0 + k * beat, rng.uniform(-0.3, 0.3))
    tr /= np.max(np.abs(tr)) + 1e-9
    return (tr * 0.5).astype(np.float32)


def active_rms(x, frame=1024):
    f = x[: len(x) // frame * frame].reshape(-1, frame)
    e = np.sqrt((f ** 2).mean(1) + 1e-12)
    thr = e.max() * 10 ** (-40 / 20)
    return float(np.sqrt((f[e > thr] ** 2).mean() + 1e-12))


def main():
    os.makedirs(OUT, exist_ok=True)
    meta = json.load(open(os.path.join(SRC, "SOURCES.json")))
    manifest = []
    for i, (name, m) in enumerate(sorted(meta.items())):
        v = load_48k(os.path.join(SRC, name))[: int(MAX_SECONDS * SR)]
        v = v / (np.max(np.abs(v)) + 1e-9) * 0.5
        seconds = len(v) / SR
        for j, mvr in enumerate(MVR_DB):
            seed = 1000 * i + j
            mus = synth_music(seconds, seed, lead=(j != 0))
            g = active_rms(v) * 10 ** (mvr / 20) / active_rms(mus.mean(1))
            mus = mus * g
            voice = np.stack([v, v], 1).astype(np.float32) * 0.7071
            mix = voice + mus
            peak = np.max(np.abs(mix))
            if peak > 0.98:
                voice, mus, mix = voice / peak * 0.98, mus / peak * 0.98, mix / peak * 0.98
            iid = f"{name[:-4]}_mvr{int(mvr):+d}"
            for kind, sig in (("voice", voice), ("music", mus)):  # mix = voice + music, rebuilt by the evaluator
                sf.write(os.path.join(OUT, f"{iid}_{kind}.flac"), sig, SR, subtype="PCM_24")
            manifest.append({"id": iid, "category": m["category"], "mvr_db": mvr, "lead_melody": j != 0,
                             "seconds": round(seconds, 2), "text": m.get("text", ""), "source": name})
    for k in range(5):  # music only: anything that comes out is leakage
        mus = synth_music(8.0, 90000 + k, lead=True)
        iid = f"music_only_{k}"
        sf.write(os.path.join(OUT, f"{iid}_music.flac"), mus, SR, subtype="PCM_24")
        manifest.append({"id": iid, "category": "music_only", "mvr_db": None, "lead_melody": True, "seconds": 8.0})
    json.dump(manifest, open(os.path.join(OUT, "manifest.json"), "w"), ensure_ascii=False, indent=1)
    print(f"{len(manifest)} items written to {OUT}")


if __name__ == "__main__":
    main()
