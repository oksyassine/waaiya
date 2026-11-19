# Status (2026-11-19, 0.2.13 in preparation)

What comes next, and why: `docs/ROADMAP.md`.

| Part | State | Evidence |
|---|---|---|
| Test set + scoring | done | `testset/`, `eval/results/summary.md` |
| Engine (C, ONNX Runtime) | done | parity >100 dB vs PyTorch, 30 ms delay on the hop-aligned path; stereo about 7 ms and mono about 3 ms per 10 ms hop on a loaded desktop core (`build/test-mono`); mono can be switched on a running engine |
| Linux always-on | done, live-tested on PulseAudio | `linux/test_run.sh`: 24 dB suppression, crash restarts fail-closed; delay in `eval/results/latency.md` |
| Android live filter | released (0.2.11); 0.2.9 and 0.2.10 used on a Galaxy S24 and a Xiaomi | Mono by default with a stereo setting (0.2.10); adapts to the phone (mono fallback, dropout counting), says when the original is not silenced or the phone is too slow, diagnostics report. When Android ends filtering, other apps stay silent by default (0.2.10). Checked on emulators with `android/tools/emu_check.py`; 27 JVM tests |
| Android: silence the originals | done; helper mode not proven on a real Xiaomi/OPPO | Session list from the audio policy dump (Android 10+); one-time grant on the phone (Wireless debugging, Android 11+), with Shizuku or ADB; slow-Shizuku handling (0.2.11). 0.2.12: guided four-step setup page; phones that refuse the grant (Xiaomi, OPPO family) use Waaiya's shell helper for the session list instead of a hidden Developer options switch (`docs/SETUP.md`), checked on emulators with a simulated refusal |
| Android: Quick Settings tiles, icon shortcuts | done (0.2.11) | "Waaiya" tile and Start/Stop shortcuts on the icon; "Notification text" tile (Android 15+) shows notification text while filtering |
| Open a link (YouTube, TikTok, Instagram) | done | Video links stay video; saved files keep the original picture with filtered sound |
| Screen blur (Android) | released | Person detector with tiles, woman/man classifier v2, outlines, steady covers: `eval/results/blur_*.md`. 0.2.10: one window per cover group without Shizuku, checked Shizuku layer, self-test on every host change. Speed on phones not measured |
| Women's-singing detector | engine + Linux + Android wired; model v1 bundled | `models/detector/test_detector_engine.py` |
| Model shrink | done: int8 weights 2.4 MB, within 0.2 dB | `eval/results/shrink.md` |
| Own voice model (keeps singing) | trained on Kaggle, not the default | roadmap item 6 |
| Flutter UI (Android main screen since 0.2.11, pages with a bottom bar), Linux desktop app | Android: released; desktop: preview | Sound filter and X11 blur work; Wayland blur untested on real sessions |
| Languages | Arabic and English written for the project; French, Urdu, Indonesian, Turkish, Bengali, Persian, Malay machine-translated (0.2.13), not reviewed by native speakers | `ui/tool/check_translation.py` (every text, format arguments, escaping), `ui/test/languages_test.dart` (each page in each language on a small phone, no overflow), setup pictures retaken per language (`android/tools/guide_shots.py`) |
| Windows desktop app (filter + blur) | preview (branch `windows-filter`) | CI on Windows Server 2022 and 2025 with a virtual output: `windows/test/audio_test.py` (route C2 measured: level back within 0.03 dB, HNR > 120 dB; tone suppressed about 47 dB, about 50 ms delay; new apps lowered before their first sound; crash, stop, restore), `windows/test/blur_test.py` (covers out of the capture on 2025, in it on 2022; click-through; fail-closed; models). Not yet on a real PC |
| macOS, iOS | not started | `docs/PLATFORMS.md`; macOS needs an Apple Developer ID (the capture permission is tied to the signature) |

Baseline DeepFilterNet3: speech kept (-2.6 dB) with 21-24 dB instrument suppression; recitation (-13 dB) and singing (-25 dB) are lost, hence the own voice model.

## Not verified on a real phone yet
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
