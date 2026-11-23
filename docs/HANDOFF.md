# Handoff (2026-11-22)

## Current phase and goal
Blur side: improve the woman/man classifier, training on Kaggle instead of the local PC.

## Done this session
- 5ad0a21 `kaggle/run_blur.sh`, `.env.example`, `.gitignore` `!.env.example` (merged to main via #34)
- 51b0ba0 merged origin/main into blur-feature
- f07ddb5 `export_vision.py` `dynamo=False` (in main)
- Two full Kaggle gender runs; end-to-end comparison vs shipped gender_v2

## Exact state
- WORKS (verified): Kaggle push/wait/download with `.env` creds; ONNX export on PyTorch 2.15; `make test-blur` 156/156.
- RESULT (verified): 2x-data model better on holdout (51.6% vs 46.7%), not end to end; shipped gender_v2 kept.
- UNVERIFIED: `KAGGLE_MACHINE=NvidiaTeslaP100` path (pushed once, deleted while queued); `run_blur.sh seg` never run.
- Local only (gitignored): `kaggle/blur-gender/out/{run1,out}`, `models/vision/v2b/gender_v2b.onnx`, `eval/results/v2b/*.npz`.
- Local `main` branch is stale vs origin/main (old rewritten history); use origin/main.

## Next 3 steps
1. Plan with the user: gender training on runtime-like crops (detector boxes on 640-px frames).
2. Implement it in `prep_train_crops.py` / the blur-gender notebook; run on Kaggle.
3. Compare with `blur_diag.py` (photo + portrait) against shipped gender_v2, same 4000 images.

## Open questions for the user
- Pursue runtime-like crops, or move to the segmenter / other blur work?
- Reset local `main` to origin/main (back it up first)?

## Files to read first
`docs/PROGRESS.md`, `docs/LESSONS.md`, `kaggle/run_blur.sh`, `kaggle/blur-gender/make_notebook.py`, `models/vision/blur_diag.py`, `eval/results/blur_gender_v2.md`

## Commands to check state
- `git fetch && git status -sb && git log --oneline -5`
- `bash -n kaggle/run_blur.sh && make test-blur`
- `kaggle kernels list --mine` (with `.env` loaded: `set -a; . ./.env; set +a`)
- `.venv/bin/python models/vision/blur_diag.py report eval/results/v2b/new_photo.npz`
