# Music detector: plan

Status: plan, 2026-11-25. Follows `docs/MUSIC_CHECK.md` and `reports/music_check.md`. Nothing is trained yet.

## Why

The "Check for music" share target ships with the AudioSet tagger (EfficientAT mn04) on the input and a fixed rule
(approach C plus a guard). That finds plain music (songs, instrumentals, intro/outro) with few false alarms. It misses
what users most need flagged: **quiet music under continuous speech** (-15 to -25 dB: 2/31 found). Lowering the
threshold to catch it makes **chanted voice** (recitation, adhan with room echo) read as music. Duff nasheeds are
never labelled "percussion only".

AudioSet's "Music" label was never trained for "faint music under a voice". Nor was it trained to say that a
mujawwad recitation or an adhan is not music. A small head trained on exactly that split should close the gap. The
backbone stays the one already shipped and measured.

## Target

The pass bar of `docs/MUSIC_CHECK.md`, on the held-out test split of `/srv/build/music/set2`, scored by
`eval/music_check_eval.py`, with no change to the bar:

| Measure | Bar | Today (C / D) |
| --- | --- | --- |
| False alarms, speech, recitation, adhan, a cappella | ≤ 2 % | 0.7 % / 1.5 % |
| False alarms, noisy recordings | ≤ 5 % | 0 % / 0 % |
| Music found (songs, instrumentals, background) | ≥ 95 % | 71 % / 80 % |
| Background music at -20 dB under speech | found (part of the 95 %) | 22 % / 33 % (all levels) |
| Percussion only labelled as such | ≥ 85 % | 38 % / 36 % |
| Parts within 2 s | all | 5/14 / 12/14 |

The adhan group is reported on its own line and must be **0 false alarms on its 25 test clips**. A false "music
heard" on an adhan would discredit the feature for its users. The same holds for recitation.

Speed: tagger path only (no engine run). At most **10 s per minute of audio** on a Snapdragon-6-class phone; today's
tagger is estimated at 1.5–2.5 s. The new model may cost at most 2x mn04.

## Model

**Choice: mn04 backbone + a small temporal head, 3 classes per window: music / percussion only / none.**

- **Input:** waveform 32 kHz mono. The windows are those of the eval: 1 s every 0.5 s.
  - The mel front end (`MelFrontEnd(32000, 1024, 800, 320)`) lives inside the ONNX graph, as today.
  - The app feeds samples, not features.
- **Backbone:** EfficientAT mn04 (MIT, AudioSet mAP .432, weights `mn04_as_mAP_432.pt`, about 1 M parameters). Its
  pooled embedding (`embed()`, `models/detector/mobilenet.py`) is concatenated with the 527 AudioSet logits: both
  carry signal.
- **Temporal head:** a 1D conv (or GRU) over **9 consecutive windows (≈ 5 s)**, about 50 k parameters, producing
  per-window logits for (music, percussion).
  - The eval showed that smoothing over ~5 s was the single best gain (D: 12/14 parts placed).
  - Chant and music differ over seconds (a melody bed under the voice), not inside one window.
- **Two stages:**
  1. **Frozen backbone.** Precompute embeddings + logits once for every training window, then train only the head,
     on the server CPU in minutes. If stage 1 meets the bar, stop: the shipped backbone and its ONNX stay
     byte-identical, and only the head (a few hundred kB) ships.
  2. **Fine-tune the last blocks of mn04** with the head on Kaggle GPU, only if stage 1 fails on music under speech.
- **Alternatives considered:**
  - mn10 / mn20: 3–6x slower; the mn10 checkpoint gave saturated output in the recitation work.
  - PANNs CNN14: 80 M parameters, too big.
  - YAMNet: Apache-2.0, but AudioSet-only like mn04, and a second runtime path.
  - Residual-based features (approach B/D): need the engine run, 25–40 s per minute, over the speed target.
- **Export:**
  - ONNX opset 17, one graph (mel + backbone + head) or two graphs (tagger as shipped + head).
  - fp16 weights. Use int8 only if a parity check on the test split shows ≤ 0.5 % change in every bar figure.
  - Thresholds and smoothing go in ONNX metadata (`im.music_threshold`, `im.perc_threshold`, `im.music_smooth`),
    the same pattern as `im.det_singing_threshold`. A model without them is refused, and the app keeps rule C.

## Data

Everything is mixed on the fly from licensed sources. **Nothing from the test split of set2 is used**: not its
speakers, reciters, recordists, artists or FMA tracks. Exclusion lists come from `set2/manifest.jsonl` (`source`
column), written to `models/music/holdout_sources.txt` and checked by the data builder (it refuses an excluded
source). The tune split of set2 stays for threshold choice, and training gets its own validation sources.

| Role | Source | Licence | Notes |
| --- | --- | --- | --- |
| Speech | LibriSpeech (as detector v1/v3); FLEURS **train** split | CC BY 4.0 | FLEURS test speakers are in set2; check speaker ids, drop overlaps |
| Recitation | fawazahmed0/quran-audio | CC0 tag (no upstream licence: accepted class) | not maher, banna, shuraym (test) nor tablaway, jibreel (tune) |
| Mujawwad (hard) | Minshawy mujawwad, Abdul Basit mujawwad (as v3 run 3) | same | the melodic recitation that read as singing |
| Adhan (hard) | Freesound via Openverse (CC0 / CC BY), new search, recordists not in set2 | CC0 / CC BY | set2 already uses 10 recordists; Wikimedia adhan stays eval only |
| A cappella / nasheed voice | none clean; OpenSinger is NC and eval only | — | use recitation + speech as the voice; see risks |
| Music | FMA permissive list (`fma_permissive.tsv`, 1,789 tracks) | CC BY / CC0 | artists of set2 (tune and test) excluded |
| Percussion only | Freesound duff, frame drum, darbuka, tabla, clapping (`NOT_PERC` filter) | CC0 / CC BY | recordists of set2 excluded |
| Noise | Freesound street, rain, crowd, wind, applause (non-musical filter `MUSICAL`) | CC0 / CC BY | recordists of set2 excluded |

**Mixing recipe (per 9-window example, ≈ 5 s):**

- **Voice bed** (70 % of examples): speech, recitation, mujawwad or adhan. It is continuous: the hard case is music
  *all along under* a voice, not only beside it.
- **Music on:** 50 % of the examples have a music part, at a level drawn from **0 to -30 dB under the voice**, with
  extra weight on -15..-25 dB. Labels:
  - window = music when the music is within **-25 dB** of the voice;
  - below -28 dB = none, so the model is not pushed towards the inaudible;
  - -25..-28 dB = no loss (masked).
- **Percussion only:** a duff or clap loop under recitation, speech or a nasheed-like voice, labelled percussion.
  Duff + melodic instrument is labelled music.
- **Hard negatives,** weighted ×3 in the loss:
  - adhan;
  - mujawwad;
  - recitation in a hall: the RT60 1.5–3 s reverb of `build_music_check.py`, plus pyroomacoustics rooms
    (MIT licence);
  - voices with a long echo tail;
  - humming and vocal effects (if a clean source is found);
  - noise.
- **Channel:** loudspeaker band-limit (high-pass 150–400 Hz, low-pass 3.4–8 kHz, 30 %), phone-mic colouring,
  clipping (5 %), AAC 64 kbps / Opus 24–48 kbps round trips (40 %), gain -30..0 dBFS.
- **Amount:** about **60 h of mixed audio per epoch**, generated from about 25 h of sources (speech 8 h,
  recitation 8 h incl. 2 h mujawwad, adhan as much as the search finds (≥ 1 h), music 6 h, percussion 1 h, noise 2 h).
  Stage 1 precomputes about 400 k windows: mn04 at 3.5 ms per window is about 25 min on 1 thread, or 7 min on 4.

## Training

- **Stage 1** (server CPU):
  - Inputs: cached embeddings + logits.
  - Loss: binary cross-entropy with masks for music and for percussion; every group weighs the same, as `train_d`
    does.
  - Settings: Adam, 30 epochs, early stop on the validation reciters/recordists.
  - Time: under an hour.
- **Stage 2** (Kaggle, account `palaoks`, run from mhost with `uvx --with six kaggle`, see `kaggle-access` memory):
  - What: fine-tune mn04 blocks 10–15 + head, mixing on the fly in the notebook. Sources come from a private
    Kaggle dataset uploaded once.
  - Budget: one T4/P100 run of about 4 h (20 epochs × 60 h of mixes at about 1,500 windows/s).
  - The GPU quota is shared with the mishkat jobs, so check `kaggle kernels list` and the quota before pushing.
  - At most two runs, then back to the owner (the rule from the recitation work).
- **Logged per epoch:**
  - loss per group;
  - false-alarm rate per voice group (speech, recitation, mujawwad, adhan, hall) at the current threshold;
  - music-found rate per level band (0..-10, -10..-20, -20..-25);
  - percussion-only rate;
  - a confusion table on the validation sources.
- **Outputs:** `music_v1.onnx`, `music_v1_eval.json`, the per-group table, and the chosen thresholds.

## Evaluation (the gate)

1. **Same windows, same rules:** extend `eval/music_check_features.py` with a `tag_det` field (the new model's
   per-window scores). Add approach **E** to `eval/music_check_eval.py`: the same parts rule (gaps < 2 s bridged,
   parts < 3 s dropped). Thresholds are chosen on the tune split with the existing margin (≤ 1 % clean, ≤ 3 % noisy
   on tune).
2. **Report on the test split:** every bar line, per group, adhan on its own line, and background by level
   (-15/-20/-25 dB).
3. **New background clips:** about 40 clips of real vlogs/adverts with music under speech, labelled by hand, from
   CC BY / CC0 video (Wikimedia Commons, Openverse video). They become a separate group in set2 (test split only), so
   a synthetic-mix gain is checked on real mixes.
4. **Speed:** tagger + head per window on this server, 1 thread, and the phone estimate. Then a real measurement in
   the app's debug build on the slow-phone emulator profile and on a real phone before shipping.
5. Results go to `reports/music_detector.md`. Ship only if every bar line passes. Otherwise the shipped C path stays.

## Integration with the app

The shipped path: decode (Media3) → 32 kHz mono → 1 s windows every 0.5 s → tagger ONNX → rule C with its guard →
parts (bridge 2 s, drop < 3 s) → result.

- **Swap:**
  - The detector ONNX replaces the tagger ONNX, and the rule becomes "smoothed music score ≥ `im.music_threshold`",
    with percussion as its own score.
  - The window size, hop, parts rule, result screen and texts stay.
  - The code change is a model file plus reading three metadata keys. A model missing them keeps rule C (and logs
    why).
- **Contract:**
  - input `wave` float32 [N, 32000];
  - output `scores` float32 [N, 2] = (music, percussion_only) after the temporal head.
  - The head needs 9 windows of context, so the app feeds the clip's windows in one batch (clips ≤ 30 min:
    3,600 windows) or in overlapping chunks of 64 with 4 windows of overlap.
- **Tests:**
  - **Python parity:** PyTorch vs ONNX (fp16) per-window scores within 1e-3 on 200 test windows.
  - **JVM test vectors:** `android/app/src/test/resources/music/` holds 3 short clips (one song, one adhan, one
    speech + -20 dB music) with their expected per-window scores and parts (tolerance 1e-3 on scores, exact parts).
    A Kotlin test runs them through the same code path as the app.
  - The eval script's approach E reads the same ONNX the app ships.

## Steps and effort

| # | Step | Effort |
| --- | --- | --- |
| 1 | Holdout source list from set2; data builder (`testset/build_music_train.py`) with the exclusion check; new adhan/duff/percussion fetch from Openverse | 1 day |
| 2 | Mixing + labelling code (masks, levels, channel effects); unit tests on the labels | 1 day |
| 3 | Stage 1: cache embeddings, train head, approach E in the eval, report | 1 day |
| 4 | Real background-music clips (about 40) with hand labels | 0.5–1 day (depends on what Openverse video offers) |
| 5 | Stage 2 on Kaggle if stage 1 fails (notebook, dataset upload, 1–2 runs) | 2 days + run time |
| 6 | ONNX export with metadata, parity, JVM vectors, app swap, emulator checks | 1 day |

## Risks

- **Chant vs music is close by nature.** Mujawwad recitation and adhan use maqam melody. The head may learn
  "voice-only melody = none" only if the hard negatives are varied enough. The adhan sources are few (10 recordists
  already used by set2), so the new search must find more, or the adhan figure stays indicative.
- **A cappella nasheeds have no trainable clean source** (OpenSinger is NC). A false "music" on a voice-only nasheed
  stays possible. It is measured by the acapella group, which is 0/27 today with C.
- **Synthetic background mixes may not match real vlogs** (ducking, compression, music EQ'd under the voice). Step 4
  exists for that.
- **-25 dB under speech is close to inaudible** on a phone speaker. Missing it may be acceptable, see the decisions.
- **Kaggle GPU quota** is shared with the mishkat jobs and may delay stage 2.
- **Recitation data has no stated upstream licence:** the same class as voice_v1 and detector v3, which the owner
  accepted. It must be disclosed in THIRD_PARTY_LICENSES with the shipped model.

## Owner decisions

1. **Bar for background music:** count -25 dB in "music found", or only -15 and -20 dB (recommended: -20 dB and
   louder, as the bar's text says; -25 dB reported but not required).
2. **Recitation data without a stated licence** for this model, as for voice_v1 (recommended: yes, disclosed).
3. **Kaggle GPU time** for stage 2 (about 4–8 GPU hours) if stage 1 fails.
4. **Wikimedia adhan** stays eval only (BY-SA ones). Adding the CC0 / CC BY / PD ones to training would give more
   adhan variety but removes them from the gate.
