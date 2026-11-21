#!/usr/bin/env python3
"""End-to-end check of the in-app update on an emulator (AppUpdate.kt): the daily check's notification, the Updates
card, the install permission, the patch (or, with --bad-patch, the fallback to the full APK), Android's installer,
and the new version installed.   e2e.py [--bad-patch]"""
import argparse
import os
import re
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from emu_check import Emu, PKG  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--bad-patch", action="store_true")
a = ap.parse_args()
import os
e = Emu(os.environ.get("SERIAL", "emulator-5580"))
url = "https://waaiya.mssid.org/preview/updtest/" + ("update-badpatch.json" if a.bad_patch else "update.json")
results = []


def check(name, ok, detail=""):
    results.append(ok)
    print(("PASS " if ok else "FAIL ") + name + (f": {detail}" if detail else ""))


def version():
    m = re.search(r"versionCode=(\d+)", e.sh(f"dumpsys package {PKG}"))
    return int(m.group(1)) if m else None


check("starts on version 16", version() == 16, str(version()))
e.sh(f"run-as {PKG} sh -c 'mkdir -p files && echo {url} > files/update-url.txt'")
e.sh(f"pm grant {PKG} android.permission.POST_NOTIFICATIONS")
e.sh(f"appops set {PKG} REQUEST_INSTALL_PACKAGES default")
e.adb("logcat", "-c")

# the app starts once (schedules the daily check), then the daily check runs now
e.sh(f"monkey -p {PKG} -c android.intent.category.LAUNCHER 1")
if e.wait(rid="choose_man", seconds=45):  # first launch: the man/woman question
    e.tap(rid="choose_man")
    if not e.wait(rid="power", seconds=5) and e.find(rid="choose_man"):
        e.tap(rid="choose_man")
time.sleep(3)
jobs = e.sh(f"dumpsys jobscheduler | grep -A3 'u0a.*{PKG}/.AppUpdateJob' | head -5")
check("daily check is scheduled", "AppUpdateJob" in jobs)
e.sh("input keyevent KEYCODE_HOME")
time.sleep(1)
e.sh(f"cmd jobscheduler run -f {PKG} 4711")
note = ""
for _ in range(30):
    note = e.sh("dumpsys notification --noredact")
    if "0.2.13-t17 is available" in note:
        break
    time.sleep(1)
check("notification: new version", "0.2.13-t17 is available" in note)
m = re.search(r"Tap to update \(([^)]*)\)", note)
check("notification names the small download", bool(m) and "MB" in m.group(1), m.group(1) if m else "")

# the Updates card on the Settings page
e.sh(f"monkey -p {PKG} -c android.intent.category.LAUNCHER 1")
time.sleep(3)
e.page("settings")
for _ in range(25):
    h = e.find(text=r"^Update now$")
    if h and h[2][1] < 1700:
        break
    e.sh("input swipe 540 1600 540 900 400")
    time.sleep(1.5)
size_line = e.find(text=r"Download: .*")
check("card offers the update", e.find(text=r"^Update now$") is not None)
check("card says only the changes are downloaded" if not a.bad_patch else "card shows the download size",
      size_line is not None and ("only what changed" in size_line[1]) != a.bad_patch, size_line[1] if size_line else "")
e.screenshot(os.environ.get("WORK", "/tmp") + "/card%s.png" % ("-bad" if a.bad_patch else ""))

# first tap: Android's "install unknown apps" switch is off -> its settings screen opens
e.tap(text=r"^Update now$")
time.sleep(3)
if e.find(text=r"^Update now$") and not re.search(r"Downloading|Preparing", " ".join(t for _, t, _ in e.nodes())):
    if "ManageAppExternalSources" not in e.sh("dumpsys activity activities | grep -m1 -E 'topResumedActivity|mResumedActivity'"):
        print("note: the first tap did not take, tapping again")
        e.tap(text=r"^Update now$")
t0 = time.time()
opened = None
for _ in range(240 if a.bad_patch else 60):
    top = e.sh("dumpsys activity activities | grep -m1 -E 'topResumedActivity|mResumedActivity'")
    if "Settings" in top or "settings" in top:
        opened = top.strip()
        break
    time.sleep(1)
check("asks for the install permission", opened is not None, opened or "")
e.sh(f"appops set {PKG} REQUEST_INSTALL_PACKAGES allow")
e.sh("input keyevent KEYCODE_BACK")
time.sleep(3)
# Android 11 and older kill the app here; when Waaiya is back, the update goes on by itself (installer).
# Android 12+: the app keeps running, and the user taps Update now again.
if PKG not in e.sh("dumpsys activity activities | grep -m1 -E 'topResumedActivity|mResumedActivity'"):
    e.sh(f"monkey -p {PKG} -c android.intent.category.LAUNCHER 1")
first = e.wait(text=r"^(Update|Install|Update now)$", seconds=90)
if first and first[1] != "Update now":
    print("note: the update went on by itself after Android restarted the app")
else:
    for _ in range(25):
        h = e.find(text=r"^Update now$")
        if h and h[2][1] < 1700:
            break
        e.sh("input swipe 540 1600 540 900 400")
        time.sleep(1.5)
    e.tap(text=r"^Update now$")

# Android's installer asks; the user confirms
hit = e.wait(text=r"^(Update|Install)$", seconds=120)
check("Android's installer asks to confirm", hit is not None)
if hit:
    e.sh(f"input tap {hit[2][0]} {hit[2][1]}")
for _ in range(90):
    if version() == 17:
        break
    time.sleep(1)
check("version 17 installed", version() == 17, str(version()))
log = e.adb("logcat", "-d", "-s", "WaaiyaUpdate")
fell_back = "downloading the full APK" in log
check("used the patch" if not a.bad_patch else "fell back to the full APK", fell_back == a.bad_patch)
print(log[-1500:])
print(f"{sum(results)}/{len(results)} passed")
sys.exit(0 if all(results) else 1)
