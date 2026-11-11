# Screen blur: woman/man classifier v2

`models/vision/gender_v2.onnx`: MobileNetV3-large (timm `mobilenetv3_large_100`, ImageNet-21k weights from
Hugging Face safetensors), input 192x128, trained on 444k person crops from the Open Images V7 **train** split.
Bundled in the app from 0.2.5 with the engine default `male_clear` 0.999; v1 (`models/vision/gender.onnx`,
MobileNetV3-small, 52k test-split crops) stays in the repo for comparison.

All end-to-end numbers go through the real C code (`build/libimvision.so` built after commit 1ffd52a, "draw close
covers as one", so they differ from `blur.md`, which predates that commit). Images: the 6336 Open Images
validation images that have Woman/Man/Girl/Boy boxes, split by `md5(image id)` into a **tuning half** (3136
images) and a **reporting half** (3200 images). Thresholds are chosen on the tuning half; numbers are given on the
reporting half. Neither model ever trained on validation images. Tools: `models/vision/blur_diag.py`,
`models/vision/eval_blur.py --half report`.

## Result (reporting half, photo layout, long side 640)

Rule, fixed before looking at the reporting half: the most men left clear with at most 0.5 pt of women covered
lost on the tuning half. v1 gets 0.98 in both layouts. v2 gets 0.995 on photo and 0.999 on portrait.

| model | male_clear | women covered | men left clear | screen covered |
|---|---|---|---|---|
| no classifier (every person covered) | - | 96.8% | 2.1% | |
| v1 `gender.onnx` | 0.98 | 96.7% | 5.9% | 72.1% |
| **v2 `gender_v2.onnx`, recommended** | **0.999** (portrait rule) | **96.8%** | **9.9%** | 68.4% |
| v2, photo only | 0.995 (photo rule) | 96.6% | 16.6% | 63.1% |
| perfect classifier (oracle) | - | 94.6% | 42.8% | |

Other pre-set rules (tuning half) give the same picture: at most 1 pt lost gives v1 0.96 (96.4% / 11.4%) and v2
0.98 (95.9% / 23.4%). At at most 0.25 pt, both are near the floor: v1 0.985 (96.8% / 4.2%), v2 0.9999 (96.8% / 3.8%).

**The engine's default `male_clear` (0.98) is too low for v2.** v2's scores sit higher than v1's, and at 0.98 it
costs 0.9 pt of women covered (95.9%). Users mostly hold the phone upright, so ship v2 with `male_clear` = 0.999,
the value the portrait tuning half picks. 0.995 is the photo-only optimum, but it loses 0.9 pt of women in portrait
(below). Whoever owns `engine/` has to change the default (`im_vision.c`, `v->prm`) or the app has to set it.

## Why women are lost: mostly not the classifier

When a cleared man stands next to a woman the detector missed, she loses the incidental cover around him. Women
lost on the reporting half (photo), against every-person-covered:

| model, male_clear | men left clear | women lost | of which her own detection was cleared |
|---|---|---|---|
| v1, 0.96 | 11.4% | 20 | 14 |
| v1, 0.98 | 5.9% | 5 | 3 |
| v2, 0.995 | 16.6% | 11 | 3 |
| v2, 0.998 | 12.3% | 5 | 1 |
| v2, 0.999 | 9.9% | 3 | 0 |
| oracle | 42.8% | 95 | 0 |

At the same share of men left clear, v2 loses a third to a quarter as many women as v1. Most of what remains comes
from detector misses. Even a perfect classifier would lose 2.2 pt of women (95 of 4169), so further gains must
come from the detector or from how covers are kept, not from the classifier. For example, do not clear a man whose
cover overlaps a low-score person detection.

## Portrait phone (diagnostic a)

The image is letterboxed into a centred 16:9 strip of a 1080x2340 screen, and the whole screen is scaled to long side 640.

| reporting half | women covered | men left clear |
|---|---|---|
| every person covered, photo | 96.8% | 2.1% |
| every person covered, portrait | 86.5% | 11.3% |
| v1 0.98, portrait | 86.5% | 14.6% |
| v2 0.999, portrait (recommended) | 86.1% | 18.2% |
| v2 0.995, portrait | 85.6% | 23.7% |

With every person covered, portrait recall falls by 10 pt. On all 6336 images, women covered by height in the image
goes from 96.9% to 91.8% (large), from 95.1% to 71.7% (medium, 10-30%) and from 89.2% to 53.8% (small, under 10%). The detector loses people that are about 3x smaller on screen. **The lever here is capture size or tiling
(run the detector on the video strip at higher resolution), not the classifier.** Because more women go undetected
in portrait, v2's incidental loss is larger there, and its portrait gain over v1 stays modest (18.2% vs 14.6%
men left clear) until capture size or tiling is fixed.

## Crop mismatch (diagnostic b)

These are the same 11,442 people (validation, IsGroupOf = 0, detector box IoU >= 0.5), scored by the classifier alone.

| crop | v1 AUC | v1 men clear at 1% women | v2 AUC | v2 men clear at 1% women |
|---|---|---|---|---|
| annotator crop (original resolution) | 0.906 | 27.1% | 0.960 | 54.0% |
| annotator box, 640-px frame | 0.905 | 25.6% | | |
| YOLOX-Nano box, 640-px frame (runtime path) | 0.902 | 25.8% | 0.958 | 54.9% |

There is no meaningful mismatch, so v2 trains on annotator boxes with box jitter instead of running the detector
on the training images.

## Training (Kaggle, 2x T4, `<user>/waaiya-blur-gender`, `kaggle/blur-gender/make_notebook.py`)

- **Data.** Open Images V7 train boxes (CC BY 4.0), Woman/Man/Girl/Boy with IsGroupOf = 0. The MIAP extension is
  not used. 103k images were fetched in-notebook and resized to the 640-px frame, and people were cut with a 25%
  margin (`models/vision/prep_train_crops.py`). That gives 444k training crops (199k female, 245k male) and a 24.7k
  holdout (1% of train images) for checkpoint selection.
- **Training** (`models/vision/train_gender_v2.py`):
  - binary cross-entropy on p(man)+p(boy), plus 0.2 x the 4-class loss, with no label smoothing (the loss
    targets the blur's decision directly);
  - box jitter, the runtime's 10% context, a stretched resize, and downscaling to 0.2-1x on half the samples;
  - AdamW, cosine schedule by wall time, 100 min per model.
- **Holdout result.** Men left clear at 0.5% of women left clear: MobileNetV3-large 46.7%, MobileNetV4-conv-small
  41.0%. End to end on the tuning half it also wins (14.9% vs 11.9% men clear at the 0.5 pt rule). It was still
  improving when time ran out.

| backbone (192x128) | params | MFLOPs | x86 ms/crop, ORT 1 thread | 2 threads |
|---|---|---|---|---|
| mobilenetv3_small_100 (v1) | 1.52 M | 55 | 1.64 | 1.27 |
| **mobilenetv3_large_100 (v2)** | 4.21 M | 214 (3.9x) | 4.36 (2.7x) | 3.18 |
| mobilenetv4_conv_small | 2.50 M | 182 | 2.27 | 1.50 |
| efficientnet_b0 (over budget) | 4.01 M | 377 | 10.16 | 6.98 |

(MFLOPs = 2 x MACs, from the torch FlopCounter. Timings are on a loaded machine.) With 12 people, the per-crop figures
mean about 52 ms per frame for v2 and 20 ms for v1 on this CPU, one thread. Phone timing has not been measured.
