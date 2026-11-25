# Status (2026-11-25, 0.2.18: "Check for music" from the share menu; 0.2.19 being prepared: blur never stuck, sound drift after an hour, clearer notification-text tile)

What comes next, and why: `docs/ROADMAP.md`.

| Part | State | Evidence |
|---|---|---|
| Test set + scoring | done | `testset/`, `eval/results/summary.md` |
| Engine (C, ONNX Runtime) | done | parity >100 dB vs PyTorch, 30 ms delay on the hop-aligned path; stereo about 7 ms and mono about 3 ms per 10 ms hop on a loaded desktop core (`build/test-mono`); mono can be switched on a running engine |
| Linux always-on | done, live-tested on PulseAudio | `linux/test_run.sh`: 24 dB suppression, crash restarts fail-closed; delay in `eval/results/latency.md` |
| Android live filter | released (0.2.14); 0.2.9 and 0.2.10 used on a Galaxy S24 and a Xiaomi | Mono by default with a stereo setting (0.2.10); adapts to the phone (mono fallback, dropout counting), says when the original is not silenced or the phone is too slow, diagnostics report. When Android ends filtering, other apps stay silent by default (0.2.10). Checked on emulators with `android/tools/emu_check.py`; 27 JVM tests |
| Android: silence the originals | done; helper mode not proven on a real Xiaomi/OPPO | Session list from the audio policy dump (Android 10+); one-time grant on the phone (Wireless debugging, Android 11+), with Shizuku or ADB; slow-Shizuku handling (0.2.11). 0.2.12: guided four-step setup page; phones that refuse the grant (Xiaomi, OPPO family) use Waaiya's shell helper for the session list instead of a hidden Developer options switch (`docs/SETUP.md`), checked on emulators with a simulated refusal |
| Android: simple mode (test) | in 0.2.14 as a "Simple mode (test)" card on the setup page (not named in the 0.2.14 release notes); emulators only; English texts only | For people who will not do the one-time setup: media is muted while Waaiya filters and its own sound plays on the alarm or notification channel (a setting); the mute is recorded first and undone on Stop, when the service ends and after a crash; volume keys become Waaiya's own volume (`SimpleMode.kt`). `emu_check.py --simple` passes on API 30 and 35. Open on real phones: is the channel heard with media muted, earphones (alarm also rings on the speaker), vibrate and Do Not Disturb, Bluetooth absolute volume; the diagnostics report has a "Simple mode" section for this |
| Android: updates inside the app | released (0.2.14); the first real update is the one after 0.2.14 | Daily check of one file on waaiya.mssid.org (never while filtering; can be turned off), notification, a zstd patch rebuilt on the phone (6 MB instead of 108 MB) checked against the published SHA-256, version and signing certificate, full APK as fallback; goes through the PIN and waiting period like Stop. Not in `-PimPlay` builds. `AppUpdateTest`, `app_update_test.dart`; emulator API 35: notification, patch and installer 10/10, a broken patch fell back to the full APK. Patches made by `site/make_update.py` from the APKs in `/srv/build/waaiya-downloads` |
| Android: the move to org.waaiya.app | 0.2.15 | Two builds from one source: `org.waaiya.app` for everyone, and the old name's last version (`-PimMoveBuild`, through 0.2.14's in-app update), which installs the new app; the new app takes the old one's settings through a signature-protected provider and offers to remove it. Emulator API 35: install, settings, removal; 0.2.14 updated in place to the move build. `docs/MOVE.md` |
| Android prayer times: "Use my location", Morocco = Ministry of Habous | 0.2.16 | The approximate location, read once when the user taps (Android asks first). In Morocco the nearest of the ministry's 190 cities and its official table (positions and altitude horizons fitted to habous.gov.ma's October and November 2026 tables by `scripts/habous/make_habous.py`: every city within 1 minute, 97% to the minute, `WorshipHabousTest`); elsewhere the coordinates and the user's choice of method, the country's preselected. Phones with time-zone data older than 2026c show Moroccan times on GMT. Emulator API 35: Salé → Rabat with the ministry's times; Saint-Denis → "near Paris", method list with France preselected |
| Android: setup from a computer in the browser | in 0.2.15 (waaiya.mssid.org/usb) | Chrome or Edge over USB (WebUSB), nothing to install; also Android 10 and phones without Wireless debugging. Tested against an emulator's adbd and with a simulated USB phone; not yet with a real phone. `docs/SETUP.md` |
| Android: Quick Settings tiles, icon shortcuts | done (0.2.11) | "Waaiya" tile and Start/Stop shortcuts on the icon; "Notification text" tile (Android 15+) shows notification text while filtering |
| Open a link (YouTube, TikTok, Instagram) | done | Video links stay video; saved files keep the original picture with filtered sound |
| Screen blur (Android) | released | Person detector with tiles, woman/man classifier v2, outlines, steady covers: `eval/results/blur_*.md`. 0.2.10: one window per cover group without Shizuku, checked Shizuku layer, self-test on every host change. Speed on phones not measured |
| Women's-singing detector | engine + Linux + Android + Windows wired; model v1 bundled, in the `models-v1` release since 0.2.12 | `models/detector/test_detector_engine.py` |
| Model shrink | done: int8 weights 2.4 MB, within 0.2 dB | `eval/results/shrink.md` |
| Own voice model (keeps singing) | trained on Kaggle, not the default | roadmap item 6 |
| Flutter UI (Android main screen since 0.2.11, pages with a bottom bar), Linux desktop app | Android: released; desktop: preview | Sound filter and X11 blur work; Wayland blur untested on real sessions |
| Languages | 18: Arabic and English written for the project; Bengali, Dutch, French, German, Hausa, Indonesian, Italian, Malay, Persian, Russian, Somali, Spanish, Swahili, Turkish, Urdu and Uzbek machine-translated (0.2.12), not reviewed by native speakers | `ui/tool/check_translation.py` (every text, format arguments, escaping), `ui/test/languages_test.dart` (each page in each language on a small phone, no overflow), setup pictures retaken per language (`android/tools/guide_shots.py`) |
| Windows: icon next to the clock, "Start at login" | 0.2.17 | Tray icon in the app's window (`desktop/windows/runner/tray.cpp`, `ui/lib/src/tray.dart`): a click opens the window; its menu has Open, Start or Stop filtering (Stop through the waiting period and the PIN, like the power button) and Quit; closing the window hides it there; a second start shows the first window. At login the app starts hidden (`--tray`): the Store package's filter starts it, a plain install has a Run value. "Start at login" in the Store package asks Windows to let the startup task run (`startup.cpp`, `RequestEnableAsync`); one turned off in Settings > Apps > Startup opens that page. Small icons (16-48 px) keep the ear (`desktop/tool/make_icons.py`), and so does the Android status bar and Quick Settings tile icon (`ic_notification.xml`, the whole mark). Widget tests `ui/test/tray_test.dart`, engine tests `desktop/test/windows_engine_test.dart`; tried on a PC with a development build (icon, menu, hide on close, second start); Windows' startup question not yet seen (needs the Store package) |
| Windows desktop app (filter + blur) | preview, released as a zip and in the Microsoft Store (Store ID 9NBB296FSRJP); not signed (SignPath: the repo side is ready, the SignPath project and the `SIGNPATH_*` settings are not set up) | CI on Windows Server 2022 and 2025 with a virtual output: `windows/test/audio_test.py` (route C2 measured: level back within 0.03 dB, HNR > 120 dB; tone suppressed about 47 dB, about 50 ms delay; new apps lowered before their first sound; crash, stop, restore), `windows/test/blur_test.py` (covers out of the capture on 2025, in it on 2022; click-through; fail-closed; models). Not yet on a real PC |
| Website, logo | live: waaiya.mssid.org (Arabic and English, downloads, privacy policy, try on your own sound); the logo since 0.2.13 | `site/`; a timer deploys every commit on main that changes the page |
| macOS, iOS | not started | `docs/PLATFORMS.md`; macOS needs an Apple Developer ID (the capture permission is tied to the signature). iOS cannot filter or silence other apps, so simple mode cannot be ported (one volume for all app sound, no second channel); the routes left are a Safari web extension, an in-app player for shared files, and AirPlay or Bluetooth to a desktop running Waaiya |

Baseline DeepFilterNet3: speech kept (-2.6 dB) with 21-24 dB instrument suppression; recitation (-13 dB) and singing (-25 dB) are lost, hence the own voice model.

## Not verified on a real phone or PC yet
- The move to org.waaiya.app on a real phone, and the setup page waaiya.mssid.org/usb with a real phone and cable.
- "Use my location" on a real phone (network or GPS fix indoors, phones without Google's location services).
- Simple mode (see its row above).
- An update from one release to the next through the app (the first one is after 0.2.14).
- The Windows app on a real PC: speakers, Bluetooth, players with copy protection, several monitors.
- How many phones need the mono fallback, and how it sounds there (the diagnostics report will tell).
- Blur speed with outlines and tiles; the shell cover layer (Waaiya's own helper, 0.2.11, or Shizuku) on a real
  phone and on Android 12 to 14 (checked on the API 35 emulator only: `docs/SETUP.md`).
- The Xiaomi/OPPO refusal messages against real output; notification text during capture on a real Samsung.
- Bluetooth output delay.

## Done earlier (approved list)
1. Women's-singing detector: streaming classifier (singing / speech / recitation x male / female) on the vocal stem, gating the output via `im_engine_set_gate`. Labels: LibriSpeech SPEAKERS.TXT, VocalSet singer ids, a female Quran reciter; optional LFM3-Audio-2B auto-labelling on Kaggle (2B parameters: labeller only, not live).
2. Shrink the model (fp16 / int8) and re-score on the test set.
3. Shizuku support so Android users can grant the muting permission without a computer.
4. Report on hosting / gender / sync research (`research_notes/Instrument muting hosting gender sync/`).

## After the Kaggle run
Download outputs (`uvx --with six kaggle kernels output KAGGLE_USER/islamic-mute-voice-train -p DIR`), check `eval_summary.md`
(accept if recitation/singing voice retention ~-3 dB or better, suppression >20 dB, music-only leak <-30 dB),
then `islamic-mute model voice_v1.onnx` and `./gradlew assembleDebug -PimModel=/path/voice_v1.onnx`.
