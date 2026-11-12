"""Windows screen blur (waaiya-blur.exe), end to end on a real Windows desktop (CI: a GitHub Windows runner).

    python windows/test/blur_test.py <dir with waaiya-blur.exe, onnxruntime.dll, models/vision/>

The covers are kept out of screen captures (WDA_EXCLUDEFROMCAPTURE), so a screenshot cannot show them: the checks
ask Windows about the cover windows instead, and click through them onto a window of this test.
  1. the self-test: state "on" (the covers are kept out of the capture) or "on_covers_visible" (they are not:
     older Windows); a nudity cover (--fake-nudity) covers the whole monitor, on top
  2. clicks pass through the cover to the window under it
  3. policy 0 (blur off): the cover goes, state idle
  4. fail closed: models missing -> models_missing, the whole screen covered, then the red bar
  5. the real models run on the runner's desktop (ms per frame, CPU)
  6. stdin closed (the app is gone) -> the helper exits
  7. the GDI capture (where desktop duplication is not available) works the same way
"""
import ctypes
import ctypes.wintypes as wt
import json
import os
import queue
import subprocess
import sys
import tempfile
import threading
import time

BIN = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "build-win")
BLUR = os.path.join(BIN, "waaiya-blur.exe")
MODELS = os.path.join(BIN, "models", "vision")
TMP = tempfile.mkdtemp(prefix="waaiya-blur-")
user32 = ctypes.windll.user32
user32.SetProcessDpiAwarenessContext(ctypes.c_void_p(-4))  # per monitor v2: physical pixels, as the helper
failures = []


def check(ok, what):
    print(("PASS " if ok else "FAIL ") + what, flush=True)
    if not ok:
        failures.append(what)


class Helper:
    def __init__(self, *args, env=None):
        e = dict(os.environ)
        e.update(env or {})
        self.p = subprocess.Popen([BLUR, "--models", MODELS, "--stats-ms", "1000", *map(str, args)],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=e,
                                  text=True, bufsize=1)
        self.q = queue.Queue()
        self.last = {}
        threading.Thread(target=self._read, daemon=True).start()

    def _read(self):
        for line in self.p.stdout:
            try:
                self.q.put(json.loads(line))
            except ValueError:
                print("  helper: " + line.rstrip(), flush=True)
        self.q.put(None)

    def wait(self, pred, timeout):
        end = time.time() + timeout
        while time.time() < end:
            try:
                r = self.q.get(timeout=max(0.05, end - time.time()))
            except queue.Empty:
                break
            if r is None:
                return None
            self.last = r
            if pred(r):
                return r
        return None

    def send(self, line):
        self.p.stdin.write(line + "\n")
        self.p.stdin.flush()

    def stop(self):
        try:
            self.p.stdin.close()
        except OSError:
            pass
        try:
            self.p.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.p.kill()
        err = self.p.stderr.read()
        if err.strip():
            print("  stderr: " + err.strip()[-600:], flush=True)


def covers():
    """Visible cover windows: [(left, top, right, bottom)]."""
    found = []
    proc = ctypes.WINFUNCTYPE(wt.BOOL, wt.HWND, wt.LPARAM)

    def each(h, _):
        cls = ctypes.create_unicode_buffer(64)
        user32.GetClassNameW(h, cls, 64)
        if cls.value == "WaaiyaBlurCover" and user32.IsWindowVisible(h):
            r = wt.RECT()
            user32.GetWindowRect(h, ctypes.byref(r))
            found.append((r.left, r.top, r.right, r.bottom))
        return True

    user32.EnumWindows(proc(each), 0)
    return found


def screen():
    # primary monitor, physical pixels
    return (0, 0, user32.GetSystemMetrics(0), user32.GetSystemMetrics(1))


def click_through():
    """A window of this test under the cover: does a click in its middle reach it?"""
    flag = os.path.join(TMP, "clicked")
    script = os.path.join(TMP, "target.py")
    with open(script, "w") as f:
        f.write(
            "import tkinter as tk, sys\n"
            "r = tk.Tk(); r.geometry('400x300+200+200'); r.configure(bg='#3366cc')\n"
            "def hit(e):\n"
            "    open(sys.argv[1], 'w').write('1'); r.destroy()\n"
            "r.bind('<Button-1>', hit); r.after(20000, r.destroy); r.mainloop()\n")
    t = subprocess.Popen([sys.executable, script, flag])
    time.sleep(2.0)
    # the window's middle, in physical pixels (tk is not DPI aware: ask Windows where it is)
    h = user32.FindWindowW("TkTopLevel", None)
    r = wt.RECT()
    user32.GetWindowRect(h, ctypes.byref(r))
    x, y = (r.left + r.right) // 2, (r.top + r.bottom) // 2
    user32.SetCursorPos(x, y)
    time.sleep(0.2)
    user32.mouse_event(0x0002, 0, 0, 0, 0)  # left down
    user32.mouse_event(0x0004, 0, 0, 0, 0)  # left up
    for _ in range(30):
        if os.path.exists(flag):
            break
        time.sleep(0.1)
    t.kill()
    return os.path.exists(flag)


def main():
    sw = screen()
    print(f"primary monitor {sw}", flush=True)

    print("=== 1. self-test and a whole-screen nudity cover", flush=True)
    h = Helper("--policy", 2, "--fake-nudity", 1)
    r = h.wait(lambda r: r.get("state") in ("on", "on_covers_visible", "no_capture", "no_overlay", "models_missing"), 20)
    print(f"  state: {r or h.last}", flush=True)
    check(r is not None and r["state"] in ("on", "on_covers_visible"), "the blur runs")
    check(r is not None and r["state"] == "on", "the covers are kept out of the screen capture (state on)")
    time.sleep(1.5)
    c = covers()
    print(f"  cover windows: {c}", flush=True)
    check(any(x[0] <= sw[0] and x[1] <= sw[1] and x[2] >= sw[2] and x[3] >= sw[3] for x in c),
          "a cover spans the whole primary monitor")

    print("=== 2. clicks pass through the cover", flush=True)
    check(click_through(), "a click on the cover reaches the window under it")

    print("=== 3. blur off: the cover goes", flush=True)
    h.send("policy 0")
    r = h.wait(lambda r: r.get("state") == "idle", 5)
    time.sleep(0.5)
    check(r is not None, "state idle")
    check(covers() == [], f"no cover shown ({covers()})")
    h.stop()
    check(h.p.returncode is not None, "stdin closed: the helper exits")

    print("=== 4. fail closed: models missing", flush=True)
    h = Helper("--policy", 3, "--fail-cover", 1, "--models", os.path.join(TMP, "none"))
    r = h.wait(lambda r: r.get("state") == "models_missing", 20)
    check(r is not None, f"state models_missing ({h.last})")
    time.sleep(1.0)
    c = covers()
    check(any(x[2] - x[0] >= sw[2] and x[3] - x[1] >= sw[3] for x in c), f"the whole screen is covered ({c})")
    time.sleep(5.0)
    c = covers()
    bar = [x for x in c if x[3] - x[1] < 60]
    check(bar and not any(x[3] - x[1] >= sw[3] for x in c), f"then only the red bar ({c})")
    h.stop()

    print("=== 5. the real models on the runner's desktop", flush=True)
    h = Helper("--policy", 3)
    r = h.wait(lambda r: "ms" in r and r.get("state") in ("on", "on_covers_visible"), 40)
    print(f"  {r or h.last}", flush=True)
    check(r is not None, "the models run (ms per frame reported)")
    h.stop()

    print("=== 6. the GDI capture", flush=True)
    h = Helper("--policy", 2, "--fake-nudity", 1, env={"WAAIYA_BLUR_GDI": "1"})
    r = h.wait(lambda r: r.get("state") in ("on", "on_covers_visible", "no_capture", "no_overlay"), 20)
    print(f"  state: {r or h.last}", flush=True)
    check(r is not None and r["state"] in ("on", "on_covers_visible"), "the blur runs with GDI")
    time.sleep(1.5)
    check(any(x[2] - x[0] >= sw[2] for x in covers()), "the nudity cover shows")
    h.stop()

    print()
    if failures:
        print(f"{len(failures)} check(s) failed:\n  " + "\n  ".join(failures))
        sys.exit(1)
    print("all checks passed")


if __name__ == "__main__":
    main()
