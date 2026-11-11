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
| `filter.delayMs` | int | Engine delay of the running filter; 0 = not measured (the screen then leaves the figure out) |
| `filter.micDenied` | bool | The microphone permission was refused at the last start (until the next start) |
| `filter.simulated` | bool | Desktop preview: start/stop are not connected to an engine yet (the screen says so) |
| `filter.error` | Map? | `{code, detail}`: why the filter could not start or stopped (desktop engine host). Codes: `no_pactl`, `no_sound_server`, `no_systemd`, `no_output`, `install_failed`, `start_failed`, `service_failed` (detail = log lines). Kept until the next start; cleared once filtering |
| `filter.autostart` | bool | The filter starts at login (capability `autostart`) |
| `setup.originalsMuted` | bool | The originals can be silenced (Android: `DUMP` granted) |
| `setup.consentSkipped` | bool | No screen-capture question at start (Android: app-op `PROJECT_MEDIA` = allow) |
| `setup.shizuku` | String? | `NOT_INSTALLED`, `NOT_RUNNING`, `TOO_OLD`, `NEEDS_PERMISSION`, `DENIED_PERMANENTLY`, `READY` (`ShizukuSetup.State`); null off Android |
| `setup.busy` | bool | A Shizuku grant is running |
| `setup.message` | Map? | `{code, detail}`: `failed` (detail = command log), `refused`, `done_restart`, `error` (detail = text) |
| `setup.adbCommands` | String? | The two `adb shell ...` lines for this package |
| `blur.state` | String? | `STARTING`, `ON`, `ON_COVERS_VISIBLE`, `NO_OVERLAY`, `MODELS_MISSING`, `FAILING` (`ScreenBlur.State`), and on desktop `NO_CAPTURE`; null when not running (or not yet applied: shown as starting) |
| `blur.overlayAllowed` | bool | May draw over other apps |
| `blur.a11yBuild` | bool | This build declares the blur accessibility service (`BuildConfig.BLUR_A11Y`) |
| `blur.a11yEnabled` | bool | That service is on |
| `blur.touchPassThrough` | bool | Touches reach the app under a cover (so a full-screen fail cover is safe) |
| `blur.layerSupported` | bool | The Shizuku cover layer is possible on this device (Android 12+) |
| `blur.shizukuLayer` | bool | Shizuku is ready on Android 12+: the covers are a Shizuku shell layer (`ShizukuCovers`), nothing else to allow |
| `blur.busy` | bool | A Shizuku blur grant is running |
| `blur.message` | Map? | `{code: "setup_failed", detail}` |
| `blur.error` | Map? | Desktop: `{code, detail}` from the blur helper. `no_capture`, `no_overlay`, `models_missing`, `failing` (detail = the helper's reason, English, shown under the translated status), `share_dialog` (Wayland: the screen-sharing dialog waits for the user; no detail), `exited` (the helper stopped by itself; detail = exit code and its last lines). Null otherwise |
| `models.detector` | bool | The women's-singing detector is bundled |
| `capabilities` | Map<String,bool> | What this platform offers, below |

Capabilities (the UI hides what is false):

| Key | Android | Desktop (now) |
|---|---|---|
| `shizukuSetup` (setup checklist, Shizuku guide, `openShizuku`, `openDeveloperOptions`) | true | false |
| `adbSetup` | true | false |
| `captureConsent` (Android asks to share the screen at start) | true | false |
| `screenBlur` (blur card, and "who is left uncovered" inside it, the only place it is shown) | true | Linux: true when the bundle has `engine/build/im-blur` and the three models. Windows: false (later: capture + overlay), so the strictness row is not shown anywhere |
| `blurStandalone` (the blur runs while a blur option is on, filtering on or off; the card's texts say so) | false (the blur runs while filtering: it shares the screen capture) | Linux with the blur |
| `links` (open/share a link screen) | true | false (later: `yt-dlp` + `cli/im-process`) |
| `womenSinging` | true | only when the engine bundles the detector (without it the engine mutes all voice while the option is on) |
| `autostart` (start at login) | false | Linux with the bundled engine |

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
| `blur_fail_cover` | bool | true | live; ignored unless `blur.touchPassThrough` (desktop: always true, clicks pass through the covers) |
| `blur_strictness` | int 0/1/2 | 0 | live (ScreenBlur watchdog; desktop: sent to the helper). Who is left uncovered: 0 strict, 1 balanced, 2 relaxed = p(man) at least 0.999 / 0.99 / 0.98 (`Settings.blurMaleClear`, `ib_male_clear`). Desktop without a blur (Windows) stores it only and does not show it |

## Methods (MethodChannel `waaiya/app`)

| Method | Arguments | Result | Android | Desktop |
|---|---|---|---|---|
| `getState` | none | snapshot | | |
| `setSetting` | `{key, value}` | null | `Settings` setters | JSON file |
| `startFilter` | none | `started`, `mic_denied`, `consent_denied`, `already_running`, `failed` (see `filter.error`) | Asks RECORD_AUDIO (+ POST_NOTIFICATIONS once), then the MediaProjection consent (whole screen on 14+), then starts `FilterService`. The result arrives when the dialogs are done; the state then follows through events. | Linux: checks (`pactl`, sound server, `systemd --user`, a real output), installs or updates the bundled engine (`engine/VERSION`), sets `women-singing`, then `waaiya start`. Windows: TODO(engine), simulated |
| `stopFilter` | none | null | `FilterService.ACTION_STOP` | Linux: `waaiya stop` (normal audio back, virtual output removed). Windows: TODO(engine) |
| `runSetupStep` | `{step: 0,1,2}` | null | The checklist button: 0 = get Shizuku (store), 1 = update (TOO_OLD) or open Shizuku, 2 = grant through Shizuku (asks Shizuku's permission first if needed). Outcome in `setup.*` events. When Shizuku is installed but not running, Flutter shows the start guide for step 1 instead of calling this. | `unsupported` |
| `blurSetup` | none | null | "Allow with Shizuku" and the button under the greyed-out "cover the screen" switch: `ShizukuSetup.grantBlur`, or the store / Shizuku's permission dialog / Shizuku first. Outcome in `blur.*` events. For NOT_RUNNING Flutter shows the guide instead. | `unsupported` |
| `openShizuku` | none | null | Opens Shizuku (its store page when not installed). From the guide. | `unsupported` |
| `setAutostart` | `{on}` | null | `unsupported` | Linux: `systemctl --user enable\|disable islamic-mute.service` (installs first; does not start or stop the filter now) |
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
- Linux: the app bundle carries the engine (`engine/`, made by `desktop/tool/bundle_engine.sh`: `linux/bin/waaiya`,
  the systemd unit template, `build/` binaries with ONNX Runtime, `models/dfn3/`, and `VERSION`). `LinuxEngine`
  (`desktop/lib/linux_engine.dart`) installs it with the unchanged `waaiya install` when the installed
  `~/.local/share/islamic-mute/VERSION` differs, then drives the systemd user service with `waaiya start|stop`,
  `systemctl --user enable|disable` and `waaiya women-singing on|off` (plus a restart while running). The state is
  polled every 3 s from `waaiya status` (`filter:`, `autostart:`) and `systemctl --user is-active`; a service
  still starting after 20 s, or `failed`, gives `service_failed` with the journal's last lines. The filter keeps
  running when the app is closed. The delay is not measured there (`delayMs` 0).
- Windows: until its host exists (`reports/desktop_windows_macos_scope.md` §2), start/stop is simulated and the
  screen says so (`TODO(engine)`: load the engine library with `dart:ffi` (`im_engine.h`), or talk to a host
  service). A development run without the bundled engine is simulated too.
- Linux screen blur: `desktop/lib/linux_blur.dart` runs the bundled helper `engine/build/im-blur` (C,
  `linux/blur/`, models in `engine/models/vision/`) as a child of the app while `blur_women` or `blur_nudity` is
  on, whether filtering runs or not (capability `blurStandalone`). Being a child, it gets the session as it is
  (`DISPLAY`, `WAYLAND_DISPLAY`, `DBUS_SESSION_BUS_ADDRESS`, `XDG_RUNTIME_DIR`, `XAUTHORITY`); a systemd user unit
  would only have them if the desktop imported them. Closing the app stops the blur (the card says so). Protocol:
  started as `im-blur --models DIR --policy N --strictness N --fail-cover 0|1 --token-file F`; settings changes
  go to its stdin (`policy N`, `strictness N`, `fail_cover 0|1`, `quit`); it prints JSON lines `{"state",
  "error", "backend", "overlay", "covers", "ms"?, "cpu"?, "fps"?}` with state `starting`, `on`,
  `on_covers_visible`, `failing`, `models_missing`, `no_capture`, `no_overlay`, `idle`, mapped to `blur.state` /
  `blur.error`. A helper that dies is restarted up to 3 times, then reported as `exited`. The Wayland
  screen-sharing permission is kept in `$XDG_CONFIG_HOME/waaiya/screencast-restore-token`. `blur.touchPassThrough`
  and `blur.overlayAllowed` are always true there (no permission to ask; clicks pass through the covers).
- No Shizuku / adb setup, no capture consent, no link screen, and no screen blur on Windows yet: their capabilities
  are false and their methods throw `unsupported`. A desktop setup checklist (for example the virtual audio device on Windows)
  will add its own `setup.*` keys and capability when it exists.
- Manual audio checks (no sound server on the build machine): `desktop/TESTING.md`.

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
