# Real-time Singing / Speech / Recitation and Voice-Gender Detection on Device (as of Nov 2026)

Scope: detecting on a phone or desktop CPU, from a separated vocal stem (or the mix), (a) whether the voice is singing, speech or Quran-style recitation, and (b) whether it is a female or male voice, so a male user can optionally mute women's singing. Reaction within 100–300 ms, with an option to fail closed. Technical options only, no religious rulings. Research done with ~27 search and fetch calls on 2026-11-09. Several model cards give no latency or parameter figures, and these are noted as gaps.

## 1. Voice-gender classification: lightweight models, features, accuracy (speech vs singing), licences

### Takeaway
Off-the-shelf speech gender classifiers reach about 92–99% accuracy on speech in their authors' tests, and two are permissively licensed (JaesungHuh ECAPA, MIT; inaSpeechSegmenter, MIT). None reports accuracy on singing, and inaSpeechSegmenter labels singing as "music", so it cannot gate singing on its own. The most accurate published model (audeering wav2vec2) is non-commercial (CC BY-NC-SA 4.0), and so are the singing-specific Essentia "voice gender" models. For an open-source, free app, the practical route is to fine-tune a small permissive backbone (ECAPA or a small CNN on log-mel, plus F0 features) on singing data such as VocalSet (CC BY 4.0).

### Cited Findings
**audeering wav2vec2 age-gender**
- The 24-layer model `audeering/wav2vec2-large-robust-24-ft-age-gender` is licensed **cc-by-nc-sa-4.0** (non-commercial, share-alike), has about 318M parameters, and was trained on aGender, Mozilla Common Voice, TIMIT and VoxCeleb2. — [HF model card (24-layer)](https://huggingface.co/audeering/wav2vec2-large-robust-24-ft-age-gender)
- The 6-layer variant `wav2vec2-large-robust-6-ft-age-gender` is also **cc-by-nc-sa-4.0** and has about 90.8M parameters ("we only trained the first six transformer layers"). It takes raw 16 kHz audio and outputs age plus child/female/male probabilities. An ONNX export is on Zenodo. The card gives no latency figure. — [HF model card (6-layer)](https://huggingface.co/audeering/wav2vec2-large-robust-6-ft-age-gender); [Zenodo ONNX](https://zenodo.org/record/7761387)
- Paper (arXiv 2306.16962): "at least 91.1% ACC for gender (female, male, child)" and +4% UAR over a handcrafted-feature baseline. It reports no singing evaluation. — [arXiv 2306.16962](https://arxiv.org/abs/2306.16962)
- audeering's demo Space is cc-by-nc-4.0, a different licence from the checkpoints. — [audeering speech-analysis Space](https://huggingface.co/spaces/audeering/speech-analysis/blob/main/app.py)

**ECAPA-TDNN based gender classifiers (SpeechBrain/VoxCeleb family)**
- JaesungHuh `voice-gender-classifier`: **MIT** licence. A pretrained ECAPA-TDNN (from TaoRuijie's implementation) plus one linear layer, fine-tuned on the VoxCeleb2 dev set. It reports 98.7% accuracy on the VoxCeleb1 identification test split. The author warns VoxCeleb "may not represent the global human population". Parameter count and input length are not stated. — [GitHub](https://github.com/JaesungHuh/voice-gender-classifier); [HF](https://huggingface.co/JaesungHuh/voice-gender-classifier)
- griko `gender_cls_svm_ecapa_voxceleb`: a SpeechBrain ECAPA-TDNN embedding fed to an SVM. It reports 98.9% on VoxCeleb2 test, **92.3% on Common Voice v10 English** and 99.6% on TIMIT. The cross-corpus Common Voice figure is the more realistic estimate. — [HF model card](https://huggingface.co/griko/gender_cls_svm_ecapa_voxceleb)
- moorlee `gender-voice-classifier-ecapa` uses a frozen `speechbrain/spkrec-ecapa-voxceleb` encoder with light heads. No accuracy figure was found in the retrieved text. — [HF](https://huggingface.co/moorlee/gender-voice-classifier-ecapa)

**inaSpeechSegmenter**
- **MIT** licence. A CNN segmenter (TensorFlow, Python 3.8–3.13) that tags speech as male or female. Its gender models are "optimized for French language". **"Singing voice is tagged as music."** It won the MIREX 2018 speech-detection challenge. The README gives no gender accuracy, window size or real-time factor. — [GitHub ina-foss/inaSpeechSegmenter](https://github.com/ina-foss/inaSpeechSegmenter)

**Essentia (MTG) singing-voice gender models, the only off-the-shelf models found that target *singing* gender**
- Essentia lists a "Voice gender" classifier: "Classification of music by singing voice gender (2 classes)": female and male. Variants run on VGGish, YAMNet, Discogs-EffNet, MSD-MusiCNN and OpenL3 embeddings, with 16 kHz input. The page gives no dataset size, accuracy or patch length in the parts read. — [Essentia models](https://essentia.upf.edu/models.html)
- Licence: "All the models created by the MTG are licensed under **CC BY-NC-SA 4.0**", with a proprietary licence available on request. — [Essentia models](https://essentia.upf.edu/models.html)
- Essentia also hosts FSD-SINet (200 FSD50K classes), which includes "Female singing", "Male singing", "Female speech, woman speaking" and "Male speech, man speaking". — [Essentia models](https://essentia.upf.edu/models.html)

**AudioSet taggers (YAMNet / PANNs)**
- YAMNet dropped the gendered classes. The 527-class AudioSet release was trimmed to 521 classes, removing Male/Female Speech and Singing on fairness reviewers' advice. It keeps "Speech" (0), "Singing" (24), "Choir" (25), "Chant" (27), "Mantra" (28), "Child singing" (29) and "Synthetic singing" (30). — [TF models YAMNet README](https://github.com/tensorflow/models/blob/master/research/audioset/yamnet/README.md); [class map CSV](https://huggingface.co/spaces/hprasath/image-processing/commit/3e697f796e336a487ecf32c6246fc5e788e003d8)
- PANNs code is **MIT**. The README states no licence for the pretrained checkpoints. Models: Cnn14 (mAP 0.431), Cnn14_16k (0.438), and Cnn14_DecisionLevelMax (0.385, framewise sound-event detection). — [GitHub audioset_tagging_cnn](https://github.com/qiuqiangkong/audioset_tagging_cnn)
- CNN14 has 80.8M parameters and about 42.2 G multiply-adds per clip. The MobileNet PANNs use about 6.7% of the FLOPs and 5% of the parameters of CNN14, with mAP of about 0.38. — [PANNs paper arXiv 1912.10211](https://arxiv.org/pdf/1912.10211.pdf); [IEEE SPS summary](https://signalprocessingsociety.org/newsletter/2024/05/panns-large-scale-pretrained-audio-neural-networks-audio-pattern-recognition)

**F0 / pitch overlap in singing (why pitch alone fails)**
- Nominal soprano is about C4–C6 (261–1046 Hz). Alto (G3–G5) overlaps the soprano range considerably. — [Henrich et al., JASA 2011](https://hal.archives-ouvertes.fr/hal-00569451/file/Henrich_JASA_2011.pdf)
- Tenor is C3–C5 (131–523 Hz) per Titze, or B2–G4 per the New Harvard Dictionary of Music. — [IJRCS choral table](https://acda-publications.s3.us-east-2.amazonaws.com/IJRCS/volumefour/ijrcs4_1_herbstetal.pdf). DPA lists tenor 131–494 Hz, alto 196–659 Hz and bass 73–330 Hz. — [DPA Microphones](https://www.dpamicrophones.com/dict/singing-voices-and-frequencies/)
- In STraDa, an F0-histogram (CREPE) + kNN baseline (B1) was among the weaker baselines. The best system was a fine-tuned x-vector, i.e. a speaker embedding (89.8%). — [STraDa arXiv 2406.04140](https://arxiv.org/html/2406.04140v1)

### Inferences
- The tenor (up to ~494–523 Hz) and alto (down to ~196 Hz) ranges overlap across roughly 196–520 Hz, which covers most pop melody lines. A pitch threshold such as "F0 > 165 Hz = female", which works for speech, will therefore misclassify male tenors, falsetto and nasheed-style high male singing as female. Timbre and formant features (MFCC, speaker embeddings) are needed, and F0 is useful only as an extra feature.
- Speaker-embedding models (ECAPA, x-vector) transfer best to singing per STraDa, but they still need singing data during fine-tuning. Speech-only checkpoints should be treated as unvalidated on singing.
- Licence summary for a free, open-source app:
  - Usable: JaesungHuh ECAPA (MIT), inaSpeechSegmenter (MIT, but useless for singing), PANNs code (MIT; weight licence unclear).
  - Problematic: audeering (NC-SA) and all Essentia MTG models (NC-SA, free use only if the app and its distribution are strictly non-commercial, and share-alike obligations apply to derived models).
  - Training your own head on VocalSet (CC BY 4.0) is the cleanest path.
- Compute order of magnitude: ECAPA-TDNN is in the low millions of parameters (not confirmed from the cards read). It and a MobileNet-class CNN are feasible every 100–250 ms on phone CPUs. The 90M-parameter 6-layer wav2vec2 is heavy for continuous mobile use.
- Children's voices: only audeering models a "child" class explicitly. Child singers (both sexes) will likely be scored as female by binary models, so the app needs a stated policy for this case.

### Gaps
- No published accuracy for any of these speech gender models on *singing* (VocalSet, OpenSinger, STraDa) was found.
- Essentia voice-gender model accuracy and training-set size were not in the portion of the page read. They may be in each model's JSON metadata.
- Parameter counts and measured CPU latency for the ECAPA gender models, and the PANNs weight licence, were not confirmed.
- SpeechBrain's own licence (Apache-2.0 is widely known) and any official SpeechBrain gender recipe were not verified in this session.
- Pyannote has no gender model (not verified here). No source on Whisper-encoder gender probes was found.
- Auto-tune and vocoder effects, and their effect on gender classifiers, are not covered by any source found.

## 2. Singing-voice gender datasets and papers

### Takeaway
Singer-gender classification on commercial music reaches about 87–92% in older or narrow studies, but accuracy falls sharply (to ~70% or lower) on diverse data. The best recent large-scale result is 89.8% (STraDa, x-vector with source-separation augmentation). Usable permissive training data exists (VocalSet CC BY 4.0, NHSS with paired speech and singing). No Arabic singing, nasheed or children's-singing gender dataset was found.

### Cited Findings
- **STraDa (2024):** automatic-strada has 25,194 30-second excerpts (169 h) from 5,264 lead singers (3,426 male, 1,827 female, 11 non-binary). annotated-strada has 200 tracks by 200 singers in 5 languages and 4 age groups, as 1,200 3-second segments. Audio is mostly copyrighted, so only YouTube links and Deezer IDs are shared. — [arXiv 2406.04140](https://arxiv.org/html/2406.04140v1)
  - Baselines: B1 is F0 histograms (CREPE) + kNN; B2 is 13 MFCCs on **Spleeter-separated vocals** + MLP; B3 is a spectrogram CNN. The best model is a fine-tuned x-vector with separated-vocal augmentation (X2), at **89.8%** average accuracy. — [STraDa](https://arxiv.org/html/2406.04140v1)
  - Prior work cited by STraDa: Weninger et al. 89.6% (beat-level BLSTM, pop); Shi 91% (internal); Jitendra and Radhika 89.16% (250 Indian clips) and 94.25% (Artist20 subset). Accuracy "reduces to 70% and below 50%" as diversity grows (refs [9], [5]). — [STraDa](https://arxiv.org/html/2406.04140v1)
- **ISMIR 2010** (Schuller/Weninger et al.), "Vocalist Gender Recognition in Recorded Popular Music": 87.31% song-level accuracy for unseen artists. — [ISMIR 2010 PDF](https://archives.ismir.net/ismir2010/paper/000105.pdf)
- Weninger et al. (singer traits): BLSTM on pop tracks gives gender 89.6%, height 72.1%, race 63.3% and age 57.6% unweighted accuracy at beat level. — [ResearchGate](https://www.researchgate.net/publication/224929629_Automatic_Assessment_of_Singer_Traits_in_Popular_Music_Gender_Age_Height_and_Race)
- CNN on spectrograms (IJACSA 2021): 91.70% averaged over Indian and Western clips, about 3% above hand-crafted features. — [IJACSA](https://thesai.org/Publications/ViewPaper?Volume=12&Issue=2&Code=IJACSA&SerialNo=18)
- **VocalSet:** 10.1 h of monophonic professional singing by 20 singers, covering standard and extended techniques (vibrato, straight tone, breathy, vocal fry, falsetto and others) on 5 vowels. CC BY 4.0 per the ISMIR 2018 paper. The gender split is reported inconsistently (9M/11F on Zenodo v1.x vs 11M/9F in the ISMIR paper). — [Zenodo](https://zenodo.org/records/1193957); [ISMIR 2018 paper](https://ismir2018.ismir.net/doc/pdfs/114_Paper.pdf)
- **NHSS (NUS-HLT Speak-Sing):** 100 songs both sung *and spoken* by 10 singers (5 male, 5 female), 7 h in total. Speech Communication 2021. — [arXiv 2012.00337](https://arxiv.org/pdf/2012.00337)
- **OpenSinger:** described as the first open-source Chinese singing dataset (Multi-Singer paper). Data is organized in gender-named folders (e.g. "Female1"), and a male-only HF subset `CodecSR/opensinger_male` has about 40.8k rows. Hours and licence were not confirmed in this session. — [arXiv 2112.10358](https://arxiv.org/pdf/2112.10358.pdf); [Amphion preprocessor](https://huggingface.co/spaces/amphion/maskgct/blob/main/preprocessors/opensinger.py); [HF opensinger_male](https://huggingface.co/datasets/CodecSR/opensinger_male/viewer)
- A singing-dataset survey with hours, singer and licence columns (including NC/ND flags) exists at arXiv 2401.17619. The OpenSinger row was not visible in the snippet. — [arXiv 2401.17619](https://arxiv.org/pdf/2401.17619)
- SingNet (2025) is a large in-the-wild singing dataset. Its gender labels and licence were not checked. — [arXiv 2505.09325](https://arxiv.org/pdf/2505.09325)

### Inferences
- The realistic accuracy target for singing-gender on diverse, in-the-wild music is high-80s to ~90% per clip (3–30 s). Expect lower accuracy on 100–300 ms windows. Fail-closed thresholds will therefore cause noticeable false mutes of male singers, especially tenors, falsetto, children and auto-tuned voices.
- Training on Spleeter or Demucs-separated vocals (as STraDa did) matches the app's runtime input, since the app also classifies a separated stem. Separation artifacts should be included in training.
- An Arabic, nasheed and Quran-recitation test set with gender labels will have to be built in-house. Labelling YouTube timestamps (STraDa style) avoids redistributing copyrighted audio.

### Gaps
- No Arabic singing, nasheed, adhan or children's-singing gender dataset was found.
- M4Singer, NUS-48E, Opencpop and MIR-1K licences and gender splits were not verified this session. Note that Opencpop is reportedly a single female singer, so it is of little use for gender classification (not verified).
- The STraDa dataset licence itself is not stated (the CC BY 4.0 label seen applies to the arXiv paper).

## 3. Singing vs speech vs Quran recitation

### Takeaway
Speech-vs-singing can be separated from F0-contour stability plus spectral-envelope features, but short windows hurt badly: about 68% at 200 ms vs about 87–90% at 2 s in the classic Ohishi studies. Generic taggers (YAMNet "Singing", "Speech", "Chant", "Choir"; Essentia voice/instrumental) give coarse cues. **No published classifier or dataset separating Quran recitation from singing or nasheed was found.** Existing Quran audio ML covers maqam, tajweed-rule and reciter identification. Because melodic (mujawwad) recitation is acoustically close to singing (melismatic, wide range), recitation-vs-singing is the hardest and least-supported part. It needs custom data and should be a separate, user-configurable class.

### Cited Findings
- **Ohishi et al., Interspeech 2005:** an F0-contour measure gives >80% accuracy on 2 s signals, and adding a spectral-envelope measure gives >90% on 2 s. — [ISCA archive](https://www.isca-archive.org/interspeech_2005/ohishi05_interspeech.html)
- **Ohishi et al. (JASA 2006, via search summary):** a combined MFCC + F0 method gives **68.1% at 200 ms** and **87.3% at 2 s**. This came from a search snippet, not the full paper. — [ISCA Interspeech 2005 PDF](https://www.isca-archive.org/interspeech_2005/ohishi05_interspeech.pdf)
- **Schuller et al., ICME 2005:** discriminates speech, monophonic singing and polyphonic music with a "real-time capable implementation". It selects from 276 features with SVM-SFFS (zero-crossing rate and spectral flux rank highly). — [ICME 2005 abstract](https://cecs.uci.edu/~papers/icme05/defevent/html/abstract/a1486.htm)
- Kim et al. (AES 2015): speech vs singing vs instrumental using an ensemble on perceptual features at several temporal resolutions. — [AES e-lib 18013](https://www.aes.org/e-lib/browse.cfm?elib=18013)
- Earlier speech/song features: harmonic ripple, harmonic segment duration, and F0 above 300 Hz. Pitch continuity is proposed as a cue. — [JCAA](https://jcaa.caa-aca.ca/index.php/jcaa/article/download/1500/1244)
- MIT Lincoln Lab, "Discrimination between singing and speech in real-world audio" (no figures retrieved). — [MIT LL](https://www.ll.mit.edu/r-d/publications/discrimination-between-singing-and-speech-real-world-audio)
- Lehner et al. (ISMIR 2013): lightweight real-time singing-voice detection, but vocals vs no vocals rather than speech vs singing. — [ISMIR 2013](https://archives.ismir.net/ismir2013/paper/000089.pdf)
- SSL embeddings on singing: voice2mode (arXiv 2602.13928, Feb 2026) uses frozen HuBERT and wav2vec2 embeddings for singing phonation-mode classification. Early HuBERT layers with an SVM reach ~95.7%, and lower layers beat top ASR-oriented layers. This is evidence that SSL features capture singing-specific voice quality, though not a speech/singing classifier. — [arXiv 2602.13928](https://arxiv.org/abs/2602.13928)
- YAMNet classes usable as cues: Speech (0), Singing (24), Choir (25), Chant (27), Mantra (28), Child singing (29), Synthetic singing (30). — [YAMNet README](https://github.com/tensorflow/models/blob/master/research/audioset/yamnet/README.md); [class map](https://huggingface.co/spaces/hprasath/image-processing/commit/3e697f796e336a487ecf32c6246fc5e788e003d8)
- Essentia voice/instrumental classifier (VGGish/YAMNet/EffNet/MusiCNN/OpenL3) detects presence of voice in music only, under CC BY-NC-SA 4.0. — [Essentia models](https://essentia.upf.edu/models.html)
- inaSpeechSegmenter tags singing as "music" and speech-over-music as "speech". Its music-vs-speech decision is effectively a free (MIT) speech-vs-singing cue on an isolated vocal stem, though it was not designed or validated for that. — [inaSpeechSegmenter](https://github.com/ina-foss/inaSpeechSegmenter)
- **Quran recitation styles:** *Murattal* is slow, measured and mostly syllabic. *Mujawwad* is melodic, with a range that can exceed an octave and extensive melisma. — [Wikipedia: Mujawwad](https://en.wikipedia.org/wiki/Mujawwad)
- **Quran audio ML that exists (none for recitation vs singing):**
  - Maqam-478 dataset, 8 maqamat, best 95.7% (5-layer ANN). — [Shahriar & Tariq, IEEE Access 2021](https://doaj.org/article/757fc24a63944092a3a44394a4679be9)
  - Rababaah 2022: 8 maqams, 96.55%. — [AUK](https://dspace.auk.edu.kw/items/07358bde-5d38-4192-ad10-665077654b04)
  - Reciter identification, 7 reciters, MFCC + CNN, 99.66%. — [Samara et al. 2023](https://doaj.org/article/2d7ca9486a8b4962aaa1abe84302d97c)
  - QDAT tajweed-rule classification (~1,505 recordings), EfficientNet-B0 + SE. The paper notes that many Quran-audio studies use private datasets. — [arXiv 2503.23470](https://arxiv.org/html/2503.23470v3)
- A recent review describes automated tajweed-compliant recitation evaluation as still unresolved. — [arXiv 2510.12858](https://arxiv.org/pdf/2510.12858v1)

### Inferences
- **Speech vs singing in ≤300 ms is unreliable** from acoustics alone (68% at 200 ms in Ohishi). In practice, use a short-window detector for onset plus a longer context (1–3 s rolling) for the stable decision, and decide fail-closed vs fail-open behaviour during the uncertain first ~1–2 s (see section 5).
- Cues that should separate classes (to validate on in-house data):
  - Speech: short voiced segments, frequent unvoiced gaps, gliding F0 with little steady-pitch hold.
  - Singing: long sustained vowels, quantized and steady pitch, vibrato at ~5–7 Hz (standard vocal-science figure, not sourced here), metrical regularity, often with accompaniment before separation.
  - Murattal: speech-like rhythm with sustained elongations (madd) at fairly stable pitch.
  - Mujawwad and adhan: long melismas and wide range, the closest to singing.
- Recitation vs singing therefore likely depends on cues beyond pitch statistics: Arabic Quranic phonetics and tajweed patterns (ghunnah nasalization, madd lengths), absence of metrical beat, characteristic maqam-based melisma without lyric meter, and often the reverberant mosque or studio context. Options:
  1. Fine-tune a small classifier (YAMNet/PANNs-MobileNet/ECAPA embeddings + head) with an explicit "recitation/adhan" class, trained on public recitation audio (e.g. QDAT, reciter corpora, everyayah-style murattal) against nasheed and Arabic singing.
  2. A text-side check (on-device Arabic ASR matching Quran text), which is more robust but much heavier and slower. This is an inference only and was not researched.
- A female lecturer or female reciter is protected if the policy mutes only "female AND singing" and treats "speech" and "recitation" as keep. The configurable policy matrix should expose (gender ∈ {F, M, uncertain}) × (mode ∈ {speech, singing, recitation, uncertain}) → {mute, keep}, with defaults set by the user and not hard-coded.
- Nasheed (unaccompanied vocal music) is classed as singing acoustically, so the app's policy (not the classifier) decides whether female nasheed is muted.

### Gaps
- **No paper, dataset or model found for Quran recitation vs singing/nasheed classification**, nor for adhan detection. This is a true research gap.
- No publicly reported accuracy for YAMNet or PANNs "Singing" vs "Speech" on isolated vocal stems was found.
- No CLAP or BEATs zero-shot speech/singing/recitation results were found. Licences for LAION-CLAP and BEATs were not checked.
- Accuracy figures for Sarasola et al. 2019 (pitch-based speech vs a-cappella singing) were not retrieved. — [Applied Sciences 2019](https://doaj.org/article/82b606013a8649b989b70c183de2674a)

## 4. Multiple voices: duets, choirs, male lead with female backing

### Takeaway
Removing only the female voice from a mixed vocal stem needs multi-singer separation. Research exists (MedleyVox, iSRNet, UNMIXX, karaoke singer separation), but none is shown running in real time on mobile, and highly correlated voices (unison, close harmony) remain hard. Tiny real-time speech-separation networks exist (TF-MLPNet, 6 ms chunks on a hearable accelerator) but are trained for speech. The feasible on-device design for 2026 is to **mute the whole vocal stem when female singing is detected with enough probability**, possibly with frame-level female-presence detection rather than whole-clip classification. Selective removal is an experimental, desktop-first option.

### Cited Findings
- **MedleyVox (ICASSP 2023)** defines multi-singer separation categories (unison, duet, main-vs-rest, N-singing). Its iSRNet reaches performance comparable to ideal time-frequency masks on the duet and unison subsets. Results are not broken down by gender. — [arXiv 2211.07302](https://arxiv.org/pdf/2211.07302)
- **Singer separation for karaoke (2021):** male-female duets need splitting into two vocals. The system estimates the number of lead singers and works best on slow ballads. — [arXiv 2110.06707](https://arxiv.org/abs/2110.06707v1)
- **UNMIXX:** highly correlated singing voices (shared pitch and timing) are hardest to separate, and standard metrics can mislead in that case. — [Moonlight review of UNMIXX](https://www.themoonlight.io/review/unmixx-untangling-highly-correlated-singing-voices-mixtures)
- **TF-MLPNet (Aug 2025):** a tiny time-frequency speech-separation network. With mixed-precision quantization-aware training it processes **6 ms chunks in real time on the GAP9** hearable processor, 3.5–4× faster than prior models. — [arXiv 2508.03047](https://arxiv.org/abs/2508.03047v1); [Clarity 2025](https://www.isca-archive.org/clarity_2025/itani25_clarity.html)
- DeepBeam (AAAI-22): 8 ms runtime on low-power mobile CPUs and 17.5 ms end-to-end latency, but it relies on multi-microphone beamforming, so it does not apply to a single stem. — [AAAI](https://aaai.org/?p=56137)
- **Pitch-conditioned separation:** the pitch-guided speech separation paper (AAAI 2023) separates one speaker per given pitch contour, avoiding permutation and unknown-speaker-count problems. A 2019 pitch-aware separator improves both same- and opposite-gender WSJ0-2mix. — [PGSS AAAI 2023](https://object.cloud.sdsc.edu/v1/AUTH_da4962d3368042ac8337e2dfdd3e7bf3/ml-papers-txt/AAAI/2023/pgss_pitchguided_speech_separation__9d727569.txt); [NWPU pitch-aware](https://pure.nwpu.edu.cn/zh/publications/a-pitch-aware-approach-to-single-channel-speech-separation/)
- Target-speaker extraction (SpeakerBeam, Delcroix et al. ICASSP 2020) is weakest when speakers sound alike, e.g. same-gender mixtures. — [BUT FIT](https://www.fit.vut.cz/research/result/c163961/)
- Personalized PercepNet (Interspeech 2021) is a real-time, speaker-conditioned enhancement model for speech, not singing. — [Interspeech 2021 PDF](https://www.isca-archive.org/interspeech_2021/giri21_interspeech.pdf)
- No real-time gender- or pitch-conditioned *singing* separation was found.

### Inferences
- **Recommended default:** whole-stem mute when the female-singing probability (or any-female-voice-present probability, trained on mixtures with male lead and female backing) exceeds a threshold. Train the detector on synthetic mixtures (male + female, female + female, choirs) so that "female present" is detected even when a male voice dominates. This is simple, fails closed, and adds no separation compute.
- **Optional advanced mode** (desktop, or flagship phones with NPU): a 2-singer separator (MedleyVox-style or a TF-MLPNet-style tiny network retrained on singing) followed by per-stream gender classification, muting only female streams. Expect artifacts and leakage in unison and close harmony (UNMIXX). Mark it experimental.
- **Choirs:** mixed choirs (SATB) almost always contain female voices, so treat "Choir" (YAMNet class 25) plus any female evidence as mute when the user enables fail-closed.

### Gaps
- No benchmark of streaming, causal multi-singer separation on mobile CPUs was found, nor any of causal TF-GridNet or SepFormer on phones.
- No published "female voice present in mixture" detector for singing was found.

## 5. Practical design: windows, hysteresis, look-ahead, false positives, evaluation

### Takeaway
Classification accuracy improves strongly with context (speech/singing: ~68% at 200 ms vs ~87–90% at 2 s; singing gender is typically reported at beat, 3 s or 30 s level). So a 100–300 ms reaction requires either (a) fail-closed muting at onset, released once confident, or (b) a short look-ahead buffer (delaying audio by the decision latency). Asymmetric hysteresis and per-class thresholds, set from the user's fail-closed preference, are the main levers. Evaluate with frame-level metrics that separately count "leaked female singing seconds" and "wrongly muted seconds" for male singing, speech and recitation.

### Cited Findings
- Short-window speech-vs-singing accuracy: 68.1% (200 ms) vs 87.3% (2 s). — [Ohishi et al. (via ISCA)](https://www.isca-archive.org/interspeech_2005/ohishi05_interspeech.html)
- Singer-gender results are reported at beat level (89.6%), at 3 s segments (STraDa annotated) and at song level (87.31%). No sub-second figures were found. — [Weninger et al.](https://www.researchgate.net/publication/224929629_Automatic_Assessment_of_Singer_Traits_in_Popular_Music_Gender_Age_Height_and_Race); [STraDa](https://arxiv.org/html/2406.04140v1); [ISMIR 2010](https://archives.ismir.net/ismir2010/paper/000105.pdf)
- Framewise event detection with AudioSet taggers is available (PANNs DecisionLevelMax/Att), though the time resolution was not stated in the README. — [PANNs repo](https://github.com/qiuqiangkong/audioset_tagging_cnn)
- Lightweight real-time singing-voice (vocal presence) detection is established. — [Lehner et al. ISMIR 2013](https://archives.ismir.net/ismir2013/paper/000089.pdf)

### Inferences (design proposals; not sourced, for the report writer to present as recommendations)
- **Two-tier detector:**
  - Tier 1 (fast, every 50–100 ms, ~250–500 ms receptive field): voice activity, F0 and voicing statistics, plus a tiny CNN giving p(female) and p(singing).
  - Tier 2 (every 250–500 ms, 1.5–3 s rolling context): an ECAPA- or MobileNet-embedding head that confirms or overturns Tier 1. Cache the speaker embedding per "voice segment" so that once a segment is confirmed male speech or recitation, later frames of the same segment need little evidence to stay unmuted.
- **Look-ahead:** delaying output by D ms (e.g. 150–300 ms) lets the classifier see D ms of the future before audio is emitted. Since the app already buffers for source separation, adding the gender decision inside that buffer gives near-zero leakage at the cost of A/V sync. Video players can usually compensate (to be checked by the sync researcher).
- **Hysteresis:** mute on p(female ∧ singing) > T_on held for ≥1 hop; unmute only when p < T_off (T_off < T_on) for ≥0.5–1 s. Ramp gain over 10–30 ms to avoid clicks. In fail-closed mode, start muted whenever a new voice onset occurs and Tier 2 has not yet decided (keep only if the user disabled fail-closed).
- **Uncertainty bins:** expose "uncertain" explicitly. Use calibrated probabilities (temperature scaling on a held-out set) and route "uncertain" through the user's policy (mute or keep).
- **Costs:** a false mute of male singing, speech or recitation is a usability failure. A leak of female singing violates the user's preference. Report both, and let the user pick an operating point (e.g. "strict", "balanced", "lenient") mapped to thresholds tuned on the test set.
- **Evaluation protocol:**
  - Frame-level (e.g. 10 ms) labels: {female, male, child, mixed} × {speech, singing, recitation, adhan, none}.
  - Metrics: leaked female-singing seconds per hour, false-mute seconds per hour by class, detection latency (onset to mute, median and 95th percentile), and segment-level F1.
  - Test set: VocalSet (CC BY 4.0) for techniques including falsetto; NHSS (same singers speaking and singing); separated vocals from in-the-wild music (STraDa-style timestamp lists); Arabic nasheed (male and female); male and female Quran recitation (murattal and mujawwad); adhan; children; auto-tuned pop; duets and choirs; female lecturers. Run on stems from the app's actual separator (Spleeter/Demucs-class) so that artifacts are included.
- **Licensing strategy:** train your own heads on permissive data (VocalSet CC BY 4.0, plus self-collected data). Avoid shipping audeering or Essentia MTG weights (CC BY-NC-SA) unless the project accepts non-commercial and share-alike constraints. Distillation from NC models may also be legally contested (not researched).

### Gaps
- No published study measures leakage vs window length or look-ahead for gender-gated muting. The design numbers above are engineering proposals.
- No measured on-device latency (ms per inference on a specific phone SoC) for any gender or speech-singing model was found in the sources read.
