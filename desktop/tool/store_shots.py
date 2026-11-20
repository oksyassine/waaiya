"""Real Store screenshots of the installed Waaiya package on this PC, one folder per language.

    python desktop/tool/store_shots.py [--out desktop/windows/msix/screenshots] [--lang en ar ...] [--size 1366x768]

For each language: writes it into %APPDATA%\\Waaiya\\settings.json, starts the package's app, places the window at the
given size in logical pixels (the visible frame is made exactly that size; real pixels at the screen's scale), clicks through the bottom bar and
saves the window's visible frame in real pixels: 1-filter.png, 2-links.png, 3-screen.png, 4-settings.png. Start the
filter first so that the first picture shows it on. The settings file is restored at the end. Windows only; needs the
package (Oks.Waaiya) installed. No third-party Python modules: the PNG is written with zlib.
"""
import argparse
import ctypes
import ctypes.wintypes as wt
import json
import os
import struct
import subprocess
import sys
import time
import zlib

LANGS = ["ar", "en", "fr", "ur", "id", "tr", "bn", "fa", "ms", "es", "nl", "de", "it", "ru", "uz", "sw", "ha", "so"]
RTL = {"ar", "ur", "fa"}
PAGES = ["1-filter", "3-screen", "2-links", "4-settings"]  # bottom bar order: Filter, Screen, Links, Settings
APP = r"shell:AppsFolder\Oks.Waaiya_wa2h0h9gfqbyp!Waaiya"

user32, gdi32, dwm = ctypes.windll.user32, ctypes.windll.gdi32, ctypes.windll.dwmapi
user32.SetProcessDpiAwarenessContext(ctypes.c_void_p(-4))  # per monitor v2: real pixels


def app_window(timeout=20):
    """The visible top-level window of waaiya_desktop.exe."""
    end = time.time() + timeout
    found = []

    @ctypes.WINFUNCTYPE(wt.BOOL, wt.HWND, wt.LPARAM)
    def each(h, _):
        if not user32.IsWindowVisible(h):
            return True
        pid = wt.DWORD()
        user32.GetWindowThreadProcessId(h, ctypes.byref(pid))
        q = ctypes.windll.kernel32.OpenProcess(0x1000, False, pid.value)
        if q:
            buf = ctypes.create_unicode_buffer(520)
            n = wt.DWORD(520)
            if ctypes.windll.kernel32.QueryFullProcessImageNameW(q, 0, buf, ctypes.byref(n)) and \
                    buf.value.lower().endswith("waaiya_desktop.exe"):
                title = ctypes.create_unicode_buffer(64)
                user32.GetWindowTextW(h, title, 64)
                if title.value:
                    found.append(h)
            ctypes.windll.kernel32.CloseHandle(q)
        return True

    while time.time() < end:
        found.clear()
        user32.EnumWindows(each, 0)
        if found:
            return found[0]
        time.sleep(0.25)
    raise SystemExit("the app's window did not appear")


def frame(h):
    """The window's visible frame (without Windows 11's invisible resize borders), real pixels."""
    r = wt.RECT()
    dwm.DwmGetWindowAttribute(h, 9, ctypes.byref(r), ctypes.sizeof(r))  # DWMWA_EXTENDED_FRAME_BOUNDS
    return r.left, r.top, r.right, r.bottom


def save_png(path, x, y, w, h):
    sdc = user32.GetDC(None)
    mdc = gdi32.CreateCompatibleDC(sdc)
    bmp = gdi32.CreateCompatibleBitmap(sdc, w, h)
    gdi32.SelectObject(mdc, bmp)
    gdi32.BitBlt(mdc, 0, 0, w, h, sdc, x, y, 0x00CC0020)  # SRCCOPY

    class BIH(ctypes.Structure):
        _fields_ = [("size", wt.DWORD), ("w", wt.LONG), ("h", wt.LONG), ("planes", wt.WORD), ("bits", wt.WORD),
                    ("comp", wt.DWORD), ("img", wt.DWORD), ("xp", wt.LONG), ("yp", wt.LONG), ("used", wt.DWORD),
                    ("imp", wt.DWORD)]

    bi = BIH(ctypes.sizeof(BIH), w, -h, 1, 32, 0, 0, 0, 0, 0, 0)  # top-down BGRA
    buf = ctypes.create_string_buffer(w * h * 4)
    gdi32.GetDIBits(mdc, bmp, 0, h, buf, ctypes.byref(bi), 0)
    gdi32.DeleteObject(bmp)
    gdi32.DeleteDC(mdc)
    user32.ReleaseDC(None, sdc)
    raw = buf.raw
    rows = bytearray()
    for row in range(h):
        line = raw[row * w * 4:(row + 1) * w * 4]
        rgb = bytearray(w * 3)
        rgb[0::3], rgb[1::3], rgb[2::3] = line[2::4], line[1::4], line[0::4]
        rows += b"\x00" + rgb

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)) +
                chunk(b"IDAT", zlib.compress(bytes(rows), 9)) + chunk(b"IEND", b""))


def click(x, y):
    user32.SetCursorPos(x, y)
    time.sleep(0.08)
    user32.mouse_event(0x0002, 0, 0, 0, 0)
    user32.mouse_event(0x0004, 0, 0, 0, 0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "windows", "msix", "screenshots"))
    ap.add_argument("--lang", nargs="*", default=LANGS)
    ap.add_argument("--size", default="1366x768")
    a = ap.parse_args()
    lw, lh = map(int, a.size.split("x"))
    settings = os.path.join(os.environ["APPDATA"], "Waaiya", "settings.json")
    saved = open(settings, "rb").read()
    try:
        for lang in a.lang:
            j = json.loads(saved.decode("utf-8"))
            j["lang"] = lang
            with open(settings, "w", encoding="utf-8") as f:
                json.dump(j, f, ensure_ascii=False, indent=2)
            subprocess.run(["taskkill", "/IM", "waaiya_desktop.exe", "/F"], capture_output=True)
            time.sleep(0.5)
            os.startfile(APP)
            h = app_window()
            s = user32.GetDpiForWindow(h) / 96
            user32.SetWindowPos(h, None, int(40 * s), int(20 * s), int(lw * s), int(lh * s), 0x0040)
            # the window's rect includes invisible resize borders: grow it until the visible frame is the size asked
            x0, y0, x1, y1 = frame(h)
            dw, dh = int(lw * s) - (x1 - x0), int(lh * s) - (y1 - y0)
            if dw or dh:
                user32.SetWindowPos(h, None, int(40 * s), int(20 * s), int(lw * s) + dw, int(lh * s) + dh, 0x0040)
            user32.SetForegroundWindow(h)
            # on top while it is photographed (Windows may refuse to bring it to the front from a script)
            user32.SetWindowPos(h, ctypes.c_void_p(-1), 0, 0, 0, 0, 0x0001 | 0x0002 | 0x0040)  # HWND_TOPMOST
            time.sleep(3)  # the app reads the filter's state; animations settle
            cr = wt.RECT()
            user32.GetClientRect(h, ctypes.byref(cr))
            o = wt.POINT(0, 0)
            user32.ClientToScreen(h, ctypes.byref(o))
            d = os.path.join(a.out, lang)
            os.makedirs(d, exist_ok=True)
            for i, name in enumerate(PAGES):
                slot = len(PAGES) - 1 - i if lang in RTL else i
                click(o.x + int((slot + 0.5) * cr.right / len(PAGES)), o.y + cr.bottom - int(40 * s))
                user32.SetCursorPos(o.x + int(4 * s), o.y + int(4 * s))  # no hover highlight in the picture
                time.sleep(0.9)
                x0, y0, x1, y1 = frame(h)
                save_png(os.path.join(d, name + ".png"), x0, y0, x1 - x0, y1 - y0)
            print(f"{lang}: {x1 - x0}x{y1 - y0} -> {d}", flush=True)
    finally:
        open(settings, "wb").write(saved)
        subprocess.run(["taskkill", "/IM", "waaiya_desktop.exe", "/F"], capture_output=True)


if __name__ == "__main__":
    sys.exit(main())
