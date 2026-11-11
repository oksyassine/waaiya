"""Unit tests of the screen-blur tracker (engine/src/im_cover.c) on synthetic frames, through build/libimvision.so.

    make build/libimvision.so && python models/vision/test_cover.py
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from imvision import SHAPE_ROWS, Cover, VRect, VShape  # noqa: E402

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


def body(l=0.35, r=0.65, y0=-0.2, y1=1.2, empty=(1, 1), flags=0):
    """A standing person's outline (box units): a head (the 3 rows after the empty ones at the top) half as wide as
    the body below, which spans l..r; empty = rows left empty at the top and bottom."""
    sh = VShape(SHAPE_ROWS, flags, y0, y1)
    q = (r - l) / 4
    for k in range(SHAPE_ROWS):
        out = k < empty[0] or k >= SHAPE_ROWS - empty[1]
        head = empty[0] <= k < empty[0] + 3
        sh.l[k], sh.r[k] = (1, 0) if out else (l + q, r - q) if head else (l, r)
    return sh


def none():
    return VShape(0, 0, 0, 0)


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
    # one detection per track per frame (drawn unmerged here, to see the tracks)
    c = Cover(covers_visible=False, merge_gap=0)
    out = c.update(0, img, [det(0.1, 0.2, 0.45, 0.8), det(0.35, 0.2, 0.7, 0.8), det(0.6, 0.2, 0.95, 0.8)])
    check("overlapping people keep separate covers", len(out) == 3)
    # groups: close covers are drawn as one, so the gaps between people are covered too
    c = Cover(covers_visible=False)
    out = c.update(0, img, [det(0.05, 0.3, 0.2, 0.6), det(0.32, 0.3, 0.47, 0.6), det(0.59, 0.3, 0.74, 0.6)])
    check("a group is covered as one, gaps included", len(out) == 1 and covers(out, 0.26, 0.45) and covers(out, 0.53, 0.45))
    c = Cover(covers_visible=False)
    out = c.update(0, img, [det(0.05, 0.1, 0.15, 0.3), det(0.8, 0.6, 0.9, 0.8)])
    check("people far apart keep their own covers", len(out) == 2 and not covers(out, 0.5, 0.45))
    c = Cover(covers_visible=False)
    c.update(0, img, [VRect(0, 0, 1, 1, 4, 0.9, -1)])
    out = c.update(10, img, [det(0.4, 0.4, 0.6, 0.8)])
    check("a whole-frame cover is not merged into", sum(r[4] == "full" for r in out) == 1 and len(out) == 2)
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

    # outlines: strips that follow the person instead of the whole rectangle
    c = Cover(covers_visible=False, bridge_gap=0, lead_ms=0)
    out = c.update(0, img, [det(0.4, 0.3, 0.6, 0.7)], [body()])
    check("outlined person: drawn as strips", len(out) > 1 and all(r[7] for r in out))
    check("strips cover the body", covers(out, 0.5, 0.31) and covers(out, 0.5, 0.5) and covers(out, 0.5, 0.69))
    check("strips leave the box corners and the margin free (text beside the person)",
          not covers(out, 0.41, 0.31) and not covers(out, 0.59, 0.69) and not covers(out, 0.36, 0.5))
    check("strips stay inside the rectangle the person would get",
          min(r[0] for r in out) >= 0.36 - 1e-6 and max(r[2] for r in out) <= 0.64 + 1e-6)
    out = c.update(40, img, [det(0.3, 0.2, 0.6, 0.8)], [body()])  # the person moved left and came closer
    check("strips follow the box (moved and scaled)", len(out) == 2 and covers(out, 0.45, 0.24) and
          covers(out, 0.4, 0.75) and not covers(out, 0.35, 0.5) and not covers(out, 0.55, 0.5))
    out = c.update(80, img, [], None)
    check("a missed detection keeps the outline", len(out) == 2 and covers(out, 0.4, 0.75) and not covers(out, 0.3, 0.5))
    out = c.update(120, img, [det(0.3, 0.2, 0.6, 0.8)], [none()])
    check("a detection without an outline: the whole rectangle again", len(out) == 1 and covers(out, 0.25, 0.5))
    # fail closed
    c = Cover(covers_visible=False)
    out = c.update(0, img, [det(0.4, 0.3, 0.6, 0.7)], [body()], max_out=1)
    check("no room for all strips: the whole rectangle, never part of an outline",
          len(out) == 1 and not out[0][7] and covers(out, 0.41, 0.31))
    out = Cover(covers_visible=False).update(0, img, [det(0.4, 0.3, 0.6, 0.7)], [body(empty=(SHAPE_ROWS, 0))])
    check("an empty outline: the whole rectangle", len(out) == 1 and covers(out, 0.41, 0.31))
    out = Cover(covers_visible=False).update(0, img, [det(0.4, 0.3, 0.6, 0.7)], [body(l=-100, r=100, empty=(0, 0),
                                                                                   flags=3)])
    check("an outline open on every side reaches the rectangle's edges",
          covers(out, 0.365, 0.3) and covers(out, 0.635, 0.7) and covers(out, 0.5, 0.225))
    out = Cover(covers_visible=True).update(0, img, [det(0.4, 0.3, 0.6, 0.7)], [body()])
    check("covers visible in the capture: rectangles only", len(out) == 1 and covers(out, 0.41, 0.31))
    # one-to-one: overlapping outlined people keep their own strips; strips are not joined into a box
    c = Cover(covers_visible=False, bridge_gap=0)
    people = [det(0.1, 0.2, 0.3, 0.8), det(0.25, 0.2, 0.45, 0.8), det(0.4, 0.2, 0.6, 0.8)]
    out = c.update(0, img, people, [body(), body(), body()])
    owners = [[k for k, p in enumerate(people) if p.x0 - 0.05 <= r[0] and r[2] <= p.x1 + 0.05] for r in out]
    check("one outline per track (each strip belongs to one person, each person has strips)",
          all(len(o) >= 1 for o in owners) and {o[0] for o in owners if len(o) == 1} == {0, 1, 2}
          and all(covers(out, (p.x0 + p.x1) / 2, 0.5) for p in people))
    c = Cover(covers_visible=False, bridge_gap=0)
    out = c.update(0, img, [det(0.1, 0.3, 0.3, 0.7), det(0.35, 0.3, 0.55, 0.7)], [body(), body()])
    check("close outlined people are not joined into a box (merge_gap)", not covers(out, 0.325, 0.5)
          and not covers(out, 0.12, 0.31))
    c = Cover(covers_visible=False)
    out = c.update(0, img, [det(0.1, 0.3, 0.3, 0.7), det(0.35, 0.3, 0.55, 0.7)], [body(), body()])
    check("a bridge covers the space between close outlined people at their height, not above them",
          covers(out, 0.325, 0.5) and covers(out, 0.325, 0.32) and not covers(out, 0.325, 0.2))
    out = Cover(covers_visible=False).update(0, img, [det(0.05, 0.1, 0.15, 0.3), det(0.8, 0.6, 0.9, 0.8)],
                                             [body(), body()])
    check("no bridge between people far apart", not covers(out, 0.5, 0.45))
    c = Cover(covers_visible=False)
    c.update(0, img, [det(0.2, 0.3, 0.3, 0.7)], [body()])
    out = c.update(100, img, [det(0.3, 0.3, 0.4, 0.7)], [body()])
    check("moving outlined person: strips extend ahead", covers(out, 0.47, 0.5))

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
