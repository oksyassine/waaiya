# Lessons

- Kaggle silently disables internet in notebooks until the account's phone is verified, even with `enable_internet: true`. Symptom: `Failed to resolve 'pypi.org'` in the first install cell.
- Kaggle no longer offers a single T4: `NvidiaTeslaT4` means 2x T4; the single-GPU choice is `NvidiaTeslaP100`. Queues for both can be hours.
- Several queued GPU runs on one account seem to wait on each other; delete stale kernels (`kaggle kernels delete -y <user>/<slug>`) and keep one queued. Observed, not confirmed by Kaggle docs.
- The Kaggle CLI has no cancel command; a run cancelled from the web page ends with `CANCEL_REQUESTED` and saves no model.
- Kaggle logs and outputs are only available after a run ends; while it runs the API gives status only.
- Holdout gains on annotator crops did not carry over to the app pipeline (detector crops on 640-px frames). Judge gender models only with `blur_diag.py` end to end.
- Status polling in a background script slows down when the PC sleeps: count elapsed time from timestamps, not from the number of checks.
- An "oracle" (perfect classifier) ceiling must also handle unmatched detections (part/duplicate boxes); clearing only IoU-matched boxes understated the ceiling (35% vs 53%).
- Debug builds on this PC are signed with `~/.android/debug.keystore` (SHA-256 6dc3004f…), so `adb install -r` updates a phone's debug install. The app id changed in 0.2.15 (`org.islamicmute.app` -> `org.waaiya.app`): a new build installs beside an old one, not over it.
- Android build here needs JDK 21 (`~/.jdks/temurin-21`; Gradle 8.13 fails on JDK 25 with only "25.0.5") and Flutter 3.41.5 as in CI (Flutter 3.47 requires Gradle 8.14).
- Xiaomi phones refuse `adb install` (INSTALL_FAILED_USER_RESTRICTED) until "Install via USB" is on and the prompt is tapped.
- Strings: `android/app/src/main/res/values*/strings.xml` is the source; every language must have every key (`ui/tool/arb_from_android.py --check`), then `flutter gen-l10n` in ui/.
- `desktop/test/linux_engine_test.dart` "no pactl" fails on main too on this PC (pactl is installed); not caused by our changes.
- Phone speed is ~5x worse than this PC per model (YOLOX-Nano 416: 24 ms x86 1 thread, ~125 ms on MT6769). Measure on the phone with `models/vision/bench_vision.c` (adb, `/data/local/tmp`), never infer from PC timings.
- Static int8 (QDQ) breaks the blur's extreme thresholds: male_clear 0.999 needs confidence that int8 rounding loses; the detector loses small people. ONNX Runtime's dynamic int8 skips Conv entirely, so it does nothing for these CNNs.
- `onnx.compose.merge_models` keeps one opset_import entry per merged model; the ORT quantizer then fails with "Failed to find proper ai.onnx domain". Reset opset_import after merging.
- After merging main into a branch, new JNI functions keep the old package name in their symbol (`Java_org_islamicmute_app_...`) while main renamed the rest: grep `Java_` names after any package rename; the build does not catch it (crash only at first call).
- Both Flutter installs here (`~/flutter`, `~/development/flutter`) are 3.47.9. For 3.41.5: `git -C ~/flutter worktree add --detach <dir> 3.41.5`, then `flutter pub get` in ui_module with it, and build with `ANDROID_HOME=~/Android/Sdk` set (no android/local.properties).

- Open Images does not box every person: "no person box/label" photos still hold drivers and passers-by, and the generic Animal / Mammal / Carnivore boxes are also drawn on people. Negatives for "not a person" must match an annotator's specific (non-generic) box.
- `kaggle kernels push` answers "400 Bad Request" for a ~5 MB notebook (a model embedded as base64); download models inside the notebook instead (a public release URL + sha256).
- `imvision.Vision.detect_raw` returns views of one ctypes buffer that the next call overwrites; copy (`VRect.from_buffer_copy`) before calling again.
- `emu_check.py` with an arm64-only APK runs under translation: blur frames take 5-8 s and the blur reports FAILING by design. Build with `-PimX86` for blur checks on an x86 emulator.
- `kaggle kernels status` with no `~/.kaggle` token says "You must authenticate": load the project's .env first (`set -a; . ./.env; set +a`). The kernel id in kernel-metadata.json has no user part; use `mohammedmoutawakkil/<slug>`.
- A Flutter worktree in the scratchpad disappears between sessions (git marks it "prunable"): `git -C ~/flutter worktree prune` before adding it again.
- `gh release create` marks the new release "Latest" by default, even a models-only one: pass `--latest=false` (or the README's app download link points at models).
