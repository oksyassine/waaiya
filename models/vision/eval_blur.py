"""End-to-end scorer for the screen blur, through the real C code (build/libimvision.so).

Open Images *validation* images (held out from training), resized like a phone capture (long side 640), each run
through im_vision_detect + one im_cover_update (margins). Ground truth: the annotators' Woman/Girl and Man/Boy boxes.

  women covered     share of woman/girl boxes with >= 90% of their area under covers (the number that matters)
  men left clear    share of man/boy boxes with < 10% under covers (what the user gets back)
  screen covered    mean share of the image under covers
  ms per frame      models + tracker, this machine

    make build/libimvision.so
    python models/vision/eval_blur.py --person models/vision/person_yolox_nano.onnx \
        [--gender models/vision/gender.onnx] [--limit 2000] [--male-clear 0.85] [--out eval/results/blur.md]
"""
import argparse
import csv
import os
import sys
import time
from collections import defaultdict

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imvision import WOMEN, Cover, Vision, load_rgba  # noqa: E402

FEMALE = {"/m/03bt1vf", "/m/05r655"}
MALE = {"/m/04yx4", "/m/01bl7v"}


def covered_fraction(box, rects, grid=24):
    """Share of the box under the union of rects (sampled on a grid)."""
    x0, y0, x1, y1 = box
    xs = x0 + (np.arange(grid) + 0.5) / grid * (x1 - x0)
    ys = y0 + (np.arange(grid) + 0.5) / grid * (y1 - y0)
    X, Y = np.meshgrid(xs, ys)
    m = np.zeros_like(X, bool)
    for r in rects:
        m |= (X >= r[0]) & (X <= r[2]) & (Y >= r[1]) & (Y <= r[3])
    return m.mean()


def main():
    ap = argparse.ArgumentParser()
    root = os.path.dirname(os.path.abspath(__file__))
    ap.add_argument("--person", required=True)
    ap.add_argument("--gender")
    ap.add_argument("--data", default=os.path.join(root, "data/openimages"))
    ap.add_argument("--limit", type=int, default=2000)
    ap.add_argument("--long-side", type=int, default=640)
    ap.add_argument("--male-clear", type=float)
    ap.add_argument("--person-score", type=float)
    ap.add_argument("--margin", type=float, help="cover margin, fraction of the person size")
    ap.add_argument("--threads", type=int, default=2)
    ap.add_argument("--out")
    a = ap.parse_args()

    gt = defaultdict(list)
    with open(os.path.join(a.data, "validation-annotations-bbox.csv"), newline="") as f:
        for r in csv.DictReader(f):
            if r["LabelName"] in FEMALE | MALE:
                gt[r["ImageID"]].append(("f" if r["LabelName"] in FEMALE else "m", r["IsGroupOf"] == "1",
                                         (float(r["XMin"]), float(r["YMin"]), float(r["XMax"]), float(r["YMax"]))))
    full = os.path.join(a.data, "crops/validation/full")
    ids = sorted(i for i in gt if os.path.exists(os.path.join(full, i + ".jpg")))[: a.limit]

    v = Vision(person=a.person, gender=a.gender, policy=WOMEN, threads=a.threads)
    if v.status:
        sys.exit("vision: " + v.error)
    kw = {}
    if a.male_clear is not None:
        kw["male_clear"] = a.male_clear
    if a.person_score is not None:
        kw["person_score"] = a.person_score
    prm = v.params(**kw)

    cover = Cover(covers_visible=False, **({"margin": a.margin} if a.margin is not None else {}))
    stats = defaultdict(lambda: [0, 0])  # key -> [hits, total]
    screen, times = [], []
    for k, i in enumerate(ids):
        rgba = load_rgba(os.path.join(full, i + ".jpg"), a.long_side)
        t = time.perf_counter()
        dets, _ = v.detect_raw(rgba, run_nsfw=False)
        rects = cover.update(0.0, rgba, dets)
        cover.reset()
        times.append((time.perf_counter() - t) * 1000)
        screen.append(covered_fraction((0, 0, 1, 1), rects, 32))
        for sex, group, box in gt[i]:
            frac = covered_fraction(box, rects)
            h = box[3] - box[1]
            size = "large" if h >= 0.3 else "medium" if h >= 0.1 else "small"
            tag = "group" if group else size
            if sex == "f":
                stats[("women covered", tag)][0] += frac >= 0.9
                stats[("women covered", tag)][1] += 1
                stats[("women covered", "all")][0] += frac >= 0.9
                stats[("women covered", "all")][1] += 1
            else:
                stats[("men left clear", tag)][0] += frac < 0.1
                stats[("men left clear", tag)][1] += 1
                stats[("men left clear", "all")][0] += frac < 0.1
                stats[("men left clear", "all")][1] += 1
        if (k + 1) % 250 == 0:
            w = stats[("women covered", "all")]
            print(f"{k + 1}/{len(ids)} women covered {w[0] / max(1, w[1]):.3f}", flush=True)

    lines = [f"# Screen blur, end to end ({len(ids)} Open Images validation images, long side {a.long_side})", "",
             f"- person model: `{os.path.basename(a.person)}`; gender model: "
             f"`{os.path.basename(a.gender) if a.gender else 'none (every person covered)'}`",
             f"- params: person_score {prm['person_score']:.2f}, male_clear {prm['male_clear']:.2f}, "
             f"nms {prm['nms_iou']:.2f}, margin {cover.params()['margin']:.2f}", "",
             "| measure | all | large (h>=30%) | medium (10-30%) | small (<10%) | group boxes |", "|---|---|---|---|---|---|"]
    for what in ("women covered", "men left clear"):
        cells = []
        for tag in ("all", "large", "medium", "small", "group"):
            h_, n_ = stats[(what, tag)]
            cells.append(f"{h_ / n_:.1%} ({n_})" if n_ else "-")
        lines.append(f"| {what} | " + " | ".join(cells) + " |")
    lines += ["", f"- screen covered: mean {np.mean(screen):.1%}",
              f"- time per frame (models + tracker, {a.threads} threads, this machine): median "
              f"{np.median(times):.1f} ms, p95 {np.percentile(times, 95):.1f} ms"]
    text = "\n".join(lines)
    print(text)
    if a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
        with open(a.out, "w") as f:
            f.write(text + "\n")


if __name__ == "__main__":
    main()
