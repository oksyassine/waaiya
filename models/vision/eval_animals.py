"""False covers on photos of animals with no people, through the real C code (build/libimvision.so).

Every cover on these images is a mistake. Images: Open Images validation images that have an animal box and no
person box of any kind (fetched by id from the public bucket; list in the results file's command).

  images with a cover   share of images where at least one person cover was drawn
  screen covered        mean share of the image under covers

    make build/libimvision.so
    python models/vision/eval_animals.py --person models/vision/person_yolox_nano.onnx \
        --gender models/vision/gender_v2.onnx --images DIR [--male-clear 0.999] [--person-score 0.1] [--seg models/vision/seg.onnx]
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from eval_blur import covered_fraction  # noqa: E402
from imvision import WOMEN, Cover, Vision, load_rgba  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--person", required=True)
    ap.add_argument("--gender")
    ap.add_argument("--images", required=True, help="folder of .jpg images with no people")
    ap.add_argument("--long-side", type=int, default=640)
    ap.add_argument("--male-clear", type=float)
    ap.add_argument("--person-score", type=float)
    ap.add_argument("--seg")
    a = ap.parse_args()

    v = Vision(person=a.person, gender=a.gender, policy=WOMEN, threads=2, seg=a.seg)
    if v.status:
        sys.exit("vision: " + v.error)
    v.params(**{k: x for k, x in (("male_clear", a.male_clear), ("person_score", a.person_score)) if x is not None})
    cover = Cover(covers_visible=False)
    files = sorted(f for f in os.listdir(a.images) if f.endswith(".jpg"))
    hit, screen = 0, 0.0
    for f in files:
        rgba = load_rgba(os.path.join(a.images, f), a.long_side)
        if a.seg:
            dets, shapes = v.detect_shapes(rgba, run_nsfw=False)
        else:
            (dets, _), shapes = v.detect_raw(rgba, run_nsfw=False), None
        rects = cover.update(0.0, rgba, dets, shapes)
        cover.reset()
        hit += bool(rects)
        screen += covered_fraction((0, 0, 1, 1), rects, 32)
    n = max(1, len(files))
    print(f"{os.path.basename(a.person)}: {len(files)} images, images with a cover {hit / n:.1%}, "
          f"screen covered {screen / n:.1%}")


if __name__ == "__main__":
    main()
