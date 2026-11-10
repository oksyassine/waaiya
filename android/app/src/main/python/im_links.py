"""Link feature: turns a page link (YouTube, TikTok, ...) into the media streams Waaiya can filter.

Runs inside the app through Chaquopy. Only yt-dlp's Python API is used (no shell, no config files, no plugins).
yt-dlp itself may be a newer copy downloaded by im_update.py (checked against PyPI's hashes). YouTube's JavaScript challenge is solved by the bundled yt-dlp-ejs scripts in QuickJS.
"""
import json
import os
import tempfile
from urllib.parse import urlparse

import yt_dlp

MAX_HEIGHT = 720  # enough for a phone screen; keeps downloads and processing light


class LinkError(Exception):
    """args[0] is a code the app turns into a translated message: invalid_url, login, limited, unsupported_site,
    playlist, no_format, failed (args[1] = detail)."""


def _http(f):
    p = f.get("protocol") or ""
    return p in ("http", "https") and f.get("url")


def _avc(f):
    return str(f.get("vcodec") or "").startswith(("avc", "h264"))


def _aac(f):
    return str(f.get("acodec") or "").startswith("mp4a") or (f.get("ext") == "m4a" and f.get("acodec") not in (None, "none"))


def _pick(info):
    fm = [f for f in (info.get("formats") or [info]) if _http(f) and "drc" not in str(f.get("format_id"))]
    has_v = lambda f: (f.get("vcodec") or "none") != "none"
    has_a = lambda f: (f.get("acodec") or "none") != "none"
    h = lambda f: f.get("height") or 0
    video = [f for f in fm if has_v(f) and not has_a(f) and _avc(f) and f.get("ext") == "mp4" and h(f) <= MAX_HEIGHT]
    audio = [f for f in fm if has_a(f) and not has_v(f) and _aac(f)]
    both = [f for f in fm if has_v(f) and has_a(f) and _avc(f) and f.get("ext") == "mp4" and h(f) <= MAX_HEIGHT]
    # Stereo/mono first (the voice model takes 1-2 channels; 5.1 tracks are refused, never passed through),
    # then the highest bitrate.
    br = lambda f: ((f.get("audio_channels") or 2) <= 2, f.get("abr") or f.get("tbr") or 0)
    if video and audio:
        return max(video, key=h), max(audio, key=br), None
    if both:
        return None, None, max(both, key=h)
    if audio:
        return None, max(audio, key=br), None
    # Direct file links (generic extractor) often carry no codec information: accept MP4/M4A by extension.
    # Safe: the exporter refuses audio it cannot filter, and the player refuses it too (no unfiltered fallback).
    unknown = [f for f in fm if f.get("vcodec") in (None, "unknown") and f.get("acodec") in (None, "unknown")]
    for f in unknown:
        if f.get("ext") in ("mp4", "m4v", "mov"):
            return None, None, f
        if f.get("ext") == "m4a":
            return None, f, None
    raise LinkError("no_format")


def _stream(f, ydl):
    if not f:
        return None
    headers = dict(f.get("http_headers") or {})
    # Some sites (TikTok) only serve the media to the session that opened the page: send its cookies too.
    cookie = ydl.cookiejar.get_cookie_header(f["url"])
    if cookie:
        headers["Cookie"] = cookie
    return {"url": f["url"], "headers": headers, "height": f.get("height"),
            "ext": f.get("ext"), "format_id": f.get("format_id"), "size": f.get("filesize") or f.get("filesize_approx")}


def resolve(url, qjs_path, cache_dir):
    """Returns JSON: title, duration, is_live, site, thumbnail and the chosen streams (video+audio, or one
    progressive file, or audio only). Raises LinkError with a user-facing message."""
    p = urlparse(url.strip())
    if p.scheme not in ("http", "https") or not p.netloc:
        raise LinkError("invalid_url")
    os.makedirs(cache_dir, exist_ok=True)
    tempfile.tempdir = cache_dir  # QuickJS reads the challenge scripts from temporary files
    opts = {
        "quiet": True, "no_warnings": True, "noplaylist": True, "skip_download": True,
        "js_runtimes": {"quickjs": {"path": qjs_path}}, "remote_components": set(),
        "cachedir": cache_dir + "/yt-dlp", "socket_timeout": 20,
    }
    y = yt_dlp.YoutubeDL(opts)
    try:
        info = y.extract_info(url.strip(), download=False)
    except yt_dlp.utils.DownloadError as e:
        msg = str(e)
        low = msg.lower()
        # Instagram & co. refuse anonymous visitors only some of the time (rate limits, per-post settings):
        # "rate-limit reached or login required" is a refusal to retry later, not proof the post is private.
        if "rate-limit" in low or "rate limit" in low or "too many requests" in low or "http error 429" in low:
            raise LinkError("limited")
        if "logged-in" in low or "login" in low or "log in" in low or "cookies" in low:
            raise LinkError("login")
        if "Unsupported URL" in msg:
            raise LinkError("unsupported_site")
        raise LinkError("failed", msg.replace("ERROR: ", "")[:300])
    if info.get("_type") == "playlist" or info.get("entries") is not None:
        raise LinkError("playlist")
    v, a, both = _pick(info)
    streams = {"video": _stream(v, y), "audio": _stream(a, y), "progressive": _stream(both, y)}
    y.close()
    return json.dumps({
        "title": info.get("title") or "", "duration": info.get("duration"), "is_live": bool(info.get("is_live")),
        "site": info.get("extractor_key") or info.get("extractor") or "", "thumbnail": info.get("thumbnail"),
        **streams,
    })


def version():
    return yt_dlp.version.__version__
