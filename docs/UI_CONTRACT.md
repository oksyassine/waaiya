# UI contract: shared Flutter screens and native backends

Waaiya's screens are written once in Flutter (`ui/`) and run on Android (add-to-app, `ui_module/`) and on desktop
(`desktop/`). Everything that touches the system stays native: audio capture and muting, the screen blur, Shizuku,
permissions, notifications, the link player. The screens only **read one state snapshot** and **call a few
methods**. This file is the contract between the two sides.

```
 Flutter (ui/)                                  native backend
 ─────────────                                  ──────────────
 screens ── WaaiyaBackend (Dart interface) ──┬─ ChannelBackend ── MethodChannel "waaiya/app"  ── Android: UiBridge.kt
                                             │                  EventChannel  "waaiya/state"     (calls Settings, Lang,
                                             │                                                    FilterService, ShizukuSetup,
                                             │                                                    ScreenBlur, LinkActivity)
                                             └─ DesktopBackend (pure Dart, desktop/) ── later: dart:ffi → engine/ (C)
```

Rules:

- The native side owns the truth. Settings stay in the Android SharedPreferences file `"settings"` with the keys of
  `Settings.kt`, because `FilterService`, `SessionMuter` and `ScreenBlur` read them there. Flutter never stores them
  itself (no `shared_preferences` plugin).
- The UI decides what to *show* (which card, which text, which button) from the snapshot, the same decisions
  `MainActivity.refresh()` made. Native code returns facts and machine codes, never display text; all text is
  translated in Flutter (`ui/lib/l10n/*.arb`).
- Every method can fail with a `PlatformException` whose `code` is one of `unsupported` (not on this platform),
  `bad_args`, `busy`, `failed`.
- Codec: `StandardMethodCodec`. Maps have `String` keys. Integers are Dart `int`.

## EventChannel `waaiya/state`

On `listen`, the backend sends the current snapshot at once, then a new snapshot after every change: filter state,
screen-blur state, Shizuku binder received / dead / permission result, a setting or the language changed, a setup
action started or finished, and whenever the host screen resumes (permissions can change in another app with no
callback: Shizuku, Android settings). Each event is a full snapshot (below), not a diff. The UI keeps the last one.

## Snapshot (`getState` result and every event)

| Key | Type | Meaning |
|---|---|---|
| `platform` | String | `android`, `linux`, `windows`, `macos` |
| `version` | String | App version name (`0.2.6`) |
| `language` | String | `ar` or `en`. Arabic is the default whatever the system language. |
| `settings` | Map | The settings below, with their current values |
| `filter.state` | String | `STOPPED`, `STARTING`, `FILTERING`, `MODEL_FAILED`, `NO_CAPTURE_PERMISSION`, `STOPPED_BY_SYSTEM` (`FilterService.State`) |
| `filter.delayMs` | int | Engine delay of the running filter |
| `filter.micDenied` | bool | The microphone permission was refused at the last start (until the next start) |
| `filter.simulated` | bool | Desktop preview: start/stop are not connected to an engine yet (the screen says so) |
| `setup.originalsMuted` | bool | The originals can be silenced (Android: `DUMP` granted) |
| `setup.consentSkipped` | bool | No screen-capture question at start (Android: app-op `PROJECT_MEDIA` = allow) |
| `setup.shizuku` | String? | `NOT_INSTALLED`, `NOT_RUNNING`, `TOO_OLD`, `NEEDS_PERMISSION`, `DENIED_PERMANENTLY`, `READY` (`ShizukuSetup.State`); null off Android |
| `setup.busy` | bool | A Shizuku grant is running |
| `setup.message` | Map? | `{code, detail}`: `failed` (detail = command log), `refused`, `done_restart`, `error` (detail = text) |
| `setup.adbCommands` | String? | The two `adb shell ...` lines for this package |
| `blur.state` | String? | `STARTING`, `ON`, `ON_COVERS_VISIBLE`, `NO_OVERLAY`, `MODELS_MISSING`, `FAILING` (`ScreenBlur.State`); null when not running (or not yet applied: shown as starting) |
| `blur.overlayAllowed` | bool | May draw over other apps |
| `blur.a11yBuild` | bool | This build declares the blur accessibility service (`BuildConfig.BLUR_A11Y`) |
| `blur.a11yEnabled` | bool | That service is on |
| `blur.touchPassThrough` | bool | Touches reach the app under a cover (so a full-screen fail cover is safe) |
| `blur.layerSupported` | bool | The Shizuku cover layer is possible on this device (Android 12+) |
| `blur.shizukuLayer` | bool | Shizuku is ready on Android 12+: the covers are a Shizuku shell layer (`ShizukuCovers`), nothing else to allow |
| `blur.busy` | bool | A Shizuku blur grant is running |
| `blur.message` | Map? | `{code: "setup_failed", detail}` |
| `models.detector` | bool | The women's-singing detector is bundled |
| `capabilities` | Map<String,bool> | What this platform offers, below |

Capabilities (the UI hides what is false):

| Key | Android | Desktop (now) |
|---|---|---|
| `shizukuSetup` (setup checklist, Shizuku guide, `openShizuku`, `openDeveloperOptions`) | true | false |
| `adbSetup` | true | false |
| `captureConsent` (Android asks to share the screen at start) | true | false |
| `screenBlur` | true | false (later: Windows capture + overlay) |
| `links` (open/share a link screen) | true | false (later: `yt-dlp` + `cli/im-process`) |
| `womenSinging` | true | true (the engine has the policy) |

## Settings

`setSetting` accepts only these keys (the `Settings.kt` names and defaults). Any other key or a wrong type is
`bad_args`. `lang` lives in the same file but is changed only through `setLanguage`. "Live": the running filter
and blur re-read the settings every 0.5 s (FilterService loop, ScreenBlur watchdog), so the UI shows no restart note.

| Key | Type | Default | Applies |
|---|---|---|---|
| `gender` | String `""`/`man`/`woman` | `""` (not asked yet: show onboarding) | live |
| `mute_women_singing` | bool | false | live |
| `silence_unfilterable` | bool | true | live |
| `blur_women` | bool | false | live |
| `blur_nudity` | bool | false | live |
| `blur_fail_cover` | bool | true | live; ignored unless `blur.touchPassThrough` |
| `blur_strictness` | int 0/1/2 | 0 | live (ScreenBlur watchdog). Who is left uncovered: 0 strict, 1 balanced, 2 relaxed = p(man) at least 0.999 / 0.99 / 0.98 (`Settings.blurMaleClear`). Desktop stores and shows it only |

## Methods (MethodChannel `waaiya/app`)

| Method | Arguments | Result | Android | Desktop |
|---|---|---|---|---|
| `getState` | none | snapshot | | |
| `setSetting` | `{key, value}` | null | `Settings` setters | JSON file |
| `startFilter` | none | `started`, `mic_denied`, `consent_denied`, `already_running` | Asks RECORD_AUDIO (+ POST_NOTIFICATIONS once), then the MediaProjection consent (whole screen on 14+), then starts `FilterService`. The result arrives when the dialogs are done; the state then follows through events. | TODO(engine): start the audio host through `dart:ffi`; now simulated |
| `stopFilter` | none | null | `FilterService.ACTION_STOP` | TODO(engine) |
| `runSetupStep` | `{step: 0,1,2}` | null | The checklist button: 0 = get Shizuku (store), 1 = update (TOO_OLD) or open Shizuku, 2 = grant through Shizuku (asks Shizuku's permission first if needed). Outcome in `setup.*` events. When Shizuku is installed but not running, Flutter shows the start guide for step 1 instead of calling this. | `unsupported` |
| `blurSetup` | none | null | "Allow with Shizuku" and the button under the greyed-out "cover the screen" switch: `ShizukuSetup.grantBlur`, or the store / Shizuku's permission dialog / Shizuku first. Outcome in `blur.*` events. For NOT_RUNNING Flutter shows the guide instead. | `unsupported` |
| `openShizuku` | none | null | Opens Shizuku (its store page when not installed). From the guide. | `unsupported` |
| `openDeveloperOptions` | none | null | `ACTION_APPLICATION_DEVELOPMENT_SETTINGS` when Developer options are on, else `ACTION_DEVICE_INFO_SETTINGS` (About phone, to turn them on). From the guide. | `unsupported` |
| `openOverlaySettings` | none | null | Android's "Display over other apps" page | `unsupported` |
| `setLanguage` | `{tag: "ar"\|"en"}` | null | Saved natively for the native screens, services and notifications (`Lang`); no activity restart, Flutter switches in place | JSON file |
| `openLinkScreen` | none | null | Starts the native `LinkActivity` | `unsupported` (later) |
| `getLicences` | none | `{notice, docs: [{label, file}]}` | Assets copied at build time (`copyLicences`) | Files next to the app, else a link to the repository |
| `getLicenceText` | `{file}` | String | One asset from `docs` | idem |

Reading: there is no per-key getter. Every setting and the language are in the snapshot (`getState`, and every
event), which is the getter; `setSetting` and `setLanguage` are the setters. The Shizuku start guide (wireless debugging, `guide_*` texts) is a Flutter dialog, shown from setup step 2 and from
the blur card's Shizuku button while Shizuku is installed but not running. Clipboard (the adb commands) uses
Flutter's own `Clipboard`; it needs no backend method.

## Where the desktop backend differs

- It is Dart, not a channel: `DesktopBackend implements WaaiyaBackend` in `desktop/lib/`. It stores settings and
  the language in a JSON file (`%APPDATA%\Waaiya\settings.json`, `$XDG_CONFIG_HOME/waaiya/settings.json`) with the
  same keys, so the engine host can read them the same way.
- The filter state comes from the engine host. Until the Windows host exists (`reports/desktop_windows_macos_scope.md`
  §2), start/stop is simulated and the screen says so. The hook points are marked `TODO(engine)`: load the engine
  library with `dart:ffi` (`im_engine.h`), or talk to the host service.
- No Shizuku / adb setup, no capture consent, no screen blur and no link screen yet: their capabilities are false and
  their methods throw `unsupported`. A desktop setup checklist (for example the virtual audio device on Windows)
  will add its own `setup.*` keys and capability when it exists.
- Linux already has a working host (`linux/bin/waaiya start|stop|status`); the desktop app can drive it later
  through the same `TODO(engine)` points.

## Layout and building

| Path | What it is |
|---|---|
| `ui/` | Dart package: screens, `WaaiyaBackend`, `ChannelBackend`, `MemoryBackend` (tests, desktop base), theme, l10n |
| `ui/lib/l10n/` | `app_ar.arb` (template, default) and `app_en.arb`, generated from the Android strings by `ui/tool/arb_from_android.py`; the Dart files from them by `flutter gen-l10n` (committed: path dependencies do not run it) |
| `ui_module/` | Flutter add-to-app module; `main()` runs the screens over `ChannelBackend` |
| `android/app/.../UiActivity.kt`, `UiBridge.kt` | The `FlutterActivity` behind the launcher alias `.MainActivity`, and the channel implementation |
| `desktop/` | Flutter app (Linux, Windows) with `DesktopBackend` |

```bash
cd ui_module && flutter pub get          # once: creates ui_module/.android, which android/settings.gradle.kts includes
cd android && ./gradlew assembleDebug    # -PimNativeUi: the old native main screen instead of Flutter
cd ui && flutter analyze && flutter test
cd desktop && flutter build linux        # Windows: `flutter build windows` on Windows (CI: .github/workflows/flutter.yml)
python3 ui/tool/arb_from_android.py && (cd ui && flutter gen-l10n)   # after changing res/values*/strings.xml
```

Texts: Android's `res/values*/strings.xml` stay the source of every text. Flutter-only texts are listed in
`ui/tool/arb_from_android.py` (`EXTRA`); their Arabic is not reviewed yet.

## Changing the contract

Add keys, never rename them; a backend that does not know a key leaves it out and the UI uses the default. Change
this file, `ui/lib/src/backend.dart`, `ui/lib/src/channel_backend.dart`,
`android/app/src/main/java/org/islamicmute/app/UiBridge.kt` and `desktop/lib/desktop_backend.dart` together.
