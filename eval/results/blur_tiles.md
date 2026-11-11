# Screen blur: person-detector tiles on portrait screens

Phones are held upright. The captured screen (long side 640) is squeezed into YOLOX-Nano's square 416 input, so a
video strip in an upright phone ends up a few pixels tall and its people are missed: women covered fell from 96.0%
(the photo itself) to 85.8% (the same photo in a 16:9 strip of a 1080x2340 portrait screen),
`eval/results/blur_gender_v2.md`.

Tiles (`engine/src/im_vision.c`, `im_vision_params.tiles`, default 3): on a frame at least 1.4x longer than wide,
the detector also runs on up to 3 overlapping square tiles along the long side (>= 30% overlap), where people
appear about twice as large. Boxes touching a tile's inner cut edge are dropped (the neighbouring tile or the
whole-frame pass sees that person whole); everything then goes through the usual NMS.

Same setup as `blur_gender_v2.md`: 6336 Open Images validation images with Woman/Man/Girl/Boy boxes, through the
real C library, `gender_v2.onnx`. "every person covered" isolates the detector; the male_clear rows are the whole
blur. Women / men columns are on the reporting half (md5 split, `models/vision/blur_diag.py`).

## Detector alone (every person covered, all images)

| layout | tiles | women covered | medium (10-30%) | small (<10%) | group boxes |
|---|---|---|---|---|---|
| portrait | none | 85.8% | 71.7% | 53.8% | 72.7% |
| portrait | 3 | **95.5%** | **94.1%** | **80.4%** | 89.0% |
| portrait, capture 960 | 3 | 95.7% | 94.1% | 82.3% | 90.2% |
| photo | none | 96.0% | 95.1% | 89.2% | 91.2% |
| photo (landscape images get 2 tiles) | 3 | 96.3% | 96.6% | 94.7% | 94.1% |

Capturing at 960 instead of 640 adds almost nothing (the classifier's men-clear rate too): the capture stays 640.

## Whole blur (reporting half: women covered / men left clear)

| layout | tiles | male_clear 0.98 | 0.99 | 0.999 (default) |
|---|---|---|---|---|
| portrait | none | 84.6% / 29.7% | 85.1% / 26.7% | 86.1% / 18.2% |
| portrait | 3 | 95.3% / 16.0% | 95.5% / 13.5% | 96.2% / 6.9% |
| photo | none | 95.9% / 23.4% | 96.3% / 19.5% | 96.8% / 9.9% |
| photo | 3 | 95.8% / 19.9% | 96.1% / 16.9% | 96.5% / 8.0% |

Men left clear drops with tiles partly because more men are now *found* (without tiles 11.3% of men were "clear"
only because the detector missed them), and partly because tiles add duplicate and body-part boxes: 3.3 -> 6.2
boxes per portrait image. Each is classified on its own, a part box is less sure, and so it is covered. A perfect
classifier leaves 47.0% of men clear without tiles and 27.7% with them.

Tried against the duplicates, both off by default:
- `nest` 0.8 (drop a box mostly inside a kept box of similar size): barely triggers; most extra boxes are small
  parts inside a much larger box, which cannot be told apart from a child in front of an adult.
- `tile_score` (a higher detector threshold inside tiles): 0.25 gives portrait 94.2% / 9.9% at 0.999, 0.40 gives
  92.0% / 12.6%. Plain tiles at 0.98 (95.3% / 16.0%) beat both on both counts.

## Cost (x86, 2 threads, 300 portrait images, detector + classifier per frame)

| | median | p95 |
|---|---|---|
| no tiles | 24 ms | 54 ms |
| 3 tiles every frame | 83 ms | 111 ms |
| 1 tile per frame, taking turns (`tiles_per_frame` 1) | 44 ms | 75 ms |

The app (`ScreenBlur.kt`) runs all tiles while frames average under 60 ms, then lets them take turns for the rest
of the session; the cover tracker holds a person (500 ms) between the frames that see them. Phone speed is not
measured yet. Turn-taking is not in these single-frame numbers.
