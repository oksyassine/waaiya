"""Diagnostics for the screen blur's woman/man classifier, through the real C code (build/libimvision.so).

One pass over the Open Images *validation* images (held out from every classifier we train) records, per
ground-truth Woman/Man/Girl/Boy box, the share covered at each male_clear threshold, plus every detection's
p(male). Then:

  run      python models/vision/blur_diag.py run --gender models/vision/gender.onnx --layout photo --out X.npz
             --layout photo     the image itself, long side 640 (what eval_blur.py measures)
             --layout portrait  the image letterboxed into a centred 16:9 strip of a 1080x2340 portrait screen,
                                the whole screen scaled to long side 640 (a phone held upright, video in an app)
  report   python models/vision/blur_diag.py report X.npz [Y.npz ...] [--md out.md]
             end-to-end coverage, male_clear chosen on the tuning half, reported on the other half
  crops    python models/vision/blur_diag.py crops --gender models/vision/gender.onnx
             classifier alone on three crop kinds of the same people: annotator crops (fetch_openimages.py),
             annotator boxes cut from the 640-px frame, and YOLOX-Nano boxes (IoU >= 0.5) from the 640-px frame

Halves: an image is in the tuning half when md5(image id) is even, else in the reporting half.
"""
import argparse
import csv
import hashlib
import json
import os
import sys
import time
from collections import defaultdict

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imvision import Cover, Vision, WOMEN  # noqa: E402

ROOT = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(ROOT, "data/openimages")
FEMALE = {"/m/03bt1vf", "/m/05r655"}
MALE = {"/m/04yx4", "/m/01bl7v"}
NAMES = {"/m/03bt1vf": "woman", "/m/04yx4": "man", "/m/05r655": "girl", "/m/01bl7v": "boy"}
THRESH = [0.5, 0.7, 0.8, 0.85, 0.9, 0.93, 0.95, 0.96, 0.97, 0.98, 0.985, 0.99, 0.995, 0.998, 0.999, 0.9995, 0.9999]
CLEAR, WOMAN, UNSURE = 0, 1, 2


def half(image_id):
    return "tune" if int(hashlib.md5(image_id.encode()).hexdigest(), 16) % 2 == 0 else "report"


def read_gt(data=DATA):
    gt = defaultdict(list)
    with open(os.path.join(data, "validation-annotations-bbox.csv"), newline="") as f:
        for r in csv.DictReader(f):
            if r["LabelName"] in NAMES:
                gt[r["ImageID"]].append((NAMES[r["LabelName"]], r["IsGroupOf"] == "1",
                                         tuple(float(r[k]) for k in ("XMin", "YMin", "XMax", "YMax"))))
    return gt


def frame(path, layout, long_side=640):
    """RGBA uint8 frame and the mapping of image-normalised boxes into frame-normalised boxes."""
    im = Image.open(path).convert("RGB")
    if layout == "photo":
        s = long_side / max(im.size)
        im = im.resize((round(im.size[0] * s), round(im.size[1] * s)), Image.BILINEAR)
        a = np.asarray(im)
        return np.concatenate([a, np.full(a.shape[:2] + (1,), 255, np.uint8)], 2), lambda b: b
    # portrait phone 1080x2340 scaled to long side 640, centred 16:9 video strip, image letterboxed in the strip
    H = long_side
    W = round(1080 * H / 2340)
    sh = W * 9 / 16
    s = min(W / im.size[0], sh / im.size[1])
    iw, ih = max(1, round(im.size[0] * s)), max(1, round(im.size[1] * s))
    ox, oy = (W - iw) // 2, round((H - sh) / 2 + (sh - ih) / 2)
    canvas = Image.new("RGB", (W, H), (24, 24, 24))  # app chrome around the strip (dark theme)
    strip = Image.new("RGB", (W, round(sh)), (0, 0, 0))
    canvas.paste(strip, (0, round((H - sh) / 2)))
    canvas.paste(im.resize((iw, ih), Image.BILINEAR), (ox, oy))
    a = np.asarray(canvas)
    rgba = np.concatenate([a, np.full(a.shape[:2] + (1,), 255, np.uint8)], 2)

    def mp(b):
        return ((ox + b[0] * iw) / W, (oy + b[1] * ih) / H, (ox + b[2] * iw) / W, (oy + b[3] * ih) / H)
    return rgba, mp


def covered_fraction(box, rects, grid=24):
    x0, y0, x1, y1 = box
    xs = x0 + (np.arange(grid) + 0.5) / grid * (x1 - x0)
    ys = y0 + (np.arange(grid) + 0.5) / grid * (y1 - y0)
    X, Y = np.meshgrid(xs, ys)
    m = np.zeros_like(X, bool)
    for r in rects:
        m |= (X >= r[0]) & (X <= r[2]) & (Y >= r[1]) & (Y <= r[3])
    return m.mean()


def iou(a, b):
    ix, iy = min(a[2], b[2]) - max(a[0], b[0]), min(a[3], b[3]) - max(a[1], b[1])
    if ix <= 0 or iy <= 0:
        return 0.0
    i = ix * iy
    return i / ((a[2] - a[0]) * (a[3] - a[1]) + (b[2] - b[0]) * (b[3] - b[1]) - i)


def match(gt_boxes, det_boxes, thr=0.5):
    """Greedy one-to-one IoU matching; returns {gt index: det index}."""
    pairs = sorted(((iou(g, d), i, j) for i, g in enumerate(gt_boxes) for j, d in enumerate(det_boxes)), reverse=True)
    out, used = {}, set()
    for v, i, j in pairs:
        if v < thr:
            break
        if i not in out and j not in used:
            out[i] = j
            used.add(j)
    return out


def cmd_run(a):
    gt = read_gt(a.data)
    full = os.path.join(a.data, "crops/validation/full")
    ids = sorted(i for i in gt if os.path.exists(os.path.join(full, i + ".jpg")))
    if a.limit:
        ids = ids[: a.limit]
    v = Vision(person=a.person, gender=a.gender, policy=WOMEN, threads=a.threads)
    if v.status:
        sys.exit("vision: " + v.error)
    v.params(male_clear=0.5, **({"tiles": a.tiles} if a.tiles is not None else {}))  # kinds: recomputed below
    cover = Cover(covers_visible=False)
    rec = defaultdict(list)
    t0 = time.time()
    for k, i in enumerate(ids):
        rgba, mp = frame(os.path.join(full, i + ".jpg"), a.layout, a.long_side)
        dets, _ = v.detect_raw(rgba, run_nsfw=False)
        dets = [type(d).from_buffer_copy(d) for d in dets]
        pm = [d.p_male for d in dets]
        boxes = [mp(b) for _, _, b in gt[i]]
        m = match(boxes, [(d.x0, d.y0, d.x1, d.y1) for d in dets])
        male_dets = {m[b] for b, (lab, _, _) in enumerate(gt[i]) if b in m and lab in ("man", "boy")}
        # columns: every person covered, each threshold, then the oracle (a perfect classifier: detections
        # matched to a man/boy box are cleared, every other detection is covered)
        fr = np.zeros((len(boxes), len(THRESH) + 2), np.float32)
        for c, t in enumerate([None] + THRESH + ["oracle"]):
            for j, (d, p) in enumerate(zip(dets, pm)):
                if t == "oracle":
                    d.kind = CLEAR if j in male_dets else UNSURE
                else:
                    d.kind = UNSURE if (t is None or p < 0) else CLEAR if p >= t else WOMAN if p <= 1 - t else UNSURE
            rects = cover.update(0.0, rgba, dets)
            cover.reset()
            for b, box in enumerate(boxes):
                fr[b, c] = covered_fraction(box, rects)
        for b, (lab, grp, box) in enumerate(gt[i]):
            rec["image"].append(i)
            rec["label"].append(lab)
            rec["group"].append(grp)
            rec["h"].append(boxes[b][3] - boxes[b][1])
            rec["h_img"].append(box[3] - box[1])
            rec["frac"].append(fr[b])
            rec["p_det"].append(pm[m[b]] if b in m else -2.0)
        if (k + 1) % 500 == 0:
            print(f"{k + 1}/{len(ids)} {time.time() - t0:.0f} s", flush=True)
    np.savez_compressed(a.out, image=np.array(rec["image"]), label=np.array(rec["label"]),
                        group=np.array(rec["group"]), h=np.array(rec["h"], np.float32),
                        h_img=np.array(rec["h_img"], np.float32), frac=np.stack(rec["frac"]),
                        p_det=np.array(rec["p_det"], np.float32), thresh=np.array(THRESH),
                        meta=json.dumps({"layout": a.layout, "tiles": v.params()["tiles"], "long_side": a.long_side, "gender": os.path.basename(a.gender or ""),
                                         "person": os.path.basename(a.person), "n_images": len(ids)}))
    print("wrote", a.out)


def rates(d, sel, col):
    f = np.isin(d["label"], ["woman", "girl"]) & sel
    m = np.isin(d["label"], ["man", "boy"]) & sel
    fr = d["frac"][:, col]
    return float((fr[f] >= 0.9).mean()), float((fr[m] < 0.1).mean()), int(f.sum()), int(m.sum())


def choose(d, sel, max_loss):
    """Largest men-left-clear threshold whose women-covered loss vs every-person-covered is <= max_loss."""
    w0 = rates(d, sel, 0)[0]
    best = None
    for c, t in enumerate(d["thresh"], 1):
        w, mc, _, _ = rates(d, sel, c)
        if w0 - w <= max_loss + 1e-9 and (best is None or mc > best[2]):
            best = (float(t), c, mc)
    return best


def cmd_report(a):
    lines = []
    for path in a.npz:
        d = dict(np.load(path))
        meta = json.loads(str(d["meta"]))
        hv = np.array([half(i) for i in d["image"]])
        tune, rep = hv == "tune", hv == "report"
        lines += [f"## {meta['gender'] or 'no gender model'}, layout {meta['layout']}, long side {meta.get('long_side', 640)}, "
                  f"tiles {meta.get('tiles', 0)} ({meta['n_images']} images)", ""]
        size = np.where(d["h_img"] >= 0.3, "large", np.where(d["h_img"] >= 0.1, "medium", "small"))  # height in the image
        lines += ["| measure (all images) | all | large (h>=30% of image) | medium | small (<10%) | group |", "|---|---|---|---|---|---|"]
        for c, name in [(0, "every person covered")] + [(list(d["thresh"]).index(0.98) + 1, "male_clear 0.98")]:
            row_w, row_m = [], []
            for tag in ("all", "large", "medium", "small", "group"):
                sel = np.ones(len(hv), bool) if tag == "all" else d["group"] if tag == "group" else (~d["group"]) & (size == tag)
                w, mc, nf, nm = rates(d, sel, c)
                row_w.append(f"{w:.1%} ({nf})")
                row_m.append(f"{mc:.1%} ({nm})")
            lines.append(f"| women covered, {name} | " + " | ".join(row_w) + " |")
            lines.append(f"| men left clear, {name} | " + " | ".join(row_m) + " |")
        lines += ["", "| rule (chosen on tuning half) | male_clear | tune: women / men clear | report: women / men clear |",
                  "|---|---|---|---|"]
        w0t, m0t, _, _ = rates(d, tune, 0)
        w0r, m0r, nf, nm = rates(d, rep, 0)
        lines.append(f"| every person covered | - | {w0t:.1%} / {m0t:.1%} | {w0r:.1%} / {m0r:.1%} |")
        if d["frac"].shape[1] == len(d["thresh"]) + 2:
            co = len(d["thresh"]) + 1
            wt, mt, _, _ = rates(d, tune, co)
            wr, mr, _, _ = rates(d, rep, co)
            lines.append(f"| perfect classifier (oracle) | - | {wt:.1%} / {mt:.1%} | {wr:.1%} / {mr:.1%} |")
        for loss in (0.0025, 0.005, 0.01):
            b = choose(d, tune, loss)
            if b is None:
                continue
            t, c, _ = b
            wt, mt, _, _ = rates(d, tune, c)
            wr, mr, _, _ = rates(d, rep, c)
            lines.append(f"| women loss <= {loss * 100:.2g} pt | {t} | {wt:.1%} / {mt:.1%} | {wr:.1%} / {mr:.1%} |")
        c98 = list(d["thresh"]).index(0.98) + 1
        wt, mt, _, _ = rates(d, tune, c98)
        wr, mr, _, _ = rates(d, rep, c98)
        lines.append(f"| fixed default | 0.98 | {wt:.1%} / {mt:.1%} | {wr:.1%} / {mr:.1%} |")
        lines += ["", f"reporting half: {nf} woman/girl boxes, {nm} man/boy boxes", ""]
        # full sweep on the reporting half
        lines += ["| male_clear | tune women / men | report women / men |", "|---|---|---|"]
        for c, t in enumerate(d["thresh"], 1):
            wt, mt, _, _ = rates(d, tune, c)
            wr, mr, _, _ = rates(d, rep, c)
            lines.append(f"| {t} | {wt:.1%} / {mt:.1%} | {wr:.1%} / {mr:.1%} |")
        lines.append("")
    text = "\n".join(lines)
    print(text)
    if a.md:
        open(a.md, "w").write(text + "\n")


# ---------------------------------------------------------------- crop-level comparison (diagnostic b)

def sample(img, box, out_w, out_h):
    """numpy port of im_vision.c sample(): bilinear, box-average when shrinking by more than 2x."""
    h, w = img.shape[:2]
    sx0, sy0, sx1, sy1 = box
    fx, fy = (sx1 - sx0) / out_w, (sy1 - sy0) / out_h
    ax, ay = (int(fx / 2) if fx > 2 else 0), (int(fy / 2) if fy > 2 else 0)
    sy = np.clip(sy0 + (np.arange(out_h) + 0.5) * fy - 0.5, 0, h - 1).astype(np.float32)
    sx = np.clip(sx0 + (np.arange(out_w) + 0.5) * fx - 0.5, 0, w - 1).astype(np.float32)
    y0, x0 = sy.astype(int), sx.astype(int)
    f = img[..., :3].astype(np.float32)
    if ax or ay:
        ii = np.zeros((h + 1, w + 1, 3), np.float64)
        ii[1:, 1:] = f.cumsum(0).cumsum(1)
        ya, yb = np.clip(y0 - ay, 0, h), np.clip(y0 + ay + 1, 0, h)
        xa, xb = np.clip(x0 - ax, 0, w), np.clip(x0 + ax + 1, 0, w)
        s = ii[yb][:, xb] - ii[ya][:, xb] - ii[yb][:, xa] + ii[ya][:, xa]
        n = ((yb - ya)[:, None] * (xb - xa)[None, :])[..., None]
        c = s / np.maximum(n, 1)
    else:
        y1, x1 = np.minimum(y0 + 1, h - 1), np.minimum(x0 + 1, w - 1)
        wy, wx = (sy - y0)[:, None, None], (sx - x0)[None, :, None]
        c = (f[y0][:, x0] * (1 - wx) + f[y0][:, x1] * wx) * (1 - wy) + (f[y1][:, x0] * (1 - wx) + f[y1][:, x1] * wx) * wy
    return (c / 255.0).astype(np.float32)


def context_box(b, w, h, ctx=0.1):
    bw, bh = (b[2] - b[0]) * w, (b[3] - b[1]) * h
    return (max(0, b[0] * w - ctx * bw), max(0, b[1] * h - ctx * bh), min(w, b[2] * w + ctx * bw),
            min(h, b[3] * h + ctx * bh))


class Classifier:
    def __init__(self, path, threads=2):
        import onnxruntime as ort
        o = ort.SessionOptions()
        o.intra_op_num_threads = threads
        self.s = ort.InferenceSession(path, o, providers=["CPUExecutionProvider"])
        meta = self.s.get_modelmeta().custom_metadata_map
        self.h, self.w = int(meta["im.input_h"]), int(meta["im.input_w"])
        labels = meta["im.labels"].split(",")
        self.male = [labels.index("man"), labels.index("boy")]

    def p_male(self, x):  # x: HxWx3 float 0..1
        p = self.s.run(None, {"image": x.transpose(2, 0, 1)[None]})[0][0]
        return float(p[self.male].sum())


def crop_metrics(pm, female):
    pm, female = np.asarray(pm), np.asarray(female)
    from itertools import product  # noqa: F401
    pf, pmm = pm[female], pm[~female]
    # AUC: P(p_male(man) > p_male(woman))
    allp = np.concatenate([pf, pmm])
    ranks = allp.argsort().argsort() + 1
    auc = (ranks[len(pf):].sum() - len(pmm) * (len(pmm) + 1) / 2) / (len(pf) * len(pmm))
    t1 = np.sort(pf)[int(np.ceil(0.99 * len(pf))) - 1]
    return {"n_f": int(len(pf)), "n_m": int(len(pmm)), "auc": float(auc),
            "acc@0.5": float(((pm >= 0.5) == ~female).mean()),
            "women_clear@0.98": float((pf >= 0.98).mean()), "men_clear@0.98": float((pmm >= 0.98).mean()),
            "t_women1%": float(t1), "men_clear@women1%": float((pmm > t1).mean())}


def cmd_crops(a):
    gt = read_gt(a.data)
    full = os.path.join(a.data, "crops/validation/full")
    ids = sorted(i for i in gt if os.path.exists(os.path.join(full, i + ".jpg")))
    if a.limit:
        ids = ids[: a.limit]
    # annotator crops (original resolution, long side <= 256), keyed by image + box
    ann = {}
    cdir = os.path.join(a.data, "crops/validation")
    with open(os.path.join(cdir, "index.csv"), newline="") as f:
        for r in csv.DictReader(f):
            key = (r["image"], round(float(r["xmin"]), 4), round(float(r["ymin"]), 4))
            ann[key] = os.path.join(cdir, r["crop"])
    v = Vision(person=a.person, gender=a.gender, policy=WOMEN, threads=a.threads)
    if v.status:
        sys.exit("vision: " + v.error)
    clf = Classifier(a.gender, a.threads)
    rows = []
    parity = []
    t0 = time.time()
    for k, i in enumerate(ids):
        rgba, mp = frame(os.path.join(full, i + ".jpg"), "photo", 640)
        H, W = rgba.shape[:2]
        dets, _ = v.detect_raw(rgba, run_nsfw=False)
        dboxes = [(d.x0, d.y0, d.x1, d.y1) for d in dets]
        items = [(lab, b) for lab, grp, b in gt[i] if not grp]
        m = match([b for _, b in items], dboxes)
        for gi, (lab, b) in enumerate(items):
            key = (i, round(b[0], 4), round(b[1], 4))
            if gi not in m or key not in ann or dets[m[gi]].p_male < 0:
                continue
            d = dets[m[gi]]
            p_rt = d.p_male
            if len(parity) < 200:  # check the numpy port against the C path on the same box
                parity.append(abs(clf.p_male(sample(rgba, context_box(dboxes[m[gi]], W, H), clf.w, clf.h)) - p_rt))
            p_gt640 = clf.p_male(sample(rgba, context_box(b, W, H), clf.w, clf.h))
            im = Image.open(ann[key]).convert("RGB").resize((clf.w, clf.h), Image.BILINEAR)
            p_ann = clf.p_male(np.asarray(im, np.float32) / 255.0)
            rows.append((lab, half(i), b[3] - b[1], p_ann, p_gt640, p_rt))
        if (k + 1) % 500 == 0:
            print(f"{k + 1}/{len(ids)} {time.time() - t0:.0f} s, {len(rows)} people", flush=True)
    print(f"numpy sample() vs C: max |dp| {max(parity):.2e} over {len(parity)} boxes")
    female = np.array([r[0] in ("woman", "girl") for r in rows])
    hgt = np.array([r[2] for r in rows])
    out = {"n_images": len(ids), "gender": os.path.basename(a.gender), "parity_max_abs": float(max(parity))}
    for name, col in (("annotator crop", 3), ("annotator box, 640 frame", 4), ("detector box, 640 frame", 5)):
        pm = np.array([r[col] for r in rows])
        out[name] = {"all": crop_metrics(pm, female)}
        for tag, sel in (("large", hgt >= 0.3), ("medium", (hgt >= 0.1) & (hgt < 0.3)), ("small", hgt < 0.1)):
            if female[sel].any() and (~female[sel]).any():
                out[name][tag] = crop_metrics(pm[sel], female[sel])
    print(json.dumps(out, indent=1))
    if a.out:
        json.dump(out, open(a.out, "w"), indent=1)
        np.savez_compressed(a.out.replace(".json", ".npz"), label=np.array([r[0] for r in rows]),
                            half=np.array([r[1] for r in rows]), h=hgt,
                            p=np.array([r[3:] for r in rows], np.float32))


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("run", "crops"):
        p = sub.add_parser(name)
        p.add_argument("--person", default=os.path.join(ROOT, "person_yolox_nano.onnx"))
        p.add_argument("--gender", required=True)
        p.add_argument("--data", default=DATA)
        p.add_argument("--limit", type=int, default=0)
        p.add_argument("--threads", type=int, default=2)
        p.add_argument("--out")
        if name == "run":
            p.add_argument("--layout", choices=["photo", "portrait"], default="photo")
            p.add_argument("--long-side", type=int, default=640)
            p.add_argument("--tiles", type=int, help="detector tiles on elongated frames (engine default if unset)")
    p = sub.add_parser("report")
    p.add_argument("npz", nargs="+")
    p.add_argument("--md")
    a = ap.parse_args()
    {"run": cmd_run, "report": cmd_report, "crops": cmd_crops}[a.cmd](a)


if __name__ == "__main__":
    main()
