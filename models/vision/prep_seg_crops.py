"""Person crops + masks from the Open Images V7 *train* split, for the silhouette-cover segmenter (train_seg.py).

Open Images V7 instance masks (CC BY 4.0) of the person-like classes (Person, Man, Woman, Boy, Girl); the MIAP
extension is never used. Crops are cut the way the phone sees people: each image is resized to long side 640 (the
blur's screen frame), then each masked person box is cut with MARGIN extra on each side (train_seg.py jitters the
box and applies the runtime context inside that margin). Each crop has a label PNG of the same size:
    255  the person's own mask
    128  ignore: inside another person-like box (masked or not) and outside this person's mask
      0  background
so other people in the crop are neither taught as person nor as background.

    python models/vision/prep_seg_crops.py --seg-csv train-seg-person.csv --box-csv train-person-boxes.csv \
        --zips-url https://storage.googleapis.com/openimages/v5/train-masks/train-masks-{c}.zip --split train \
        --out /kaggle/tmp/segcrops [--images 60000] [--max-minutes 40]

--seg-csv: the object-segmentation CSV (or only its person-like rows, with the header).
--box-csv: the bbox CSV (or only its person-like rows, with the header): people without a mask become "ignore".
--zips-url: the mask archives, {c} = 0..9a..f; a local path works too (then the archives are kept).
Images are split by md5(image id): 1 in 100 goes to the *holdout* (checkpoints, never trained on).
Writes <out>/index.csv: image, label, holdout, bx0, by0, bx1, by1 (box inside the crop, 0..1), h_frame, crop, mask
"""
import argparse
import csv
import hashlib
import io
import os
import random
import shutil
import sys
import time
import urllib.request
import zipfile
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor

import numpy as np
from PIL import Image

PERSONLIKE = {"/m/01g317": "person", "/m/04yx4": "man", "/m/03bt1vf": "woman", "/m/01bl7v": "boy", "/m/05r655": "girl"}
URL = "https://open-images-dataset.s3.amazonaws.com/{split}/{id}.jpg"
FRAME_LONG = 640
MARGIN = 0.35
CROP_LONG = 256
MIN_H = 12  # skip people shorter than this in the 640 frame (pixels)


def is_holdout(image_id):
    return int(hashlib.md5(image_id.encode()).hexdigest(), 16) % 100 == 0


def fetch(url, tries=3):
    for i in range(tries):
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                return r.read()
        except Exception as e:  # noqa: BLE001 - network: retry, then give up
            if i == tries - 1:
                print(f"skip {url}: {e}", file=sys.stderr)
                return None
            time.sleep(1 + 2 * i)


def fetch_zip(src, dst):
    if os.path.exists(src):
        return src
    for i in range(3):
        try:
            with urllib.request.urlopen(src, timeout=120) as r, open(dst + ".part", "wb") as f:
                shutil.copyfileobj(r, f, 1 << 22)
            os.replace(dst + ".part", dst)
            return dst
        except Exception as e:  # noqa: BLE001
            print(f"zip retry {src}: {e}", file=sys.stderr)
            time.sleep(5)
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seg-csv", required=True)
    ap.add_argument("--box-csv", required=True)
    ap.add_argument("--zips-url", required=True)
    ap.add_argument("--split", default="train")
    ap.add_argument("--out", required=True)
    ap.add_argument("--images", type=int, default=60000, help="training images wanted (holdout images come on top)")
    ap.add_argument("--max-minutes", type=float, default=40, help="stop fetching images after this")
    ap.add_argument("--threads", type=int, default=16)
    ap.add_argument("--seed", type=int, default=0)
    a = ap.parse_args()
    t0 = time.time()

    masks = defaultdict(list)  # image -> [(mask path, label, x0, y0, x1, y1)]
    with open(a.seg_csv, newline="") as f:
        for r in csv.DictReader(f):
            if r["LabelName"] in PERSONLIKE:
                masks[r["ImageID"]].append((r["MaskPath"], PERSONLIKE[r["LabelName"]], float(r["BoxXMin"]),
                                            float(r["BoxYMin"]), float(r["BoxXMax"]), float(r["BoxYMax"])))
    ids = sorted(masks)
    hold = [i for i in ids if is_holdout(i)]
    rest = [i for i in ids if not is_holdout(i)]
    random.Random(a.seed).shuffle(rest)
    hold = hold[: max(200, a.images // 100)]
    chosen = hold + rest[: a.images]
    cset = set(chosen)
    print(f"{len(ids)} images with person masks; using {len(hold)} holdout + {len(chosen) - len(hold)} train",
          flush=True)

    boxes = defaultdict(list)
    with open(a.box_csv, newline="") as f:
        for r in csv.DictReader(f):
            if r["ImageID"] in cset and r["LabelName"] in PERSONLIKE:
                boxes[r["ImageID"]].append((float(r["XMin"]), float(r["YMin"]), float(r["XMax"]), float(r["YMax"])))

    # masks of the chosen images, archive by archive
    mdir = os.path.join(a.out, "rawmasks")
    os.makedirs(mdir, exist_ok=True)
    want = defaultdict(set)
    for i in chosen:
        for m in masks[i]:
            if not os.path.exists(os.path.join(mdir, m[0])):
                want[m[0][0]].add(m[0])
    for c, names in sorted(want.items()):
        z = fetch_zip(a.zips_url.format(c=c), os.path.join(a.out, f"masks-{c}.zip"))
        if not z:
            continue
        with zipfile.ZipFile(z) as zf:
            have = set(zf.namelist())
            for n in names & have:
                with zf.open(n) as s, open(os.path.join(mdir, n), "wb") as d:
                    shutil.copyfileobj(s, d)
        if z.startswith(a.out):
            os.remove(z)
        print(f"masks {c}: {len(names)} wanted, {time.time() - t0:.0f} s", flush=True)

    cdir = os.path.join(a.out, "crops")
    os.makedirs(cdir, exist_ok=True)
    deadline = t0 + a.max_minutes * 60

    def work(image_id):
        if time.time() > deadline:
            return []
        data = fetch(URL.format(split=a.split, id=image_id))
        if data is None:
            return []
        img = Image.open(io.BytesIO(data)).convert("RGB")
        s = FRAME_LONG / max(img.size)
        W, H = max(1, round(img.size[0] * s)), max(1, round(img.size[1] * s))
        img = img.resize((W, H), Image.BILINEAR)
        mine = masks[image_id]
        others = [(x0, y0, x1, y1) for (_, _, x0, y0, x1, y1) in mine] + boxes.get(image_id, [])
        lines = []
        for n, (mp, lab, x0, y0, x1, y1) in enumerate(mine):
            if (y1 - y0) * H < MIN_H or (x1 - x0) * W < 4:
                continue
            p = os.path.join(mdir, mp)
            if not os.path.exists(p):
                continue
            m = np.asarray(Image.open(p).convert("L").resize((W, H), Image.BILINEAR)) >= 128
            if not m.any():
                continue
            label = np.zeros((H, W), np.uint8)
            for (ox0, oy0, ox1, oy1) in others:
                if abs(ox0 - x0) < 1e-3 and abs(oy0 - y0) < 1e-3 and abs(ox1 - x1) < 1e-3 and abs(oy1 - y1) < 1e-3:
                    continue  # this person's own box
                label[int(oy0 * H):int(np.ceil(oy1 * H)), int(ox0 * W):int(np.ceil(ox1 * W))] = 128
            label[m] = 255
            bw, bh = (x1 - x0) * W, (y1 - y0) * H
            cx0, cy0 = max(0, int(x0 * W - MARGIN * bw)), max(0, int(y0 * H - MARGIN * bh))
            cx1, cy1 = min(W, int(np.ceil(x1 * W + MARGIN * bw))), min(H, int(np.ceil(y1 * H + MARGIN * bh)))
            crop, lc = img.crop((cx0, cy0, cx1, cy1)), Image.fromarray(label[cy0:cy1, cx0:cx1])
            k = CROP_LONG / max(crop.size)
            if k < 1:
                sz = (max(1, round(crop.size[0] * k)), max(1, round(crop.size[1] * k)))
                crop, lc = crop.resize(sz, Image.BILINEAR), lc.resize(sz, Image.NEAREST)
            name = f"{image_id}_{n}"
            crop.save(os.path.join(cdir, name + ".jpg"), quality=92)
            lc.save(os.path.join(cdir, name + ".png"))
            cw, ch = cx1 - cx0, cy1 - cy0
            lines.append([image_id, lab, int(is_holdout(image_id)), (x0 * W - cx0) / cw, (y0 * H - cy0) / ch,
                          (x1 * W - cx0) / cw, (y1 * H - cy0) / ch, y1 - y0, name + ".jpg", name + ".png"])
        return lines

    n_img = n_crop = 0
    with open(os.path.join(a.out, "index.csv"), "w", newline="") as f, ThreadPoolExecutor(a.threads) as ex:
        w = csv.writer(f)
        w.writerow(["image", "label", "holdout", "bx0", "by0", "bx1", "by1", "h_frame", "crop", "mask"])
        for lines in ex.map(work, chosen):
            w.writerows(lines)
            n_img += 1
            n_crop += len(lines)
            if n_img % 2000 == 0:
                f.flush()
                print(f"{n_img}/{len(chosen)} images, {n_crop} crops, {time.time() - t0:.0f} s", flush=True)
    shutil.rmtree(mdir, ignore_errors=True)
    print(f"done: {n_crop} crops from {n_img} images in {time.time() - t0:.0f} s", flush=True)


if __name__ == "__main__":
    main()
