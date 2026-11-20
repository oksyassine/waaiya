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
| `version` | String | App version name (`0.2.9`; desktop: from the bundle's `engine/VERSION`, else `desktop/lib/version.dart`, checked against `desktop/pubspec.yaml` by a test) |
| `language` | String | One of `ar`, `en`, `fr`, `ur`, `id`, `tr`, `bn`, `fa`, `ms` (`appLanguages` in backend.dart, Android `Lang.ALL`). First launch: the phone's or computer's language when Waaiya has it, else Arabic; someone who used Waaiya before 0.2.12 keeps Arabic. Besides Arabic and English the texts are machine translations, not reviewed yet |
| `navigate` | Map? | `{page, id}`: a page the platform asks to show once (`filter`, `screen`, `links`, `setup`, `settings`), e.g. a Quick Settings tile's "Open Waaiya" (`UiActivity.EXTRA_PAGE`). Flutter shows it when `id` is new and calls `pageShown`. Null most of the time |
| `settings` | Map | The settings below, with their current values |
| `filter.state` | String | `STOPPED`, `STARTING`, `FILTERING`, `MODEL_FAILED`, `NO_CAPTURE_PERMISSION`, `STOPPED_BY_SYSTEM`, `CAPTURE_FAILED`, `SILENCED` (`FilterService.State`). `SILENCED`: filtering stopped by itself and `hold_silence` keeps the other apps muted (not running: the power button starts again; a "Stop: hear apps unfiltered" button calls `stopFilter`); Linux: the daemon is gone and its virtual output stayed. Desktop: `STOPPED_BY_SYSTEM` = the filter stopped by itself (the service died or failed; the screen says "Waaiya stopped"), `MODEL_FAILED` = running but its voice model did not load (silent, fail-closed) |
| `filter.problem` | String? | While `FILTERING`, what the user hears is not what filtering promises (shown instead of the "on" line, in the error colour): `too_slow` (the device cannot filter live in time), `not_muted` (the original sound is not silenced: setup missing), `mute_failing` (silencing the playing app fails), desktop `detector_failed` (women's singing on, its detector did not load: voices muted). Null: none |
| `filter.mono` | bool | Stereo was chosen but the live sound was made mono so the device keeps up (a note under the "on" line). Android: `health.monoForSpeed`, not mono by choice (the default) |
| `filter.blockedApps` | List<String> | Apps playing now that do not allow filtering (names); said as silenced or unfiltered according to `silence_unfilterable` |
| `filter.captureCancelled` | bool | Android's screen-sharing question was cancelled at the last start (until the next start) |
| `filter.delayMs` | int | Engine delay of the running filter; 0 = not measured (the screen then leaves the figure out) |
| `filter.micDenied` | bool | The microphone permission was refused at the last start (until the next start) |
| `filter.simulated` | bool | Desktop preview: start/stop are not connected to an engine yet (the screen says so) |
| `filter.error` | Map? | `{code, detail}`: why the filter could not start or stopped (desktop engine host). Codes: `no_pactl`, `no_sound_server`, `no_systemd`, `no_output`, `install_failed`, `start_failed`, `service_failed` (detail = log lines). Kept until the next start; cleared once filtering |
| `filter.autostart` | bool | The filter starts at login (capability `autostart`) |
| `setup.originalsMuted` | bool | The originals can be silenced (Android: `DUMP` granted, or helper mode: see `setup.helperMode`) |
| `setup.helperMode` | bool | Android: the phone refused the grants (Xiaomi, OPPO family), so Waaiya's shell helper (`CoverHelper`) reads the sound sessions for the app (`HelperDumps`). Android then asks before each capture (`consentSkipped` stays false and is not a missing setup) |
| `setup.helperMissing` | bool | Helper mode and the helper is not running (phone restarted, Waaiya updated, Developer options turned off): the original plays too. False during the first 6 s of a new process (a running helper has not answered yet). Flutter shows `HelperMissingBanner` (Filter and Setup pages) and warns before Start |
| `setup.helperRestarting` | bool | An automatic, silent restart of the helper is trying (at most ~25 s). A run the user started is not this: it shows the steps |
| `setup.helperTip` | String? | `xiaomi` or `coloros`: the optional Developer options switch that would make the permissions permanent (shown on the done card in helper mode) |
| `setup.consentSkipped` | bool | No screen-capture question at start (Android: app-op `PROJECT_MEDIA` = allow) |
| `setup.notificationTextNeedsSetup` | bool | Android 15+: the "Notification text" Quick Settings tile is on but `WRITE_SECURE_SETTINGS` is missing; the setup card shows again (the same setup grants it). Default false |
| `setup.deviceNote` | String? | A note under the steps: `xiaomi` (its notification style can hide the field for the pairing code), `huawei` (Wireless debugging may be missing: use a computer); null otherwise. No phone needs a switch changed before the setup any more (helper mode) |
| `setup.wireless` | Map | The setup on the phone itself (Wireless debugging, `WirelessSetup`): `supported` (Android 11+), `running`, `phase` (`WAITING`, `PAIRING`, `CONNECTING`, `DONE`, `FAILED`; null before the first run), `title` and `body` (Android string names, `wsetup_*` / `setup_refused_*`, turned into words by Flutter's `wirelessText`), `detail` (raw output, only when no sentence explains it), `isError`, `hint` (`wsetup_notif_off`, `wsetup_dev_off`, `wsetup_filter_on`: filtering runs on Android 15+, where notifications cannot be used during a screen share). For the guided steps (`wirelessSteps`), what Waaiya can see of the phone, as hints for the ticks and never as gates: `devOptions`, `wifi` (guessed from the network interfaces), `wirelessDebugging` (bool, or null when the phone does not let apps read the switch), `paired` (paired before: no code needed), `aboutHint` (where "Build number" is on this make: `samsung`, `xiaomi`, `coloros`, `vivo`, `huawei`, `transsion`, or null). Empty off Android |
| `setup.shizuku` | String? | `NOT_INSTALLED`, `NOT_RUNNING`, `TOO_OLD`, `NEEDS_PERMISSION`, `DENIED_PERMANENTLY`, `READY` (`ShizukuSetup.State`); null off Android |
| `setup.busy` | bool | A Shizuku grant is running |
| `setup.message` | Map? | `{code, detail}`: `failed` (detail = command log), `refused`, `done_restart`, `error` (detail = text), `slow` (Shizuku still starting after 20 s; not an error), `timeout` (no answer after 2 min; a later answer still updates the state), `refused_xiaomi` / `refused_coloros` (detail = log) |
| `setup.adbCommands` | String? | The `adb shell ...` lines for this package (DUMP, PROJECT_MEDIA, WRITE_SECURE_SETTINGS) |
| `blur.state` | String? | `STARTING`, `ON`, `ON_COVERS_VISIBLE`, `NO_OVERLAY`, `MODELS_MISSING`, `FAILING` (`ScreenBlur.State`), and on desktop `NO_CAPTURE`; null when not running (or not yet applied: shown as starting) |
| `blur.overlayAllowed` | bool | May draw over other apps |
| `blur.a11yBuild` | bool | This build declares the blur accessibility service (`BuildConfig.BLUR_A11Y`) |
| `blur.a11yEnabled` | bool | That service is on |
| `blur.touchPassThrough` | bool | Touches reach the app under a cover (so a full-screen fail cover is safe) |
| `blur.layerSupported` | bool | The Shizuku cover layer is possible on this device (Android 12+) |
| `blur.shizukuLayer` | bool | Android 12+ and a shell process draws the covers as a pass-through layer: Waaiya's own helper (`CoverHelper`) or Shizuku (name kept from 0.2.x). Nothing else to allow |
| `blur.helperRunning` | bool | Waaiya's own cover helper runs for this app version (`CoverHelper.available`) |
| `blur.helperStartable` | bool | The helper can be started from the Screen page: Android 12+ with the on-phone setup (it is started by the same Wireless debugging run, `wirelessStart`, when a blur option is on) |
| `blur.busy` | bool | A Shizuku blur grant is running |
| `blur.message` | Map? | `{code: "setup_failed", detail}` |
| `blur.uncovered` | int | Desktop: monitors the blur does not cover (Wayland: not shared in the screen-sharing dialog, or plugged in later); the card says so in the error colour. 0 otherwise |
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
| `audio_stereo` | bool | false | Live filter in stereo; off = mono (owner's decision, 0.2.10). Android: `Settings.audioStereo` (read live by the filter). Desktop: `waaiya stereo on\|off`, then `waaiya reload` while running; a value set on the command line is adopted by the app at its next status poll, so Start never overrides it |
| `hold_silence` | bool | true | When filtering stops by itself, other apps stay silent (`filter.state` `SILENCED`) until the user starts again or stops (owner's decision, 0.2.10). Android: `Settings.holdSilence`. Linux: `waaiya keep-silent on\|off` (adopted from the command line as above); off = the daemon moves the streams back to the real output with a desktop notice (filter keeps failing, model not loaded, daemon died: `ExecStopPost`), in the app's language (`$XDG_CONFIG_HOME/islamic-mute/notice`, written at start and on a language change) |
| `simple_mode` | bool | false | Android, TEST (0.2.13): filter without the one-time setup. While filtering, media is muted and Waaiya plays the filtered sound on the `simple_channel`; the muter does not run. `setup.originalsMuted` is true while it is on (no setup banner or warning), and the Setup page shows its card first (`SimpleModeCard`). English texts only (`simple_*`, translatable="false") until real phones prove it. Android: `SimpleMode.kt` |
| `simple_channel` | String | `alarm` | `alarm` or `notification`: the usage of Waaiya's own track in simple mode |

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
| `diagnosticsReport` | none | String | `Diagnostics.report`: what the app sees on this phone (plain text, English) | Linux: version, session, settings, filter and blur state, `waaiya status`, the service journal and the end of `filter.log` |
| `wirelessStart` | none | `started`, `dev_off`, `asking` | The on-phone setup: asks POST_NOTIFICATIONS first (the code is typed in a notification; `asking` = Android's question is open, the run goes on after it), `dev_off` = Developer options are off (Flutter offers `openAboutPhone`), else starts `WirelessSetupService` and opens Wireless debugging. With a blur option on (12+), the run also starts the cover helper. Progress in `setup.wireless` | `unsupported` |
| `openWifiSettings` | none | null | Android's Wi-Fi settings (step 2 of the guided setup) | `unsupported` |
| `wirelessEnterCode` | `{code}` | bool | A pairing code typed in Waaiya (split screen); false when it is not 6 digits | `unsupported` |
| `wirelessCancel` | none | null | Stops a running on-phone setup | no-op |
| `openAboutPhone` | none | null | Wireless debugging in Developer options, or About phone when they are off | `unsupported` |
| `openSetupGuide` | none | null | The native step-by-step guide with pictures (`SetupGuideActivity`) | `unsupported` |
| `guidePicture` | `{name}` | bytes | One picture of that guide (`guide_1_about` ... `guide_9_done`, `guidePictureNames`) in the app's language, WebP. The setup steps show the current step's pictures under its button | null |
| `pageShown` | none | null | The `navigate` page was shown: the request is cleared | no-op |
| `shareText` | `{text}` | null | Android's share sheet (the diagnostics report's Share button) | `unsupported` |

Screens (0.2.11): a bottom bar with one page per purpose, so that no page is long: Filter (the on/off control,
"one step left" with "Go to the setup", filter options), Screen (blur, who draws the covers and the helper button),
Links, Setup (on this phone, with Shizuku, from a computer; once done, a short "Setup done" card), Settings (who
uses the phone, language, start at login, diagnostics, licences). Pages without their capability are left out
(desktop: Filter, Screen with a blur, Settings). "Do the setup" in the start dialog opens the Setup page. Nodes
that UI tests use carry `Semantics(identifier:)` = the native view ids (`power`, `state_detail`, `switch_*`,
`nav_*`...), so `android/tools/emu_check.py` runs on both screens.
Screens (0.2.10, as `MainActivity`): the settings card has "Keep apps silent if filtering stops by itself" and
"Stereo sound"; the wireless-debugging setup (`wsetup_*`) is Android-only and never shown on desktop.
Screens (0.2.9, as `MainActivity`): Start without the one-time setup (`capabilities.shizukuSetup` and not
`setup.originalsMuted`) first asks "The music will still be heard" (`start_no_setup_*`: "Do the setup" scrolls to
the setup card, "Start anyway" starts); a "Problem? Diagnostics report" button at the bottom shows
`diagnosticsReport` with Copy (nothing is sent).

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
  `systemctl --user enable|disable` and `waaiya women-singing on|off` (plus `waaiya reload` while running: only
  the filter process restarts, the apps stay on the virtual output, so a change never plays unfiltered sound; an
  older installed engine without `reload` gets stop + start). The state is polled every 3 s from `waaiya status`
  (`filter:` running / restarting / down / stopped, `engine:` ok / model not loaded / detector not loaded,
  `autostart:`) and `systemctl --user is-active`; a service still starting after 20 s, or `failed`, gives
  `service_failed` with the journal's last lines. The filter keeps running when the app is closed. The delay is
  not measured there (`delayMs` 0).
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
  `blur.error`, and `"uncovered": n` to `blur.uncovered`. A helper that dies is restarted up to 3 times (the
  count goes back to 0 only after 60 s "on"), then reported as `exited`; one silent for 15 s (it prints a line at
  least every 5 s) is reported `failing` and restarted; one whose capture ended while on (`no_capture`) is
  started again; one that gave up or fails (`no_capture`, `no_overlay`, `failing`) is restarted on any change.
  Models missing from the bundle keep the card (`models_missing`, then a red bar: a permanent failure covers the
  screens for 4 s only). The Wayland
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
cd android && ./gradlew assembleDebug    # the Flutter screens (the native MainActivity screen was retired in 0.2.11)
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
