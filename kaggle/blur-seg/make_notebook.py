"""Generate the Kaggle notebook that fine-tunes the screen blur's person segmenter (silhouette covers).

    python kaggle/blur-seg/make_notebook.py [--owner KAGGLE_USER] [--out DIR]
        ->  DIR (default kaggle/blur-seg)/{notebook.ipynb, kernel-metadata.json}

The committed metadata keeps the KAGGLE_USER placeholder: generate a copy with --owner "$KAGGLE_USERNAME" --out
<somewhere outside the repo> and push that copy (kaggle kernels push -p <dir>).
No Kaggle dataset is attached: the Open Images V7 mask index, mask archives, box CSV and images are downloaded inside
the notebook, and the COCO LR-ASPP weights from download.pytorch.org. Outputs in /kaggle/working/out:
seg_<tag>.pt (+ _eval.json, .log).
"""
import argparse
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FILES = ["models/vision/prep_seg_crops.py", "models/vision/train_seg.py"]
SEG_URL = "https://storage.googleapis.com/openimages/v5/train-annotations-object-segmentation.csv"
BOX_URL = "https://storage.googleapis.com/openimages/v6/oidv6-train-annotations-bbox.csv"
ZIPS_URL = "https://storage.googleapis.com/openimages/v5/train-masks/train-masks-{c}.zip"
SEG_ROWS = 634241  # person-like rows (Person, Man, Woman, Boy, Girl) in the segmentation CSV, checked 2026-11-11
WEIGHTS = "https://download.pytorch.org/models/lraspp_mobilenet_v3_large-d234d4ea.pth"
SIZES = [("s192", 192, 128), ("s144", 144, 96)]
# awk filter: the LabelName column ($3) of both CSVs is one of the person-like classes
PL = " || ".join(f'$3=="{m}"' for m in ("/m/01g317", "/m/04yx4", "/m/03bt1vf", "/m/01bl7v", "/m/05r655"))


def md(text):
    return {"cell_type": "markdown", "metadata": {}, "source": text.strip("\n").splitlines(True)}


def code(text):
    return {"cell_type": "code", "metadata": {}, "execution_count": None, "outputs": [],
            "source": text.strip("\n").splitlines(True)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--owner", default=os.environ.get("KAGGLE_USERNAME", "KAGGLE_USER"))
    ap.add_argument("--slug", default="waaiya-blur-seg")
    ap.add_argument("--out", default=os.path.dirname(os.path.abspath(__file__)))
    ap.add_argument("--prep-minutes", type=float, default=45)
    ap.add_argument("--train-minutes", type=float, default=110)
    ap.add_argument("--images", type=int, default=70000)
    a = ap.parse_args()

    cells = [md("""
# Waaiya screen blur: fine-tune the person segmenter for silhouette covers

Person crops and instance masks from the **Open Images V7 train split** (Person / Man / Woman / Boy / Girl masks
and boxes, CC BY 4.0; images listed as CC BY 2.0), cut from images resized to the phone's 640-px screen frame, with
the runtime's detector box + 20% context. torchvision's LR-ASPP MobileNetV3-large (COCO with VOC labels, BSD-3) is
fine-tuned to one "this person" output at two input sizes. The MIAP extension is **not** used. Checkpoints are chosen
on a 1% holdout of train images; the validation and test splits stay untouched for the end-to-end scorer.

Outputs in `/kaggle/working/out`: `seg_<tag>.pt` (state_dict + size + mean/std + context), `seg_<tag>_eval.json`, logs.
"""), code(f"""
PREP_MINUTES = {a.prep_minutes}
TRAIN_MINUTES = {a.train_minutes}   # per model when two GPUs train side by side; split in two on one GPU
IMAGES = {a.images}
SIZES = {SIZES!r}
SEG_URL, BOX_URL, ZIPS_URL, WEIGHTS = {SEG_URL!r}, {BOX_URL!r}, {ZIPS_URL!r}, {WEIGHTS!r}
SEG_ROWS = {SEG_ROWS}
PL = {PL!r}
""" + """
import os, subprocess, time, glob
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
    run(f"uv pip install -q -p {PY} numpy==1.26.4 pillow==11.0.0 setuptools==69.5.1")  # torch 2.1 imports pkg_resources
run(f"{PY} -c 'import torch, torchvision; print(torch.__version__, torchvision.__version__, torch.cuda.device_count(), \\"GPUs\\")'")
run("nproc; free -g; df -h /kaggle/tmp /kaggle/working")
W = f"{TMP}/lraspp_coco.pth"
if not os.path.exists(W):
    run(f"curl -sfL {WEIGHTS} -o {W}")
"""), code("""
# mask index (~800 MB) and box CSV (~2.3 GB): stream them, keep only the person-like rows
SEG = f"{TMP}/train-seg-person.csv"
BOX = f"{TMP}/train-person-boxes.csv"
if not os.path.exists(SEG):
    run(f"curl -sfL {SEG_URL} | awk -F, 'NR==1 || {PL}' > {SEG}.part && mv {SEG}.part {SEG}")
if not os.path.exists(BOX):
    run(f"curl -sfL {BOX_URL} | awk -F, 'NR==1 || {PL}' > {BOX}.part && mv {BOX}.part {BOX}")
n = sum(1 for _ in open(SEG)) - 1
print(n, "mask rows;", sum(1 for _ in open(BOX)) - 1, "box rows")
assert n == SEG_ROWS, f"expected {SEG_ROWS} rows, got {n}"
"""), code("""
DATA = f"{TMP}/segcrops"
if not os.path.exists(f"{DATA}/index.csv") or os.path.exists(f"{DATA}/rawmasks"):
    run(f"{PY} models/vision/prep_seg_crops.py --seg-csv {SEG} --box-csv {BOX} --zips-url {ZIPS_URL} --split train "
        f"--out {DATA} --images {IMAGES} --max-minutes {PREP_MINUTES} --threads 24 2>{TMP}/prep_err.log")
run(f"tail -n 3 {TMP}/prep_err.log; grep -c skip {TMP}/prep_err.log || true; du -sh {DATA}")
run(f"cut -d, -f2,3 {DATA}/index.csv | sort | uniq -c")
"""), code("""
ngpu = int(subprocess.check_output([PY, "-c", "import torch; print(torch.cuda.device_count())"]).decode())
ncpu = os.cpu_count()

def cmd(tag, h, w, minutes, workers):
    return [PY, "models/vision/train_seg.py", "--data", DATA, "--weights", W, "--out", OUT, "--size", str(h), str(w),
            "--tag", tag, "--minutes", str(minutes), "--workers", str(workers)]

if ngpu >= 2:   # one model per GPU, side by side
    procs = []
    for k, (tag, h, w) in enumerate(SIZES):
        log = open(f"{OUT}/seg_{tag}.log", "w")
        procs.append((tag, subprocess.Popen(cmd(tag, h, w, TRAIN_MINUTES, max(2, ncpu // 2)), cwd=CODE, stdout=log,
                                            stderr=subprocess.STDOUT, env={**os.environ, "CUDA_VISIBLE_DEVICES": str(k)})))
    while any(p.poll() is None for _, p in procs):
        time.sleep(300)
        for tag, _ in procs:
            lines = open(f"{OUT}/seg_{tag}.log").read().strip().splitlines()
            print(tag, "|", lines[-1][:300] if lines else "(no output yet)", flush=True)
    for tag, p in procs:
        print(tag, "exit", p.returncode)
else:
    for tag, h, w in SIZES:
        run(" ".join(cmd(tag, h, w, TRAIN_MINUTES / 2, ncpu)) + f" 2>&1 | tee {OUT}/seg_{tag}.log | grep -v '^ep '")
"""), code("""
run(f"ls -la {OUT}; grep -h '^eval\\\\|^best' {OUT}/*.log || true")
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
