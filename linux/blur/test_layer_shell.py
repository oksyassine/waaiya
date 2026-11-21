#!/usr/bin/env python3
"""The Wayland layer-shell overlay (layer.c) in a real wlroots compositor: sway, headless, software rendering.

    python3 linux/blur/test_layer_shell.py [--image woman.jpg ...] [--sway sway] [--grim grim]
                                           [--im-blur build/im-blur] [--models models/vision] [--shot out.png]

No screen-cast portal runs here, so the capture is replaced by a still picture (im-blur --capture-ppm: the women
side by side, the size of the output). Checks, from grim screenshots (wlr-screencopy, which shows every layer):
  - im-blur finds the wlr-layer-shell global and reports overlay "layer-shell", state "on" (no self-test: the
    picture never shows the overlay);
  - with --image (pictures of women; none are in the repository): the covers are drawn over each woman, at the
    right place on the output, and nowhere else (the rest of the output stays as the compositor drew it: the
    surface is transparent there);
  - without: the nudity cover, forced with a zero threshold, covers the whole output, opaque;
  - "policy 0" clears them, "quit" exits, and the surface goes away.
Needs Pillow (picture, screenshots). Not checked here: clicks (headless sway has no input devices).
"""
import argparse
import json
import os
import queue
import shutil
import subprocess
import sys
import tempfile
import threading
import time

from PIL import Image


def check(cond, msg):
    if not cond:
        raise AssertionError(msg)
    print("ok  ", msg)


def main():
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    ap = argparse.ArgumentParser()
    ap.add_argument("--sway", default="sway")
    ap.add_argument("--grim", default="grim")
    ap.add_argument("--im-blur", default=os.path.join(root, "build/im-blur"))
    ap.add_argument("--models", default=os.path.join(root, "models/vision"))
    ap.add_argument("--image", action="append", default=[])
    ap.add_argument("--shot")
    a = ap.parse_args()

    tmp = tempfile.mkdtemp(prefix="im-blur-wl-")
    rt = os.path.join(tmp, "rt")
    os.mkdir(rt, 0o700)
    cfg = os.path.join(tmp, "sway.cfg")
    with open(cfg, "w") as f:
        f.write("output * resolution 1280x720 bg #5a6068 solid_color\n")
    env = {**os.environ, "XDG_RUNTIME_DIR": rt, "WLR_BACKENDS": "headless", "WLR_RENDERER": "pixman",
           "WLR_LIBINPUT_NO_DEVICES": "1", "WLR_HEADLESS_OUTPUTS": "1"}
    for k in ("WAYLAND_DISPLAY", "DISPLAY", "SWAYSOCK"):
        env.pop(k, None)
    sway = subprocess.Popen([a.sway, "-c", cfg], env=env, stdout=subprocess.DEVNULL, stderr=open(os.path.join(tmp, "sway.log"), "w"))
    try:
        sock = None
        for _ in range(100):
            socks = [s for s in os.listdir(rt) if s.startswith("wayland-") and not s.endswith(".lock")]
            if socks:
                sock = socks[0]
                break
            time.sleep(0.1)
        if not sock:
            sys.exit("sway did not start:\n" + open(os.path.join(tmp, "sway.log")).read()[-2000:])
        env["WAYLAND_DISPLAY"] = sock
        time.sleep(0.5)

        def shot():
            p = os.path.join(tmp, "shot.png")
            subprocess.run([a.grim, p], env=env, check=True)
            return Image.open(p).convert("RGB")

        before = shot()
        W, H = before.size
        print(f"     output {W}x{H}")

        # the "screen": the women side by side on a plain background, the size of the output
        pic = Image.new("RGB", (W, H), (90, 96, 104))
        boxes, x = [], 120
        for path in a.image:
            im = Image.open(path).convert("RGB")
            s = min(480 / im.height, 300 / im.width)
            im = im.resize((int(im.width * s), int(im.height * s)))
            y = (H - im.height) // 2
            pic.paste(im, (x, y))
            boxes.append((x, y, im.width, im.height))
            x += im.width + 60
        ppm = os.path.join(tmp, "screen.ppm")
        pic.save(ppm)

        mode = ["--policy", "1"] if boxes else ["--policy", "2", "--nsfw-score", "0.000001"]
        p = subprocess.Popen([a.im_blur, "--backend", "wayland", "--capture-ppm", ppm, "--models", a.models,
                              "--stats-ms", "1000", *mode], env=env, stdin=subprocess.PIPE,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        q = queue.Queue()
        threading.Thread(target=lambda: [q.put(json.loads(l)) for l in p.stdout], daemon=True).start()
        last = {}

        def wait(pred, timeout, what):
            nonlocal last
            end = time.time() + timeout
            while time.time() < end:
                try:
                    last = q.get(timeout=0.1)
                except queue.Empty:
                    pass
                if last and pred(last):
                    return last
            raise AssertionError(f"timeout waiting for {what}; last {last}; exit {p.poll()} "
                                 f"{p.stderr.read() if p.poll() is not None else ''}")

        st = wait(lambda m: m["state"] == "on" and m.get("covers", 0) >= 1, 30, "covers")
        check(st["overlay"] == "layer-shell" and st["backend"] == "wayland",
              f"overlay {st['overlay']} on {st['backend']}: the wlr-layer-shell surface is used")
        time.sleep(1.0)
        after = shot()
        if a.shot:
            after.save(a.shot)
            print("     screenshot:", a.shot)
        for i, (bx, by, bw, bh) in enumerate(boxes):
            pts = [(bx + bw * fx // 4, by + bh * fy // 4) for fx in (1, 2, 3) for fy in (1, 2, 3)]
            changed = sum(after.getpixel(pt) != before.getpixel(pt) for pt in pts)
            check(changed == len(pts), f"woman {i + 1}: covered at all {len(pts)} sample points ({changed})")
        far = [(10, 10), (W - 10, H - 10), (W - 10, 10), (10, H - 10)]
        if boxes:
            check(all(after.getpixel(pt) == before.getpixel(pt) for pt in far),
                  "outside the covers the output is unchanged (transparent surface)")
        else:
            check(all(after.getpixel(pt) == (0x2b, 0x2d, 0x31) for pt in far + [(W // 2, H // 2)]),
                  "nudity: the whole output is covered, opaque")
        p.stdin.write("policy 0\n")
        p.stdin.flush()
        wait(lambda m: m["state"] == "idle", 10, "idle")
        time.sleep(0.5)
        cleared = shot()
        bx, by, bw, bh = boxes[0] if boxes else (0, 0, W, H)
        check(cleared.getpixel((bx + bw // 2, by + bh // 2)) == before.getpixel((bx + bw // 2, by + bh // 2)),
              "policy 0: the covers are gone")
        p.stdin.write("quit\n")
        p.stdin.flush()
        check(p.wait(timeout=5) == 0, "'quit' -> im-blur exits")
        print("all layer-shell checks passed")
        return 0
    finally:
        sway.terminate()
        sway.wait()
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
