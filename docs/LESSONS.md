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
