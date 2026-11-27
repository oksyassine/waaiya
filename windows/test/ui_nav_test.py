"""The app's pages switched by real mouse clicks on a GitHub Windows runner: Settings, then back to Filter, several
times, first with no accessibility client, then with one reading the window (UI Automation: Flutter then builds its
accessibility tree, as on a PC with Narrator, a touch keyboard or any tool that reads windows). The app must still be
running at the end. On a crash: the exit code and Windows' own record of it (Application log, events 1000 and 1001).

    python windows/test/ui_nav_test.py exe <waaiya_desktop.exe> <screenshots folder>
    python windows/test/ui_nav_test.py msix <package family name> <screenshots folder>   (the package installed)
"""
import ctypes
import ctypes.wintypes as wt
import json
import os
import subprocess
import sys
import time

MODE, TARGET, SHOTS = sys.argv[1], sys.argv[2], os.path.abspath(sys.argv[3])
os.makedirs(SHOTS, exist_ok=True)
u32 = ctypes.WinDLL("user32", use_last_error=True)
k32 = ctypes.WinDLL("kernel32", use_last_error=True)
u32.SetProcessDpiAwarenessContext(ctypes.c_void_p(-4))  # per-monitor v2: real pixels
failures = []


def check(ok, what):
    print(("ok   " if ok else "FAIL ") + what, flush=True)
    if not ok:
        failures.append(what)


def ps(cmd):
    r = subprocess.run(["powershell", "-NoProfile", "-NonInteractive", "-Command", cmd], capture_output=True, text=True,
                       timeout=300)
    return (r.stdout + r.stderr).strip()


def settings():
    """English (left to right, known labels) and the onboarding question answered: the main screen opens."""
    d = os.path.join(os.environ["APPDATA"], "Waaiya")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "settings.json"), "w") as f:
        json.dump({"gender": "man", "lang": "en"}, f)


def pid_of(image):
    out = subprocess.run(["tasklist", "/fi", f"imagename eq {image}", "/fo", "csv", "/nh"], capture_output=True,
                         text=True).stdout
    for line in out.splitlines():
        parts = [p.strip('"') for p in line.split('","')]
        if len(parts) > 1 and parts[0].lower() == image.lower():
            return int(parts[1])
    return None


def window():
    return u32.FindWindowW("FLUTTER_RUNNER_WIN32_WINDOW", "Waaiya")


def client_rect(hwnd):
    r = wt.RECT()
    u32.GetClientRect(hwnd, ctypes.byref(r))
    p = wt.POINT(0, 0)
    u32.ClientToScreen(hwnd, ctypes.byref(p))
    return p.x, p.y, r.right, r.bottom


def click(x, y):
    u32.SetCursorPos(int(x), int(y))
    time.sleep(0.05)
    u32.mouse_event(0x0002, 0, 0, 0, 0)  # left down
    time.sleep(0.05)
    u32.mouse_event(0x0004, 0, 0, 0, 0)  # left up


def shot(name):
    x, y, w, h = client_rect(window()) if window() else (0, 0, 800, 600)
    path = os.path.join(SHOTS, name + ".png")
    ps("Add-Type -AssemblyName System.Drawing; "
       f"$b = New-Object System.Drawing.Bitmap({w}, {h}); $g = [System.Drawing.Graphics]::FromImage($b); "
       f"$g.CopyFromScreen({x}, {y}, 0, 0, $b.Size); $b.Save('{path}'); $g.Dispose(); $b.Dispose()")


def digest(name):
    import hashlib
    with open(os.path.join(SHOTS, name + ".png"), "rb") as f:
        return hashlib.md5(f.read()).hexdigest()[:8]


def alive(proc_handle):
    code = wt.DWORD()
    k32.GetExitCodeProcess(proc_handle, ctypes.byref(code))
    return code.value == 259, code.value  # STILL_ACTIVE


def uia_names():
    """Reads the Flutter view's whole UI Automation tree (Flutter turns its accessibility on for this; asked twice,
    as the first question only turns it on)."""
    view = u32.FindWindowExW(window(), None, "FLUTTERVIEW", None)
    script = (
        "Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes; "
        f"$e = [System.Windows.Automation.AutomationElement]::FromHandle([IntPtr]{view or window()}); "
        "$walker = [System.Windows.Automation.TreeWalker]::RawViewWalker; $n = 0; $lines = @(); "
        "function Walk($x, $depth) { $script:n++; if ($script:lines.Count -lt 80) { $script:lines += ('  ' * $depth) + "
        "$x.Current.ControlType.ProgrammaticName + ' | ' + $x.Current.Name + ' | ' + $x.Current.AutomationId }; "
        "$c = $walker.GetFirstChild($x); while ($c) { Walk $c ($depth + 1); $c = $walker.GetNextSibling($c) } } "
        "Walk $e 0; \"$n elements\"; $lines")
    ps(script)
    time.sleep(2)
    return ps(script)


def crash_record():
    print(ps("Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000} -MaxEvents 1 | "
             "ForEach-Object { ($_.Message -split [Environment]::NewLine) -match 'offset' }"), flush=True)
    print(ps("Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,1001,1026} -MaxEvents 8 "
             "-ErrorAction SilentlyContinue | Where-Object { $_.Message -match 'waaiya' } | "
             "ForEach-Object { '--- ' + $_.TimeCreated + ' event ' + $_.Id; $_.Message }"), flush=True)


def main():
    settings()
    # Windows keeps a dump of a crash here (Windows Error Reporting, LocalDumps)
    dumps = os.path.join(SHOTS, "dumps")
    os.makedirs(dumps, exist_ok=True)
    key = r"HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\waaiya_desktop.exe"
    subprocess.run(["reg", "add", key, "/v", "DumpFolder", "/t", "REG_EXPAND_SZ", "/d", dumps, "/f"], capture_output=True)
    subprocess.run(["reg", "add", key, "/v", "DumpType", "/t", "REG_DWORD", "/d", "1", "/f"], capture_output=True)

    filtering = len(sys.argv) > 4 and sys.argv[4] == "filtering"
    if filtering:  # the filter running first, as on a PC where it started at login
        if MODE == "exe":
            subprocess.Popen([os.path.join(os.path.dirname(TARGET), "engine", "waaiya-filter.exe"), "run"])
        else:
            loc = ps("(Get-AppxPackage -Name Oks.Waaiya).InstallLocation")
            print(ps(f"Invoke-CommandInDesktopPackage -PackageFamilyName {TARGET} -AppId Waaiya "
                     f"-Command '{loc}\\engine\\waaiya-filter.exe' -Args 'run'"), flush=True)
        time.sleep(6)
        print("  filter running: " + str(pid_of("waaiya-filter.exe")), flush=True)
    if MODE == "exe":
        subprocess.Popen([TARGET])
    else:
        subprocess.run(["explorer.exe", f"shell:AppsFolder\\{TARGET}!Waaiya"])
    pid = None
    for _ in range(60):
        pid = pid_of("waaiya_desktop.exe")
        if pid and window() and u32.IsWindowVisible(window()):
            break
        time.sleep(0.5)
    check(bool(pid and window()), "the app starts and shows its window")
    if not (pid and window()):
        return
    proc = k32.OpenProcess(0x1000 | 0x00100000, False, pid)  # query limited information, synchronize
    time.sleep(4)  # the first state, the pages built
    hwnd = window()
    u32.ShowWindow(hwnd, 9)
    u32.SetForegroundWindow(hwnd)
    time.sleep(0.5)
    x, y, w, h = client_rect(hwnd)
    dpi = u32.GetDpiForWindow(hwnd) or 96
    bar_y = y + h - int(40 * dpi / 96)  # the bottom bar (80 logical pixels high)
    first, last = x + w * 0.1, x + w * 0.9  # Filter is the first page, Settings the last (English: left to right)
    print(f"  window {w}x{h} at {x},{y}, {dpi} dpi; bar at y={bar_y}", flush=True)
    shot("0-start")

    def rounds(tag, n=4):
        for i in range(n):
            click(last, bar_y)
            time.sleep(1.5)
            shot(f"{tag}-{i}-settings")
            ok, _ = alive(proc)
            if not ok:
                return f"on Settings, round {i + 1}"
            click(first, bar_y)
            time.sleep(1.5)
            shot(f"{tag}-{i}-filter")
            a, b = digest(f"{tag}-{i}-settings"), digest(f"{tag}-{i}-filter")
            print(f"  round {i + 1}: settings {a}, filter {b}" + (" (the same picture: the click did not switch)" if a == b else ""), flush=True)
            ok, _ = alive(proc)
            if not ok:
                return f"back on Filter, round {i + 1}"
        return None

    where = rounds("a")
    ok, code = alive(proc)
    check(ok, "Settings then Filter, 4 times, no accessibility client: the app keeps running"
          + ("" if ok else f" (ended {where}, exit code 0x{code:08X})"))
    if ok:
        print(uia_names(), flush=True)
        where = rounds("b")
        ok, code = alive(proc)
        check(ok, "the same with an accessibility client reading the window: the app keeps running"
              + ("" if ok else f" (ended {where}, exit code 0x{code:08X})"))
        if ok:
            print(uia_names(), flush=True)
    if not ok:
        crash_record()
        print("  dumps: " + ", ".join(os.listdir(dumps)), flush=True)
    subprocess.run(["taskkill", "/f", "/im", "waaiya_desktop.exe"], capture_output=True)
    subprocess.run(["taskkill", "/f", "/im", "waaiya-filter.exe"], capture_output=True)
    subprocess.run(["taskkill", "/f", "/im", "waaiya-blur.exe"], capture_output=True)


main()
sys.exit(1 if failures else 0)
