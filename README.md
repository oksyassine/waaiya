# Waaiya · واعية

[![Android](https://github.com/oksyassine/waaiya/actions/workflows/android.yml/badge.svg)](https://github.com/oksyassine/waaiya/actions/workflows/android.yml)
[![Linux engine](https://github.com/oksyassine/waaiya/actions/workflows/linux.yml/badge.svg)](https://github.com/oksyassine/waaiya/actions/workflows/linux.yml)
[![License: AGPL-3.0-or-later](https://img.shields.io/badge/license-AGPL--3.0--or--later-blue.svg)](LICENSE)

> «وَتَعِيَهَا أُذُنٌ وَاعِيَةٌ», "and that a heedful ear would retain it" (al-Ḥāqqah 69:12)

Waaiya removes musical instruments from everything your device plays and keeps the voice: speech, Quran
recitation, lectures. It runs on the device, in real time, and fails closed: if the filter itself cannot run, you
hear silence, never the unfiltered sound. (On Android, when the system ends the capture, filtering stops and a
notification says the sound is no longer filtered.) (The project was called "Islamic Mute" before; some internal names, such as
the Android package `org.islamicmute.app` and the Linux service, keep the old name so existing installs update.)

| Platform | Status | How it works |
|---|---|---|
| **Android** 10+ | Works (phones: arm64, armv7) | Captures every app's sound, filters it, mutes the original. Also: open or share a YouTube/TikTok/… link to watch or save it without music. Optional screen blur (women, immodest images) over every app. |
| **Linux** (PulseAudio, PipeWire-Pulse) | Works | Virtual output + always-on user service (`waaiya install`, `waaiya start`). |
| **macOS** 14.4+ | Planned | Core Audio process tap; see [docs/PLATFORMS.md](docs/PLATFORMS.md). |
| **Windows** 10/11 | Planned | Per-app loopback capture or a virtual device; see [docs/PLATFORMS.md](docs/PLATFORMS.md). |
| **iOS / iPadOS** | Limited by Apple | No app may change other apps' sound. Planned: in-app player for links, Safari extension. |
| **Browsers** | Planned | Extension filtering the tab's media (desktop Chrome, Firefox, Edge, Safari). |

The Android app is Arabic first, with English in its settings (Android 13+ also lists both in the system's
per-app language settings).

Download the Android app from the [releases](https://github.com/oksyassine/waaiya/releases). How each platform
is handled, and what is shared between them: [docs/PLATFORMS.md](docs/PLATFORMS.md).
Research behind the design: `reports/System wide instrument muting app.md`.

## Layout

| Path | What it is |
|---|---|
| `engine/` | C11 streaming engine on the ONNX Runtime C API. Loads any model that follows the contract below. Same code for Linux, Android (NDK), macOS, Windows. |
| `models/dfn3/` | Streaming export of DeepFilterNet3 (speech mode) + parity tests against the official implementation. |
| `models/voice/` | Training of our own model that keeps speech, Quran recitation and singing (stage 3). |
| `models/vision/` | Screen blur models: export of the person and nudity models, our woman/man classifier, scorer. |
| `cli/` | `im-process` (file in/out, delay-compensated), `im-pulse` (the Linux daemon's filter) and `im-stream` (raw stdin/stdout filter, its fallback). |
| `linux/` | `waaiya` command (also installed as `islamic-mute`), systemd user service, LADSPA plugin (for PipeWire filter-chain), live tests. |
| `testset/` | Builds the evaluation set: licensed voice clips + synthesised instrumental music (exact references). |
| `eval/` | Scores models through the real engine: instrument suppression, voice retention, SI-SDR, leakage, optional WER. |
| `android/` | Android app: system-wide filter, player, links (yt-dlp in the app). |
| `scripts/` | `fetch_deps.sh`: ONNX Runtime and the default model, with checksums. |
| `kaggle/` | Training notebooks (Kaggle GPU) for the voice model and the detector. |

## Model contract (`im.contract = 1`)

ONNX inputs `audio_in[hop]`, `state_in[state_size]`; outputs `audio_out[hop]`, `state_out[state_size]`.
Metadata: `im.sample_rate`, `im.hop`, `im.state_size`, `im.latency_samples`, `im.model_name`.
Optional `<model>.state_init.bin` (raw float32) holds the initial state. All DSP lives inside the graph.

## Build and run (Linux)

```bash
scripts/fetch_deps.sh                 # ONNX Runtime 1.19.2 + default model (int8 DeepFilterNet3), checksummed
make                                  # needs gcc; uses third_party/sysroot if libc headers are missing
linux/bin/waaiya install              # copies engine + model to ~/.local; then:
waaiya start                          # or: waaiya enable  (always on, every login)
waaiya status | stop
```

To export the models yourself instead of downloading them:

```bash
python3 -m venv .venv && . .venv/bin/activate && pip install deepfilternet torch==2.1.2 onnx onnxruntime soundfile
python models/dfn3/export_stream.py --out models/dfn3/dfn3_stream.onnx
python models/dfn3/test_parity.py     # streaming export == official DeepFilterNet3
python models/dfn3/test_engine.py     # C engine == PyTorch
```

Tests that touch the sound server are isolated (null sinks, nothing audible):
`linux/test_daemon.sh`, `linux/test_run.sh` (filtering, crash recovery, clean stop, end-to-end delay).

## Evaluate

```bash
python testset/fetch_sources.py && python testset/build_testset.py
python eval/evaluate.py --candidate dfn3=models/dfn3/dfn3_stream.onnx [--asr base]
```

## Android

```bash
scripts/fetch_deps.sh                   # default model (the APK bundles it)
# Needs Python 3.11 on the build machine (Chaquopy runs the link feature's yt-dlp in the app):
cd android && ./gradlew assembleDebug -PimBuildPython=/path/to/python3.11
#   -PimModel=/path/model.onnx   bundle another voice model
#   -PimX86                      also build x86_64 (emulators); phones are arm64-v8a + armeabi-v7a
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

The app captures every app's audio (AudioPlaybackCapture), filters it and plays the filtered copy.
To mute the original sound it needs `android.permission.DUMP` (to list audio sessions, as RootlessJamesDSP does).
Optionally, the app-op `PROJECT_MEDIA` = allow stops Android asking for screen-capture permission at every start.
Both are granted once, in one of two ways:

- **Without a computer (Shizuku):** install and start [Shizuku](https://shizuku.rikka.app) (wireless debugging
  on Android 11+, or root), open Waaiya and tap **Grant with Shizuku**, then allow it in Shizuku's dialog.
  The app runs a short-lived Shizuku UserService that executes `cmd package grant` and `cmd appops set`
  (see `android/app/src/main/java/org/islamicmute/app/ShizukuSetup.kt`). Shizuku can be stopped afterwards:
  both grants persist until the app is uninstalled.
- **With a computer (ADB):**
  ```bash
  adb shell pm grant org.islamicmute.app android.permission.DUMP
  adb shell appops set org.islamicmute.app PROJECT_MEDIA allow   # optional
  ```

## Links: watch or save a video without music

"Open a link" (or Share from YouTube/TikTok/Instagram to Waaiya) reads the page with
[yt-dlp](https://github.com/yt-dlp/yt-dlp) inside the app (Chaquopy, Python 3.11; YouTube's JavaScript check runs in
QuickJS-NG, built by `android/tools/build_qjs.sh`). **Watch** streams it through the filtered player. **Save**
downloads it, filters the audio (the video is copied unchanged) and puts the file in Movies/ (or Music/) "Waaiya";
the AAC encoder's start delay is measured once per phone and compensated, so lip sync is kept. Fail-closed:
audio the filter cannot take (e.g. 5.1) means no file, never an unfiltered one. Private posts, and public posts
when a site refuses anonymous visitors for a while (Instagram does this at times), cannot be opened.

yt-dlp keeps itself current (`im_update.py`): once a day the app checks PyPI for a newer stable release. A
release is taken only after its wheel has been on PyPI for 3 days, and the newest release that old is taken, so
a bad upload has time to be found and yanked first. After a link fails, the app also considers yt-dlp's nightly
builds (checked at most once an hour; a nightly must be 1 day old) and retries once. The yt-dlp-ejs version that
yt-dlp pins gets the same wait. Each wheel is checked: pure-Python only, from files.pythonhosted.org, SHA-256 as
published by PyPI, not yanked, size capped, only the yt_dlp / yt_dlp_ejs packages unpacked. A new copy is used
only after it imports correctly, and a newer yt-dlp in an APK update always wins. Requests to PyPI carry no app
name (Python's default User-Agent). Because the app
downloads code, this build is meant for direct download (GitHub releases); stores that forbid downloading code
(Google Play, F-Droid's main repository) would need a build with the self-update turned off.
Code: `android/app/src/main/python/im_links.py`, `im_update.py`, `Links.kt`, `LinkExport.kt`.

## Women's-singing filter (optional, for men)

A small classifier (EfficientAT `mn04`, MIT, ~1M parameters) watches the separated voice and mutes it while a
woman is singing. Women's speech and recitation are kept. It is off unless the user enables it. Fail-closed: if
the detector is missing or fails while the option is on, the voice is muted.

- Train: `python kaggle/make_notebook.py --detector`, then push `kaggle/detector-train` (Kaggle GPU, ~2 h).
  Code: `models/detector/` (`train_detector.py`, `prepare_detector_data.py`, `mobilenet.py`).
- Engine: `im_config.detector_path` + `im_engine_set_policy(e, IM_POLICY_MUTE_FEMALE_SINGING | IM_POLICY_FAIL_CLOSED)`;
  CLI: `im-process -m voice.onnx -d detector.onnx --mute-female-singing in.wav out.wav`.
- Linux: `waaiya women-singing on [detector.onnx]` (or `off`), then restart.
- Android: the toggle appears for men; build with `-PimDetector=/path/detector_v1.onnx`
  (default `models/detector/detector_v1.onnx` if present).
- Parity test (C front end vs PyTorch): `make build/test-detector && python models/detector/test_detector_engine.py detector.onnx`.

## Screen blur (optional, Android)

While filtering runs, Waaiya can also cover, over every app, **women** (whole body; people the app cannot
clearly tell are men are covered too) and **immodest images** (nudity, revealing clothing; the screen is
covered). Both are off by default and chosen in the app. Everything runs on the phone.

How it works: the screen is captured small (long side 640 px, same screen-capture permission as the audio
filter), a person detector (YOLOX-Nano, Apache-2.0) finds people, our own classifier (MobileNetV3-large,
`models/vision/train_gender_v2.py`, trained on 444k Open Images person boxes) says woman or man for each, and a nudity classifier (Marqo ViT-tiny, Apache-2.0)
checks the frame a few times a second. A small segmenter (LR-ASPP MobileNetV3, fine-tuned on Open Images person
masks) outlines each covered person, so the cover follows the body as a stack of strips and text beside them stays
readable; when it is missing or unsure, the whole rectangle is covered. With Shizuku running (Android 12+), the covers are drawn by
Shizuku as a screen layer that taps go through. Without it, they are drawn in a "display over other apps" window
(Shizuku can allow it: **Allow with Shizuku**), where a tap on a covered area does not reach the app underneath.
A build made with `-PimBlurA11y` also declares an accessibility service that only hosts the covers window, so
touches pass through it. It is not the default: Google Play Protect blocks installing, from a browser or a file
manager, any app that declares an accessibility service. Install that build with adb. **Who is left uncovered** (strict, balanced, relaxed) sets how sure the classifier must be that someone is a man before leaving him uncovered (99.9%, 99%, 98%); `eval/results/blur_tiles.md` has the trade-off.

Limits, said plainly:
- The cover is drawn after the frame was analysed (about 50–150 ms), so new content can show uncovered for that
  long. Covers are widened and moved ahead of the measured motion to reduce it.
- To see under its own covers, the app asks Android to leave the covers out of its screen capture (a hidden flag).
  At start it checks whether that worked. If not, it runs in a cautious mode: a cover stays until the scene changes.
- DRM-protected video (most paid streaming) captures as black: it cannot be analysed or covered.
- When the blur cannot keep up or fails, the user's setting decides: cover the whole screen, or show a warning.
- Measured numbers (and what they do not cover) are in `eval/results/blur.md`.

C code: `engine/src/im_vision.c` (models), `engine/src/im_cover.c` (tracker), header `engine/include/im_vision.h`.
Android: `ScreenBlur.kt`, `BlurOverlay.kt`, `Vision.kt`. Tests: `models/vision/test_vision_engine.py` (C vs the
original YOLOX), `models/vision/test_cover.py` (tracker), `models/vision/eval_blur.py` (end to end),
`models/vision/eval_silhouette.py` (outlines against rectangles, on person masks).

## Contributing / building

See [CONTRIBUTING.md](CONTRIBUTING.md). In short:

- Build steps are above (Linux: `make`; Android: `./gradlew assembleDebug`). `scripts/fetch_deps.sh` puts ONNX
  Runtime 1.19.2 in `third_party/onnxruntime/`, or pass `ORT=/path/to/onnxruntime` to `make`.
- Model files are not in git: export them or download them from the release assets (`docs/MODELS.md`).
- Project status and open work: `docs/STATUS.md`. Run the parity tests and `eval/evaluate.py` before proposing model
  or engine changes.
- Only train on data whose licence allows redistributing the resulting model (`THIRD_PARTY_LICENSES.md`, section 5).
- Contributions are accepted under the project licence (AGPL-3.0-or-later, `LICENSE`).

## License

GNU Affero General Public License v3.0 or later (AGPL-3.0-or-later): see `LICENSE` and `NOTICE`. Third-party code, models and datasets, with their licences and
open questions (notably the Quran recitation training data), are listed in `THIRD_PARTY_LICENSES.md`.
