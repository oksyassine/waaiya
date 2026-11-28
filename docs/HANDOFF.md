# Handoff (2026-11-28, second part)

## Current phase and goal
Blur: fewer animals covered, faster on slow phones. The new models are released and switched in; next is a real-phone check.

## Done this session
- 5da3634: "other" label (animals) in the classifier + verdict reuse (code from 2026-11-27, now committed).
- Release `models-vision-v2` (person_yolox_nano with the animal gate, gender_v3, nsfw/seg unchanged; app v0.2.19 kept as Latest).
- Switch commit (see git log): every gender_v2.onnx reference -> gender_v3.onnx, VISION_TAG models-vision-v2, MODELS.md, licences.

## Exact state
- VERIFIED: fresh `fetch_deps.sh vision` downloads v2, checksums match. make test-blur 156/156; test_cover ALL PASS;
  test_reuse 200 photos; Android unit tests 142/142; desktop linux_blur_test + ui parity_test pass; emu_check --blur ALL PASSED.
- UNVERIFIED: gender_v3, verdict reuse and outline drop on a real phone. Windows desktop build not run (CI will).
- BROKEN (pre-existing): `test_vision_engine.py` parity, worst IoU 0.63.

## Next 3 steps
1. Watch the PR's CI (Android, Linux, Windows desktop fetch models-vision-v2).
2. Phone: install the debug APK; the user runs the blur 30 s; `adb logcat -d | grep -i "blur:"` (outlines off? frame ms?).
3. Speed: a smaller/faster person detector (it is now most of the frame time).

## Open questions for the user
- Who merges the PR (the repo owner)? A new app version to ship gender_v3 to users?

## Files to read first
`eval/results/blur_animals.md` (end), `eval/results/blur_speed.md`, `docs/DECISIONS.md` (last 3)

## Commands to check the state
- `git status -sb` ; `make test-blur` ; `gh pr checks` ; `gh release view models-vision-v2`
- Flutter 3.41.5: `git -C ~/flutter worktree prune; git -C ~/flutter worktree add --detach <scratch>/flutter341 3.41.5`
- Build: `cd android && JAVA_HOME=~/.jdks/temurin-21 ANDROID_HOME=~/Android/Sdk ./gradlew assembleDebug testDebugUnitTest -PimX86 -PimBuildPython=$HOME/.local/bin/python3.11`
- Emulator: `android/tools/emu_check.py --serial emulator-5554 --apk android/app/build/outputs/apk/debug/app-debug.apk --setup none --blur`
