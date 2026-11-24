# Progress (blur side)

Updated 2026-11-24. Project-wide status lives in `docs/STATUS.md`; this file tracks the blur work.

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
- Engine-side handling of extra/part detection boxes (the main cap on men clear), or retrain the segmenter.
