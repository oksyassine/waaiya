"""Parity: the C vision path (letterbox + wrapped YOLOX graph + threshold/NMS) against an independent Python
reference that runs the ORIGINAL YOLOX ONNX with YOLOX's own preprocessing and decoding (demo_utils logic).

    python models/vision/test_vision_engine.py --raw downloads/yolox_nano.onnx --wrapped person_yolox_nano.onnx \
        IMAGE [IMAGE ...]
Images are first resized to the model size (long side 416) so neither side resamples: this checks the wrapped
graph, the letterbox, decoding and NMS exactly. Passes when every reference person box (score >= 0.3) has a C box
with IoU >= 0.99 and the scores agree to 1e-3. (Resampling quality is measured end to end by eval_blur.py.)
"""
import argparse
import sys

import numpy as np
import onnxruntime as ort
from PIL import Image

from imvision import WOMEN, Vision, load_rgba


def reference(sess, rgb, thr=0.3, nms=0.5):
    size = sess.get_inputs()[0].shape[2]
    h, w = rgb.shape[:2]
    r = min(size / h, size / w)
    im = Image.fromarray(rgb).resize((int(round(w * r)), int(round(h * r))), Image.BILINEAR)
    pad = np.full((size, size, 3), 114, np.float32)
    a = np.asarray(im, np.float32)
    pad[: a.shape[0], : a.shape[1]] = a
    x = pad[:, :, ::-1].transpose(2, 0, 1)[None].copy()  # BGR, 0..255
    out = sess.run(None, {sess.get_inputs()[0].name: x})[0][0]
    grids, strides = [], []
    for s in (8, 16, 32):
        n = size // s
        yv, xv = np.meshgrid(np.arange(n), np.arange(n), indexing="ij")
        grids.append(np.stack((xv, yv), 2).reshape(-1, 2))
        strides.append(np.full((n * n, 1), s))
    g, st = np.concatenate(grids), np.concatenate(strides)
    xy = (out[:, :2] + g) * st
    wh = np.exp(out[:, 2:4]) * st
    score = out[:, 4] * out[:, 5]
    boxes = np.concatenate([xy - wh / 2, xy + wh / 2], 1) / r
    boxes = np.clip(boxes, 0, [w, h, w, h])  # the C side clips to the frame before NMS
    keep = []
    for i in np.argsort(-score):
        if score[i] < thr:
            break
        if all(iou(boxes[i], boxes[j]) <= nms for j in keep):
            keep.append(i)
    return [(boxes[i] / [w, h, w, h], score[i]) for i in keep]


def iou(a, b):
    ix = min(a[2], b[2]) - max(a[0], b[0])
    iy = min(a[3], b[3]) - max(a[1], b[1])
    if ix <= 0 or iy <= 0:
        return 0.0
    i = ix * iy
    return i / ((a[2] - a[0]) * (a[3] - a[1]) + (b[2] - b[0]) * (b[3] - b[1]) - i)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", required=True)
    ap.add_argument("--wrapped", required=True)
    ap.add_argument("images", nargs="+")
    a = ap.parse_args()
    sess = ort.InferenceSession(a.raw)
    v = Vision(person=a.wrapped, policy=WOMEN)
    assert v.status == 0, v.error
    v.params(person_score=0.25)
    worst_iou, worst_ds, n_ref = 1.0, 0.0, 0
    for path in a.images:
        rgba = load_rgba(path, long_side=sess.get_inputs()[0].shape[2])
        ref = reference(sess, rgba[:, :, :3])
        got = [(np.array(r[:4]), r[5]) for r in v.detect(rgba)]
        for box, s in ref:
            n_ref += 1
            best = max(got, key=lambda g: iou(box, g[0]), default=None)
            bi = iou(box, best[0]) if best else 0
            worst_iou = min(worst_iou, bi)
            if best:
                worst_ds = max(worst_ds, abs(best[1] - s))
    ok = worst_iou >= 0.99 and worst_ds <= 1e-3
    print(f"{len(a.images)} images, {n_ref} reference people: worst IoU {worst_iou:.3f}, worst score diff "
          f"{worst_ds:.3f} -> {'PASS' if ok else 'FAIL'}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
