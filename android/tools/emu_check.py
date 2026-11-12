#!/usr/bin/env python3
"""Drives the live filter on an Android emulator and checks what the user would see.

No phone needed: installs an APK, puts the one-time setup in a chosen state, starts filtering through the real
screens, plays a sound file in another app, and checks the state line, the notification, the app's own speed and
dropout numbers (the "stats:" log line) and the diagnostics report.

  android/tools/emu_check.py --apk app-debug.apk --setup none          # a phone without Shizuku or a computer
  android/tools/emu_check.py --apk app-release.apk --setup done --expect-slow

A release APK has no x86 code, so the emulator translates it: that is this script's "slow phone". A debug APK
built with -PimX86 runs natively: the "fast phone".

Needs: adb on PATH or in ~/Android/Sdk/platform-tools, a running emulator, ffmpeg (to make the test sound),
and an app on the emulator that plays an audio file (YouTube Music's preview player on Google images).
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET

PKG = "org.islamicmute.app"
HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(HERE, "..", "app", "src", "main", "res")
REPO = os.path.join(HERE, "..", "..")


def find_adb():
    for p in os.environ.get("PATH", "").split(os.pathsep):
        if os.path.isfile(os.path.join(p, "adb")):
            return os.path.join(p, "adb")
    return os.path.expanduser("~/Android/Sdk/platform-tools/adb")


class Emu:
    def __init__(self, serial):
        self.base = [find_adb(), "-s", serial]

    def adb(self, *args, check=False, timeout=120):
        r = subprocess.run(self.base + list(args), capture_output=True, text=True, timeout=timeout)
        if check and r.returncode != 0:
            raise SystemExit(f"adb {' '.join(args)} failed: {r.stdout}{r.stderr}")
        return r.stdout + r.stderr

    def sh(self, cmd, **kw):
        return self.adb("shell", cmd, **kw)

    def nodes(self):
        """The visible screen as a list of (resource-id, text, bounds centre)."""
        for _ in range(4):
            self.sh("uiautomator dump /sdcard/emu_check.xml")
            xml = self.sh("cat /sdcard/emu_check.xml")
            try:
                root = ET.fromstring(xml[xml.index("<?xml"):])
            except (ValueError, ET.ParseError):
                time.sleep(1)
                continue
            out = []
            for n in root.iter("node"):
                m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", n.get("bounds", ""))
                if m:
                    x1, y1, x2, y2 = map(int, m.groups())
                    out.append((n.get("resource-id", ""), n.get("text", ""), ((x1 + x2) // 2, (y1 + y2) // 2)))
            return out
        raise SystemExit("could not read the screen")

    def find(self, rid=None, text=None):
        for r, t, c in self.nodes():
            if rid and r.endswith(":id/" + rid):
                return r, t, c
            if text and re.search(text, t):
                return r, t, c
        return None

    def wait(self, rid=None, text=None, seconds=20):
        end = time.time() + seconds
        while time.time() < end:
            hit = self.find(rid, text)
            if hit:
                return hit
            time.sleep(1)
        return None

    def tap(self, rid=None, text=None, seconds=20):
        hit = self.wait(rid, text, seconds)
        if not hit:
            raise SystemExit(f"not on screen: {rid or text}\n" + "\n".join(t for _, t, _ in self.nodes() if t))
        self.sh(f"input tap {hit[2][0]} {hit[2][1]}")
        time.sleep(1)

    def screenshot(self, path):
        with open(path, "wb") as f:
            f.write(subprocess.run(self.base + ["exec-out", "screencap", "-p"], capture_output=True).stdout)


def strings(lang):
    """name -> text of the app's strings in one language."""
    path = os.path.join(RES, "values-ar" if lang == "ar" else "values", "strings.xml")
    out = {}
    for s in ET.parse(path).getroot().iter("string"):
        out[s.get("name")] = (s.text or "").replace("\\n", "\n").replace("\\'", "'").replace('\\"', '"')
    return out


class Checks:
    def __init__(self):
        self.failed = 0

    def check(self, ok, what, detail=""):
        print(("ok:   " if ok else "FAIL: ") + what + (f"  [{detail}]" if detail and not ok else ""))
        if not ok:
            self.failed += 1


def make_sound(path):
    """90 s of speech with music under it, from the project's test set."""
    mix = os.path.join(REPO, "testset", "data", "mixtures")
    voice = os.path.join(mix, "speech_ar_0_mvr+3_voice.flac")
    music = os.path.join(mix, "speech_ar_0_mvr+3_music.flac")
    if os.path.isfile(voice) and os.path.isfile(music):
        cmd = ["ffmpeg", "-v", "error", "-y", "-stream_loop", "8", "-i", voice, "-stream_loop", "8", "-i", music,
               "-filter_complex", "amix=inputs=2:normalize=0", "-t", "90", "-ar", "44100", "-ac", "2", path]
    else:  # no test set here: a voice-like buzz plus a tone
        cmd = ["ffmpeg", "-v", "error", "-y", "-f", "lavfi", "-i", "sine=frequency=140:duration=90", "-f", "lavfi",
               "-i", "sine=frequency=880:duration=90", "-filter_complex", "amix=inputs=2", "-ar", "44100", "-ac", "2", path]
    subprocess.run(cmd, check=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--serial", default="emulator-5580")
    ap.add_argument("--apk", required=True)
    ap.add_argument("--setup", choices=["none", "done"], default="none",
                    help="none: no DUMP permission (a phone without Shizuku); done: the one-time setup is finished")
    ap.add_argument("--expect-slow", action="store_true", help="the build is expected to be too slow for stereo here")
    ap.add_argument("--seconds", type=int, default=45, help="how long to play before reading the numbers")
    ap.add_argument("--shots", help="folder for screenshots")
    ap.add_argument("--keep", action="store_true", help="keep the app data (default: start from a fresh install)")
    a = ap.parse_args()
    e, c, ar = Emu(a.serial), Checks(), strings("ar")
    shot = (lambda name: e.screenshot(os.path.join(a.shots, name + ".png"))) if a.shots else (lambda name: None)
    if a.shots:
        os.makedirs(a.shots, exist_ok=True)

    # --- install and put the setup in the wanted state
    e.sh(f"am force-stop {PKG}")
    out = e.adb("install", "-r", a.apk, timeout=300)
    if "Success" not in out:  # another signing key (debug over release): start over
        e.adb("uninstall", PKG)
        e.adb("install", a.apk, check=True, timeout=300)
    if not a.keep:
        e.sh(f"pm clear {PKG}")
    e.sh(f"pm grant {PKG} android.permission.RECORD_AUDIO")
    e.sh(f"pm grant {PKG} android.permission.POST_NOTIFICATIONS")
    if a.setup == "done":
        e.sh(f"pm grant {PKG} android.permission.DUMP")
        e.sh(f"appops set {PKG} PROJECT_MEDIA allow")
    else:
        e.sh(f"pm revoke {PKG} android.permission.DUMP")
        e.sh(f"appops set {PKG} PROJECT_MEDIA default")
    e.adb("logcat", "-c")
    e.sh("input keyevent KEYCODE_WAKEUP")
    e.sh(f"am start -n {PKG}/.MainActivity")

    # --- first launch: Arabic, the man/woman question
    if e.wait(rid="choose_man", seconds=15):
        c.check(e.find(text=re.escape(ar["onboard_title"])) is not None, "first launch is in Arabic")
        e.tap(rid="choose_man")
    c.check(e.wait(rid="power", seconds=10) is not None, "main screen shows the power button")
    banner = e.find(text=re.escape(ar["setup_banner_title"]))
    c.check((banner is not None) == (a.setup == "none"), "setup banner shown only when the setup is missing")
    shot("1_idle")

    # --- start
    e.tap(rid="power")
    if a.setup == "none":
        c.check(e.wait(text=re.escape(ar["start_no_setup_title"]), seconds=5) is not None,
                "start without setup: a dialog says the music will still be heard")
        shot("2_start_dialog")
        e.tap(text=re.escape(ar["start_no_setup_anyway"]))
        # Android's own question (in the phone's language)
        e.tap(text=r"^(Start|Start now|ابدأ|بدء|البدء الآن)$", seconds=15)
    else:
        c.check(e.wait(text=re.escape(ar["start_no_setup_title"]), seconds=3) is None, "setup done: no warning dialog")
        if e.find(text=r"^(Start|Start now)$"):
            c.check(False, "setup done: Android should not ask to share the screen")
            e.tap(text=r"^(Start|Start now)$")
    on = e.wait(text=re.escape(ar["state_on_title"]), seconds=60)
    c.check(on is not None, "the screen says filtering is on")
    time.sleep(2)
    detail = (e.find(rid="state_detail") or ("", "", None))[1]
    if a.setup == "none":
        c.check(detail == ar["state_on_not_muted"], "state line warns the original sound is not silenced", detail)
        c.check(ar["notif_not_muted"] in e.sh("dumpsys notification --noredact"), "notification warns too")
    shot("3_filtering")

    # --- play something in another app
    with tempfile.TemporaryDirectory() as d:
        wav = os.path.join(d, "mix.wav")
        make_sound(wav)
        e.adb("push", wav, "/sdcard/Music/emu_check.wav", check=True)
    e.sh("am start -n com.google.android.apps.youtube.music/.audiopreview.AudioPreviewPlayerActivity "
         "-a android.intent.action.VIEW -t audio/x-wav -d file:///sdcard/Music/emu_check.wav")
    time.sleep(a.seconds)
    log = e.adb("logcat", "-d", "-s", "IslamicMute:V")
    if a.setup == "done":
        # the other app's player must carry the silencing effect while it plays
        m = re.search(r"muter: original of session (\d+) \(uid (\d+), USAGE_MEDIA\) silenced", log)
        c.check(m is not None, "the muter silenced the other app's player", log[-300:])
        flinger = e.sh("dumpsys media.audio_flinger")
        if a.shots:
            with open(os.path.join(a.shots, "audio_flinger.txt"), "w") as f:
                f.write(flinger)
        if m:
            c.check(re.search(r"effects? for session %s\b" % m.group(1), flinger, re.I) is not None or
                    re.search(r"Effect Chain.*session.*\b%s\b" % m.group(1), flinger, re.I) is not None,
                    "Android's mixer shows an effect on that session")
    stats = re.findall(r"stats: hop avg ([\d.]+) max ([\d.]+) ms, late (\d+)%, underruns (\d+), buffered (\d+) ms, "
                       r"mono (\w+), slow (\w+), capture (-?\d+) dB, muter (\w+)", log)
    c.check(bool(stats), "the filter logs its numbers every 10 s", log[-400:])
    if stats:
        avg, mx, late, under, buffered, mono, slow, cap, muter = stats[-1]
        print(f"      numbers: hop avg {avg} ms, max {mx} ms, late {late}%, dropouts {under}, waiting {buffered} ms, "
              f"mono {mono}, too slow {slow}, capture {cap} dB, muter {muter}")
        c.check(int(cap) > -60, "the other app's sound reaches the filter", f"capture {cap} dB")
        c.check(muter == ("OK" if a.setup == "done" else "NO_PERMISSION"), "muter state matches the setup", muter)
        if a.expect_slow:
            c.check(mono == "true", "slow build: switched to mono")
        else:
            # stereo or mono depends on the host's speed; either way the hops must finish in time
            c.check(slow == "false", "fast build: not flagged too slow")
            c.check(float(avg) < 7.5, "fast build: hops finish in time", f"avg {avg} ms")

    # --- the app's own screen while playing
    e.sh(f"am start -n {PKG}/.MainActivity")
    time.sleep(2)
    detail = (e.find(rid="state_detail") or ("", "", None))[1]
    if a.setup == "done":
        ok_line = ar["state_on_detail"].split("%1$d")[0]
        slow_line = ar["state_too_slow"]
        c.check(detail.startswith(ok_line) or detail == slow_line, "state line: delay, or the too-slow message", detail)
        if a.expect_slow and stats and stats[-1][5] == "true" and stats[-1][6] == "false":
            c.check(ar["state_mono_note"] in detail, "state line says the sound is in mono", detail)
    shot("4_while_playing")

    # --- diagnostics report
    for _ in range(6):
        if e.find(rid="diagnostics"):
            break
        e.sh("input swipe 540 1800 540 500 200")
    e.tap(rid="diagnostics")
    time.sleep(1)
    report = "\n".join(t for _, t, _ in e.nodes() if "Waaiya" in t and "[Setup]" in t)
    c.check("[Filter]" in report and "[Original sound]" in report, "diagnostics report opens", report[:200])
    c.check(f"Silence originals (DUMP): {'yes' if a.setup == 'done' else 'no'}" in report, "report states the setup")
    c.check("State: FILTERING" in report and "Speed since start" in report, "report has the live numbers")
    if a.setup == "done":
        c.check("Muter: OK, list from audio_policy" in report, "report: the muter reads the session list", report[-600:])
    shot("5_diagnostics")
    if a.shots:
        with open(os.path.join(a.shots, "report.txt"), "w") as f:
            f.write(report)
    e.sh("input keyevent KEYCODE_BACK")

    # --- stop
    for _ in range(4):
        e.sh("input swipe 540 600 540 2000 150")
    e.tap(rid="power")
    c.check(e.wait(text=re.escape(ar["state_off_title"]), seconds=10) is not None, "the button stops filtering")
    e.sh("am force-stop com.google.android.apps.youtube.music")
    c.check("FATAL EXCEPTION" not in e.adb("logcat", "-d", "-s", "AndroidRuntime:E"), "no crash")
    print(f"\n{'ALL PASSED' if not c.failed else str(c.failed) + ' FAILED'}  (setup {a.setup}, {os.path.basename(a.apk)})")
    sys.exit(1 if c.failed else 0)


if __name__ == "__main__":
    main()
