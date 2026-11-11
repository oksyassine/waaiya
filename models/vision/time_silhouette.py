"""Cost of the outlines per frame, through the real C code: the same frames run with and without the segmenter.

Layouts as blur_diag.py: photo (the image, long side 640) and portrait (the image in a 16:9 strip of a 1080x2340
screen, long side 640, where the detector also runs on tiles and so finds about twice the boxes).

    python models/vision/time_silhouette.py --seg models/vision/seg.onnx [--layout portrait] [--limit 300] [--threads 1]
"""
import argparse
import glob
import os
import sys
import time

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from blur_diag import frame  # noqa: E402
from imvision import WOMEN, Vision  # noqa: E402

ROOT = os.path.dirname(os.path.abspath(__file__))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--person", default=os.path.join(ROOT, "person_yolox_nano.onnx"))
    ap.add_argument("--gender", default=os.path.join(ROOT, "gender_v2.onnx"))
    ap.add_argument("--seg", required=True)
    ap.add_argument("--images", default=os.path.join(ROOT, "data/oi_seg/test/full"))
    ap.add_argument("--layout", default="photo", choices=["photo", "portrait"])
    ap.add_argument("--limit", type=int, default=300)
    ap.add_argument("--threads", type=int, default=1)
    a = ap.parse_args()
    v = Vision(person=a.person, gender=a.gender, seg=a.seg, policy=WOMEN, threads=a.threads)
    if v.status:
        sys.exit(v.error)
    t_off, t_on, n_out, n_cov = [], [], [], []
    for f in sorted(glob.glob(os.path.join(a.images, "*.jpg")))[: a.limit]:
        rgba, _ = frame(f, a.layout)
        v.params(seg=0)
        t = time.perf_counter()
        v.detect_shapes(rgba, run_nsfw=False)
        t_off.append(time.perf_counter() - t)
        v.params(seg=1)
        t = time.perf_counter()
        d, s = v.detect_shapes(rgba, run_nsfw=False)
        t_on.append(time.perf_counter() - t)
        n_out.append(sum(x.rows > 0 for x in s))
        n_cov.append(sum(x.kind in (1, 2) for x in d))
    extra = np.array(t_on) - np.array(t_off)
    print(f"{a.layout}, {len(t_on)} frames, {a.threads} thread(s): covered people per frame mean {np.mean(n_cov):.2f}, "
          f"outlined mean {np.mean(n_out):.2f} (max {max(n_out)}); detect median {1000 * np.median(t_off):.0f} ms; "
          f"outlines add mean {1000 * extra.mean():.0f} ms, p95 {1000 * np.percentile(extra, 95):.0f} ms per frame, "
          f"{1000 * extra.sum() / max(1, sum(n_out)):.1f} ms per outlined person")


if __name__ == "__main__":
    main()
