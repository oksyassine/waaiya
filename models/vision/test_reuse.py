"""Verdict reuse (im_vision_params.reuse_frames) through the real C library.

    python models/vision/test_reuse.py IMAGE [IMAGE ...]   (photos with people; e.g. data/openimages/.../full/*.jpg)

Each photo is shown, then shown again slightly brighter: the detector finds the same people, but the classifier
would give a slightly different p(man). So a person whose p(man) comes back bit-for-bit equal reused the earlier
verdict, and one with a new value was classified again. Checks:
  1. reuse_frames 0: everyone is classified again (no shared state between calls).
  2. reuse_frames 2: covered people reuse their verdict on the next 2 calls and are classified on the third.
  3. people left clear are never reused (reuse can only cover).
"""
import os
import sys

import numpy as np

from imvision import WOMEN, Vision, VRect, load_rgba

HERE = os.path.dirname(os.path.abspath(__file__))
CLEAR = 0  # IM_VK_CLEAR (imvision.KINDS)


def people(v, rgba):
    rects = v.detect_raw(rgba, run_nsfw=False)[0]  # views of one buffer the next call overwrites: copy
    return [VRect.from_buffer_copy(r) for r in rects if r.p_male >= 0]


def matched(a, b):
    """Pairs of the same person in two calls (boxes within 1% of the frame)."""
    out = []
    for r in a:
        for s in b:
            if max(abs(r.x0 - s.x0), abs(r.y0 - s.y0), abs(r.x1 - s.x1), abs(r.y1 - s.y1)) < 0.01:
                out.append((r, s))
                break
    return out


def main(paths):
    v = Vision(os.path.join(HERE, "person_yolox_nano.onnx"), os.path.join(HERE, "gender_v2.onnx"), None, WOMEN)
    if v.status:
        sys.exit(f"models: {v.error}")
    fails, n_cov, n_clear = [], 0, 0
    for path in paths:
        a = load_rgba(path, 640)
        b = a.copy()
        b[..., :3] = np.minimum(a[..., :3].astype(np.int16) + 6, 255).astype(np.uint8)
        name = os.path.basename(path)

        v.params(reuse_frames=0)
        p0 = people(v, a)
        for r, s in matched(p0, people(v, b)):
            if r.p_male == s.p_male:
                fails.append(f"{name}: reuse off, p(man) {r.p_male} came back unchanged")

        v.params(reuse_frames=2)
        p1 = people(v, a)
        calls = [people(v, b), people(v, a), people(v, b)]  # reused, reused, classified again
        for r in p1:
            seq = [matched([r], c) for c in calls]
            if not all(seq):
                continue  # the detector lost them on one of the frames: nothing to compare
            if any(len(matched(p1, [m[0][1]])) > 1 for m in seq):
                continue  # their later box also fits another person: who took which verdict cannot be told
            later = [m[0][1] for m in seq]
            if r.kind == CLEAR:
                n_clear += 1
                if later[0].p_male == r.p_male:
                    fails.append(f"{name}: a clear person (p {r.p_male:.5f}) was reused")
            else:
                n_cov += 1
                if not (later[0].p_male == r.p_male and later[1].p_male == r.p_male):
                    fails.append(f"{name}: a covered person was not reused ({r.p_male} -> "
                                 f"{later[0].p_male}, {later[1].p_male})")
                if later[2].p_male == r.p_male:
                    fails.append(f"{name}: a covered person was still reused after reuse_frames calls")
        v.params(reuse_frames=0)
        people(v, np.zeros_like(a))  # forget, before the next photo
    print(f"{len(paths)} photos: {n_cov} covered and {n_clear} clear people followed through 4 calls")
    for f in fails:
        print("FAIL", f)
    if not n_cov:
        sys.exit("no covered person to check: give photos with people")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1:])
