# Screen blur, end to end (2000 Open Images validation images, long side 640)

- person model: `person_yolox_nano.onnx`; gender model: `none (every person covered)`
- params: person_score 0.10, male_clear 0.95, nms 0.50, margin 0.20

| measure | all | large (h>=30%) | medium (10-30%) | small (<10%) | group boxes |
|---|---|---|---|---|---|
| women covered | 93.6% (2439) | 95.8% (1848) | 92.3% (349) | 88.4% (112) | 71.5% (130) |
| men left clear | 4.0% (2955) | 0.7% (1851) | 4.0% (751) | 32.2% (214) | 4.3% (139) |

- screen covered: mean 70.8%
- time per frame (models + tracker, 2 threads, this machine): median 17.1 ms, p95 20.8 ms
