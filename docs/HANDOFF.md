# Handoff (2026-11-25)

## Current phase and goal
Blur side: fewer wrong covers (animals, men) and faster on slow phones (user report: slow, hides men/animals).

## Done this session (branch blur-feature, NOT pushed)
- f1f735f: detector score 0 where a COCO animal wins; `eval_animals.py`, `bench_vision.c`, `bench_frames.py`,
  `export_vision.py qdq` (rejected path, kept for evidence); results `eval/results/blur_animals.md`, `blur_speed.md`.
- 69295d4: Android slow phones drop outlines after tiles take turns (> 150 ms/frame over 10 frames).
- 67a6753: merged origin/main (PR #45 Screen page, package org.waaiya.app). 9585ac0: JNI name fix for that merge.
- Local only: models/vision/person_yolox_nano.onnx is the new animal-gated detector (sha a5bbdf5d...);
  old copy `person_yolox_nano_v1.onnx`. `scripts/fetch_deps.sh vision` would overwrite it with the v1 release.

## Exact state
- VERIFIED: `make test-blur` 156/156; Android unit tests 142 passed (before C-only fix 9585ac0); APK builds.
- VERIFIED: phone (MT6769) timing: ~950 ms/frame default, ~700 tiles taking turns (bench, not the app).
- VERIFIED: new APK bundles the new detector; installed on the phone (org.waaiya.app debug).
- UNVERIFIED: outline drop in the real app (no blur log yet); expected ~450 ms/frame.
- UNVERIFIED: Screen page on the phone.
- BROKEN (pre-existing, also on main's model): `test_vision_engine.py` parity, worst IoU 0.63 (predates tiles/nest).

## Next 3 steps
1. User runs blur on the phone 30 s on photos; read `adb logcat -d | grep -i "blur:"` and the diagnostics line.
2. With the user's OK: push blur-feature, open a PR; publish detector as release `models-vision-v2` + fetch_deps.
3. Bigger speed step (needs user choice): smaller person detector (Kaggle) or GPU (LiteRT).

## Open questions for the user
- Publish the animal-gated detector (new GitHub release)? Push blur-feature?
- Next speed work: smaller detector trained on Kaggle, or GPU path? Lower default strictness (0.98) for men?

## Files to read first
`eval/results/blur_speed.md`, `eval/results/blur_animals.md`, `docs/PROGRESS.md`, `docs/LESSONS.md` (last 5),
`android/app/src/main/java/org/waaiya/app/ScreenBlur.kt` (process(): speed steps)

## Commands to check the state
- `git status -sb && git log --oneline -6` ; `make test-blur`
- Build: Flutter 3.41.5 worktree (LESSONS), `JAVA_HOME=~/.jdks/temurin-21 ANDROID_HOME=~/Android/Sdk`,
  `cd android && ./gradlew assembleDebug testDebugUnitTest -PimBuildPython=$HOME/.local/bin/python3.11`
- Phone: `adb devices`; `adb logcat -d | grep -i "blur:"`
