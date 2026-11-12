#!/usr/bin/env python3
"""Drives the live filter on an Android emulator and checks what the user would see.

No phone needed: installs an APK, puts the one-time setup in a chosen state, starts filtering through the real
screens, plays a sound file in another app, and checks the state line, the notification, the app's own speed and
dropout numbers (the "stats:" log line) and the diagnostics report.

  android/tools/emu_check.py --apk app-debug.apk --setup none          # a phone without Shizuku or a computer
  android/tools/emu_check.py --apk app-release.apk --setup done --expect-slow
  android/tools/emu_check.py --apk app-debug.apk --setup done --blur --end-capture --blur-fail   # debug hooks

--end-capture, --blur (covers and touches) and --blur-fail use debug-only broadcasts of FilterService
(ACTION_DEBUG_*): they need a debug APK.

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
            # another app (or the system UI) is slow on a loaded host: Android's "isn't responding" dialog hides
            # the screen under test; answer "Wait" and look again
            if any(re.search(r"isn't responding|لا يستجيب", t) for _, t, _ in out):
                w = next((c for _, t, c in out if re.fullmatch(r"Wait|انتظار", t)), None)
                if w:
                    self.sh(f"input tap {w[0]} {w[1]}")
                    time.sleep(1)
                    continue
            return out
        raise SystemExit("could not read the screen")

    def checked(self, rid):
        """The 'checked' state of a view by resource id, or None when it is not on screen."""
        self.sh("uiautomator dump /sdcard/emu_check.xml")
        xml = self.sh("cat /sdcard/emu_check.xml")
        m = re.search(r'resource-id="[^"]*:id/%s"[^>]*checked="(\w+)"' % rid, xml)
        return None if not m else m.group(1) == "true"

    def scroll_to(self, rid, down=True):
        for _ in range(8):
            if self.find(rid=rid):
                return True
            self.sh("input swipe 540 1500 540 900 200" if down else "input swipe 540 600 540 2000 150")
        return self.find(rid=rid) is not None

    def broadcast(self, action, extra=""):
        return self.sh(f"am broadcast -a {PKG}.{action} -p {PKG} {extra}")

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
    ap.add_argument("--blur", action="store_true", help="also turn the screen blur on (women and immodest images)")
    ap.add_argument("--stereo", action="store_true", help="choose stereo in the settings first (mono is the default)")
    ap.add_argument("--end-capture", action="store_true",
                    help="debug APK: end the capture as Android does and check the other apps stay silent")
    ap.add_argument("--blur-fail", action="store_true",
                    help="debug APK: make the blur's capture fail and check the screen says so")
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
    if a.stereo:
        e.scroll_to("switch_stereo")
        e.tap(rid="switch_stereo")
        c.check(e.checked("switch_stereo") is True, "stereo chosen")
        for _ in range(4):
            e.sh("input swipe 540 600 540 2000 150")

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
        if a.expect_slow or not a.stereo:
            c.check(mono == "true", "slow build or the default: mono" if not a.stereo else "slow build: switched to mono")
        if not a.expect_slow:
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
        c.check(detail.startswith(ok_line) or detail == slow_line, "state line: delay, or the too-slow message",
                repr(detail))
        if a.stereo and a.expect_slow and stats and stats[-1][5] == "true" and stats[-1][6] == "false":
            c.check(ar["state_mono_note"] in detail, "stereo chosen, too slow: the state line says it went mono", detail)
        if not a.stereo:
            c.check(ar["state_mono_note"] not in detail, "mono by default: no 'too slow, mono' note", detail)
    shot("4_while_playing")

    # --- screen blur: on, over a still screen, and the last frame gets its extra passes
    if a.blur:
        e.sh(f"appops set {PKG} SYSTEM_ALERT_WINDOW allow")
        for rid in ("switch_blur_women", "switch_blur_nudity"):
            for _ in range(6):
                if e.find(rid=rid):
                    break
                e.sh("input swipe 540 1500 540 900 200")
            e.tap(rid=rid)
        time.sleep(6)
        e.sh("input keyevent KEYCODE_HOME")   # the launcher: a still screen
        time.sleep(5)
        e.sh(f"am start -n {PKG}/.MainActivity")
        time.sleep(2)
        shizuku = "READY" in e.sh(f"dumpsys activity service {PKG}") and False  # no Shizuku on these emulators
        if not shizuku:
            # App-overlay host: two covers, left and right; a tap in the gap must reach the app; a tap on a cover
            # must not on Android 12+ (the cover windows take their touches so that Android keeps them opaque).
            e.scroll_to("switch_hold_silence")
            e.broadcast("DEBUG_COVERS", "--es covers '0.0,0.0,0.3,1.0,1;0.7,0.0,1.0,1.0,1'")
            e.sh("input swipe 540 1200 540 1150 300")   # a small scroll: a new frame carries the covers
            time.sleep(3)
            time.sleep(2)                               # let the scroll settle before reading positions
            hit = e.find(rid="switch_hold_silence")
            wins = e.sh("dumpsys window windows")
            blocks = [b for b in re.split(r"\n  Window #", wins) if re.match(r"\d+ Window\{[^}]*Waaiya blur\}", b)]
            # Android 15 prints "frame=[..]", Android 11 "mFrame=[..]"
            frames = [m.groups() for b in blocks
                      for m in [re.search(r"\b(?:m|)[Ff]rame=\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]", b)] if m]
            # Android 15's mAttrs prints alpha only when it is not 1 (it lowers it on a non-touchable app overlay);
            # Android 11 prints the surface's alpha
            alphas = [m.group(1) for b in blocks for m in [re.search(r"\balpha=([\d.]+)", b)] if m]
            c.check(bool(blocks) and all(float(a) == 1.0 for a in alphas), "app overlay covers are fully opaque",
                    str(alphas))
            big = [f for f in frames if int(f[2]) - int(f[0]) > 1]
            c.check(len(big) >= 2, "app overlay: one window per cover group", str(frames))
            shot("6_blur_two_covers")
            if hit:
                before = e.checked("switch_hold_silence")
                w = int(re.search(r"(\d+)x(\d+)", e.sh("wm size")).group(1))
                e.sh(f"input tap {w // 2} {hit[2][1]}")
                time.sleep(1)
                c.check(e.checked("switch_hold_silence") == (not before), "a tap between two covers reaches the app")
                e.sh(f"input tap {w // 2} {hit[2][1]}")     # back as it was
                time.sleep(1)
                # Android 12+: cover windows take their taps (that keeps them opaque); 10/11: taps go through
                api = int(e.sh("getprop ro.build.version.sdk").strip() or 0)
                e.sh(f"input tap {w // 8} {hit[2][1]}")
                time.sleep(1)
                held = e.checked("switch_hold_silence") == before
                c.check(held == (api >= 31), "Android 12+: a tap on a cover is held back" if api >= 31
                        else "Android 10/11: a tap on a cover goes through, as before")
                if not held:
                    e.sh(f"input tap {w // 8} {hit[2][1]}")
            else:
                c.check(False, "the hold-silence switch is on screen for the touch test")
            e.broadcast("DEBUG_COVERS")
            for _ in range(4):
                e.sh("input swipe 540 600 540 2000 150")

    # --- diagnostics report
    # the button must be clear of the navigation bar: a tap on its visible edge would land on the bar
    m = re.search(r"(\d+)x(\d+)", e.sh("wm size").splitlines()[-1])
    screen_h = int(m.group(2)) if m else 2280
    for _ in range(10):
        hit = e.find(rid="diagnostics")
        if hit and hit[2][1] < screen_h * 0.8:
            break
        e.sh("input swipe 540 1500 540 700 200")
    e.tap(rid="diagnostics")
    time.sleep(1)
    report = "\n".join(t for _, t, _ in e.nodes() if "Waaiya" in t and "[Setup]" in t)
    c.check("[Filter]" in report and "[Original sound]" in report, "diagnostics report opens", report[:200])
    c.check(f"Silence originals (DUMP): {'yes' if a.setup == 'done' else 'no'}" in report, "report states the setup")
    c.check("State: FILTERING" in report and "Speed since start" in report, "report has the live numbers")
    if a.setup == "done":
        c.check("Muter: OK, list from audio_policy" in report, "report: the muter reads the session list", report[-600:])
        if int(e.sh("getprop ro.build.version.sdk").strip() or 0) >= 31:
            c.check("list from audio_policy+audio" in report, "Android 12+: both session lists are read", report[-600:])
    if a.blur:
        m = re.search(r"\[Screen blur\].*?State: (\w+).*?(Frames: [^\n]*)?$", report, re.S)
        c.check(m is not None and m.group(1) in ("ON", "ON_COVERS_VISIBLE"), "blur is on", report[-400:])
        p = re.search(r"still-screen passes (\d+)", report)
        c.check(p is not None and int(p.group(1)) > 0, "the last frame of a still screen was analysed again",
                report[-300:])
    shot("5_diagnostics")
    if a.shots:
        with open(os.path.join(a.shots, "report.txt"), "w") as f:
            f.write(report)
    e.sh("input keyevent KEYCODE_BACK")

    # --- Android ends the capture (debug hook): the other apps stay silent, the service stays in the foreground
    if a.end_capture and a.setup == "done":
        e.sh("am start -n com.google.android.apps.youtube.music/.audiopreview.AudioPreviewPlayerActivity "
             "-a android.intent.action.VIEW -t audio/x-wav -d file:///sdcard/Music/emu_check.wav")
        time.sleep(5)
        e.adb("logcat", "-c")
        e.broadcast("DEBUG_END_CAPTURE")
        time.sleep(3)
        log = e.adb("logcat", "-d", "-s", "IslamicMute:V")
        c.check("other apps stay muted" in log, "capture ended: the app keeps the other apps muted", log[-300:])
        notif = e.sh("dumpsys notification --noredact")
        c.check(ar["notif_silenced_title"] in notif, "notification: filtering stopped, other apps silenced")
        e.sh(f"am start -n {PKG}/.MainActivity")
        for _ in range(4):
            e.sh("input swipe 540 600 540 2000 150")   # the top of the screen: state and buttons
        c.check(e.wait(text=re.escape(ar["state_silenced_title"]), seconds=10) is not None, "screen: filtering stopped")
        detail = (e.find(rid="state_detail") or ("", "", None))[1]
        c.check(detail == ar["state_silenced"], "screen: other apps are silenced, start again or stop", detail)
        c.check(e.find(rid="release_silence") is not None, "screen: a Stop button to hear apps unfiltered")
        shot("7_silenced")
        for wait_s in (0, 70):
            time.sleep(wait_s)
            svc = e.sh(f"dumpsys activity services {PKG}/.FilterService")
            c.check("isForeground=true" in svc, f"service still in the foreground after {wait_s + 3} s", svc[-400:])
            flinger = e.sh("dumpsys media.audio_flinger")
            sessions = re.findall(r"muter: original of session (\d+)", e.adb("logcat", "-d", "-s", "IslamicMute:V") + log)
            c.check(any(re.search(r"session %s\b" % sid, flinger, re.I) for sid in sessions) or not sessions,
                    "the other app's session still carries the silencing effect")
        # start again from the silence: back to filtering, no question (setup done)
        e.scroll_to("power", down=False)
        e.tap(rid="power")
        c.check(e.wait(text=re.escape(ar["state_on_title"]), seconds=30) is not None, "start again from the silence")
        # and the Stop button releases everything
        e.broadcast("DEBUG_END_CAPTURE")
        e.scroll_to("power", down=False)
        c.check(e.wait(rid="release_silence", seconds=10) is not None, "silenced again")
        e.tap(rid="release_silence")
        c.check(e.wait(text=re.escape(ar["state_off_title"]), seconds=10) is not None, "Stop: filtering off")
        svc = e.sh(f"dumpsys activity services {PKG}/.FilterService")
        c.check("ServiceRecord" not in svc, "Stop: the service is gone", svc[-300:])
        e.sh("am force-stop com.google.android.apps.youtube.music")
        e.scroll_to("power", down=False)
        e.tap(rid="power")   # running again for the steps below
        e.wait(text=re.escape(ar["state_on_title"]), seconds=30)

    # --- the blur's capture fails (debug hook): the blur line says so instead of "starting" for ever
    if a.blur_fail:
        e.broadcast("DEBUG_FAIL_BLUR", "--ez fail true")
        e.scroll_to("power", down=False)
        e.tap(rid="power")
        e.wait(text=re.escape(ar["state_off_title"]), seconds=10)
        e.tap(rid="power")
        e.wait(text=re.escape(ar["state_on_title"]), seconds=30)
        e.broadcast("DEBUG_FAIL_BLUR", "--ez fail false")
        e.scroll_to("blur_status")
        time.sleep(2)
        st = (e.find(rid="blur_status") or ("", "", None))[1]
        c.check(st == ar["blur_status_no_capture"], "blur capture failed: the screen says so", st)
        shot("8_blur_no_capture")
        for _ in range(4):
            e.sh("input swipe 540 600 540 2000 150")

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
