# Islamic Mute

System-wide voice filter: removes musical instruments from everything the device plays and keeps the voice.
On-device, streaming, fail-closed (if the filter cannot run, the output is silent, never unfiltered).

Research behind the design: `reports/System wide instrument muting app.md`.

## Layout

| Path | What it is |
|---|---|
| `engine/` | C11 streaming engine on the ONNX Runtime C API. Loads any model that follows the contract below. Same code for Linux, Android (NDK), macOS, Windows. |
| `models/dfn3/` | Streaming export of DeepFilterNet3 (speech mode) + parity tests against the official implementation. |
| `models/voice/` | Training of our own model that keeps speech, Quran recitation and singing (stage 3). |
| `cli/` | `im-process` (file in/out, delay-compensated) and `im-stream` (raw stdin/stdout filter used by the Linux daemon). |
| `linux/` | `islamic-mute` command, systemd user service, LADSPA plugin (for PipeWire filter-chain), live tests. |
| `testset/` | Builds the evaluation set: licensed voice clips + synthesised instrumental music (exact references). |
| `eval/` | Scores models through the real engine: instrument suppression, voice retention, SI-SDR, leakage, optional WER. |
| `android/` | Android app (stage 2). |

## Model contract (`im.contract = 1`)

ONNX inputs `audio_in[hop]`, `state_in[state_size]`; outputs `audio_out[hop]`, `state_out[state_size]`.
Metadata: `im.sample_rate`, `im.hop`, `im.state_size`, `im.latency_samples`, `im.model_name`.
Optional `<model>.state_init.bin` (raw float32) holds the initial state. All DSP lives inside the graph.

## Build and run (Linux)

```bash
make                                  # needs gcc; uses third_party/sysroot if libc headers are missing
python3 -m venv .venv && . .venv/bin/activate && pip install deepfilternet torch==2.1.2 onnx onnxruntime soundfile
python models/dfn3/export_stream.py --out models/dfn3/dfn3_stream.onnx
python models/dfn3/test_parity.py     # streaming export == official DeepFilterNet3
python models/dfn3/test_engine.py     # C engine == PyTorch
linux/bin/islamic-mute install
islamic-mute start                    # or: islamic-mute enable  (always on, every login)
islamic-mute status | stop
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
cd android && ./gradlew assembleDebug   # -PimModel=/path/model.onnx to bundle another model
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

The app captures every app's audio (AudioPlaybackCapture), filters it and plays the filtered copy.
To mute the original sound it needs `android.permission.DUMP` (to list audio sessions, as RootlessJamesDSP does).
Optionally, the app-op `PROJECT_MEDIA` = allow stops Android asking for screen-capture permission at every start.
Both are granted once, in one of two ways:

- **Without a computer (Shizuku):** install and start [Shizuku](https://shizuku.rikka.app) (wireless debugging
  on Android 11+, or root), open Islamic Mute and tap **Grant with Shizuku**, then allow it in Shizuku's dialog.
  The app runs a short-lived Shizuku UserService that executes `cmd package grant` and `cmd appops set`
  (see `android/app/src/main/java/org/islamicmute/app/ShizukuSetup.kt`). Shizuku can be stopped afterwards:
  both grants persist until the app is uninstalled.
- **With a computer (ADB):**
  ```bash
  adb shell pm grant org.islamicmute.app android.permission.DUMP
  adb shell appops set org.islamicmute.app PROJECT_MEDIA allow   # optional
  ```

## Women's-singing filter (optional, for men)

A small classifier (EfficientAT `mn04`, MIT, ~1M parameters) watches the separated voice and mutes it while a
woman is singing. Women's speech and recitation are kept. It is off unless the user enables it. Fail-closed: if
the detector is missing or fails while the option is on, the voice is muted.

- Train: `python kaggle/make_notebook.py --detector`, then push `kaggle/detector-train` (Kaggle GPU, ~2 h).
  Code: `models/detector/` (`train_detector.py`, `prepare_detector_data.py`, `mobilenet.py`).
- Engine: `im_config.detector_path` + `im_engine_set_policy(e, IM_POLICY_MUTE_FEMALE_SINGING | IM_POLICY_FAIL_CLOSED)`;
  CLI: `im-process -m voice.onnx -d detector.onnx --mute-female-singing in.wav out.wav`.
- Linux: `islamic-mute women-singing on [detector.onnx]` (or `off`), then restart.
- Android: the toggle appears for men; build with `-PimDetector=/path/detector_v1.onnx`
  (default `models/detector/detector_v1.onnx` if present).
- Parity test (C front end vs PyTorch): `make build/test-detector && python models/detector/test_detector_engine.py detector.onnx`.

## Contributing / building

- Build steps are above (Linux: `make`; Android: `./gradlew assembleDebug`). The Linux build expects ONNX Runtime
  1.19.2 (`onnxruntime-linux-x64-1.19.2.tgz` from the ONNX Runtime GitHub releases) unpacked into
  `third_party/onnxruntime/`, or pass `ORT=/path/to/onnxruntime` to `make`.
- Model files are not in git: export them or download them from the release assets (`docs/MODELS.md`).
- Project status and open work: `docs/STATUS.md`. Run the parity tests and `eval/evaluate.py` before proposing model
  or engine changes.
- Only train on data whose licence allows redistributing the resulting model (`THIRD_PARTY_LICENSES.md`, section 5).
- Contributions are accepted under the project licence (AGPL-3.0-or-later, `LICENSE`).

## License

GNU Affero General Public License v3.0 or later (AGPL-3.0-or-later): see `LICENSE` and `NOTICE`. Third-party code, models and datasets, with their licences and
open questions (notably the Quran recitation training data), are listed in `THIRD_PARTY_LICENSES.md`.
