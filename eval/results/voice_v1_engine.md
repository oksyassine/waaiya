# voice_v1 through the C engine: the "keep singing" gate (roadmap item 6)

Date: 2026-11-20. Models: `models/voice/v3/voice_v1.onnx` (Kaggle voice-train v3, fp32, 16.1 MB) and its shrunk
variants (`models/shrink.py`): `voice_v1_int8` (2.4 MB, the file from 2026-11-09) and `voice_v1_fp16` (4.4 MB, made
today with `--fp16`). Compared with the current default `dfn3_stream_int8`. Test set: `testset/` (65 items).

Commands (repository root; numbers per item in the JSON files next to each command's `--out`):

```sh
make build/im-process
PYTHONNOUSERSITE=1 .venv/bin/python eval/evaluate.py --out /tmp/e \
  --candidate dfn3_int8=models/dfn3/dfn3_stream_int8.onnx --candidate v1_fp32=models/voice/v3/voice_v1.onnx \
  --candidate v1_int8=models/voice/v3/voice_v1_int8.onnx --candidate v1_fp16=models/voice/v3/voice_v1_fp16.onnx \
  --candidate dfn3_int8_mono=models/dfn3/dfn3_stream_int8.onnx:mono \
  --candidate v1_int8_mono=models/voice/v3/voice_v1_int8.onnx:mono
# speed and delay: build/im-process -m MODEL [--mono] --aligned on a 60 s stereo file, one core (taskset), best of 3
```

## Result

**Pass. Ship `voice_v1_fp16` (4.4 MB) as the "Keep singing (test)" model.** It scores exactly as fp32 (within
0.01 dB everywhere), runs as fast as the default model, and has the same delay. `voice_v1_int8` passes on suppression
and voice (within 0.32 dB of fp32) but lets 1.6 dB more through on music-only items (-53.3 vs -54.9 dB), which is just
over the 1 dB parity rule; fp16 removes that question for 2 MB more.

| gate | rule | voice_v1_fp16 | voice_v1_int8 | dfn3_stream_int8 (default) |
|---|---|---|---|---|
| instrument suppression, all voice items | >= 18 dB | 21.56 | 21.35 | 26.70 |
| music-only leak | <= -40 dB | -54.87 | -53.25 | -36.03 |
| singing retention | much better than dfn3 | -1.81 | -1.79 | -24.20 |
| recitation retention | | -2.67 | -2.62 | -13.26 |
| speech retention (ar / en) | | -0.92 / -0.89 | -0.92 / -0.89 | -2.69 / -2.59 |
| parity with fp32 (group means) | within 1 dB | 0.01 | supp 0.32, voice 0.05, **leak 1.63** | |
| size | fp32 fallback under 10 MB | 4.4 MB | 2.4 MB | 2.4 MB |
| delay, hop-aligned path (the Android loop) | | 30 ms | 30 ms | 30 ms |
| real-time factor, stereo / mono, one core | | 0.224 / 0.112 | 0.226 / 0.112 | 0.222 / 0.112 |

fp32 itself: real-time factor 0.226 stereo, best of 3 (0.30 as the mean over the eval run). Speed was measured with other work on the machine (load about 2.5 of 6 cores), so only the comparison
between rows holds; per-phone figures come from the diagnostics report.

## Per group (instrument suppression / voice retention, dB; SI-SDR gain dB)

| model | recitation | singing | speech_ar | speech_en | music -10 dB | music -3 dB | music +3 dB |
|---|---|---|---|---|---|---|---|
| dfn3_int8 | 28.64 / -13.26 | 30.07 / -24.20 | 21.42 / -2.69 | 24.04 / -2.59 | 24.97 / -9.41 | 26.40 / -11.45 | 28.74 / -16.02 |
| v1_fp32 | 21.90 / -2.67 | 23.24 / -1.81 | 18.03 / -0.92 | 22.03 / -0.89 | 21.22 / -0.70 | 21.06 / -1.57 | 22.38 / -2.84 |
| v1_fp16 | 21.90 / -2.67 | 23.24 / -1.81 | 18.03 / -0.92 | 22.03 / -0.89 | 21.22 / -0.70 | 21.06 / -1.57 | 22.38 / -2.84 |
| v1_int8 | 21.65 / -2.62 | 22.95 / -1.79 | 17.98 / -0.92 | 21.89 / -0.89 | 21.14 / -0.70 | 20.87 / -1.56 | 22.06 / -2.80 |
| dfn3_int8, mono | 28.56 / -13.21 | 29.83 / -24.23 | 21.37 / -2.65 | 23.83 / -2.50 | 24.80 / -9.23 | 26.46 / -11.76 | 28.42 / -15.79 |
| v1_int8, mono | 21.54 / -2.63 | 22.79 / -1.77 | 17.95 / -0.91 | 21.81 / -0.87 | 21.01 / -0.69 | 20.81 / -1.54 | 21.94 / -2.79 |

SI-SDR gain (all voice): dfn3_int8 -0.65 to -5.17 dB (it removes the singing voice with the instruments); voice_v1
+8.5 to +11.7 dB. Mono (the Android default) costs voice_v1 about 0.1 dB, as it does dfn3.

## Music-only items (leak dB, more negative = less music through)

| item | v1_fp32 | v1_fp16 | v1_int8 | dfn3_int8 |
|---|---|---|---|---|
| mean of 5 | -54.88 | -54.87 | -53.25 | -36.03 |
| worst item | -46.24 | -46.25 | -45.04 | -34.09 |

## What the user gives up with "keep singing" on

- About 5 dB less instrument suppression than the default (21.4 vs 26.7 dB on voice items). The weakest group is
  Arabic speech: 18.0 dB on average, and one item at 14.8 dB. Music alone is removed far better than by the
  default (-55 vs -36 dB), because the model was trained to silence instrument-only sound.
- Singing voices stay, by design; that is the option's purpose and the user's choice. The women's-singing detector
  still works on top of it (it gates the output from the same engine).
- The model was trained for 12,275 of 60,000 planned steps (Kaggle time budget): hence "(test)".

## Files for the models-v1 release

`voice_v1_fp16.onnx` (sha256 a849608386b55381f0db594c63e15a7530f4c258f8adc4ac59c1babf0c061f3b) and
`voice_v1_fp16.state_init.bin` (43350d1f808ed0f92f7cea0a6c33a378c3c63decd46652750c19ab9183797aea, the same zero state
as the other models); full list in `models/SHA256SUMS`. Before publishing, check the data-licence section of
`THIRD_PARTY_LICENSES.md` (docs/MODELS.md: the recitation training data is not yet cleared).

## Live switch on Android (emulator smoke check, im_ui35, debug x86_64 build)

Turning "Keep singing" on while filtering loaded voice_v1_fp16 on a helper thread in 0.84 s while the default model
kept filtering, then swapped at a hop boundary (`filter: model reloaded: voice_v1_fp16, keep singing true, failed
false`); off swapped back the same way, and the audio loop kept running (its 10 s stats lines continued). Not verified:
that no silence gap beyond the swap is heard. The test sound was not playing at the moment of the swap (hop times 0.0
ms, silent hops), and this emulator counts dropouts all the time (20-90 per 10 s), so its counter cannot show it.
