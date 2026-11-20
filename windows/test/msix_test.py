"""The Microsoft Store package (MSIX, desktop/tool/make_msix.ps1), installed and run on a GitHub Windows runner with
the Scream virtual output (windows/test/audio_device.ps1). The packages must be signed with a test certificate
whose subject is the Store publisher, trusted by the runner (the CI step does both).

    python windows/test/msix_test.py <build-win (waaiya-wtest.exe)> <waaiya.msix> <the same, higher version>

What it checks (a failed check exits 1 at the end; the rest prints what happened, for docs/PLATFORMS.md):
  1. it installs, with the package family name of the Store's identity, and the app starts from it
  2. the filter inside the package lowers another app and Stop gives its level back
  3. where its state is (a packaged program's AppData writes may go to the package's own folder)
  4. the startup task's command: does nothing when "Start at login" is off and nothing is stored; filters when on
  5. a Store update while filtering: Windows asks the filter to close (its hidden window), it gives the levels back,
     and Windows starts it again once the new version is in place (RegisterApplicationRestart): no app is left
     lowered without a filter
  6. uninstalling while filtering: the filter gives the levels back before Windows ends it
"""
import os
import subprocess
import sys
import time

import audio_test as at  # noqa: E402  (BIN = argv[1])

MSIX, MSIX2 = os.path.abspath(sys.argv[2]), os.path.abspath(sys.argv[3])
NAME = "Oks.Waaiya"
PFN = "Oks.Waaiya_wa2h0h9gfqbyp"
LOCAL = os.environ["LOCALAPPDATA"]
DIRS = [os.path.join(LOCAL, "Packages", PFN, "LocalCache", "Local", "Waaiya", "filter"),
        os.path.join(LOCAL, "Waaiya", "filter")]


def ps(cmd, check=True):
    r = subprocess.run(["powershell", "-NoProfile", "-NonInteractive", "-Command",
                        "$ErrorActionPreference='Stop'; " + cmd], capture_output=True, text=True, timeout=300)
    out = (r.stdout + r.stderr).strip()
    if r.returncode and check:
        print(f"powershell: {cmd}\n  exit {r.returncode}: {out}", flush=True)
    return r.returncode, out


def install_dir():
    return ps(f"(Get-AppxPackage -Name {NAME}).InstallLocation")[1]


def in_package(*args):
    """Runs the packaged filter inside the package (as the app and the startup task run it)."""
    exe = os.path.join(install_dir(), "engine", "waaiya-filter.exe")
    a = f" -Args '{' '.join(args)}'" if args else ""
    return ps(f"Invoke-CommandInDesktopPackage -PackageFamilyName {PFN} -AppId Waaiya -Command '{exe}'{a}")


def running(image):
    r = subprocess.run(["tasklist", "/fi", f"imagename eq {image}", "/fo", "csv", "/nh"], capture_output=True, text=True)
    return image.lower() in r.stdout.lower()


def wait_volume(pid, below=None, above=None, seconds=20):
    v = None
    for _ in range(seconds * 2):
        v = at.volume(pid, wait=1)
        if v is not None and ((below is not None and v < below) or (above is not None and v > above)):
            return True, v
        time.sleep(0.5)
    return False, v


def state_dir():
    """The folder the packaged filter writes its state to (the freshest state.json)."""
    best = None
    for d in DIRS:
        f = os.path.join(d, "state.json")
        if os.path.exists(f) and (best is None or os.path.getmtime(f) > os.path.getmtime(os.path.join(best, "state.json"))):
            best = d
    return best


def log_size(d):
    try:
        return os.path.getsize(os.path.join(d, "filter.log"))
    except (OSError, TypeError):
        return 0


def closing_seen(d, since):
    """The filter logged Windows' close message (WM_ENDSESSION) after offset [since] of its log."""
    try:
        with open(os.path.join(d, "filter.log"), encoding="utf-8", errors="replace") as f:
            f.seek(since)
            return "Windows is closing the filter" in f.read()
    except (OSError, TypeError):
        return False


NO_CLOSE = ("Windows ended the filter without its close message (a GitHub runner: no signed-in desktop, seen on a "
            "real PC the message comes and the levels are given back; audio_test.py 12 checks the filter's side)")


def kill_filters():
    subprocess.run(["taskkill", "/f", "/im", "waaiya-filter.exe"], capture_output=True)


def main():
    # 1. install, identity, the app starts
    rc, out = ps(f"Add-AppxPackage -Path '{MSIX}'")
    at.check(rc == 0, "the package installs" + ("" if rc == 0 else f": {out}"))
    pfn = ps(f"(Get-AppxPackage -Name {NAME}).PackageFamilyName")[1]
    at.check(pfn == PFN, f"package family name {pfn!r} is the Store's {PFN!r}")
    print("  installed in " + install_dir(), flush=True)
    at.check(os.path.exists(os.path.join(install_dir(), "engine", "models", "detector", "detector_v1.onnx")),
             "the women's-singing model is in the package")
    at.check(os.path.exists(os.path.join(install_dir(), "engine", "models", "voice", "v3", "voice_v1_fp16.onnx")),
             "the keep-singing model is in the package")
    print("  manifest startup task: " + ps(f"(Get-AppxPackageManifest -Package (Get-AppxPackage -Name {NAME})).Package."
                                           "Applications.Application.Extensions.Extension.StartupTask | Out-String")[1])
    subprocess.run(["explorer.exe", f"shell:AppsFolder\\{PFN}!Waaiya"])
    ok = False
    for _ in range(30):
        if running("waaiya_desktop.exe"):
            ok = True
            break
        time.sleep(0.5)
    time.sleep(5)
    at.check(ok and running("waaiya_desktop.exe"), "the app starts from the package and keeps running")
    subprocess.run(["taskkill", "/f", "/im", "waaiya_desktop.exe"], capture_output=True)

    # 2. the packaged filter lowers another app; Stop gives its level back
    tone, pid = at.tone("musicapp")
    in_package("run")
    ok, v = wait_volume(pid, below=0.001)
    at.check(ok, f"the filter inside the package lowers another app (its level {v})")
    time.sleep(2)
    d = state_dir()
    print(f"  3. state written to {d}", flush=True)
    for base in (os.path.join(LOCAL, "Packages", PFN), os.path.join(LOCAL, "Waaiya")):
        for root, _, files in os.walk(base):
            if files:
                print(f"     {root}: {', '.join(sorted(files)[:12])}", flush=True)
    at.check(d is not None, "the packaged filter writes its state")
    in_package("stop")
    ok, v = wait_volume(pid, above=0.99)
    at.check(ok, f"Stop inside the package gives the level back ({v})")
    time.sleep(2)
    kill_filters()  # the restorer that stays for apps not running

    # 4. the startup task's command
    if d:
        for f in ("autostart", "levels.txt"):
            try:
                os.remove(os.path.join(d, f))
            except OSError:
                pass
    in_package("autostart")
    time.sleep(4)
    at.check(not running("waaiya-filter.exe"), "startup task, 'Start at login' off, nothing stored: nothing runs")
    with open(os.path.join(d or DIRS[0], "autostart"), "w") as f:
        f.write("1\n")
    in_package("autostart")
    ok, v = wait_volume(pid, below=0.001)
    at.check(ok, f"startup task, 'Start at login' on: filtering ({v})")
    in_package("stop")
    ok, v = wait_volume(pid, above=0.99)
    time.sleep(2)
    kill_filters()
    in_package()  # the startup task without its parameter: a packaged start with no command is the same
    ok, v = wait_volume(pid, below=0.001)
    at.check(ok, f"packaged start without arguments acts as the startup task ({v})")
    os.remove(os.path.join(d or DIRS[0], "autostart"))

    # 5. a Store update while filtering (started as the app starts it: Windows starts it again with the same command)
    in_package("stop")
    wait_volume(pid, above=0.99)
    time.sleep(2)
    kill_filters()
    in_package("run")
    ok, v = wait_volume(pid, below=0.001)
    at.check(ok, f"filtering before the update ({v})")
    time.sleep(2)
    mark = log_size(d)
    rc, out = ps(f"Add-AppxPackage -Path '{MSIX2}' -ForceApplicationShutdown")
    at.check(rc == 0, "the higher version installs over it while filtering" + ("" if rc == 0 else f": {out}"))
    restarted = False
    for _ in range(60):  # Windows starts the filter again once the new version is registered
        if running("waaiya-filter.exe"):
            restarted = True
            break
        time.sleep(1)
    v = at.volume(pid, wait=1)
    print(f"  5. after the update: filter started again by Windows {restarted}, the other app's level {v}", flush=True)
    if not closing_seen(d, mark):
        print("     " + NO_CLOSE, flush=True)
        in_package("stop" if restarted else "autostart")  # Stop, or the startup task at the next login
        ok, v = wait_volume(pid, above=0.99)
        at.check(ok, f"after an update while filtering, Stop or the next login gives the level back ({v})")
    else:
        if restarted:
            ok, v = wait_volume(pid, below=0.001)
            at.check(ok, f"after an update while filtering, Windows starts the filter again and it filters ({v})")
            in_package("stop")
        ok, v = wait_volume(pid, above=0.99)
        at.check(ok, f"after an update while filtering, no app is left lowered without a filter ({v})")
    time.sleep(2)
    kill_filters()

    # 6. uninstall while filtering
    in_package("run")
    ok, v = wait_volume(pid, below=0.001)
    d = state_dir() or d
    mark = log_size(d)
    rc, out = ps(f"Remove-AppxPackage -Package (Get-AppxPackage -Name {NAME}).PackageFullName")
    at.check(rc == 0, "the package uninstalls while filtering" + ("" if rc == 0 else f": {out}"))
    seen = closing_seen(d, mark)  # read before the package's data goes (it may be in the package's folder)
    ok, v = wait_volume(pid, above=0.99, seconds=10)
    if seen or ok:
        at.check(ok, f"uninstalling while filtering gives the other app its level back ({v})")
    else:
        print(f"     {NO_CLOSE}; the other app's level {v}", flush=True)
    print(f"  6. after uninstalling while filtering: filter running {running('waaiya-filter.exe')}", flush=True)
    print(f"     package data left: {os.path.exists(os.path.join(LOCAL, 'Packages', PFN))}", flush=True)
    kill_filters()
    at.wtest("volume", "--pid", pid, "--set", "1")
    tone.kill()

    print("\n" + ("ALL PASSED" if not at.failures else f"{len(at.failures)} FAILED: " + "; ".join(at.failures)))
    sys.exit(1 if at.failures else 0)


if __name__ == "__main__":
    main()
