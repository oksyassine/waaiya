# Progress (blur side)

Updated 2026-11-25. Project-wide status lives in `docs/STATUS.md`; this file tracks the blur work.

## Done (verified)
- Kaggle runner `kaggle/run_blur.sh gender|seg`: push, wait, download (5ad0a21, in main via #34).
- Local credentials via repo-root `.env` (gitignored), template `.env.example` tracked.
- `export_vision.py` exports with PyTorch 2.15 (`dynamo=False`) (f07ddb5, in main).
- gender v2 retrain with 2x data: holdout 51.6% vs 46.7%, but no end-to-end gain; shipped gender_v2 kept.
- Why men stay covered (1b32b30, 8ea7ea1; `eval/results/blur_parts.md`, `models/vision/blur_parts.py`):
  - perfect-classifier ceiling 35% (photo) ignores detector part boxes; with man parts cleared: 53%.
  - with shipped gender_v2 that gain is only +2 pt at 0.999, +4 pt at 0.98.
  - at 0.98, 53% of men's own boxes clear them but only 21% of men end clear: other boxes block them.
  - outlines (app path, `--seg`) vs rectangles: men clear 9.9% vs 8.9% at 0.999; the rectangle eval is a fair proxy.
  - women wrongly cleared are spread over all sizes: a size-dependent male_clear gains nothing.
- Animals covered (`eval/results/blur_animals.md`): detector score 0 where a COCO animal class beats person;
  animal photos with a cover 16.5% -> 15.3%, women covered 95.9% -> 95.8% (report half). Higher person_score
  rejected (0.15: small women 93.6% -> 86.7%). New detector is local only; `models-vision-v1` still has the old one.
- Phone speed (`eval/results/blur_speed.md`, `bench_vision.c`, MT6769): app default ~950 ms/frame, ~700 with
  tiles taking turns. XNNPACK (-7%) and int8 QDQ (15-35% faster, loses women/men) rejected.
- Runtime-like crop retrain dropped: `blur_gender_v2.md` diagnostic b shows no crop mismatch.
- Screen page + blur without Shizuku (17f6c80, branch `screen-page`, PR #45 open, mergeable):
  ui tests 211 passed, `flutter analyze` clean, Android unit tests passed, debug APK built and installed.

## Implemented, not verified
- PR #45 on a real phone: installed (debug, org.waaiya.app 0.2.17) but the Screen page was not looked at
  (screenshot attempt hit another app). `android/tools/emu_check.py` not run.

## In progress
- Nothing running. Local only (gitignored): `kaggle/blur-gender/out/`, `models/vision/v2b/`, `eval/results/v2b/`.

## Next
- User checks the Screen page on the phone; merge PR #45.
- Push blur-feature (2 commits ahead of origin).
- Speed: drop outlines automatically on slow phones (~250 ms/frame); detector input shaped like the screen
  (half of each pass is padding on an upright phone).
- Publish the animal-gated detector (new release `models-vision-v2`, needs the user's OK).
- `test_vision_engine.py` fails on main's detector too (worst IoU 0.63 on 20 images): predates tiles/nest.
- Engine-side handling of extra/part detection boxes (the main cap on men clear), or retrain the segmenter.
