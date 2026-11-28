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

## In progress: an "other" label in the classifier (2026-11-27)

The remaining false covers are animals the detector's COCO classes do not name. Instead of retraining the detector,
the classifier gets a fifth label, "other", that the engine leaves clear like a man (`im_vision.c` sums man, boy
and other; same male_clear 0.999). Training crops: `models/vision/prep_other_crops.py` runs the person detector on
Open Images **train** photos of animals and keeps a box only when it matches an annotator's animal box (IoU >=
0.6). That gate matters: on a contact sheet of 60 detector boxes from validation photos with no person label, many
were real people Open Images did not box (drivers, passers-by), and annotators also put the generic Animal / Mammal /
Carnivore boxes on people, so images with those are skipped, as are animals people ride. Kaggle run
`waaiya-blur-gender` v1 trains `gender_v3_other` and a control `gender_v3_ctrl` (same data without "other").

Animal test set rebuilt (the earlier list was not kept): the first 600 validation images by md5(id) with an animal
box and no person-like or generic animal box, ids in `eval/results/blur_animals_ids.txt`. Baseline, shipped
detector + gender_v2 at 0.999: images with a cover 13.2%, screen covered 5.6%. People (report half): women
covered 95.9%, men left clear 8.9%.

Rule, fixed before the run finished: ship `gender_v3_other` only if, at 0.999 on the report half, women covered
stays >= 95.7% and small women lose at most 2 points, and animal images with a cover drop clearly below both
gender_v2 and the control.

## Result (2026-11-28): gender_v3_other passes the rule

Kaggle `waaiya-blur-gender` v1, best epoch 8 for both runs. Exported with `export_vision.py gender --arch
mobilenetv3_large_100`; shipped detector, male_clear 0.999, rectangles.

| classifier | animal images with a cover | animal screen covered | women covered (report) | small women covered | men left clear |
|---|---|---|---|---|---|
| gender_v2 | 13.2% | 5.6% | 95.9% | 90.9% | 8.9% |
| gender_v3_ctrl | 13.2% | 5.6% | 96.0% | 90.9% | 8.3% |
| gender_v3_other | **6.5%** | **1.6%** | 95.8% | 90.9% | 7.3% |

Rule check: women 95.8% >= 95.7%, small women unchanged, animal covers halved against both. Cost: men left clear
8.9% -> 7.3% (more men covered), screen covered 68.9% -> 70.2%.
