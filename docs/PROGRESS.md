# Progress (blur side)

Updated 2026-11-23. Project-wide status lives in `docs/STATUS.md`; this file tracks the blur training work.

## Done (verified)
- Kaggle runner `kaggle/run_blur.sh gender|seg`: push, wait, download. Verified by a full 2x T4 gender run that completed and downloaded (commit 5ad0a21, in main via #34).
- Local credentials via repo-root `.env` (gitignored), template `.env.example` tracked. Verified with `git check-ignore`.
- `export_vision.py` exports with PyTorch 2.15 (`dynamo=False`). Verified: export ran, file size matches the shipped gender_v2 (commit f07ddb5, in main).
- Retrain of gender v2 with 2x data (400k per side, 150 min): holdout 51.6% vs shipped 46.7% men clear at 0.5% women.
- End-to-end comparison (blur_diag.py, real C code, 4000 local validation images, photo + portrait): no clear gain. At the app default 0.999 the new model clears ~1.5 pt fewer men. Decision: keep shipped gender_v2.onnx.

- Why men stay covered (eval/results/blur_parts.md, models/vision/blur_parts.py): the perfect-classifier ceiling (35% photo) ignores detector part boxes; clearing parts inside a man's box lifts it to 53%, but with shipped gender_v2 only +2 pt at 0.999 (+4 pt at 0.98).
- Runtime-like crop retrain dropped: diagnostic b (blur_gender_v2.md) already shows no crop mismatch (54.0% annotator vs 54.9% detector boxes).

## In progress
- Nothing running. Results kept locally (gitignored): `kaggle/blur-gender/out/`, `models/vision/v2b/`, `eval/results/v2b/`.

## Next
- Decide: train the classifier on part crops (small expected gain, ~2 pt at 0.999), or work on classifier confidence on whole people (8.9% vs 35% ceiling at 0.999), or the segmenter.
- Segmenter (`kaggle/run_blur.sh seg`) not retrained this session.
