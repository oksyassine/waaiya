# Status (2026-11-12, 0.2.10)

What comes next, and why: `docs/ROADMAP.md`.

| Part | State | Evidence |
|---|---|---|
| Test set + scoring | done | `testset/`, `eval/results/summary.md` |
| Engine (C, ONNX Runtime) | done | parity >100 dB vs PyTorch, 30 ms delay on the hop-aligned path; stereo about 7 ms and mono about 3 ms per 10 ms hop on a loaded desktop core (`build/test-mono`); mono can be switched on a running engine |
| Linux always-on | done, live-tested on PulseAudio | `linux/test_run.sh`: 24 dB suppression, crash restarts fail-closed; delay in `eval/results/latency.md` |
| Android live filter | released (0.2.9), used on a Galaxy S24; 0.2.10 built, not published | Mono by default with a stereo setting (0.2.10); adapts to the phone (mono fallback, dropout counting), says when the original is not silenced or the phone is too slow, diagnostics report. When Android ends filtering, other apps stay silent by default (0.2.10). Checked on emulators with `android/tools/emu_check.py`; 27 JVM tests |
| Android: silence the originals | done | Session list from the audio policy dump (Android 10+); one-time grant with Shizuku or ADB |
| Open a link (YouTube, TikTok, Instagram) | done | Video links stay video; saved files keep the original picture with filtered sound |
| Screen blur (Android) | released | Person detector with tiles, woman/man classifier v2, outlines, steady covers: `eval/results/blur_*.md`. 0.2.10: one window per cover group without Shizuku, checked Shizuku layer, self-test on every host change. Speed on phones not measured |
| Women's-singing detector | engine + Linux + Android wired; model v1 bundled | `models/detector/test_detector_engine.py` |
| Model shrink | done: int8 weights 2.4 MB, within 0.2 dB | `eval/results/shrink.md` |
| Own voice model (keeps singing) | trained on Kaggle, not the default | roadmap item 6 |
| Flutter UI, Linux desktop app | preview (branch `flutter-ui`) | Sound filter and X11 blur work; Wayland blur untested on real sessions |
| macOS, Windows engine, iOS | not started | `docs/PLATFORMS.md` |

Baseline DeepFilterNet3: speech kept (-2.6 dB) with 21-24 dB instrument suppression; recitation (-13 dB) and singing (-25 dB) are lost, hence the own voice model.

## Not verified on a real phone yet
- How many phones need the mono fallback, and how it sounds there (the diagnostics report will tell).
- Blur speed with outlines and tiles; the Shizuku cover layer (its probe and health call are untested on a device:
  the emulators have no Shizuku).
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
