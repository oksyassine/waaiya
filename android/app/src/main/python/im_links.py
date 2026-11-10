"""Link feature: turns a page link (YouTube, TikTok, ...) into the media streams Islamic Mute can filter.

Runs inside the app through Chaquopy. Only yt-dlp's Python API is used (no shell, no config files, no plugins
fetched at run time). YouTube's JavaScript challenge is solved by the bundled yt-dlp-ejs scripts in QuickJS.
"""
import json
import tempfile
from urllib.parse import urlparse

import yt_dlp

MAX_HEIGHT = 720  # enough for a phone screen; keeps downloads and processing light


class LinkError(Exception):
    """Message is shown to the user."""


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
    br = lambda f: f.get("abr") or f.get("tbr") or 0
    if video and audio:
        return max(video, key=h), max(audio, key=br), None
    if both:
        return None, None, max(both, key=h)
    if audio:
        return None, max(audio, key=br), None
    raise LinkError("This link has no format Islamic Mute can play (MP4/H.264 video or AAC audio).")


def _stream(f):
    if not f:
        return None
    return {"url": f["url"], "headers": f.get("http_headers") or {}, "height": f.get("height"),
            "ext": f.get("ext"), "format_id": f.get("format_id"), "size": f.get("filesize") or f.get("filesize_approx")}


def resolve(url, qjs_path, cache_dir):
    """Returns JSON: title, duration, is_live, site, thumbnail and the chosen streams (video+audio, or one
    progressive file, or audio only). Raises LinkError with a user-facing message."""
    p = urlparse(url.strip())
    if p.scheme not in ("http", "https") or not p.netloc:
        raise LinkError("Please paste a web link (starting with https://).")
    tempfile.tempdir = cache_dir  # QuickJS reads the challenge scripts from temporary files
    opts = {
        "quiet": True, "no_warnings": True, "noplaylist": True, "skip_download": True,
        "js_runtimes": {"quickjs": {"path": qjs_path}}, "remote_components": set(),
        "cachedir": cache_dir + "/yt-dlp", "socket_timeout": 20,
    }
    try:
        with yt_dlp.YoutubeDL(opts) as y:
            info = y.extract_info(url.strip(), download=False)
    except yt_dlp.utils.DownloadError as e:
        msg = str(e)
        if "logged-in" in msg or "login" in msg.lower() or "cookies" in msg:
            raise LinkError("This site only shows this video to logged-in users. Islamic Mute cannot open it yet.")
        if "Unsupported URL" in msg:
            raise LinkError("This site is not supported.")
        raise LinkError("Could not open this link: " + msg.replace("ERROR: ", "")[:200])
    if info.get("_type") == "playlist" or info.get("entries") is not None:
        raise LinkError("This is a playlist. Please open one video.")
    v, a, both = _pick(info)
    return json.dumps({
        "title": info.get("title") or "", "duration": info.get("duration"), "is_live": bool(info.get("is_live")),
        "site": info.get("extractor_key") or info.get("extractor") or "", "thumbnail": info.get("thumbnail"),
        "video": _stream(v), "audio": _stream(a), "progressive": _stream(both),
    })


def version():
    return yt_dlp.version.__version__
