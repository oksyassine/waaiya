# Platforms: one engine, a thin host per system

Waaiya has one filter and a small host for each operating system:

- **The filter** is `engine/`: C11 on the ONNX Runtime C API, plus the voice model (any ONNX file that follows the
  model contract in the README). It knows nothing about phones or sound servers. It takes audio blocks in and
  gives filtered blocks out, with a fixed, known delay.
- **A host** gets the sound that apps play, passes it through the engine, plays the result, and makes sure the
  original sound is never heard: on its own, or when the filter has stopped (fail-closed).

Getting other apps' sound and silencing the original is what differs between systems. That part is the host's
job, and it is usually a few hundred lines. The engine, the models, the test set and the scorer (`eval/`) are
shared. A model improvement reaches every platform without changing any host.

```
            ┌──────────────── shared ─────────────────┐
 app sound → │ host (per OS) → engine (C) + model.onnx │ → speakers
            └──────────────────────────────────────────┘
   Android: AudioPlaybackCapture + mute sessions    Linux: virtual sink + im-pulse
   macOS:   Core Audio process tap (planned)        Windows: apps lowered + process loopback
   Browser: Web Audio in the page (planned)         iOS: in-app player only (planned)
```

## Status and approach per platform

| Platform | Host | Fail-closed | Status |
|---|---|---|---|
| Android 10+ | `android/`: AudioPlaybackCapture, sessions muted through `DUMP` (granted once: on the phone with Wireless debugging on Android 11+, or with Shizuku or ADB; see `docs/SETUP.md`), engine over JNI | A failed model gives silence. If Android ends the capture, filtering stops and a notification says so | Released (0.2.9) |
| Linux | `linux/`: apps play into a virtual sink; `im-pulse` filters its monitor into the real output; systemd user service | A dead filter means silence (apps still play into the virtual sink) | Works on PulseAudio and PipeWire-Pulse; the native PipeWire filter-chain is untested |
| macOS 14.4+ | Core Audio process tap set to mute, read through a private aggregate device; engine runs in the IO callback | Risk: while the app restarts, sound is not filtered. A watchdog is needed | Scoped: `reports/desktop_windows_macos_scope.md` §3 |
| Windows 10 2004+ / 11 | `windows/filter` (`waaiya-filter.exe`): every other app's audio session is turned down to 1e-4 (−80 dB) of the user's level; one process-loopback capture of every process but ours reads their mix in float, ×1e4, through the engine, to the default output. Screen blur: `windows/blur` (`waaiya-blur.exe`): DXGI capture, click-through layered covers kept out of captures | Windows keeps the lowered levels when the filter dies: apps stay silent until Start or Stop. A capture louder than a lowered app can be is never played amplified (silence, and the sessions are looked at again). Apps that record the speakers (OBS) record the originals at −80 dB while it runs, unless left alone | Preview. CI on Windows Server 2022 and 2025 with a virtual output (`windows/test/audio_test.py`, `blur_test.py`): the −80 dB route gives the level back within 0.03 dB, clean (HNR > 120 dB); an instrument-like tone suppressed by about 47 dB at about 50 ms delay; new apps lowered before their first sound; crash, stop and restore. Not yet run on a real PC (speakers, Bluetooth, DRM players, exclusive-mode apps, several monitors) |
| iOS / iPadOS | Apple does not let an app capture or silence other apps' sound, so system-wide filtering is impossible. Possible: an in-app player for links and files, and a Safari web extension (as in the browser row) | — | Not started |
| Browsers (Chrome, Firefox, Edge, Safari) | Extension: route the page's `<video>`/`<audio>` through Web Audio and an AudioWorklet that runs the engine compiled to WebAssembly (or ONNX Runtime Web) | Media the extension cannot route is muted, never played unfiltered | Not started; covers desktops and ChromeOS without a native app |

The link feature (watch or save a video from a page link without music) exists on Android, which bundles yt-dlp
and QuickJS. Desktop hosts can call the `yt-dlp` command and the CLI in `cli/` (`im-process`) the same way.

## How the shared parts stay shared

- **One engine API** (`engine/include/im_engine.h`). Hosts may only call it; no platform code goes inside
  `engine/`, apart from small `#ifdef`s for file paths (Windows needs UTF-16 paths). The engine is built with the
  host's toolchain: CMake on Android, the Makefile on Linux, and later Xcode/CMake on macOS and MSVC/clang-cl on
  Windows.
- **One model format.** Models carry their own sample rate, block size, state size and delay as ONNX metadata
  (`im.*`). Hosts read those values instead of assuming them. A new model is a new file, not a code change.
- **One quality bar.** Every model and engine change is scored with `eval/evaluate.py` on the same test set
  through the real C engine. Every host must pass the same checks before release: no leak when the filter
  stops, measured end-to-end delay, and a crash restart.
- **CI per platform.** Linux (engine build plus a smoke test through the engine) and Android (APK build plus
  lint) run on every push and pull request. Windows (`windows.yml`): the engine, filter and blur are
  cross-compiled with llvm-mingw (`windows/Makefile`), then tested on Windows runners. When the macOS port
  starts, it adds a macOS runner for the engine and the tap host. A tag `v*` builds
  the release files for every platform that has a job and attaches them, with `SHA256SUMS`, to a draft
  release.
- **Models as release assets** (`docs/MODELS.md`). Every platform downloads the same checksummed files
  (`scripts/fetch_deps.sh models`), so app builds do not need the training setup.

## Order of work

1. Android and Linux: keep them solid (real-phone tests, low-delay model, Shizuku path).
2. macOS host (the path is clear, about 18–27 developer-days to a first version).
3. Windows: done as a preview (route C2, the attenuation-plus-loopback test passed in CI); next, a real PC.
4. Browser extension (reaches every desktop at once), then the iOS player and Safari extension.

Order and estimates come from `reports/desktop_windows_macos_scope.md`.
