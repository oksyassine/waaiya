#!/usr/bin/env python3
"""The update goes through the Stop gate: with a waiting period set and the filter running, "Update now" must be
held back (nothing downloaded, nothing installed, the filter keeps running).   prot.py [--serial S]"""
import argparse
import os
import re
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from emu_check import Emu, PKG, strings  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--serial", default="emulator-5580")
a = ap.parse_args()
e = Emu(a.serial)
en = strings("en")
res = []


def check(name, ok, detail=""):
    res.append(ok)
    print(("PASS " if ok else "FAIL ") + name + (f": {detail}" if detail else ""))


def version():
    m = re.search(r"versionCode=(\d+)", e.sh(f"dumpsys package {PKG}"))
    return int(m.group(1)) if m else None


def filtering():
    return "FilterService" in e.sh(f"dumpsys activity services {PKG}")


e.sh(f"run-as {PKG} sh -c 'mkdir -p files && echo https://waaiya.mssid.org/preview/updtest/update.json > files/update-url.txt'")
e.sh(f"appops set {PKG} REQUEST_INSTALL_PACKAGES allow")
e.sh(f"pm grant {PKG} android.permission.POST_NOTIFICATIONS")
e.sh(f"pm grant {PKG} android.permission.RECORD_AUDIO")
e.sh(f"monkey -p {PKG} -c android.intent.category.LAUNCHER 1")
if e.wait(rid="choose_man", seconds=45):
    e.tap(rid="choose_man")
    if not e.wait(rid="power", seconds=5) and e.find(rid="choose_man"):
        e.tap(rid="choose_man")
time.sleep(4)  # the check runs when the app opens (not filtering yet)
# a waiting period of 5 minutes (as if set in the protection card; the app is stopped while the file is edited)
e.sh(f"am force-stop {PKG}")
e.sh(f"""run-as {PKG} sh -c 'sed -i "s|</map>|    <int name=\\"protect_delay_minutes\\" value=\\"5\\" />\\n</map>|" shared_prefs/settings.xml'""")
check("waiting period saved", 'protect_delay_minutes" value="5"' in e.sh(f"run-as {PKG} cat shared_prefs/settings.xml"))
e.sh(f"monkey -p {PKG} -c android.intent.category.LAUNCHER 1")
time.sleep(6)

# start filtering (no setup on this emulator: Waaiya warns, then Android asks to share)
e.page("filter")
e.tap(rid="power")
if e.wait(text=re.escape(en["start_no_setup_title"]), seconds=5):
    e.tap(text=re.escape(en["start_no_setup_anyway"]))
for _ in range(3):
    hit = e.wait(rid="android:id/button1", seconds=10) or e.wait(text=r"^(Start|Start now)$", seconds=3)
    if not hit:
        break
    e.sh(f"input tap {hit[2][0]} {hit[2][1]}")
    time.sleep(2)
check("filtering is on", e.wait(text=re.escape(en["state_on_title"]), seconds=60) is not None and filtering())

e.page("settings")
for _ in range(10):
    if e.find(text=r"^Update now$"):
        break
    e.sh("input swipe 540 1600 540 700 300")
    time.sleep(1)
# no automatic check while filtering: the card offers "Check now" (the user's own request)
if not e.find(text=r"^Update now$"):
    check("no automatic check while filtering", e.find(text=r"^Check now$") is not None)
    e.tap(text=r"^Check now$")
    e.wait(text=r"^Update now$", seconds=30)
check("card offers the update while filtering", e.find(text=r"^Update now$") is not None)
e.adb("logcat", "-c")
e.tap(text=r"^Update now$")
time.sleep(10)
screen = " | ".join(t for _, t, _ in e.nodes() if t)
check("held back: the protection prompt shows", re.search(r"(?i)wait|minute|PIN", screen) is not None, screen[:300])
files = e.sh(f"run-as {PKG} ls cache/update 2>/dev/null").strip()
check("nothing downloaded", files == "", files)
check("still version 16", version() == 16, str(version()))
check("still filtering", filtering())
e.screenshot(os.environ.get("WORK", "/tmp") + "/prot.png")
print(f"{sum(res)}/{len(res)} passed")
sys.exit(0 if all(res) else 1)
