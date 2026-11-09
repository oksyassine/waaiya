# Model files: how they are produced and shipped

Model weights are **not in git**. `.gitignore` excludes `*.onnx`, `*.state_init.bin`, `*.pt`/`*.pth`/`*.ckpt`.

| File | Size | How to get it |
|---|---|---|
| `models/dfn3/dfn3_stream.onnx` + `.state_init.bin` | 16 MB | `python models/dfn3/export_stream.py --out models/dfn3/dfn3_stream.onnx` (downloads the official DeepFilterNet3 checkpoint) |
| `models/dfn3/dfn3_stream_{fp16,int8}.onnx` | 4.4 / 2.4 MB | `python models/shrink.py models/dfn3/dfn3_stream.onnx --fp16 --int8` |
| `voice_v1.onnx` + `.state_init.bin` | ~16 MB (2-5 MB shrunk) | Kaggle notebook `kaggle/voice-train` (see `models/voice/README.md`) |
| `models/detector/detector_v1.onnx` | ~4 MB | Kaggle notebook `kaggle/detector-train` |
| `models/detector/weights/mn04_as_mAP_432.pt` | 4 MB | EfficientAT release v0.0.1 (fetched by the detector notebook) |

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
