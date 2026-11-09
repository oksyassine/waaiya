"""Score voice-filter models on the test set by running them through the real C engine.

Usage:
  python eval/evaluate.py --candidate dfn3=models/dfn3/dfn3_stream.onnx [--candidate name=path[:mono]] [--asr]

Metrics (all on the mono sum, after removing the engine delay):
  inst_supp_db   attenuation of time-frequency bins where music dominates the voice by >10 dB (higher = fewer instruments)
  voice_ret_db   level change of bins where voice dominates music by >10 dB (0 = voice intact, negative = voice lost)
  sisdr_gain_db  SI-SDR of the output against the clean voice minus SI-SDR of the input mix
  leak_db        music-only items: output level relative to input (more negative = less leakage)
  leak_frames    music-only items: share of 100 ms frames still louder than -50 dBFS
  wer            with --asr: word error rate of the output transcript against the clean-voice transcript
"""
import argparse, json, os, subprocess, sys, tempfile, time
from collections import defaultdict

import numpy as np
import soundfile as sf

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIX = os.path.join(ROOT, "testset", "data", "mixtures")
CLI = os.path.join(ROOT, "build", "im-process")
SR = 48000


def stft_pow(x, n=1024, hop=512):
    w = np.hanning(n)
    frames = np.lib.stride_tricks.sliding_window_view(np.pad(x, (n, n)), n)[::hop] * w
    return np.abs(np.fft.rfft(frames, axis=1)) ** 2


def si_sdr(est, ref):
    ref = ref - ref.mean()
    est = est - est.mean()
    a = np.dot(est, ref) / (np.dot(ref, ref) + 1e-12)
    t = a * ref
    return 10 * np.log10(np.sum(t ** 2) / (np.sum((est - t) ** 2) + 1e-12) + 1e-12)


def run_engine(model, mix, mono=False):
    with tempfile.TemporaryDirectory() as d:
        i, o = os.path.join(d, "i.wav"), os.path.join(d, "o.wav")
        sf.write(i, mix, SR, subtype="FLOAT")
        cmd = [CLI, "-m", model, i, o] + (["--mono"] if mono else [])
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            raise RuntimeError(r.stderr)
        y, _ = sf.read(o, dtype="float32", always_2d=True)
        info = dict(kv.split("=", 1) for kv in r.stdout.split() if "=" in kv and not kv.startswith('model'))
    return y, float(info.get("rtf", "nan"))


class Asr:
    def __init__(self, size):
        from faster_whisper import WhisperModel
        self.m = WhisperModel(size, device="cpu", compute_type="int8")

    def text(self, x, lang):
        x16 = x[::3].astype(np.float32)  # 48 kHz -> 16 kHz (inputs are band-limited enough for ASR)
        segs, _ = self.m.transcribe(x16, language=lang, beam_size=1, vad_filter=False)
        return " ".join(s.text for s in segs)


def wer(ref, hyp):
    import re
    norm = lambda s: re.sub(r"[^\w\s]", " ", s.lower()).split()
    r, h = norm(ref), norm(hyp)
    if not r:
        return float("nan")
    d = np.arange(len(h) + 1)
    for i, rw in enumerate(r, 1):
        prev, d[0] = d.copy(), i
        for j, hw in enumerate(h, 1):
            d[j] = min(prev[j] + 1, d[j - 1] + 1, prev[j - 1] + (rw != hw))
    return d[len(h)] / len(r)


def evaluate(name, model, mono, items, asr=None):
    rows, rtfs = [], []
    for it in items:
        mus = sf.read(os.path.join(MIX, f"{it['id']}_music.flac"), dtype="float32", always_2d=True)[0]
        vp = os.path.join(MIX, f"{it['id']}_voice.flac")
        voice = sf.read(vp, dtype="float32", always_2d=True)[0] if os.path.exists(vp) else None
        mix = mus + voice if voice is not None else mus
        if model == "passthrough":
            y, rtf = mix.copy(), 0.0
        else:
            y, rtf = run_engine(model, mix, mono)
        rtfs.append(rtf)
        ym, xm = y.mean(1), mix.mean(1)
        row = {"id": it["id"], "category": it["category"], "mvr_db": it["mvr_db"], "lead": it["lead_melody"]}
        if voice is None:
            row["leak_db"] = 10 * np.log10((ym ** 2).sum() / ((xm ** 2).sum() + 1e-12) + 1e-12)
            f = ym[: len(ym) // 4800 * 4800].reshape(-1, 4800)
            row["leak_frames"] = float((20 * np.log10(np.sqrt((f ** 2).mean(1)) + 1e-12) > -50).mean())
        else:
            vm, mm = voice.mean(1), mus.mean(1)
            V, M, X, Y = stft_pow(vm), stft_pow(mm), stft_pow(xm), stft_pow(ym)
            mdom = M > V * 10
            vdom = V > M * 10
            row["inst_supp_db"] = 10 * np.log10(X[mdom].sum() / (Y[mdom].sum() + 1e-12))
            row["voice_ret_db"] = 10 * np.log10(Y[vdom].sum() / (X[vdom].sum() + 1e-12))
            row["sisdr_gain_db"] = si_sdr(ym, vm) - si_sdr(xm, vm)
            if asr is not None:
                lang = "en" if it["category"] == "speech_en" else "ar"
                if it["category"] != "singing":
                    ref = asr.text(vm, lang)
                    row["wer"] = wer(ref, asr.text(ym, lang))
                    row["wer_mix"] = wer(ref, asr.text(xm, lang))
        rows.append(row)
        print(f"  {name} {it['id']}: " + ", ".join(f"{k}={v:.2f}" for k, v in row.items() if isinstance(v, float)), flush=True)
    return rows, float(np.nanmean(rtfs)) if rtfs else 0.0


def summarise(name, rows, rtf):
    groups = defaultdict(list)
    for r in rows:
        groups[r["category"]].append(r)
        if r["mvr_db"] is not None:
            groups[f"all voice, music {r['mvr_db']:+.0f} dB"].append(r)
    keys = ["inst_supp_db", "voice_ret_db", "sisdr_gain_db", "wer", "wer_mix", "leak_db", "leak_frames"]
    out = {}
    for g, rs in sorted(groups.items()):
        out[g] = {k: round(float(np.nanmean([r[k] for r in rs if k in r])), 2) for k in keys if any(k in r for r in rs)}
        out[g]["n"] = len(rs)
    return {"candidate": name, "rtf_stereo_1thread": round(rtf, 3), "groups": out}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--candidate", action="append", default=[], help="name=model.onnx[:mono] or name=passthrough")
    ap.add_argument("--asr", nargs="?", const="base", help="also score word error rate with faster-whisper (model size)")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--out", default=os.path.join(ROOT, "eval", "results"))
    args = ap.parse_args()
    items = json.load(open(os.path.join(MIX, "manifest.json")))
    if args.limit:
        items = items[: args.limit]
    asr = Asr(args.asr) if args.asr else None
    os.makedirs(args.out, exist_ok=True)
    cands = args.candidate or ["passthrough=passthrough", f"dfn3={os.path.join(ROOT, 'models/dfn3/dfn3_stream.onnx')}"]
    summary = []
    for c in cands:
        name, spec = c.split("=", 1)
        mono = spec.endswith(":mono")
        model = spec[:-5] if mono else spec
        t0 = time.time()
        rows, rtf = evaluate(name, model, mono, items, asr)
        s = summarise(name, rows, rtf)
        s["seconds"] = round(time.time() - t0, 1)
        json.dump({"summary": s, "rows": rows}, open(os.path.join(args.out, f"{name}.json"), "w"), indent=1)
        summary.append(s)
    lines = ["| candidate | group | n | instrument suppression dB | voice retention dB | SI-SDR gain dB | WER out | WER mix | music-only leak dB | leak frames |", "|---|---|---|---|---|---|---|---|---|---|"]
    for s in summary:
        for g, v in s["groups"].items():
            f = lambda k: f"{v[k]:.2f}" if k in v else ""
            lines.append(f"| {s['candidate']} | {g} | {v['n']} | {f('inst_supp_db')} | {f('voice_ret_db')} | {f('sisdr_gain_db')} | {f('wer')} | {f('wer_mix')} | {f('leak_db')} | {f('leak_frames')} |")
    lines.append("")
    for s in summary:
        lines.append(f"- {s['candidate']}: real-time factor {s['rtf_stereo_1thread']} (stereo, one thread), eval took {s['seconds']} s")
    open(os.path.join(args.out, "summary.md"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
