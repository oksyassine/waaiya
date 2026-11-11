"""Generate the Kaggle notebook that trains the screen blur's woman/man classifier v2 (from the repo sources).

    python kaggle/blur-gender/make_notebook.py [--owner KAGGLE_USER] [--out DIR]
        ->  DIR (default kaggle/blur-gender)/{notebook.ipynb, kernel-metadata.json}

The committed metadata keeps the KAGGLE_USER placeholder: generate a copy with --owner "$KAGGLE_USERNAME" --out
<somewhere outside the repo> and push that copy (kaggle kernels push -p <dir>).
No Kaggle dataset is attached (big attachments caused long queues): the Open Images box CSV and images are
downloaded inside the notebook. Outputs in /kaggle/working/out: gender_v2_<arch>.pt (+ _eval.json, .log).
"""
import argparse
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FILES = ["models/vision/prep_train_crops.py", "models/vision/train_gender_v2.py"]
CSV_URL = "https://storage.googleapis.com/openimages/v6/oidv6-train-annotations-bbox.csv"
CSV_ROWS = 2470641  # Woman/Man/Girl/Boy rows (all IsGroupOf values) in that file, checked on 2026-11-10
ARCHS = [("mobilenetv3_large_100", "miil_in21k_ft_in1k"), ("mobilenetv4_conv_small", "e2400_r224_in1k")]


def md(text):
    return {"cell_type": "markdown", "metadata": {}, "source": text.strip("\n").splitlines(True)}


def code(text):
    return {"cell_type": "code", "metadata": {}, "execution_count": None, "outputs": [],
            "source": text.strip("\n").splitlines(True)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--owner", default=os.environ.get("KAGGLE_USERNAME", "KAGGLE_USER"))
    ap.add_argument("--slug", default="waaiya-blur-gender")
    ap.add_argument("--out", default=os.path.dirname(os.path.abspath(__file__)))
    ap.add_argument("--prep-minutes", type=float, default=40)
    ap.add_argument("--train-minutes", type=float, default=100)
    ap.add_argument("--per-side", type=int, default=200000)
    a = ap.parse_args()

    cells = [md("""
# Waaiya screen blur: train the woman/man person classifier v2

Person crops from the **Open Images V7 train split** (Woman / Man / Girl / Boy boxes, IsGroupOf = 0; boxes
CC BY 4.0, images listed as CC BY 2.0), cut from images resized to the phone's 640-px screen frame. Two small
backbones (each at most ~4x the cost of v1's MobileNetV3-small at 192x128) are fine-tuned from ImageNet weights
(Hugging Face safetensors). The MIAP extension is **not** used (its authors ask that no gender classifier be built
from it). Checkpoints are chosen on a 1% holdout of train images; the validation split stays untouched for the
end-to-end scorer.

Outputs in `/kaggle/working/out`: `gender_v2_<arch>.pt` (state_dict + labels + size + mean/std + arch),
`gender_v2_<arch>_eval.json`, logs.
"""), code(f"""
PREP_MINUTES = {a.prep_minutes}     # stop fetching images after this (train on what arrived)
TRAIN_MINUTES = {a.train_minutes}   # per model when two GPUs train side by side; split in two on one GPU
PER_SIDE = {a.per_side}       # crops wanted per side (woman+girl, man+boy)
ARCHS = {ARCHS!r}
CSV_URL = {CSV_URL!r}
CSV_ROWS = {CSV_ROWS}
""" + """
import os, subprocess, time, glob, shutil
CODE, TMP, OUT = "/kaggle/working/code", "/kaggle/tmp", "/kaggle/working/out"
for d in (CODE + "/models/vision", TMP, OUT):
    os.makedirs(d, exist_ok=True)

def run(cmd, cwd=CODE, env=None):
    print("$", cmd, flush=True)
    p = subprocess.Popen(["bash", "-o", "pipefail", "-c", cmd], cwd=cwd, env={**os.environ, **(env or {})},
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in p.stdout:
        print(line, end="", flush=True)
    if p.wait() != 0:
        raise RuntimeError(f"command failed ({p.returncode}): {cmd}")
""")]
    for f in FILES:
        cells.append(code(f"%%writefile /kaggle/working/code/{f}\n" + open(os.path.join(ROOT, f)).read()))
    cells += [code("""
PY = f"{TMP}/venv/bin/python"
if not os.path.exists(PY):
    run("pip install -q uv")
    run(f"uv venv -q -p 3.10 {TMP}/venv")
    run(f"uv pip install -q -p {PY} torch==2.1.2 torchvision==0.16.2 --index-url https://download.pytorch.org/whl/cu121")
    run(f"uv pip install -q -p {PY} timm==1.0.11 numpy==1.26.4 pillow==11.0.0 huggingface_hub==0.26.5 safetensors==0.4.5")
run(f"{PY} -c 'import torch, timm; print(torch.__version__, timm.__version__, torch.cuda.device_count(), \\"GPUs\\")'")
run("nproc; free -g; df -h /kaggle/tmp /kaggle/working")
"""), code("""
# box CSV (~2.3 GB): stream it and keep only the Woman/Man/Girl/Boy rows
CSV = f"{TMP}/train-wmgb.csv"
if not os.path.exists(CSV):
    run(f"curl -sfL {CSV_URL} | awk -F, 'NR==1 || $3==\\"/m/03bt1vf\\" || $3==\\"/m/04yx4\\" || $3==\\"/m/05r655\\" "
        f"|| $3==\\"/m/01bl7v\\"' > {CSV}.part && mv {CSV}.part {CSV}")
n = sum(1 for _ in open(CSV)) - 1
print(n, "rows")
assert n == CSV_ROWS, f"expected {CSV_ROWS} rows, got {n}"
"""), code("""
DATA = f"{TMP}/gcrops"
if not os.path.exists(f"{DATA}/index.csv"):
    run(f"{PY} models/vision/prep_train_crops.py --csv {CSV} --out {DATA} --per-side {PER_SIDE} "
        f"--max-minutes {PREP_MINUTES} --threads 12 2>{TMP}/prep_err.log")
run(f"tail -n 3 {TMP}/prep_err.log; grep -c skip {TMP}/prep_err.log || true; du -sh {DATA}")
run(f"cut -d, -f2,3 {DATA}/index.csv | sort | uniq -c")
"""), code("""
ngpu = int(subprocess.check_output([PY, "-c", "import torch; print(torch.cuda.device_count())"]).decode())
ncpu = os.cpu_count()
procs = []
if ngpu >= 2:   # one model per GPU, side by side
    for k, (arch, tag) in enumerate(ARCHS):
        log = open(f"{OUT}/gender_v2_{arch}.log", "w")
        cmd = [PY, "models/vision/train_gender_v2.py", "--data", DATA, "--out", OUT, "--arch", arch, "--tag", tag,
               "--minutes", str(TRAIN_MINUTES), "--workers", str(max(2, ncpu // 2 + 1))]
        procs.append((arch, subprocess.Popen(cmd, cwd=CODE, stdout=log, stderr=subprocess.STDOUT,
                                             env={**os.environ, "CUDA_VISIBLE_DEVICES": str(k)})))
    while any(p.poll() is None for _, p in procs):
        time.sleep(300)
        for arch, _ in procs:
            lines = open(f"{OUT}/gender_v2_{arch}.log").read().strip().splitlines()
            print(arch, "|", lines[-1][:300] if lines else "(no output yet)", flush=True)
    for arch, p in procs:
        print(arch, "exit", p.returncode)
else:           # one GPU: one after the other, half the budget each
    for arch, tag in ARCHS:
        run(f"{PY} models/vision/train_gender_v2.py --data {DATA} --out {OUT} --arch {arch} --tag {tag} "
            f"--minutes {TRAIN_MINUTES / 2} --workers {ncpu} 2>&1 | tee {OUT}/gender_v2_{arch}.log | grep -v '^ep '")
"""), code("""
for f in glob.glob(f"{OUT}/*_last.pt"):
    os.remove(f)
run(f"ls -la {OUT}; grep -h '^best' {OUT}/*.log || true")
""")]
    nb = {"cells": cells, "metadata": {"kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
                                        "language_info": {"name": "python"}}, "nbformat": 4, "nbformat_minor": 5}
    os.makedirs(a.out, exist_ok=True)
    json.dump(nb, open(os.path.join(a.out, "notebook.ipynb"), "w"), indent=1)
    meta = {"id": f"{a.owner}/{a.slug}", "title": a.slug, "code_file": "notebook.ipynb", "language": "python",
            "kernel_type": "notebook", "is_private": True, "enable_gpu": True, "enable_tpu": False,
            "enable_internet": True, "machine_shape": "NvidiaTeslaT4", "dataset_sources": [],
            "competition_sources": [], "kernel_sources": [], "model_sources": []}
    json.dump(meta, open(os.path.join(a.out, "kernel-metadata.json"), "w"), indent=1)
    print("wrote", a.out)


if __name__ == "__main__":
    main()
