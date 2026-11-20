#!/usr/bin/env python3
"""Apps heard unfiltered ("Fix mistakes", setting filter_off_apps) in the waaiya daemon, against the fake sound
server of test_daemon_fake.py: no PulseAudio needed.

    python3 linux/test_filter_off_apps.py

Checks:
  - at start, a listed app stays on the real output while the others move to the virtual output;
  - names match exactly (a listed "Fire" does not free "Firefox"; a name with spaces and quotes works);
  - adding an app moves its stream back to the real output within a second, with no reload;
  - removing it moves the stream onto the virtual output again (filtered);
  - a new stream of a listed app that lands on the virtual output (the default) is moved out;
  - `waaiya apps` lists the playing apps without the filter's own stream; `status` names the unfiltered apps;
  - stop: everything back on the real output.
"""
import json
import os
import signal
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "bin", "islamic-mute")
FAKE = os.path.join(HERE, "test_daemon_fake.py")

FAKE_FILTER = r"""#!/usr/bin/env bash
sf=""; while [ $# -gt 0 ]; do [ "$1" = --status-file ] && sf="$2"; shift; done
[ -n "$sf" ] && echo ok > "$sf"
trap 'exit 0' TERM
while :; do sleep 0.1; done
"""


def check(cond, msg):
    if not cond:
        raise AssertionError(msg)
    print("ok  ", msg)


def main():
    tmp = tempfile.mkdtemp(prefix="waaiya-offapps-")
    fake = os.path.join(tmp, "fake")
    bindir = os.path.join(tmp, "bin")
    os.makedirs(fake)
    os.makedirs(bindir)
    pa = os.path.join(fake, "pa.json")
    with open(pa, "w") as f:
        json.dump({"sinks": {"speakers": 1}, "default": "speakers", "modules": {},
                   "inputs": {"10": {"sink": 1, "app": "Firefox"},
                              "20": {"sink": 1, "app": 'Quran "Player" app'}}}, f)
    with open(os.path.join(bindir, "pactl"), "w") as f:
        f.write(f"#!/bin/sh\nexec {sys.executable} {FAKE} --pactl \"$@\"\n")
    os.chmod(os.path.join(bindir, "pactl"), 0o755)
    env = {
        "PATH": f"{bindir}:/usr/bin:/bin",
        "HOME": tmp,
        "XDG_DATA_HOME": os.path.join(tmp, "data"),
        "XDG_CONFIG_HOME": os.path.join(tmp, "config"),
        "XDG_STATE_HOME": os.path.join(tmp, "state"),
        "FAKE_PA": pa,
        "FAKE_DIR": fake,
        "LANG": "C",
    }
    lib = os.path.join(env["XDG_DATA_HOME"], "islamic-mute", "lib")
    cfg = os.path.join(env["XDG_CONFIG_HOME"], "islamic-mute")
    os.makedirs(lib)
    os.makedirs(cfg)
    for name in ("im-stream", "im-pulse"):
        with open(os.path.join(lib, name), "w") as f:
            f.write(FAKE_FILTER)
        os.chmod(os.path.join(lib, name), 0o755)
    with open(os.path.join(cfg, "model"), "w") as f:
        f.write(os.path.join(tmp, "model.onnx\n"))

    def pa_state():
        with open(pa) as f:
            return json.load(f)

    def sink_of(k):
        st = pa_state()
        return {v: n for n, v in st["sinks"].items()}.get(st["inputs"][k]["sink"])

    def add_input(k, app, sink):
        st = pa_state()
        st["inputs"][k] = {"sink": st["sinks"][sink], "app": app}
        with open(pa, "w") as f:
            json.dump(st, f)

    def wait(pred, timeout, what):
        end = time.time() + timeout
        while time.time() < end:
            if pred():
                return
            time.sleep(0.1)
        raise AssertionError(f"timeout: {what}")

    def waaiya(*args):
        return subprocess.run([SCRIPT, *args], env=env, capture_output=True, text=True, timeout=20)

    # the Quran player is listed before the start; "Fire" must not free Firefox
    r = waaiya("filter-off-apps", 'Quran "Player" app', "Fire")
    check(r.returncode == 0, "filter-off-apps writes the list")
    d = subprocess.Popen([SCRIPT, "run", "--default"], env=env, stderr=subprocess.PIPE, text=True)
    try:
        wait(lambda: sink_of("10") == "islamic_mute", 10, "Firefox on the virtual output")
        add_input("30", "Waaiya filter", "speakers")  # the filter's own output (im-pulse)
        time.sleep(1.5)
        check(sink_of("20") == "speakers", "start: a listed app stays on the real output (exact name, quotes)")
        check(sink_of("10") == "islamic_mute", "start: a name that only begins like a listed one is filtered")
        check(sink_of("30") == "speakers", "the filter's own stream is never moved")

        # add Firefox: out within about a second, no reload
        r = waaiya("filter-off-apps", 'Quran "Player" app', "Firefox")
        wait(lambda: sink_of("10") == "speakers", 3, "Firefox back on the real output")
        check(d.poll() is None, "adding an app: the daemon keeps running, no reload")

        # remove the Quran player: filtered again
        r = waaiya("filter-off-apps", "Firefox")
        wait(lambda: sink_of("20") == "islamic_mute", 3, "the Quran player filtered again")
        check(sink_of("10") == "speakers", "removing one app leaves the other unfiltered")

        # a new Firefox stream lands on the default (the virtual output): moved out
        add_input("11", "Firefox", "islamic_mute")
        wait(lambda: sink_of("11") == "speakers", 3, "a new stream of a listed app moved to the real output")

        apps = waaiya("apps").stdout.splitlines()
        check("Firefox" in apps and 'Quran "Player" app' in apps and "Waaiya filter" not in apps,
              "apps: the playing apps, not the filter's own stream")
        check("unfiltered apps: Firefox" in waaiya("status").stdout, "status names the unfiltered apps")

        # none listed: everything filtered
        waaiya("filter-off-apps")
        wait(lambda: sink_of("10") == "islamic_mute" and sink_of("11") == "islamic_mute", 3, "all filtered again")
        check(not os.path.exists(os.path.join(cfg, "filter_off_apps")), "an empty list removes the file")

        d.send_signal(signal.SIGTERM)
        d.wait(timeout=10)
        check(all(sink_of(k) == "speakers" for k in ("10", "11", "20")), "stop: every app on the real output")
        print("all filter-off-apps checks passed")
        return 0
    finally:
        if d.poll() is None:
            d.kill()
        # the fake filters are children of the daemon's process groups; end any left by pid, never by pattern
        for pidfile in (os.path.join(env["XDG_STATE_HOME"], "islamic-mute", "filter.pid"),):
            try:
                os.killpg(int(open(pidfile).read()), signal.SIGKILL)
            except (OSError, ValueError):
                pass


if __name__ == "__main__":
    sys.exit(main())
