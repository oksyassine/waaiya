# Live captions (Arabic)

Status: on the branch `claude/live-arabic-captions`, not released. The engine and the app's screens are built and
tested here; the real Arabic model has not been exported yet, and nothing has run on a phone.

## What it does

The Filter page has a card, **Live captions** (only in a build that bundles the Arabic speech model). Its button opens a
full-screen page that listens to the microphone and writes what is said in Arabic as large text, right to left,
scrolling as it grows. It is meant for deaf and hard-of-hearing listeners at a khutba or a lesson: the phone is
pointed at the imam or the loudspeaker.

- The line being spoken shows dimmer and changes as more is heard; it becomes a finished line after a short pause.
- **Pause / Resume**, **Clear**, **Smaller text / Bigger text** (20 to 72 sp, default 34), **Colours** (white on
  black, black on white, yellow on black) and **Remove background sounds first** (on by default). All are kept.
- The screen stays on while the page is open. It listens only while the page is in front: leaving it, or the phone
  locking, stops the microphone.
- A note under the text: "Written by the phone: some words can be wrong."
- Everything runs on the phone. Nothing is sent (no new network code; `NoNetworkTest` covers the new files).

## How it works

```
microphone 48 kHz ─► [voice model, optional] ─► im_captions ─► recogniser (im_asr, ONNX) ─► text
                      Engine.open(mono)          48→16 kHz        CTC greedy decoding
                      (the filter's model)       level gate
                                                 line cutting
```

- **Clean sound first**: the same voice-keeping model as the filter (`Engine.open(context, 1, mono = true)`), so
  noise, music and echo are reduced before recognition. If it cannot open, the raw microphone is used: captions only
  show text, so no captions would help nobody. The user's voice policy (women's singing) applies as in the filter.
- **im_captions** (`engine/src/im_captions.c`, header `engine/include/im_captions.h`): decimates to 16 kHz (windowed
  sinc), finds speech with a level gate that follows the room's noise floor, re-recognises the open line about every
  0.8 s (slower if the phone is slow), finishes a line after 0.7 s of pause, and cuts a line longer than 12 s at its
  quietest moment, so a khutba with few pauses still comes out as readable lines and no word is lost or doubled.
- **im_asr** (`engine/src/im_asr.c`): runs any ONNX model that follows the ASR contract in `im_captions.h` (16 kHz
  waveform in, CTC logits out, tokens in the file's metadata). The decoder is `engine/src/im_ctc.c`.
- **Android**: `Captions.kt` (feature `captions`, the listener thread, `CaptionsNative`, the screen's text rules),
  `CaptionsActivity.kt`, `cpp/captions_jni.c`. The model is the asset `captions_ar.onnx`, copied out of the APK the
  first time the page opens (it is large; it is not copied with the other models at start).
- **Flutter**: `ui/lib/src/captions.dart` (the card).
- **Desktop / files**: `im-caption -a model.onnx [-m voice.onnx] [--partials] file.wav` prints the captions of a
  WAV file exactly as the phone would make them, with the time each line would appear, and how fast it ran.

## The model, and the choice

Default: NVIDIA's **FastConformer Arabic** (`nvidia/stt_ar_fastconformer_hybrid_large_pc_v1.0`), CTC head, int8,
about 120 MB in the APK. Made by `models/asr/export_fastconformer.py` (see `models/asr/README.md`).

| Model | Size | For | Against |
|---|---|---|---|
| FastConformer Arabic `_pc` (default) | ~115M params, ~120 MB int8 | Best published accuracy for Modern Standard Arabic among open on-device models; punctuation; CTC runs in one pass, cheap to repeat as a line grows | Large APK; no diacritics; weak on Darija |
| FastConformer Arabic `_pcd` | same | Diacritics, trained with Classical Arabic (Quran) | Higher word error on everyday speech; diacritics are harder to read at speed |
| Moonshine tiny Arabic | ~27M params | Small and fast | Clearly less accurate; encoder-decoder (slower to repeat) |
| Whisper (small or larger) | 240M+ | Many languages | Too slow for live captions on a mid-range phone; invents text in silence |

**Darija**: none of these handles Moroccan Arabic well. A khutba in Fusha will read much better than a dars in Darija.
The plan is to fine-tune the default model's CTC head on Darija speech later; the app needs no change for that, only a
new model file that follows the contract.

## Tested here, and not

Tested (`make test-captions`, `flutter test`, CI):

- Line cutting, partial lines, long-line cuts with no word lost or doubled, clicks ignored, flush, reset, recogniser
  failures, 48 kHz decimation (a 1 kHz tone passes, 12 kHz is removed), CTC decoding and UTF-8 cuts (`test_captions.c`).
- The ONNX runner on a made-up model, metadata checks, refusals, and the whole path at 48 kHz (`test_asr.c`).
- The card: hidden without the model, opens the page, fits in every language (`captions_test.dart`).
- The screen's text rules, sizes, colours and the "slow phone" note (`CaptionsTextTest.kt`).

Not tested yet:

- The real model: the export script has not run (it needs NeMo and Hugging Face, which this machine cannot reach),
  so accuracy, speed and memory on a phone are unknown. Run the export, then `im-caption` on a recorded khutba, then
  the phone.
- The licence of the NVIDIA model (read it on the model card before shipping; credit it in `THIRD_PARTY_LICENSES.md`).
- The page on a real phone: microphone quality across a mosque, battery, heat over a 30-minute khutba.

## Left to do

- Export the model and measure it (word error on a few recorded khutbas, time per second of audio on a mid-range phone).
- Captions for a file or a stream played in Waaiya's player (the engine already takes any 16 kHz-multiple source).
- Captions on the desktop app.
- Darija.
