#!/usr/bin/env python3
"""Makes the landing page's generated pictures and sound from real material (run with the repo's venv):

    PYTHONNOUSERSITE=1 .venv/bin/python site/make_assets.py

Inputs (not committed, see site/.work/README in the report):
  site/.work/mix.wav  testset speech_ar_0_mvr-3: Arabic Speech Corpus voice (Nawar Halabi, CC BY 4.0) + music the
                      project synthesised (testset/build_testset.py)
  site/.work/out.wav  the same 10 s after the real filter: build/im-process -m models/dfn3/dfn3_stream_int8.onnx
Outputs in site/assets/:
  spec-*-dark.webp / spec-*-light.webp   spectrograms before / after, one shared dB scale (an honest comparison)
  bands.webp          the steady music bands: what the filter removed (before minus after), smoothed along time,
                      as an alpha mask the page tints; mirrored so it tiles sideways without a seam
  filtered.m4a/.webm  ONLY the filtered sound (out.wav), mono. The unfiltered mix is never published.
  lang/<code>.webp    the Windows app's filter page in each of its 18 languages (desktop/windows/msix/screenshots)
  speaker.webp        a frame of the intro film's loudspeaker shot (/srv/build/waaiya-intro/flow), for the cover demo
"""
import subprocess
import sys
from pathlib import Path

import numpy as np
import soundfile as sf
from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
WORK = HERE / ".work"
A = HERE / "assets"
LANGS = ["ar", "en", "fr", "ur", "id", "tr", "bn", "fa", "ms", "es", "nl", "de", "it", "ru", "uz", "sw", "ha", "so"]

SR = 48000
NFFT, HOP = 4096, 240
FMIN, FMAX, ROWS = 60.0, 8000.0, 420
TOP_DB, RANGE_DB = 0.0, 72.0  # relative to the loudest cell of the BEFORE picture, shared by both


def spec(path):
    x, sr = sf.read(path, dtype="float64", always_2d=True)
    assert sr == SR, sr
    x = x.mean(axis=1)
    win = np.hanning(NFFT)
    n = 1 + (len(x) - NFFT) // HOP
    frames = np.lib.stride_tricks.sliding_window_view(x, NFFT)[::HOP][:n] * win
    mag = np.abs(np.fft.rfft(frames, axis=1)).T  # freq x time
    freqs = np.fft.rfftfreq(NFFT, 1 / SR)
    edges = np.geomspace(FMIN, FMAX, ROWS + 1)
    out = np.zeros((ROWS, mag.shape[1]))
    for i in range(ROWS):
        sel = (freqs >= edges[i]) & (freqs < edges[i + 1])
        if not sel.any():
            sel = np.argmin(np.abs(freqs - (edges[i] + edges[i + 1]) / 2))
            out[i] = mag[sel]
        else:
            out[i] = mag[sel].mean(axis=0)
    db = 20 * np.log10(out + 1e-9)
    return db[::-1]  # high frequencies on top


def ramp(stops, t):
    """t in [0,1] -> RGB through the colour stops [(pos, (r,g,b)), ...]."""
    t = np.clip(t, 0, 1)
    out = np.zeros(t.shape + (3,))
    for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
        m = (t >= p0) & (t <= p1)
        u = ((t - p0) / (p1 - p0))[m][:, None]
        out[m] = np.array(c0) * (1 - u) + np.array(c1) * u
    return out.astype(np.uint8)


DARK = [(0, (5, 61, 53)), (0.35, (9, 90, 78)), (0.7, (92, 196, 178)), (1, (230, 248, 243))]
LIGHT = [(0, (246, 247, 245)), (0.3, (211, 239, 232)), (0.65, (13, 107, 94)), (1, (5, 61, 53))]


def picture(db, ref, stops, size):
    t = (db - (ref + TOP_DB - RANGE_DB)) / RANGE_DB
    t = np.clip(t, 0, 1) ** 1.35
    img = Image.fromarray(ramp(stops, t)).resize(size, Image.LANCZOS)
    return img


def smooth_time(a, k):
    pad = np.pad(a, ((0, 0), (k, k)), mode="edge")
    c = np.cumsum(pad, axis=1)
    c = np.concatenate([np.zeros((a.shape[0], 1)), c], axis=1)
    return (c[:, 2 * k + 1:] - c[:, :-2 * k - 1]) / (2 * k + 1)


def main():
    before, after = spec(WORK / "mix.wav"), spec(WORK / "out.wav")
    ref = before.max()
    size = (2400, 840)
    picture(before, ref, DARK, size).save(A / "spec-before-dark.webp", quality=80, method=6)
    picture(after, ref, DARK, size).save(A / "spec-after-dark.webp", quality=80, method=6)
    picture(after, ref, LIGHT, (1600, 560)).save(A / "spec-after-light.webp", quality=82, method=6)

    # the steady bands: what the filter took away, held along time (sustained notes are the music's signature)
    removed = np.clip(before - after, 0, 40) / 40
    loud = np.clip((before - (ref - 60)) / 60, 0, 1)
    band = smooth_time(removed * loud, 60)
    band = band / np.percentile(band, 99.5)
    alpha = (np.clip(band, 0, 1) ** 1.6 * 255).astype(np.uint8)
    m = Image.fromarray(alpha, "L").resize((1600, 420), Image.LANCZOS)
    tile = Image.new("L", (3200, 420))
    tile.paste(m, (0, 0))
    tile.paste(m.transpose(Image.FLIP_LEFT_RIGHT), (1600, 0))
    rgba = Image.merge("RGBA", (Image.new("L", tile.size, 255),) * 3 + (tile,))
    rgba.save(A / "bands.webp", quality=70, method=6)

    # only the filtered sound, mono
    for args, name in ((["-c:a", "aac", "-b:a", "64k"], "filtered.m4a"), (["-c:a", "libopus", "-b:a", "48k"], "filtered.webm")):
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(WORK / "out.wav"), "-ac", "1", *args, str(A / name)], check=True)

    (A / "lang").mkdir(exist_ok=True)
    for code in LANGS:
        src = REPO / f"desktop/windows/msix/screenshots/{code}/1-filter.png"
        Image.open(src).convert("RGB").save(A / "lang" / f"{code}.webp", quality=80, method=6)

    film = Path("/srv/build/waaiya-intro/flow")
    clip = next(film.glob("Sand_vibrating*.mp4"), None)
    if clip:
        frame = WORK / "speaker.png"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", "2.5", "-i", str(clip), "-frames:v", "1", str(frame)], check=True)
        im = Image.open(frame).convert("RGB").crop((0, 520, 1080, 1720)).resize((960, 1067), Image.LANCZOS)
        im.save(A / "speaker.webp", quality=80, method=6)
    else:
        print("speaker clip not found: keeping assets/speaker.webp", file=sys.stderr)
    print("assets written")


if __name__ == "__main__":
    main()
