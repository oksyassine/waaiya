#!/usr/bin/env python3
"""Makes Waaiya's plain tones: android/app/src/main/res/raw/worship_{ring,notification}_N.ogg.

The ringtone and the notification sound are played by Android itself and cannot be filtered, only replaced
(docs/ROADMAP.md item 9). These are plain beeps with no melody: sine waves or the two-frequency ring of a telephone
line, with soft 10 ms edges so they do not click. Written for Waaiya, dedicated to the public domain (CC0 1.0).

    python3 scripts/make_tones.py            # needs ffmpeg with libvorbis
    python3 scripts/make_tones.py --wav DIR  # only the WAV files, into DIR (no ffmpeg)

Rings end with a pause, because Android repeats a ringtone; notification sounds are short.
"""
import math
import struct
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "android/app/src/main/res/raw"
EDGE = 0.010  # seconds of fade in and out per beep
LEVEL = 0.45  # peak level (about -7 dBFS)

# name -> list of (frequencies in Hz, seconds); an empty frequency list is silence
TONES = {
    # two soft beeps, then a pause
    "worship_ring_1": [([880], 0.40), ([], 0.20), ([880], 0.40), ([], 1.60)],
    # four short low pulses, then a pause
    "worship_ring_2": [([523.25], 0.22), ([], 0.18)] * 4 + [([], 1.40)],
    # a telephone line's double ring (400 + 450 Hz), then a pause
    "worship_ring_3": [([400, 450], 0.40), ([], 0.20), ([400, 450], 0.40), ([], 2.00)],
    # one soft beep
    "worship_notification_1": [([1000], 0.18), ([], 0.10)],
    # two short beeps
    "worship_notification_2": [([1200], 0.08), ([], 0.08), ([1200], 0.08), ([], 0.10)],
    # one low beep that fades out
    "worship_notification_3": [([600], 0.45, "decay"), ([], 0.10)],
}


def samples(parts):
    out = []
    for part in parts:
        freqs, secs = part[0], part[1]
        decay = len(part) > 2
        n = int(round(secs * RATE))
        edge = int(EDGE * RATE)
        for i in range(n):
            if not freqs:
                out.append(0.0)
                continue
            t = i / RATE
            v = sum(math.sin(2 * math.pi * f * t) for f in freqs) / len(freqs)
            env = 1.0
            if i < edge:
                env = 0.5 - 0.5 * math.cos(math.pi * i / edge)
            elif i >= n - edge:
                env = 0.5 - 0.5 * math.cos(math.pi * (n - i) / edge)
            if decay:
                env *= math.exp(-4.0 * t / secs)
            out.append(LEVEL * env * v)
    return out


def write_wav(path, data):
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(round(max(-1.0, min(1.0, x)) * 32767))) for x in data))


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--wav":
        out = Path(sys.argv[2])
        out.mkdir(parents=True, exist_ok=True)
        for name, parts in TONES.items():
            write_wav(out / f"{name}.wav", samples(parts))
        return 0
    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for name, parts in TONES.items():
            wav = Path(tmp) / f"{name}.wav"
            write_wav(wav, samples(parts))
            title = "Waaiya plain " + name.removeprefix("worship_").replace("_", " ")
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "3",
                            "-fflags", "+bitexact", "-flags:a", "+bitexact", "-map_metadata", "-1",
                            "-metadata", f"title={title}", "-metadata", "copyright=CC0 1.0 (public domain), Waaiya",
                            str(OUT / f"{name}.ogg")], check=True)
            print(OUT / f"{name}.ogg")
    return 0


if __name__ == "__main__":
    sys.exit(main())
