# Roadmap (2026-11-12)

What comes next for Waaiya, in order, and why. Each item names the evidence behind it: the research notes in
`research_notes/Muslim phone needs/findings.md` (needs are numbered as in its table, sources as `[S1]`, `[G3]`…),
the code audit, or a measurement in `eval/results/`.

## Rules that do not change

- The app applies the user's choice. It never decides a religious ruling: where scholars differ, it is a setting.
- The filter and the blur run on the device and send nothing. No account, no analytics. Only "Open a link" goes
  online: to the site of the link, and to PyPI for yt-dlp updates.
- Fail-closed: when the app is unsure or broken, the user gets silence or a cover, never unfiltered content.
- Arabic first, with an English switch. No root.
- Current features come before new ones.

## Done in 0.2.10: audit fixes, mono by default, silence when filtering ends by itself

| Problem | Cause | Fix |
|---|---|---|
| Without Shizuku, covers let a fifth of the picture show through, and taps went through them (Android 12+) | Android forces a non-touchable app overlay to 80% opacity so that touches can pass (`alpha=0.8` in `dumpsys window` on the API 35 emulator); the code assumed opaque covers that hold touches back | From Android 12, app-overlay covers are touchable windows, so Android keeps them fully opaque; a tap on a cover stays on the cover. Android 10/11 have no such rule: covers there stay opaque and let taps through, as before |
| ...and then the space between two covers could not be tapped or scrolled | One app-overlay window spanned all covers, and a touchable window takes every touch inside its bounds | One window per group of touching covers, at most 8, reused from frame to frame; every window gets the skip-screenshot flag before it shows a cover (`CoverWindows`, `BlurOverlay`) |
| Shizuku cover layer could say "on" with nothing drawn | Drawing calls are one-way, and an error in the shell process was only logged there; the host counted as Shizuku during the whole bind | `start()` draws a hidden probe cover through the same calls and fails on any error; a two-way `health()` call twice a second reports draw errors; on failure the covers move to a window. "Starting" until the layer is confirmed |
| A fallback from the Shizuku layer to a window kept "covers not in the capture" | The self-test ran only when the blur was switched on | Any change of the drawing host re-runs the self-test |
| A foldable that unfolds without rotating kept the old capture shape | Only a portrait/landscape flip resized the capture | Resized whenever the shape differs, also checked twice a second |
| Accessibility build: a switched-off service was not noticed | Nothing checked it after attach | The watchdog moves the covers to another host or reports that none is left |
| Android 10/11 window covers (and Linux): the whole-screen nudity cover lifted every 3 s over a video | The capture shows the cover, not the picture, so the detection stops and the cover expires | In the shared tracker, each re-detection right after a lift doubles the next hold, up to 60 s (`full_max_hold_ms`) |
| A failed blur start said "starting" for the whole session | An exception from the capture setup was swallowed and leaked its thread | Caught and cleaned up; the blur line says Android did not let it see the screen (state `NO_CAPTURE`) |
| Player: AC-3 / E-AC-3 / DTS could reach a TV or soundbar unfiltered | Media3 sends such tracks encoded ("passthrough") to an output that takes them, around the filter | The audio sink only accepts PCM, so every track is decoded and filtered |
| Player: any app could make Waaiya fetch chosen URLs with chosen headers | The exported player read a stream list from any intent | Stream lists are read only by a non-exported `LinkPlayerActivity` |
| Player played on in the background with no control | No `onStop` | Pauses when left |
| Link saving: no handler for Android 15's time limit on its service | `onTimeout` missing | Cancels (no partial file, gallery entry removed), says why, stops at once |
| yt-dlp self-update named the app to PyPI and took nightlies after any failure | Custom User-Agent; no age check | Python's default User-Agent; stable releases only once 3 days on PyPI, nightlies only after a failed link and 1 day old, the pinned yt-dlp-ejs too |
| A long press on selected text in the diagnostics report crashed the app (Android 15) | Android throws "Drag shadow dimensions must be positive" when dragging some selections | That drag is ignored; copying still works |
| Release APKs built by CI had no blur models; no tests ran there | `fetch_deps.sh` fetched only the voice model; the workflow only built | Blur models fetched and checked; a release build fails if a bundled model is missing; JVM and C tests run first; fail-closed engine tests added |

Owner decisions, 2026-11-12:

| Decision | What the app does |
|---|---|
| Mono is the default for the live filter | A "Stereo sound" setting, off by default: mono uses about half the battery and keeps up on more phones. It switches live both ways (the engine is always built with one model state per channel). With stereo chosen, a phone that is too slow still drops to mono by itself, and only then does the screen say so |
| When Android ends filtering, other apps stay silent | "Keep apps silent if filtering stops by itself", on by default. When the capture stops or dies (not the user's Stop), the capture, filter and blur end but the service and its muter keep running: the screen and the notification say "Filtering stopped: other apps are silenced", with start again and Stop. Off, or without the one-time setup (nothing can be muted then): as before, the sound comes back with the "Waaiya stopped" notification |

Checked without a phone: 27 JVM tests (now with `CoverWindowsTest`), the tracker tests (`models/vision/test_cover.py`,
the 3 s lift reproduced and gone), `build/test-failclosed`, 28 link-updater tests, and `emu_check.py --setup done
--blur --end-capture --blur-fail` on the Android 15 emulator: covers opaque, one window per group, a tap between
covers reaches the app and a tap on a cover does not, the service stays in the foreground 73 s after the capture
ended with the other app's session still muted, start again and Stop from there, the blur capture failure shown.
The same on the Android 11 emulator (covers in the capture there, so the cautious mode). By hand on Android 11: a
screen size change without rotation (`wm size`) resizes the capture both ways; the accessibility build moves the
covers to an app overlay when the service is switched off and runs the capture test again; "Stereo sound" applies
while filtering, both ways (the loaded emulator then fell back to mono by itself, as designed). On Android 15:
the exported player closes on a stream list, `LinkPlayerActivity` cannot be started from outside, and the player
pauses when left. Not checked: the Shizuku probe and health call (no Shizuku on the emulators), passthrough on a
real TV output, the export time limit (needs hours of saving or a system override), a real foldable, sound by ear.

## Done in 0.2.9: the live filter says what is wrong and adapts to the phone

Found by running the app on emulators in the state of a phone that never installed Shizuku
(`android/tools/emu_check.py`), and by reading the audio path.

| Problem | Cause | Fix |
|---|---|---|
| Sound cuts on some phones, with no message | The model must finish each 10 ms hop in under 10 ms. Stereo runs it twice per hop (about 7 ms on a desktop core). A slower phone drops sound at the capture and at the output; nothing measured or reported it | The filter times every hop and counts dropouts (`LoadMonitor`). Too slow in stereo: it mixes to mono, half the work, and remembers that for a week. Too slow even in mono: the screen and the notification say so and point to "Open a link", which filters before playing. Android 12+: the audio thread asks the system for a fast core |
| "Instruments are removed from all apps" shown while the music was still heard | Without the one-time setup the original sound cannot be silenced; the state line did not depend on it | Start without setup opens a dialog first. While running, the state line and the notification say the original is not silenced |
| On Android 10 and 11 the original was never silenced, even with the setup done | The session list was read from a system dump that has session numbers only from Android 12 | Sessions come from the audio policy dump, which has them on every version, with the real "refuses capture" flag (`AudioDump`, tested against dumps from Android 11 and 15 emulators) |
| The app stayed "on" with no sound when capture died | A failed read was retried forever | A dead capture stops the filter with its own message. A cancelled screen-sharing question explains why it is asked |
| Nobody could tell which of these a phone had | No numbers were kept | "Problem? Diagnostics report" at the bottom of the screen: setup state, speed per hop, dropouts, what is silenced, blur speed. Copy or share; the app sends nothing |
| Delay grew after a slow start or a stall and never came back | Late sound stays in the output buffer as extra delay | Delay that the phone's slowest recent hop does not need is given back during silence |
| Apps that refuse capture went silent without explanation | Not shown | The state line names the app: silenced, or playing unfiltered, by the user's setting |
| Filtering ended by Android left no trace | The "on" notification just disappeared | A "Waaiya stopped: the sound is not filtered any more" notification |
| Blur: an immodest image could stay uncovered on a still screen | Android sends a frame only when the screen changes; the nudity model runs a few times a second and the detector tiles may take turns, so the last frame could miss both | The last frame is kept and passed again until every model and tile has seen it (`ScreenBlur.process`) |
| Blur: a build without blur models covered the whole screen for good | A missing model was treated like a passing failure | Badge and status line instead of a cover |
| Links: the retry with yt-dlp's nightly build was blocked for an hour by the daily check; a failed save left its progress notification; a killed save left the downloaded original in the cache | Shared time stamp; wrong stop mode; cleanup only on a clean exit | Separate stamp; notification removed; cache cleared at app start |
| Settings and the downloaded yt-dlp could leave the phone in Android's backup | Backup was not switched off | No cloud backup, no device transfer |

Checks that run without a phone: 19 JVM tests (load monitor, session list parser), an engine test for the mono
switch, and `emu_check.py` on Android 11 and 15 emulators with the setup missing and done, with a native build
("fast phone") and the release build under ARM translation ("slow phone").

Not provable without a phone, so still open: how many real phones need mono, sound quality by ear, Bluetooth.
The diagnostics report is how those answers will come back.

## Next, in order

1. **Setup without a second app.** Today the setup needs Shizuku or a computer; it is longer than any
   competitor's, and a crash or confusion during first-run setup is a known reason people give up (finding 3.16).
   - a. Pair with Android's wireless debugging from inside Waaiya (Android 11+) and run the two grants directly.
     Shizuku stays optional, for the touch-through blur layer. Large: needs the ADB pairing protocol in the app.
   - b. A "use a computer" page that does the grant from Chrome over USB (WebUSB), no ADB install. Medium.
2. **A lighter live model, and measured battery and heat** (need 3: the most common complaint about every similar
   tool). Benchmark model variants on ARM through the diagnostics numbers; try the two channels on two threads
   for those who choose stereo (mono is the default since 0.2.10); publish per-phone figures.
3. **Blur quality where users judge it** (need 2, finding 3.1, 3.2): shorten the first-frame gap, small
   thumbnails, drawn and 3D figures (anime, games: need 10). Evaluate before changing models.
4. **Protection that survives a weak moment** (need 4, [C1] [C3]): a waiting period, chosen in advance, before
   switching off or weakening takes effect; a local PIN for parents (need 8). Local only: no partner reports,
   no uninstall blocking (they need a server or an accessibility service).
5. **Fix mistakes on the spot** (need 7): cover an area by hand, turn the filter or blur off for one app, and a
   local "wrong detection" note the user can export himself.
6. **Keep singing as an option** (need 1, lectures with a nasheed under them [S6]): finish `voice_v1`; a setting,
   since what counts as acceptable differs.
7. **Proof of the privacy claim** (need 5): a plain privacy page, a test that the filter and blur paths open no
   network connection, reproducible-build notes. Competitors' store labels contradict their claims
   (finding 2.6); this is cheap and sets Waaiya apart.
8. **Worship helpers that reuse what Waaiya already holds** (needs 9, 16): silent at prayer times and an optional
   "mute media at the adhan", computed on the phone from a city the user picks, each action announced in a
   notification ([W3]). Off by default. Well served by other apps, so small scope only.
9. **Plain tones helper** (need 15): one screen that sets a plain ringtone and notification tone. Ring and
   notification sound cannot be filtered, only replaced.
10. **More languages** (need 11): Urdu, Indonesian, Malay, Turkish, French, Persian. Each needs a native reviewer;
    "Arabic that needs fixing" is itself a complaint (finding 3.15).
11. **Distribution**: decide on Google's developer verification (live in Indonesia, Brazil, Singapore, Thailand
    since 2026-09-30, global in 2027 [D5]; it needs an identity check); a Play build without the link
    downloader's self-update; F-Droid.
12. **Other platforms**: Windows engine and blur; Linux blur on real Wayland sessions; Android TV (need 8,
    [G6]); iPhone in-app player and Safari extension (need 12).

## Known defects, not fixed yet (code audit, 2026-11-12)

Android:
- When the capture ends by itself the blur stops too, so the screen is uncovered while the sound stays silent
  (see "Done in 0.2.10"). Keeping a cover would need its own decision: nothing can be analysed then.
- `im_engine_set_enabled(e, 0)` (the Linux LADSPA plugin's A/B switch) passes the original through even on an
  engine whose model failed to load. Android never calls it.

Linux and desktop (branch `flutter-ui`): the 2026-11-12 audit's items are fixed there, not released yet:
- Fixed: a nudity cover over a still image came back no more after 3 s (the last frame is now analysed again
  until every pass ran; test_x11.py checks it with a fake nudity result).
- Fixed: capture failure is counted per monitor, a closed screen-cast session is reported, and a monitor the
  blur does not see is said in the app ("a monitor is not covered"). Still open: a monitor plugged in after the
  share dialog is only reported, not added (turning a blur option off and on asks again).
- Fixed: the women's-singing switch reloads the filter only (no unfiltered sound); streams the sound server puts
  back on the real output are moved again every second.
- Fixed: a permanent blur failure covers the screens for 4 s, then the red bar; the helper is restarted when its
  capture ends or it hangs.
- Fixed: the frame grab could read freed memory on a format change; GNOME/XWayland follows a resolution change.
- Fixed: `filter.log` is bounded; "running" checks the daemon, the filter and its model; the version comes from
  the build.
- Not verified on real hardware yet: multi-monitor Wayland (portal) and a resolution change under GNOME are
  covered by code review and unit tests only; CI runs Xvfb and sway headless with one output.
- Open: a filter that keeps crashing between two status polls still reads as filtering; mono by default
  (0.2.10) not yet heard on a real sound server. Done in 0.2.10: the stereo and keep-silent switches, "Stop:
  hear apps unfiltered" while apps are held silent, the desktop notice in Arabic or English.

CI: no release asset holds the women's-singing detector, so release APKs built by CI have no women's-singing
filter (the build warns) and `test-detector` is skipped there with a notice. The owner decides whether to publish
`detector_v1.onnx` as a release asset. No test yet covers the blur loop on a device or the link export.

## Not building

| Idea | Why not |
|---|---|
| Prayer times, adhan and qibla as an app of its own | Crowded and free elsewhere; location data is where users lost trust [T3] |
| Website filtering by DNS or VPN | Needs servers; done at scale by others [C5] |
| Hiding Reels and Shorts inside other apps | Needs an accessibility service tied to each app's layout; breaks with their updates |
| Partner reports, remote parental dashboards, uninstall blocking | Send data off the phone or need device-admin powers |
| Filtering links on a server | Against "nothing is sent"; it is what users wait on elsewhere [S13] |
| Blocking ads | Forbidden on Play [D4]. Removing instruments from an ad's sound is a different act |
| Any built-in ruling or "is this allowed" score | The app applies the user's choice |

## Decisions that belong to the owner

- Developer verification: register (identity check) or rely on the advanced install flow.
- Whether the waiting period (item 4) may delay switching the filter off, or only weakening the blur.
- Whether to publish the women's-singing detector (`detector_v1.onnx`) as a release asset, so CI-built APKs
  include it.
