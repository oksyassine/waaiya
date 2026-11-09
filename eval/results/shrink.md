# Shrinking the streaming model (DFN3): fp16 / int8 variants

Date: 2026-11-09. Input: `models/dfn3/dfn3_stream.onnx` (16.1 MB, 4.0 M float32 weights).
Tool: `models/shrink.py`. Scorer: `kaggle/eval_onnx.py` (Python ORT 1.19.2, 65 test items).
Its fp32 numbers match `summary.md` (C engine) to 0.01 dB. Per-item rows for every variant are
in `eval/results/shrink_rows.json`.

## Result

**Ship `dfn3_stream_int8.onnx`: 2.4 MB, 6.6x smaller, same speed, and within 0.2 dB of fp32 on
every group average.** `dfn3_stream_fp16.onnx` (4.4 MB) is the "no measurable change" fallback.
Neither variant is faster. On x86 ORT CPU none of the quantization routes made this model faster
(see Speed).

| variant | file | size MB | RTF stereo (C engine) | RTF mono (Python) | instr. supp. dB (all) | voice ret. dB (all) | music-only leak dB | worst group Δ supp / Δ ret vs fp32 | verdict |
|---|---|---|---|---|---|---|---|---|---|
| fp32 (input) | dfn3_stream.onnx | 16.12 | 0.262 | 0.128 | 26.63 | -12.44 | -36.11 | — | reference |
| fp32 + DFT rebuild | (`--fp32`, not kept) | 8.74 | 0.266 | 0.130 | 26.63 | -12.44 | -36.11 | -0.00 / -0.00 | lossless |
| **fp16 weights** | dfn3_stream_fp16.onnx | 4.43 | 0.276 | 0.127 | 26.63 | -12.44 | -36.11 | -0.00 / -0.00 | pass, identical |
| fp16 compute (onnxconverter-common) | (not kept) | 8.13 | **1.52** | 0.743 | 26.11 | -14.68 | -32.48 | -1.87 / **-5.10** | fail: slow and broken |
| **int8 weights** | dfn3_stream_int8.onnx | **2.44** | 0.266 | 0.129 | 26.70 | -12.29 | -36.03 | +0.03 / -0.17 | **pass, recommended** |
| int8 dynamic, DSP excluded | (not kept) | 16.02 | 0.351 | 0.151 | 26.53 | -12.61 | -35.82 | -0.20 / -0.33 | pass but useless (no shrink, slower) |
| int8 dynamic, everything | (not kept) | 10.41 | 0.232 | 0.119 | 25.19 | -20.78 | -29.89 | -3.01 / **-10.61** | fail |

The worst-group Δ is the minimum over the 4 categories and the 3 music levels (negative = worse
than fp32). Acceptance was within about 1 dB on suppression and voice retention. RTF is compute
time / audio time on one thread. The C engine figure is `build/im-process` on a 60 s stereo file
(best of 3). The Python figure is `sess.run` per 10 ms hop, mono, best of 3.

### Per category (instrument suppression / voice retention, dB; music-only leak)

| variant | recitation | singing | speech_ar | speech_en | music-only leak |
|---|---|---|---|---|---|
| fp32 | 28.55 / -13.17 | 30.01 / -24.76 | 21.28 / -2.68 | 24.01 / -2.63 | -36.11 |
| fp32 + DFT rebuild | 28.55 / -13.17 | 30.01 / -24.76 | 21.28 / -2.68 | 24.01 / -2.63 | -36.11 |
| fp16 weights | 28.55 / -13.17 | 30.01 / -24.76 | 21.28 / -2.68 | 24.01 / -2.63 | -36.11 |
| fp16 compute | 27.78 / -15.23 | 29.95 / -29.86 | 21.29 / -2.91 | 22.68 / -2.85 | -32.48 |
| int8 weights | 28.64 / -13.26 | 30.07 / -24.20 | 21.42 / -2.69 | 24.04 / -2.59 | -36.03 |
| int8 dynamic, DSP excl. | 28.48 / -13.39 | 29.86 / -25.02 | 21.13 / -2.66 | 24.03 / -2.79 | -35.82 |
| int8 dynamic, all | 27.53 / -22.55 | 27.00 / -35.18 | 20.47 / -9.18 | 23.66 / -8.11 | -29.89 |

### Per music level (all voice categories; supp / ret, dB) and SI-SDR gain

| variant | music -10 dB | music -3 dB | music +3 dB | SI-SDR gain |
|---|---|---|---|---|
| fp32 | 24.85 / -9.79 | 26.34 / -11.28 | 28.69 / -16.26 | -3.23 |
| fp32 + DFT rebuild | 24.85 / -9.79 | 26.34 / -11.28 | 28.69 / -16.26 | -3.23 |
| fp16 weights | 24.85 / -9.78 | 26.34 / -11.28 | 28.69 / -16.26 | -3.25 |
| fp16 compute | 22.98 / -11.21 | 26.54 / -14.57 | 28.82 / -18.26 | -5.54 |
| int8 weights | 24.97 / -9.41 | 26.40 / -11.45 | 28.74 / -16.02 | -2.63 |
| int8 dynamic, DSP excl. | 24.80 / -10.12 | 26.32 / -11.48 | 28.49 / -16.24 | -3.31 |
| int8 dynamic, all | 21.98 / -14.66 | 25.53 / -20.79 | 28.06 / -26.87 | -12.55 |

### Per item (int8 weights vs fp32)

- All 24 speech items are within 0.5 dB on voice retention.
- Instrument suppression moves between -0.23 and +0.51 dB per item.
- Music-only leak moves by at most +0.16 dB.
- Larger per-item swings happen only where fp32 already removes the voice by 13–60 dB:
  - recitation_60000 and singing_0/200: -0.6 to -1.9 dB.
  - singing_900: +6 to +10 dB, on items where fp32 is at -44 to -61 dB.

  These are tiny changes in an already-closed mask, and they cancel out in the averages. The
  output waveform differs from fp32 by about 15–30 dB SNR, because the GRUs drift slightly.
  The metrics show no audible-level difference, but a listen on singing is worth doing.
- fp16 weights differ from fp32 by at most 0.06 dB on any item. Waveform SNR vs fp32 is
  about 60 dB.

## What each variant does (and why the obvious routes fail)

- **DFT rebuild (lossless, used by the fp16 and int8 variants).** 46 % of DFN3's weights
  (1.85 M of 4.0 M) are the STFT/ISTFT cos/sin tables `fwd_re/fwd_im/inv_re/inv_im`.
  `shrink.py` detects any (N, N/2+1) matrix that equals `scale[k]·cos|sin(2πnk/N)` and replaces
  it with Range/Mod/Cos/Sin nodes. ORT constant-folds those nodes when the session loads, so
  the tables cost no file size and no run time. Output SNR is 122 dB vs the stored tables.
- **fp16 weights.** Weights are stored as float16 and Cast back to float32 at load (folded).
  The math stays float32.
- **int8 weights.** Weights are stored as int8 with symmetric scales:
  - one scale per output channel for Conv,
  - one per gate row for GRU,
  - one per group and output for the grouped-linear Einsums.

  Cast(int8→float)·scale at load rebuilds the float weights. The first attempt used
  DequantizeLinear, but ORT does not fold it (it keeps it for QDQ fusion) and it cost 25 % speed.
  Cast+Mul is folded. The DSP matrices are never quantized: the ERB filterbanks stay float32,
  and the DFT tables are rebuilt.
- **Why not real int8 compute (`quantize_dynamic`)?**
  - ORT only has integer kernels for Conv and MatMul. It has none for GRU or Einsum, which
    hold 52 % of the weights and do most of the work.
  - The only MatMuls in DFN3 are the DSP ones. Quantizing them ("everything") quantizes the raw
    audio and spectrum to 8 bits per frame. That costs 6–10 dB of voice and 6 dB of leak.
  - With the DSP excluded, only the small convs become integer. File size does not change and
    the result is 15–35 % slower, because of the per-hop quantize/dequantize overhead.
  - ORT CPU ConvInteger also only accepts uint8 weights, so `shrink.py` uses QUInt8 there.
- **Why not fp16 compute (onnxconverter-common, keep_io_types=True)?** ORT 1.19 loads it, but
  the float16 CPU kernels are about 6x slower: RTF 1.5 stereo, which is not real-time. The
  float16 power spectrum and log features also underflow on quiet input, which costs 5 dB of
  voice on singing and 3.6 dB of leak. The CPU float16 kernels are of no use here. (GPU and
  NNAPI are out of scope.)

## Speed: where the time goes

Profiling the fp32 model per hop on one thread shows:

| GRU | DFT MatMuls | Conv | Einsum | Concat, Reshape, Slice (glue) |
|---|---|---|---|---|
| ~26 % | ~22 % | 8 % | 8 % | ~20 % |

At about 4 M multiply-adds per 10 ms hop, the model is dominated by per-node overhead and memory,
not by arithmetic. That is why weight quantization does not speed it up. If speed matters later,
the levers are:

- Replace the 960×481 DFT MatMuls with the ONNX `DFT` op or a real FFT. This could cut up to
  about 20 %.
- Fewer glue nodes in the export.
- A smaller network (fine-tuning a narrower model).

None of these involve quantization.

## Reproduce / apply to another model

```sh
PYTHONNOUSERSITE=1 .venv/bin/python models/shrink.py models/voice/voice_v1.onnx --int8 --fp16 -o models/voice
#  -> models/voice/voice_v1_int8.onnx + voice_v1_int8.state_init.bin   (im.model_name=voice_v1_int8)
#  -> models/voice/voice_v1_fp16.onnx + voice_v1_fp16.state_init.bin   (im.model_name=voice_v1_fp16)
PYTHONNOUSERSITE=1 .venv/bin/python kaggle/eval_onnx.py fp32=models/voice/voice_v1.onnx \
    int8=models/voice/voice_v1_int8.onnx fp16=models/voice/voice_v1_fp16.onnx
```

`shrink.py` checks each output loads, has the contract IO (all float32) and the `im.*` metadata.
It also prints the waveform SNR vs the input model. It prints which initializers it treated as DSP
(never quantized) and which DFT tables it rebuilt. If a fine-tuned model has a learned MatMul
weight that does not end in `.weight`, it is conservatively kept float32. If the model has a DSP
constant under an unusual name, add it with `--keep-float NAME`. The other modes are
`--fp32`, `--fp16-mode compute` and `--int8-mode dynamic|dynamic-all`, kept for comparison only.
