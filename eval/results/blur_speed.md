# Blur speed on a phone (2026-11-25)

Phone: MediaTek MT6769 (2x 2.0 GHz + 6x 1.8 GHz), Android 14. `bench_vision.c` (the real `im_vision.c`, ONNX
Runtime 1.19.2 from the app's AAR) on 30 frames from `bench_frames.py`: report-half photos with people, fitted
across a 296x640 portrait capture (the app's capture size). Median ms per frame, 2 threads, nudity model off.
Timings drift by 10-20% between runs (heat).

| pipeline | ms per frame |
|---|---|
| detector, whole frame + 3 tiles | 513 |
| detector, tiles take turns (whole frame + 1 tile) | 255 |
| + gender_v2, 3 tiles | 702 |
| + gender_v2 + seg outlines, 3 tiles (app default) | 954 |
| + nudity model every frame | 1390 |

The app switches tiles to taking turns when frames average over 60 ms, so on this phone it runs at about 0.7 s
per frame: covers lag the screen by that much.

On this PC (x86, 1 thread) the detector alone takes 24 ms: Conv 62%, SiLU 20%. gender_v2 5.3 ms and seg 7.7 ms
per crop, about 90% Conv.

## Tried, not kept

- **XNNPACK execution provider** (in the AAR): detector with tiles taking turns 255 -> 238 ms, app default
  954 -> 873 ms. About 7%, not worth a second code path.
- **Pinning to the big cores** (`taskset c0`): no change (265 ms).
- **Static int8 (QDQ) of the convolutions** (`export_vision.py qdq`, calibrated on 200 tune-half images/crops,
  percentile 99.99, per channel): models 3-4x smaller (gender 17 -> 4.7 MB, seg 12.9 -> 3.7 MB, detector 3.7 ->
  1.2 MB) but only 15-35% faster on the phone (app pipeline, tiles taking turns: 459 ms), and accuracy drops
  (tune half, male_clear 0.999):

| detector / gender | women covered | small women | men left clear |
|---|---|---|---|
| float / float | 95.3% | 93.6% | 7.5% |
| float / int8 | 95.3% | 93.6% | 4.0% |
| int8 / int8 | 93.0% | 79.3% | 5.3% |

  The int8 detector misses women; the int8 classifier loses the extreme confidence male_clear 0.999 needs.
  Quantization-aware training could fix the classifier, but the speed gain does not justify it now.
