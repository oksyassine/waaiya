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

## Kept: covered people keep their verdict for a few frames (2026-11-27)

`im_vision_params.reuse_frames` (engine default 0; the Android app sets 3 in `vision_jni.c`): a person covered on
the previous frame (woman or unsure) whose box overlaps by IoU >= 0.6 keeps that p(man) instead of running the
classifier again, for up to 3 frames; then they are classified again. People left clear are classified on every
frame, and a reused p(man) that would now mean "clear" (male_clear raised) is classified again: reuse can only
keep someone covered a little longer, never uncover anyone. A man who turns clear can wait up to 3 frames longer.
The evaluation tools keep 0 (unrelated photos must not share verdicts). `models/vision/test_reuse.py` checks it
through the C library (200 photos: 853 covered people reused, then classified again; 66 clear people never reused).

This PC, 1 thread, the same 30 frames, each run 4 times in a row (a screen that stays still for a moment;
`bench_vision ... TILES_PER_FRAME REUSE_FRAMES 4`), mean ms per call over 3 interleaved rounds:

| pipeline | reuse 0 | reuse 3 |
|---|---|---|
| detector only, tiles take turns | 50 | |
| + gender_v2, tiles take turns (slow phones) | 72 | 58 (-19%) |
| + gender_v2, 3 tiles every frame | 127 | 108 (-15%) |

The classifier's share drops from ~23 to ~9 ms. Not measured on the phone; on the MT6769 (gender ~190 ms of
~450 ms with tiles taking turns) the same share would be ~450 -> ~330 ms on a still screen, less while scrolling
(boxes move and match less). The detector is now most of the frame.
