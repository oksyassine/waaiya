# Decisions

## 2026-11-22: Train blur models on Kaggle only
- Why: free (~30 GPU h/week), already had notebook generators, fully scriptable from the CLI (push/status/output).
- Rejected: Google Colab and SageMaker Studio Lab (browser-only, cannot be driven from the terminal); Hugging Face (no free training GPU); several platforms at once (more glue to maintain for little gain).

## 2026-11-22: Evaluate on the local PC, not Kaggle
- Why: evaluation is CPU inference through `build/libimvision.so` on validation images already on disk; Kaggle would add queue time, rebuilds and downloads.

## 2026-11-22: Credentials in a gitignored repo-root `.env`
- Why: user preference; `.env.example` (tracked, empty values) documents the fields. `~/.kaggle` still works. Empty `.env` entries are unset so they do not hide `~/.kaggle`.

## 2026-11-22: Keep shipped gender_v2.onnx
- Why: the 2x-data retrain won on the holdout (51.6% vs 46.7%) but not end to end; at app default 0.999 it clears fewer men.
- Rejected: shipping on the holdout score alone.

## 2026-11-22: ONNX export uses the TorchScript exporter (`dynamo=False`)
- Why: PyTorch 2.9+ defaults to dynamo (needs onnxscript, different graph from shipped models).
