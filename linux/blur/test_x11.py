#!/usr/bin/env python3
"""End-to-end test of im-blur on a real X server (Xvfb, no compositor, no window manager).

    python3 linux/blur/test_x11.py [--im-blur build/im-blur] [--models models/vision] [--image woman.jpg ...]
                                   [--xvfb Xvfb] [--xkbdir DIR] [--shot out.png] [--compositor "xcompmgr -a"]

Starts its own Xvfb (abstract socket, so it needs no root and no /tmp/.X11-unix), optionally a compositing
manager (--compositor: then every window, ours included, is drawn by it), shows a test picture in a window, runs
im-blur against it and checks, through the X server itself:
  - the self-test runs and the state becomes on_covers_visible (the overlay shows in the root capture);
  - the colours reach the models the right way round (a red area is red in the analysed frame, not blue);
  - clicks pass through the overlay (empty input shape; an XTest click reaches the window underneath);
  - with --image (pictures of women, e.g. Open Images crops; none are in the repository): the overlay's bounding
    shape covers each woman, and the screen there shows the blur, not the picture;
  - the nudity cover (FULL, forced with a zero threshold) covers the whole screen, opaque, clicks still pass,
    and clears when the nudity option is turned off;
  - fail closed: models missing -> models_missing and a full-screen cover (fail_cover 1), a red bar (fail_cover 0);
  - stdin closed -> the helper exits;
  - cost: ms per analysed frame and CPU, on a still screen and on a changing one (printed).
Images need Pillow; everything else only the standard library and the X client libraries.
"""
import argparse
import ctypes
import ctypes.util
import json
import os
import queue
import struct
import subprocess
import sys
import threading
import time

W, H = 1280, 800

# ---------------------------------------------------------------- Xlib through ctypes


def lib(name):
    path = ctypes.util.find_library(name)
    if not path:
        sys.exit(f"lib{name} not found")
    return ctypes.CDLL(path)


X = lib("X11")
XEXT = lib("Xext")
XTST = lib("Xtst")
P = ctypes.c_void_p
UL = ctypes.c_ulong


def sig(f, res, *args):
    f.restype = res
    f.argtypes = list(args)


sig(X.XOpenDisplay, P, ctypes.c_char_p)
sig(X.XDefaultScreen, ctypes.c_int, P)
sig(X.XRootWindow, UL, P, ctypes.c_int)
sig(X.XDefaultVisual, P, P, ctypes.c_int)
sig(X.XDefaultDepth, ctypes.c_int, P, ctypes.c_int)
sig(X.XCreateSimpleWindow, UL, P, UL, ctypes.c_int, ctypes.c_int, ctypes.c_uint, ctypes.c_uint, ctypes.c_uint, UL, UL)
sig(X.XMapWindow, ctypes.c_int, P, UL)
sig(X.XSelectInput, ctypes.c_int, P, UL, ctypes.c_long)
sig(X.XCreateGC, P, P, UL, UL, P)
sig(X.XCreateImage, P, P, P, ctypes.c_uint, ctypes.c_int, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint,
    ctypes.c_uint, ctypes.c_int, ctypes.c_int)
sig(X.XPutImage, ctypes.c_int, P, UL, P, P, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_uint,
    ctypes.c_uint)
sig(X.XGetImage, P, P, UL, ctypes.c_int, ctypes.c_int, ctypes.c_uint, ctypes.c_uint, UL, ctypes.c_int)
sig(X.XSync, ctypes.c_int, P, ctypes.c_int)
sig(X.XCreatePixmap, UL, P, UL, ctypes.c_uint, ctypes.c_uint, ctypes.c_uint)
sig(X.XSetWindowBackgroundPixmap, ctypes.c_int, P, UL, UL)
sig(X.XClearWindow, ctypes.c_int, P, UL)
sig(X.XFreePixmap, ctypes.c_int, P, UL)
sig(X.XFlush, ctypes.c_int, P)
sig(X.XPending, ctypes.c_int, P)
sig(X.XNextEvent, ctypes.c_int, P, P)
sig(X.XQueryTree, ctypes.c_int, P, UL, ctypes.POINTER(UL), ctypes.POINTER(UL), ctypes.POINTER(ctypes.POINTER(UL)),
    ctypes.POINTER(ctypes.c_uint))
sig(X.XFetchName, ctypes.c_int, P, UL, ctypes.POINTER(ctypes.c_char_p))
sig(X.XFree, ctypes.c_int, P)
sig(XEXT.XShapeGetRectangles, P, P, UL, ctypes.c_int, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int))
sig(XTST.XTestFakeMotionEvent, ctypes.c_int, P, ctypes.c_int, ctypes.c_int, ctypes.c_int, UL)
sig(XTST.XTestFakeButtonEvent, ctypes.c_int, P, ctypes.c_uint, ctypes.c_int, UL)

ZPixmap, ButtonPressMask, ButtonPress, ShapeBounding, ShapeInput = 2, 1 << 2, 4, 0, 2


class XImage(ctypes.Structure):  # leading fields only
    _fields_ = [("width", ctypes.c_int), ("height", ctypes.c_int), ("xoffset", ctypes.c_int),
                ("format", ctypes.c_int), ("data", P), ("byte_order", ctypes.c_int),
                ("bitmap_unit", ctypes.c_int), ("bitmap_bit_order", ctypes.c_int), ("bitmap_pad", ctypes.c_int),
                ("depth", ctypes.c_int), ("bytes_per_line", ctypes.c_int), ("bits_per_pixel", ctypes.c_int)]


class XRect(ctypes.Structure):
    _fields_ = [("x", ctypes.c_short), ("y", ctypes.c_short), ("width", ctypes.c_ushort), ("height", ctypes.c_ushort)]


class Display:
    def __init__(self, name):
        self.d = X.XOpenDisplay(name.encode())
        if not self.d:
            raise RuntimeError(f"cannot open display {name}")
        s = X.XDefaultScreen(self.d)
        self.root = X.XRootWindow(self.d, s)
        self.vis = X.XDefaultVisual(self.d, s)
        self.depth = X.XDefaultDepth(self.d, s)
        self.keep = []

    def window(self, x, y, w, h):
        win = X.XCreateSimpleWindow(self.d, self.root, x, y, w, h, 0, 0, 0)
        X.XSelectInput(self.d, win, ButtonPressMask)
        X.XMapWindow(self.d, win)
        X.XSync(self.d, 0)
        return win

    def put(self, win, rgb, w, h):
        """rgb: bytes, w*h*3 (R, G, B). Sent as 32-bit X pixels 0x00RRGGBB."""
        px = bytearray(w * h * 4)
        px[0::4], px[1::4], px[2::4] = rgb[2::3], rgb[1::3], rgb[0::3]
        buf = ctypes.create_string_buffer(bytes(px), len(px))
        self.keep.append(buf)
        img = X.XCreateImage(self.d, self.vis, self.depth, ZPixmap, 0, ctypes.cast(buf, ctypes.c_char_p), w, h, 32, 0)
        # as the window's background, so the server repaints it itself when a cover moves away (like an app would)
        pm = X.XCreatePixmap(self.d, win, w, h, self.depth)
        gc = X.XCreateGC(self.d, pm, 0, None)
        X.XPutImage(self.d, pm, gc, img, 0, 0, 0, 0, w, h)
        X.XSetWindowBackgroundPixmap(self.d, win, pm)
        X.XClearWindow(self.d, win)
        X.XFreePixmap(self.d, pm)
        X.XSync(self.d, 0)

    def grab(self):
        """The root window as RGB bytes (what the user sees)."""
        img = ctypes.cast(X.XGetImage(self.d, self.root, 0, 0, W, H, 0xFFFFFFFF, ZPixmap), ctypes.POINTER(XImage))
        im = img.contents
        raw = ctypes.string_at(im.data, im.bytes_per_line * H)
        out = bytearray(W * H * 3)
        for y in range(H):
            row = raw[y * im.bytes_per_line:y * im.bytes_per_line + W * 4]
            out[y * W * 3:(y + 1) * W * 3:3] = row[2::4]
            out[y * W * 3 + 1:(y + 1) * W * 3:3] = row[1::4]
            out[y * W * 3 + 2:(y + 1) * W * 3:3] = row[0::4]
        return bytes(out)

    def find(self, name):
        r, p, kids, n = UL(), UL(), ctypes.POINTER(UL)(), ctypes.c_uint()
        X.XQueryTree(self.d, self.root, ctypes.byref(r), ctypes.byref(p), ctypes.byref(kids), ctypes.byref(n))
        found = []
        for i in range(n.value):
            s = ctypes.c_char_p()
            if X.XFetchName(self.d, kids[i], ctypes.byref(s)) and s.value == name.encode():
                found.append(kids[i])
        return found

    def shape(self, win, kind):
        n, order = ctypes.c_int(), ctypes.c_int()
        p = XEXT.XShapeGetRectangles(self.d, win, kind, ctypes.byref(n), ctypes.byref(order))
        rs = ctypes.cast(p, ctypes.POINTER(XRect)) if p else None
        return [(rs[i].x, rs[i].y, rs[i].width, rs[i].height) for i in range(n.value)] if rs else []

    def click(self, x, y):
        XTST.XTestFakeMotionEvent(self.d, -1, x, y, 0)
        XTST.XTestFakeButtonEvent(self.d, 1, 1, 0)
        XTST.XTestFakeButtonEvent(self.d, 1, 0, 0)
        X.XSync(self.d, 0)

    def presses(self):
        """Button presses received by our windows since the last call: [(window, x, y)]."""
        out = []
        ev = ctypes.create_string_buffer(192)
        while X.XPending(self.d):
            X.XNextEvent(self.d, ev)
            if struct.unpack_from("i", ev.raw, 0)[0] == ButtonPress:
                # XButtonEvent: type, serial, send_event, display, window, root, subwindow, time, x, y
                win = struct.unpack_from("L", ev.raw, 32)[0]
                x, y = struct.unpack_from("ii", ev.raw, 64)
                out.append((win, x, y))
        return out


# ---------------------------------------------------------------- helper process


class Helper:
    def __init__(self, exe, env, *args):
        self.p = subprocess.Popen([exe, "--backend", "x11", "--stats-ms", "1000", *args], env=env,
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        self.q = queue.Queue()
        self.lines = []
        self.last = {}
        threading.Thread(target=self._read, daemon=True).start()

    def _read(self):
        for line in self.p.stdout:
            self.q.put(json.loads(line))

    def send(self, cmd):
        self.p.stdin.write(cmd + "\n")
        self.p.stdin.flush()

    def pump(self):
        while True:
            try:
                m = self.q.get_nowait()
            except queue.Empty:
                return
            self.lines.append(m)
            self.last = m

    def wait(self, pred, timeout, what):
        end = time.time() + timeout
        while time.time() < end:
            self.pump()
            if self.last and pred(self.last):
                return self.last
            time.sleep(0.05)
        raise AssertionError(f"timeout waiting for {what}; last state {self.last}; exit {self.p.poll()}")

    def stats(self, seconds):
        """Mean of the stats lines over the next `seconds`."""
        self.pump()
        start = len(self.lines)
        time.sleep(seconds)
        self.pump()
        st = [m for m in self.lines[start:] if "cpu" in m]
        if not st:
            return None
        return {k: sum(m[k] for m in st) / len(st) for k in ("ms", "cpu", "fps")}

    def close(self):
        self.p.stdin.close()
        try:
            return self.p.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.p.kill()
            raise AssertionError("im-blur did not exit after stdin was closed")


# ---------------------------------------------------------------- the test


def check(cond, msg):
    if not cond:
        raise AssertionError(msg)
    print("ok  ", msg)


def canvas(images):
    """Test picture: grey desktop, a pure red block (colour order check) and the images, if any.
    Returns (rgb bytes, [(x, y, w, h) of each image])."""
    rgb = bytearray(b"\x5a\x60\x68" * (W * H))
    for y in range(40, 200):
        for x in range(1100, 1260):
            rgb[(y * W + x) * 3:(y * W + x) * 3 + 3] = b"\xff\x00\x00"
    boxes = []
    if images:
        from PIL import Image
        x0 = 200
        for path in images:
            im = Image.open(path).convert("RGB")
            s = min(560 / im.height, 300 / im.width)
            im = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))))
            y0 = (H - im.height) // 2
            data = im.tobytes()
            for y in range(im.height):
                o = ((y0 + y) * W + x0) * 3
                rgb[o:o + im.width * 3] = data[y * im.width * 3:(y + 1) * im.width * 3]
            boxes.append((x0, y0, im.width, im.height))
            x0 += im.width + 60
    return bytes(rgb), boxes


def covered(rects, box):
    """Fraction of box inside the union of rects (on a coarse grid)."""
    bx, by, bw, bh = box
    inside = total = 0
    for gy in range(by, by + bh, 4):
        for gx in range(bx, bx + bw, 4):
            total += 1
            inside += any(x <= gx < x + w and y <= gy < y + h for x, y, w, h in rects)
    return inside / max(1, total)


def pixel(rgb, x, y):
    o = (y * W + x) * 3
    return tuple(rgb[o:o + 3])


def main():
    ap = argparse.ArgumentParser()
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    ap.add_argument("--im-blur", default=os.path.join(root, "build/im-blur"))
    ap.add_argument("--models", default=os.path.join(root, "models/vision"))
    ap.add_argument("--image", action="append", default=[])
    ap.add_argument("--xvfb", default="Xvfb")
    ap.add_argument("--xkbdir")
    ap.add_argument("--display", default=":91")
    ap.add_argument("--extra", action="append", default=[], help="more im-blur arguments for the first run")
    ap.add_argument("--compositor", help="compositing manager command to run first, e.g. 'xcompmgr -a'")
    ap.add_argument("--shot", help="save what the screen shows with the covers (PNG, needs Pillow)")
    a = ap.parse_args()

    cmd = [a.xvfb, a.display, "-screen", "0", f"{W}x{H}x24", "-nolisten", "tcp", "-nolisten", "unix",
           "-listen", "local", "+extension", "XTEST"]
    if a.xkbdir:
        cmd += ["-xkbdir", a.xkbdir]
    xvfb = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    try:
        d = None
        for _ in range(100):
            try:
                d = Display(a.display)
                break
            except RuntimeError:
                time.sleep(0.05)
        if not d:
            sys.exit(f"Xvfb did not start: {xvfb.stderr.read().decode()[-500:]}")
        env = {**os.environ, "DISPLAY": a.display}
        env.pop("WAYLAND_DISPLAY", None)
        comp = None
        if a.compositor:
            comp = subprocess.Popen(a.compositor.split(), env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(1.0)
            check(comp.poll() is None, f"compositing manager running: {a.compositor}")

        rgb, boxes = canvas(a.image)
        bg = d.window(0, 0, W, H)
        d.put(bg, rgb, W, H)
        d.presses()

        # 1. people (or none), self-test, colours, click-through, cost
        dump = os.path.join(os.environ.get("TMPDIR", "/tmp"), f"im-blur-frame-{os.getpid()}.ppm")
        h = Helper(a.im_blur, env, "--models", a.models, "--policy", "1", "--dump-frame", dump, *a.extra)
        st = h.wait(lambda m: m["state"] not in ("starting",), 30, "the self-test")
        check(st["state"] == "on_covers_visible" and st["backend"] == "x11" and st["overlay"] == "x11",
              f"state after the self-test: {st['state']} (overlay in the root capture -> covers-visible mode)")
        wins = d.find("waaiya-blur")
        check(len(wins) == 1, "one overlay window for the one monitor")
        ov = wins[0]
        check(d.shape(ov, ShapeInput) == [], "the overlay's input shape is empty (clicks pass through)")
        # people close together are drawn as one cover (im_cover merge_gap): at least one cover when there are any
        h.wait(lambda m: m.get("covers", 0) >= min(1, len(boxes)), 20, "the covers")
        time.sleep(1.0)
        for _ in range(50):
            if os.path.exists(dump):
                break
            time.sleep(0.1)
        with open(dump, "rb") as f:
            ppm = f.read()
        hdr = ppm.split(b"\n", 3)
        fw, fh = map(int, hdr[1].split())
        frame = hdr[3]
        check((fw, fh) == (640, 400), f"analysed frame {fw}x{fh} (long side 640)")
        fx, fy = 1180 * fw // W, 120 * fh // H
        r, g, b = frame[(fy * fw + fx) * 3:(fy * fw + fx) * 3 + 3]
        check(r > 200 and g < 40 and b < 40, f"red reaches the models as red ({r},{g},{b}), not swapped with blue")
        os.unlink(dump)
        shape = d.shape(ov, ShapeBounding)
        screen = d.grab()
        for i, box in enumerate(boxes):
            c = covered(shape, box)
            check(c >= 0.9, f"woman {i + 1} at {box}: {c:.0%} of her picture is inside the overlay's shape")
            cx, cy = box[0] + box[2] // 2, box[1] + box[3] // 2
            check(pixel(screen, cx, cy) != pixel(rgb, cx, cy), f"woman {i + 1}: the screen shows the blur, not the picture")
        if not boxes:
            check(shape == [], "nothing to cover: the overlay shows nothing")
        tx, ty = (boxes[0][0] + boxes[0][2] // 2, boxes[0][1] + boxes[0][3] // 2) if boxes else (640, 400)
        d.presses()
        d.click(tx, ty)
        time.sleep(0.2)
        got = d.presses()
        check((bg, tx, ty) in got, f"a click on {'a cover' if boxes else 'the screen'} reaches the window underneath")
        if a.shot:
            from PIL import Image
            Image.frombytes("RGB", (W, H), d.grab()).save(a.shot)
            print("     screenshot:", a.shot)
        still = h.stats(4.0)
        print(f"     still screen: {still}")

        # a changing screen (like a video): the picture moves every 100 ms
        stop = threading.Event()

        def animate():
            k = 0
            shifted = [rgb[(i * 3 % W) * 3:] + rgb[:(i * 3 % W) * 3] for i in range(8)]
            dd = Display(a.display)
            while not stop.is_set():
                dd.put(bg, shifted[k % 8], W, H)
                k += 1
                time.sleep(0.1)

        t = threading.Thread(target=animate, daemon=True)
        t.start()
        time.sleep(1.0)
        moving = h.stats(5.0)
        stop.set()
        t.join()
        print(f"     changing screen: {moving}")
        d.put(bg, rgb, W, H)
        check(h.close() == 0, "stdin closed -> im-blur exits")
        check(d.find("waaiya-blur") == [], "its overlay window is gone")

        # 2. nudity cover, forced: whole screen, opaque, clicks pass; nudity off -> it clears
        h = Helper(a.im_blur, env, "--models", a.models, "--policy", "2", "--nsfw-score", "0.000001")
        h.wait(lambda m: m["state"] == "on_covers_visible" and m.get("covers", 0) >= 1, 30, "the nudity cover")
        time.sleep(0.5)
        ov = d.find("waaiya-blur")[0]
        check(d.shape(ov, ShapeBounding) == [(0, 0, W, H)], "nudity: the cover is the whole screen")
        check(pixel(d.grab(), 640, 400) == (0x2b, 0x2d, 0x31), "nudity: the cover is opaque")
        d.presses()
        d.click(300, 300)
        time.sleep(0.2)
        check((bg, 300, 300) in d.presses(), "nudity: clicks still reach the window underneath")
        h.send("policy 1")
        h.wait(lambda m: m.get("covers", 1) == min(1, len(boxes)) and m["state"] == "on_covers_visible", 15,
               "the nudity cover to clear")
        time.sleep(0.5)
        end = time.time() + 10  # the tracker holds a nudity cover a few seconds
        while (0, 0, W, H) in d.shape(ov, ShapeBounding) and time.time() < end:
            time.sleep(0.2)
        check((0, 0, W, H) not in d.shape(ov, ShapeBounding), "nudity off: the full cover is gone")
        h.send("quit")
        check(h.p.wait(timeout=5) == 0, "'quit' -> im-blur exits")

        # 3. fail closed: no models
        h = Helper(a.im_blur, env, "--models", "/nonexistent", "--policy", "1", "--fail-cover", "1")
        st = h.wait(lambda m: m["state"] == "models_missing", 30, "models_missing")
        check(st["error"] != "", f"models_missing explains: {st['error'][:80]}")
        time.sleep(1.0)
        ov = d.find("waaiya-blur")[0]
        check(d.shape(ov, ShapeBounding) == [(0, 0, W, H)], "fail_cover 1: the whole screen is covered")
        d.presses()
        d.click(500, 500)
        time.sleep(0.2)
        check((bg, 500, 500) in d.presses(), "fail cover: clicks still reach the window underneath")
        h.send("fail_cover 0")
        time.sleep(1.2)
        sh = d.shape(ov, ShapeBounding)
        check(len(sh) == 1 and sh[0][1] == 0 and sh[0][2] == W and sh[0][3] <= 12,
              f"fail_cover 0: only a red bar at the top {sh}")
        check(pixel(d.grab(), 640, 2) == (0xd3, 0x2f, 0x2f), "the bar is red")
        h.close()
        if comp:
            check(comp.poll() is None, "the compositing manager is still running")
            comp.terminate()
        print("all X11 checks passed")
        return 0
    finally:
        xvfb.terminate()
        xvfb.wait()


if __name__ == "__main__":
    sys.exit(main())
