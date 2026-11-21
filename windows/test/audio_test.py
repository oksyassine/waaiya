"""Windows sound filter, end to end on a real Windows audio stack (CI: a GitHub Windows runner with the Scream
virtual output, windows/test/audio_device.ps1).

    python windows/test/audio_test.py <dir with waaiya-filter.exe, waaiya-wtest.exe, onnxruntime.dll, models/>

What it checks, in order (each step prints its numbers; a failed check exits 1 at the end):
  1. route C2 itself (reports/desktop_windows_macos_scope.md 2.4): a session at 1e-4 is still captured by process
     loopback in float, so x 1e4 gives back the same level and a clean signal (not 16-bit noise)
  2. bypass (engine passes the sound through): what the output plays matches the tone alone, the tone's own
     session is at 1e-4, no leak
  3. stop gives the level back (exactly)
  4. filtering: the instrument-like tone is suppressed at the output
  5. an app that starts while filtering is lowered at once; nothing loud reaches the output
  6. the filter killed: apps stay silent (fail-closed); stop without a filter gives the levels back
  7. an app that ended while lowered gets its level back when it plays again after the stop
"""
import ctypes
import json
import math
import os
import shutil
import subprocess
import sys
import tempfile
import time

import numpy as np

BIN = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "build-win")
FILTER = os.path.join(BIN, "waaiya-filter.exe")
WTEST = os.path.join(BIN, "waaiya-wtest.exe")
TMP = tempfile.mkdtemp(prefix="waaiya-audio-")
STATE_DIR = os.path.join(TMP, "filter")
SETTINGS = os.path.join(TMP, "settings.json")
RATE = 48000
failures = []


def check(ok, what):
    print(("PASS " if ok else "FAIL ") + what, flush=True)
    if not ok:
        failures.append(what)


def read_f32(path):
    return np.fromfile(path, dtype="<f4").astype(np.float64)


def db(x):
    x = np.asarray(x, dtype=np.float64)
    rms = math.sqrt(float(np.mean(x * x))) if x.size else 0.0
    return 20 * math.log10(rms) if rms > 0 else -math.inf


def hnr(x, freq=220.0):
    """Harmonic-to-noise ratio (dB) of the left channel over its last second: energy within 6 Hz of the tone's 8
    harmonics (the 3 Hz tremolo puts sidebands there) against everything else."""
    left = np.asarray(x, dtype=np.float64)[0::2][-RATE:]
    spec = np.abs(np.fft.rfft(left * np.hanning(left.size))) ** 2
    hz = np.fft.rfftfreq(left.size, 1 / RATE)
    near = np.zeros(spec.size, dtype=bool)
    for h in range(1, 9):
        near |= np.abs(hz - freq * h) <= 6
    harm, noise = spec[near].sum(), spec[~near].sum()
    return 10 * math.log10(max(harm, 1e-30) / max(noise, 1e-30))


def wtest(*args, timeout=60):
    r = subprocess.run([WTEST, *map(str, args)], capture_output=True, text=True, timeout=timeout)
    if r.returncode != 0:
        print(f"waaiya-wtest {' '.join(map(str, args))}: exit {r.returncode}\n{r.stdout}{r.stderr}", flush=True)
    return r


def app(name):
    """A copy of the test tool under its own name: Windows keeps one volume per program, so each test "app" is a
    program of its own."""
    path = os.path.join(TMP, name + ".exe")
    if not os.path.exists(path):
        shutil.copy(WTEST, path)
    return path


def tone(name, seconds=600, freq=220, level=0.3):
    p = subprocess.Popen([app(name), "tone", "--seconds", str(seconds), "--freq", str(freq), "--level", str(level)],
                         stdout=subprocess.PIPE, text=True, cwd=BIN)
    pid = int(p.stdout.readline().split()[1])
    assert p.stdout.readline().strip() == "playing"
    time.sleep(1.0)  # Windows takes a moment to start the stream
    return p, pid


def capture(name, seconds=3, pid=None):
    path = os.path.join(TMP, name + ".f32")
    args = ["capture", "--out", path, "--seconds", seconds]
    if pid:
        args += ["--pid", pid, "--include"]
    r = wtest(*args)
    x = read_f32(path) if r.returncode == 0 else []
    print(f"  {name}: {db(x):.2f} dBFS", flush=True)
    return x


def suspend(pid):
    """Freezes a process (every thread), as a hung one."""
    k = ctypes.windll.kernel32
    h = k.OpenProcess(0x0800, False, pid)  # PROCESS_SUSPEND_RESUME
    ctypes.windll.ntdll.NtSuspendProcess(ctypes.c_void_p(h))
    k.CloseHandle(h)


def filter_window(pid, timeout=5):
    """The filter's hidden top-level window (class WaaiyaFilter), or None."""
    u = ctypes.windll.user32
    found = []
    proto = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)

    def each(h, _):
        p = ctypes.c_ulong()
        u.GetWindowThreadProcessId(ctypes.c_void_p(h), ctypes.byref(p))
        name = ctypes.create_unicode_buffer(64)
        u.GetClassNameW(ctypes.c_void_p(h), name, 64)
        if p.value == pid and name.value == "WaaiyaFilter":
            found.append(h)
        return True

    cb = proto(each)
    end = time.time() + timeout
    while time.time() < end:
        u.EnumWindows(cb, 0)
        if found:
            return ctypes.c_void_p(found[0])
        time.sleep(0.2)
    return None


def volume(pid, wait=5):
    r = wtest("volume", "--pid", pid, "--wait", wait)
    return float(r.stdout.strip()) if r.returncode == 0 else None


def state():
    try:
        with open(os.path.join(STATE_DIR, "state.json"), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def flowing(seconds=2.0):
    """The audio runs: frames keep coming in and the state stays fresh."""
    a = state().get("cap_frames", 0)
    time.sleep(seconds)
    s = state()
    return s.get("cap_frames", 0) > a + RATE * seconds / 2 and time.time() * 1000 - s.get("t", 0) < 2000


def start_filter(*extra):
    log = open(os.path.join(TMP, "filter-%d.log" % int(time.time() * 1000)), "w")
    # the test's own recorder (endpoint loopback) is left alone: lowered, it would record at -80 dB
    p = subprocess.Popen([FILTER, "run", "--dir", STATE_DIR, "--settings", SETTINGS, "--log-stderr",
                          "--leave-alone", "waaiya-wtest.exe", *extra],
                         stdout=log, stderr=subprocess.STDOUT)
    for _ in range(100):
        s = state()
        if s.get("pid") == p.pid and s.get("state") == "filtering" and s.get("lowered", 0) >= 1:
            break
        time.sleep(0.1)
    time.sleep(1.0)
    print(f"  filter state: {state()}", flush=True)
    return p, log


def stop_filter(p, log):
    subprocess.run([FILTER, "stop", "--dir", STATE_DIR], timeout=30)
    time.sleep(0.5)
    log.flush()
    with open(log.name, encoding="utf-8", errors="replace") as f:
        print("  --- filter log\n" + "".join("  " + l for l in f.readlines()[-80:]), flush=True)


def tone_db(x, freq):
    """Level of one frequency in a recording (dB of the amplitude of a sine at that frequency, both channels)."""
    x = np.asarray(x, dtype=np.float64)
    if x.size < RATE:
        return -200.0
    m = x[: (x.size // 2) * 2].reshape(-1, 2).mean(axis=1)
    m = m[-RATE * 2:] if m.size > RATE * 2 else m
    w = np.hanning(m.size)
    spec = np.abs(np.fft.rfft(m * w)) * 2 / w.sum()
    k = int(round(freq * m.size / RATE))
    return 20 * math.log10(max(spec[max(k - 2, 0):k + 3].max(), 1e-12))


def write_settings(**over):
    s = {"audio_stereo": True, "hold_silence": True, "mute_women_singing": False}
    s.update(over)
    with open(SETTINGS, "w") as f:
        json.dump(s, f)


def test_off_apps():
    print("=== 13. apps left unfiltered (filter_off_apps): not lowered, not captured, heard as they are; the others "
          "filtered; the list changes live", flush=True)
    a, apid = tone("tone-a", freq=220, level=0.1)
    b, bpid = tone("tone-b", freq=1010, level=0.1)  # not an overtone of 220 Hz
    ref = capture("both, no filter")
    ref_a, ref_b = tone_db(ref, 220), tone_db(ref, 1010)
    print(f"  reference: 220 Hz {ref_a:.1f} dB, 1010 Hz {ref_b:.1f} dB", flush=True)
    write_settings(filter_off_apps="tone-b.exe, Some-Other.exe")
    f, flog = start_filter()
    va, vb = volume(apid), volume(bpid)
    check(va is not None and abs(va - 1e-4) < 1e-6, f"the filtered app is lowered ({va})")
    check(vb is not None and abs(vb - 1) < 1e-4, f"the app left unfiltered keeps its level ({vb})")
    s = state()
    check(s.get("captures", -1) >= 1, f"one capture per app ({s.get('captures')})")
    check(any(x.get("exe") == "tone-b.exe" for x in s.get("apps", [])), f"the app list names it ({s.get('apps')})")
    x = capture("filtering, tone-b left unfiltered", seconds=4)
    fa, fb = tone_db(x, 220), tone_db(x, 1010)
    print(f"  filtering: 220 Hz {fa:.1f} dB, 1010 Hz {fb:.1f} dB", flush=True)
    check(abs(fb - ref_b) < 2.0, f"the app left unfiltered is heard once, at its level ({fb - ref_b:+.1f} dB)")
    check(fa < ref_a - 10, f"the other app is still filtered ({fa - ref_a:+.1f} dB)")
    check(state().get("leaks", 1) == 0, f"no leak ({state().get('leaks')})")
    write_settings()  # taken off the list while filtering: lowered and filtered again
    ok = False
    for _ in range(20):
        vb = volume(bpid, wait=1)
        if vb is not None and abs(vb - 1e-4) < 1e-6:
            ok = True
            break
        time.sleep(0.25)
    check(ok, f"taken off the list: lowered again at once ({vb})")
    time.sleep(1.5)
    x = capture("filtering, both", seconds=3)
    check(tone_db(x, 1010) < ref_b - 10, f"and filtered ({tone_db(x, 1010) - ref_b:+.1f} dB)")
    write_settings(filter_off_apps="tone-b.exe")  # back on the list: its level back
    ok = False
    for _ in range(20):
        vb = volume(bpid, wait=1)
        if vb is not None and abs(vb - 1) < 1e-4:
            ok = True
            break
        time.sleep(0.25)
    check(ok, f"put on the list while filtering: its level back ({vb})")
    stop_filter(f, flog)
    va = volume(apid)
    check(va is not None and abs(va - 1) < 1e-4, f"stop gives the filtered app its level back ({va})")
    write_settings()
    a.kill()
    b.kill()


def test_keep_singing():
    print("=== 14. keep singing (voice_v1) switched while filtering: the other model loads beside the running one, "
          "the sound never stops, nothing unfiltered", flush=True)
    if not os.path.exists(os.path.join(BIN, "models", "voice", "v3", "voice_v1_fp16.onnx")):
        check(False, "the keep-singing model is next to the filter (models/voice/v3)")
        return
    a, apid = tone("tone-k", freq=220, level=0.1)
    ref = tone_db(capture("tone alone"), 220)
    write_settings()
    f, flog = start_filter()
    check(state().get("keep_singing") is False, f"default model at the start ({state().get('keep_singing')})")
    for on in (True, False, True):
        write_settings(keep_singing=on)
        frames = state().get("cap_frames", 0)
        ok = False
        for _ in range(60):
            s = state()
            if s.get("keep_singing") is on:
                ok = True
                break
            time.sleep(0.25)
        check(ok and s.get("engine") == "ok", f"keep singing {'on' if on else 'off'}: that model runs ({s.get('keep_singing')}, "
              f"engine {s.get('engine')})")
        check(s.get("state") == "filtering" and s.get("cap_frames", 0) > frames, "the sound kept flowing during the switch")
        check(flowing(), "and flows after it")
        x = capture(f"keep singing {on}", seconds=3)
        check(tone_db(x, 220) < ref - 10, f"the instrument tone stays removed ({tone_db(x, 220) - ref:+.1f} dB)")
    check(state().get("leaks", 1) == 0, f"no leak ({state().get('leaks')})")
    stop_filter(f, flog)
    write_settings()
    a.kill()


def main():
    only = os.environ.get("AUDIO_TEST_ONLY")  # one test on a PC: AUDIO_TEST_ONLY=13 or 14
    if only in ("13", "14"):
        os.makedirs(STATE_DIR, exist_ok=True)
        write_settings()
        test_off_apps() if only == "13" else test_keep_singing()
        print("\n" + ("all checks passed" if not failures else f"{len(failures)} check(s) failed:\n  " + "\n  ".join(failures)))
        sys.exit(1 if failures else 0)
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(SETTINGS, "w") as f:
        json.dump({"audio_stereo": True, "hold_silence": True, "mute_women_singing": False}, f)

    print("=== 1. route C2: a session at 1e-4, captured by process loopback, x 1e4", flush=True)
    a, apid = tone("waaiya-test-a")
    ref = capture("c2-ref", pid=apid)
    wtest("volume", "--pid", apid, "--set", "0.0001")
    time.sleep(0.5)
    low = capture("c2-low", pid=apid)
    back = low * 1e4
    lvl_ref, lvl_back = db(ref), db(back)
    h_ref, h_back = hnr(ref), hnr(back)
    print(f"  level {lvl_ref:.2f} -> {db(low):.2f} -> x1e4 {lvl_back:.2f} dBFS; HNR {h_ref:.1f} -> {h_back:.1f} dB", flush=True)
    check(abs(lvl_back - lvl_ref) < 0.5, f"C2: the gain gives the level back ({lvl_back - lvl_ref:+.2f} dB)")
    check(h_back > 40 and h_back > h_ref - 6, f"C2: the signal stays clean at -80 dB (HNR {h_back:.1f} dB)")
    wtest("volume", "--pid", apid, "--set", "1")
    time.sleep(0.5)
    end_ref = capture("output-ref")
    end_ref_db = db(end_ref)
    check(end_ref_db > -40, f"the tone reaches the output ({end_ref_db:.1f} dBFS)")

    print("=== 2. bypass: the filter passes the sound through", flush=True)
    f, flog = start_filter("--bypass")
    v = volume(apid)
    check(v is not None and abs(v - 1e-4) < 1e-6, f"the tone's session is lowered to 1e-4 ({v})")
    print(f"  volumes: tone {volume(apid)}, the filter's own output {volume(f.pid, wait=1)}")
    byp = db(capture("output-bypass", seconds=4))
    check(abs(byp - end_ref_db) < 1.5, f"bypass: the output matches the tone alone ({byp - end_ref_db:+.2f} dB)")
    s = state()
    print(f"  state: {s}")
    check(s.get("leaks") == 0, f"no leak ({s.get('leaks')})")
    print(f"  delay {s.get('delay_ms')} ms, cpu {s.get('cpu')} %, underruns {s.get('underruns')}, dropped {s.get('dropped')}")
    check(s.get("underruns", 99) <= 3, f"the output does not run dry ({s.get('underruns')} underruns in 5 s)")

    print("=== 3. stop gives the level back", flush=True)
    stop_filter(f, flog)
    v = volume(apid)
    check(v is not None and abs(v - 1.0) < 1e-4, f"the tone's level is back ({v})")
    after = db(capture("output-after-stop"))
    check(abs(after - end_ref_db) < 1.0, f"the output is the tone again ({after - end_ref_db:+.2f} dB)")

    print("=== 4. filtering: the instrument-like tone is suppressed", flush=True)
    f, flog = start_filter()
    print(f"  volumes: tone {volume(apid)}, the filter's own output {volume(f.pid, wait=1)}")
    filt = db(capture("output-filtered", seconds=5))
    check(filt < end_ref_db - 10, f"the tone is suppressed by {end_ref_db - filt:.1f} dB (>= 10)")
    s = state()
    print(f"  state: {s}")
    check(s.get("engine") == "ok", f"engine ok ({s.get('engine')})")
    check(s.get("leaks") == 0, f"no leak ({s.get('leaks')})")

    print("=== 5. an app that starts while filtering", flush=True)
    b, bpid = tone("waaiya-test-b", freq=330)
    vb = volume(bpid)
    check(vb is not None and abs(vb - 1e-4) < 1e-6, f"the new app is lowered at once ({vb})")
    both = db(capture("output-filtered-two", seconds=4))
    check(both < end_ref_db - 6, f"nothing loud reaches the output ({both:.1f} dBFS, tone alone {end_ref_db:.1f})")
    print(f"  leaks while it started: {state().get('leaks')}")

    print("=== 6. the filter killed: apps stay silent until stop", flush=True)
    f.kill()
    f.wait()
    time.sleep(0.5)
    dead = db(capture("output-killed"))
    check(dead < end_ref_db - 60, f"apps silent after a crash ({dead:.1f} dBFS)")
    subprocess.run([FILTER, "stop", "--dir", STATE_DIR], timeout=30)  # no filter: a restorer starts
    time.sleep(1.5)
    va, vb = volume(apid), volume(bpid)
    check(va is not None and abs(va - 1) < 1e-4 and vb is not None and abs(vb - 1) < 1e-4,
          f"stop without a filter gives the levels back ({va}, {vb})")
    b.kill()

    print("=== 7. an app that ended while lowered gets its level back when it plays again", flush=True)
    f, flog = start_filter()
    c, cpid = tone("waaiya-test-c", freq=440)
    vc = volume(cpid)
    check(vc is not None and abs(vc - 1e-4) < 1e-6, f"lowered ({vc})")
    c.kill()
    c.wait()
    time.sleep(1.0)
    stop_filter(f, flog)
    s = state()
    print(f"  after stop: {s}")
    check(s.get("pending", 0) >= 1 and s.get("state") == "restoring", "its level waits in the store")
    c2, c2pid = tone("waaiya-test-c", freq=440)
    time.sleep(1.0)
    v2 = volume(c2pid)
    check(v2 is not None and abs(v2 - 1) < 1e-4, f"its next run gets the level back ({v2})")
    c2.kill()
    a.kill()
    time.sleep(1.0)
    s = state()
    check(s.get("state") == "stopped", f"the restorer ends when nothing is left ({s.get('state')})")

    print("=== 8. stop and start again while apps open and close sessions", flush=True)
    import threading
    churning = [True]
    churn_apps = []

    def churn():
        k = 0
        while churning[0]:
            p, _ = tone(f"waaiya-test-churn{k % 3}", seconds=2, freq=500 + 50 * (k % 3))
            churn_apps.append(p)
            time.sleep(0.3)
            k += 1

    a, apid = tone("waaiya-test-a")
    th = threading.Thread(target=churn, daemon=True)
    th.start()
    for cycle in range(3):
        f, flog = start_filter()
        s = state()
        check(s.get("pid") == f.pid and s.get("state") == "filtering", f"cycle {cycle + 1}: filtering ({s.get('state')})")
        check(flowing(), f"cycle {cycle + 1}: the audio runs")
        stop_filter(f, flog)
    churning[0] = False
    th.join()
    for p in churn_apps:
        p.kill()

    print("=== 9. a stuck filter holding the lock: the next start takes over", flush=True)
    f, flog = start_filter("--test-hang")
    time.sleep(6.5)  # its state is now over 5 s old; its watchdog has not acted yet (10 s)
    g, glog = start_filter()
    s = state()
    check(s.get("pid") == g.pid and s.get("state") == "filtering", f"the new filter runs ({s.get('pid')} vs {g.pid})")
    check(f.poll() is not None, "the stuck one was ended")
    check(flowing(), "the audio runs")
    stop_filter(g, glog)
    time.sleep(1)

    print("=== 10. a stuck filter ends itself (watchdog)", flush=True)
    f, flog = start_filter("--test-hang")
    try:
        code = f.wait(timeout=20)
    except subprocess.TimeoutExpired:
        code = None
    check(code == 3, f"the watchdog ended it (exit {code})")
    va = volume(apid)
    check(va is not None and abs(va - 1e-4) < 1e-6, f"apps stay silent ({va})")
    subprocess.run([FILTER, "stop", "--dir", STATE_DIR], timeout=30)
    time.sleep(1.5)
    va = volume(apid)
    check(va is not None and abs(va - 1) < 1e-4, f"stop gives the level back ({va})")
    a.kill()

    print("=== 11. a hung filter behind an old state (seen on a PC: 0.2.10 hung, state.json still said stopped)",
          flush=True)
    c, cpid = tone("tone-d")
    f, flog = start_filter()
    vc = volume(cpid)
    check(vc is not None and abs(vc - 1e-4) < 1e-6, f"lowered ({vc})")
    suspend(f.pid)  # frozen: holds the lock, writes nothing
    with open(os.path.join(STATE_DIR, "state.json"), "w", encoding="utf-8") as sf:
        sf.write('{"pid":4,"t":%d,"state":"stopped","engine":""}\n' % int(time.time() * 1000 - 3600_000))
    subprocess.run([FILTER, "stop", "--dir", STATE_DIR], timeout=30)
    try:
        f.wait(timeout=10)
    except subprocess.TimeoutExpired:
        pass
    check(f.poll() is not None, "stop ended the hung filter")
    time.sleep(1.5)
    vb = volume(cpid)
    check(vb is not None and abs(vb - 1) < 1e-4, f"stop gave the level back ({vb})")
    g, glog = start_filter()
    s = state()
    check(s.get("pid") == g.pid and s.get("state") == "filtering", f"a new filter starts ({s.get('state')})")
    stop_filter(g, glog)
    c.kill()

    print("=== 12. Windows closes the filter (as before a Store update or uninstall: WM_ENDSESSION, ENDSESSION_CLOSEAPP, "
          "then the process is ended)", flush=True)
    e, epid = tone("tone-e")
    f, flog = start_filter()
    ve = volume(epid)
    check(ve is not None and abs(ve - 1e-4) < 1e-6, f"lowered ({ve})")
    h = filter_window(f.pid)
    check(h is not None, "the filter has a (hidden) top-level window for Windows to ask")
    if h:
        u = ctypes.windll.user32
        res = ctypes.c_size_t(0)
        u.SendMessageTimeoutW(h, 0x0011, 0, 1, 0, 5000, ctypes.byref(res))  # WM_QUERYENDSESSION, ENDSESSION_CLOSEAPP
        check(res.value == 1, f"it agrees to close ({res.value})")
        u.SendMessageTimeoutW(h, 0x0016, 1, 1, 0, 8000, ctypes.byref(res))  # WM_ENDSESSION: returns once done
    f.kill()  # what Windows does once WM_ENDSESSION is answered
    f.wait()
    ve = volume(epid)
    check(ve is not None and abs(ve - 1) < 1e-4, f"the level was given back before the process ended ({ve})")
    s = state()
    check(s.get("state") in ("stopped", "restoring"), f"the state says stopped, not filtering ({s.get('state')})")
    e.kill()

    test_off_apps()
    test_keep_singing()

    print()
    if failures:
        print(f"{len(failures)} check(s) failed:\n  " + "\n  ".join(failures))
        sys.exit(1)
    print("all checks passed")


if __name__ == "__main__":
    main()
