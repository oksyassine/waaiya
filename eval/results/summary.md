| candidate | group | n | instrument suppression dB | voice retention dB | SI-SDR gain dB | WER out | WER mix | music-only leak dB | leak frames |
|---|---|---|---|---|---|---|---|---|---|
| passthrough | all voice, music +3 dB | 20 | 0.00 | -0.00 | 0.00 |  |  |  |  |
| passthrough | all voice, music -10 dB | 20 | -0.00 | 0.00 | 0.00 |  |  |  |  |
| passthrough | all voice, music -3 dB | 20 | 0.00 | 0.00 | 0.00 |  |  |  |  |
| passthrough | music_only | 5 |  |  |  |  |  | 0.00 | 1.00 |
| passthrough | recitation | 18 | 0.00 | 0.00 | 0.00 |  |  |  |  |
| passthrough | singing | 18 | 0.00 | 0.00 | 0.00 |  |  |  |  |
| passthrough | speech_ar | 12 | 0.00 | 0.00 | 0.00 |  |  |  |  |
| passthrough | speech_en | 12 | -0.00 | -0.00 | 0.00 |  |  |  |  |
| dfn3 | all voice, music +3 dB | 20 | 28.69 | -16.26 | -0.42 |  |  |  |  |
| dfn3 | all voice, music -10 dB | 20 | 24.85 | -9.79 | -6.71 |  |  |  |  |
| dfn3 | all voice, music -3 dB | 20 | 26.34 | -11.28 | -2.56 |  |  |  |  |
| dfn3 | music_only | 5 |  |  |  |  |  | -36.11 | 0.03 |
| dfn3 | recitation | 18 | 28.55 | -13.17 | -6.55 |  |  |  |  |
| dfn3 | singing | 18 | 30.01 | -24.76 | -12.62 |  |  |  |  |
| dfn3 | speech_ar | 12 | 21.28 | -2.68 | 7.11 |  |  |  |  |
| dfn3 | speech_en | 12 | 24.01 | -2.63 | 5.49 |  |  |  |  |
| dfn3_mono | all voice, music +3 dB | 20 | 28.35 | -15.96 | -0.62 |  |  |  |  |
| dfn3_mono | all voice, music -10 dB | 20 | 24.67 | -9.69 | -6.92 |  |  |  |  |
| dfn3_mono | all voice, music -3 dB | 20 | 26.38 | -11.64 | -3.74 |  |  |  |  |
| dfn3_mono | music_only | 5 |  |  |  |  |  | -36.15 | 0.03 |
| dfn3_mono | recitation | 18 | 28.44 | -13.17 | -7.10 |  |  |  |  |
| dfn3_mono | singing | 18 | 29.76 | -24.80 | -13.72 |  |  |  |  |
| dfn3_mono | speech_ar | 12 | 21.24 | -2.64 | 7.02 |  |  |  |  |
| dfn3_mono | speech_en | 12 | 23.80 | -2.53 | 5.42 |  |  |  |  |

- passthrough: real-time factor 0.0 (stereo, one thread), eval took 4.0 s
- dfn3: real-time factor 0.25 (stereo, one thread), eval took 120.8 s
- dfn3_mono: real-time factor 0.125 (stereo, one thread), eval took 68.0 s
