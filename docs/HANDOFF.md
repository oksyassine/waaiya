# Handoff (2026-11-28)

## Current phase and goal
Blur: fewer animals covered, faster on slow phones. The new classifier gender_v3_other is accepted; next it gets released and switched in.

## Done this session (no code commits; docs only)
- Downloaded Kaggle `waaiya-blur-gender` v1 output (COMPLETE) to `kaggle/blur-gender/out/out/` (gitignored).
- Exported both to ONNX and scored them (eval/results/blur_animals.md, "Result" section). gender_v3_other passes the rule.
- Copied it to `models/vision/gender_v3.onnx` (gitignored). Built an x86 debug APK with `-PimBlurGender=` pointing at it.

## Exact state
- VERIFIED: `make test-blur` 156/156 (today). emu_check --blur on rattil_test with the gender_v3 APK: ALL PASSED (24 checks).
- VERIFIED: APK blur_gender.onnx sha256 = gender_v3.onnx. blur-feature = origin up to 547597c; PR #53 merged.
- UNCOMMITTED (code, from 2026-11-27): verdict reuse, "other" label (engine, JNI, imvision, train/prep scripts,
  notebook), prep_other_crops.py, test_reuse.py, eval docs.
- NOT SWITCHED: build.gradle.kts, linux/blur/im_blur.c, desktop (linux_blur.dart, bundle_*.sh, tests),
  scripts/fetch_deps.sh, ui/test/parity_test.dart all still name gender_v2.onnx.
- UNVERIFIED: gender_v3, verdict reuse and the outline drop on a real phone.
- BROKEN (pre-existing): `test_vision_engine.py` parity, worst IoU 0.63.

## Next 3 steps
1. With the user's OK: commit the uncommitted blur work and publish release `models-vision-v2` (animal-gated detector
   + gender_v3.onnx + SHA256SUMS). Then rename gender_v2 -> gender_v3 everywhere, bump VISION_TAG, open a PR.
2. Phone: install the latest APK; the user runs the blur for 30 s; `adb logcat -d | grep -i "blur:"`.
3. Rerun the Android unit tests (`testDebugUnitTest`) after the rename, plus the desktop tests (linux_blur_test.dart).

## Open questions for the user
- OK to commit, push and publish `models-vision-v2`?
- Accept men left clear 8.9% -> 7.3% (more men covered) for half as many animal covers? (The rule says yes.)

## Files to read first
`eval/results/blur_animals.md` (end), `docs/DECISIONS.md` (last 3), `docs/LESSONS.md` (last 4), `scripts/fetch_deps.sh`

## Commands to check the state
- `git status -sb` ; `make test-blur` ; `ls -la models/vision/gender_v3.onnx kaggle/blur-gender/out/out/`
- Kaggle: `set -a; . ./.env; set +a; kaggle kernels status mohammedmoutawakkil/waaiya-blur-gender`
- Flutter 3.41.5: `git -C ~/flutter worktree prune; git -C ~/flutter worktree add --detach <scratch>/flutter341 3.41.5`
- Build: `cd android && JAVA_HOME=~/.jdks/temurin-21 ANDROID_HOME=~/Android/Sdk ./gradlew assembleDebug -PimX86
  -PimBlurGender=$PWD/../models/vision/gender_v3.onnx -PimBuildPython=$HOME/.local/bin/python3.11`
- Emulator: `android/tools/emu_check.py --serial emulator-5554 --apk android/app/build/outputs/apk/debug/app-debug.apk --setup none --blur`
