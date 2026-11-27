# Arabic speech model for live captions

Live captions (`docs/CAPTIONS.md`) run any ONNX model that follows the **ASR contract** (`engine/include/im_captions.h`):

- input `audio`: float32 `[1, N]`, mono, 16 kHz, -1..1 (feature extraction is inside the model);
- output `logits`: float32 `[1, T, V]`, CTC scores per frame;
- metadata: `asr.contract` = `1`, `asr.sample_rate` = `16000`, `asr.blank` (blank token index), `asr.frame_ms`,
  `asr.model_name`, and `asr.tokens` (the V tokens, one per line; `▁` starts a word, `<...>` tokens are skipped).

A model that lacks the contract is refused when it loads, so a wrong file gives "could not start", never wrong text.

## Files

- `make_test_model.py`: a tiny made-up model that follows the contract, for the engine's tests (`make test-captions`).
- `export_fastconformer.py`: exports NVIDIA's Arabic FastConformer (default
  `nvidia/stt_ar_fastconformer_hybrid_large_pc_v1.0`) with its CTC head, then an int8 copy. It checks its own front end
  against NeMo, ONNX Runtime against PyTorch, and int8 text against float text, and stops on any mismatch.

## Making the default model

Not run yet: this machine cannot reach Hugging Face. On one that can:

```
pip install "nemo_toolkit[asr]" onnx onnxruntime soundfile
python models/asr/export_fastconformer.py --out models/asr/fastconformer_ar --check khutba1.wav khutba2.wav
make build/im-caption && build/im-caption -a models/asr/fastconformer_ar_int8.onnx --partials khutba1.wav
```

The Android build bundles `models/asr/fastconformer_ar_int8.onnx` as `captions_ar.onnx` when it exists (or
`-PimCaptionsModel=/path`). Without it the build still works and the app offers no captions.

Before shipping: read the licence on the model card, credit NVIDIA in `THIRD_PARTY_LICENSES.md`, and publish the
file as a release asset like the other models (`docs/MODELS.md`), never in git.

## Choice and trade-offs

See the table in `docs/CAPTIONS.md`. In short: FastConformer `_pc` for the best Modern Standard Arabic at a size a
phone can run; `_pcd` if diacritics matter more than speed of reading; Moonshine tiny if the APK must stay small.
Darija needs a fine-tuned model later; it drops in as a new file that follows the contract.
