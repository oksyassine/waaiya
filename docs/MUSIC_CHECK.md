# Check for music before sharing

Status: part 1 shipped in 0.2.18 as a modest check (owner, 2026-11-25: "ship the modest version"): it finds
music that plays clearly and may miss quiet music under speech ("Shipped" below). A trained detector to reach the
bar is planned in `docs/MUSIC_DETECTOR_PLAN.md`; part 2 follows.
Evaluation: see "Results" below and `reports/music_check.md`.

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
   - **B. An audio tagger on the residual**: EfficientAT `mn04` (MobileNetV3 trained on AudioSet, MIT licence,
     527 classes including "Music", every "Musical instrument" class, "Drum", "Percussion"; weights
     `models/detector/weights/mn04_as_mAP_432.pt`, the same family as the recitation detector, about 4 MB). It runs
     on the residual, not the mix, so voices do not hide quiet music. (YAMNet was the first idea; mn04 scores higher
     on AudioSet and is already in the project.)
   - **C. The same tagger on the input itself**: no engine run at all, the cheapest. Voices can mask quiet music.
   - **BC**: both, music when either says so.
   - **D**: a logistic model (one weight per tag of the input and of the residual, plus the residual level) trained
     on the tune split's 1 s windows, its score averaged over about 5 s. On the phone: one dot product per window.
   - **Dm**: the same model on the input's tags only, no engine run.
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

## Results (2026-11-25)

Full numbers, misses and false alarms: `reports/music_check.md` (975 clips of about 20 s, 588 in the test split).

| Approach | False alarms, clean voice (bar 2 %) | Noisy (bar 5 %) | Music found (bar 95 %) | Percussion only (bar 85 %) | Parts within 2 s |
| --- | --- | --- | --- | --- | --- |
| A signal features | 1.5 % | 2.0 % | 16 % | 0 % | 1/14 |
| B tagger on residual | 1.1 % | 0 % | 74 % | 45 % | 4/14 |
| C tagger on input | 0.7 % | 0 % | 71 % | 38 % | 5/14 |
| D logistic, input + residual | 1.5 % | 0 % | 80 % | 36 % | 12/14 |
| Dm logistic, input only | 2.6 % | 0 % | 81 % | 36 % | 12/14 |

- Songs, instrumentals and intro/outro music: found (D: 41/41, 72/74, 13/14) with false alarms within the bar.
- **Music under continuous speech (−15 to −25 dB): mostly missed** (D: 2/31). Lowering the threshold catches about
  half of the −20 dB mixes only at 13–17 % false alarms on clean voice, a large share of them adhan: chanted voice
  (recitation, adhan, especially with room echo) leaves a residual the tagger hears as music.
- Percussion only: duff nasheeds are never labelled as percussion only (they are reported as music); plain
  percussion recordings about two times in three.
- Speed (estimate, see the report): the tagger alone is cheap (about 1.5–2.5 s for a minute of audio on a
  mid-range phone); the engine run that B and D need is about 25–40 s, over the 10 s target.

**So:** the bar is not met. What works today is a check that says "music heard" for clips that are plainly music or
start/end with it (Dm or D), with honest wording that quiet music under speech may be missed. Reaching the bar for
background music needs a detector trained for it (music under speech, chanted voice as negatives), which the test set
can now measure. Owner decision pending.

**Adhan guard (Cg, Dmg).** On adhan the generic "Music" class fires while only voice-like instrument classes do
(brass, woodwind, theremin). A part now stays only if one of its windows has a voice-proof class (plucked, struck,
keyboard, drums, genres; `classes.specific` in `eval/dm_weights.json`) above a threshold chosen on the tune split:
Cg (C + guard): 0.0 % false alarms on clean voice (adhan 0/25), 69 % of music found; Dmg (Dm + guard): 1.1 % (adhan
2/25), 81 % found (songs 41/41, instrumentals 73/74). Both need only the tags of the input. The rules, Dm's weights
and test vectors for the app's port: `eval/dm_weights.json`, `eval/music_rule_vectors.json`,
`eval/check_rule_port.py`.

**Side finding (filter, not this feature):** the default dfn3 filter mutes adhan recorded at a distance (32 of 46
clips lose more than 20 dB), speech recorded at a distance (21/66) and very quiet speech (25/147). Cause, fixes and
numbers: `reports/adhan_filter.md`.

## Shipped (0.2.18)

- **Rule: Cg** (the AudioSet tagger on the file itself, no engine run, with the adhan guard). Its tags come from
  `engine/src/im_music.c`: the file's sound mixed to mono, resampled to 32 kHz (windowed sinc), the singing detector's
  C front end (`im_detector`, now with the model's own output size) and `models/music/tagger_mn04.onnx`
  (`models/music/export_tagger.py`, EfficientAT mn04, MIT; in the models-v1 release, `scripts/fetch_deps.sh models`).
  The decision is `MusicRule.kt`, the same rule as `eval/music_check_eval.py`.
- **Tuned on what the phone computes:** `models/music/eval_scan.py` runs the same C code (`build/im-music-scan`) over
  the test set; the thresholds were chosen again on its tune split (music 0.75, vocal 0.0, perc 0.1, tonal_max 0.3,
  pshare 0.3, spec 0.12). Test split with these tags: **false alarms 0/272 on clean voice (adhan 0/25, recitation
  0/96), 0/100 on noisy recordings; music found 108/160 = 67.5 %** (songs 38/41, instrumentals 62/74, background
  8/45); percussion only labelled 21/56 (duff nasheeds are reported as music). Under the bar for music found, so the
  screen says "Quiet music under speech can be missed".
- **Tests:** `MusicRuleTest` checks the Kotlin rule against the evaluation (17 test clips with the phone's tags, and
  the evaluation's own vectors `eval/music_rule_vectors.json`: same window flags, parts and verdicts). Emulators
  (Android 16 and 11): a song, an adhan, percussion and a recitation file shared through MediaStore give the
  evaluation's verdicts; "Share without music" makes and shares the copy; "Listen here" opens the player; Arabic
  right to left checked.
- **App:** `MusicCheckActivity` (share target "Waaiya: check for music", next to the player), `MusicScan.kt`
  (MediaExtractor/MediaCodec decode), `MusicTimelineView`, `CleanCopyProvider` (copies in cache/clean, a day at most).
  The check runs while the screen is open (the share's read access belongs to it); files over 30 minutes are not
  checked. Works in the Google Play build (no link service needed).

## Build plan (part 1)

1. Offline analysis in the engine or Kotlin: decode with Media3, run the engine hop by hop, collect per-hop
   residual features (and the classifier, if B), return the music parts. JVM tests on synthetic and test-set clips.
2. Evaluation script on the server over the test set (`eval/music_check_features.py`, `eval/music_check_eval.py`,
   set built by `testset/build_music_check.py`); pick the approach; results in `reports/music_check.md`.
3. The share target (activity-alias with its own label), the check screen, the result screen, the clean copy
   (reuses the export path of `LinkExport`), sharing through `FileProvider`.
4. Texts in the 18 languages, RTL checked.
5. Tests on the Android 11 and Android 16 emulators, then on a real phone.

## Privacy

Everything runs on the phone. The file is read once through the permission the share sheet gives; the clean copy is
kept in the app's cache until shared, and deleted after a day. Nothing is sent anywhere and nothing is kept about the
file.
