#!/usr/bin/env python3
"""The waaiya daemon (linux/bin/islamic-mute run --default) against a fake sound server: no PulseAudio needed.

    python3 linux/test_daemon_fake.py

A fake `pactl` (this file, run as `pactl`) keeps sinks and streams in a JSON file; a fake filter stands in for
im-pulse. Checks:
  - start: the virtual output is made the default and the apps' streams are moved onto it;
  - a stream the sound server puts back on the real output (its saved per-app device) is moved onto it again,
    but never the filter's own output stream;
  - `reload` (women's singing turned on): only the filter restarts, with the new flags; no stream ever goes back
    to the real output (no unfiltered sound);
  - `status`: running and what the engine loaded (ok / model not loaded), mono by default, stereo on request;
  - filter.log is cut down at start when it has grown large;
  - the filter's model did not load and keep-silent is off: the daemon gives the normal sound back and exits;
  - the daemon killed: apps stay silent; `waaiya stop` then gives the normal sound back;
  - stop (SIGTERM): the normal sound back, the virtual output removed.
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


# ---------------------------------------------------------------- fake pactl


def pactl(argv):
    path = os.environ["FAKE_PA"]
    with open(path) as f:
        st = json.load(f)
    out = []
    a = argv
    sinks = st["sinks"]  # name -> index
    by_index = {v: k for k, v in sinks.items()}

    def log(line):
        with open(path + ".log", "a") as f:
            f.write(line + "\n")

    if a[:1] == ["info"]:
        out.append("Server Name: fake")
        out.append(f"Default Sink: {st['default']}")
    elif a[:1] == ["get-default-sink"]:
        out.append(st["default"])
    elif a[:3] == ["list", "short", "sinks"]:
        out += [f"{i}\t{n}\tmodule\tfloat32le 2ch 48000Hz\tRUNNING" for n, i in sinks.items()]
    elif a[:3] == ["list", "short", "sink-inputs"]:
        out += [f"{k}\t{v['sink']}\t1\tprotocol-native.c\tfloat32le 2ch 48000Hz" for k, v in st["inputs"].items()]
    elif a[:2] == ["list", "sink-inputs"]:
        for k, v in st["inputs"].items():
            out += [f"Sink Input #{k}", "\tDriver: protocol-native.c", f"\tSink: {v['sink']}", "\tProperties:",
                    f"\t\tapplication.name = \"{v['app']}\""]
    elif a[:2] == ["load-module", "module-null-sink"]:
        name = [x.split("=", 1)[1] for x in a if x.startswith("sink_name=")][0]
        sinks[name] = max(sinks.values()) + 1
        st["modules"][str(sinks[name] + 100)] = name
        out.append(str(sinks[name] + 100))
    elif a[:1] == ["unload-module"]:
        name = st["modules"].pop(a[1], None)
        if name:
            idx = sinks.pop(name)
            for v in st["inputs"].values():  # streams on a removed sink fall back to the default
                if v["sink"] == idx:
                    v["sink"] = sinks.get(st["default"], min(sinks.values()))
    elif a[:1] == ["set-default-sink"]:
        st["default"] = a[1]
        log(f"default {a[1]}")
    elif a[:1] == ["move-sink-input"]:
        k, name = a[1], a[2]
        if k in st["inputs"] and name in sinks:
            st["inputs"][k]["sink"] = sinks[name]
            log(f"move {k} {name}")
        else:
            return 1
    elif a[:1] == ["set-sink-volume"]:
        pass
    else:
        sys.stderr.write(f"fake pactl: {a}\n")
        return 1
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(st, f)
    os.replace(tmp, path)
    if out:
        print("\n".join(out))
    return 0


FAKE_FILTER = r"""#!/usr/bin/env bash
echo "$*" >> "$FAKE_DIR/filter.args"
sf=""; while [ $# -gt 0 ]; do [ "$1" = --status-file ] && sf="$2"; shift; done
[ -n "$sf" ] && cat "$FAKE_DIR/engine_status" > "$sf"
trap 'exit 0' TERM
while :; do sleep 0.1; done
"""


# ---------------------------------------------------------------- the test


def check(cond, msg):
    if not cond:
        raise AssertionError(msg)
    print("ok  ", msg)


def main():
    tmp = tempfile.mkdtemp(prefix="waaiya-daemon-")
    fake = os.path.join(tmp, "fake")
    bindir = os.path.join(tmp, "bin")
    os.makedirs(fake)
    os.makedirs(bindir)
    pa = os.path.join(fake, "pa.json")
    with open(pa, "w") as f:
        json.dump({"sinks": {"speakers": 1}, "default": "speakers", "modules": {},
                   "inputs": {"10": {"sink": 1, "app": "Firefox"}}}, f)
    with open(os.path.join(bindir, "pactl"), "w") as f:
        f.write(f"#!/bin/sh\nexec {sys.executable} {os.path.abspath(__file__)} --pactl \"$@\"\n")
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
    state = os.path.join(env["XDG_STATE_HOME"], "islamic-mute")
    os.makedirs(lib)
    os.makedirs(cfg)
    os.makedirs(state)
    for name in ("im-stream", "im-pulse"):
        with open(os.path.join(lib, name), "w") as f:
            f.write(FAKE_FILTER)
        os.chmod(os.path.join(lib, name), 0o755)
    with open(os.path.join(cfg, "model"), "w") as f:
        f.write(os.path.join(tmp, "model.onnx\n"))
    with open(os.path.join(fake, "engine_status"), "w") as f:
        f.write("ok\n")
    with open(os.path.join(state, "filter.log"), "wb") as f:
        f.write(b"x" * 700_000)

    def pa_state():
        with open(pa) as f:
            return json.load(f)

    def sink_of(k):
        st = pa_state()
        return {v: n for n, v in st["sinks"].items()}.get(st["inputs"][k]["sink"])

    def add_input(k, app, sink="speakers"):
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

    def moves_to_speakers():
        try:
            return [l for l in open(pa + ".log") if l.startswith("move ") and l.split()[2] == "speakers"]
        except FileNotFoundError:
            return []

    d = subprocess.Popen([SCRIPT, "run", "--default"], env=env, stderr=subprocess.PIPE, text=True)
    try:
        wait(lambda: os.path.exists(os.path.join(fake, "filter.args")), 10, "the filter to start")
        wait(lambda: sink_of("10") == "islamic_mute", 5, "the app's stream on the virtual output")
        check(pa_state()["default"] == "islamic_mute", "start: the virtual output is the default")
        check(os.path.getsize(os.path.join(state, "filter.log")) < 200_000, "start: a large filter.log is cut down")
        args = open(os.path.join(fake, "filter.args")).read().splitlines()
        check("--mono" in args[-1] and "--stats-s 300" in args[-1], f"filter args: mono by default, stats every 5 min")

        # the sound server restores a stream to the real output: moved again; our own output stream never
        add_input("11", "Chromium")
        add_input("12", "Islamic Mute")
        wait(lambda: sink_of("11") == "islamic_mute", 5, "a restored stream to be moved back onto the virtual output")
        time.sleep(1.5)
        check(sink_of("11") == "islamic_mute", "a stream restored to the real output is moved onto the virtual one")
        check(sink_of("12") == "speakers", "the filter's own output stream is never moved")

        st = waaiya("status").stdout
        check("filter:   running" in st and "engine:   ok" in st and "sound:    mono" in st, "status: running, engine ok, mono")

        # women's singing on + reload: only the filter restarts, nothing plays unfiltered meanwhile
        before = len(moves_to_speakers())
        waaiya("women-singing", "on")
        waaiya("stereo", "on")
        r = waaiya("reload")
        check(r.returncode == 0, "reload signals the daemon")
        wait(lambda: len(open(os.path.join(fake, "filter.args")).read().splitlines()) >= 2, 5, "the filter restart")
        args = open(os.path.join(fake, "filter.args")).read().splitlines()
        check("--mute-female-singing" in args[-1] and "--mono" not in args[-1], "reload: new flags (singing, stereo)")
        check(d.poll() is None, "reload: the daemon keeps running")
        time.sleep(1.2)
        check(len(moves_to_speakers()) == before and sink_of("10") == "islamic_mute",
              "reload: no stream was moved to the real output (no unfiltered sound)")
        check(pa_state()["default"] == "islamic_mute", "reload: the virtual output stays the default")

        # the model did not load (the filter runs silent): status says so
        with open(os.path.join(state, "filter.status"), "w") as f:
            f.write("model_failed cannot load model\n")
        st = waaiya("status").stdout
        check("model not loaded" in st, "status: model not loaded")
        # keep-silent on (default): the daemon keeps the apps silent
        time.sleep(1.5)
        check(d.poll() is None and sink_of("10") == "islamic_mute", "keep-silent on: apps stay on the silent output")
        # keep-silent off: normal sound back, the daemon ends
        waaiya("keep-silent", "off")
        d.wait(timeout=10)
        check(d.returncode == 0, "keep-silent off + model failed: the daemon gives up")
        check(sink_of("10") == "speakers" and pa_state()["default"] == "speakers", "... and the sound is normal again")
        check("islamic_mute" not in pa_state()["sinks"], "... and the virtual output is gone")

        # the daemon dies (keep-silent on): the apps stay silent; 'waaiya stop' still gives the normal sound back
        d = subprocess.Popen([SCRIPT, "run", "--default"], env=env, stderr=subprocess.PIPE, text=True)
        wait(lambda: sink_of("10") == "islamic_mute", 10, "the stream on the virtual output again")
        d.kill()
        d.wait(timeout=10)
        subprocess.run(["pkill", "-f", os.path.join(lib, "im-")], check=False)
        time.sleep(0.3)
        check(sink_of("10") == "islamic_mute", "daemon killed, keep-silent on: apps stay on the silent output")
        check("down" in waaiya("status").stdout, "status: filter down, apps silent")
        waaiya("stop")
        check(sink_of("10") == "speakers" and pa_state()["default"] == "speakers",
              "stop with the daemon gone: the normal sound is back")
        check("islamic_mute" not in pa_state()["sinks"], "... and the virtual output is removed")

        # a normal run again, then stop
        waaiya("keep-silent", "on")
        with open(os.path.join(fake, "engine_status"), "w") as f:
            f.write("ok\n")
        d = subprocess.Popen([SCRIPT, "run", "--default"], env=env, stderr=subprocess.PIPE, text=True)
        wait(lambda: sink_of("10") == "islamic_mute", 10, "the stream on the virtual output again")
        d.send_signal(signal.SIGTERM)
        d.wait(timeout=10)
        check(sink_of("10") == "speakers" and pa_state()["default"] == "speakers", "stop: the normal sound is back")
        check("islamic_mute" not in pa_state()["sinks"], "stop: the virtual output is removed")
        print("all daemon checks passed")
        return 0
    finally:
        if d.poll() is None:
            d.kill()
        subprocess.run(["pkill", "-f", os.path.join(lib, "im-")], check=False)


if __name__ == "__main__":
    if sys.argv[1:2] == ["--pactl"]:
        sys.exit(pactl(sys.argv[2:]))
    sys.exit(main())
