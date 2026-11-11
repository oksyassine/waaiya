"""Open Images V7 person masks (validation + test splits, CC BY 4.0) for the silhouette-cover scorer (eval_silhouette.py).

Keeps, under --out (default models/vision/data/oi_seg, gitignored):
  <split>-annotations-object-segmentation.csv     the official mask index (downloaded)
  zips/<split>-masks-<c>.zip                      the official mask archives (downloaded, ~220 MB for both splits)
  <split>/masks/<MaskPath>                        the masks of person-like classes only (Person, Man, Woman, Boy, Girl)
  <split>/full/<ImageID>.jpg                      the images that have such a mask, long side <= 960
  <split>/boxes.csv                               every person-like *box* of those images (bbox annotations): people
                                                  without a mask are excluded from the "background" pixels
Only the standard Open Images V7 boxes and masks are used (never the MIAP extension).

    python models/vision/fetch_oi_masks.py --bbox-dir models/vision/data/openimages [--reuse-full DIR]
"""
import argparse
import csv
import io
import os
import shutil
import sys
import time
import urllib.request
import zipfile
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor

from PIL import Image

PERSONLIKE = {"/m/01g317": "person", "/m/04yx4": "man", "/m/03bt1vf": "woman", "/m/01bl7v": "boy", "/m/05r655": "girl"}
BASE = "https://storage.googleapis.com/openimages/v5/"
IMG = "https://open-images-dataset.s3.amazonaws.com/{split}/{id}.jpg"
FULL_LONG = 960


def get(url, dst=None, tries=3):
    for i in range(tries):
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                data = r.read()
            if dst:
                with open(dst + ".part", "wb") as f:
                    f.write(data)
                os.replace(dst + ".part", dst)
            return data
        except Exception as e:  # noqa: BLE001 - network: retry, then give up
            if i == tries - 1:
                print(f"skip {url}: {e}", file=sys.stderr)
                return None
            time.sleep(1 + 2 * i)


def main():
    ap = argparse.ArgumentParser()
    root = os.path.dirname(os.path.abspath(__file__))
    ap.add_argument("--out", default=os.path.join(root, "data/oi_seg"))
    ap.add_argument("--bbox-dir", default=os.path.join(root, "data/openimages"),
                    help="where <split>-annotations-bbox.csv are (fetch_openimages.py downloads them)")
    ap.add_argument("--reuse-full", action="append", default=[],
                    help="directory of already fetched whole images <id>.jpg (long side <= 960) to copy from")
    ap.add_argument("--splits", default="validation,test")
    ap.add_argument("--workers", type=int, default=16)
    a = ap.parse_args()
    os.makedirs(os.path.join(a.out, "zips"), exist_ok=True)

    for split in a.splits.split(","):
        seg_csv = os.path.join(a.out, f"{split}-annotations-object-segmentation.csv")
        if not os.path.exists(seg_csv):
            get(BASE + f"{split}-annotations-object-segmentation.csv", seg_csv)
        rows = [r for r in csv.DictReader(open(seg_csv, newline="")) if r["LabelName"] in PERSONLIKE]
        ids = sorted({r["ImageID"] for r in rows})
        print(f"{split}: {len(rows)} person-like masks on {len(ids)} images", flush=True)

        # masks
        mdir = os.path.join(a.out, split, "masks")
        os.makedirs(mdir, exist_ok=True)
        want = defaultdict(set)
        for r in rows:
            if not os.path.exists(os.path.join(mdir, r["MaskPath"])):
                want[r["MaskPath"][0]].add(r["MaskPath"])
        for c, names in sorted(want.items()):
            z = os.path.join(a.out, "zips", f"{split}-masks-{c}.zip")
            if not os.path.exists(z):
                get(BASE + f"{split}-masks/{split}-masks-{c}.zip", z)
            with zipfile.ZipFile(z) as zf:
                for n in names:
                    with zf.open(n) as src, open(os.path.join(mdir, n), "wb") as dst:
                        shutil.copyfileobj(src, dst)

        # person-like boxes of those images
        idset = set(ids)
        with open(os.path.join(a.bbox_dir, f"{split}-annotations-bbox.csv"), newline="") as f, \
                open(os.path.join(a.out, split, "boxes.csv"), "w", newline="") as g:
            w = csv.writer(g)
            w.writerow(["ImageID", "label", "XMin", "XMax", "YMin", "YMax", "IsGroupOf"])
            for r in csv.DictReader(f):
                if r["ImageID"] in idset and r["LabelName"] in PERSONLIKE:
                    w.writerow([r["ImageID"], PERSONLIKE[r["LabelName"]], r["XMin"], r["XMax"], r["YMin"], r["YMax"],
                                r["IsGroupOf"]])

        # images
        fdir = os.path.join(a.out, split, "full")
        os.makedirs(fdir, exist_ok=True)

        def one(i):
            dst = os.path.join(fdir, i + ".jpg")
            if os.path.exists(dst):
                return 1
            for d in a.reuse_full:
                if os.path.exists(os.path.join(d, i + ".jpg")):
                    shutil.copyfile(os.path.join(d, i + ".jpg"), dst)
                    return 1
            data = get(IMG.format(split=split, id=i))
            if data is None:
                return 0
            im = Image.open(io.BytesIO(data)).convert("RGB")
            s = FULL_LONG / max(im.size)
            if s < 1:
                im = im.resize((round(im.size[0] * s), round(im.size[1] * s)), Image.BILINEAR)
            im.save(dst + ".part.jpg", quality=90)
            os.replace(dst + ".part.jpg", dst)
            return 1

        with ThreadPoolExecutor(a.workers) as ex:
            got = sum(ex.map(one, ids))
        print(f"{split}: {got}/{len(ids)} images", flush=True)


if __name__ == "__main__":
    main()
