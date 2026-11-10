# Low-delay voice model (look-ahead 0 = 10 ms): local check through the C engine

Date: 2026-11-09. Delay is the model's algorithmic delay on the engine's hop-aligned path
(`im.latency_samples`): (n_fft − hop) + look-ahead × hop at 48 kHz. dfn3 and voice_v1 have 30 ms, look-ahead 1
has 20 ms and look-ahead 0 has 10 ms. The audio-server pipeline adds its own delay on top (see `latency.md`).

## How the look-ahead was lowered

DeepFilterNet3 applies its 2-frame look-ahead only as a time alignment: `DfNet.pad_feat` shifts the features
2 frames left, and the deep filter (order 5) spans frames t−2..t+2. The weights do not depend on it, so the same
checkpoint runs at look-ahead 0 (features unshifted, deep filter on frames t−4..t). `export_stream.py` and
`train.py` now take the look-ahead as a parameter (`--lookahead`). Streaming parity holds at every value:

| look-ahead | delay | stream vs offline PyTorch | ORT vs PyTorch | C engine (any block / `--aligned`) |
|---|---|---|---|---|
| 2 | 30 ms | 122.1 dB | 2.3e-8 max err | 105.4 / 105.4 dB |
| 1 | 20 ms | 118.6 dB | 2.4e-8 max err | 105.4 / 105.4 dB |
| 0 | 10 ms | 121.6 dB | 2.0e-8 max err | 105.4 / 105.4 dB |

The la=2 export of the v1 checkpoint is bit-identical to the shipped `voice_v1.onnx` (the state layout is unchanged:
31240 floats at every look-ahead).

Moving trained weights to a smaller look-ahead without any other change puts the deep filter's "current frame" tap
on frame t−2. The band below ~5 kHz (nb_df = 96 bins) then comes out 20 ms late, and SI-SDR collapses even though
the level metrics look fine. `export_stream.shift_df_taps` moves each tap by (old − new look-ahead), dropping the
taps that would need future frames. `train.py` does this automatically when its starting weights have a different
look-ahead.

## Starting points (voice_v1 weights, no training at the new look-ahead)

| candidate | delay | group | instrument suppression dB | voice retention dB | SI-SDR gain dB | music-only leak dB |
|---|---|---|---|---|---|---|
| voice_v1 (reference) | 30 ms | recitation / singing | 21.90 / 23.24 | −2.67 / −1.81 | 8.19 / 11.09 | −54.88 |
| | | speech_ar / speech_en | 18.03 / 22.03 | −0.92 / −0.89 | 9.51 / 11.44 | |
| v1 weights, la=0, taps not moved | 10 ms | recitation / singing | 20.01 / 18.31 | −2.84 / −2.46 | **−28.25 / −28.79** | −54.52 |
| | | speech_ar / speech_en | 12.79 / 17.25 | −1.52 / −1.31 | −23.92 / −33.02 | |
| v1 weights, la=0, taps moved | 10 ms | recitation / singing | 19.72 / 19.42 | −3.80 / −3.51 | 7.25 / 8.45 | −51.70 |
| | | speech_ar / speech_en | 15.03 / 18.44 | −3.53 / −1.45 | 4.92 / 8.30 | |
| v1 weights, la=1, taps moved | 20 ms | recitation / singing | 20.99 / 21.63 | −2.83 / −2.10 | 7.97 / 10.11 | −54.20 |
| | | speech_ar / speech_en | 17.07 / 20.93 | −1.46 / −1.04 | 8.09 / 10.48 | |

Even before any fine-tuning, look-ahead 1 is within about 1 dB of voice_v1, and look-ahead 0 loses about 2–3 dB of
suppression and 1–2.6 dB of voice retention. Fine-tuning at the new look-ahead is meant to win this back.

## Fine-tuned look-ahead 0 (Kaggle `KAGGLE_USER/islamic-mute-voice-lowdelay`)

Recipe: same data and settings as voice v3 (`kaggle/voice-lowdelay/`; DATA_HOURS, voice weights, batch 16, lr 5e-5,
warmup + cosine schedule, 5 h budget on a T4). It starts from the voice_v1 checkpoint (`KAGGLE_USER/islamic-mute-voice-v1-ckpt`,
step 12,275) with the taps moved, and trains with `--lookahead 0`.

_Pending: the run has not finished yet._
