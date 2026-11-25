# Animals covered as people, and the person threshold (2026-11-25)

User report: the blur hides animals. Cause: the detector keeps a box at person score >= 0.10 (recall first), and
every box the classifier is not sure about is covered. YOLOX also scores 79 other COCO classes, which the export
threw away.

## Fix kept: score 0 where an animal class wins

`export_vision.py yolox` now sets the person score to 0 where any COCO animal class (bird, cat, dog, horse, sheep,
cow, elephant, bear, zebra, giraffe) scores higher than person. Boxes and every other score are unchanged
(checked: identical outputs where the gate is open).

Animal photos: 600 Open Images validation images with an animal box and no person box of any kind (first 600 by
md5 of the id), `python models/vision/eval_animals.py --images DIR`, gender_v2, male_clear 0.999, rectangles.
Every cover there is a mistake (apart from people the annotators did not box: legs, a person behind a dog).

| detector | images with a cover | screen covered |
|---|---|---|
| v1 (person score only) | 16.5% | 8.0% |
| animal gate | 15.3% | 6.9% |

People (`eval_blur.py --half report`, 2022 images, male_clear 0.999): women covered 95.9% -> 95.8% (about 2 of
2507 women), men left clear 8.9% -> 8.9%.

The gain is small because most remaining false covers are animals COCO has no class for (monkeys, fish, drawings)
or low-score boxes.

## Rejected: a higher person threshold

Tune half (2649 women), animal gate on:

| person_score | animal images with a cover | women covered | small women covered | men left clear |
|---|---|---|---|---|
| 0.10 (default) | 15.3% | 95.3% | 93.6% | 7.5% |
| 0.15 | 11.8% | 94.1% | 86.7% | 8.5% |
| 0.20 | 9.8% | 92.3% | 79.8% | 9.3% |
| 0.25 | 7.0% | 91.2% | 73.9% | 10.2% |

Every step trades women (small ones most) for a few animal covers: not worth it.
