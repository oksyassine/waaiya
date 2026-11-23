# Why men stay covered: part boxes (2026-11-23)

The question was why a perfect classifier leaves only 35% of men clear (photo) and 29% (portrait) in
`blur_diag.py`. This uses gender_v2.onnx and YOLOX-Nano with 3 tiles. It runs the real C code (`build/libimvision.so`)
on the 4000 local Open Images validation images, with results reported on the reporting half (2022 images).

## Where covered men come from (photo, perfect classifier)

Out of 5910 man/boy boxes, the perfect classifier leaves 34% clear. The rest are covered for these reasons:

| reason | share of men |
|---|---|
| matched and cleared, no woman or group in the image, still covered | 30.0% |
| matched, the image also has a woman/girl | 17.6% |
| no detection matched (IoU < 0.5) | 11.5% |
| the man box is a group box | 4.6% |
| matched, the image has a group box | 2.3% |

Replaying 300 images from the first row: every one had extra detections that matched no labelled person, and
with every detection cleared none of those men was covered. The perfect classifier clears only the matched box,
so any extra box stays covered.

The detector produces 9119 unmatched detections on the 2022 images, more than the number of labelled people.
About 5400 lie inside a labelled box (parts or duplicates) and about 3700 lie outside every labelled box (people
nobody labelled, or false detections). Most come out "unsure" with the real classifier.

## Ceiling if part boxes inside a man were cleared

Part boxes here are unmatched detections that lie at least 70% inside one man/boy box and touch no woman, girl or
group box. There are 1209 of them in photo. "+ man parts" clears them and leaves everything else as before.
Command: `python models/vision/blur_parts.py photo|portrait`.

| rule | photo: women covered / men clear | portrait: women covered / men clear |
|---|---|---|
| every person covered | 96.1% / 2.2% | 95.8% / 2.3% |
| perfect classifier | 94.1% / 35.2% | 93.3% / 29.1% |
| perfect classifier + man parts | 94.0% / 52.8% | 93.3% / 43.9% |
| gender_v2, male_clear 0.98 | 95.1% / 21.3% | 94.5% / 16.6% |
| gender_v2 0.98 + man parts | 95.1% / 25.6% | 94.4% / 20.3% |
| gender_v2, male_clear 0.999 (app default) | 95.9% / 8.9% | 95.7% / 7.4% |
| gender_v2 0.999 + man parts | 95.8% / 10.9% | 95.7% / 9.2% |

## Reading

- The 35% ceiling understates what is possible. With part boxes handled, it reaches 53% (photo) and 44% (portrait)
  at the same women coverage.
- With the shipped classifier, handling part boxes adds only +2 points at 0.999 and +4 points at 0.98. At the app
  default the classifier on the matched person is still the main limit: 8.9% against a 35% ceiling.
- Training the classifier on part crops (detector part boxes labelled by the man box that contains them) is the
  only lever found here that raises the ceiling. Its realistic gain at 0.999 is about 2 points unless the classifier
  also becomes more confident on whole people.
- Dropping nested boxes by geometry was already rejected (`blur_tiles.md`: `nest`) because part boxes cannot be
  told apart from a child in front of an adult. This measurement does not change that.

## Outlines (the app's path) do not change this

`eval_blur.py --half report` (2000 images, photo), rectangles vs `--seg models/vision/seg.onnx` (strips + bridges,
the app default). "women covered" (>= 90% of the box) undercounts outlines by design (see `blur_silhouette.md`).

| male_clear | rectangles: men clear | outlines: men clear |
|---|---|---|
| 0.999 | 8.9% | 9.9% |
| 0.98 | 21.5% | 23.2% |

## The classifier alone vs end to end (photo, matched people, IsGroupOf = 0)

| | own box p(male) >= 0.98 | >= 0.999 |
|---|---|---|
| men | 53.3% | 21.5% |
| boys | 37.9% | 7.3% |
| women | 1.02% | 0.06% |
| girls | 0.58% | 0.17% |

Women whose own box scores high are spread evenly over sizes (0.6% to 2% at 0.98 in every size bucket), so a
size-dependent male_clear has nothing to gain. At 0.98, 53% of men's own boxes clear them but only 21% of men end
up clear. The rest are blocked by other boxes: part/duplicate boxes, neighbours' covers, or people without a
detection. That cap is why classifier-only gains (gender_v2b: +5 pt on the holdout) do not show up end to end.
