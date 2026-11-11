# Screen blur: covers that follow the body (silhouette strips)

A user on a Samsung S24 found the covers too big. Text right next to a person was hidden, and people standing close
together were joined into one big box. Now a small person segmenter outlines each covered person. The tracker
draws the outline as a stack of horizontal strips, one per row of the person's box, instead of the whole
rectangle.

All numbers go through the real C code (`build/libimvision.so`) via ctypes, with the app's models and defaults:
YOLOX-Nano with tiles, `gender_v2.onnx` at male_clear 0.999, margin 0.20, merge_gap 0.30, hold and lead as shipped.
Each image is resized to long side 640, like a phone capture, and is a single frame (no motion).

## What changed

- **Segmenter** `models/vision/seg.onnx` (12.9 MB, im.kind = segmenter): torchvision LR-ASPP MobileNetV3-large,
  COCO weights, with the head cut to one "this person" output. Fine-tuned on Open Images V7 person masks
  (train split, 132k crops from 70k images, 2x T4, about 75 min to the best holdout checkpoint; `kaggle/blur-seg/`).
  Input: the person's box plus 20% context on each side, stretched to 192x128. Output: p(person) at 24x16.
  Holdout (1% of train images): IoU 0.865 at 0.5. Mean share of each mask above 0.2: 98.0%.
- **Outline** (`im_vision.c segment()`): this runs on WOMAN/UNSURE people only. It covers the 6 largest per frame
  (`seg_max_people`) that are at least 48 px tall (`seg_min_px`). Each of 16 rows keeps its leftmost and rightmost
  pixel with p >= 0.15. Empty rows between covered rows are filled. Each row is widened to its neighbours.
  A row that touches the side of the crop stays open to that side.
- **Strips** (`im_cover.c`): the track carries the outline relative to its box, so strips move and scale with the
  box and get the same motion lead. Each strip gets a 0.05 margin and is clipped to the person's old rectangle.
  When the body goes past the top or bottom of the crop (the detector cut the box short), that end strip reaches
  0.8 of the person's height past the box (`open_reach`).
- **Fail closed**: the person gets the whole rectangle when any of these holds:
  - no segmenter is loaded;
  - the model fails;
  - the mask fills less than 25% of the box;
  - the person is beyond the cap or too small;
  - the covers show in the capture;
  - the output has no room for all of that person's strips (an outline is never cut in part).
- **Groups**: merge_gap joins rectangles only. An outlined person instead gets a **bridge** to each close
  neighbour (`bridge_gap` 0.30): a rect between their centres, at the height they share.
- **Drawing**: strips and bridges carry the `IM_VK_PART` flag and are drawn with square corners.
  The window host tints their union once. Buffers grew from 64 to 256 rects (JNI, ScreenBlur, Shizuku layers).
- FULL (nudity) covers are unchanged: still the whole frame.

## Result: Open Images V7 **test** person masks (reporting; never used to tune)

The test split has 1509 images with 1710 Woman/Girl masks (large 1371, medium 298, small 41; size = box height /
image height). The defaults were chosen on the validation split (494 images, 568 masks); see the sweep below.

| covers | woman px covered | women >= 99% covered | women >= 95% | large / medium / small px | man px covered | background covered (in and around women) | screen covered |
|---|---|---|---|---|---|---|---|
| rectangles (today) | **98.55%** | 97.4% | 97.8% | 99.08 / 98.66 / 97.93% | 96.5% | **81.5%** | 82.6% |
| **strips + bridges (new default)** | **98.52%** | 96.1% | 97.3% | 99.05 / 98.18 / 90.61% | 95.9% | **50.8%** | 69.9% |
| strips, no bridges | 98.50% | 95.3% | 96.8% | 98.99 / 97.34 / 90.44% | 93.9% | 45.7% | 66.3% |
| strips + bridges, COCO weights as is (no fine-tuning) | 98.42% | 94.4% | 96.8% | 98.92 / 98.53 / 93.05% | 96.5% | 58.9% | 74.0% |

- **Woman pixels covered: 98.52% vs 98.55%**, which is 99.97% of what rectangles cover (target: >= 99%).
- **Background covered drops from 81.5% to 50.8%.** This measures the non-person pixels in and around each woman:
  her box widened by half its size on each side. Person-like boxes without a mask are left out.
- Screen covered drops from 82.6% to 69.9%. These images are mostly people, so a screen with text has more to gain.
- Fallback to the whole rectangle (outline not trusted): 0.1% of 5966 outlined people.
- Small women lose 7 pt (90.6% vs 97.9%; 41 masks). 3 of the 41 lose 5 pt or more. All 3 were missed by the
  detector, and only the old group box covered them. Bridges cover the space between people only at the height they
  share and between their centres. Setting `bridge_gap` higher, or keeping merge_gap for groups of small people,
  would get this back, at the cost of text between people.
- Fine-tuning paid off. Against the COCO weights it covers fewer background pixels (50.8% vs 58.9%). It also
  covers more women fully (96.1% vs 94.4% have >= 99% of their mask covered). COCO weights fall back to the
  rectangle for 9% of people, versus 0.1%.

Box-based end-to-end score (`eval_blur.py --half report`, 3200 validation images; the measure used so far):

| | women covered (>= 90% of box) | woman box area covered | men left clear | screen covered |
|---|---|---|---|---|
| rectangles | 96.5% | 98.0% | 8.0% | 69.8% |
| strips + bridges | 79.3% | 93.5% | 9.4% | 57.4% |

"Women covered" falls by design: an outline leaves the corners of the box free. A woman's box is mostly corners
when her arms are down. That is why this report scores mask pixels instead.

## Choosing the defaults (validation split)

| setting | woman px | >= 99% | background | screen |
|---|---|---|---|---|
| rectangles | 97.78% | 96.3% | 80.3% | 82.9% |
| thr 0.25, margin 0.05, bridges, open_reach 0.2 (first design) | 97.24% | 93.1% | 42.0% | 65.7% |
| thr 0.15, margin 0.05, bridges, open_reach 0.2 | 97.33% | 93.5% | 44.6% | 66.7% |
| thr 0.15, margin 0.05, bridges, open_reach 0.5 | 97.93% | 95.4% | 47.2% | 68.7% |
| **thr 0.15, margin 0.05, bridges, open_reach 0.8** | **98.01%** | **96.3%** | **48.6%** | **69.9%** |
| thr 0.15, margin 0.08, bridges, open_reach 0.8 | 98.06% | 96.8% | 53.1% | 71.5% |
| thr 0.15, margin 0.03, bridges, open_reach 0.8 | 97.98% | 95.8% | 45.6% | 68.9% |

- The first design only reached the rectangle's edge where the body left the crop. It lost about 0.5 pt of woman
  pixels: the feet and dress hems of women whose detector box stops at the knees. `open_reach` fixed that.
- A lower mask threshold (0.15) covers more of the head and hair. It barely adds background.
- At margin 0.05 and open_reach 0.8, the woman-pixel score matches the rectangles. A wider margin buys little.
- `seg_min_px`: 48, 96 and 128 give the same coverage on validation (98.01-98.02% woman px, 48.6% background).
  On test, 96 changed nothing either: small women stayed at 90.6%. But in a portrait frame, where people are
  small, 96 outlines only 1.5 people per frame against 3.2 at 48, so most of them would keep their rectangle.
  48 stays.
- A 144x96 model, trained the same way, was slightly worse than the 192x128 one. At threshold 0.15, margin 0.05,
  bridges and open_reach 0.2, it scored 97.24% vs 97.33% woman px and 46.9% vs 44.6% background. It took 5.0 ms
  vs 8.9 ms per person. It is the fallback if phones are too slow.

## Cost

Single x86 core (`time_silhouette.py`, 300 test images; same frames with and without the segmenter):

| layout | covered people per frame | outlined per frame (cap 6) | detect without outlines | outlines add (mean / p95) | per outlined person |
|---|---|---|---|---|---|
| photo (long side 640) | 9.6 | 4.0 | 103 ms | 33 / 78 ms | 8.4 ms |
| portrait (16:9 strip in a 1080x2340 screen, tiles on) | 8.3 | 3.2 | 160 ms | 27 / 80 ms | 8.4 ms |

The paired difference (with and without outlines, same frames) is the measure here. Absolute times are noisy:
other jobs shared the machine (load about 16 on 6 cores).

**Phone speed is not measured.** The 6-person cap bounds the worst case at about 6x the time per person. If phones lag, lower `seg_max_people`, set `seg` to 0, or build with
`-PimBlurSeg=` pointing to a missing file: all three give rectangles back.

## Not tested

- On a phone: speed, battery, and how strips look on both hosts (Shizuku layer and window). Square-cornered
  strips, the window host's single tint over their union, and 256 Shizuku colour layers were only built
  (assembleDebug + lint), never seen on a screen.
- Motion: strips use the same lead as rectangles, but nothing here measures moving people. The eval uses single
  frames.
- Real screens with text beside people: the "background covered" measure stands in for it.
- Mask coverage in the portrait layout (a small video strip in a tall screen). Only photos were scored with masks.
  Portrait was used for timing only.
- Covers visible in the capture (no skip-screenshot): rectangles are kept on purpose there. That path is unchanged.
