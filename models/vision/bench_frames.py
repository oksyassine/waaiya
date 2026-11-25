"""Frames for bench_vision.c: Open Images validation photos (report half) with people, placed like a phone capture.

portrait: each photo fitted across a 296x640 frame (the app's capture of a 1080x2340 screen, long side 640), centred
on black, as when a photo is shown full width on an upright phone. Detector tiles run on it like in the app.

    python models/vision/bench_frames.py OUT.raw [--count 30]
"""
import argparse
import os
import struct
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from blur_diag import half  # noqa: E402
from imvision import load_rgba  # noqa: E402

W, H = 296, 640


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--count", type=int, default=30)
    a = ap.parse_args()
    full = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data/openimages/crops/validation/full")
    ids = [f[:-4] for f in sorted(os.listdir(full)) if f.endswith(".jpg") and half(f[:-4]) == "report"][:a.count]
    with open(a.out, "wb") as f:
        f.write(struct.pack("<ii", W, H))
        for i in ids:
            img = load_rgba(os.path.join(full, i + ".jpg"))
            h = min(H, max(1, round(img.shape[0] * W / img.shape[1])))
            small = np.asarray(Image.fromarray(img).resize((W, h), Image.BILINEAR))
            frame = np.zeros((H, W, 4), np.uint8)
            frame[..., 3] = 255
            y = (H - h) // 2
            frame[y:y + h] = small
            f.write(frame.tobytes())
    print("wrote", len(ids), "frames to", a.out)


if __name__ == "__main__":
    main()
