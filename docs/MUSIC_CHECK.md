# Check for music before sharing

Status: spec, approved in principle by the owner on 2026-11-25. Part 1 is built first; part 2 follows.

## Why

With Waaiya on, the user never hears the music in what they watch. A video can feel clean when it is not: the user
forwards it, and the other person hears everything. Waaiya should say so before the clip leaves the phone, and offer
a clean copy.

## Part 1: "Check for music" (share target)

### Flow

1. In any app that shares a video or audio file (WhatsApp, Telegram, the gallery, Files), the user shares it to
   **"Waaiya: check for music"**. Its own entry in the share sheet, next to the existing "Waaiya" player entry.
2. A screen opens with the file's name and "Listening… 40 %". Analysis runs on the phone, faster than real time;
   nothing is sent anywhere, and the screen can be left (the result waits in a notification).
3. The result, in plain words:
   - **Music heard**: a timeline of the clip with the music parts marked, and "Music in 0:00–0:35 and 1:10–1:40
     (about 40 % of the clip)".
   - **Only percussion heard** (duff, drums, claps in rhythm): the same, labelled separately, so the user decides.
   - **No instruments heard**: "Waaiya listened to the whole clip and heard no musical instruments."
   - **Could not check**: unsupported or protected file, no sound track, too long (limit below).
4. Buttons:
   - **Share without music**: makes a clean copy (the same filter, the voice kept, picture untouched) and opens the
     share sheet with it. The copy lives in the app's cache and is deleted after a day.
   - **Share anyway**: opens the share sheet with the original.
   - **Listen here**: opens the existing filtered player at the first music part.

The wording stays modest: "Waaiya heard instruments", never a ruling.

### Limits

- Clips up to 30 minutes (longer: "too long to check"). Typical shared clips are under 3 minutes.
- Speed target: a 1-minute clip checked in 10 s or less on a mid-range phone (Snapdragon 6-class, 2022).
- Formats: whatever the phone's decoders read (Media3 extractors: MP4, MKV, WebM, MP3, M4A, OGG, WAV, 3GP).
- No new permission: the share sheet grants read access to that one file. Works in the Google Play build.

## Part 2: live hint (later)

While the filter runs, after a few seconds of clear music the filter notification's line becomes "Music is being
removed from what is playing now". Same detector as part 1, run on the live residual at low cost. Built after
part 1 meets its bar.

## How the music is found

The engine already splits each moment into voice (kept) and everything else (removed). The removed part, the
**residual**, holds the instruments, but also noise, wind, crowd, clapping and room echo. So:

1. **Residual energy**: per 20 ms hop, the energy removed vs the input, and the loudness of the input. Moments where
   the input is too quiet (below about -45 dBFS) are ignored.
2. **Is the residual music?** Two candidates, both measured on the test set below; the one that meets the bar ships:
   - **A. Signal features (no extra model)**: harmonic-percussive split of the residual spectrogram (median
     filtering); the harmonic part's tonality (stable spectral peaks lasting > 200 ms) marks melodic instruments;
     a periodic onset envelope (autocorrelation peak at 60-200 BPM) in the percussive part marks rhythm. Noise is
     neither tonal nor periodic.
   - **B. A small audio classifier on the residual**: YAMNet (Apache-2.0, AudioSet classes "Music", "Musical
     instrument", "Drum", "Percussion"...; about 3.7 MB, converted to ONNX for the runtime the app already ships).
     It runs on the residual, not the mix, so voices do not hide the music.
3. **Decision**: a moment counts as music when the residual is loud enough relative to the input (at least -20 dB
   below it, so quiet background music under speech is still caught) and is classed as music. Parts shorter than
   3 s are merged or dropped; gaps under 2 s are bridged. The clip is "music heard" when any part remains.
4. **Percussion only**: music parts whose residual is mostly percussive and has no tonal part are reported as
   "only percussion".
5. **Voice kept by the filter**: singing and voice-only nasheeds are voice, so the filter keeps them and they are
   not reported here (the women's-singing filter is a separate setting).

## Test set and pass bar

Clips gathered with their licences (the existing `testset/` tooling), each labelled by hand with its music parts:

| Group | Examples | Expected |
| --- | --- | --- |
| Speech | lectures, podcasts, phone recordings, outdoor talks, noisy cafés | no music |
| Recitation and adhan | studio, mosque echo, children reciting, adhan from loudspeakers | no music |
| Voice-only nasheed | including vocal effects and humming | no music |
| Percussion only | duff nasheeds, clapping rhythms | percussion only |
| Music | songs, instrumentals, ringtones, cartoon themes | music |
| Background music | vlogs and adverts with quiet music under speech, music only in intro/outro | music, with the right parts |
| Noise | street, car, rain, crowd, wind, applause | no music |

Pass bar (per clip, on held-out clips not used for tuning):

- Music clips found: at least 95 %, including background music at -20 dB under speech.
- False alarms: at most 2 % on speech, recitation and adhan; at most 5 % on noisy recordings.
- Music parts placed within 2 s of the hand labels.
- Percussion-only clips labelled as such: at least 85 % (the rest may show as "music", never as "no instruments").
- Speed target above on a real mid-range phone.

The report lists every miss and false alarm with the clip, so the wording and thresholds can be judged by ear.

## Build plan (part 1)

1. Offline analysis in the engine or Kotlin: decode with Media3, run the engine hop by hop, collect per-hop
   residual features (and the classifier, if B), return the music parts. JVM tests on synthetic and test-set clips.
2. Evaluation script on the server over the test set; pick A or B; write the results to `reports/`.
3. The share target (activity-alias with its own label), the check screen, the result screen, the clean copy
   (reuses the export path of `LinkExport`), sharing through `FileProvider`.
4. Texts in the 18 languages, RTL checked.
5. Tests on the Android 11 and Android 16 emulators, then on a real phone.

## Privacy

Everything runs on the phone. The file is read once through the permission the share sheet gives; the clean copy is
kept in the app's cache until shared, and deleted after a day. Nothing is sent anywhere and nothing is kept about the
file.
