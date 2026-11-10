"""Person crops from Open Images V7 for the woman/man classifier (boxes: CC BY 4.0, images: listed as CC BY 2.0).

Reads the box CSV of one split, keeps Woman / Man / Girl / Boy boxes (not group boxes), downloads each image once
from the public open-images-dataset bucket, and writes crops with some context around the box:

    <out>/<split>/<label>/<imageid>_<n>.jpg   (long side <= 256 px)
    <out>/<split>/index.csv                   image, label, box, occluded/truncated/depiction flags, crop file

`--full` also keeps the whole images (resized, long side <= 960) for the end-to-end scorer (eval_blur.py).
Resumable: images already done are skipped.
"""
import argparse
import csv
import io
import os
import sys
import time
import urllib.request
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor

from PIL import Image

LABELS = {"/m/03bt1vf": "woman", "/m/04yx4": "man", "/m/05r655": "girl", "/m/01bl7v": "boy"}
PERSON = "/m/01g317"
URL = "https://open-images-dataset.s3.amazonaws.com/{split}/{id}.jpg"
CONTEXT = 0.10  # extra margin on each side, as a fraction of the box size
CROP_LONG = 256
FULL_LONG = 960


def read_boxes(csv_path, keep_person=False):
    by_image = defaultdict(list)
    with open(csv_path, newline="") as f:
        for r in csv.DictReader(f):
            lab = r["LabelName"]
            if lab in LABELS or (keep_person and lab == PERSON):
                by_image[r["ImageID"]].append(r)
    return by_image


def fetch(split, image_id, tries=3):
    for i in range(tries):
        try:
            with urllib.request.urlopen(URL.format(split=split, id=image_id), timeout=30) as r:
                return r.read()
        except Exception as e:  # noqa: BLE001 - network: retry, then give up on this image
            if i == tries - 1:
                print(f"skip {image_id}: {e}", file=sys.stderr)
                return None
            time.sleep(1 + 2 * i)


def crop_box(img, r):
    w, h = img.size
    x0, x1 = float(r["XMin"]) * w, float(r["XMax"]) * w
    y0, y1 = float(r["YMin"]) * h, float(r["YMax"]) * h
    bw, bh = x1 - x0, y1 - y0
    x0, x1 = max(0, x0 - CONTEXT * bw), min(w, x1 + CONTEXT * bw)
    y0, y1 = max(0, y0 - CONTEXT * bh), min(h, y1 + CONTEXT * bh)
    c = img.crop((int(x0), int(y0), int(round(x1)), int(round(y1))))
    s = CROP_LONG / max(c.size)
    if s < 1:
        c = c.resize((max(1, round(c.size[0] * s)), max(1, round(c.size[1] * s))), Image.BILINEAR)
    return c


def work(args, split, image_id, rows):
    out = os.path.join(args.out, split)
    done_flag = os.path.join(out, "done", image_id)
    if os.path.exists(done_flag):
        return []
    data = fetch(split, image_id)
    if data is None:
        return []
    img = Image.open(io.BytesIO(data)).convert("RGB")
    lines = []
    if args.full:
        f = img.copy()
        s = FULL_LONG / max(f.size)
        if s < 1:
            f = f.resize((round(f.size[0] * s), round(f.size[1] * s)), Image.BILINEAR)
        f.save(os.path.join(out, "full", image_id + ".jpg"), quality=90)
    for n, r in enumerate(rows):
        if r["LabelName"] not in LABELS or r["IsGroupOf"] == "1":
            continue
        w = (float(r["XMax"]) - float(r["XMin"])) * img.size[0]
        h = (float(r["YMax"]) - float(r["YMin"])) * img.size[1]
        if min(w, h) < args.min_px:
            continue
        lab = LABELS[r["LabelName"]]
        name = f"{lab}/{image_id}_{n}.jpg"
        crop_box(img, r).save(os.path.join(out, name), quality=92)
        lines.append([image_id, lab, r["XMin"], r["XMax"], r["YMin"], r["YMax"],
                      r["IsOccluded"], r["IsTruncated"], r["IsDepiction"], name])
    open(done_flag, "w").close()
    return lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True, help="<split>-annotations-bbox.csv")
    ap.add_argument("--split", required=True, choices=["train", "validation", "test"])
    ap.add_argument("--out", required=True)
    ap.add_argument("--limit", type=int, default=0, help="max images (0 = all)")
    ap.add_argument("--min-px", type=int, default=12, help="skip boxes smaller than this (original pixels)")
    ap.add_argument("--full", action="store_true", help="also keep whole images for the end-to-end scorer")
    ap.add_argument("--workers", type=int, default=24)
    args = ap.parse_args()

    by_image = read_boxes(args.csv)
    ids = sorted(i for i, rows in by_image.items() if any(r["LabelName"] in LABELS for r in rows))
    if args.limit:
        ids = ids[: args.limit]
    out = os.path.join(args.out, args.split)
    for d in list(set(LABELS.values())) + ["done"] + (["full"] if args.full else []):
        os.makedirs(os.path.join(out, d), exist_ok=True)
    index = os.path.join(out, "index.csv")
    new = not os.path.exists(index)
    t0, n_done = time.time(), 0
    with open(index, "a", newline="") as f, ThreadPoolExecutor(args.workers) as ex:
        w = csv.writer(f)
        if new:
            w.writerow(["image", "label", "xmin", "xmax", "ymin", "ymax", "occluded", "truncated", "depiction", "crop"])
        for lines in ex.map(lambda i: work(args, args.split, i, by_image[i]), ids):
            w.writerows(lines)
            n_done += 1
            if n_done % 500 == 0:
                f.flush()
                print(f"{n_done}/{len(ids)} images, {time.time() - t0:.0f} s", flush=True)
    print(f"done: {len(ids)} images in {time.time() - t0:.0f} s")


if __name__ == "__main__":
    main()
