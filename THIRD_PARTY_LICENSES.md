# Third-party components, models and data

Islamic Mute itself is licensed under AGPL-3.0-or-later (`LICENSE`, `NOTICE`). This file lists everything it builds on,
where the licence was read, and what each licence requires. Audit date: 2026-11-09.

Status: **OK** = permissive, attribution only. **Flag** = needs a decision or restricts redistribution.

## 1. Code shipped in this repository

| Component | Path | Licence | Source of truth | Status |
|---|---|---|---|---|
| EfficientAT licence (kept because the detector loads its weights; `mobilenet.py` is our own re-implementation) | `models/detector/efficientat/LICENSE` | MIT, (c) 2022 Florian Schmid | the LICENSE file | OK |
| AudioSet class list (not used by code) | `models/detector/efficientat/class_labels_indices.csv` | AudioSet: dataset CC BY 4.0, ontology CC BY-SA 4.0 (Google) | research.google.com/audioset/download.html | OK (attribute; SA applies to this data file only) |
| Gradle wrapper | `android/gradlew*`, `android/gradle/wrapper/` | Apache-2.0 | file headers, `META-INF/LICENSE` in the jar | OK |
| LADSPA ABI declarations | `linux/ladspa/ladspa_abi.h` | ours (types and constants rewritten from the LADSPA 1.1 spec; the SDK's `ladspa.h` is LGPL-2.1, whose section 5 exempts data layouts and small macros anyway) | file header | OK |
| Desktop screen blur: X11 / PipeWire / Wayland ABI declarations | `linux/blur/x11_dl.h`, `pw_dl.h`, `wl_dl.h`, the interface tables in `layer.c` | ours (layouts, constants and message signatures for run-time loading; X11 and Wayland are MIT, PipeWire's headers MIT; the wlr-layer-shell and xdg-output protocol descriptions are MIT, and only their message tables are reproduced) | `linux/blur/abi_check.c` (compared with the real headers in CI) | OK |
| Licence texts of the blur models | `models/vision/licences/YOLOX-LICENSE.txt` (YOLOX repository `LICENSE`, Apache-2.0, (c) Megvii), `Marqo-nsfw-image-detection-384-NOTICE.txt` (ours: points to the model card's Apache-2.0) | as stated | upstream repository / model card | OK; copied next to the desktop app (`desktop/tool/bundle_engine.sh`) |

## 2. Build and runtime dependencies (not in the repository; fetched or installed at build time)

| Component | Version | Used by | Licence | Source of truth | Status |
|---|---|---|---|---|---|
| ONNX Runtime (C API, Linux x64) | 1.19.2 (commit ffceed9d) | engine, CLI, LADSPA; `make` copies `libonnxruntime.so` into `build/` | MIT, (c) Microsoft | `third_party/onnxruntime/LICENSE`, `VERSION_NUMBER` | OK. Binary releases must include `LICENSE` and `ThirdPartyNotices.txt` (338 KB, covers ORT's own deps) |
| onnxruntime-android (AAR) | 1.19.2 | Android app (`libonnxruntime.so` in the APK) | MIT | Maven POM | OK, same notice rule |
| Shizuku-API: api, provider, aidl, shared | 13.1.5 | Android one-tap setup | MIT | Maven POMs (`<license>MIT License`, RikkaApps/Shizuku-API) | OK |
| androidx.media3 (exoplayer, ui, common, container, datasource, decoder, extractor, database) | 1.5.1 | Android player | Apache-2.0 | Maven POMs | OK |
| Other AndroidX (annotation, arch.core, collection, concurrent-futures, core, customview, exifinterface, lifecycle, media, recyclerview, versionedparcelable) | various | transitive | Apache-2.0 | Maven POMs (Google Maven) | OK |
| Kotlin stdlib, org.jetbrains:annotations | 2.0.21, 13.0 | Android | Apache-2.0 | Maven POMs | OK |
| Guava, failureaccess, listenablefuture | transitive of Media3 | Android | Apache-2.0 | guava-parent POM (listenablefuture is the empty placeholder artifact) | OK |
| androidx.media3 transformer, effect, muxer | 1.5.1 | Android "Save without music" (filter audio, copy video) | Apache-2.0 | Maven POMs | OK |
| Chaquopy (Gradle plugin + runtime) | 17.2.0 | Android link feature: runs Python in the app | MIT, (c) Chaquo Ltd | `android/app/licences/Chaquopy-LICENSE.txt` (from the 17.2.0 tag) | OK |
| CPython (shipped by Chaquopy) | 3.11 | Android link feature | PSF License | `android/app/licences/Python-LICENSE.txt` | OK |
| yt-dlp (pip, in the APK) | 2026.10.26 | Android link feature: reads page links | Unlicense (public domain) | wheel `dist-info/licenses/LICENSE` | OK. No extras installed (`yt-dlp[default]` would add other licences) |
| yt-dlp-ejs (pip, in the APK) | 0.8.0 | YouTube JavaScript challenge scripts | Unlicense; bundles astring (MIT) and meriyah (ISC) in `yt/solver/*.min.js` | wheel `dist-info/licenses/LICENSE`, upstream README | OK. The bundled MIT/ISC notices stay inside the minified files as shipped |
| QuickJS-NG (`qjs`, built from source by `android/tools/build_qjs.sh`) | 0.18.0 (sha256 28bcd89a…f9f1dd) | runs the yt-dlp-ejs scripts on the phone | MIT | source tarball `LICENSE` | OK |
| HiddenApiBypass (`org.lsposed.hiddenapibypass`) | 4.3 | Android screen blur: sets the hidden "skip screenshot" flag on the covers window | Apache-2.0 | Maven POM (LSPosed/AndroidHiddenApiBypass) | OK |
| glibc / Linux UAPI headers (optional local sysroot) | Ubuntu 22.04 `libc6-dev`, `linux-libc-dev` | build only, when headers are missing | LGPL-2.1+ / GPL-2.0 with syscall exception | `third_party/sysroot/usr/share/doc/*/copyright` | OK: build-time only, not committed, not shipped |
| Python tooling (not shipped): torch 2.1.2, torchaudio 2.1.2, numpy 1.26.4, soundfile 0.13.1, onnx 1.16.2, onnxruntime 1.19.2, onnxconverter-common 1.16.0, huggingface_hub | | export, training, evaluation | BSD-3 / BSD-2 / BSD / BSD-3 / Apache-2.0 / MIT / MIT / Apache-2.0 | `.venv` package metadata (huggingface_hub not installed locally: licence not verified) | OK |
| Python tooling for the screen blur (not shipped): timm 1.0.11, torchvision 0.16.2, safetensors, Pillow, huggingface_hub 0.26.5 | | `models/vision/` export, training, scoring | Apache-2.0 / BSD-3 / Apache-2.0 / MIT-CMU (HPND) / Apache-2.0 | PyPI metadata | OK |
| Linux system libraries loaded at run time by `im-blur` (not shipped): libX11, libXext, libXrandr, libXdamage, libgio-2.0, libpipewire-0.3, libwayland-client | the user's system | desktop screen blur (`dlopen`) | MIT (X11, Wayland), LGPL-2.1+ (GLib), MIT (PipeWire library) | distribution packages | OK: not linked at build time, not redistributed |
| deepfilternet / DeepFilterLib | 0.5.6 | export (`models/dfn3/export_stream.py`) and fine-tuning | MIT OR Apache-2.0, (c) 2021 Hendrik Schroeter | `.venv` dist-info `LICENSE`, `LICENSE-MIT`, `LICENSE-APACHE` | OK |
| faster-whisper (optional `--asr` in `eval/evaluate.py`) | | evaluation only | not installed locally: **unknown, not verified** | | n/a (not shipped) |

## 3. Models

| Model | Origin | Weights licence | Trained on | Status |
|---|---|---|---|---|
| `models/dfn3/dfn3_stream{,_fp16,_int8}.onnx` (16 / 4.4 / 2.4 MB) | Streaming re-export of the official DeepFilterNet3 checkpoint (downloaded by `df.enhance` from `github.com/Rikorose/DeepFilterNet/raw/main/models/DeepFilterNet3.zip`) | MIT OR Apache-2.0 (the repository licence; the zip carries no separate licence). Our export records `im.licence = MIT OR Apache-2.0` in the ONNX metadata | Upstream's training data (not re-checked here) | OK |
| EfficientAT `mn04_as_mAP_432.pt` (detector backbone, 4 MB) | GitHub release `fschmid56/EfficientAT` v0.0.1 | MIT (repository licence; the release asset carries no separate licence) | AudioSet (labels CC BY 4.0; audio is YouTube content, not redistributed by anyone) | OK |
| `mn10_as_mAP_471.pt` (only `zeroshot.py`, an experiment) | same | MIT | AudioSet | OK, not shipped |
| `voice_v1.onnx` (future, Kaggle) | DeepFilterNet3 fine-tuned by `models/voice/train.py` | ours (AGPL-3.0-or-later) on top of MIT/Apache base, **subject to section 4** | LibriSpeech, Arabic Speech Corpus, VocalSet, Slakh2100, **Diverse Quran Reciters** (`USE_QURAN = True` in `kaggle/make_notebook.py`) | **Flag** (Quran data) |
| `detector_v1.onnx` (future, Kaggle) | EfficientAT mn04 fine-tuned by `models/detector/train_detector.py` | ours (AGPL-3.0-or-later) on top of MIT base, **subject to section 4** | LibriSpeech, FLEURS ar_eg, VocalSet, Slakh2100, **Diverse Quran Reciters** (incl. the female reciter "Ayu Rumiyati") | **Flag** (Quran data) |
| `models/vision/person_yolox_nano.onnx` (3.6 MB; screen blur, people; Android and the Linux desktop bundle) | YOLOX-Nano official ONNX (`github.com/Megvii-BaseDetection/YOLOX` release 0.1.1rc0, sha256 c7891611…a0b7d), wrapped by `models/vision/export_vision.py` (pre/post-processing added, weights unchanged) | Apache-2.0 (repository licence) | COCO 2017 (annotations CC BY 4.0; images Flickr, per-image licences) | OK |
| `models/vision/nsfw_marqo{,_int8}.onnx` (22 / 6.7 MB; screen blur, immodest images; int8 in Android and the Linux desktop bundle) | `Marqo/nsfw-image-detection-384` (Hugging Face, safetensors), exported by `export_vision.py`; int8 = dynamic quantisation of MatMul/Gemm | Apache-2.0 (model card `license: apache-2.0`) | Marqo's own 220k-image set (not public; not re-checked) | OK (upstream statement) |
| `models/vision/gender_v2.onnx` (screen blur, woman/man per person; bundled on Android and the Linux desktop) | ours: timm `mobilenetv3_large_100` (ImageNet-21k pretrained, timm Apache-2.0) fine-tuned by `models/vision/train_gender_v2.py` | ours (AGPL-3.0-or-later) | Open Images V7 boxes Woman/Man/Girl/Boy, train split (section 4) | OK. ImageNet pre-training: the usual caveat (ImageNet images are research-licensed; the weights are widely redistributed) |
| `models/vision/gender.onnx` (screen blur, woman/man per person) | ours: timm `mobilenetv3_small_100` (ImageNet-1k pretrained, timm Apache-2.0) fine-tuned by `models/vision/train_gender.py` | ours (AGPL-3.0-or-later) | Open Images V7 boxes Woman/Man/Girl/Boy, test split (section 4) | OK. ImageNet pre-training: the usual caveat (ImageNet images are research-licensed; the weights are widely redistributed) |

## 4. Datasets

Licences below were read from the dataset card / record on 2026-11-09, not copied from our own docstrings.

| Dataset | Where we get it | Used for | Licence (read from) | Status |
|---|---|---|---|---|
| LibriSpeech | Kaggle `hieugiaosu/librispeech` (training); HF `sanchit-gandhi/librispeech_asr_dummy` (test set) | voice_v1, detector_v1; evaluation | CC BY 4.0 (openslr.org/12; HF card). The Kaggle mirror itself says **"Unknown"** | OK (upstream licence applies; mirror is an unmodified re-upload as far as we know) |
| Arabic Speech Corpus (N. Halabi) | HF `tunis-ai/arabic_speech_corpus` | voice_v1; evaluation | CC BY 4.0 (HF card) | OK |
| FLEURS (Google) | HF `google/fleurs` (ar_eg, en_us) | detector_v1; detector check set | CC BY 4.0 (HF card) | OK |
| VocalSet 1.1 | Zenodo 1442513; HF `Bill13579/vocalset-mirror` | voice_v1, detector_v1; evaluation | CC BY 4.0 (Zenodo record; HF card) | OK |
| Slakh2100 | HF `tvergho/slakh` (1 GB subset) or a Kaggle copy | instrument audio for voice_v1, detector_v1 | CC BY 4.0 (Zenodo 4599666). The HF subset declares **no licence** | OK (upstream licence applies) |
| Diverse Quran Reciters | Kaggle `abdo3id/diverse-quran-reciters` | **training** voice_v1 and detector_v1 | Kaggle metadata: **"Unknown"**; no source or reciter permissions stated. Recordings belong to the reciters / their publishers | **Flag: redistribution of models trained on it not cleared** |
| Quran audio | HF `fawazahmed0/quran-audio` | 6 test-set clips (evaluation only, not committed) | Card says CC0-1.0, but lists everyayah.com and qurancomplex.gov.sa as sources: the uploader cannot waive rights it does not hold | Flag, low: evaluation only, nothing redistributed |
| OpenSinger (Multi-Singer, Huang et al. 2021) | HF `CodecSR/opensinger_female`, `_male` | detector check set only (`models/detector/evalset/`, gitignored); never trained on | **CC BY-NC-SA** (upstream Multi-Singer README; the HF mirrors declare nothing) | Flag: must stay evaluation-only and must not be redistributed or used to train a released model |
| AudioSet | indirectly, through the EfficientAT pretrained weights | backbone pre-training (upstream) | CC BY 4.0 (labels) | OK |
| MUSDB18, MoisesDB, MedleyDB | not used | | non-commercial / academic | must not be used for released models (`models/voice/README.md`) |
| Common Voice Arabic | listed in `models/voice/README.md`, not used by the current scripts | | CC0 | OK |
| Open Images V7 (boxes for Woman, Man, Girl, Boy) | `storage.googleapis.com/openimages/v5/*-annotations-bbox.csv`; images from the public `open-images-dataset` bucket (`models/vision/fetch_openimages.py`) | `gender.onnx` (test split crops), `gender_v2.onnx` (train split crops); end-to-end scoring (validation split) | Annotations CC BY 4.0 (Google); images listed as CC BY 2.0, "no representations or warranties" per image | OK (crops and images stay local, gitignored, not redistributed). Not used: the MIAP extension, whose authors ask not to build gender classifiers from it |

Evaluation mixtures (`testset/build_testset.py`) use procedurally synthesised music, so no music copyright is involved.

## 5. Does a model trained on a dataset inherit the dataset's terms?

There is no settled answer, and it differs by jurisdiction. Training copies the data, so whether the licence
conditions bind depends on whether that copy needs permission at all (EU text-and-data-mining exceptions, US fair
use, etc.) and on whether trained weights count as "adapted material" of the data. Creative Commons' own guidance
is that CC conditions apply only where the use needs copyright permission; it does not say the weights are
always a derivative. Practical policy for this project:

1. **CC BY data**: attribute every training dataset when weights are released (release notes plus `NOTICE`).
   That is cheap and satisfies the strictest reading.
2. **NC, SA or unknown-licence data is never used to train a released model.** OpenSinger complies (evaluation only).
3. **Quran recitations** do not comply: both Kaggle runs train on `abdo3id/diverse-quran-reciters` (licence unknown).
   Before publishing `voice_v1.onnx` or `detector_v1.onnx`, choose one:
   a. get permission from the dataset owner / reciters (or use recordings whose licence explicitly allows it);
   b. retrain with `USE_QURAN = False` (`kaggle/make_notebook.py`, `--no-quran` in both data scripts), accepting
      possibly lower recitation retention, or replace it with self-recorded / commissioned recitation;
   c. publish anyway, disclosing the data source and the risk (not recommended).
   The code is unaffected either way: none of this data is in the repository.

## 6. How models are distributed

ONNX models (2-20 MB) are **not committed**: `*.onnx`, `*.state_init.bin` and `*.pt` are gitignored. They are
published as **release assets** (with SHA-256 sums and the attributions above). See `docs/MODELS.md`.
