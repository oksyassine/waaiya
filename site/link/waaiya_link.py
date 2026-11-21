"""Waaiya's "try a link" fetcher: a page link (YouTube, TikTok, ...) -> up to 60 s of its sound as a small mono M4A.

The landing page filters that sound in the visitor's browser (the same model as the app); this only fetches it.
Used by the same code on every server in the chain (site/link/README.md): o2switch through link.php, oracle-trial
and mhost through server.py in a locked-down container.

    python waaiya_link.py <link> <out.m4a>      prints one line of JSON: {"ok": true, ...} or {"ok": false, "error": code}

Error codes. The page stops at once on: invalid_url, unsupported_site, playlist, live, no_format.
It tries the next server on: bot, limited, login, timeout, failed (this server's address may be the problem).

Hostile input runs here, so: only links to the sites below, yt-dlp's generic extractor off (no arbitrary pages),
no shell anywhere, ffmpeg limited to https, hard time limits, and nothing is kept after the answer.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from urllib.parse import urlparse

LENGTH = 60          # seconds of sound sent back
FETCH_TIMEOUT = 40   # ffmpeg's limit; yt-dlp has its own socket timeout
SITES = ("youtube.com", "youtu.be", "youtube-nocookie.com", "tiktok.com", "facebook.com", "fb.watch",
         "instagram.com", "x.com", "twitter.com", "soundcloud.com", "dailymotion.com", "dai.ly", "vimeo.com",
         "archive.org", "rumble.com", "twitch.tv", "bilibili.com", "ok.ru", "vk.com", "streamable.com")
HERE = os.path.dirname(os.path.abspath(__file__))


class Fail(Exception):
    pass


def site_of(url):
    try:
        p = urlparse(url.strip())
    except ValueError:
        raise Fail("invalid_url")
    host = (p.hostname or "").lower().rstrip(".")
    if p.scheme not in ("http", "https") or not host or p.username or p.password or (p.port not in (None, 80, 443)):
        raise Fail("invalid_url")
    if p.path.rstrip("/").endswith("/playlist") or "/sets/" in p.path:  # a whole playlist / SoundCloud set
        raise Fail("playlist")
    for s in SITES:
        if host == s or host.endswith("." + s):
            return s
    raise Fail("unsupported_site")


def classify(msg):
    low = msg.lower()
    if "not a bot" in low or "confirm you" in low:
        return "bot"
    if "rate-limit" in low or "rate limit" in low or "too many requests" in low or "429" in low:
        return "limited"
    if "unsupported url" in low:
        return "unsupported_site"
    if "live event" in low or "is live" in low or "premieres in" in low:
        return "live"
    if "login" in low or "log in" in low or "logged-in" in low or "sign in" in low or "cookies" in low or "private" in low:
        return "login"
    return "failed"


def qjs_path():
    for p in (os.environ.get("WAAIYA_QJS"), os.path.join(HERE, "qjs"), shutil.which("qjs")):
        if p and os.path.exists(p):
            return p
    return None


def resolve(url):
    import yt_dlp
    cache = tempfile.mkdtemp(prefix="wl-")
    opts = {"quiet": True, "no_warnings": True, "noplaylist": True, "skip_download": True, "socket_timeout": 15,
            "extract_flat": "in_playlist", "playlistend": 1,  # a playlist link is refused, never walked
            "allowed_extractors": ["default", "-generic"], "cachedir": False, "remote_components": set()}
    q = qjs_path()
    if q:
        opts["js_runtimes"] = {"quickjs": {"path": q}}
    tempfile.tempdir = cache  # QuickJS reads YouTube's challenge scripts from temporary files
    try:
        y = yt_dlp.YoutubeDL(opts)
        try:
            info = y.extract_info(url.strip(), download=False)
        except Exception as e:  # DownloadError and extractor bugs alike
            raise Fail(classify(str(e)))
        if info.get("_type") == "playlist" or info.get("entries") is not None:
            raise Fail("playlist")
        if info.get("is_live") or info.get("live_status") in ("is_live", "is_upcoming"):
            raise Fail("live")
        fmt = pick(info)
        headers = dict(fmt.get("http_headers") or {})
        cookie = y.cookiejar.get_cookie_header(fmt["url"])  # TikTok serves media only to the session that opened the page
        if cookie:
            headers["Cookie"] = cookie
        return info, fmt, headers
    finally:
        tempfile.tempdir = None
        shutil.rmtree(cache, ignore_errors=True)


def pick(info):
    """Audio only if there is any (lowest bitrate from 48 kb/s up: enough for a 96 kb/s mono result, quickest to
    fetch), else the smallest file that has sound. Only plain https downloads or HLS."""
    fs = [f for f in (info.get("formats") or [info]) if f.get("url") and str(f.get("url")).startswith("https://")
          and (f.get("protocol") or "https") in ("https", "m3u8", "m3u8_native") and "drc" not in str(f.get("format_id"))]
    sound = [f for f in fs if f.get("acodec") not in ("none",)]
    if not sound:
        raise Fail("no_format")
    plain = [f for f in sound if (f.get("protocol") or "https") == "https"]
    sound = plain or sound  # a plain file first: downloaded here, ffmpeg stays off the network
    only = [f for f in sound if f.get("vcodec") in ("none",)]
    if only:
        rate = lambda f: f.get("abr") or f.get("tbr") or 0
        ok = [f for f in only if rate(f) >= 48]
        return min(ok, key=rate) if ok else max(only, key=rate)
    size = lambda f: f.get("filesize") or f.get("filesize_approx") or (f.get("tbr") or 1e9)
    return min(sound, key=size)


MAX_BYTES = 64 << 20  # never download more than this for one answer


def download(fmt, headers, need, path, deadline):
    """The first [need] bytes of a plain https file (all of it if smaller). Done here, not by ffmpeg: the static
    ffmpeg on shared hosting resolves names very slowly, and a local file keeps ffmpeg off the network entirely."""
    import urllib.request
    h = dict(headers)
    h["Range"] = f"bytes=0-{need - 1}"
    req = urllib.request.Request(fmt["url"], headers=h)
    try:
        with urllib.request.urlopen(req, timeout=15) as r, open(path, "wb") as f:
            got = 0
            while got < need:
                if time.time() > deadline:
                    raise Fail("timeout")
                chunk = r.read(1 << 16)
                if not chunk:
                    break
                f.write(chunk)
                got += len(chunk)
    except Fail:
        raise
    except Exception as e:
        code = getattr(e, "code", 0)
        raise Fail("limited" if code in (403, 429) else "failed")


def fetch(info, fmt, headers, out):
    t0 = time.time()
    dur = info.get("duration") or 0
    start = float(info.get("start_time") or 0)
    if dur and start >= dur - 5:
        start = 0.0
    ff = os.environ.get("WAAIYA_FFMPEG") or shutil.which("ffmpeg") or os.path.expanduser("~/bin/ffmpeg")
    work = tempfile.mkdtemp(prefix="wl-")
    try:
        cmd = [ff, "-nostdin", "-hide_banner", "-loglevel", "error"]
        if (fmt.get("protocol") or "https") == "https":
            size = fmt.get("filesize") or fmt.get("filesize_approx") or 0
            rate = fmt.get("abr") or fmt.get("tbr") or ((size * 8 / 1000 / dur) if size and dur else 0)
            need = int((start + LENGTH + 10) * rate * 1000 / 8 * 1.2) + (512 << 10) if rate else MAX_BYTES
            if need > MAX_BYTES:  # a start time far into a long video: take its first minute instead
                start, need = 0.0, int((LENGTH + 10) * rate * 1000 / 8 * 1.2) + (512 << 10)
            if size:
                need = min(need, size)
            src = os.path.join(work, "in")
            download(fmt, headers, min(need, MAX_BYTES), src, t0 + FETCH_TIMEOUT)
            cmd += ["-protocol_whitelist", "file"]
        else:  # HLS: ffmpeg fetches the pieces itself, https only
            hdr = "".join(f"{k}: {v}\r\n" for k, v in headers.items() if k.lower() != "user-agent")
            cmd += ["-protocol_whitelist", "https,tls,tcp,crypto", "-rw_timeout", "15000000"]
            if headers.get("User-Agent"):
                cmd += ["-user_agent", headers["User-Agent"]]
            if hdr:
                cmd += ["-headers", hdr]
            src = fmt["url"]
        if start:
            cmd += ["-ss", f"{start:.2f}"]
        cmd += ["-i", src, "-t", str(LENGTH), "-vn", "-sn", "-dn", "-ac", "1", "-ar", "48000",
                "-c:a", "aac", "-b:a", "96k", "-movflags", "+faststart", "-f", "mp4", "-y", out]
        try:
            r = subprocess.run(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
                               timeout=max(5, t0 + FETCH_TIMEOUT - time.time()))
        except subprocess.TimeoutExpired:
            raise Fail("timeout")
        if r.returncode != 0 or not os.path.exists(out) or os.path.getsize(out) < 1000:
            err = r.stderr.decode("utf-8", "replace")
            raise Fail("limited" if "403" in err or "429" in err else "failed")
    finally:
        shutil.rmtree(work, ignore_errors=True)
    return start, min(LENGTH, max(0.0, dur - start)) if dur else LENGTH


def run(url, out):
    try:
        site = site_of(url)
        info, fmt, headers = resolve(url)
        start, length = fetch(info, fmt, headers, out)
        return {"ok": True, "site": site, "title": (info.get("title") or "")[:200], "start": start, "length": length}
    except Fail as e:
        return {"ok": False, "error": e.args[0]}
    except Exception:
        return {"ok": False, "error": "failed"}


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(json.dumps({"ok": False, "error": "invalid_url"}))
        sys.exit(2)
    res = run(sys.argv[1], sys.argv[2])
    if not res["ok"] and os.path.exists(sys.argv[2]):
        os.unlink(sys.argv[2])
    print(json.dumps(res, ensure_ascii=False))
