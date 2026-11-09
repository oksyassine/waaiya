"""Build labelled audio for the women's-singing detector (runs on Kaggle; 48 kHz mono 16-bit WAV clips <= 20 s).

Layout: <out>/<split>/<style>_<gender>/*.wav   split in {train, val, ext}; style in {speech, singing, recitation}
        <out>/music/*.wav                       instrument residue used as augmentation

| source                                   | gives                          | licence           | split            |
|------------------------------------------|--------------------------------|-------------------|------------------|
| LibriSpeech (attached) + SPEAKERS.TXT    | English speech, F/M            | CC BY 4.0         | train / val=test-clean |
| FLEURS ar_eg (HF google/fleurs)          | Arabic speech, F/M             | CC BY 4.0         | train / val=dev  |
| VocalSet 1.1 (Zenodo 1442513)            | singing F/M (+ 'spoken' speech)| CC BY 4.0         | 2 singers held out for val |
| Diverse Quran Reciters (attached)        | recitation, M + Ayu Rumiyati F | reciters' rights  | 1 male reciter + 20% Ayu held out |
| Slakh2100 subset (HF tvergho/slakh)      | instrument residue             | CC BY 4.0         | augmentation     |
| OpenSinger (HF CodecSR/opensinger_*)     | Chinese singing F/M            | CC BY-NC-SA       | ext (evaluation only, never trained on) |
"""
import argparse, csv, glob, io, os, random, re, sys, tarfile, urllib.request, zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(HERE)), "kaggle"))
from prepare_data import decode, write_clips, find, from_files, from_hf_parquet  # noqa: E402

VOCALSET_URL = "https://zenodo.org/api/records/1442513/files/VocalSet11.zip/content"


def budget(files, out_dir, hours, workers, rng, prefix):
    if not files:
        print("  no files for", out_dir, flush=True)
        return 0.0
    s = from_files(list(files), out_dir, hours * 3600, workers, rng, prefix)
    print(f"  {out_dir}: {s / 3600:.2f} h", flush=True)
    return s


def librispeech(out, h, workers, rng):
    spk = {}
    for p in find("SPEAKERS.TXT", "librispeech"):
        for line in open(p, errors="ignore"):
            if line.startswith(";"):
                continue
            f = [c.strip() for c in line.split("|")]
            if len(f) >= 2 and f[0].isdigit() and f[1] in ("F", "M"):
                spk[f[0]] = f[1]
    files = find("*.flac", "librispeech")
    print(f"LibriSpeech: {len(spk)} speakers with sex labels, {len(files)} files", flush=True)
    for split, keep in (("train", lambda f: "/test-" not in f), ("val", lambda f: "/test-clean/" in f)):
        for g in "FM":
            sel = [f for f in files if keep(f) and spk.get(os.path.basename(f).split("-")[0]) == g]
            budget(sel, f"{out}/{split}/speech_{g}", h if split == "train" else 0.3, workers, rng, f"ls{g}")


def fleurs(out, lang, h, tmp):
    from huggingface_hub import hf_hub_download
    for split, hours, dst in (("train", h, "train"), ("dev", 0.3, "val")):
        tsv = hf_hub_download("google/fleurs", f"data/{lang}/{split}.tsv", repo_type="dataset", cache_dir=tmp)
        gender = {}
        for r in csv.reader(open(tsv, encoding="utf-8"), delimiter="\t", quoting=csv.QUOTE_NONE):
            if len(r) >= 7 and r[-1] in ("FEMALE", "MALE"):
                gender[r[1]] = r[-1][0]
        tar = hf_hub_download("google/fleurs", f"data/{lang}/audio/{split}.tar.gz", repo_type="dataset", cache_dir=tmp)
        done = {"F": 0.0, "M": 0.0}
        with tarfile.open(tar) as t:
            for m in t:
                g = gender.get(os.path.basename(m.name))
                if not m.isfile() or g is None or done[g] >= hours * 3600:
                    continue
                x = decode(m.name, t.extractfile(m).read())
                done[g] += write_clips(x, f"{out}/{dst}/speech_{g}", f"fl{lang}_{os.path.basename(m.name)[:-4]}")
        os.remove(tar)
        print(f"FLEURS {lang} {split}: F {done['F'] / 3600:.2f} h, M {done['M'] / 3600:.2f} h", flush=True)


def singer(path):
    """VocalSet singer id as 'f3' / 'm11'. Folders are 'female3' / 'male11' (FULL/female3/...);
    file names start with 'f3_' / 'm11_'. Returns None if neither is found."""
    for p in path.split("/")[:-1]:
        m = re.fullmatch(r"(female|male|[fm])(\d+)", p.lower())
        if m:
            return m.group(1)[0] + m.group(2)
    m = re.match(r"([fm])(\d+)_", os.path.basename(path).lower())
    return m.group(1) + m.group(2) if m else None


def vocalset(out, h, tmp, rng):
    z = f"{tmp}/VocalSet11.zip"
    if not os.path.exists(z):
        print("downloading VocalSet 1.1 (2.1 GB) from Zenodo", flush=True)
        urllib.request.urlretrieve(VOCALSET_URL, z)
    with zipfile.ZipFile(z) as zf:
        names = [n for n in zf.namelist() if n.lower().endswith(".wav") and "__macosx" not in n.lower()]
        singers = sorted({singer(n) for n in names if singer(n)}, key=lambda s: (s[0], int(s[1:])))
        if not all(any(s[0] == g for s in singers) for g in "fm"):
            raise SystemExit(f"VocalSet: could not read singer ids (got {singers}); sample paths: {names[:5]}")
        held = {max((s for s in singers if s[0] == g), key=lambda s: int(s[1:])) for g in "fm"}
        print(f"VocalSet: {len(names)} wavs, singers {singers}, validation singers {sorted(held)}", flush=True)
        rng.shuffle(names)
        done = {}
        for n in names:
            s = singer(n)
            if not s:
                continue
            style = "speech" if "spoken" in n.lower() else "singing"
            split = "val" if s in held else "train"
            key = (split, style, s[0].upper())
            cap = (h if split == "train" else 0.4) * 3600 * (0.15 if style == "speech" else 1.0)
            if done.get(key, 0.0) >= cap:
                continue
            x = decode(n, zf.read(n))
            done[key] = done.get(key, 0.0) + write_clips(x, f"{out}/{split}/{style}_{s[0].upper()}",
                                                         f"vs_{os.path.basename(n)[:-4]}")
    os.remove(z)
    for k, v in sorted(done.items()):
        print(f"  VocalSet {k}: {v / 3600:.2f} h", flush=True)


def quran(out, h, workers, rng):
    files = find("*.mp3", "quran")
    fem = [f for f in files if "ayu_rumiyati" in f.lower()]
    male = [f for f in files if f not in set(fem)]
    reciters = sorted({os.path.basename(os.path.dirname(f)) for f in male})
    held = reciters[len(reciters) // 2] if reciters else None
    print(f"Quran: {len(fem)} female files, {len(male)} male files, {len(reciters)} male reciters; held out {held}", flush=True)
    rng.shuffle(fem)
    k = max(1, len(fem) // 5)
    budget(fem[k:], f"{out}/train/recitation_F", h, workers, rng, "qF")
    budget(fem[:k], f"{out}/val/recitation_F", 0.3, workers, rng, "qFv")
    budget([f for f in male if os.path.basename(os.path.dirname(f)) != held], f"{out}/train/recitation_M", h, workers, rng, "qM")
    budget([f for f in male if os.path.basename(os.path.dirname(f)) == held], f"{out}/val/recitation_M", 0.3, workers, rng, "qMv")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="/kaggle/tmp/det")
    ap.add_argument("--tmp", default="/kaggle/tmp/dl")
    ap.add_argument("--hours", type=float, default=2.0, help="training hours per (style, gender) and source")
    ap.add_argument("--no-quran", action="store_true")
    ap.add_argument("--workers", type=int, default=os.cpu_count() or 4)
    a = ap.parse_args()
    os.makedirs(a.tmp, exist_ok=True)
    rng = random.Random(0)
    librispeech(a.out, a.hours, a.workers, rng)
    fleurs(a.out, "ar_eg", a.hours, a.tmp)
    vocalset(a.out, a.hours * 2, a.tmp, rng)
    if not a.no_quran:
        quran(a.out, a.hours, a.workers, rng)
    # the HF subset only has data/test-*.parquet; with the default split_hint="train" nothing matched (detector v1 trained without music)
    s = from_hf_parquet("tvergho/slakh", f"{a.out}/music", 1.0 * 3600, set(), rng, split_hint="test", columns=("audio", "stem_mix"))
    if s < 600:
        raise SystemExit(f"music augmentation: only {s:.0f} s from tvergho/slakh")
    for g, repo in (("F", "CodecSR/opensinger_female"), ("M", "CodecSR/opensinger_male")):
        s = from_hf_parquet(repo, f"{a.out}/ext/singing_{g}", 0.4 * 3600, set(), rng, split_hint="original")
        print(f"OpenSinger {g} (evaluation only): {s / 3600:.2f} h", flush=True)
    for d in sorted(glob.glob(f"{a.out}/*/*")) + [f"{a.out}/music"]:
        print(f"{d}: {len(glob.glob(d + '/*.wav'))} clips", flush=True)


if __name__ == "__main__":
    main()
