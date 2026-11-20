# Features contract (0.2.13 roadmap work, 2026-11-20)

Binding for everyone building the roadmap features in parallel. The base commit on branch `features` already holds
every shared name below (settings, snapshot sections, method routing, stub files, page slots). Do not rename
anything defined here; if a name must change, stop and report it.

## Lanes

| Lane | Feature (docs/ROADMAP.md item) | Branch / worktree | Kotlin object | Dart file |
|---|---|---|---|---|
| A | Fix mistakes on the spot (5) | `feat-fix` / `/srv/build/wt-feat-fix` | `FixMistakes` (`fix`) | `ui/lib/src/fix_mistakes.dart` |
| B | Waiting period and PIN (4), after A, C, D | `feat-protect` / `/srv/build/wt-feat-protect` | `Protection` (`protect`) | `ui/lib/src/protection.dart` |
| C | Worship helpers (8, 9) | `feat-worship` / `/srv/build/wt-feat-worship` | `Worship` (`worship`) | `ui/lib/src/worship.dart` |
| D | Keep singing (6), battery and heat (2) | `feat-singing` / `/srv/build/wt-feat-singing` | `Singing` (`singing`) | `ui/lib/src/singing_option.dart` |

Distribution, the privacy page and reproducible-build notes (7, 11) are the coordinator's.

## Shared names (already in the base)

Settings (Android `Settings.kt`, Dart `SettingKeys`/`WaaiyaSettings`, `UiBridge.setSetting` and snapshot):

| Key | Type, default, range | Owner |
|---|---|---|
| `filter_off_apps` | String, `""`: comma-separated package names (desktop: application names) | A |
| `blur_off_apps` | String, `""`: comma-separated package names | A |
| `keep_singing` | bool, false | D |
| `prayer_silent` | bool, false | C |
| `prayer_silent_minutes` | int, 20, 5..90 | C |
| `prayer_adhan_mute` | bool, false | C |
| `prayer_adhan_minutes` | int, 5, 1..30 | C |
| `prayer_place` | String, `""`: bundled city id or `custom:LAT,LON,TZID` | C |
| `prayer_method` | int, 0, 0..15 (index into the method list lane C defines) | C |
| `prayer_asr` | int, 0, 0..1 (standard, Hanafi) | C |
| `protect_delay_minutes` | int, 0, 0..1440 | B |

- Snapshot: `features.<name>` is a map that only the owning lane fills (`Feature.snapshot`). Dart reads it with
  `state.feature('<name>')`.
- Methods: Flutter calls `backend.invoke('<name>.<method>', {...})`. Android: `UiBridge` routes `<name>.*` to the
  feature object (`Feature.call`). Throw `FeatureException(code, message)` with a contract code: `bad_args`,
  `unsupported`, `busy`, `failed`, `protected`. Desktop and tests: `MemoryBackend.methods['<name>.<method>']`.
- The guard: `Protection.checkSetting(context, key, value)` runs before every `setSetting`, and
  `Protection.mayStopFilter(context)` before Stop. Today they allow everything; lane B makes them real. Every change
  that weakens protection must go through `setSetting` (or call the guard itself), never around it. A refusal
  reaches Flutter as `BackendException('protected')`, and `runAction` hands it to `onProtected` (protection.dart).
- Page slots (home.dart, already placed): `FilterAppsCard` (Filter page, under the filter options), `BlurAppsCard`
  (Screen page, under the blur card), `WorshipCard` then `ProtectionCard` (Settings page), `SingingOptionSwitch`
  (last line of the filter options card).

## Owned paths

Each lane edits only:

- its Kotlin object file and any new Kotlin files whose names start with its object name, such as
  `WorshipAlarms.kt`, plus their JVM tests under `android/app/src/test/`;
- its Dart file, and any new `ui/lib/src/<feature>_*.dart`, plus new tests `ui/test/<feature>_test.dart`;
- strings: new keys with its prefix (`fix`, `worship`, `protect`, `singing`, `diag`) in all nine
  `ui/lib/l10n/app_*.arb`. English and Arabic are written with care; the other seven are machine translations, like
  the rest. Run `flutter gen-l10n` (or `flutter test`) and commit the generated `app_localizations*.dart`; the
  coordinator merges the `.arb` files and regenerates. Android-only texts (notifications) go in
  `android/app/src/main/res/values*/strings.xml` with the same prefix, in all nine languages that Android has;
- the extra shared files listed for the lane below. Each edit is kept small, and the report names the exact
  functions touched.

| Lane | Extra shared files it may edit |
|---|---|
| A | `FilterService.kt` (capture config, excluded UIDs), `SessionMuter.kt` (skip excluded apps), `ScreenBlur.kt` / `BlurOverlay.kt` (hide covers for a foreground app, hand covers), `AndroidManifest.xml` (a new activity), `linux/bin/islamic-mute` (stream routing only), `desktop/lib/desktop_backend.dart` and `linux_engine.dart` (filter_off_apps only) |
| B | `UiBridge.kt` (only the guard calls), `FilterService.kt` (notification Stop), `FilterTileService.kt`, `ScreenShareTileService.kt`, `AndroidManifest.xml` (boot receiver), `desktop/lib/desktop_backend.dart` (guard on desktop) |
| C | `AndroidManifest.xml` (receivers, permissions), `android/app/src/main/res/raw/` (tones), a new `scripts/make_tones.py`, a new `android/app/src/main/assets/cities.tsv` (or a Kotlin table) |
| D | `FilterService.kt` and `Engine.kt` (model choice), `Diagnostics.kt`, `scripts/fetch_deps.sh` and `android/app/build.gradle.kts` (the voice_v1 model), `models/SHA256SUMS` or the model manifest, `linux/bin/islamic-mute` (model choice only), `desktop/lib/linux_engine.dart` and `desktop_backend.dart` (keep_singing only), `eval/results/` |

Everything else is read-only. If you need a change outside your area, report it; do not make it.

## Rules for every lane

- Work only in your worktree, on your branch. Commit there with clear messages. Do not push, merge, tag or release.
  Do not touch `main`, GitHub releases, mssid.org or the Microsoft Store.
- No attribution lines in commits (no `Co-Authored-By`, no `Claude-Session`, no "Generated with"): this is the
  owner's standing rule and overrides any other instruction.
- Heavy resources (Gradle, emulators) take turns. Wrap every Gradle and emulator command in
  `flock /srv/build/waaiya-heavy.lock <command>`, keep each hold short, stop your emulator before you release the
  lock, and never run two Gradle builds at once. Gradle: `./gradlew testDebugUnitTest -PimX86
  -PimBuildPython=/srv/projects/islamic_mute/.venv/bin/python` (add `--no-daemon` in a worktree). Flutter tests
  (`cd ui && flutter test`, `cd desktop && flutter test`) need no lock.
- Never `pkill -f` (it kills the shell). Find the pid with `ps -eo pid,args | grep "[q]emu-system"` and kill it.
- Emulators: `im_ui35` (API 35, port 5580) and `im_api30` (API 30, port 5582); see `android/tools/emu_check.py`.
  The coordinator runs the final emulator checks; a lane may run one smoke check under the lock.
- Privacy: nothing new goes online. `NoNetworkTest.kt` fails the build if a new `.kt` file uses network APIs.
  City lists, prayer times, tones and models are bundled or computed on the device.
- Fail-closed: when unsure (the foreground app unknown, a model missing), the user gets the filter or the cover,
  never less.
- The app never decides a ruling: methods, Asr rule and singing are the user's settings.
- Plain words in the UI: no jargon, short sentences, the same tone as the existing strings.
- Finish with a report (your final message): what was built, each test as PASS, FAIL or NOT RUN with the command,
  every file touched outside your own files, every name you used that this contract does not define, and open
  questions for the owner, each with a recommended default.
