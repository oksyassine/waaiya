"""Download a small, licensed set of voice clips for the evaluation test set.

Each source is a public Hugging Face dataset read through the datasets-server
rows API, so only the needed clips are downloaded. Licences are recorded in
data/sources/SOURCES.json. Clips are used for local evaluation only.
"""
import base64, io, json, os, subprocess, sys, tempfile, time, urllib.parse, urllib.request

import numpy as np
import soundfile as sf

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "sources")
API = "https://datasets-server.huggingface.co/rows"

SOURCES = [
    # (category, dataset, config, split, offsets, licence, note)
    ("speech_en", "sanchit-gandhi/librispeech_asr_dummy", "default", "test.clean", [0, 3, 7, 12], "CC-BY-4.0", "LibriSpeech"),
    ("speech_ar", "tunis-ai/arabic_speech_corpus", "default", "train", [0, 50, 100, 150], "CC-BY-4.0", "Arabic Speech Corpus (Halabi)"),
    ("recitation", "fawazahmed0/quran-audio", "default", "train", [0, 1, 4000, 9000, 30000, 60000], "CC0-1.0 (dataset tag; recordings belong to reciters)", "Quran audio"),
    ("singing", "Bill13579/vocalset-mirror", "default", "train", [0, 200, 900, 1500, 2300, 3100], "CC-BY-4.0", "VocalSet"),
]


def get_json(url, tries=6):
    for i in range(tries):
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                return json.loads(r.read().decode())
        except Exception as e:  # rate limits and cold caches are common
            print(f"  retry {i+1}: {e}", file=sys.stderr)
            time.sleep(3 * (i + 1))
    return None


def fetch(url):
    with urllib.request.urlopen(url, timeout=120) as r:
        return r.read()


def decode(blob):
    """Decode any audio container with ffmpeg (mp3/flac/wav/ogg) to mono float32."""
    with tempfile.TemporaryDirectory() as d:
        src, dst = os.path.join(d, "in.bin"), os.path.join(d, "out.wav")
        open(src, "wb").write(blob)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", src, "-ac", "1", "-c:a", "pcm_f32le", dst], check=True)
        data, sr = sf.read(dst, dtype="float32")
    return data, sr


def main():
    os.makedirs(OUT, exist_ok=True)
    meta_path = os.path.join(OUT, "SOURCES.json")
    meta = json.load(open(meta_path)) if os.path.exists(meta_path) else {}
    for cat, ds, cfg, split, offsets, lic, note in SOURCES:
        for off in offsets:
            name = f"{cat}_{off}.wav"
            path = os.path.join(OUT, name)
            if os.path.exists(path):
                continue
            q = urllib.parse.urlencode({"dataset": ds, "config": cfg, "split": split, "offset": off, "length": 1})
            d = get_json(f"{API}?{q}")
            if not d or not d.get("rows"):
                print(f"skip {ds}@{off}: {str(d)[:120]}")
                continue
            row = d["rows"][0]["row"]
            audio = row.get("audio")
            if isinstance(audio, list):
                audio = audio[0]
            try:
                if isinstance(audio, dict) and audio.get("src"):
                    blob = fetch(audio["src"])
                elif isinstance(audio, dict) and audio.get("bytes"):
                    blob = base64.b64decode(audio["bytes"])
                else:
                    print(f"skip {ds}@{off}: no audio field")
                    continue
                mono, sr = decode(blob)
            except Exception as e:
                print(f"skip {ds}@{off}: {e}")
                continue
            sf.write(path, mono, sr, subtype="FLOAT")
            text = row.get("text") or row.get("transcription") or row.get("sentence") or ""
            meta[name] = {"category": cat, "dataset": ds, "offset": off, "licence": lic, "source": note,
                          "sample_rate": sr, "seconds": round(len(mono) / sr, 2), "text": text}
            print(f"got {name}: {len(mono)/sr:.1f}s @ {sr} Hz")
            json.dump(meta, open(meta_path, "w"), ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
