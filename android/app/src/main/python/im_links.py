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


def _hevc(f):
    return str(f.get("vcodec") or "").startswith(("hvc1", "hev1", "h265", "hevc"))


def _aac(f):
    return str(f.get("acodec") or "").startswith("mp4a") or (f.get("ext") == "m4a" and f.get("acodec") not in (None, "none"))


def _known(v):
    return v not in (None, "unknown")


def _short_side(f):
    """Size of a video format for the MAX_HEIGHT cap: the short side, so a portrait 720x1280 reel, TikTok or Short
    counts as 720p (capping its 1280 height dropped every portrait video and left only the audio). 0 if unknown."""
    w, h = f.get("width") or 0, f.get("height") or 0
    return min(w, h) if w and h else (h or w)


def _best_video(fs):
    """Largest format within MAX_HEIGHT; if every one is larger, the smallest, so a video never turns into audio
    only because of its size. Formats of known size first (TikTok's watermarked "download" has none)."""
    if not fs:
        return None
    rate = lambda f: f.get("tbr") or f.get("vbr") or 0
    fit = [f for f in fs if _short_side(f) <= MAX_HEIGHT and _short_side(f) > 0]
    if fit:
        return max(fit, key=lambda f: (_short_side(f), rate(f)))
    big = [f for f in fs if _short_side(f) > MAX_HEIGHT]
    if big:
        return min(big, key=lambda f: (_short_side(f), -rate(f)))
    return max(fs, key=rate)


def _pick(info, hevc=False):
    """Chooses what the player and the exporter use: (video, audio, progressive), one or two of them set.

    A page with video gives video: separate MP4 video + AAC audio (DASH: YouTube, Instagram), else one MP4 file with
    both (TikTok, YouTube 360p, Instagram's progressive files), else a direct MP4 link without codec information.
    Audio only is the last resort, for pages without video or whose video cannot go into an MP4 (VP9, AV1, HLS only).
    Video must be H.264 (plays and muxes everywhere); HEVC only when there is no H.264 at all and [hevc] says the
    phone decodes it. The video track is copied into saved files as is, never re-encoded."""
    fm = [f for f in (info.get("formats") or [info]) if _http(f) and "drc" not in str(f.get("format_id"))]
    has_v = lambda f: _known(f.get("vcodec")) and f.get("vcodec") != "none"
    has_a = lambda f: _known(f.get("acodec")) and f.get("acodec") != "none"
    mp4 = lambda f: f.get("ext") in ("mp4", "m4v", "mov")

    def video_codec(fs):  # H.264 if any, else HEVC (when allowed)
        avc = [f for f in fs if _avc(f)]
        return avc or ([f for f in fs if _hevc(f)] if hevc else [])

    video = video_codec([f for f in fm if has_v(f) and not has_a(f) and mp4(f)])
    audio = [f for f in fm if has_a(f) and not has_v(f) and _aac(f)]
    # "Both" also takes formats whose audio codec is unreported but not "none" (the decoder sees what it is).
    both = video_codec([f for f in fm if has_v(f) and f.get("acodec") != "none" and mp4(f)])
    # Stereo/mono first (the voice model takes 1-2 channels; 5.1 tracks are refused, never passed through),
    # then the highest bitrate.
    br = lambda f: ((f.get("audio_channels") or 2) <= 2, f.get("abr") or f.get("tbr") or 0)
    if video and audio:
        return _best_video(video), max(audio, key=br), None
    if both:
        return None, None, _best_video(both)
    # Direct file links (generic extractor), Instagram's progressive files: no codec information. Accept MP4 by
    # extension (unless it says there is no audio). Safe: the exporter refuses audio it cannot filter, and the
    # player refuses it too (no unfiltered fallback); an unsupported video codec fails, it does not drop the video.
    unknown = [f for f in fm if not _known(f.get("vcodec")) and f.get("acodec") != "none" and mp4(f)]
    if unknown:
        return None, None, _best_video(unknown)
    if audio:
        return None, max(audio, key=br), None
    m4a = [f for f in fm if not _known(f.get("vcodec")) and not _known(f.get("acodec")) and f.get("ext") == "m4a"]
    if m4a:
        return None, m4a[0], None
    raise LinkError("no_format")


def _stream(f, ydl):
    if not f:
        return None
    headers = dict(f.get("http_headers") or {})
    # Some sites (TikTok) only serve the media to the session that opened the page: send its cookies too.
    cookie = ydl.cookiejar.get_cookie_header(f["url"])
    if cookie:
        headers["Cookie"] = cookie
    return {"url": f["url"], "headers": headers, "height": f.get("height"), "width": f.get("width"),
            "vcodec": f.get("vcodec"), "acodec": f.get("acodec"),
            "ext": f.get("ext"), "format_id": f.get("format_id"), "size": f.get("filesize") or f.get("filesize_approx")}


def resolve(url, qjs_path, cache_dir, hevc=False):
    """Returns JSON: title, duration, is_live, site, thumbnail and the chosen streams (video+audio, or one
    progressive file, or audio only; video_unavailable: the page has video but only its audio could be used).
    [hevc]: the phone decodes HEVC (used only when there is no H.264). Raises LinkError with a user-facing message."""
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
    v, a, both = _pick(info, hevc)
    streams = {"video": _stream(v, y), "audio": _stream(a, y), "progressive": _stream(both, y)}
    page_video = any((f.get("vcodec") or "none") != "none" for f in (info.get("formats") or [info]))
    y.close()
    return json.dumps({
        "title": info.get("title") or "", "duration": info.get("duration"), "is_live": bool(info.get("is_live")),
        "site": info.get("extractor_key") or info.get("extractor") or "", "thumbnail": info.get("thumbnail"),
        "video_unavailable": page_video and not (v or both), **streams,
    })


def version():
    return yt_dlp.version.__version__
