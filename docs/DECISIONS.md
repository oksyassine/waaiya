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

## 2026-11-25: Detector ignores boxes where a COCO animal class beats person
- Why: user reported animals covered. Free in the graph (`export_vision.py yolox`); animal photos with a cover 16.5% -> 15.3%, women covered unchanged (95.9% -> 95.8%).
- Rejected: raising person_score (0.15: animal covers 11.8% but small women covered 93.6% -> 86.7%).

## 2026-11-25: Slow phones switch to rectangles (no outlines) instead of faster models
- Why: on an MT6769 the app runs ~700 ms/frame with tiles taking turns; the segmenter is ~250 ms of it. Rectangles cover the same women.
- Rejected: XNNPACK EP (-7%), pinning to big cores (no change), static int8 QDQ (15-35% faster; int8 detector women covered 95.3% -> 93.0%, int8 gender men clear 7.5% -> 4.0%), detector input shaped like the screen (only the whole-frame pass has padding: ~7% of a frame).

