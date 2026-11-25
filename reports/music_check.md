# Check for music: evaluation

975 clips measured (387 tune, 588 test). Rates below are on the test split; thresholds were chosen on the tune split. A clip is about 20 s.

Run on 2026-11-25 with `eval/music_check_eval.py` over the set built by `testset/build_music_check.py`
(`/srv/build/music/set2`, not committed: audio). Tagger: EfficientAT mn04 (AudioSet, 527 classes). Engine for the
residual: voice_v1. Thresholds are chosen on the tune split with margin (false alarms at most half the bar there), then
judged on the test split, whose sources (speaker language, reciter, recordist, artist) the tuning never saw.

## Findings

- **No approach meets the whole pass bar.** Clips where the music is plain (songs, instrumentals, intro/outro
  music) are found reliably with few false alarms; music held 15–25 dB under continuous speech is mostly missed,
  and "percussion only" is labelled correctly for about a third to a half of the percussion clips at best.
- **Best overall: D** (a logistic model over the tags of the input and of the residual, plus the residual level,
  averaged over about 5 s): songs 41/41, instrumentals 72/74, intro/outro parts 13/14 found and 12/14 placed within
  2 s; false alarms 1.5 % on clean voice and 0 % on noisy recordings (bar: 2 % and 5 %). It needs the engine run.
- **Cheapest: C / Dm** (tags of the input only, no engine): C has the fewest false alarms (0.7 %) but finds less
  (71 %); Dm finds as much as D but its false alarms reach 2.6 %, almost all on adhan (6/25).
- **Music under speech**: in the residual, mn04's "Music" score for background music at −15/−20 dB (median 0.71)
  stands well above plain speech (0.06), but chanted voice (recitation 0.36, recitation in a hall 0.54, adhan 0.40)
  overlaps it: the engine removes part of melodic and reverberant voice, and the tagger hears that as music. The curve
  below shows the price: catching half of the −20 dB mixes costs 13–17 % false alarms on clean voice, a large share of them
  adhan.
- **Adhan** is the hardest "no music" group (6 test sources only; treat its rate as indicative). It is also where the
  filter itself misbehaves: the default dfn3 filter mutes the far-field Wikimedia `Adhan.ogg` completely
  (−25 → −73 dBFS); a filter issue to look at separately.
- **Approach A** (signal features, no model) is not usable: 16 % of music found.
- Groups with few sources: recitation and recitation in a hall (4 reciters), speech (5 FLEURS languages served by the
  dataset server; Bengali and Persian were unavailable), songs (7 artists in test), adhan (6). Room speech was
  stopped at 66 Freesound clips.

## Approach D: false alarms against music found (test split)

Tagger score averaged over 9 windows (about 5 s); percussion rule fixed (drums > 0.1, tonal < 0.3, share 0.3).

| Threshold | False alarms, clean | False alarms, noisy | Adhan false alarms | Music found | Background −15 dB | −20 dB | −25 dB | Intro/outro |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0.30 | 46/272 = 16.9% | 32/100 | 22/25 | 144/160 = 90% | 5/9 | 5/9 | 6/13 | 13/14 |
| 0.35 | 34/272 = 12.5% | 12/100 | 20/25 | 140/160 = 88% | 5/9 | 4/9 | 3/13 | 13/14 |
| 0.40 | 18/272 = 6.6% | 7/100 | 13/25 | 134/160 = 84% | 3/9 | 3/9 | 1/13 | 13/14 |
| 0.45 | 14/272 = 5.1% | 1/100 | 11/25 | 132/160 = 82% | 3/9 | 1/9 | 1/13 | 13/14 |
| 0.50 | 10/272 = 3.7% | 1/100 | 8/25 | 131/160 = 82% | 3/9 | 1/9 | 0/13 | 13/14 |
| 0.55 | 4/272 = 1.5% | 0/100 | 3/25 | 129/160 = 81% | 2/9 | 0/9 | 0/13 | 13/14 |
| 0.60 | 4/272 = 1.5% | 0/100 | 3/25 | 128/160 = 80% | 2/9 | 0/9 | 0/13 | 13/14 |

## Speed (estimate)

Measured on this server's CPU, one thread: the mn04 tagger takes 3.5 ms per 1 s window (one window every 0.5 s:
about 7 ms per second of audio); the voice_v1 engine (im-process, start-up included) about 130 ms per second of audio.
A Snapdragon 6-class phone core is roughly 3 to 5 times slower than this server's (estimate, not measured): a
1-minute clip would take about 1.5–2.5 s with the tags of the input only (C, Dm) and about 25–40 s with the engine
(B, D), well over the 10 s target, unless the engine runs on several cores or a lighter residual is used.

## Summary (test split)

| Approach | False alarms, clean voice (bar 2 %) | False alarms, noisy (bar 5 %) | Music found (bar 95 %) | Percussion only labelled (bar 85 %) | Parts within 2 s |
| --- | --- | --- | --- | --- | --- |
| A | 4/272 = 1.5% | 2/100 = 2.0% | 26/160 = 16.2% | 0/56 = 0.0% | 1/14 |
| B | 3/272 = 1.1% | 0/100 = 0.0% | 118/160 = 73.8% | 25/56 = 44.6% | 4/14 |
| C | 2/272 = 0.7% | 0/100 = 0.0% | 113/160 = 70.6% | 21/56 = 37.5% | 5/14 |
| BC | 3/272 = 1.1% | 0/100 = 0.0% | 114/160 = 71.2% | 22/56 = 39.3% | 5/14 |
| D | 4/272 = 1.5% | 0/100 = 0.0% | 128/160 = 80.0% | 20/56 = 35.7% | 12/14 |
| Dm | 7/272 = 2.6% | 0/100 = 0.0% | 130/160 = 81.2% | 20/56 = 35.7% | 12/14 |

## Clips per group and split

| Group | Tune | Test | Sources (test) |
| --- | --- | --- | --- |
| acapella | 16 | 27 | 23 |
| adhan | 21 | 25 | 6 |
| background | 30 | 45 | 32 |
| duff_nasheed | 15 | 25 | 23 |
| music_instr | 44 | 74 | 16 |
| music_song | 25 | 41 | 7 |
| noise | 56 | 60 | 53 |
| noisy_speech | 25 | 40 | 37 |
| percussion | 30 | 31 | 25 |
| recitation | 23 | 69 | 4 |
| recitation_hall | 13 | 27 | 4 |
| speech | 63 | 84 | 5 |
| speech_room | 26 | 40 | 19 |

## Approach A

Thresholds (from tune): `{"rel": -35, "tonal": 0.6, "rhythm": 0.6}`

| Group | Expected | Meaning | Tune | Test |
| --- | --- | --- | --- | --- |
| acapella | none | false alarms | 0/16 = 0% | 0/27 = 0% |
| adhan | none | false alarms | 0/21 = 0% | 3/25 = 12% |
| background | music | found | 3/30 = 10% | 2/45 = 4% |
| duff_nasheed | percussion | labelled percussion only | 1/15 = 7% | 0/25 = 0% |
| music_instr | music | found | 14/44 = 32% | 19/74 = 26% |
| music_song | music | found | 5/25 = 20% | 5/41 = 12% |
| noise | none | false alarms | 3/56 = 5% | 2/60 = 3% |
| noisy_speech | none | false alarms | 2/25 = 8% | 0/40 = 0% |
| percussion | percussion | labelled percussion only | 1/30 = 3% | 0/31 = 0% |
| recitation | none | false alarms | 0/23 = 0% | 1/69 = 1% |
| recitation_hall | none | false alarms | 0/13 = 0% | 0/27 = 0% |
| speech | none | false alarms | 1/63 = 2% | 0/84 = 0% |
| speech_room | none | false alarms | 1/26 = 4% | 0/40 = 0% |

Background music by level: -15 dB: 0/9, -20 dB: 0/9, -25 dB: 0/13, intro/outro: 2/14
Intro/outro parts placed within 2 s: 1/14
Percussion clips reported as no instruments: 49

Misses and false alarms (test):

- `recitation_ts_recitation_4000` (recitation, aac64): expected none, got music at 13.5-17.0 s
- `music_song_fma113511` (music_song, aac64): expected music, got none
- `music_song_fma113512` (music_song, none): expected music, got none
- `music_song_fma113513` (music_song, aac64): expected music, got none
- `music_song_fma118048` (music_song, opus32): expected music, got none
- `music_song_fma118052` (music_song, none): expected music, got none
- `music_song_fma118053` (music_song, none): expected music, got none
- `music_song_fma118054` (music_song, aac64): expected music, got none
- `music_song_fma118055` (music_song, none): expected music, got none
- `music_song_fma118056` (music_song, none): expected music, got none
- `music_song_fma20198` (music_song, none): expected music, got none
- `music_song_fma22472` (music_song, aac64): expected music, got none
- `music_song_fma22473` (music_song, none): expected music, got none
- `music_song_fma22474` (music_song, none): expected music, got none
- `music_song_fma22475` (music_song, none): expected music, got none
- `music_song_fma22476` (music_song, opus32): expected music, got none
- `music_song_fma22477` (music_song, none): expected music, got none
- `music_song_fma22478` (music_song, none): expected music, got none
- `music_song_fma22479` (music_song, aac64): expected music, got none
- `music_song_fma22480` (music_song, aac64): expected music, got none
- `music_song_fma3855` (music_song, none): expected music, got none
- `music_song_fma3856` (music_song, none): expected music, got none
- `music_song_fma3857` (music_song, none): expected music, got none
- `music_song_fma3859` (music_song, aac64): expected music, got none
- `music_song_fma3861` (music_song, none): expected music, got none
- `music_song_fma3862` (music_song, aac64): expected music, got none
- `music_song_fma3863` (music_song, none): expected music, got none
- `music_song_fma61491` (music_song, none): expected music, got none
- `music_song_fma61492` (music_song, none): expected music, got none
- `music_song_fma61493` (music_song, aac64): expected music, got none
- `music_song_fma75782` (music_song, aac64): expected music, got none
- `music_song_fma75783` (music_song, none): expected music, got none
- `music_song_fma75784` (music_song, aac64): expected music, got none
- `music_song_fma75785` (music_song, none): expected music, got none
- `music_song_fma75786` (music_song, aac64): expected music, got none
- `music_song_fma75787` (music_song, aac64): expected music, got none
- `music_song_fma75788` (music_song, aac64): expected music, got none
- `noise_fs11dea6fd_0` (noise, aac64): expected none, got percussion at 0.0-20.0 s
- `noise_fs110f9453_0` (noise, aac64): expected none, got percussion at 2.0-10.0, 13.0-18.5 s
- `percussion_fs7c48e045_0` (percussion, aac64): expected percussion, got none
- `percussion_fsdc8a0780_0` (percussion, none): expected percussion, got none
- `percussion_fs0602c0bd_0` (percussion, opus32): expected percussion, got none
- `percussion_fse0d59f6c_0` (percussion, aac64): expected percussion, got none
- `percussion_fs251072b4_0` (percussion, none): expected percussion, got none
- `percussion_fs7150cc88_0` (percussion, aac64): expected percussion, got none
- `percussion_fsf7653c36_0` (percussion, none): expected percussion, got none
- `percussion_fs2b7569a3_0` (percussion, none): expected percussion, got none
- `percussion_fsb0de54ac_0` (percussion, aac64): expected percussion, got music at 10.0-13.0 s
- `percussion_fsd2e82abb_0` (percussion, none): expected percussion, got none
- `percussion_fsa30b1f5a_0` (percussion, none): expected percussion, got music at 7.0-10.0 s
- `percussion_fs5f6e6e3a_0` (percussion, aac64): expected percussion, got none
- `percussion_fs28744cde_0` (percussion, opus32): expected percussion, got none
- `percussion_fs18d5da18_0` (percussion, opus32): expected percussion, got none
- `percussion_fs6bd6e761_0` (percussion, opus32): expected percussion, got none
- `percussion_fs008b24af_0` (percussion, aac64): expected percussion, got none
- `percussion_fs51bbfcd7_0` (percussion, none): expected percussion, got none
- `percussion_fs1f8eed62_0` (percussion, aac64): expected percussion, got music at 0.5-12.0 s
- `percussion_fs566875fc_0` (percussion, none): expected percussion, got music at 3.5-8.5 s
- `percussion_fsa9947952_0` (percussion, none): expected percussion, got music at 1.0-15.5 s
- `percussion_fs34d9e6d3_0` (percussion, none): expected percussion, got none
- `percussion_fsa541818e_0` (percussion, aac64): expected percussion, got none
- `percussion_fsec391cbf_0` (percussion, none): expected percussion, got none
- `percussion_fs6f0c61b8_0` (percussion, none): expected percussion, got none
- `percussion_fs87878ab7_0` (percussion, none): expected percussion, got none
- `percussion_fsf4c0fc5f_0` (percussion, none): expected percussion, got none
- `percussion_fs5fbb1c04_0` (percussion, none): expected percussion, got none
- `percussion_fs43560c17_0` (percussion, none): expected percussion, got none
- `percussion_fs9aa75005_0` (percussion, opus32): expected percussion, got music at 4.5-19.0 s
- `percussion_fsc43f1ee3_0` (percussion, aac64): expected percussion, got none
- `percussion_fs11bd2f16_0` (percussion, aac64): expected percussion, got none
- `adhan_fs144431_1` (adhan, none): expected none, got music at 10.5-15.5 s
- `adhan_fs423945_0` (adhan, opus32): expected none, got music at 0.0-5.5 s
- `adhan_fs423945_2` (adhan, none): expected none, got music at 6.0-10.0, 15.0-19.5 s
- `music_instr_fma37976` (music_instr, opus32): expected music, got none
- `music_instr_fma37977` (music_instr, none): expected music, got none
- `music_instr_fma37978` (music_instr, none): expected music, got none
- `music_instr_fma37979` (music_instr, opus32): expected music, got none
- `music_instr_fma140317` (music_instr, aac64): expected music, got none
- `music_instr_fma140319` (music_instr, opus32): expected music, got none
- `music_instr_fma140320` (music_instr, aac64): expected music, got none
- `music_instr_fma140321` (music_instr, none): expected music, got none
- `music_instr_fma140322` (music_instr, opus32): expected music, got none
- `music_instr_fma140323` (music_instr, aac64): expected music, got none
- `music_instr_fma140329` (music_instr, aac64): expected music, got none
- `music_instr_fma140330` (music_instr, none): expected music, got none
- `music_instr_fma140331` (music_instr, aac64): expected music, got none
- `music_instr_fma140335` (music_instr, none): expected music, got none
- `music_instr_fma140337` (music_instr, none): expected music, got none
- `music_instr_fma140340` (music_instr, none): expected music, got none
- `music_instr_fma140341` (music_instr, none): expected music, got none
- `music_instr_fma140344` (music_instr, aac64): expected music, got none
- `music_instr_fma141074` (music_instr, none): expected music, got none
- `music_instr_fma50975` (music_instr, none): expected music, got none
- `music_instr_fma50970` (music_instr, none): expected music, got none
- `music_instr_fma50971` (music_instr, aac64): expected music, got none
- `music_instr_fma149489` (music_instr, aac64): expected music, got none
- `music_instr_fma149695` (music_instr, none): expected music, got none
- `music_instr_fma149696` (music_instr, aac64): expected music, got none
- `music_instr_fma149712` (music_instr, none): expected music, got none
- `music_instr_fma149713` (music_instr, none): expected music, got none
- `music_instr_fma149714` (music_instr, none): expected music, got none
- `music_instr_fma149755` (music_instr, aac64): expected music, got none
- `music_instr_fma149756` (music_instr, none): expected music, got none
- `music_instr_fma149775` (music_instr, aac64): expected music, got none
- `music_instr_fma149776` (music_instr, aac64): expected music, got none
- `music_instr_fma149777` (music_instr, aac64): expected music, got none
- `music_instr_fma149778` (music_instr, aac64): expected music, got none
- `music_instr_fma152480` (music_instr, none): expected music, got none
- `music_instr_fma141877` (music_instr, aac64): expected music, got none
- `music_instr_fma141878` (music_instr, none): expected music, got none
- `music_instr_fma141892` (music_instr, opus32): expected music, got none
- `music_instr_fma141893` (music_instr, opus32): expected music, got none
- `music_instr_fma141895` (music_instr, none): expected music, got none
- `music_instr_fma144779` (music_instr, none): expected music, got none
- `music_instr_fma144781` (music_instr, none): expected music, got none
- `music_instr_fma144782` (music_instr, aac64): expected music, got none
- `music_instr_fma10033` (music_instr, opus32): expected music, got none
- `music_instr_fma10035` (music_instr, aac64): expected music, got none
- `music_instr_fma10037` (music_instr, opus32): expected music, got none
- `music_instr_fma10038` (music_instr, none): expected music, got none
- `music_instr_fma10693` (music_instr, opus32): expected music, got none
- `music_instr_fma10694` (music_instr, none): expected music, got none
- `music_instr_fma10695` (music_instr, none): expected music, got none
- `music_instr_fma10696` (music_instr, opus32): expected music, got none
- `music_instr_fma10697` (music_instr, aac64): expected music, got none
- `music_instr_fma10698` (music_instr, none): expected music, got none
- `music_instr_fma10699` (music_instr, none): expected music, got none
- `music_instr_fma11206` (music_instr, aac64): expected music, got none
- `background_test_0` (background, none): expected music, got none
- `background_test_1` (background, opus32): expected music, got none
- `background_test_2` (background, aac64): expected music, got none
- `background_test_3` (background, none): expected music, got none
- `background_test_4` (background, none): expected music, got none
- `background_test_5` (background, opus32): expected music, got none
- `background_test_6` (background, none): expected music, got none
- `background_test_7` (background, opus32): expected music, got none
- `background_test_8` (background, none): expected music, got none
- `background_test_9` (background, none): expected music, got none
- `background_test_10` (background, none): expected music, got none
- `background_test_11` (background, none): expected music, got none
- `background_test_12` (background, none): expected music, got none
- `background_test_13` (background, none): expected music, got none
- `background_test_14` (background, aac64): expected music, got none
- `background_test_15` (background, opus32): expected music, got none
- `background_test_16` (background, aac64): expected music, got none
- `background_test_17` (background, none): expected music, got none
- `background_test_18` (background, aac64): expected music, got none
- `background_test_19` (background, none): expected music, got none
- `background_test_20` (background, opus32): expected music, got none
- `background_test_21` (background, aac64): expected music, got none
- `background_test_22` (background, none): expected music, got none
- `background_test_23` (background, none): expected music, got none
- `background_test_25` (background, aac64): expected music, got none
- `background_test_26` (background, aac64): expected music, got none
- `background_test_27` (background, aac64): expected music, got none
- `background_test_28` (background, none): expected music, got none
- `background_test_29` (background, aac64): expected music, got none
- `background_test_30` (background, aac64): expected music, got none
- `background_test_31` (background, none): expected music, got none
- `background_test_32` (background, aac64): expected music, got none
- `background_test_33` (background, opus32): expected music, got none
- `background_test_34` (background, aac64): expected music, got none
- `background_test_35` (background, none): expected music, got none
- `background_test_36` (background, opus32): expected music, got none
- `background_test_37` (background, none): expected music, got none
- `background_test_38` (background, aac64): expected music, got none
- `background_test_39` (background, opus32): expected music, got none
- `background_test_41` (background, aac64): expected music, got none
- `background_test_42` (background, none): expected music, got none
- `background_test_43` (background, opus32): expected music, got none
- `background_test_44` (background, none): expected music, got none
- `duffnasheed_test_0` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_1` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_2` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_3` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_4` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_5` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_6` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_7` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_8` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_9` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_10` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_11` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_12` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_13` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_14` (duff_nasheed, opus32): expected percussion, got music at 0.5-5.5 s
- `duffnasheed_test_15` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_16` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_17` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_18` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_19` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_20` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_21` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_22` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_23` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_24` (duff_nasheed, none): expected percussion, got none

## Approach B

Thresholds (from tune): `{"rel": -20, "music": 0.75, "vocal": 0.5, "perc": 0.1, "tonal_max": 0.2, "pshare": 0.3}`

| Group | Expected | Meaning | Tune | Test |
| --- | --- | --- | --- | --- |
| acapella | none | false alarms | 0/16 = 0% | 0/27 = 0% |
| adhan | none | false alarms | 0/21 = 0% | 0/25 = 0% |
| background | music | found | 12/30 = 40% | 12/45 = 27% |
| duff_nasheed | percussion | labelled percussion only | 1/15 = 7% | 6/25 = 24% |
| music_instr | music | found | 33/44 = 75% | 66/74 = 89% |
| music_song | music | found | 24/25 = 96% | 40/41 = 98% |
| noise | none | false alarms | 1/56 = 2% | 0/60 = 0% |
| noisy_speech | none | false alarms | 1/25 = 4% | 0/40 = 0% |
| percussion | percussion | labelled percussion only | 20/30 = 67% | 19/31 = 61% |
| recitation | none | false alarms | 0/23 = 0% | 0/69 = 0% |
| recitation_hall | none | false alarms | 4/13 = 31% | 2/27 = 7% |
| speech | none | false alarms | 0/63 = 0% | 1/84 = 1% |
| speech_room | none | false alarms | 1/26 = 4% | 0/40 = 0% |

Background music by level: -15 dB: 3/9, -20 dB: 0/9, -25 dB: 0/13, intro/outro: 9/14
Intro/outro parts placed within 2 s: 4/14
Percussion clips reported as no instruments: 23

Misses and false alarms (test):

- `music_song_fma20198` (music_song, none): expected music, got none
- `recitation_hall_qa_mahmoud_ali_al_banna_11_21` (recitation_hall, aac64): expected none, got music at 2.5-5.5 s
- `recitation_hall_qa_mahmoud_ali_al_banna_11_18` (recitation_hall, aac64): expected none, got music at 4.0-9.5 s
- `percussion_fs7c48e045_0` (percussion, aac64): expected percussion, got none
- `percussion_fse0d59f6c_0` (percussion, aac64): expected percussion, got music at 0.5-15.0 s
- `percussion_fs2b7569a3_0` (percussion, none): expected percussion, got none
- `percussion_fsb0de54ac_0` (percussion, aac64): expected percussion, got none
- `percussion_fsa30b1f5a_0` (percussion, none): expected percussion, got music at 2.5-12.0 s
- `percussion_fs5f6e6e3a_0` (percussion, aac64): expected percussion, got music at 0.0-7.0 s
- `percussion_fs28744cde_0` (percussion, opus32): expected percussion, got none
- `percussion_fs6bd6e761_0` (percussion, opus32): expected percussion, got none
- `percussion_fsa541818e_0` (percussion, aac64): expected percussion, got none
- `percussion_fs6f0c61b8_0` (percussion, none): expected percussion, got none
- `percussion_fs87878ab7_0` (percussion, none): expected percussion, got music at 4.5-8.5 s
- `percussion_fs9aa75005_0` (percussion, opus32): expected percussion, got none
- `speech_fleurs_fr_fr_12` (speech, none): expected none, got percussion at 2.5-5.5 s
- `music_instr_fma140322` (music_instr, opus32): expected music, got none
- `music_instr_fma149489` (music_instr, aac64): expected music, got none
- `music_instr_fma149755` (music_instr, aac64): expected music, got none
- `music_instr_fma149778` (music_instr, aac64): expected music, got none
- `music_instr_fma144782` (music_instr, aac64): expected music, got none
- `music_instr_fma10035` (music_instr, aac64): expected music, got none
- `music_instr_fma10037` (music_instr, opus32): expected music, got none
- `music_instr_fma10044` (music_instr, aac64): expected music, got none
- `background_test_1` (background, opus32): expected music, got none
- `background_test_3` (background, none): expected music, got none
- `background_test_4` (background, none): expected music, got none
- `background_test_5` (background, opus32): expected music, got none
- `background_test_6` (background, none): expected music, got none
- `background_test_7` (background, opus32): expected music, got none
- `background_test_8` (background, none): expected music, got none
- `background_test_9` (background, none): expected music, got none
- `background_test_10` (background, none): expected music, got none
- `background_test_11` (background, none): expected music, got none
- `background_test_12` (background, none): expected music, got none
- `background_test_13` (background, none): expected music, got none
- `background_test_14` (background, aac64): expected music, got none
- `background_test_15` (background, opus32): expected music, got none
- `background_test_16` (background, aac64): expected music, got none
- `background_test_17` (background, none): expected music, got none
- `background_test_19` (background, none): expected music, got none
- `background_test_20` (background, opus32): expected music, got none
- `background_test_21` (background, aac64): expected music, got none
- `background_test_22` (background, none): expected music, got none
- `background_test_23` (background, none): expected music, got none
- `background_test_25` (background, aac64): expected music, got none
- `background_test_26` (background, aac64): expected music, got none
- `background_test_28` (background, none): expected music, got none
- `background_test_29` (background, aac64): expected music, got none
- `background_test_31` (background, none): expected music, got none
- `background_test_32` (background, aac64): expected music, got none
- `background_test_35` (background, none): expected music, got none
- `background_test_36` (background, opus32): expected music, got none
- `background_test_37` (background, none): expected music, got none
- `background_test_41` (background, aac64): expected music, got none
- `background_test_42` (background, none): expected music, got none
- `background_test_44` (background, none): expected music, got none
- `duffnasheed_test_1` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_2` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_5` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_6` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_7` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_8` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_9` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_10` (duff_nasheed, aac64): expected percussion, got music at 1.0-5.5 s
- `duffnasheed_test_11` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_13` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_14` (duff_nasheed, opus32): expected percussion, got music at 1.0-7.0 s
- `duffnasheed_test_16` (duff_nasheed, opus32): expected percussion, got music at 2.0-5.5 s
- `duffnasheed_test_17` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_18` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_19` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_20` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_21` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_22` (duff_nasheed, opus32): expected percussion, got music at 2.5-5.5 s
- `duffnasheed_test_24` (duff_nasheed, none): expected percussion, got none

## Approach C

Thresholds (from tune): `{"rel": -99, "music": 0.75, "vocal": 0.5, "perc": 0.1, "tonal_max": 0.3, "pshare": 0.3}`

| Group | Expected | Meaning | Tune | Test |
| --- | --- | --- | --- | --- |
| acapella | none | false alarms | 0/16 = 0% | 0/27 = 0% |
| adhan | none | false alarms | 0/21 = 0% | 2/25 = 8% |
| background | music | found | 9/30 = 30% | 10/45 = 22% |
| duff_nasheed | percussion | labelled percussion only | 0/15 = 0% | 0/25 = 0% |
| music_instr | music | found | 33/44 = 75% | 64/74 = 86% |
| music_song | music | found | 23/25 = 92% | 39/41 = 95% |
| noise | none | false alarms | 1/56 = 2% | 0/60 = 0% |
| noisy_speech | none | false alarms | 0/25 = 0% | 0/40 = 0% |
| percussion | percussion | labelled percussion only | 22/30 = 73% | 21/31 = 68% |
| recitation | none | false alarms | 0/23 = 0% | 0/69 = 0% |
| recitation_hall | none | false alarms | 0/13 = 0% | 0/27 = 0% |
| speech | none | false alarms | 1/63 = 2% | 0/84 = 0% |
| speech_room | none | false alarms | 0/26 = 0% | 0/40 = 0% |

Background music by level: -15 dB: 1/9, -20 dB: 0/9, -25 dB: 0/13, intro/outro: 9/14
Intro/outro parts placed within 2 s: 5/14
Percussion clips reported as no instruments: 33

Misses and false alarms (test):

- `music_song_fma20198` (music_song, none): expected music, got none
- `music_song_fma22475` (music_song, none): expected music, got none
- `percussion_fse0d59f6c_0` (percussion, aac64): expected percussion, got music at 0.5-15.0 s
- `percussion_fs2b7569a3_0` (percussion, none): expected percussion, got none
- `percussion_fsb0de54ac_0` (percussion, aac64): expected percussion, got none
- `percussion_fs5f6e6e3a_0` (percussion, aac64): expected percussion, got none
- `percussion_fs28744cde_0` (percussion, opus32): expected percussion, got none
- `percussion_fs6bd6e761_0` (percussion, opus32): expected percussion, got music at 2.0-7.0 s
- `percussion_fs1f8eed62_0` (percussion, aac64): expected percussion, got none
- `percussion_fsa541818e_0` (percussion, aac64): expected percussion, got none
- `percussion_fs6f0c61b8_0` (percussion, none): expected percussion, got none
- `percussion_fs9aa75005_0` (percussion, opus32): expected percussion, got none
- `adhan_fs144431_1` (adhan, none): expected none, got music at 10.5-14.5 s
- `adhan_fs534968_2` (adhan, aac64): expected none, got percussion at 2.5-5.5 s
- `music_instr_fma140321` (music_instr, none): expected music, got none
- `music_instr_fma140322` (music_instr, opus32): expected music, got none
- `music_instr_fma140336` (music_instr, none): expected music, got none
- `music_instr_fma149489` (music_instr, aac64): expected music, got none
- `music_instr_fma149755` (music_instr, aac64): expected music, got none
- `music_instr_fma149778` (music_instr, aac64): expected music, got none
- `music_instr_fma144782` (music_instr, aac64): expected music, got none
- `music_instr_fma10035` (music_instr, aac64): expected music, got none
- `music_instr_fma10037` (music_instr, opus32): expected music, got none
- `music_instr_fma10044` (music_instr, aac64): expected music, got none
- `background_test_1` (background, opus32): expected music, got none
- `background_test_3` (background, none): expected music, got none
- `background_test_4` (background, none): expected music, got none
- `background_test_5` (background, opus32): expected music, got none
- `background_test_6` (background, none): expected music, got none
- `background_test_7` (background, opus32): expected music, got none
- `background_test_8` (background, none): expected music, got none
- `background_test_9` (background, none): expected music, got none
- `background_test_10` (background, none): expected music, got none
- `background_test_11` (background, none): expected music, got none
- `background_test_12` (background, none): expected music, got none
- `background_test_13` (background, none): expected music, got none
- `background_test_14` (background, aac64): expected music, got none
- `background_test_15` (background, opus32): expected music, got none
- `background_test_16` (background, aac64): expected music, got none
- `background_test_17` (background, none): expected music, got none
- `background_test_19` (background, none): expected music, got none
- `background_test_20` (background, opus32): expected music, got none
- `background_test_21` (background, aac64): expected music, got none
- `background_test_22` (background, none): expected music, got none
- `background_test_23` (background, none): expected music, got none
- `background_test_25` (background, aac64): expected music, got none
- `background_test_26` (background, aac64): expected music, got none
- `background_test_28` (background, none): expected music, got none
- `background_test_29` (background, aac64): expected music, got none
- `background_test_30` (background, aac64): expected music, got none
- `background_test_31` (background, none): expected music, got none
- `background_test_32` (background, aac64): expected music, got none
- `background_test_35` (background, none): expected music, got none
- `background_test_36` (background, opus32): expected music, got none
- `background_test_37` (background, none): expected music, got none
- `background_test_39` (background, opus32): expected music, got none
- `background_test_41` (background, aac64): expected music, got none
- `background_test_42` (background, none): expected music, got none
- `background_test_44` (background, none): expected music, got none
- `duffnasheed_test_0` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_1` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_2` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_3` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_4` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_5` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_6` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_7` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_8` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_9` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_10` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_11` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_12` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_13` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_14` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_15` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_16` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_17` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_18` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_19` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_20` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_21` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_22` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_23` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_24` (duff_nasheed, none): expected percussion, got none

## Approach BC

Thresholds (from tune): `{"rel": -20, "music": 0.75, "vocal": 0.5, "perc": 0.2, "tonal_max": 0.3, "pshare": 0.3}`

| Group | Expected | Meaning | Tune | Test |
| --- | --- | --- | --- | --- |
| acapella | none | false alarms | 0/16 = 0% | 0/27 = 0% |
| adhan | none | false alarms | 0/21 = 0% | 1/25 = 4% |
| background | music | found | 11/30 = 37% | 11/45 = 24% |
| duff_nasheed | percussion | labelled percussion only | 0/15 = 0% | 4/25 = 16% |
| music_instr | music | found | 33/44 = 75% | 63/74 = 85% |
| music_song | music | found | 24/25 = 96% | 40/41 = 98% |
| noise | none | false alarms | 1/56 = 2% | 0/60 = 0% |
| noisy_speech | none | false alarms | 1/25 = 4% | 0/40 = 0% |
| percussion | percussion | labelled percussion only | 18/30 = 60% | 18/31 = 58% |
| recitation | none | false alarms | 0/23 = 0% | 0/69 = 0% |
| recitation_hall | none | false alarms | 6/13 = 46% | 2/27 = 7% |
| speech | none | false alarms | 0/63 = 0% | 0/84 = 0% |
| speech_room | none | false alarms | 1/26 = 4% | 0/40 = 0% |

Background music by level: -15 dB: 3/9, -20 dB: 0/9, -25 dB: 0/13, intro/outro: 8/14
Intro/outro parts placed within 2 s: 5/14
Percussion clips reported as no instruments: 25

Misses and false alarms (test):

- `music_song_fma20198` (music_song, none): expected music, got none
- `recitation_hall_qa_mahmoud_ali_al_banna_11_21` (recitation_hall, aac64): expected none, got music at 2.5-5.5 s
- `recitation_hall_qa_mahmoud_ali_al_banna_11_18` (recitation_hall, aac64): expected none, got music at 4.0-9.5 s
- `percussion_fse0d59f6c_0` (percussion, aac64): expected percussion, got music at 0.5-15.0 s
- `percussion_fs2b7569a3_0` (percussion, none): expected percussion, got none
- `percussion_fsb0de54ac_0` (percussion, aac64): expected percussion, got none
- `percussion_fsa30b1f5a_0` (percussion, none): expected percussion, got music at 2.0-11.5 s
- `percussion_fs5f6e6e3a_0` (percussion, aac64): expected percussion, got music at 0.0-7.0 s
- `percussion_fs28744cde_0` (percussion, opus32): expected percussion, got none
- `percussion_fs6bd6e761_0` (percussion, opus32): expected percussion, got music at 2.0-7.0 s
- `percussion_fs1f8eed62_0` (percussion, aac64): expected percussion, got music at 5.5-11.0 s
- `percussion_fsa541818e_0` (percussion, aac64): expected percussion, got none
- `percussion_fs6f0c61b8_0` (percussion, none): expected percussion, got none
- `percussion_fs87878ab7_0` (percussion, none): expected percussion, got none
- `percussion_fs5fbb1c04_0` (percussion, none): expected percussion, got music at 1.0-13.0, 16.0-19.5 s
- `percussion_fs9aa75005_0` (percussion, opus32): expected percussion, got none
- `adhan_fs144431_1` (adhan, none): expected none, got music at 10.5-14.5 s
- `music_instr_fma140322` (music_instr, opus32): expected music, got none
- `music_instr_fma140331` (music_instr, aac64): expected music, got none
- `music_instr_fma140333` (music_instr, aac64): expected music, got none
- `music_instr_fma140336` (music_instr, none): expected music, got none
- `music_instr_fma149489` (music_instr, aac64): expected music, got none
- `music_instr_fma149755` (music_instr, aac64): expected music, got none
- `music_instr_fma149778` (music_instr, aac64): expected music, got none
- `music_instr_fma144782` (music_instr, aac64): expected music, got none
- `music_instr_fma10035` (music_instr, aac64): expected music, got none
- `music_instr_fma10037` (music_instr, opus32): expected music, got none
- `music_instr_fma10044` (music_instr, aac64): expected music, got none
- `background_test_0` (background, none): expected music, got none
- `background_test_1` (background, opus32): expected music, got none
- `background_test_3` (background, none): expected music, got none
- `background_test_4` (background, none): expected music, got none
- `background_test_5` (background, opus32): expected music, got none
- `background_test_6` (background, none): expected music, got none
- `background_test_7` (background, opus32): expected music, got none
- `background_test_8` (background, none): expected music, got none
- `background_test_9` (background, none): expected music, got none
- `background_test_10` (background, none): expected music, got none
- `background_test_11` (background, none): expected music, got none
- `background_test_12` (background, none): expected music, got none
- `background_test_13` (background, none): expected music, got none
- `background_test_14` (background, aac64): expected music, got none
- `background_test_15` (background, opus32): expected music, got none
- `background_test_16` (background, aac64): expected music, got none
- `background_test_17` (background, none): expected music, got none
- `background_test_19` (background, none): expected music, got none
- `background_test_20` (background, opus32): expected music, got none
- `background_test_21` (background, aac64): expected music, got none
- `background_test_22` (background, none): expected music, got none
- `background_test_23` (background, none): expected music, got none
- `background_test_25` (background, aac64): expected music, got none
- `background_test_26` (background, aac64): expected music, got none
- `background_test_28` (background, none): expected music, got none
- `background_test_29` (background, aac64): expected music, got none
- `background_test_31` (background, none): expected music, got none
- `background_test_32` (background, aac64): expected music, got none
- `background_test_35` (background, none): expected music, got none
- `background_test_36` (background, opus32): expected music, got none
- `background_test_37` (background, none): expected music, got none
- `background_test_41` (background, aac64): expected music, got none
- `background_test_42` (background, none): expected music, got none
- `background_test_44` (background, none): expected music, got none
- `duffnasheed_test_0` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_1` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_2` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_5` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_6` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_7` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_8` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_9` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_10` (duff_nasheed, aac64): expected percussion, got music at 1.0-5.5 s
- `duffnasheed_test_11` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_13` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_14` (duff_nasheed, opus32): expected percussion, got music at 1.0-7.0 s
- `duffnasheed_test_16` (duff_nasheed, opus32): expected percussion, got music at 2.0-5.5 s
- `duffnasheed_test_17` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_18` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_19` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_20` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_21` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_22` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_23` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_24` (duff_nasheed, none): expected percussion, got none

## Approach D

Thresholds (from tune): `{"music": 0.6, "smooth": 9, "perc": 0.1, "tonal_max": 0.3, "pshare": 0.3}`

| Group | Expected | Meaning | Tune | Test |
| --- | --- | --- | --- | --- |
| acapella | none | false alarms | 0/16 = 0% | 0/27 = 0% |
| adhan | none | false alarms | 0/21 = 0% | 3/25 = 12% |
| background | music | found | 10/30 = 33% | 15/45 = 33% |
| duff_nasheed | percussion | labelled percussion only | 0/15 = 0% | 0/25 = 0% |
| music_instr | music | found | 34/44 = 77% | 72/74 = 97% |
| music_song | music | found | 25/25 = 100% | 41/41 = 100% |
| noise | none | false alarms | 2/56 = 4% | 0/60 = 0% |
| noisy_speech | none | false alarms | 0/25 = 0% | 0/40 = 0% |
| percussion | percussion | labelled percussion only | 21/30 = 70% | 20/31 = 65% |
| recitation | none | false alarms | 0/23 = 0% | 0/69 = 0% |
| recitation_hall | none | false alarms | 0/13 = 0% | 0/27 = 0% |
| speech | none | false alarms | 1/63 = 2% | 0/84 = 0% |
| speech_room | none | false alarms | 0/26 = 0% | 1/40 = 2% |

Background music by level: -15 dB: 2/9, -20 dB: 0/9, -25 dB: 0/13, intro/outro: 13/14
Intro/outro parts placed within 2 s: 12/14
Percussion clips reported as no instruments: 23

Misses and false alarms (test):

- `percussion_fse0d59f6c_0` (percussion, aac64): expected percussion, got music at 0.0-15.0 s
- `percussion_fs2b7569a3_0` (percussion, none): expected percussion, got none
- `percussion_fsb0de54ac_0` (percussion, aac64): expected percussion, got none
- `percussion_fs5f6e6e3a_0` (percussion, aac64): expected percussion, got music at 0.0-7.0 s
- `percussion_fs28744cde_0` (percussion, opus32): expected percussion, got none
- `percussion_fs6bd6e761_0` (percussion, opus32): expected percussion, got music at 0.0-12.0 s
- `percussion_fs1f8eed62_0` (percussion, aac64): expected percussion, got music at 1.0-12.0 s
- `percussion_fsa541818e_0` (percussion, aac64): expected percussion, got none
- `percussion_fs6f0c61b8_0` (percussion, none): expected percussion, got music at 0.0-17.5 s
- `percussion_fs87878ab7_0` (percussion, none): expected percussion, got music at 3.5-20.0 s
- `percussion_fs9aa75005_0` (percussion, opus32): expected percussion, got music at 5.0-16.5 s
- `adhan_fs144431_1` (adhan, none): expected none, got music at 11.5-14.5 s
- `adhan_fs144432_0` (adhan, opus32): expected none, got music at 6.5-10.0 s
- `adhan_fs534968_2` (adhan, aac64): expected none, got music at 0.0-5.5 s
- `music_instr_fma149778` (music_instr, aac64): expected music, got none
- `music_instr_fma10035` (music_instr, aac64): expected music, got none
- `background_test_1` (background, opus32): expected music, got none
- `background_test_3` (background, none): expected music, got none
- `background_test_4` (background, none): expected music, got none
- `background_test_5` (background, opus32): expected music, got none
- `background_test_6` (background, none): expected music, got none
- `background_test_7` (background, opus32): expected music, got none
- `background_test_8` (background, none): expected music, got none
- `background_test_9` (background, none): expected music, got none
- `background_test_10` (background, none): expected music, got none
- `background_test_12` (background, none): expected music, got none
- `background_test_13` (background, none): expected music, got none
- `background_test_14` (background, aac64): expected music, got none
- `background_test_15` (background, opus32): expected music, got none
- `background_test_16` (background, aac64): expected music, got none
- `background_test_19` (background, none): expected music, got none
- `background_test_21` (background, aac64): expected music, got none
- `background_test_22` (background, none): expected music, got none
- `background_test_23` (background, none): expected music, got none
- `background_test_25` (background, aac64): expected music, got none
- `background_test_26` (background, aac64): expected music, got none
- `background_test_28` (background, none): expected music, got none
- `background_test_29` (background, aac64): expected music, got none
- `background_test_30` (background, aac64): expected music, got none
- `background_test_31` (background, none): expected music, got none
- `background_test_32` (background, aac64): expected music, got none
- `background_test_35` (background, none): expected music, got none
- `background_test_36` (background, opus32): expected music, got none
- `background_test_37` (background, none): expected music, got none
- `background_test_42` (background, none): expected music, got none
- `background_test_44` (background, none): expected music, got none
- `duffnasheed_test_0` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_1` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_2` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_3` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_4` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_5` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_6` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_7` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_8` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_9` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_10` (duff_nasheed, aac64): expected percussion, got music at 2.5-5.5 s
- `duffnasheed_test_11` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_12` (duff_nasheed, none): expected percussion, got music at 3.5-7.0 s
- `duffnasheed_test_13` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_14` (duff_nasheed, opus32): expected percussion, got music at 2.5-7.0 s
- `duffnasheed_test_15` (duff_nasheed, aac64): expected percussion, got music at 1.0-6.0 s
- `duffnasheed_test_16` (duff_nasheed, opus32): expected percussion, got music at 2.0-7.5 s
- `duffnasheed_test_17` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_18` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_19` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_20` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_21` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_22` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_23` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_24` (duff_nasheed, none): expected percussion, got music at 0.0-4.0 s
- `speech_room_fs833bdccf_0` (speech_room, aac64): expected none, got music at 0.5-12.5 s

## Approach Dm

Thresholds (from tune): `{"music": 0.5, "smooth": 9, "perc": 0.1, "tonal_max": 0.3, "pshare": 0.3}`

| Group | Expected | Meaning | Tune | Test |
| --- | --- | --- | --- | --- |
| acapella | none | false alarms | 0/16 = 0% | 0/27 = 0% |
| adhan | none | false alarms | 0/21 = 0% | 6/25 = 24% |
| background | music | found | 10/30 = 33% | 16/45 = 36% |
| duff_nasheed | percussion | labelled percussion only | 0/15 = 0% | 0/25 = 0% |
| music_instr | music | found | 36/44 = 82% | 73/74 = 99% |
| music_song | music | found | 25/25 = 100% | 41/41 = 100% |
| noise | none | false alarms | 2/56 = 4% | 0/60 = 0% |
| noisy_speech | none | false alarms | 0/25 = 0% | 0/40 = 0% |
| percussion | percussion | labelled percussion only | 21/30 = 70% | 20/31 = 65% |
| recitation | none | false alarms | 0/23 = 0% | 0/69 = 0% |
| recitation_hall | none | false alarms | 0/13 = 0% | 0/27 = 0% |
| speech | none | false alarms | 1/63 = 2% | 0/84 = 0% |
| speech_room | none | false alarms | 0/26 = 0% | 1/40 = 2% |

Background music by level: -15 dB: 2/9, -20 dB: 1/9, -25 dB: 0/13, intro/outro: 13/14
Intro/outro parts placed within 2 s: 12/14
Percussion clips reported as no instruments: 25

Misses and false alarms (test):

- `percussion_fse0d59f6c_0` (percussion, aac64): expected percussion, got music at 0.0-15.0 s
- `percussion_fs2b7569a3_0` (percussion, none): expected percussion, got none
- `percussion_fsb0de54ac_0` (percussion, aac64): expected percussion, got none
- `percussion_fs5f6e6e3a_0` (percussion, aac64): expected percussion, got music at 0.0-6.5 s
- `percussion_fs28744cde_0` (percussion, opus32): expected percussion, got none
- `percussion_fs6bd6e761_0` (percussion, opus32): expected percussion, got music at 0.0-12.0 s
- `percussion_fs1f8eed62_0` (percussion, aac64): expected percussion, got music at 0.0-12.0 s
- `percussion_fsa541818e_0` (percussion, aac64): expected percussion, got none
- `percussion_fs6f0c61b8_0` (percussion, none): expected percussion, got music at 0.0-20.0 s
- `percussion_fs87878ab7_0` (percussion, none): expected percussion, got music at 3.0-20.0 s
- `percussion_fs9aa75005_0` (percussion, opus32): expected percussion, got music at 4.5-20.0 s
- `adhan_fs144431_1` (adhan, none): expected none, got music at 10.5-15.0 s
- `adhan_fs144431_3` (adhan, none): expected none, got music at 8.0-11.0 s
- `adhan_fs144432_0` (adhan, opus32): expected none, got music at 4.5-10.5 s
- `adhan_fs534968_2` (adhan, aac64): expected none, got music at 0.0-5.5 s
- `adhan_fs534968_3` (adhan, aac64): expected none, got music at 3.5-8.0 s
- `adhan_fs255761_0` (adhan, none): expected none, got music at 3.5-7.0 s
- `music_instr_fma149778` (music_instr, aac64): expected music, got none
- `background_test_1` (background, opus32): expected music, got none
- `background_test_3` (background, none): expected music, got none
- `background_test_5` (background, opus32): expected music, got none
- `background_test_6` (background, none): expected music, got none
- `background_test_7` (background, opus32): expected music, got none
- `background_test_8` (background, none): expected music, got none
- `background_test_9` (background, none): expected music, got none
- `background_test_10` (background, none): expected music, got none
- `background_test_12` (background, none): expected music, got none
- `background_test_13` (background, none): expected music, got none
- `background_test_14` (background, aac64): expected music, got none
- `background_test_15` (background, opus32): expected music, got none
- `background_test_16` (background, aac64): expected music, got none
- `background_test_19` (background, none): expected music, got none
- `background_test_21` (background, aac64): expected music, got none
- `background_test_22` (background, none): expected music, got none
- `background_test_23` (background, none): expected music, got none
- `background_test_25` (background, aac64): expected music, got none
- `background_test_26` (background, aac64): expected music, got none
- `background_test_28` (background, none): expected music, got none
- `background_test_29` (background, aac64): expected music, got none
- `background_test_30` (background, aac64): expected music, got none
- `background_test_31` (background, none): expected music, got none
- `background_test_32` (background, aac64): expected music, got none
- `background_test_35` (background, none): expected music, got none
- `background_test_36` (background, opus32): expected music, got none
- `background_test_37` (background, none): expected music, got none
- `background_test_42` (background, none): expected music, got none
- `background_test_44` (background, none): expected music, got none
- `duffnasheed_test_0` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_1` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_2` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_3` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_4` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_5` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_6` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_7` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_8` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_9` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_10` (duff_nasheed, aac64): expected percussion, got music at 2.5-5.5 s
- `duffnasheed_test_11` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_12` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_13` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_14` (duff_nasheed, opus32): expected percussion, got music at 4.0-7.0 s
- `duffnasheed_test_15` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_16` (duff_nasheed, opus32): expected percussion, got music at 2.5-6.5 s
- `duffnasheed_test_17` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_18` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_19` (duff_nasheed, none): expected percussion, got none
- `duffnasheed_test_20` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_21` (duff_nasheed, aac64): expected percussion, got none
- `duffnasheed_test_22` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_23` (duff_nasheed, opus32): expected percussion, got none
- `duffnasheed_test_24` (duff_nasheed, none): expected percussion, got music at 0.0-4.0 s
- `speech_room_fs833bdccf_0` (speech_room, aac64): expected none, got music at 0.0-12.5 s

