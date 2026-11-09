# voice_v1 (Kaggle voice-train v3) — local check through the C engine

Date: 2026-11-09. Trained 12,275 of 60,000 planned steps (Kaggle time budget). Files: models/voice/v3/ (not in git).
Local fp32 numbers match the Kaggle eval exactly. int8 (models/shrink.py --int8, 2.4 MB) is within 0.3 dB everywhere.
int8 RTF was measured while another latency benchmark was running on the same CPU, so the speed numbers are not comparable.

Baseline (current default dfn3): singing retention -24.8 dB, recitation -13.2 dB, suppression 21-30 dB, music-only leak -36.1 dB.

| candidate | group | n | instrument suppression dB | voice retention dB | SI-SDR gain dB | WER out | WER mix | music-only leak dB | leak frames |
|---|---|---|---|---|---|---|---|---|---|
| v1_fp32 | all voice, music +3 dB | 20 | 22.38 | -2.84 | 11.71 |  |  |  |  |
| v1_fp32 | all voice, music -10 dB | 20 | 21.22 | -0.70 | 8.49 |  |  |  |  |
| v1_fp32 | all voice, music -3 dB | 20 | 21.06 | -1.57 | 9.72 |  |  |  |  |
| v1_fp32 | music_only | 5 |  |  |  |  |  | -54.88 | 0.00 |
| v1_fp32 | recitation | 18 | 21.90 | -2.67 | 8.19 |  |  |  |  |
| v1_fp32 | singing | 18 | 23.24 | -1.81 | 11.09 |  |  |  |  |
| v1_fp32 | speech_ar | 12 | 18.03 | -0.92 | 9.51 |  |  |  |  |
| v1_fp32 | speech_en | 12 | 22.03 | -0.89 | 11.44 |  |  |  |  |
| v1_int8 | all voice, music +3 dB | 20 | 22.06 | -2.80 | 11.69 |  |  |  |  |
| v1_int8 | all voice, music -10 dB | 20 | 21.14 | -0.70 | 8.51 |  |  |  |  |
| v1_int8 | all voice, music -3 dB | 20 | 20.87 | -1.56 | 9.75 |  |  |  |  |
| v1_int8 | music_only | 5 |  |  |  |  |  | -53.25 | 0.00 |
| v1_int8 | recitation | 18 | 21.65 | -2.62 | 8.26 |  |  |  |  |
| v1_int8 | singing | 18 | 22.95 | -1.79 | 11.07 |  |  |  |  |
| v1_int8 | speech_ar | 12 | 17.98 | -0.92 | 9.51 |  |  |  |  |
| v1_int8 | speech_en | 12 | 21.89 | -0.89 | 11.42 |  |  |  |  |

- v1_fp32: real-time factor 0.272 (stereo, one thread), eval took 129.9 s
- v1_int8: real-time factor 0.345 (stereo, one thread), eval took 159.8 s
