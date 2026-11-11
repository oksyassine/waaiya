"""Person crops from the Open Images V7 *train* split for the woman/man classifier v2 (boxes CC BY 4.0).

Crops are cut the way the phone sees people: each image is first resized to long side 640 (the screen frame the
blur works on), then every Woman / Man / Girl / Boy box (IsGroupOf = 0) is cut with 25% extra margin on each side
(train_gender_v2.py jitters the box and applies the runtime's 10% context inside that margin). Crops keep the
frame's pixels (no upscaling; long side capped at 256).

    python models/vision/prep_train_crops.py --csv train-wmgb.csv --out /kaggle/tmp/gcrops \
        [--per-side 200000] [--max-minutes 50] [--limit 0]

--csv: the train box CSV, or only its Woman/Man/Girl/Boy rows with the header line.
Images are split by md5(image id): 1 in 100 goes to the *holdout* (checkpoint and threshold selection, never
trained on). Training images are taken in a fixed random order until both sides (woman+girl, man+boy) reach
--per-side crops. Holdout images are fetched first. Writes <out>/index.csv:
    image, label, holdout, bx0, by0, bx1, by1 (box inside the crop, 0..1), h_frame (box height / frame), crop
"""
import argparse
import csv
import hashlib
import io
import os
import random
import sys
import time
import urllib.request
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from multiprocessing import Pool

from PIL import Image

LABELS = {"/m/03bt1vf": "woman", "/m/04yx4": "man", "/m/05r655": "girl", "/m/01bl7v": "boy"}
FEMALE = {"woman", "girl"}
URL = "https://open-images-dataset.s3.amazonaws.com/{split}/{id}.jpg"
FRAME_LONG = 640  # the blur's screen frame (long side)
MARGIN = 0.25     # saved context around the box, each side, fraction of the box size
CROP_LONG = 256
MIN_W, MIN_H = 6, 10  # skip people smaller than this in the 640 frame (pixels)


def is_holdout(image_id):
    return int(hashlib.md5(image_id.encode()).hexdigest(), 16) % 100 == 0


def read_boxes(path):
    by_image = defaultdict(list)
    n = 0
    with open(path, newline="") as f:
        for r in csv.DictReader(f):
            lab = LABELS.get(r["LabelName"])
            if lab is None or r["IsGroupOf"] != "0":
                continue
            n += 1
            by_image[r["ImageID"]].append((lab, float(r["XMin"]), float(r["YMin"]), float(r["XMax"]), float(r["YMax"])))
    return by_image, n


def select(by_image, per_side, seed=0):
    ids = sorted(by_image)
    hold = [i for i in ids if is_holdout(i)]
    rest = [i for i in ids if not is_holdout(i)]
    random.Random(seed).shuffle(rest)
    nf = nm = 0
    train = []
    for i in rest:
        f = sum(b[0] in FEMALE for b in by_image[i])
        m = len(by_image[i]) - f
        if (f and nf < per_side) or (m and nm < per_side):
            train.append(i)
            nf += f
            nm += m
        if nf >= per_side and nm >= per_side:
            break
    return hold, train, nf, nm


def fetch(split, image_id, tries=3):
    for k in range(tries):
        try:
            with urllib.request.urlopen(URL.format(split=split, id=image_id), timeout=30) as r:
                return r.read()
        except Exception as e:  # noqa: BLE001 - network: retry, then give up on this image
            if k == tries - 1:
                print(f"skip {image_id}: {e}", file=sys.stderr)
                return None
            time.sleep(1 + 2 * k)


_G = {}


def _init(out, split, threads):
    _G.update(out=out, split=split, pool=ThreadPoolExecutor(threads))


def one(job):
    image_id, boxes, hold = job
    data = fetch(_G["split"], image_id)
    if data is None:
        return []
    try:
        im = Image.open(io.BytesIO(data))
        s = FRAME_LONG / max(im.size)
        W, H = max(1, round(im.size[0] * s)), max(1, round(im.size[1] * s))
        im.draft("RGB", (W, H))  # JPEG DCT downscale: faster decode, still >= the frame size
        im = im.convert("RGB").resize((W, H), Image.BILINEAR)
    except Exception as e:  # noqa: BLE001 - a broken image: skip it
        print(f"skip {image_id}: {e}", file=sys.stderr)
        return []
    rows = []
    sub = os.path.join(_G["out"], "crops", image_id[:2])
    os.makedirs(sub, exist_ok=True)
    for n, (lab, x0, y0, x1, y1) in enumerate(boxes):
        bx0, by0, bx1, by1 = x0 * W, y0 * H, x1 * W, y1 * H
        bw, bh = bx1 - bx0, by1 - by0
        if bw < MIN_W or bh < MIN_H:
            continue
        cx0, cy0 = max(0, int(bx0 - MARGIN * bw)), max(0, int(by0 - MARGIN * bh))
        cx1, cy1 = min(W, int(round(bx1 + MARGIN * bw))), min(H, int(round(by1 + MARGIN * bh)))
        c = im.crop((cx0, cy0, cx1, cy1))
        cw, ch = c.size
        k = CROP_LONG / max(cw, ch)
        if k < 1:
            c = c.resize((max(1, round(cw * k)), max(1, round(ch * k))), Image.BILINEAR)
        name = f"crops/{image_id[:2]}/{image_id}_{n}.jpg"
        c.save(os.path.join(_G["out"], name), quality=90)
        rows.append([image_id, lab, int(hold), f"{(bx0 - cx0) / cw:.4f}", f"{(by0 - cy0) / ch:.4f}",
                     f"{(bx1 - cx0) / cw:.4f}", f"{(by1 - cy0) / ch:.4f}", f"{bh / H:.4f}", name])
    return rows


def batch(jobs):
    return [r for rows in _G["pool"].map(one, jobs) for r in rows]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--split", default="train")
    ap.add_argument("--per-side", type=int, default=200000)
    ap.add_argument("--limit", type=int, default=0, help="max images in total (0 = no limit; for tests)")
    ap.add_argument("--max-minutes", type=float, default=0, help="stop fetching after this time (0 = no limit)")
    ap.add_argument("--procs", type=int, default=0, help="worker processes (default 2 x CPUs)")
    ap.add_argument("--threads", type=int, default=12, help="download threads per process")
    a = ap.parse_args()

    t0 = time.time()
    by_image, n = read_boxes(a.csv)
    hold, train, nf, nm = select(by_image, a.per_side)
    print(f"{n} boxes in {len(by_image)} images; holdout {len(hold)} images; train {len(train)} images "
          f"({nf} female, {nm} male boxes); parse {time.time() - t0:.0f} s", flush=True)
    jobs = [(i, by_image[i], True) for i in hold] + [(i, by_image[i], False) for i in train]
    if a.limit:
        jobs = [j for j in jobs if j[2]][: max(1, a.limit // 10)] + [j for j in jobs if not j[2]][: a.limit - max(1, a.limit // 10)]
    os.makedirs(os.path.join(a.out, "crops"), exist_ok=True)
    chunks = [jobs[k:k + 48] for k in range(0, len(jobs), 48)]
    t0, done, counts = time.time(), 0, defaultdict(int)
    with open(os.path.join(a.out, "index.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["image", "label", "holdout", "bx0", "by0", "bx1", "by1", "h_frame", "crop"])
        pool = Pool(a.procs or 2 * os.cpu_count(), _init, (a.out, a.split, a.threads))
        try:
            for rows in pool.imap(batch, chunks):  # in order: the holdout comes first and is complete
                w.writerows(rows)
                for r in rows:
                    counts[(r[1], r[2])] += 1
                done += 48
                if done % 4800 < 48:
                    f.flush()
                    print(f"{min(done, len(jobs))}/{len(jobs)} images, {sum(counts.values())} crops, "
                          f"{time.time() - t0:.0f} s", flush=True)
                if a.max_minutes and time.time() - t0 > a.max_minutes * 60:
                    print("time limit: stopping the fetch", flush=True)
                    break
        finally:
            pool.terminate()
    print("crops (label, holdout):", dict(counts), f"{time.time() - t0:.0f} s", flush=True)


if __name__ == "__main__":
    main()
