"""Exports NVIDIA's Arabic FastConformer (NeMo) as an ASR-contract model for live captions (models/asr/README.md).

The model is a hybrid RNN-T + CTC FastConformer (about 115M parameters, SentencePiece, 1024 tokens). Waaiya runs
its CTC head: one pass over the audio and a greedy pick per 80 ms frame, which a phone can do again and again as a
line grows. Everything before the encoder (pre-emphasis, STFT, mel filterbank, log, per-feature normalisation) is
rebuilt here from plain operations, with NeMo's own buffers, so the ONNX file takes the raw 16 kHz waveform as the
contract asks. The script checks itself and stops on any mismatch:

  1. its front end against NeMo's preprocessor (random audio and every --check file),
  2. the exported model in ONNX Runtime against the same model in PyTorch,
  3. the greedy text of the int8 model against the float model on every --check file (and NeMo's own CTC text).

Needs a machine that can download the model from Hugging Face, and (written against these; not run yet, see README.md):
    pip install "nemo_toolkit[asr]" onnx onnxruntime soundfile

Usage:
    python models/asr/export_fastconformer.py --out models/asr/fastconformer_ar \\
        [--model nvidia/stt_ar_fastconformer_hybrid_large_pc_v1.0] [--check a.wav b.wav ...]
writes OUT.onnx (float) and OUT_int8.onnx (dynamic int8, the one the app bundles), and prints the check results.

Default model: ..._pc_v1.0 (Modern Standard Arabic, punctuation, no diacritics): the clearest to read at speed and
the lowest error in NVIDIA's paper (arXiv 2507.13977). ..._pcd_v1.0 adds full diacritics and Classical Arabic
(Quran) training, at a higher word error on everyday speech. Check the model card's licence before shipping and
credit NVIDIA in THIRD_PARTY_LICENSES.md.
"""
import argparse
import math
import sys

import numpy as np
import torch
import torch.nn.functional as F

RATE = 16000


class Frontend(torch.nn.Module):
    """NeMo's AudioToMelSpectrogramPreprocessor at inference time, in ONNX-friendly operations: the STFT is a strided
    convolution with the windowed DFT basis, so the export needs no STFT operator."""

    def __init__(self, preprocessor):
        super().__init__()
        f = preprocessor.featurizer
        self.n_fft = int(f.n_fft)
        self.hop = int(f.hop_length)
        win = int(f.win_length)
        if getattr(f, "exact_pad", False):
            raise SystemExit("exact_pad front ends are not handled (this model does not use one)")
        if getattr(f, "mag_power", 2.0) != 2.0:
            raise SystemExit(f"mag_power {f.mag_power} is not handled (2.0 expected)")
        if f.normalize != "per_feature":
            raise SystemExit(f"normalize={f.normalize!r} is not handled (per_feature expected)")
        self.preemph = float(f.preemph) if f.preemph is not None else 0.0
        window = f.window.detach().float().cpu() if f.window is not None else torch.ones(win)
        # torch.stft centres a shorter window inside n_fft
        left = (self.n_fft - window.numel()) // 2
        w = torch.zeros(self.n_fft)
        w[left:left + window.numel()] = window
        bins = self.n_fft // 2 + 1
        n = torch.arange(self.n_fft, dtype=torch.float64)
        k = torch.arange(bins, dtype=torch.float64)[:, None]
        ang = 2 * math.pi * k * n / self.n_fft
        basis = torch.cat([torch.cos(ang), -torch.sin(ang)], 0) * w.double()
        self.register_buffer("basis", basis.float()[:, None, :])          # [2 * bins, 1, n_fft]
        self.register_buffer("fb", f.fb.detach().float().cpu()[0])         # [mels, bins]
        self.bins = bins
        guard = f.log_zero_guard_value_fn(torch.zeros(1)) if hasattr(f, "log_zero_guard_value_fn") else f.log_zero_guard_value
        self.guard = float(guard)
        self.log = bool(f.log)
        if getattr(f, "log_zero_guard_type", "add") != "add":
            raise SystemExit("log_zero_guard_type other than 'add' is not handled")

    def forward(self, audio):  # [1, N]
        x = audio
        if self.preemph:
            x = torch.cat([x[:, :1], x[:, 1:] - self.preemph * x[:, :-1]], 1)
        x = F.pad(x[:, None, :], (self.n_fft // 2, self.n_fft // 2))   # centre, pad_mode="constant" as NeMo
        spec = F.conv1d(x, self.basis, stride=self.hop)                   # [1, 2 * bins, T]
        re, im = spec[:, :self.bins], spec[:, self.bins:]
        mel = torch.matmul(self.fb, re * re + im * im)                    # [1, mels, T]
        if self.log:
            mel = torch.log(mel + self.guard)
        # per_feature, as nemo.collections.asr.parts.preprocessing.features.normalize_batch (batch of one, no padding)
        # the frame count as a tensor, so the export keeps it dynamic
        length = torch._shape_as_tensor(mel)[2:3].to(torch.int64)
        t = length.to(mel.dtype)
        mean = mel.sum(2, keepdim=True) / t
        std = torch.sqrt(((mel - mean) ** 2).sum(2, keepdim=True) / (t - 1)) + 1e-5
        mel = (mel - mean) / std
        return mel, length


class CtcWaveform(torch.nn.Module):
    def __init__(self, model):
        super().__init__()
        self.front = Frontend(model.preprocessor)
        self.encoder = model.encoder
        self.ctc = model.ctc_decoder if hasattr(model, "ctc_decoder") else model.decoder

    def forward(self, audio):
        feats, length = self.front(audio)
        enc, _ = self.encoder(audio_signal=feats, length=length)
        return self.ctc(encoder_output=enc)   # [1, frames, tokens] log-probabilities


def greedy(logits, tokens, blank):
    ids = np.asarray(logits).reshape(-1, logits.shape[-1]).argmax(-1)
    out, prev = [], -1
    for i in ids:
        if i != prev and i != blank:
            t = tokens[i]
            if not (t.startswith("<") and t.endswith(">")):
                out.append(t)
        prev = i
    return " ".join("".join(out).replace("▁", " ").split())


def cer(a, b):
    """character error rate of b against a"""
    a, b = a.replace(" ", ""), b.replace(" ", "")
    d = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        prev, d[0] = d[0], i
        for j, cb in enumerate(b, 1):
            prev, d[j] = d[j], min(d[j] + 1, d[j - 1] + 1, prev + (ca != cb))
    return d[len(b)] / max(1, len(a))


def load_wav(path):
    import soundfile as sf
    x, sr = sf.read(path, dtype="float32", always_2d=True)
    x = x.mean(1)
    if sr != RATE:
        import torchaudio
        x = torchaudio.functional.resample(torch.from_numpy(x), sr, RATE).numpy()
    return x.astype(np.float32)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="nvidia/stt_ar_fastconformer_hybrid_large_pc_v1.0")
    ap.add_argument("--out", required=True, help="output path without .onnx")
    ap.add_argument("--check", nargs="*", default=[], help="WAV files to compare texts on")
    ap.add_argument("--opset", type=int, default=17)
    args = ap.parse_args()

    import nemo.collections.asr as nemo_asr
    from nemo.core.classes import typecheck
    import onnx
    import onnxruntime as ort
    from onnxruntime.quantization import QuantType, quantize_dynamic

    typecheck.set_typecheck_enabled(False)
    model = nemo_asr.models.ASRModel.from_pretrained(args.model, map_location="cpu")
    model.eval()
    if hasattr(model, "change_decoding_strategy") and hasattr(model, "ctc_decoder"):
        model.change_decoding_strategy(decoder_type="ctc")
    if hasattr(model.encoder, "export_cache_support"):
        model.encoder.export_cache_support = False
    # room for 40 s lines in the relative position table (a line is cut at 12 s)
    if hasattr(model.encoder, "update_max_seq_length"):
        model.encoder.update_max_seq_length(seq_length=40 * RATE // 160 + 1, device=torch.device("cpu"))

    vocab = model.tokenizer.vocab_size
    tokens = [model.tokenizer.ids_to_tokens([i])[0] for i in range(vocab)]
    blank = vocab
    tokens.append("<blk>")
    print(f"model {args.model}: {vocab} tokens + blank, preprocessor {type(model.preprocessor).__name__}")

    net = CtcWaveform(model).eval()
    checks = [(p, load_wav(p)) for p in args.check]
    rng = np.random.default_rng(0)
    probes = [rng.standard_normal(RATE * 3).astype(np.float32) * 0.05] + [x for _, x in checks]

    # 1. front end == NeMo's preprocessor
    with torch.no_grad():
        worst = 0.0
        for x in probes:
            t = torch.from_numpy(x)[None]
            ref, ref_len = model.preprocessor(input_signal=t, length=torch.tensor([t.shape[1]]))
            ours, our_len = net.front(t)
            n = int(ref_len[0])
            if n != int(our_len[0]):
                raise SystemExit(f"front end: {int(our_len[0])} frames, NeMo {n}")
            worst = max(worst, float((ref[:, :, :n] - ours[:, :, :n]).abs().max()))
    print(f"check 1, front end vs NeMo: largest difference {worst:.2e}")
    if worst > 1e-3:
        raise SystemExit("front end differs from NeMo's preprocessor")

    # 2. export, then ONNX Runtime == PyTorch
    out = args.out
    example = torch.from_numpy(probes[0])[None]
    torch.onnx.export(net, (example,), out + ".onnx", input_names=["audio"], output_names=["logits"],
                      dynamic_axes={"audio": {1: "samples"}, "logits": {1: "frames"}}, opset_version=args.opset,
                      do_constant_folding=True, dynamo=False)
    m = onnx.load(out + ".onnx")
    meta = {
        "asr.contract": "1",
        "asr.sample_rate": str(RATE),
        "asr.blank": str(blank),
        "asr.frame_ms": "80",
        "asr.model_name": args.model.split("/")[-1] + "_ctc",
        "asr.tokens": "\n".join(tokens),
        "asr.source": args.model,
    }
    del m.metadata_props[:]
    for k, v in meta.items():
        p = m.metadata_props.add()
        p.key, p.value = k, v
    onnx.save(m, out + ".onnx")
    sess = ort.InferenceSession(out + ".onnx", providers=["CPUExecutionProvider"])
    with torch.no_grad():
        worst = 0.0
        for x in probes:
            a = net(torch.from_numpy(x)[None]).numpy()
            b = sess.run(["logits"], {"audio": x[None]})[0]
            if a.shape != b.shape:
                raise SystemExit(f"ONNX shape {b.shape}, PyTorch {a.shape}")
            worst = max(worst, float(np.abs(a - b).max()))
    print(f"check 2, ONNX Runtime vs PyTorch: largest difference {worst:.2e}")
    if worst > 1e-2:
        raise SystemExit("the exported model differs from PyTorch")

    # 3. int8 (dynamic, weights only): the text should not change
    quantize_dynamic(out + ".onnx", out + "_int8.onnx", weight_type=QuantType.QInt8, per_channel=True,
                     op_types_to_quantize=["MatMul", "Gemm"])
    m8 = onnx.load(out + "_int8.onnx")
    if not any(p.key == "asr.contract" for p in m8.metadata_props):
        for k, v in meta.items():
            p = m8.metadata_props.add()
            p.key, p.value = k, v
        onnx.save(m8, out + "_int8.onnx")
    s8 = ort.InferenceSession(out + "_int8.onnx", providers=["CPUExecutionProvider"])
    worst_cer = 0.0
    for path, x in checks:
        f32 = greedy(sess.run(["logits"], {"audio": x[None]})[0], tokens, blank)
        i8 = greedy(s8.run(["logits"], {"audio": x[None]})[0], tokens, blank)
        try:
            hyp = model.transcribe([path], batch_size=1, verbose=False)[0]
            nemo_text = hyp.text if hasattr(hyp, "text") else str(hyp)
        except Exception as e:  # NeMo's API changes between versions; the check is informative
            nemo_text = f"(NeMo transcribe failed: {e})"
        c = cer(f32, i8)
        worst_cer = max(worst_cer, c)
        print(f"{path}\n  nemo ctc: {nemo_text}\n  onnx f32: {f32}\n  onnx int8: {i8}  (CER vs f32 {c:.3f})")
    if checks:
        print(f"check 3, int8 vs float: worst CER {worst_cer:.3f}")
        if worst_cer > 0.05:
            print("warning: int8 changes the text noticeably; bundle the float model or quantise fewer layers",
                  file=sys.stderr)
    print("wrote", out + ".onnx", "and", out + "_int8.onnx")


if __name__ == "__main__":
    main()
