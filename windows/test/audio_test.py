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


def volume(pid, wait=5):
    r = wtest("volume", "--pid", pid, "--wait", wait)
    return float(r.stdout.strip()) if r.returncode == 0 else None


def state():
    try:
        with open(os.path.join(STATE_DIR, "state.json"), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


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


def main():
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

    print()
    if failures:
        print(f"{len(failures)} check(s) failed:\n  " + "\n  ".join(failures))
        sys.exit(1)
    print("all checks passed")


if __name__ == "__main__":
    main()
