"""Host tests for im_update.py (the yt-dlp self-updater). Standard library only, no network.

Run from the repo root:  python3 android/app/src/test/python/test_im_update.py
"""
import hashlib
import io
import json
import os
import shutil
import sys
import tempfile
import time
import unittest
import urllib.error
import urllib.request
import zipfile
from datetime import datetime, timezone

sys.dont_write_bytecode = True  # no __pycache__ in the app's source tree
SRC = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "main", "python"))
sys.path.insert(0, SRC)
import im_update  # noqa: E402

ORIG_GET = im_update._get
ORIG_NOW = im_update._now
DAY = 86400
NOW = datetime(2026, 11, 12, 12, 0, 0, tzinfo=timezone.utc).timestamp()
INDEX = im_update.PYPI.format("yt-dlp")
EJS_VERSION = "0.3.1"
EJS_INDEX = im_update.PYPI_VERSION.format("yt-dlp-ejs", EJS_VERSION)


def iso(ts):
    return datetime.fromtimestamp(ts, timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")


def entry(project, version, uploaded, data=b"wheel", **over):
    """A PyPI JSON file entry for the pure-Python wheel of `project` `version`, uploaded at `uploaded`."""
    name = "{}-{}-py3-none-any.whl".format(project.replace("-", "_"), version)
    e = {
        "filename": name,
        "packagetype": "bdist_wheel",
        "url": im_update.FILES_HOST + "packages/ab/cd/" + name,
        "digests": {"sha256": hashlib.sha256(data).hexdigest()},
        "yanked": False,
        "requires_python": ">=3.10",
        "size": len(data),
        "upload_time": datetime.fromtimestamp(uploaded, timezone.utc).strftime("%Y-%m-%dT%H:%M:%S"),
        "upload_time_iso_8601": iso(uploaded),
    }
    e.update(over)
    return e


def sdist(project, version, uploaded):
    name = "{}-{}.tar.gz".format(project.replace("-", "_"), version)
    return {"filename": name, "packagetype": "sdist", "url": im_update.FILES_HOST + "packages/ab/cd/" + name,
            "digests": {"sha256": "0" * 64}, "yanked": False, "upload_time_iso_8601": iso(uploaded)}


def index(releases, latest=None):
    """Project JSON as https://pypi.org/pypi/<project>/json returns it."""
    stable = [v for v in releases if im_update._is_stable(v)]
    latest = latest or max(stable or releases, key=im_update._vt)
    return {"info": {"version": latest, "requires_python": ">=3.10"}, "urls": releases[latest], "releases": releases}


def ytdlp_wheel(version, ejs=EJS_VERSION):
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as z:
        z.writestr("yt_dlp/__init__.py", "from . import version\n")
        z.writestr("yt_dlp/version.py", "__version__ = {!r}\n".format(version))
        z.writestr("not_ours/evil.py", "raise SystemExit('must not be extracted')\n")
        meta = "Metadata-Version: 2.1\nName: yt-dlp\nVersion: {}\n".format(version)
        if ejs:
            meta += "Requires-Dist: yt-dlp-ejs==" + ejs + "\n"
        z.writestr("yt_dlp-{}.dist-info/METADATA".format(version), meta)
    return buf.getvalue()


def ejs_wheel():
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as z:
        z.writestr("yt_dlp_ejs/__init__.py", "")
        z.writestr("yt_dlp_ejs-{}.dist-info/METADATA".format(EJS_VERSION),
                   "Metadata-Version: 2.1\nName: yt-dlp-ejs\nVersion: {}\n".format(EJS_VERSION))
    return buf.getvalue()


class FakePyPI:
    """Stands in for im_update._get: serves canned bytes by URL and records every URL asked for."""

    def __init__(self):
        self.routes = {}
        self.calls = []

    def json(self, url, obj):
        self.routes[url] = json.dumps(obj).encode()

    def __call__(self, url, limit=1 << 20):
        self.calls.append(url)
        r = self.routes.get(url)
        if r is None:
            raise urllib.error.URLError("no route in fake PyPI: " + url)
        if isinstance(r, BaseException):
            raise r
        if len(r) > limit:
            raise ValueError("response too large: " + url)
        return r


def purge_fake_modules():
    for name in list(sys.modules):
        if name.split(".")[0] in im_update.PACKAGES:
            del sys.modules[name]


class Base(unittest.TestCase):
    def setUp(self):
        self.now = NOW
        im_update._now = lambda: self.now
        self.pypi = FakePyPI()
        im_update._get = self.pypi
        self.files = tempfile.mkdtemp(prefix="im_update_test_")
        self.root = os.path.join(self.files, "ytdlp")

    def tearDown(self):
        im_update._get = ORIG_GET
        im_update._now = ORIG_NOW
        im_update._use(None)
        purge_fake_modules()
        sys.path[:] = [p for p in sys.path if not p.startswith(self.files)]
        shutil.rmtree(self.files, ignore_errors=True)

    def leftovers(self):
        """Everything under files_dir/ytdlp except the check stamps."""
        if not os.path.isdir(self.root):
            return []
        return sorted(n for n in os.listdir(self.root) if not n.startswith("last_check"))


class ChooseTests(Base):
    """The version choice itself (no download, so errors are not swallowed)."""

    def choose(self, releases, current="2026.10.26", bundled="2026.10.1", prerelease=False):
        return im_update._choose(index(releases), current, bundled, prerelease)

    def test_young_stable_skipped_older_eligible_chosen(self):
        rel = {
            "2026.11.10": [entry("yt-dlp", "2026.11.10", NOW - 1 * DAY)],
            "2026.11.5": [entry("yt-dlp", "2026.11.5", NOW - 7 * DAY)],
            "2026.11.1": [entry("yt-dlp", "2026.11.1", NOW - 11 * DAY)],
            "2026.10.26": [entry("yt-dlp", "2026.10.26", NOW - 17 * DAY)],
        }
        version, u = self.choose(rel)
        self.assertEqual(version, "2026.11.5")
        self.assertEqual(u["filename"], "yt_dlp-2026.11.5-py3-none-any.whl")

    def test_nothing_eligible(self):
        rel = {
            "2026.11.10": [entry("yt-dlp", "2026.11.10", NOW - 1 * DAY)],
            "2026.11.9": [entry("yt-dlp", "2026.11.9", NOW - 2 * DAY)],
            "2026.10.26": [entry("yt-dlp", "2026.10.26", NOW - 17 * DAY)],  # = current
        }
        self.assertIsNone(self.choose(rel))
        # Control: the same releases a day later.
        self.now = NOW + DAY
        self.assertEqual(self.choose(rel)[0], "2026.11.9")

    def test_age_boundaries(self):
        rel = {"2026.11.9": [entry("yt-dlp", "2026.11.9", NOW - im_update.MIN_AGE_STABLE)]}
        self.assertEqual(self.choose(rel)[0], "2026.11.9")
        rel = {"2026.11.9": [entry("yt-dlp", "2026.11.9", NOW - im_update.MIN_AGE_STABLE + 1)]}
        self.assertIsNone(self.choose(rel))
        n = "2026.11.11.232659.dev0"
        rel = {n: [entry("yt-dlp", n, NOW - im_update.MIN_AGE_PRE)]}
        self.assertEqual(self.choose(rel, prerelease=True)[0], n)
        rel = {n: [entry("yt-dlp", n, NOW - im_update.MIN_AGE_PRE + 1)]}
        self.assertIsNone(self.choose(rel, prerelease=True))

    def test_constants(self):
        self.assertEqual(im_update.MIN_AGE_STABLE, 3 * DAY)
        self.assertEqual(im_update.MIN_AGE_PRE, 1 * DAY)

    def test_missing_or_bad_upload_time_rejected(self):
        old = NOW - 30 * DAY
        for bad in ({"upload_time": None, "upload_time_iso_8601": None},
                    {"upload_time": "", "upload_time_iso_8601": ""},
                    {"upload_time": "garbage", "upload_time_iso_8601": "not a date"},
                    {"upload_time": 12345, "upload_time_iso_8601": 12345}):
            e = entry("yt-dlp", "2026.11.5", old)
            e.update(bad)
            with self.subTest(bad=bad):
                self.assertIsNone(self.choose({"2026.11.5": [e]}))
                # An older release with a good time is still taken.
                rel = {"2026.11.5": [e], "2026.11.1": [entry("yt-dlp", "2026.11.1", old)]}
                self.assertEqual(self.choose(rel)[0], "2026.11.1")
        e = entry("yt-dlp", "2026.11.5", old)
        del e["upload_time"], e["upload_time_iso_8601"]
        self.assertIsNone(self.choose({"2026.11.5": [e]}))
        # A garbled ISO time is not rescued by the plain one.
        e = entry("yt-dlp", "2026.11.5", old, upload_time_iso_8601="garbage")
        self.assertIsNone(self.choose({"2026.11.5": [e]}))

    def test_only_one_upload_field_is_enough(self):
        e = entry("yt-dlp", "2026.11.5", NOW - 5 * DAY)
        del e["upload_time_iso_8601"]
        self.assertEqual(self.choose({"2026.11.5": [e]})[0], "2026.11.5")

    def test_upload_time_without_offset_is_utc(self):
        want = datetime(2026, 11, 1, tzinfo=timezone.utc).timestamp()
        old_tz = os.environ.get("TZ")
        if hasattr(time, "tzset"):  # a phone far from UTC must read PyPI's offset-less time as UTC too
            os.environ["TZ"] = "Asia/Riyadh"
            time.tzset()
        try:
            self.assertEqual(im_update._uploaded({"upload_time": "2026-11-01T00:00:00"}), want)
            self.assertEqual(im_update._uploaded({"upload_time_iso_8601": "2026-11-01T00:00:00.000000Z"}), want)
        finally:
            if hasattr(time, "tzset"):
                if old_tz is None:
                    os.environ.pop("TZ", None)
                else:
                    os.environ["TZ"] = old_tz
                time.tzset()

    def test_future_upload_time_rejected(self):
        self.assertIsNone(self.choose({"2026.11.5": [entry("yt-dlp", "2026.11.5", NOW + 5 * DAY)]}))

    def test_nightly_ignored_by_default(self):
        n = "2026.11.8.232659.dev0"
        rel = {
            n: [entry("yt-dlp", n, NOW - 4 * DAY)],
            "2026.11.5": [entry("yt-dlp", "2026.11.5", NOW - 7 * DAY)],
        }
        self.assertEqual(self.choose(rel)[0], "2026.11.5")
        self.assertIsNone(self.choose({n: rel[n]}))
        self.assertIsNone(self.choose({"2026.11.8rc1": [entry("yt-dlp", "2026.11.8rc1", NOW - 9 * DAY)]}))

    def test_nightly_taken_on_prerelease_only_when_old_enough(self):
        young, aged = "2026.11.11.232659.dev0", "2026.11.10.101010.dev0"
        rel = {
            young: [entry("yt-dlp", young, NOW - 12 * 3600)],
            aged: [entry("yt-dlp", aged, NOW - 36 * 3600)],
            "2026.11.5": [entry("yt-dlp", "2026.11.5", NOW - 7 * DAY)],
        }
        self.assertEqual(self.choose(rel, prerelease=True)[0], aged)
        self.assertEqual(self.choose(rel, prerelease=False)[0], "2026.11.5")
        # Only young nightlies: the stable one is taken, and a too-young stable one never.
        rel = {young: rel[young], "2026.11.11": [entry("yt-dlp", "2026.11.11", NOW - 2 * DAY)],
               "2026.11.5": rel["2026.11.5"]}
        self.assertEqual(self.choose(rel, prerelease=True)[0], "2026.11.5")

    def test_prerelease_still_takes_newer_old_stable(self):
        n = "2026.11.3.232659.dev0"
        rel = {n: [entry("yt-dlp", n, NOW - 9 * DAY)], "2026.11.5": [entry("yt-dlp", "2026.11.5", NOW - 7 * DAY)]}
        self.assertEqual(self.choose(rel, prerelease=True)[0], "2026.11.5")

    def test_not_newer_than_current_or_bundled(self):
        rel = {"2026.11.5": [entry("yt-dlp", "2026.11.5", NOW - 7 * DAY)]}
        self.assertIsNone(self.choose(rel, current="2026.11.5", bundled="2026.10.1"))
        self.assertIsNone(self.choose(rel, current="2026.10.1", bundled="2026.11.5"))
        self.assertIsNone(self.choose(rel, current="2026.11.6", bundled="2026.10.1"))
        # A nightly in use ('2026.11.04.232659', yt-dlp's own spelling) is newer than the stable of that day.
        rel = {"2026.11.4": [entry("yt-dlp", "2026.11.4", NOW - 8 * DAY)]}
        self.assertIsNone(self.choose(rel, current="2026.11.04.232659", prerelease=True))
        self.assertEqual(self.choose(rel, current="2026.10.26")[0], "2026.11.4")

    def test_unusable_files_ignored(self):
        old = NOW - 9 * DAY
        cases = {
            "yanked": [entry("yt-dlp", "2026.11.5", old, yanked=True)],
            "sdist only": [sdist("yt-dlp", "2026.11.5", old)],
            "other host": [entry("yt-dlp", "2026.11.5", old, url="https://example.org/yt_dlp.whl")],
            "no sha256": [entry("yt-dlp", "2026.11.5", old, digests={})],
            "binary wheel": [entry("yt-dlp", "2026.11.5", old,
                                   filename="yt_dlp-2026.11.5-cp311-cp311-manylinux_x86_64.whl")],
            "python too new": [entry("yt-dlp", "2026.11.5", old, requires_python=">=9.0")],
        }
        for why, files in cases.items():
            with self.subTest(why=why):
                self.assertIsNone(self.choose({"2026.11.5": files}))
        # Control: the sdist is skipped and the wheel next to it is taken.
        files = [sdist("yt-dlp", "2026.11.5", old), entry("yt-dlp", "2026.11.5", old)]
        self.assertEqual(self.choose({"2026.11.5": files})[0], "2026.11.5")

    def test_without_releases_key_only_latest_is_considered(self):
        meta = index({"2026.11.5": [entry("yt-dlp", "2026.11.5", NOW - 7 * DAY)]})
        del meta["releases"]
        self.assertEqual(im_update._choose(meta, "2026.10.26", "2026.10.1")[0], "2026.11.5")
        meta["urls"] = [entry("yt-dlp", "2026.11.5", NOW - DAY)]
        self.assertIsNone(im_update._choose(meta, "2026.10.26", "2026.10.1"))


class DownloadTests(Base):
    """download() and install() against a fake PyPI and real wheel bytes."""

    def serve(self, versions, ejs_age=10 * DAY, ejs_data=None):
        """versions: {version: age_seconds}. Serves the project index, each wheel, and the pinned EJS wheel."""
        rel, self.wheels = {}, {}
        for v, age in versions.items():
            data = ytdlp_wheel(v)
            e = entry("yt-dlp", v, NOW - age, data)
            rel[v] = [sdist("yt-dlp", v, NOW - age), e]
            self.pypi.routes[e["url"]] = data
            self.wheels[v] = e["url"]
        self.pypi.json(INDEX, index(rel))
        ejs = ejs_wheel()
        e = entry("yt-dlp-ejs", EJS_VERSION, NOW - ejs_age, ejs)
        self.pypi.json(EJS_INDEX, {"info": {"version": EJS_VERSION}, "urls": [e]})
        self.pypi.routes[e["url"]] = ejs if ejs_data is None else ejs_data
        self.ejs_url = e["url"]

    def download(self, prerelease=False, current="2026.10.26"):
        return im_update.download(self.files, current, prerelease, every_s=0)

    def test_full_download_and_install(self):
        self.serve({"2026.11.10": 1 * DAY, "2026.11.5": 7 * DAY, "2026.10.26": 17 * DAY})
        staged = self.download()
        self.assertEqual(staged, "2026.11.5")
        self.assertEqual(self.pypi.calls, [INDEX, self.wheels["2026.11.5"], EJS_INDEX, self.ejs_url])
        dest = os.path.join(self.root, staged)
        self.assertTrue(os.path.isfile(os.path.join(dest, "yt_dlp", "version.py")))
        self.assertTrue(os.path.isfile(os.path.join(dest, "yt_dlp_ejs", "__init__.py")))
        self.assertFalse(os.path.exists(os.path.join(dest, "not_ours")))
        self.assertEqual(sorted(os.listdir(dest)), ["VERSION", "yt_dlp", "yt_dlp_ejs"])
        self.assertEqual(self.leftovers(), [staged])  # no .whl left behind
        self.assertEqual(im_update.install(self.files, staged, "2026.10.26"), "2026.11.5")
        self.assertEqual(im_update.active_version("2026.10.26"), "2026.11.5")
        self.assertEqual(sys.modules["yt_dlp"].version.__version__, "2026.11.5")
        self.assertEqual(sorted(self.leftovers()), ["2026.11.5", "current.json"])

    def test_nothing_eligible_returns_none(self):
        self.serve({"2026.11.10": 1 * DAY, "2026.11.9": 2 * DAY})
        self.assertIsNone(self.download())
        self.assertEqual(self.pypi.calls, [INDEX])
        self.assertEqual(self.leftovers(), [])

    def test_nightly_path(self):
        n = "2026.11.10.232659.dev0"
        self.serve({n: 2 * DAY, "2026.11.10": 2 * DAY}, ejs_age=2 * DAY)
        self.assertIsNone(self.download(prerelease=False))  # stable too young, nightly not wanted
        self.assertEqual(self.pypi.calls, [INDEX])
        self.pypi.calls.clear()
        self.assertEqual(self.download(prerelease=True), "2026.11.10.232659.dev0")
        self.assertEqual(self.pypi.calls, [INDEX, self.wheels[n], EJS_INDEX, self.ejs_url])

    def test_young_nightly_not_taken_after_failure(self):
        n = "2026.11.12.010101.dev0"
        self.serve({n: 6 * 3600})
        self.assertIsNone(self.download(prerelease=True))
        self.assertEqual(self.pypi.calls, [INDEX])

    def test_not_newer_returns_none(self):
        self.serve({"2026.11.5": 7 * DAY})
        self.assertIsNone(self.download(current="2026.11.5"))
        self.assertEqual(self.pypi.calls, [INDEX])
        self.assertEqual(self.leftovers(), [])

    def test_offline_index(self):
        for err in (urllib.error.URLError("offline"), OSError("network unreachable"), TimeoutError("timed out")):
            with self.subTest(err=err):
                self.pypi.routes[INDEX] = err
                self.pypi.calls.clear()
                self.assertIsNone(self.download())
                self.assertEqual(self.pypi.calls, [INDEX])
                self.assertEqual(self.leftovers(), [])

    def test_offline_during_wheel(self):
        self.serve({"2026.11.5": 7 * DAY})
        self.pypi.routes[self.wheels["2026.11.5"]] = OSError("connection reset")
        self.assertIsNone(self.download())
        self.assertEqual(self.pypi.calls, [INDEX, self.wheels["2026.11.5"]])
        self.assertEqual(self.leftovers(), [])

    def test_offline_during_ejs_leaves_nothing(self):
        # The yt-dlp wheel is already on disk when the EJS fetch fails: it must not stay behind.
        self.serve({"2026.11.5": 7 * DAY})
        self.pypi.routes[self.ejs_url] = urllib.error.URLError("offline")
        self.assertIsNone(self.download())
        self.assertEqual(self.pypi.calls, [INDEX, self.wheels["2026.11.5"], EJS_INDEX, self.ejs_url])
        self.assertEqual(self.leftovers(), [])

    def test_sha256_mismatch(self):
        self.serve({"2026.11.5": 7 * DAY})
        self.pypi.routes[self.wheels["2026.11.5"]] = ytdlp_wheel("2026.11.5") + b"tampered"
        self.assertIsNone(self.download())
        self.assertEqual(self.pypi.calls, [INDEX, self.wheels["2026.11.5"]])
        self.assertEqual(self.leftovers(), [])

    def test_ejs_sha256_mismatch(self):
        self.serve({"2026.11.5": 7 * DAY}, ejs_data=b"tampered")
        self.assertIsNone(self.download())
        self.assertEqual(self.pypi.calls[-1], self.ejs_url)
        self.assertEqual(self.leftovers(), [])

    def test_ejs_too_young(self):
        self.serve({"2026.11.5": 7 * DAY}, ejs_age=2 * DAY)
        self.assertIsNone(self.download())
        self.assertEqual(self.pypi.calls, [INDEX, self.wheels["2026.11.5"], EJS_INDEX])  # EJS wheel never fetched
        self.assertEqual(self.leftovers(), [])

    def test_ejs_missing_upload_time(self):
        self.serve({"2026.11.5": 7 * DAY})
        meta = json.loads(self.pypi.routes[EJS_INDEX])
        del meta["urls"][0]["upload_time"], meta["urls"][0]["upload_time_iso_8601"]
        self.pypi.json(EJS_INDEX, meta)
        self.assertIsNone(self.download())
        self.assertNotIn(self.ejs_url, self.pypi.calls)
        self.assertEqual(self.leftovers(), [])

    def test_bad_wheel_path_rejected(self):
        self.serve({"2026.11.5": 7 * DAY})
        buf = io.BytesIO()
        with zipfile.ZipFile(buf, "w") as z:
            z.writestr("../yt_dlp/__init__.py", "")
        data = buf.getvalue()
        e = entry("yt-dlp", "2026.11.5", NOW - 7 * DAY, data)
        self.pypi.json(INDEX, index({"2026.11.5": [e]}))
        self.pypi.routes[e["url"]] = data
        self.assertIsNone(self.download())
        self.assertEqual(self.pypi.calls, [INDEX, e["url"]])
        self.assertEqual(self.leftovers(), [])
        self.assertFalse(os.path.exists(os.path.join(self.files, "yt_dlp")))


class UserAgentTest(unittest.TestCase):
    def test_request_does_not_name_the_app(self):
        seen = []

        class Resp(io.BytesIO):
            def __enter__(self):
                return self

            def __exit__(self, *a):
                return False

        def fake_urlopen(req, *a, **kw):
            seen.append(req)
            return Resp(b"{}")

        real = urllib.request.urlopen
        urllib.request.urlopen = fake_urlopen
        try:
            self.assertEqual(ORIG_GET(INDEX), b"{}")
        finally:
            urllib.request.urlopen = real
        self.assertEqual(len(seen), 1)
        req = seen[0]
        if isinstance(req, str):
            return  # a bare URL carries no headers of ours
        self.assertEqual(req.full_url, INDEX)
        headers = dict(req.header_items())
        # No User-Agent set: urllib's opener then sends its default 'Python-urllib/3.x'.
        self.assertIsNone(req.get_header("User-agent"))
        for k, v in headers.items():
            self.assertNotIn("waaiya", (k + v).lower())
        default = dict(urllib.request.build_opener().addheaders).get("User-agent", "")
        self.assertTrue(default.startswith("Python-urllib/"), default)


if __name__ == "__main__":
    unittest.main(verbosity=2)
