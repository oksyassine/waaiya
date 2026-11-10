"""Keeps the app's yt-dlp current without a new APK.

Sites change often and yt-dlp follows them within days, so the copy bundled in the APK goes stale. This module
downloads a newer yt-dlp wheel (and the yt-dlp-ejs version it pins) from PyPI into the app's private files and
puts it in front of the bundled copy on sys.path.

Safety:
- Only PyPI over HTTPS, only pure-Python wheels (py3-none-any) hosted on files.pythonhosted.org, checked
  against the SHA-256 that PyPI publishes; size capped; zip paths checked; only the yt_dlp / yt_dlp_ejs packages
  are extracted. The trust is the same as `pip install -U yt-dlp`.
- A new copy goes live only after it imports and reports the expected version. Otherwise it is deleted, and the
  previous copy (or the bundled one) is restored.
- At start, a downloaded copy is used only if it is newer than the bundled one, so an APK update that bundles
  a newer yt-dlp always wins. A copy that fails to import at start is deleted and the bundled one is used.

The app calls, in this order: activate() once before the first `import im_links`; then, from a background
thread, download(); then install() while no link is being opened (Links.kt holds a lock).
"""
import hashlib
import json
import os
import re
import shutil
import ssl
import sys
import time
import urllib.request
import zipfile

PYPI = "https://pypi.org/pypi/{}/json"
PYPI_VERSION = "https://pypi.org/pypi/{}/{}/json"
FILES_HOST = "https://files.pythonhosted.org/"
MAX_WHEEL = 16 << 20
TIMEOUT = 20
PACKAGES = ("yt_dlp", "yt_dlp_ejs")

_active_dir = None  # sys.path entry of the downloaded copy in use, or None for the bundled one
_active_version = None  # its version (None: the bundled one)


def _vt(v):
    """'2026.10.26' / '2026.11.04.232659' / '2026.11.4.232659.dev0' -> comparable tuple of ints."""
    v = re.sub(r"\.?dev\d*$", "", str(v or "0"))  # PyPI's nightly '...232659.dev0' is yt-dlp's '...232659'
    return tuple(int(x) for x in re.findall(r"\d+", v))


def _root(files_dir):
    return os.path.join(files_dir, "ytdlp")


def _state_path(files_dir):
    return os.path.join(_root(files_dir), "current.json")


def _read_state(files_dir):
    try:
        with open(_state_path(files_dir)) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def _write_state(files_dir, state):
    tmp = _state_path(files_dir) + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f)
    os.replace(tmp, _state_path(files_dir))


def _forget(files_dir, keep=None):
    """Delete every downloaded copy except `keep` (a directory name)."""
    root = _root(files_dir)
    if not os.path.isdir(root):
        return
    for name in os.listdir(root):
        p = os.path.join(root, name)
        if os.path.isdir(p) and name != keep:
            shutil.rmtree(p, ignore_errors=True)
    if keep is None:
        try:
            os.remove(_state_path(files_dir))
        except OSError:
            pass


def _purge_modules():
    for name in list(sys.modules):
        if name.split(".")[0] in PACKAGES + ("im_links",):
            del sys.modules[name]


def _use(path, version=None):
    global _active_dir, _active_version
    if _active_dir and _active_dir in sys.path:
        sys.path.remove(_active_dir)
    _active_dir, _active_version = path, (version if path else None)
    if path:
        sys.path.insert(0, path)


def _import_check(expected):
    """Import yt_dlp (and the EJS scripts) from the current sys.path; True if it reports `expected`."""
    _purge_modules()
    import importlib
    importlib.invalidate_caches()
    try:
        import yt_dlp
        import yt_dlp_ejs  # noqa: F401  (the YouTube challenge scripts; yt-dlp needs the version it pins)
        return _vt(yt_dlp.version.__version__) == _vt(expected)
    except Exception:
        return False


def activate(files_dir, bundled):
    """Before the first import of yt_dlp: use the downloaded copy if it is valid and newer than `bundled`.
    Returns the yt-dlp version that will be imported."""
    st = _read_state(files_dir)
    if st and _vt(st.get("version")) > _vt(bundled):
        path = os.path.join(_root(files_dir), st.get("dir", ""))
        if os.path.isfile(os.path.join(path, "yt_dlp", "__init__.py")):
            _use(path, st["version"])
            if _import_check(st["version"]):
                return st["version"]  # stays imported; im_links uses it
            _use(None)
    _forget(files_dir)
    _purge_modules()
    return bundled


def active_version(bundled):
    return _active_version or bundled


def _get(url, limit=1 << 20):
    ctx = ssl.create_default_context()
    req = urllib.request.Request(url, headers={"User-Agent": "waaiya-updater", "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=TIMEOUT, context=ctx) as r:
        data = r.read(limit + 1)
    if len(data) > limit:
        raise ValueError("response too large: " + url)
    return data


def _python_ok(spec):
    """Very small PEP 440 check for the requires_python forms PyPI shows ('>=3.10', '>=3.9,<4')."""
    if not spec:
        return True
    have = sys.version_info[:3]
    for part in spec.split(","):
        m = re.match(r"\s*(>=|<=|>|<|==|!=)\s*([\d.]+)", part)
        if not m:
            continue
        op, v = m.group(1), _vt(m.group(2))
        cur = have[:len(v)]
        ok = {">=": cur >= v, "<=": cur <= v, ">": cur > v, "<": cur < v, "==": cur == v, "!=": cur != v}[op]
        if not ok:
            return False
    return True


def _wheel(meta):
    """The pure-Python wheel of a PyPI JSON release, or None."""
    for u in meta.get("urls") or []:
        name = u.get("filename", "")
        if (u.get("packagetype") == "bdist_wheel" and name.endswith("-py3-none-any.whl")
                and u.get("url", "").startswith(FILES_HOST) and (u.get("digests") or {}).get("sha256")
                and not u.get("yanked")):
            return u
    return None


def _fetch_wheel(u, dest_dir):
    data = _get(u["url"], MAX_WHEEL)
    if hashlib.sha256(data).hexdigest() != u["digests"]["sha256"]:
        raise ValueError("sha256 mismatch: " + u["filename"])
    path = os.path.join(dest_dir, u["filename"])
    with open(path, "wb") as f:
        f.write(data)
    return path


def _extract(wheel, dest):
    """Extract only the yt_dlp / yt_dlp_ejs packages, refusing absolute or escaping paths. Returns METADATA."""
    metadata = ""
    with zipfile.ZipFile(wheel) as z:
        for info in z.infolist():
            name = info.filename
            norm = os.path.normpath(name)
            if os.path.isabs(name) or norm.startswith(".."):
                raise ValueError("bad path in wheel: " + name)
            top = norm.split(os.sep)[0]
            if top.endswith(".dist-info") and norm.endswith("METADATA"):
                metadata = z.read(info).decode("utf-8", "replace")
            if top in PACKAGES and not info.is_dir():
                z.extract(info, dest)
    return metadata


def _due(files_dir, every_s):
    stamp = os.path.join(_root(files_dir), "last_check")
    try:
        if time.time() - os.path.getmtime(stamp) < every_s:
            return False
    except OSError:
        pass
    os.makedirs(_root(files_dir), exist_ok=True)
    with open(stamp, "w") as f:
        f.write(str(int(time.time())))
    return True


def download(files_dir, bundled, prerelease=False, every_s=20 * 3600):
    """If PyPI has a yt-dlp newer than the one in use, download and unpack it next to the current copy.
    Returns the staged directory name, or None (nothing newer, not due yet, or any failure).
    prerelease=True also takes yt-dlp's nightly builds, which follow site changes within a day."""
    if not _due(files_dir, every_s):
        return None
    staged = None
    try:
        current = active_version(bundled)
        meta = json.loads(_get(PYPI.format("yt-dlp"), 8 << 20))
        candidates = [meta["info"]["version"]]  # latest stable
        if prerelease:
            candidates += [v for v, files in meta.get("releases", {}).items() if files]
        version = max(candidates, key=_vt)
        if _vt(version) <= _vt(current) or _vt(version) <= _vt(bundled):
            return None
        rel = meta if version == meta["info"]["version"] else json.loads(_get(PYPI_VERSION.format("yt-dlp", version)))
        if not _python_ok(rel["info"].get("requires_python")):
            return None
        u = _wheel(rel)
        if not u:
            return None
        root = _root(files_dir)
        staged = re.sub(r"[^\w.]", "_", version)
        dest = os.path.join(root, staged)
        shutil.rmtree(dest, ignore_errors=True)
        os.makedirs(dest)
        meta_txt = _extract(_fetch_wheel(u, root), dest)
        # The EJS scripts (YouTube's JavaScript challenge) must be the exact version this yt-dlp pins.
        m = re.search(r"^Requires-Dist:\s*yt-dlp-ejs\s*\(?==\s*([\w.]+)", meta_txt, re.M)
        if m:
            ejs = json.loads(_get(PYPI_VERSION.format("yt-dlp-ejs", m.group(1))))
            w = _wheel(ejs)
            if not w:
                raise ValueError("no yt-dlp-ejs wheel " + m.group(1))
            _extract(_fetch_wheel(w, root), dest)
        for f in os.listdir(root):
            if f.endswith(".whl"):
                os.remove(os.path.join(root, f))
        with open(os.path.join(dest, "VERSION"), "w") as f:
            f.write(version)
        return staged
    except Exception:
        if staged:
            shutil.rmtree(os.path.join(_root(files_dir), staged), ignore_errors=True)
        return None


def install(files_dir, staged, bundled):
    """Switch to the staged copy if it imports and reports its version; otherwise go back to the copy in use.
    Call only while no link is being opened. Returns the yt-dlp version now in use."""
    path = os.path.join(_root(files_dir), staged)
    try:
        with open(os.path.join(path, "VERSION")) as f:
            version = f.read().strip()
    except OSError:
        return active_version(bundled)
    previous, previous_version = _active_dir, _active_version
    _use(path, version)
    if _import_check(version):  # also dropped the old im_links: the next call imports it bound to this yt_dlp
        _write_state(files_dir, {"version": version, "dir": staged, "installed": int(time.time())})
        _forget(files_dir, keep=staged)
        return version
    shutil.rmtree(path, ignore_errors=True)
    _use(previous, previous_version)
    _import_check(previous_version or bundled)
    return active_version(bundled)
