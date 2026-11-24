# Handoff (2026-11-24)

## Current phase and goal
Blur side: find what limits "men left clear"; Screen page on/off and the blur without Shizuku (PR #45).

## Done this session
- 1b32b30, 8ea7ea1 (blur-feature, NOT pushed): `blur_parts.py`, `eval/results/blur_parts.md`, notes.
- 17f6c80 (branch `screen-page`, pushed, PR #45 open): Screen page power button (`blur_on`), blur without Shizuku.
- Local `main` reset to origin/main; old one kept as `main-backup-20261123` (15 commits not on origin).
- Phone: old 0.2.3 (org.islamicmute.app) removed by the user; debug build of 17f6c80 installed (org.waaiya.app).

## Exact state
- VERIFIED: `make test-blur` 156/156 (blur-feature); ui `flutter test` 211 passed + analyze clean (screen-page).
- VERIFIED (2026-11-23): Android unit tests passed; desktop tests pass except linux_engine_test "no pactl" (fails on main too).
- VERIFIED: cap on men clear is other boxes (parts, neighbours, misses), not the classifier (`blur_parts.md`).
- UNVERIFIED: Screen page on the phone not looked at; `emu_check.py` not run.
- Build tree for screen-page lives in the scratchpad worktree (temporary); the branch itself is in the repo.

## Next 3 steps
1. User checks Screen page on the phone (on/off, starts filtering, off keeps choices); fix findings; merge #45.
2. Push blur-feature (`git push`), open a small PR for the blur_parts analysis.
3. Plan engine-side handling of part/duplicate boxes in `engine/src/im_vision.c` (measure with `blur_parts.py` and `eval_blur.py --seg`); alternative: retrain segmenter.

## Open questions for the user
- Screen page OK on the phone? Merge #45?
- Later: make the Android blur fully independent of sound filtering?
- Next blur work: engine part boxes, or segmenter?

## Files to read first
`docs/PROGRESS.md`, `eval/results/blur_parts.md`, `docs/LESSONS.md`, PR #45 (`gh pr view 45`), `ui/lib/src/blur_card.dart`

## Commands to check the state
- `git fetch && git status -sb && git log --oneline -5` ; `gh pr view 45`
- `make test-blur`
- Android build: `JAVA_HOME=~/.jdks/temurin-21` + Flutter 3.41.5 on PATH, `cd android && ./gradlew assembleDebug -PimBuildPython=$HOME/.local/bin/python3.11`
- `adb shell dumpsys package org.waaiya.app | grep versionName`
