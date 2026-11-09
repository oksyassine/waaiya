# Keep the model on the device, host only downloads, and gate women's singing with a small classifier

The engine stays on the user's device, and o2switch hosts only the website, APKs, F-Droid repository and model files. Its contract rules out a server-side separation service, but serving static files is its core business. Lip-sync is already within limits on the paths built so far. The engine adds 40 ms, the Linux PulseAudio daemon measured 59 ms end to end, and the Media3 share-target player removes the delay exactly. Both delays sit well below the 125 ms point where ITU-R BT.1359 says lag becomes detectable. Rootless Android is the open sync question: the notes put its capture floor at 60–85 ms before the model runs, so it is the only path that may approach the 125 ms point. The voice model is the main gap. Baseline DeepFilterNet3 keeps speech but destroys recitation and singing, so a fine-tuned version is training on Kaggle. The optional women's-singing filter should be a small streaming classifier on the vocal stem that drives the engine's gain gate. LFM3-Audio-2B is too heavy to run live and serves only as an offline labeller for that classifier's training data. No published model separates Quran recitation from singing, so that class has to be trained in-house.

## Summary of decisions

| Question | Decision | Basis |
|---|---|---|
| Where inference runs | On the user's device only | Engine RTF 0.25 stereo on one thread (`docs/STATUS.md`); o2switch CGV forbids daemons and processes above 420 consecutive CPU-seconds |
| What o2switch hosts | Website, docs, APK and F-Droid static repo, ONNX model files, optionally a small short-request API | Static serving fits the plan; per-file cap 50 GB, 500,000 inodes |
| Sync target | Under 45–60 ms uncompensated where possible; 125 ms hard ceiling; never audio early | ATSC IS-191, EBU R37, ITU-R BT.1359 |
| Video on Android | Share-target Media3 player as the in-sync path; system-wide capture for everything else | Player drops the engine's priming samples, so Δ = 0 |
| Voice model | Fine-tune DeepFilterNet3 to keep singing and recitation (Kaggle run v3 in flight) | Baseline loses recitation (-13 dB) and singing (-25 dB) |
| Women's-singing filter | Separate streaming classifier, {speech, singing, recitation} × {male, female}, on the vocal stem, gating via `im_engine_set_gate` | No off-the-shelf permissive singing-gender model |
| LFM3-Audio-2B | Offline auto-labeller on Kaggle only, never shipped or run live | 2B parameters (`docs/STATUS.md`) |
| Policy | Mute/keep matrix set by the user, defaulting to fail closed; no rulings hard-coded | Product decision |

## Sync and latency

**Late audio is tolerated far better than early audio, so the targets are asymmetric.** ATSC IS-191 allows audio to lag by up to 45 ms at the encoder input, and EBU R37 allows 60 ms end to end ([Wikipedia: Audio-to-video synchronization](https://en.wikipedia.org/wiki/Audio-to-video_synchronization)). ITU-R BT.1359 puts the detection threshold at 125 ms lag and the acceptability limit at about 185 ms. A second secondary source says 190 ms, and the ITU text was not re-read ([ITU-R BT.1359-1](https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.1359-1-199811-I!!MSW-E.doc); [Forasoft](https://www.forasoft.com/learn/audio-for-video/articles-audio/lip-sync-itu-r-bt-1359-tolerance-windows)). Audio leading the picture is penalised about three times as hard, so any reported compensation must never exceed the true delay. No phone-specific threshold study was found, so the broadcast figures are the design basis.

**What the project has measured.** The engine adds 40 ms: 30 ms of model look-ahead plus 10 ms of hop buffering, matching the DeepFilterNet3 paper's figure ([arXiv 2305.08227](https://ar5iv.labs.arxiv.org/html/2305.08227)). On Linux, `linux/test_run.sh` measured 59 ms from the virtual output to the speakers on the PulseAudio daemon. It does this by cross-correlating the dry and filtered streams. That is about the EBU R37 limit and well under BT.1359 detection. PulseAudio does not pass plugin latency on to players: `module-ladspa-sink` has an explicit TODO for it ([module-ladspa-sink.c](https://gitlab.freedesktop.org/pulseaudio/pulseaudio/-/blob/master/src/modules/module-ladspa-sink.c)). Treat the 59 ms as uncompensated. The Android Media3 player (`PlayerActivity.kt`) drops the engine's first `latency` output frames and flushes the tail at end of stream, so output frame k matches input frame k. Media3 times video against frames actually played, so this gives exact sync on every output route, Bluetooth included ([DefaultAudioSink.java](https://github.com/androidx/media/blob/release/libraries/exoplayer/src/main/java/androidx/media3/exoplayer/audio/DefaultAudioSink.java)).

| Path | Δ (uncompensated audio lag) | Status |
|---|---|---|
| Media3 share-target player | 0 by construction | Built; not yet run on a phone |
| Linux PulseAudio daemon | 59 ms | Measured |
| Linux PipeWire filter-chain with a latency port | ≈ 0 for mpv; Chrome, Firefox and OBS through the Pulse API (partly verified) | Not built |
| Android rootless, capture plus session mute | About 100–130 ms best case with a 40 ms model; 150–300 ms typical | Estimate from the notes' budget; about 500 ms reported for RootlessJamesDSP |
| Android Shizuku LOOP_BACK reroute, speaker or wired | About 65–80 ms | Estimate; Bluetooth gets worse, 200 ms or more |
| macOS AudioServerPlugIn reporting latency | ≈ 0 for Chrome and Firefox | Not built |
| macOS Core Audio tap | 30–60 ms best, uncompensated | Not built |

**Rootless Android cannot be compensated and starts with a 60–85 ms capture floor.** The remote-submix pipe is 4096 frames, and its write throttle holds the mean fill at 11/16 of that: 2816 frames, or 58.7 ms at 48 kHz. The record thread then pulls 1024-frame (21.3 ms) periods ([MonoPipe.cpp](https://android.googlesource.com/platform/frameworks/av/+/refs/heads/main/media/libnbaio/MonoPipe.cpp); [SubmixRoute.h](https://android.googlesource.com/platform/hardware/interfaces/+/refs/heads/main/audio/aidl/default/r_submix/SubmixRoute.h)). These figures come from source constants and have not been measured on a device. No public API lets an app raise another app's reported latency. The muted original keeps its own clock, which already includes Bluetooth delay, because the Bluetooth HAL subtracts the headset's delay report ([stream_apis.cc](https://android.googlesource.com/platform/packages/modules/Bluetooth/+/refs/heads/main/system/audio_bluetooth_hw/stream_apis.cc)). The A2DP delay therefore cancels out of Δ. The source app must be muted, not paused, for that to hold.

**Design rules taken from the notes.**
1. Report the delay wherever the platform has a channel for it, because a reported delay costs video nothing. The channels are a PipeWire latency port, a macOS virtual device's `kAudioDevicePropertyLatency`, a Windows WaveRT presentation position, and a root HAL shim on Android.
2. On rootless Android, read capture in chunks of one hop or less, and drop audio rather than queue it when behind. Open the output as low-latency Oboe or AAudio (about 20 ms round trip with MMAP, about 205 ms in the default mode ([Android Oboe](https://developer.android.com/games/sdk/oboe/low-latency-audio))). Never use a blocking Java `AudioTrack`.
3. With Shizuku, choose the route mode by output. Use LOOP_BACK reroute on speaker or wired, because the source app's clock then compensates the pipe. Use capture plus mute on Bluetooth, so the A2DP delay keeps cancelling.
4. Measure Δ at runtime from capture and output timestamps. Warn the user, or exclude video apps, when Δ exceeds 125 ms.
5. Keep the system-wide model's algorithmic latency at about 32 ms or less. Heavier, higher-latency models suit only the player path, where latency is free.

**Sync and the gender gate.** The singing notes suggest buying classification accuracy with 150–300 ms of look-ahead. On system-wide paths that would push Δ past the detection threshold, so the gate must react causally, failing closed at voice onsets. Look-ahead is affordable only in the Media3 player, where latency costs nothing.

## Hosting on o2switch

**o2switch can host the project's distribution, not its inference.** Since February 2025 the plans are Grow (8 vCPU, 16 GB, 16 MB/s I/O, 7 € HT/month), Cloud (12 vCPU, 48 GB, 42 MB/s) and Pro (24 vCPU, 64 GB, 84 MB/s). All are CloudLinux LVE caps on shared servers, with no GPU on any tier ([o2switch.fr/hebergement-illimite](https://www.o2switch.fr/hebergement-illimite/); [hebergement-entreprise](https://www.o2switch.fr/hebergement-entreprise/)). o2switch publishes no entry-process, process-count or IOPS limits.

**The CGV, not the CPU count, is the binding limit on compute.** It forbids any process using more than 420 consecutive CPU-seconds, more than 2.9 GHz or more than 48 GB of RAM. It also bans "toutes sortes de daemons" and "tout programme binaire autres que ceux mis à disposition par o2switch". It limits the hosting to "héberger des sites internet ou tout service lié" ([o2switch CGV](https://www.o2switch.fr/cgv/)). The only CGV found is dated 26 August 2019 and still titled "Offre Unique". It most likely still governs the new tiers, but that is unconfirmed. Overuse normally earns a warning, but o2switch reserves immediate suspension without notice.

**Server-side inference is not viable as a service.** A 10-minute htdemucs job needs roughly 650–3,600 CPU-seconds in one process, 1.5–9 times the 420-second rule. A light ONNX model at RTF 0.05–0.2 would fit, at 30–120 CPU-seconds. These are the notes' estimates from other hardware; nothing was benchmarked on o2switch. This project's engine runs at RTF 0.25 stereo on one thread of the dev machine, which would be about 150 CPU-seconds for 10 minutes of audio. That is technically under the cap, but a "paste a link, we clean it" endpoint still runs non-provided binaries such as yt-dlp, ffmpeg and ONNX Runtime. It is not "hébergement web conventionnel" either, so it remains a suspension risk whatever the timing. If server-side processing is ever wanted, the notes point to Modal, at $30 a month of free credits and HaramMute's choice ([modal.com/pricing](https://modal.com/pricing)), or an Oracle Always Free ARM box, now 2 OCPU and 12 GB ([Oracle docs](https://docs.oracle.com/en-us/iaas/Content/FreeTier/resourceref.htm)). Colab and Kaggle forbid serving a web backend ([Colab FAQ](https://research.google.com/colaboratory/faq.html)).

**What fits o2switch well.**
- **Website, docs and APK downloads.** Disk and transfer are unlimited. The limits are 50 GB per file, 20,000 files per directory, 500,000 inodes, 10,000 packets per second, and no backups once an account holds more than 100,000 files.
- **F-Droid repository.** Build it with `fdroidserver` locally or in CI, because Java and the Android build tools would hit the binaries clause. Then upload the static `repo/` folder over SSH.
- **Model files.** The current streaming ONNX is about 16 MB, far below any limit. Mirror large release artefacts on GitHub Releases if download traffic grows.
- **Small API.** Settings sync or opt-in telemetry runs through Passenger (Python up to 3.12, Node up to 24) with MySQL, provided requests stay short.

Grow, or Cloud at its first-year promotional price of 22.32 € HT, is enough. The project's condition was "open source if light enough for o2switch". Inference never runs on the server, so model weight does not decide that question.

## Gender and singing detection

**No off-the-shelf model can gate singing by gender under a licence the app can ship.** Speech gender classifiers score 92–99% on speech, but none reports singing accuracy:

| Model | Licence | Accuracy reported | Use for this app |
|---|---|---|---|
| JaesungHuh ECAPA-TDNN | MIT | 98.7% VoxCeleb1 ([GitHub](https://github.com/JaesungHuh/voice-gender-classifier)) | Candidate backbone; needs singing fine-tune |
| griko ECAPA + SVM | Not stated in notes | 92.3% cross-corpus on Common Voice ([HF](https://huggingface.co/griko/gender_cls_svm_ecapa_voxceleb)) | Realistic speech figure |
| inaSpeechSegmenter | MIT | None in README | Tags singing as "music", so it cannot gate singing ([GitHub](https://github.com/ina-foss/inaSpeechSegmenter)) |
| audeering wav2vec2 (6- and 24-layer) | CC BY-NC-SA 4.0 | ≥ 91.1% including a child class ([arXiv 2306.16962](https://arxiv.org/abs/2306.16962)) | Not shippable; 90.8M parameters is heavy |
| Essentia singing-voice gender | CC BY-NC-SA 4.0 | Not found | The only singing-specific models; not shippable ([Essentia](https://essentia.upf.edu/models.html)) |
| YAMNet | Not stated in notes | n/a | Gendered classes removed; keeps Singing, Choir and Chant as cues ([YAMNet README](https://github.com/tensorflow/models/blob/master/research/audioset/yamnet/README.md)) |

**Pitch alone misclassifies male singers.** Tenor reaches about 494–523 Hz and alto descends to about 196 Hz, so the ranges overlap across most melody lines ([Henrich et al., JASA 2011](https://hal.archives-ouvertes.fr/hal-00569451/file/Henrich_JASA_2011.pdf); [DPA](https://www.dpamicrophones.com/dict/singing-voices-and-frequencies/)). A speech-style threshold would mute tenors, falsetto and high nasheed voices. In STraDa, an F0-histogram baseline was among the weakest, and a fine-tuned x-vector on separated vocals led at 89.8% ([arXiv 2406.04140](https://arxiv.org/html/2406.04140v1)). Accuracy on diverse in-the-wild singing falls to 70% or below in older studies, so expect high-80s per clip at best, and lower on short windows.

**Short windows are the core difficulty.** Speech-versus-singing accuracy was 68.1% at 200 ms against 87.3% at 2 s ([Ohishi et al.](https://www.isca-archive.org/interspeech_2005/ohishi05_interspeech.html)); the 200 ms figure came from a search snippet. No sub-second singing-gender figure exists. The notes therefore propose two tiers:
1. A fast tier every 50–100 ms gives p(female) and p(singing).
2. A 1.5–3 s rolling tier confirms or overturns it, caching the decision per voice segment.

Mute when p(female and singing) exceeds T_on, and unmute only after p stays below a lower T_off for 0.5–1 s. Ramp the gain over 10–30 ms. The engine's `im_engine_set_gate` already smooths over about 5 ms. These are engineering proposals; no study measures leakage against window length.

**Recitation versus singing has no published model or dataset.** Existing Quran audio ML covers maqam (up to 96.55%), reciter identity (99.66%) and tajweed rules ([Samara et al.](https://doaj.org/article/2d7ca9486a8b4962aaa1abe84302d97c); [arXiv 2503.23470](https://arxiv.org/html/2503.23470v3)). Mujawwad recitation is melismatic and wide-ranging, which makes it acoustically close to singing ([Wikipedia: Mujawwad](https://en.wikipedia.org/wiki/Mujawwad)). Recitation must therefore be its own class, trained on in-house data. The policy matrix should cover {female, male, uncertain} × {speech, singing, recitation, uncertain} → {mute, keep}. The user sets it, so a female lecturer or reciter is kept unless the user chooses otherwise. Nasheed is singing acoustically, so whether female nasheed is muted is a policy setting, not a classifier output.

**Mixed voices: mute the whole stem.** Multi-singer separation exists in research (MedleyVox, karaoke duet splitting), but none runs live on a phone, and unison or close harmony remains hard ([arXiv 2211.07302](https://arxiv.org/pdf/2211.07302); [UNMIXX review](https://www.themoonlight.io/review/unmixx-untangling-highly-correlated-singing-voices-mixtures)). Train the detector on synthetic male-plus-female and choir mixtures, so it flags "female present" even under a male lead. Mute the whole vocal stem when it fires.

**Training data and labelling.** The approved plan takes labels from three sources:
- LibriSpeech `SPEAKERS.TXT` speaker sex (CC BY 4.0)
- VocalSet singer IDs (CC BY 4.0). The notes record a conflicting gender split, 9M/11F on Zenodo against 11M/9F in the paper, so check the IDs before use ([Zenodo](https://zenodo.org/records/1193957)).
- A female Quran reciter from the Diverse Quran Reciters set, whose recording rights belong to the reciter

NHSS adds the same ten singers both speaking and singing ([arXiv 2012.00337](https://arxiv.org/pdf/2012.00337)). OpenSinger and GTSinger are non-commercial. **LFM3-Audio-2B** may auto-label unlabelled audio on Kaggle to widen coverage. At 2B parameters it is far outside a live budget, since the gate needs a decision every 50–100 ms on a phone CPU. Its labels must be spot-checked against the hand-labelled sources. The research notes do not cover its licence or the terms on its outputs. Train on stems produced by the app's own separator, as STraDa did with Spleeter output, so that separation artefacts are in the training data. Evaluate frame by frame: report leaked female-singing seconds per hour, false-mute seconds per hour for each kept class, and onset-to-mute latency at the median and 95th percentile.

## Women's-singing detector — implementation status

Built on 2026-11-09; the first trained model is on Kaggle (`KAGGLE_USER/islamic-mute-detector-train`).

**Design.** The detector is EfficientAT `mn04`, a MobileNetV3 audio tagger pretrained on AudioSet. It is MIT-licensed, has about 1M parameters, and its ONNX file is about 2.6 MB. It gets a new head with two outputs:
- P(a woman's voice is present);
- P(speech / singing / recitation).

It runs on the **separated voice**, not on the original mix, every 250 ms over the last 1 s of audio. With the user's policy on, the engine mutes while P(female) × P(singing) is at or above the threshold. The mute holds for 2 s after the last detection and fades in about 5 ms. A woman's speech and a woman's recitation are kept. The policy is fail-closed: if the detector is missing or fails, voice is muted while the option is on.

**Pretrained network re-implemented.** We wrote our own copy of the network and load only the published weights tensors (`weights_only=True`). No third-party Python runs and no pickled code is loaded.

**Engine integration.** The engine (`engine/src/im_detector.c`) computes the front end in C from the voice it already produces: pre-emphasis, a 1536-point FFT, and one power frame per 10 ms engine hop. So nothing is resampled. Only the classifier runs in ONNX Runtime.
- Parity with the PyTorch training code: power spectra agree to a relative error of 1e-7, and the probabilities agree to 1e-5.
- Cost: real-time factor 0.103 → 0.122 for stereo on one desktop core, about 2% extra CPU.
- The voice path delay is unchanged (40 ms). The detector's own decision lag means roughly the first 0.25–0.5 s of a woman's singing can be heard before the mute.

**Zero-shot baseline, before fine-tuning.** Measured on 1 s windows of OpenSinger (Chinese singing) and FLEURS (Arabic and English speech), using the AudioSet "Female singing" output:
- Women's vs men's singing: AUC 0.89 (0.91 on 2 s windows).
- Women's singing vs speech: AUC 0.99.
- Calibration is poor. Catching 88% of women's singing also mutes 17% of men's singing windows. The 1.0-width model (`mn10`) gave unusable outputs with our loader, so `mn04` was kept.

**Training data (all CC BY 4.0, except Quran recitations, whose rights belong to the reciters):**

| Source | Content | Split |
|---|---|---|
| LibriSpeech | English speech, sexes from SPEAKERS.TXT | trained on |
| FLEURS ar_eg | Arabic speech, 1686 female / 418 male utterances | trained on |
| VocalSet 1.1 | singing and spoken, 20 singers | one male and one female singer held out |
| Diverse Quran Reciters | recitation, including Ayu Rumiyati as the female reciter | trained on |
| Slakh | instrument residue mixed in at 10–35 dB below the voice, simulating imperfect separation | augmentation |

- Other augmentations: duets and backing voices, low-pass filtering, reverb, level changes.
- OpenSinger (CC BY-NC) is used **only** as an unseen-singer, unseen-language test, never for training.

**Threshold.** It is set on the held-out singers so that 95% of 1 s women's-singing windows are caught. The evaluation reports the false-mute rate per group (men's singing, speech, recitation) at that threshold, plus how the same threshold carries over to OpenSinger.

**Known limits:**
- **Onset leak.** The first 0.25–0.5 s of a woman's singing can pass. The alternative is adding up to 1 s of delay, which would break A/V sync.
- **Tenors and falsetto.** Men singing high may be muted by mistake.
- **Children's voices** are likely scored as female.
- **Female recitation in the mujawwad style** is the hardest case to keep. The training data has only one female reciter.

## Model options

**The project's own baseline shows why fine-tuning is needed.** On the 65-item test set (`eval/results/summary.md`), DeepFilterNet3 measured:

| Group | Instrument suppression | Voice retention | SI-SDR gain |
|---|---|---|---|
| Arabic speech | 21.3 dB | -2.7 dB | +7.1 dB |
| English speech | 24.0 dB | -2.6 dB | +5.5 dB |
| Recitation | 28.6 dB | -13.2 dB | -6.6 dB |
| Singing | 30.0 dB | -24.8 dB | -12.6 dB |

Music-only input leaks at -36.1 dB. It runs at RTF 0.25 stereo on one thread, and 0.125 for the mono variant, with near-identical scores. It keeps speech, but its high suppression on recitation and singing comes from deleting the voice along with the music. That confirms the notes' warning that a speech-enhancement objective treats singing as noise ([Microsoft DNS](https://www.microsoft.com/en-us/research/academic-program/deep-noise-suppression-challenge-icassp-2023)).

**The chosen path is the notes' low-risk option.** Fine-tune DeepFilterNet3, whose code and weights are MIT/Apache, so that its "clean" target includes singing and recitation and its "noise" is instruments. The architecture keeps the 40 ms latency, its streaming state and its ONNX export. The Kaggle run v3 trains on LibriSpeech, the Arabic Speech Corpus, VocalSet and Slakh2100, all CC BY 4.0, plus Diverse Quran Reciters. Acceptance requires three things: recitation and singing retention of about -3 dB or better, suppression above 20 dB, and music-only leak below -30 dB.

**Causal vocals models with public weights still barely exist (status 9 Nov 2026).**

| Option | Latency | Weights and licence | Verdict |
|---|---|---|---|
| DeepFilterNet3 fine-tune (in training) | 40 ms | MIT/Apache base; own training data CC BY 4.0 except reciter rights | Current path |
| ADI causal U-Net recipe, 131K parameters ([arXiv 2609.12201](https://arxiv.org/html/2609.12201v1)) | 0–23 ms | No weights; trains on one T4 | Next candidate if the fine-tune falls short; streaming state must be part of training |
| Causal Open-Unmix `umx-live` ([HF](https://huggingface.co/shuoyang-zheng/Open-Unmix-Unidirectional)) | About 93 ms (inferred) | Tagged MIT but MUSDB18-trained (NC); ExecuTorch `.pte` only, about 260 MB | Over the latency budget; ask the author for `.pth` |
| Spleeter 2-stem, chunked ([GitHub](https://github.com/deezer/spleeter)) | About 0.5–1 s (estimate) | MIT, verified | Player path only |
| Streamed HT-Demucs or SCNet ([arXiv 2609.35397](https://arxiv.org/pdf/2609.35397)) | 23–93 ms | MIT code | GPU RTF 0.89–1.59; teacher or reference only |
| se2svs BSRNN ([GitHub](https://github.com/pablebe/se2svs)) | Causality unverified | Apache-2.0 checkpoints | Evidence that fine-tuning from speech enhancement adds 0.2–1.8 dB over training from scratch |
| Band-SCNet, HS-TasNet, RT-STT, LiteCASS | 23–92 ms | No weights | Not usable |

The notes add one finding on teacher latency: streamed offline models lose less than 1 dB at one window of look-ahead (93 ms) and drop steeply below it. A 23 ms streamed HT-Demucs reaches 6.90 dB vocals SDR, against 8.91 dB offline.

**Model shrink is the next engineering step.** fp16 and int8 versions are to be re-scored on the same test set (`docs/STATUS.md`). No phone-CPU RTF exists for any of these models, so the first Android run must measure it.

## Open risks

| Risk | Why it matters | Response |
|---|---|---|
| Fine-tune misses the acceptance bar | Without it, recitation and singing are lost, which breaks the "singing is voice" decision | Fall back to the ADI-style causal model or a larger backbone; keep the bar fixed |
| Rootless Android Δ above 125 ms | Capture floor of 60–85 ms is from source constants; the field report is about 500 ms | First phone test measures Δ; default video to the Media3 player; exclude video apps when over |
| PulseAudio 59 ms is uncompensated | Players cannot see it; fine for now, but adds up with Bluetooth or slower machines | Move to a PipeWire filter-chain with a latency port |
| o2switch terms | 2019 CGV may apply to the new tiers; overuse can bring suspension without notice | Keep o2switch to static files and short requests; confirm in writing with support before adding any compute |
| Gender gate false mutes | Tenors, falsetto, children and auto-tuned voices score as female; short windows are about 68% accurate | User-chosen strictness (strict, balanced, lenient), an explicit "uncertain" class, and a test set that covers these cases |
| Female-singing leaks at onsets | A causal gate needs time to decide; look-ahead would break sync | Fail closed at voice onsets in strict mode; use look-ahead only in the player |
| Recitation misread as singing | No published classifier or dataset; mujawwad is close to singing | In-house labelled set of male and female murattal, mujawwad and adhan; separate class |
| Label quality from LFM3-Audio-2B | Auto-labels can be wrong, and its licence and output terms were not researched | Spot-check against LibriSpeech and VocalSet ground truth; record provenance |
| Reciter audio rights | Quran recitation datasets leave recording rights with the reciters (EveryAyah, QUD) | Keep a provenance record; seek permission for reciter audio used in released weights |
| Non-commercial models creeping in | audeering and Essentia weights, MUSDB18, MoisesDB and OpenSinger are NC or share-alike | Train heads only on permissive data; do not distil from NC models without legal advice |
| No phone performance data | No phone RTF or battery figures exist for the voice model or the detector | Measure both on the first Android run before choosing int8 or fp16 |
