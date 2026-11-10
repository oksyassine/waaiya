# Screen blur, end to end (2000 Open Images validation images, long side 640)

- person model: `person_yolox_nano.onnx`; gender model: `gender.onnx`
- params: person_score 0.10, male_clear 0.98, nms 0.50, margin 0.20

| measure | all | large (h>=30%) | medium (10-30%) | small (<10%) | group boxes |
|---|---|---|---|---|---|
| women covered | 93.2% (2439) | 95.4% (1848) | 91.7% (349) | 87.5% (112) | 71.5% (130) |
| men left clear | 8.8% (2955) | 7.4% (1851) | 6.1% (751) | 33.6% (214) | 4.3% (139) |

- screen covered: mean 66.5%
- time per frame (models + tracker, 2 threads, this machine): median 21.9 ms, p95 38.2 ms

## Choosing male_clear (the same 2000 images)

| male_clear | women covered | men left clear |
|---|---|---|
| no gender model (every person covered) | 93.6% | 4.0% |
| 0.99 | 93.6% | 5.1% |
| **0.98 (default)** | **93.2%** | **8.8%** |
| 0.95 | 91.8% | 17.3% |

The classifier (`models/vision/train_gender.py`, MobileNetV3-small on 52k Open Images person crops, 82% woman/man
accuracy on held-out crops) is the weak part: a stricter threshold gives back few men, a looser one uncovers women.
0.98 costs 0.4 points of women covered. Next step: train on the Open Images train split (many more crops) and a
larger backbone on a GPU.

What these numbers do not measure: video (motion, the overlay delay), phone speed, and nudity (no explicit test
images are collected; on 1000 ordinary photos the nudity model flags 1.9%, mostly bikinis and lingerie).
