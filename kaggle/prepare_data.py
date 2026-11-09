"""Prepare training audio on Kaggle: decode once to 48 kHz mono 16-bit WAV clips (fast random reads).

Sources (licences in models/voice/README.md):
  voice/speech_en   LibriSpeech (attached Kaggle dataset; test-clean/test-other excluded)      CC BY 4.0
  voice/speech_ar   Arabic Speech Corpus (Hugging Face tunis-ai/arabic_speech_corpus)           CC BY 4.0
  voice/singing     VocalSet (Hugging Face Bill13579/vocalset-mirror)                           CC BY 4.0
  voice/recitation  Diverse Quran Reciters (attached Kaggle dataset)          rights belong to the reciters
  music/slakh       Slakh2100 mixes (attached Kaggle dataset) or the 1 GB stems+mixes subset tvergho/slakh   CC BY 4.0
Clips used by our evaluation set (testset/fetch_sources.py) are skipped.

Usage: python prepare_data.py --out /kaggle/tmp/data [--hours speech_en=3,speech_ar=3,singing=4,recitation=4,slakh=10]
"""
import argparse, glob, io, os, random, subprocess, sys, tempfile
from concurrent.futures import ProcessPoolExecutor

import numpy as np
import soundfile as sf

SR = 48000
CLIP_S = 20
EXCLUDE = {  # rows used by the evaluation set
    "speech_ar": {0, 50, 100, 150},
    "singing": {0, 200, 900, 1500, 2300, 3100},
}


def decode(src, data=None):
    """ffmpeg -> mono float32 at 48 kHz. src is a path, or a name hint when data (bytes) is given."""
    if data is not None:
        with tempfile.NamedTemporaryFile(suffix=os.path.splitext(src)[1] or ".bin") as t:
            t.write(data)
            t.flush()
            return decode(t.name)
    out = subprocess.run(["ffmpeg", "-v", "error", "-i", src, "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"],
                         capture_output=True)
    return np.frombuffer(out.stdout, np.float32).copy() if out.returncode == 0 else np.zeros(0, np.float32)


def trim(x, thr_db=-50):
    if not len(x):
        return x
    e = np.abs(x)
    idx = np.where(e > np.max(e) * 10 ** (thr_db / 20))[0]
    return x[idx[0]:idx[-1] + 1] if len(idx) else x[:0]


def write_clips(x, out_dir, stem):
    """Split into <= CLIP_S second clips, normalise peak, save as 16-bit WAV. Returns seconds written."""
    x = trim(x)
    if len(x) < SR:  # skip < 1 s
        return 0.0
    os.makedirs(out_dir, exist_ok=True)
    total = 0.0
    for k, s in enumerate(range(0, len(x), CLIP_S * SR)):
        c = x[s:s + CLIP_S * SR]
        if len(c) < SR:
            continue
        c = c / (np.max(np.abs(c)) + 1e-9) * 0.9
        sf.write(os.path.join(out_dir, f"{stem}_{k}.wav"), c, SR, subtype="PCM_16")
        total += len(c) / SR
    return total


def job_file(args):
    path, out_dir, stem = args
    return write_clips(decode(path), out_dir, stem)


INPUT = os.environ.get("KAGGLE_INPUT", "/kaggle/input")


def find(pattern, hint):
    """Search only inside attached datasets whose folder name contains `hint`
    (works for both /kaggle/input/<slug> and /kaggle/input/datasets/<owner>/<slug> layouts)."""
    roots = [d for d in glob.glob(f"{INPUT}/*") + glob.glob(f"{INPUT}/*/*/*") if hint in os.path.basename(d).lower()]
    out = set()
    for r in roots:
        out.update(glob.glob(os.path.join(r, "**", pattern), recursive=True))
    print(f"found {len(out)} {pattern} files for '{hint}' in {roots}", flush=True)
    return sorted(out)


def from_files(files, out_dir, budget_s, workers, rng, prefix):
    rng.shuffle(files)
    done, i = 0.0, 0
    with ProcessPoolExecutor(workers) as ex:
        while done < budget_s and i < len(files):
            batch = files[i:i + workers * 4]
            i += len(batch)
            jobs = [(f, out_dir, f"{prefix}{i + k}") for k, f in enumerate(batch)]
            done += sum(ex.map(job_file, jobs))
    return done


def from_hf_parquet(repo, out_dir, budget_s, exclude, rng, split_hint="train", columns=("audio",)):
    """Stream rows from a Hugging Face parquet dataset (audio columns with bytes)."""
    import pyarrow.parquet as pq
    from huggingface_hub import HfApi, hf_hub_download
    files = sorted(f for f in HfApi().list_repo_files(repo, repo_type="dataset")
                   if f.endswith(".parquet") and split_hint in f)
    done, row = 0.0, 0
    for f in files:
        local = hf_hub_download(repo, f, repo_type="dataset")
        table = pq.ParquetFile(local)
        for batch in table.iter_batches(batch_size=32, columns=list(columns)):
            cols = [batch.column(i).to_pylist() for i in range(len(columns))]
            for vals in zip(*cols):
                r, row = row, row + 1
                if r in exclude:
                    continue
                for ci, a in enumerate(vals):
                    if not a or not a.get("bytes"):
                        continue
                    done += write_clips(decode(a.get("path") or "x.wav", a["bytes"]), out_dir, f"r{r}c{ci}")
                if done >= budget_s:
                    os.remove(local)
                    return done
        os.remove(local)  # keep disk use low
    return done


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="/kaggle/tmp/data")
    ap.add_argument("--hours", default="speech_en=3,speech_ar=3,singing=4,recitation=4,slakh=10")
    ap.add_argument("--no-quran", action="store_true", help="skip recitation data (rights not cleared)")
    ap.add_argument("--workers", type=int, default=os.cpu_count() or 4)
    args = ap.parse_args()
    hours = {k: float(v) for k, v in (kv.split("=") for kv in args.hours.split(","))}
    rng = random.Random(0)
    report = {}

    libri = [f for f in find("*.flac", "librispeech") if "/test-" not in f]
    report["speech_en"] = from_files(libri, f"{args.out}/voice/speech_en", hours["speech_en"] * 3600, args.workers, rng, "ls")

    report["speech_ar"] = from_hf_parquet("tunis-ai/arabic_speech_corpus", f"{args.out}/voice/speech_ar",
                                          hours["speech_ar"] * 3600, EXCLUDE["speech_ar"], rng)
    report["singing"] = from_hf_parquet("Bill13579/vocalset-mirror", f"{args.out}/voice/singing",
                                        hours["singing"] * 3600, EXCLUDE["singing"], rng)
    if not args.no_quran:
        quran = find("*.mp3", "quran")
        report["recitation"] = from_files(quran, f"{args.out}/voice/recitation", hours["recitation"] * 3600,
                                          args.workers, rng, "q")

    # music: full Slakh mixes plus random partial sub-mixes (fewer instruments = harder, more varied)
    mixes = [f for f in find("mix.flac", "slakh") if "/omitted/" not in f and "/test/" not in f]
    if mixes:  # full Slakh2100 attached as a Kaggle dataset
        report["slakh"] = from_files(mixes, f"{args.out}/music/slakh", hours["slakh"] * 3600, args.workers, rng, "s")
    else:  # 1 GB Slakh subset on Hugging Face: single instrument stems plus their mixes
        report["slakh"] = from_hf_parquet("tvergho/slakh", f"{args.out}/music/slakh", hours["slakh"] * 3600, set(),
                                          rng, split_hint="test", columns=("audio", "stem_mix"))

    for k, v in report.items():
        print(f"{k:12s} {v / 3600:6.2f} h")
    missing = [k for k, v in report.items() if v < 600]
    if missing:
        sys.exit(f"too little data for: {missing} (check the attached datasets)")


if __name__ == "__main__":
    main()
