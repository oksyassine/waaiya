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

## 2026-11-23: Drop the "train gender on runtime-like crops" plan
- Why: `blur_gender_v2.md` diagnostic b already shows annotator vs detector crops give the same result (54.0% vs 54.9%); `blur_parts.md` shows the cap is other boxes, not the classifier.
- Rejected: retraining on detector crops (Kaggle time for a mismatch that does not exist).

## 2026-11-23: Screen page gets its own on/off (`blur_on`), tied to filtering on Android
- Why: user asked for a Filter-like on/off. `blur_on` defaults to true so existing users see no change; off keeps the women/nudity choices; protected like other blur switches.
- Android: turning it on also starts filtering (one service owns the single MediaProjection, audio + blur).
- Rejected (user chose, for now): a fully independent blur on Android (needs splitting FilterService and the muter; risk of leaving other apps muted).

## 2026-11-23: The blur no longer uses Shizuku
- Why: Waaiya's own helper (CoverHelper, Wireless debugging / USB setup) draws the same pass-through layer since 0.2.11. Shizuku kept only for the sound setup.
- Done as: ShizukuCovers -> ShellCovers (helper only), CoverService always checks the caller uid, Shizuku blur grant and blur.busy/message removed, "Go to the setup" button.
- Rejected: keeping Shizuku as a second cover route (two paths to maintain, one of them a third-party app).
