"""Unit tests of the screen-blur tracker (engine/src/im_cover.c) on synthetic frames, through build/libimvision.so.

    make build/libimvision.so && python models/vision/test_cover.py
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imvision import Cover, VRect  # noqa: E402

W, H = 320, 640
rng = np.random.default_rng(0)


def texture(seed):
    """Smooth random picture (so a shift is measurable on a coarse thumbnail)."""
    r = np.random.default_rng(seed)
    small = r.integers(0, 256, (H // 32 + 4, W // 32 + 4, 3)).astype(np.float32)
    big = np.kron(small, np.ones((32, 32, 1)))
    k = np.ones(17) / 17
    for ax in (0, 1):
        big = np.apply_along_axis(lambda m: np.convolve(m, k, "same"), ax, big)
    img = big[:H, :W]
    return np.concatenate([img, np.full((H, W, 1), 255)], 2).astype(np.uint8)


def det(x0, y0, x1, y1, kind=1):
    return VRect(x0, y0, x1, y1, kind, 0.9, -1)


def covers(out, x, y):
    return any(r[0] <= x <= r[2] and r[1] <= y <= r[3] for r in out)


def main():
    ok = True

    def check(name, cond):
        nonlocal ok
        print(("PASS " if cond else "FAIL ") + name)
        ok &= bool(cond)

    img = texture(1)
    # clean capture: hold, then release
    c = Cover(covers_visible=False)
    out = c.update(0, img, [det(0.4, 0.4, 0.6, 0.8)])
    check("person covered with margin", covers(out, 0.38, 0.39) and covers(out, 0.5, 0.6))
    check("held during a missed detection", covers(c.update(300, img, []), 0.5, 0.6))
    check("released after the hold time", not covers(c.update(900, img, []), 0.5, 0.6))
    # one detection per track per frame
    c = Cover(covers_visible=False)
    out = c.update(0, img, [det(0.1, 0.2, 0.45, 0.8), det(0.35, 0.2, 0.7, 0.8), det(0.6, 0.2, 0.95, 0.8)])
    check("overlapping people keep separate covers", len(out) == 3)
    # men are not covered and never refresh a cover
    c = Cover(covers_visible=False)
    out = c.update(0, img, [det(0.1, 0.1, 0.3, 0.5, kind=0)])
    check("a man is left clear", not out)
    c.update(0, img, [det(0.4, 0.4, 0.6, 0.8)])
    out = c.update(600, img, [det(0.4, 0.4, 0.6, 0.8, kind=0)])
    check("a flicker to 'man' does not keep or extend a cover past its hold", not covers(out, 0.5, 0.6))
    # motion lead
    c = Cover(covers_visible=False)
    c.update(0, img, [det(0.2, 0.4, 0.3, 0.8)])
    out = c.update(100, img, [det(0.3, 0.4, 0.4, 0.8)])
    check("moving person: cover extends ahead", covers(out, 0.5, 0.6))
    # nudity: whole frame, held
    c = Cover(covers_visible=False)
    c.update(0, img, [VRect(0, 0, 1, 1, 4, 0.9, -1)])
    check("nudity covers the whole frame", any(r[4] == "full" for r in c.update(1000, img, None)))
    check("nudity cover released after its hold", not any(r[4] == "full" for r in c.update(2000, img, None)))

    # covers visible in the capture: keep until a scene change, follow scrolls
    c = Cover(covers_visible=True)
    c.update(0, img, [det(0.4, 0.3, 0.6, 0.5)])
    check("kept while the scene does not change", covers(c.update(5000, img, []), 0.5, 0.4))
    scrolled = np.roll(img, -64, axis=0)  # content moves up by 64 px = 0.1 of the height
    out = c.update(5100, scrolled, [])
    check("scroll moves the cover with the content", covers(out, 0.5, 0.31) and not covers(out, 0.5, 0.52))
    out = c.update(5200, texture(7), [])
    check("scene change releases the cover", not out)
    print("ALL PASS" if ok else "SOME FAILED")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
