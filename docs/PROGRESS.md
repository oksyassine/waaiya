# Progress (blur side)

Updated 2026-11-27. Project-wide status lives in `docs/STATUS.md`; this file tracks the blur work.

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
- Screen page + blur without Shizuku: PR #45 merged into main (2026-11-24), merged into blur-feature (67a6753).

- Verdict reuse for covered people (2026-11-27, `blur_speed.md`): classifier time ~-60% on a still screen, frame
  -15..-19% on this PC; Android sets reuse_frames 3; emulator blur check 25/25; `test_reuse.py`.

## Implemented, not verified
- Slow phones drop person outlines (69295d4, JNI name fix 9585ac0): ScreenBlur, tiles already taking turns and
  still > 150 ms a frame over 10 frames -> rectangles for the session. Debug APK builds, Android unit tests 142
  passed (before the C-only fix 9585ac0), installed on the MT6769 phone; never run there (no blur log yet).
- Screen page (PR #45) on a real phone: still not looked at.

- "other" label (animals) in the classifier (2026-11-28, `blur_animals.md`): Kaggle v1 finished; gender_v3_other
  passes the rule fixed before the run: animal photos with a cover 13.2% -> 6.5%, women covered 95.8%, small women
  unchanged, men left clear 8.9% -> 7.3%. x86 debug APK with it (-PimBlurGender): emu_check --blur ALL PASSED.

- Released `models-vision-v2` (2026-11-28: animal-gated detector + gender_v3.onnx; nsfw and seg unchanged). Every
  platform and fetch_deps.sh switched; fresh fetch verified; make test-blur 156/156, Android unit 142/142, desktop
  linux_blur_test + ui parity_test pass, emu_check --blur ALL PASSED.

## Next
- On the phone: start blur, scroll photos 30 s; logcat should show "tiles now take turns" then "person outlines
  off"; frames ~450 ms (expected, not measured).
- `test_vision_engine.py` fails on main's detector too (worst IoU 0.63 on 20 images): predates tiles/nest.
- Engine-side handling of extra/part detection boxes (the main cap on men clear), or retrain the segmenter.
