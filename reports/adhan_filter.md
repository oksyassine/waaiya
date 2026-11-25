# The default filter and adhan

Run on 2026-11-25 over the music-check test set (`/srv/build/music/set2`, 20 s clips, not committed: audio) with
`eval/adhan_filter.py`, `eval/adhan_cause.py` and `eval/adhan_agc.py`. **Kept** = output level minus input level over
the loud 1 s windows (input above −45 dBFS). 0 dB = all kept; −20 dB = what is left is barely heard.

## Which filter users have

- **Android, Linux and Windows: DeepFilterNet3 streaming, int8** (`models/dfn3/dfn3_stream_int8.onnx`, bundled as
  `voice.onnx` on Android by `android/app/build.gradle.kts`; `linux/bin/islamic-mute`; the Windows bundle).
- voice_v1 (`models/voice/v3/voice_v1_fp16.onnx`) runs only with the "Keep singing" setting (`keep_singing`, a
  test, off by default).

## How much of the voice each filter keeps

| Group | Filter | Clips | Median kept | Muted more than 20 dB | More than 10 dB |
| --- | --- | --- | --- | --- | --- |
| adhan | **dfn3 int8 (default)** | 46 | **−27.3 dB** | **32** | 45 |
| adhan | dfn3 fp32 | 46 | −25.2 dB | 31 | 44 |
| adhan | voice_v1 fp16 | 46 | −10.1 dB | 6 | 23 |
| speech in a room (Freesound) | **dfn3 int8** | 66 | **−13.2 dB** | **21** | 36 |
| speech in a room | voice_v1 fp16 | 66 | −6.9 dB | 7 | 22 |
| speech (FLEURS, studio) | **dfn3 int8** | 147 | −0.6 dB | **25** | 27 |
| speech | voice_v1 fp16 | 147 | −0.4 dB | 1 | 1 |
| recitation (studio) | dfn3 int8 | 92 | −0.8 dB | 0 | 1 |
| recitation in a hall (synthetic, voice dominant) | dfn3 int8 | 40 | −4.6 dB | 1 | 1 |
| a cappella singing | dfn3 int8 | 43 | −0.4 dB | 0 | 2 |

- **Adhan recorded where people hear it (from the street, a roof, a courtyard) is muted by the default filter**: 32
  of 46 clips lose more than 20 dB, 45 of 46 more than 10 dB. All 6 sources, not one recording. The Wikimedia
  `Adhan.ogg` (−25 → −73 dBFS) is the same thing.
- **Not quantization**: the fp32 model mutes the same clips (31/46).
- **The same happens to speech recorded at a distance** (a lecture from the back of a room: 21/66 muted), and to
  **very quiet speech**: the 25 FLEURS clips muted are the quiet ones (input −67 to −57 dBFS; the others' median is
  −33).
- Studio recitation, recitation with a moderate echo, and a cappella singing are kept.
- voice_v1 keeps far more (adhan median −10 dB, 6/46 muted), but not all of it either.

## Why: one factor at a time

Six studio recitation clips (six reciters), changed one way at a time; four muted adhan clips at other levels.

| Change | dfn3 int8: median kept (worst) | voice_v1: median kept (worst) |
| --- | --- | --- |
| studio recitation as is | −1.4 dB (−4.8) | −0.3 dB (−0.7) |
| echo below the voice (hall, −5 dB) | −5.3 (−8.0) | −1.1 (−1.6) |
| echo as loud as the voice (RT60 2.5 s) | −7.9 (−9.7) | −3.8 (−5.6) |
| echo 6 dB / 12 dB above the voice (far away) | −11.2 / −11.3 (−12.7 / −16.6) | −6.2 / −7.0 |
| loudspeaker horn (300–3400 Hz) | −3.9 (−7.4) | −0.9 (−4.7) |
| horn, overdriven 12 dB | −5.9 (−12.3) | −2.3 (−5.3) |
| horn, overdriven, then far away (echo +6 dB) | −10.7 (**−21.7**) | −9.6 (−11.0) |
| the same with street noise (SNR 10 dB) | −10.6 (−19.1) | −6.7 (−8.2) |
| street noise only (SNR 10 dB) | −2.0 (−3.7) | −1.0 (−1.4) |
| quieter: −12 / −30 / −40 dBFS | −2.2 / −1.9 / −3.4 (**−33.2** at −40) | −0.3 / −0.3 / −0.3 |
| muted adhan as recorded | **−43.4** (−50.7) | −6.2 (−21.1) |
| the same 10 dB louder | −22.3 (−28.5) | −6.0 |
| the same 10 dB quieter | −41.9 (−46.8) | −10.0 |
| the same without its lows (high-pass 300 Hz) | −43.2 (−53.2) | −12.7 |

**Cause.** DeepFilterNet3 is a speech enhancer: it was trained to output dry, close-talk speech, so it removes
reverberation as well as noise. A muezzin heard from afar reaches the microphone mostly as echo, through a horn
loudspeaker, with the direct voice weak; the model treats nearly all of it as "not speech" and removes it. Each factor
alone costs a few dB (echo ~11 dB, horn + echo up to 22 dB); together on real recordings, 25 to 50 dB. Its decision
also depends on the absolute level: the same adhan 10 dB louder keeps 21 dB more, and quiet speech (below about
−45 dBFS) is gated away entirely. Long held vowels and melisma are not the cause: studio recitation, full of them, is
kept. Band-limiting alone is not either.

## Fixes, cheapest first

1. **Raise quiet input before the model and lower it after** (an automatic gain in the engine, to about −16 dBFS,
   at most +30 dB; the output gain is restored, so the user hears no change in loudness). Measured as a fixed gain per
   clip (`eval/adhan_agc.py`): quiet speech 25 → **0** muted clips; speech in a room 21 → 12; adhan only 32 → 24 (it is
   not quiet, it is far). Music removal unchanged on the test music (songs: median −13.9 vs −13.6 dB; instrumentals
   −27.2 vs −27.3; most test music is already above the target, so quiet music is not covered by this check). In the
   engine it needs a slow, look-ahead-free gain (seconds, so it does not pump) and a test of quiet music. **Fixes the
   quiet-speech half; not adhan.**
2. **voice_v1 as the default** (today "Keep singing"): adhan 32 → 6 muted, room speech 21 → 7, quiet speech 25 → 1.
   It keeps singing voices too, which is a product decision (today's default removes them), and it costs more CPU
   than dfn3 int8 (to measure on phones). An option: voice_v1 by default with the women's-singing detector, if that
   is the intended product.
3. **A chant guard in the engine**: when the tagger (mn04, the music check's) sees no voice-proof instrument
   (`classes.specific` in `eval/dm_weights.json`) for a few seconds while speech/chant classes are present, limit the
   filter's cut (e.g. to −6 dB, or mix in the input). It keeps adhan and lectures whatever their echo, but quiet
   background music under speech, which the tagger misses (music check: about 2/31 found), would then pass softened:
   it weakens "music off" exactly where the filter is weakest. Needs care and listening tests; the music check's live
   hint (part 2) would run the same tagger.
4. **Train the next voice model with far-field chant**: adhan and recitation through horn impulse responses with the
   echo dominant (DRR −12 to 0 dB, RT60 1–3 s), outdoor noise, and level augmentation from −60 to −10 dBFS, with the
   target being the voice *with* its echo (not dereverberated). The proper fix for both models; `eval/adhan_filter.py`
   over this set is the regression test (bar: adhan median kept above −6 dB, none muted over 20 dB, music removal no
   worse than today).

Recommended: 1 now (small, measurable, fixes quiet speech for everyone), 4 as part of the next voice model, and the
product question of 2 for the owner (it is the only one that fixes adhan today).
