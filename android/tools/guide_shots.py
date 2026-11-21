#!/usr/bin/env python3
"""Takes the pictures of the illustrated setup guide in one language, on an emulator.

    .venv/bin/python android/tools/guide_shots.py --serial emulator-5580 --apk <debug apk> --lang fr [--out DIR]

Needs an API 35 emulator with root (a "userdebug" system image, e.g. the AVD im_ui35) and Pillow (the project's
.venv has it). It switches the emulator to the language (system and app), runs the real on-phone setup (Developer
options must be on, Wi-Fi on) and saves the nine pictures guide_1_about ... guide_9_done as 540-pixel-wide WebP files,
the place to tap marked with a green frame: by default into android/app/src/main/res/drawable-<language>-nodpi
(drawable-nodpi for English, drawable-in-nodpi for Indonesian). SetupGuideActivity and the Flutter setup steps show
them. Check every picture by eye before committing: a menu that moved on a new system image needs a fix here.
"""
import argparse
import io
import re
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from emu_check import Emu, PKG  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
RES = REPO / "android/app/src/main/res"
LOCALES = {"en": "en-US", "ar": "ar-EG", "fr": "fr-FR", "ur": "ur-PK", "id": "in-ID", "tr": "tr-TR", "bn": "bn-BD",
           "fa": "fa-IR", "ms": "ms-MY"}
GREEN = (15, 110, 90)
WIDTH = 540

# Android's own Settings wording on the API 35 emulator (aapt2 dump of its Settings app).
LABELS = {
    "en": {
        "build_number": "Build number",
        "enable_adb_wireless": "Wireless debugging",
        "adb_pair_method_code_title": "Pair device with pairing code",
        "wireless_debugging_main_switch_title": "Use wireless debugging"
    },
    "ar": {
        "build_number": "رقم الإصدار",
        "enable_adb_wireless": "تصحيح الأخطاء اللاسلكي",
        "adb_pair_method_code_title": "إقران الجهاز باستخدام رمز الإقران",
        "wireless_debugging_main_switch_title": "استخدام ميزة \"تصحيح الأخطاء اللاسلكي\""
    },
    "fr": {
        "build_number": "Numéro de build",
        "enable_adb_wireless": "Débogage sans fil",
        "adb_pair_method_code_title": "Associer l'appareil avec un code d'association",
        "wireless_debugging_main_switch_title": "Utiliser le débogage sans fil"
    },
    "ur": {
        "build_number": "بلڈ نمبر",
        "enable_adb_wireless": "وائرلیس ڈیبگنگ",
        "adb_pair_method_code_title": "جوڑا بنانے کے کوڈ کے ذریعے آلہ کا جوڑا بنائیں",
        "wireless_debugging_main_switch_title": "وائرلیس ڈیبگنگ کا استعمال کریں"
    },
    "id": {
        "build_number": "Nomor build",
        "enable_adb_wireless": "Proses debug nirkabel",
        "adb_pair_method_code_title": "Sambungkan perangkat dengan kode penyambungan",
        "wireless_debugging_main_switch_title": "Gunakan proses debug nirkabel"
    },
    "tr": {
        "build_number": "Derleme numarası",
        "enable_adb_wireless": "Kablosuz hata ayıklama",
        "adb_pair_method_code_title": "Eşleme kodu ile cihaz eşle",
        "wireless_debugging_main_switch_title": "Kablosuz hata ayıklamayı kullan"
    },
    "bn": {
        "build_number": "বিল্ড নম্বর",
        "enable_adb_wireless": "ওয়্যারলেস ডিবাগিং",
        "adb_pair_method_code_title": "পেয়ারিং কোড ব্যবহার করে ডিভাইসের সাথে পেয়ার করুন",
        "wireless_debugging_main_switch_title": "ওয়্যারলেস ডিবাগিং বিকল্প ব্যবহার করুন"
    },
    "fa": {
        "build_number": "شمارهٔ ساخت",
        "enable_adb_wireless": "اشکال‌زدایی بی‌سیم",
        "adb_pair_method_code_title": "جفت کردن دستگاه با کد مرتبط‌سازی",
        "wireless_debugging_main_switch_title": "استفاده از اشکال‌زدایی بی‌سیم"
    },
    "ms": {
        "build_number": "Nombor binaan",
        "enable_adb_wireless": "Penyahpepijatan wayarles",
        "adb_pair_method_code_title": "Gandingkan peranti dengan kod gandingan",
        "wireless_debugging_main_switch_title": "Gunakan nyahpepijat wayarles"
    }
}


class Node:
    def __init__(self, el):
        self.rid = el.get("resource-id", "")
        self.text = el.get("text", "")
        self.desc = el.get("content-desc", "")
        x1, y1, x2, y2 = map(int, re.findall(r"\d+", el.get("bounds", "[0,0][0,0]")))
        self.box = (x1, y1, x2, y2)
        self.clickable = el.get("clickable") == "true"

    @property
    def centre(self):
        return (self.box[0] + self.box[2]) // 2, (self.box[1] + self.box[3]) // 2


def norm(s):
    return re.sub(r"\s+", " ", s.replace("‏", "").replace("‎", "")).strip()


class Shooter:
    def __init__(self, e: Emu, lang: str, out: Path):
        self.e, self.lang, self.out = e, lang, out
        self.labels = LABELS[lang]
        folder = "values" if lang == "en" else "values-" + ("in" if lang == "id" else lang)
        app = ET.parse(RES / folder / "strings.xml").getroot()
        self.app_name = next(el.text for el in app if el.get("name") == "app_name")

    # --- screen
    def tree(self):
        for _ in range(5):
            self.e.sh("uiautomator dump /sdcard/guide.xml")
            xml = self.e.sh("cat /sdcard/guide.xml")
            try:
                root = ET.fromstring(xml[xml.index("<?xml"):])
                return [Node(el) for el in root.iter("node")]
            except (ValueError, ET.ParseError):
                time.sleep(1)
        raise SystemExit("uiautomator dump failed")

    def find(self, pred, tries=10, swipe=False):
        for _ in range(tries):
            for n in self.tree():
                if pred(n):
                    return n
            if swipe:
                self.e.sh("input swipe 540 1700 540 1100 400")
            time.sleep(1)
        return None

    def need(self, what, pred, **kw):
        n = self.find(pred, **kw)
        if n is None:
            shot = Path(tempfile.gettempdir()) / f"guide_shots_{self.lang}_failed.png"
            self.screenshot().save(shot)
            texts = [f"(screen: {shot})"] + [norm(x.text) for x in self.tree() if x.text]
            raise SystemExit(f"{self.lang}: not on screen: {what}\n" + "\n".join(texts[:40]))
        return n

    def scroll(self, y_from, y_to):
        """Moves a row from y_from up to y_to; never starts at the bottom edge (Android takes that for "go home")."""
        start = min(y_from, 1900)
        self.e.sh(f"input swipe 540 {start} 540 {y_to - (y_from - start)} 800")
        time.sleep(2)

    def tap(self, n):
        self.e.sh(f"input tap {n.centre[0]} {n.centre[1]}")
        time.sleep(2)

    def screenshot(self):
        png = subprocess.run(self.e.base + ["exec-out", "screencap", "-p"], capture_output=True, timeout=60).stdout
        return Image.open(io.BytesIO(png)).convert("RGB")

    def row(self, n):
        """The list row around a title: the smallest clickable node containing it."""
        best = None
        for m in self.tree():
            b = m.box
            if m.clickable and b[0] <= n.box[0] and b[1] <= n.box[1] and b[2] >= n.box[2] and b[3] >= n.box[3]:
                if best is None or (b[2] - b[0]) * (b[3] - b[1]) < (best.box[2] - best.box[0]) * (best.box[3] - best.box[1]):
                    best = m
        return best or n

    def save(self, name, top, bottom, marks, img=None):
        img = img or self.screenshot()
        d = ImageDraw.Draw(img)
        for x1, y1, x2, y2 in marks:
            pad = 10
            box = (max(4, x1 - pad), y1 - pad, min(img.width - 4, x2 + pad), y2 + pad)
            d.rounded_rectangle(box, radius=28, outline=(255, 255, 255), width=14)
            d.rounded_rectangle(box, radius=28, outline=GREEN, width=8)
        top, bottom = max(0, top), min(img.height, bottom)
        crop = img.crop((0, top, img.width, bottom))
        crop = crop.resize((WIDTH, round(crop.height * WIDTH / crop.width)), Image.LANCZOS)
        self.out.mkdir(parents=True, exist_ok=True)
        crop.save(self.out / f"{name}.webp", "WEBP", quality=80, method=6)
        print(f"{self.lang}: {name} {crop.size}")

    # --- the run
    def prepare(self, apk):
        e = self.e
        e.adb("root"); time.sleep(3)
        # A new phone each time: the language, and no paired computer or trusted Wi-Fi network (Android would skip
        # its "Allow wireless debugging on this network?" question); both take effect when the system restarts.
        e.sh("settings put global adb_wifi_enabled 0")
        e.sh(f"setprop persist.sys.locale {LOCALES[self.lang]}; rm -f /data/misc/adb/adb_temp_keys.xml; "
             "stop; sleep 2; start")
        time.sleep(20)
        for _ in range(60):
            if "mResumedActivity" in e.sh("dumpsys activity activities") and \
                    e.sh("getprop sys.boot_completed").strip() == "1":
                break
            time.sleep(3)
        time.sleep(10)
        for k in ("window_animation_scale", "transition_animation_scale", "animator_duration_scale"):
            e.sh(f"settings put global {k} 0")
        e.sh("settings put global development_settings_enabled 1")
        e.sh("svc wifi enable; svc power stayon true; input keyevent KEYCODE_WAKEUP; wm dismiss-keyguard")
        if apk:
            out = e.adb("install", "-r", apk, timeout=300)
            if "INSTALL_FAILED_UPDATE_INCOMPATIBLE" in out:  # another signing key (a release build): start afresh
                e.adb("uninstall", PKG)
                out = e.adb("install", apk, timeout=300)
            if "Success" not in out:
                raise SystemExit(f"install failed: {out[-500:]}")
        print(f"{self.lang}: Waaiya " + re.search(r"versionName=(\S+)", e.sh(f"dumpsys package {PKG}")).group(1) +
              ", installed " + re.search(r"lastUpdateTime=(.+)", e.sh(f"dumpsys package {PKG}")).group(1).strip())
        e.sh(f"am force-stop {PKG}; pm clear {PKG}")
        # a new phone: none of the setup's grants (a run before this one, or an install with -g, made them)
        e.sh(f"pm revoke {PKG} android.permission.DUMP; pm revoke {PKG} android.permission.WRITE_SECURE_SETTINGS; "
             f"appops set {PKG} PROJECT_MEDIA default")
        e.sh(f"pm grant {PKG} android.permission.RECORD_AUDIO; pm grant {PKG} android.permission.POST_NOTIFICATIONS")
        e.sh(f"cmd locale set-app-locales {PKG} --locales {LOCALES[self.lang].split('-')[0]}")
        e.sh("cmd statusbar collapse")

    def view_rows(self):
        """(title box, row box) of every visible Settings row, from the view tree that `dumpsys activity top` prints.
        For the About page: it updates its "Up time" every second, so uiautomator never finds it idle."""
        out = self.e.sh("dumpsys activity top")
        part = out[out.rindex("View Hierarchy:"):]
        stack, rows = [], []
        for line in part.splitlines():
            m = re.match(r"^(\s*)\S+\{[0-9a-f]+ (\S+) \S+ (-?\d+),(-?\d+)-(-?\d+),(-?\d+)(?: #[0-9a-f]+ ?([^\s}]*)[^}]*)?\}",
                         line)
            if not m:
                continue
            ind, flags, rid = len(m.group(1)), m.group(2), m.group(7) or ""
            l, t, r, b = map(int, m.group(3, 4, 5, 6))
            while stack and stack[-1][0] >= ind:
                stack.pop()
            px, py = (stack[-1][1], stack[-1][2]) if stack else (0, 0)
            box = (px + l, py + t, px + r, py + b)
            visible = flags[0] == "V" and all(s[3] for s in stack)
            stack.append((ind, box[0], box[1], visible, box))
            if rid == "android:id/title" and visible:
                row = next((s[4] for s in reversed(stack[:-1]) if s[4][2] - s[4][0] >= 1000), box)
                rows.append((box, row))
        return rows

    def about(self):
        """About phone, Build number marked: the page's last row (scrolled to the end)."""
        e = self.e
        e.sh("am force-stop com.android.settings")
        e.sh("am start -W -a android.settings.DEVICE_INFO_SETTINGS"); time.sleep(3)
        for _ in range(4):
            e.sh("input swipe 540 2000 540 500 300")
        time.sleep(3)
        rows = [r for t, r in self.view_rows() if r[3] <= 2400]
        row = max(rows, key=lambda r: r[1])
        self.save("guide_1_about", row[1] - 400, row[3] + 14, [row])
        e.sh("input keyevent KEYCODE_BACK")

    def run(self):
        e = self.e
        self.about()
        # Waaiya's Setup page, step 3: its button opens Developer options and starts listening for the code
        e.sh(f"am start -W -n {PKG}/.MainActivity"); time.sleep(6)
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        if self.find(lambda n: n.rid == "choose_man", tries=15):
            self.tap(self.need("choose_man", lambda n: n.rid == "choose_man"))
        nav = self.need("Setup tab", lambda n: n.rid == "nav_setup", tries=20)
        self.tap(nav); time.sleep(2)
        start = self.need("Waaiya's start button", lambda n: n.rid == "wsetup_start", swipe=True)
        if start.box[1] > 1700:
            self.scroll(start.box[1], 1300); time.sleep(2)
            start = self.need("Waaiya's start button", lambda n: n.rid == "wsetup_start")
        self.save("guide_5_start", start.box[1] - 330, start.box[3] + 60, [start.box])
        self.tap(start); time.sleep(4)
        if self.find(lambda n: n.rid == "android:id/button1" and n.box[1] > 1000, tries=2):  # notification question
            self.tap(self.need("allow", lambda n: n.rid == "android:id/button1"))
        # Developer options at Wireless debugging
        wd = self.need("Wireless debugging", lambda n: n.rid == "android:id/title" and
                       norm(n.text) == norm(self.labels["enable_adb_wireless"]), swipe=True, tries=20)
        if wd.box[1] > 1600 or wd.box[1] < 700:
            self.scroll(wd.box[1], 1100); time.sleep(2)
            wd = self.need("Wireless debugging", lambda n: n.rid == "android:id/title" and
                           norm(n.text) == norm(self.labels["enable_adb_wireless"]))
        r = self.row(wd)
        self.save("guide_2_dev", r.box[1] - 520, r.box[3] + 40, [r.box])
        self.tap(wd); time.sleep(2)
        # the Wireless debugging page: the switch, then Android's question
        sw = self.need("Use wireless debugging", lambda n: norm(n.text) == norm(self.labels["wireless_debugging_main_switch_title"]))
        self.tap(sw); time.sleep(2)
        ok = self.need("Allow", lambda n: n.rid == "android:id/button1")
        title = self.find(lambda n: n.rid in ("android:id/alertTitle", "android:id/title_template"), tries=2)
        self.save("guide_3_allow", (title.box[1] if title else ok.box[1] - 700) - 90, ok.box[3] + 70, [ok.box])
        self.tap(ok); time.sleep(4)
        pair = self.need("Pair device with pairing code",
                         lambda n: norm(n.text) == norm(self.labels["adb_pair_method_code_title"]), swipe=True)
        r = self.row(pair)
        self.save("guide_4_pair", 150, r.box[3] + 30, [r.box])
        self.tap(pair); time.sleep(3)
        code = self.need("pairing code", lambda n: n.rid.endswith("pairing_code") and n.text.strip())
        title = self.find(lambda n: n.rid in ("android:id/alertTitle", "android:id/title_template"), tries=2)
        cancel = self.find(lambda n: n.rid == "android:id/button2", tries=2)
        self.save("guide_6_code", (title.box[1] if title else code.box[1] - 250) - 80,
                  (cancel.box[3] if cancel else code.box[3] + 400) + 60, [code.box])
        digits = code.text.strip()
        # Waaiya's notification: Enter code
        time.sleep(4)
        e.sh("cmd statusbar expand-notifications"); time.sleep(3)
        head = self.need("Waaiya's notification", lambda n: n.rid == "android:id/app_name_text" and
                         norm(n.text) == norm(self.app_name), tries=15)
        act = self.need("Enter code", lambda n: n.rid == "android:id/action0" and n.box[1] > head.box[1], tries=10)
        self.save("guide_7_notif", head.box[1] - 60, act.box[3] + 50, [act.box])
        self.tap(act); time.sleep(2)
        e.sh(f"input text {digits}"); time.sleep(2)
        send = self.need("send", lambda n: n.rid.endswith("remote_input_send"))
        head = self.need("Waaiya's notification", lambda n: n.rid == "android:id/app_name_text" and
                         norm(n.text) == norm(self.app_name))
        self.save("guide_8_reply", head.box[1] - 60, send.box[3] + 50, [send.box])
        self.tap(send)
        # "Setup done"
        for _ in range(30):
            time.sleep(2)
            if e.sh(f"dumpsys package {PKG}").count("android.permission.DUMP: granted=true"):
                break
        time.sleep(4)
        e.sh("cmd statusbar collapse"); time.sleep(1)
        e.sh("cmd statusbar expand-notifications"); time.sleep(3)
        nodes = self.tree()
        heads = [i for i, n in enumerate(nodes) if n.rid == "android:id/app_name_text" and norm(n.text) == norm(self.app_name)]
        if not heads:
            raise SystemExit(f"{self.lang}: no Waaiya notification after the setup")
        i = heads[0]
        body = [n for n in nodes[i + 1:i + 12] if n.rid in ("android:id/title", "android:id/text", "android:id/big_text")]
        bottom = max([n.box[3] for n in body] or [nodes[i].box[3] + 300])
        self.save("guide_9_done", nodes[i].box[1] - 60, bottom + 60, [])
        e.sh("cmd statusbar collapse")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--serial", default="emulator-5580")
    ap.add_argument("--apk", help="install this build first (a debug build with the texts of the language)")
    ap.add_argument("--lang", required=True, choices=sorted(LOCALES))
    ap.add_argument("--out", help="folder for the pictures (default: the app's drawable folder for the language)")
    a = ap.parse_args()
    folder = "drawable-nodpi" if a.lang == "en" else f"drawable-{'in' if a.lang == 'id' else a.lang}-nodpi"
    s = Shooter(Emu(a.serial), a.lang, Path(a.out) if a.out else RES / folder)
    s.prepare(a.apk)
    s.run()


if __name__ == "__main__":
    main()
