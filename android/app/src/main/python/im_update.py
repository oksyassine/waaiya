"""Keeps the app's yt-dlp current without a new APK.

Sites change often and yt-dlp follows them within days, so the copy bundled in the APK goes stale. This module
downloads a newer yt-dlp wheel (and the yt-dlp-ejs version it pins) from PyPI into the app's private files and
puts it in front of the bundled copy on sys.path.

Safety:
- Only PyPI over HTTPS, only pure-Python wheels (py3-none-any) hosted on files.pythonhosted.org, checked
  against the SHA-256 that PyPI publishes; size capped; zip paths checked; only the yt_dlp / yt_dlp_ejs packages
  are extracted. The trust is the same as `pip install -U yt-dlp`.
- A release is taken only once it has been on PyPI for a while (its wheel's upload time): 3 days for a stable
  release, 1 day for a nightly. A bad or hijacked upload is usually found and yanked within that time. The newest
  release that is old enough is taken, so a fresh release only delays the update, it does not block it.
- Stable releases only, except after a link failed (prerelease=True): then yt-dlp's nightly builds are also taken,
  with their own 1-day wait.
- Requests carry no app name: urllib's default User-Agent, the same as any Python script.
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
from datetime import datetime, timezone

PYPI = "https://pypi.org/pypi/{}/json"
PYPI_VERSION = "https://pypi.org/pypi/{}/{}/json"
FILES_HOST = "https://files.pythonhosted.org/"
MAX_WHEEL = 16 << 20
TIMEOUT = 20
PACKAGES = ("yt_dlp", "yt_dlp_ejs")
MIN_AGE_STABLE = 3 * 86400  # seconds a stable release must have been on PyPI before it is taken
MIN_AGE_PRE = 1 * 86400  # the same for a nightly (only taken after a link failed)

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


def _now():
    """The clock for the release-age rule (tests replace it)."""
    return time.time()


def _get(url, limit=1 << 20):
    ctx = ssl.create_default_context()
    # No User-Agent of our own: urllib then sends its default ('Python-urllib/3.x'), the same as countless scripts
    # and tools, so PyPI cannot tell these requests come from this app. A browser or pip User-Agent would be a lie
    # about the client, and an app name would mark every user of the app in PyPI's and the CDN's logs.
    req = urllib.request.Request(url)
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
    return _wheel_in(meta.get("urls"))


def _wheel_in(files):
    """The pure-Python wheel among a release's file entries, or None."""
    for u in files or []:
        name = u.get("filename", "")
        if (u.get("packagetype") == "bdist_wheel" and name.endswith("-py3-none-any.whl")
                and u.get("url", "").startswith(FILES_HOST) and (u.get("digests") or {}).get("sha256")
                and not u.get("yanked")):
            return u
    return None


def _is_stable(version):
    """True for a final release ('2026.10.26'); False for nightlies ('2026.11.4.232659.dev0') and any other
    pre-release or unusual version (rc, alpha, post...)."""
    return re.fullmatch(r"\d+(\.\d+)*", str(version or "")) is not None


def _uploaded(u):
    """Upload time (Unix seconds, UTC) of a PyPI file entry, or None if missing or unparseable. 'upload_time' is
    read only when 'upload_time_iso_8601' is absent: a garbled ISO time rejects the file."""
    t = u.get("upload_time_iso_8601")
    if t is None:
        t = u.get("upload_time")
    if not isinstance(t, str) or not t:
        return None
    try:
        d = datetime.fromisoformat(t.strip().replace("Z", "+00:00"))
    except ValueError:
        return None
    if d.tzinfo is None:
        d = d.replace(tzinfo=timezone.utc)  # PyPI's 'upload_time' is UTC without an offset
    return d.timestamp()


def _old_enough(u, min_age):
    """True if the file entry `u` has been on PyPI for at least `min_age` seconds. A missing, unparseable or
    future upload time fails."""
    t = _uploaded(u)
    if t is None:
        return False
    age = _now() - t
    return 0 <= age and age >= min_age


def _min_age(version):
    return MIN_AGE_STABLE if _is_stable(version) else MIN_AGE_PRE


def _choose(meta, current, bundled, prerelease=False):
    """The yt-dlp release to take from the project's PyPI JSON: the newest one that is newer than both `current`
    and `bundled`, stable (or also a pre-release when `prerelease`), with a usable wheel for this Python that has
    been on PyPI long enough. Returns (version, wheel file entry) or None. The age is judged on the very file entry
    that is then downloaded."""
    releases = meta.get("releases")
    if not isinstance(releases, dict):  # PyPI has dropped 'releases' from some JSON views: use the latest only
        latest = (meta.get("info") or {}).get("version")
        releases = {latest: meta.get("urls") or []} if latest else {}
    floor = max(_vt(current), _vt(bundled))
    for version in sorted(releases, key=_vt, reverse=True):
        if _vt(version) <= floor:
            break
        if not (_is_stable(version) or prerelease):
            continue
        u = _wheel_in(releases[version])
        if not u or not _python_ok(u.get("requires_python")):
            continue
        if _old_enough(u, _min_age(version)):
            return version, u
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


def _due(files_dir, every_s, name="last_check"):
    # Real clock on purpose (not _now()): it is compared with a file's mtime, which the file system sets.
    stamp = os.path.join(_root(files_dir), name)
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
    Only a release that has been on PyPI for MIN_AGE_STABLE (nightly: MIN_AGE_PRE) is taken; the newest such one.
    prerelease=True also takes yt-dlp's nightly builds, which follow site changes within a day."""
    # The check after a failed link has its own stamp: the daily check, made when the link screen opens, must
    # not block it for an hour.
    if not _due(files_dir, every_s, "last_check_nightly" if prerelease else "last_check"):
        return None
    staged = None
    root = _root(files_dir)
    try:
        current = active_version(bundled)
        meta = json.loads(_get(PYPI.format("yt-dlp"), 8 << 20))
        chosen = _choose(meta, current, bundled, prerelease)
        if not chosen:
            return None
        version, u = chosen
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
            # Same wait as the yt-dlp release that pins it: yt-dlp publishes the EJS version it needs together with
            # (or just before) the release, so a 3-day rule here would hold back a 1-day-old nightly for two more
            # days on exactly the path meant to fix a broken link. The pin is exact, so the EJS wheel is as
            # trusted as the yt-dlp release that names it.
            if not _old_enough(w, _min_age(version)):
                raise ValueError("yt-dlp-ejs too new: " + m.group(1))
            _extract(_fetch_wheel(w, root), dest)
        with open(os.path.join(dest, "VERSION"), "w") as f:
            f.write(version)
        return staged
    except Exception:
        if staged:
            shutil.rmtree(os.path.join(root, staged), ignore_errors=True)
            staged = None
        return None
    finally:
        try:
            for f in os.listdir(root):
                if f.endswith(".whl"):
                    os.remove(os.path.join(root, f))
        except OSError:
            pass


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
