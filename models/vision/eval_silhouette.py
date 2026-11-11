"""Silhouette covers (person outlines as strips) against today's rectangles, through the real C code
(build/libimvision.so), on Open Images V7 person *masks* (fetch_oi_masks.py; validation to tune, test to report).

Each image is resized like a phone capture (long side 640) and run once through im_vision_detect_shapes; the same
detections then go through im_cover_update twice: without outlines (today's rectangles: margin 0.20, groups joined
by merge_gap) and with them (strips, bridges). Pixel measures, over all images:

  woman px covered      share of Woman/Girl mask pixels under a cover (the number that must not drop)
  woman >= 99% / 95%    share of Woman/Girl masks with at least that much of their pixels covered
  man px covered        share of Man/Boy mask pixels covered (lower = more of men left visible)
  background covered    share of non-person pixels covered inside and around the women (their boxes widened by
                        50% of their size on each side); person-like boxes without a mask are left out, since
                        Open Images masks only some of the people in an image
  screen covered        mean share of the frame covered
  seg ms / person       segmenter time per outlined person (detect with outlines - without, this machine, --threads)

    make build/libimvision.so
    python models/vision/eval_silhouette.py --seg models/vision/seg.onnx --split validation \
        [--seg-threshold 0.25 0.4] [--seg-min-fill 0.25] [--strip-margin 0.05] [--bridge-gap 0 0.3]
        [--open-reach 0.2 0.5] [--limit 0]
        [--md eval/results/x.md]
"""
import argparse
import csv
import itertools
import os
import sys
import time
from collections import defaultdict

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imvision import WOMEN, Cover, Vision, load_rgba  # noqa: E402

ROOT = os.path.dirname(os.path.abspath(__file__))
FEMALE = {"/m/03bt1vf", "/m/05r655"}
MALE = {"/m/04yx4", "/m/01bl7v"}


def paint(rects, W, H):
    m = np.zeros((H, W), bool)
    for r in rects:
        x0, y0 = max(0, int(np.floor(r[0] * W))), max(0, int(np.floor(r[1] * H)))
        x1, y1 = min(W, int(np.ceil(r[2] * W))), min(H, int(np.ceil(r[3] * H)))
        m[y0:y1, x0:x1] = True
    return m


class Acc:
    def __init__(self):
        self.s = defaultdict(float)
        self.inst = defaultdict(list)

    def add(self, cov, gt):
        W = cov.shape[1]
        H = cov.shape[0]
        s = self.s
        s["w_px"] += gt["woman"].sum()
        s["w_cov"] += (gt["woman"] & cov).sum()
        s["m_px"] += gt["man"].sum()
        s["m_cov"] += (gt["man"] & cov).sum()
        s["bg_px"] += gt["bg"].sum()
        s["bg_cov"] += (gt["bg"] & cov).sum()
        s["screen"] += cov.mean()
        s["n"] += 1
        for size, m in gt["women"]:
            n = m.sum()
            if n:
                self.inst[size].append((m & cov).sum() / n)
        del W, H

    def row(self):
        s, all_ = self.s, [x for v in self.inst.values() for x in v]
        a = np.array(all_)
        r = {"woman px covered": s["w_cov"] / max(1, s["w_px"]), "woman >= 99%": (a >= 0.99).mean(),
             "woman >= 95%": (a >= 0.95).mean(), "man px covered": s["m_cov"] / max(1, s["m_px"]),
             "background covered": s["bg_cov"] / max(1, s["bg_px"]), "screen covered": s["screen"] / max(1, s["n"]),
             "women": len(a)}
        for size in ("large", "medium", "small"):
            v = np.array(self.inst.get(size, []))
            r[f"{size} px"] = v.mean() if len(v) else float("nan")
            r[f"{size} n"] = len(v)
        return r


def read_gt(data, split):
    rows = defaultdict(list)
    with open(os.path.join(data, f"{split}-annotations-object-segmentation.csv"), newline="") as f:
        for r in csv.DictReader(f):
            if r["LabelName"] in FEMALE | MALE | {"/m/01g317"}:
                rows[r["ImageID"]].append(r)
    boxes = defaultdict(list)
    with open(os.path.join(data, split, "boxes.csv"), newline="") as f:
        for r in csv.DictReader(f):
            boxes[r["ImageID"]].append(tuple(float(r[k]) for k in ("XMin", "YMin", "XMax", "YMax")))
    return rows, boxes


def image_gt(data, split, rows, boxes, W, H):
    def mask(r):
        m = Image.open(os.path.join(data, split, "masks", r["MaskPath"])).convert("L").resize((W, H), Image.BILINEAR)
        return np.asarray(m) >= 128

    gt = {"woman": np.zeros((H, W), bool), "man": np.zeros((H, W), bool), "women": []}
    person = np.zeros((H, W), bool)
    region = np.zeros((H, W), bool)
    masked = []
    for r in rows:
        m = mask(r)
        person |= m
        b = tuple(float(r[k]) for k in ("BoxXMin", "BoxYMin", "BoxXMax", "BoxYMax"))
        masked.append(b)
        if r["LabelName"] in FEMALE:
            gt["woman"] |= m
            h = b[3] - b[1]
            gt["women"].append(("large" if h >= 0.3 else "medium" if h >= 0.1 else "small", m))
            bw, bh = b[2] - b[0], b[3] - b[1]
            region |= paint([(b[0] - 0.5 * bw, b[1] - 0.5 * bh, b[2] + 0.5 * bw, b[3] + 0.5 * bh)], W, H)
        elif r["LabelName"] in MALE:
            gt["man"] |= m
    unknown = paint([b for b in boxes if not any(max(abs(b[i] - q[i]) for i in range(4)) < 0.01 for q in masked)],
                    W, H)
    gt["bg"] = region & ~person & ~unknown
    return gt


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--person", default=os.path.join(ROOT, "person_yolox_nano.onnx"))
    ap.add_argument("--gender", default=os.path.join(ROOT, "gender_v2.onnx"))
    ap.add_argument("--seg", required=True)
    ap.add_argument("--data", default=os.path.join(ROOT, "data/oi_seg"))
    ap.add_argument("--split", default="validation")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--long-side", type=int, default=640)
    ap.add_argument("--threads", type=int, default=1)
    ap.add_argument("--timing-images", type=int, default=300, help="images also run without outlines, for the time")
    ap.add_argument("--seg-threshold", type=float, nargs="+", default=[0.25])
    ap.add_argument("--seg-min-fill", type=float, nargs="+", default=[0.25])
    ap.add_argument("--seg-min-px", type=int, help="people shorter than this keep their rectangle (default: engine)")
    ap.add_argument("--strip-margin", type=float, nargs="+", default=[0.05])
    ap.add_argument("--bridge-gap", type=float, nargs="+", default=[0.3])
    ap.add_argument("--open-reach", type=float, nargs="+", default=[0.8])
    ap.add_argument("--md")
    a = ap.parse_args()

    rows, boxes = read_gt(a.data, a.split)
    ids = sorted(i for i, rs in rows.items() if any(r["LabelName"] in FEMALE for r in rs))
    if a.limit:
        ids = ids[: a.limit]
    v = Vision(person=a.person, gender=a.gender, seg=a.seg, policy=WOMEN, threads=a.threads)
    if v.status:
        sys.exit("vision: " + v.error)
    base = v.params(**({"seg_min_px": a.seg_min_px} if a.seg_min_px is not None else {}))
    rect_cover = Cover(covers_visible=False)
    vis_cfgs = list(itertools.product(a.seg_threshold, a.seg_min_fill))
    cov_cfgs = list(itertools.product(a.strip_margin, a.bridge_gap, a.open_reach))
    acc = defaultdict(Acc)
    fallback = defaultdict(lambda: [0, 0])
    t_seg, n_seg, t_base = [], 0, []
    t0 = time.time()
    for k, i in enumerate(ids):
        rgba = load_rgba(os.path.join(a.data, a.split, "full", i + ".jpg"), a.long_side)
        H, W = rgba.shape[:2]
        gt = image_gt(a.data, a.split, rows[i], boxes[i], W, H)
        if k < a.timing_images:
            v.params(seg=0)
            t = time.perf_counter()
            d0, _ = v.detect_shapes(rgba, run_nsfw=False)
            t_base.append(time.perf_counter() - t)
        for vc in vis_cfgs:
            v.params(seg=1, seg_threshold=vc[0], seg_min_fill=vc[1])
            t = time.perf_counter()
            dets, shapes = v.detect_shapes(rgba, run_nsfw=False)
            dt = time.perf_counter() - t
            # the people the segmenter ran on: covered, among the max_people largest, tall enough, the first seg_max_people
            covered = [j for j, d in enumerate(dets) if d.kind in (1, 2) and j < base["max_people"]
                       and (d.y1 - d.y0) * H >= base["seg_min_px"]]
            covered = covered[: base["seg_max_people"]]
            if k < a.timing_images and vc == vis_cfgs[0]:
                t_seg.append(dt - t_base[-1])
                n_seg += len(covered)
            fallback[vc][0] += sum(shapes[j].rows == 0 for j in covered)
            fallback[vc][1] += len(covered)
            if vc == vis_cfgs[0]:
                acc["rect"].add(paint(rect_cover.update(0.0, rgba, dets), W, H), gt)
                rect_cover.reset()
            for cc in cov_cfgs:
                c = Cover(covers_visible=False, strip_margin=cc[0], bridge_gap=cc[1], open_reach=cc[2])
                acc[vc + cc].add(paint(c.update(0.0, rgba, dets, shapes), W, H), gt)
        if (k + 1) % 200 == 0:
            print(f"{k + 1}/{len(ids)} images, {time.time() - t0:.0f} s", flush=True)

    cols = ["woman px covered", "woman >= 99%", "woman >= 95%", "large px", "medium px", "small px", "man px covered",
            "background covered", "screen covered"]
    r0 = acc["rect"].row()
    lines = [f"Open Images V7 **{a.split}**, {len(ids)} images with {r0['women']} Woman/Girl masks "
             f"(large {r0['large n']}, medium {r0['medium n']}, small {r0['small n']}; size = box height / image), "
             f"long side {a.long_side}. Detector `{os.path.basename(a.person)}`, classifier "
             f"`{os.path.basename(a.gender)}` (male_clear {base['male_clear']:g}), segmenter `{os.path.basename(a.seg)}`.",
             "", "| covers | " + " | ".join(cols) + " | outline not trusted |",
             "|---" * (len(cols) + 2) + "|"]

    def fmt(r):
        return " | ".join(f"{r[c]:.2%}" if c not in ("woman >= 99%", "woman >= 95%") else f"{r[c]:.1%}" for c in cols)

    lines.append(f"| rectangles (today: margin 0.20, merge_gap 0.30) | {fmt(r0)} | - |")
    for vc in vis_cfgs:
        fb = fallback[vc]
        for cc in cov_cfgs:
            r = acc[vc + cc].row()
            lines.append(f"| strips: threshold {vc[0]:g}, min fill {vc[1]:g}, strip margin {cc[0]:g}, "
                         f"bridge_gap {cc[1]:g}, open_reach {cc[2]:g} | {fmt(r)} | {fb[0] / max(1, fb[1]):.1%} of {fb[1]} |")
    if t_seg:
        lines += ["", f"- segmenter time per outlined person ({a.threads} thread{'s' if a.threads > 1 else ''}, "
                      f"this machine, {min(len(ids), a.timing_images)} images): "
                      f"{1000 * sum(t_seg) / max(1, n_seg):.1f} ms ({n_seg} people); detect without outlines: median "
                      f"{1000 * np.median(t_base):.1f} ms per frame"]
    text = "\n".join(lines)
    print(text)
    if a.md:
        os.makedirs(os.path.dirname(os.path.abspath(a.md)), exist_ok=True)
        with open(a.md, "w") as f:
            f.write(text + "\n")


if __name__ == "__main__":
    main()
