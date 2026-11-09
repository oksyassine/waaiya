"""Generate the Kaggle training notebook from the repo sources (so the notebook never drifts from the code).

python kaggle/make_notebook.py [--owner KAGGLE_USER]  ->  kaggle/voice-train/{notebook.ipynb, kernel-metadata.json}
"""
import argparse, json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = [
    "models/dfn3/df_compat.py", "models/dfn3/export_stream.py",
    "models/voice/train.py", "models/voice/test_frontend.py",
    "testset/fetch_sources.py", "testset/build_testset.py",
    "eval/evaluate.py", "kaggle/prepare_data.py", "kaggle/eval_onnx.py",
]
DATASETS = ["hieugiaosu/librispeech", "abdo3id/diverse-quran-reciters"]  # Slakh comes from Hugging Face (1 GB subset)


def md(text):
    return {"cell_type": "markdown", "metadata": {}, "source": text.strip("\n").splitlines(True)}


def code(text):
    return {"cell_type": "code", "metadata": {}, "execution_count": None, "outputs": [], "source": text.strip("\n").splitlines(True)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--owner", default="KAGGLE_USER")
    ap.add_argument("--slug", default=None)
    ap.add_argument("--detector", action="store_true", help="generate the women's-singing detector notebook instead")
    args = ap.parse_args()
    if args.detector:
        return detector(args.owner, args.slug or "islamic-mute-detector-train")
    args.slug = args.slug or "islamic-mute-voice-train"
    cells = [md("""
# Islamic Mute: train the voice model (keep speech, recitation and singing; remove instruments)

Fine-tunes DeepFilterNet3 (MIT/Apache) so that **all voice is kept** and only musical instruments are removed,
then exports the 30 ms streaming ONNX model used by the Linux/Android engine and scores it against the
baseline on our evaluation set.

| Data | Licence |
|---|---|
| LibriSpeech (attached) | CC BY 4.0 |
| Arabic Speech Corpus (Hugging Face) | CC BY 4.0 |
| VocalSet singing (Hugging Face) | CC BY 4.0 |
| Diverse Quran Reciters (attached) | rights belong to the reciters: get permission before releasing weights, or set `USE_QURAN = False` |
| Slakh2100 instrument stems and mixes (Hugging Face subset) | CC BY 4.0 |

Outputs (in `/kaggle/working/out`): `voice_v1.onnx` + `voice_v1.state_init.bin` (drop-in model), `last.pt`, `eval_summary.md`.
"""), code("""
# ---- settings -------------------------------------------------------------
TRAIN_HOURS = 5.0            # wall-clock training budget (Kaggle GPU sessions stop at 12 h)
DATA_HOURS = "speech_en=3,speech_ar=3,singing=4,recitation=4,slakh=10"
USE_QURAN = True             # see the licence note above
BATCH = 16
MAX_STEPS = 60000            # upper bound; TRAIN_HOURS normally stops first
VOICE_WEIGHTS = {"speech_en": 0.7, "speech_ar": 1.0, "singing": 1.5, "recitation": 1.5}

import os, subprocess, sys, time
CODE, TMP, OUT = "/kaggle/working/code", "/kaggle/tmp", "/kaggle/working/out"
for d in (CODE, TMP, OUT):
    os.makedirs(d, exist_ok=True)

def run(cmd, cwd=CODE, env=None):
    \"\"\"Run a shell command, stream its output, fail loudly.\"\"\"
    print("$", cmd, flush=True)
    p = subprocess.Popen(cmd, shell=True, cwd=cwd, env={**os.environ, **(env or {})},
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in p.stdout:
        print(line, end="", flush=True)
    if p.wait() != 0:
        raise RuntimeError(f"command failed ({p.returncode}): {cmd}")
""")]
    cells.append(md("## Source files (generated from the repository)"))
    for f in FILES:
        src = open(os.path.join(ROOT, f)).read()
        cells.append(code(f"%%writefile {'/kaggle/working/code/' + f}\n" + src))
    # make the target folders before the %%writefile cells
    dirs = sorted({os.path.dirname("/kaggle/working/code/" + f) for f in FILES})
    cells.insert(2, code("import os\nfor d in " + repr(dirs) + ":\n    os.makedirs(d, exist_ok=True)"))
    cells += [md("""
## 1. Isolated Python 3.10 environment
Same versions as the verified local setup (torch 2.1.2, ONNX Runtime 1.19.2, numpy 1.26, deepfilternet 0.5.6),
so the official DeepFilterNet wheels work regardless of Kaggle's default Python.
"""), code("""
PY = f"{TMP}/venv/bin/python"
if not os.path.exists(PY):
    run("pip install -q uv")
    run(f"uv venv -q -p 3.10 {TMP}/venv")
    run(f"uv pip install -q -p {PY} torch==2.1.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu121")
    run(f"uv pip install -q -p {PY} deepfilternet==0.5.6 numpy==1.26.4 soundfile onnx==1.16.2 onnxruntime==1.19.2 "
        "'protobuf<5' huggingface_hub pyarrow")
run(f"{PY} -c 'import torch; print(\\"torch\\", torch.__version__, \\"cuda\\", torch.cuda.is_available(), torch.cuda.get_device_name(0) if torch.cuda.is_available() else \\"\\")'")
run("command -v ffmpeg || (apt-get update -qq && apt-get install -y -qq ffmpeg)")
run("ffmpeg -version | head -1")
run(f"{PY} test_frontend.py", cwd=f"{CODE}/models/voice")   # training front end == libDF
"""), md("## 2. Prepare training audio"), code("""
args = f"--out {TMP}/data --hours {DATA_HOURS}" + ("" if USE_QURAN else " --no-quran")
run(f"{PY} kaggle/prepare_data.py {args}")
run(f"du -sh {TMP}/data/*/*")
"""), md("## 3. Train (smoke test first, then the full run with a time budget)"), code("""
voice = [f"--voice {TMP}/data/voice/{k}:{w}" for k, w in VOICE_WEIGHTS.items() if os.path.isdir(f"{TMP}/data/voice/{k}")]
common = " ".join(voice) + f" --music {TMP}/data/music/slakh --synth-music 0.15 --workers 4"
run(f"{PY} models/voice/train.py {common} --steps 20 --batch 4 --log-every 5 --out {TMP}/smoke")
t0 = time.time()
run(f"{PY} models/voice/train.py {common} --steps {MAX_STEPS} --batch {BATCH} --hours {TRAIN_HOURS} "
    f"--log-every 200 --save-every 1000 --out {OUT}")
print(f"training took {(time.time() - t0) / 3600:.2f} h")
"""), md("## 4. Export streaming ONNX (baseline and fine-tuned)"), code("""
run(f"{PY} models/dfn3/export_stream.py --out {OUT}/dfn3_baseline.onnx")
run(f"{PY} models/dfn3/export_stream.py --checkpoint {OUT}/last.pt --out {OUT}/voice_v1.onnx "
    "--name 'Voice v1 (speech, recitation, singing)' --keeps speech,recitation,singing")
"""), md("## 5. Evaluate on the held-out test set"), code("""
run(f"{PY} testset/fetch_sources.py")
run(f"{PY} testset/build_testset.py")
run(f"{PY} kaggle/eval_onnx.py baseline={OUT}/dfn3_baseline.onnx voice_v1={OUT}/voice_v1.onnx", env={"EVAL_OUT": OUT})
"""), code("""
run(f"rm -rf {CODE}/testset/data; ls -la {OUT}")
print(open(f"{OUT}/eval_summary.md").read())
""")]
    nb = {"cells": cells, "metadata": {"kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
                                        "language_info": {"name": "python"}}, "nbformat": 4, "nbformat_minor": 5}
    write(nb, "voice-train", args.owner, args.slug)


def write(nb, folder, owner, slug):
    out_dir = os.path.join(ROOT, "kaggle", folder)
    os.makedirs(out_dir, exist_ok=True)
    json.dump(nb, open(os.path.join(out_dir, "notebook.ipynb"), "w"), indent=1)
    meta = {"id": f"{owner}/{slug}", "title": slug, "code_file": "notebook.ipynb",
            "language": "python", "kernel_type": "notebook", "is_private": True, "enable_gpu": True,
            "enable_tpu": False, "enable_internet": True, "machine_shape": "NvidiaTeslaT4",
            "dataset_sources": DATASETS, "competition_sources": [], "kernel_sources": [], "model_sources": []}
    json.dump(meta, open(os.path.join(out_dir, "kernel-metadata.json"), "w"), indent=1)
    print("wrote", out_dir)


DET_FILES = ["kaggle/prepare_data.py", "models/detector/mobilenet.py", "models/detector/prepare_detector_data.py",
             "models/detector/train_detector.py"]
MN04_URL = "https://github.com/fschmid56/EfficientAT/releases/download/v0.0.1/mn04_as_mAP_432.pt"


def detector(owner, slug):
    cells = [md("""
# Islamic Mute: train the women's-singing detector

Fine-tunes EfficientAT `mn04` (MobileNetV3, AudioSet-pretrained, MIT licence, ~1M parameters) to tell, from 1 s
of *separated voice*, whether a woman's voice is present and whether it is speech, singing or recitation.
The app (optionally, for men who enable it) mutes the voice when P(female) x P(singing) stays above the threshold
chosen here on held-out singers.  OpenSinger (CC BY-NC) is used **only** as an unseen-singer test, never for training.

Outputs in `/kaggle/working/out`: `detector_v1.onnx` (input: 769x100 power spectrogram, output: 4 probabilities),
`detector_eval.json`, `best.pt`.
"""), code("""
TRAIN_MINUTES = 90
HOURS = 2.0          # training audio per (style, gender, source)
USE_QURAN = True
import os, subprocess, time
CODE, TMP, OUT = "/kaggle/working/code", "/kaggle/tmp", "/kaggle/working/out"
for d in (CODE, TMP, OUT, CODE + "/kaggle", CODE + "/models/detector/weights"):
    os.makedirs(d, exist_ok=True)

def run(cmd, cwd=CODE, env=None):
    print("$", cmd, flush=True)
    p = subprocess.Popen(cmd, shell=True, cwd=cwd, env={**os.environ, **(env or {})},
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in p.stdout:
        print(line, end="", flush=True)
    if p.wait() != 0:
        raise RuntimeError(f"command failed ({p.returncode}): {cmd}")
""")]
    for f in DET_FILES:
        cells.append(code(f"%%writefile /kaggle/working/code/{f}\n" + open(os.path.join(ROOT, f)).read()))
    cells += [code(f"""
PY = f"{{TMP}}/venv/bin/python"
if not os.path.exists(PY):
    run("pip install -q uv")
    run(f"uv venv -q -p 3.10 {{TMP}}/venv")
    run(f"uv pip install -q -p {{PY}} torch==2.1.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu121")
    run(f"uv pip install -q -p {{PY}} numpy==1.26.4 soundfile onnx==1.16.2 onnxruntime==1.19.2 'protobuf<5' huggingface_hub pyarrow")
run("command -v ffmpeg || (apt-get update -qq && apt-get install -y -qq ffmpeg)")
run("curl -sfL -o models/detector/weights/mn04_as_mAP_432.pt {MN04_URL}")
run("sha256sum models/detector/weights/mn04_as_mAP_432.pt")
"""), code("""
run(f"{PY} models/detector/prepare_detector_data.py --out {TMP}/det --tmp {TMP}/dl --hours {HOURS}" + ("" if USE_QURAN else " --no-quran"))
run(f"du -sh {TMP}/det/*")
"""), code("""
run(f"{PY} models/detector/train_detector.py --data {TMP}/det --out {OUT} --minutes {TRAIN_MINUTES} --workers 4")
run(f"rm -f {OUT}/last.pt; ls -la {OUT}")
""")]
    nb = {"cells": cells, "metadata": {"kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
                                        "language_info": {"name": "python"}}, "nbformat": 4, "nbformat_minor": 5}
    write(nb, "detector-train", owner, slug)


if __name__ == "__main__":
    main()
