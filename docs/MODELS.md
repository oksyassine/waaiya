# Model files: how they are produced and shipped

Model weights are **not in git**. `.gitignore` excludes `*.onnx`, `*.state_init.bin`, `*.pt`/`*.pth`/`*.ckpt`.

| File | Size | How to get it |
|---|---|---|
| `models/dfn3/dfn3_stream.onnx` + `.state_init.bin` | 16 MB | `python models/dfn3/export_stream.py --out models/dfn3/dfn3_stream.onnx` (downloads the official DeepFilterNet3 checkpoint) |
| `models/dfn3/dfn3_stream_{fp16,int8}.onnx` | 4.4 / 2.4 MB | `python models/shrink.py models/dfn3/dfn3_stream.onnx --fp16 --int8` | **Default** for the APK and `waaiya install` is the int8 file (listening check passed).
| `voice_v1.onnx` + `.state_init.bin` | ~16 MB (2-5 MB shrunk) | Kaggle notebook `kaggle/voice-train` (see `models/voice/README.md`) |
| `models/detector/detector_v1.onnx` | ~4 MB | Kaggle notebook `kaggle/detector-train` |
| `models/detector/weights/mn04_as_mAP_432.pt` | 4 MB | EfficientAT release v0.0.1 (fetched by the detector notebook) |
| `models/vision/person_yolox_nano.onnx` | 3.6 MB | screen blur, people: `python models/vision/export_vision.py yolox --src yolox_nano.onnx --out ...` (official YOLOX ONNX, release 0.1.1rc0) |
| `models/vision/gender_v2.onnx` | ~17 MB | screen blur (bundled), woman/man per person, MobileNetV3-large: `prep_train_crops.py` + `kaggle/blur-gender/` (2x T4, ~100 min), `train_gender_v2.py`; scores in `eval/results/blur_gender_v2.md` |
| `models/vision/gender.onnx` (v1, comparison) | ~6 MB | screen blur, woman/man per person: `fetch_openimages.py` (both splits), `train_gender.py` (CPU, ~2 h), `export_vision.py gender` |
| `models/vision/seg.onnx` | 12.9 MB | screen blur (bundled as `blur_seg.onnx` when present; without it covers are rectangles), person outlines: LR-ASPP MobileNetV3-large fine-tuned on Open Images V7 person masks: `kaggle/blur-seg/` (`prep_seg_crops.py` + `train_seg.py`, 2x T4), then `export_vision.py seg --src seg_s192.pt --out seg.onnx`; scores in `eval/results/blur_silhouette.md` |
| `models/vision/nsfw_marqo_int8.onnx` | 6.7 MB | screen blur, immodest images: `export_vision.py marqo` (Marqo/nsfw-image-detection-384), then int8 (MatMul/Gemm only; see `models/vision/README.md`) |

## Distribution: release assets

Published models are attached to a tagged release (for example `models-v1`) as
`<name>.onnx`, `<name>.state_init.bin` and a `SHA256SUMS` file, plus release notes that list each model's
base model, training data and licences (from `THIRD_PARTY_LICENSES.md`). App and daemon releases bundle the
model they were tested with.

Why not the alternatives:

- **In-repo**: every retrain adds 2-16 MB of binary history that every clone downloads forever.
- **Git LFS**: forks and source archives get pointer files instead of models, free hosting quotas are small,
  and contributors need an extra tool. It brings nothing that release assets do not.

Before publishing a trained model, check the data-licence section of `THIRD_PARTY_LICENSES.md`
(the Quran recitation training data is not yet cleared).
