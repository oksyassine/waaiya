"""Fetch a small gender/style-labelled check set for the women's-singing detector (16 kHz FLAC, <=8 s).

  singing  F/M : OpenSinger (HF CodecSR/opensinger_female / _male)    CC BY-NC-SA (upstream Multi-Singer README) -> evaluation only
  speech   F/M : FLEURS ar_eg + en_us test (HF google/fleurs)          CC BY 4.0
  recitation   : the project test-set sources (male reciters)

Writes models/detector/evalset/<style>_<gender>_<n>.flac and labels.json.
"""
import io, json, os, sys, time, urllib.request
import numpy as np, soundfile as sf


def resample(x, up, down):
    import torch, torchaudio.functional as AF
    return AF.resample(torch.from_numpy(np.ascontiguousarray(x, dtype=np.float32)), down, up).numpy()


ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "evalset")
API = "https://datasets-server.huggingface.co/rows?dataset={d}&config={c}&split={s}&offset={o}&length=1"


def get(url, tries=8):
    for i in range(tries):
        try:
            time.sleep(0.7)  # the datasets-server rate-limits bursts (HTTP 429)
            with urllib.request.urlopen(url, timeout=60) as r:
                return r.read()
        except Exception as e:  # noqa: BLE001
            if i == tries - 1:
                raise
            time.sleep(min(60, 5 * 2 ** i) if "429" in str(e) else 2 + 3 * i)


def row(d, c, s, o):
    return json.loads(get(API.format(d=d, c=c, s=s, o=o)))["rows"][0]["row"]


def done(name, labels, meta):
    if os.path.exists(os.path.join(OUT, name + ".flac")):
        labels[name] = meta
        return True
    return False


def save(name, audio_bytes, labels, meta, max_s=8.0):
    x, sr = sf.read(io.BytesIO(audio_bytes), dtype="float32", always_2d=True)
    x = x.mean(1)
    if sr != 16000:
        x = resample(x, 16000, sr).astype(np.float32)
    x = x[: int(max_s * 16000)]
    sf.write(os.path.join(OUT, name + ".flac"), x, 16000)
    labels[name] = meta
    json.dump(labels, open(os.path.join(OUT, "labels.json"), "w"), indent=1, ensure_ascii=False)


def main():
    os.makedirs(OUT, exist_ok=True)
    lp = os.path.join(OUT, "labels.json")
    labels = json.load(open(lp)) if os.path.exists(lp) else {}
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 24
    for g, d, total in (("F", "CodecSR/opensinger_female", 1884), ("M", "CodecSR/opensinger_male", 2040)):
        for i, o in enumerate(np.linspace(0, total - 1, n).astype(int)):
            if done(f"singing_{g}_{i}", labels, {"style": "singing", "gender": g, "src": f"{d}#{o}"}):
                continue
            try:
                r = row(d, "default", "original", int(o))
                a = get(r["audio"][0]["src"])
            except Exception as e:  # noqa: BLE001
                print("skip", d, o, e); continue
            save(f"singing_{g}_{i}", a, labels,
                 {"style": "singing", "gender": g, "src": f"{d}#{o}", "id": r["id"]})
    for lang, total in (("ar_eg", 428), ("en_us", 647)):
        for i, o in enumerate(np.linspace(0, total - 1, n).astype(int)):
            if any(k.endswith(f"_{lang}_{i}") for k in labels):
                continue
            try:
                r = row("google/fleurs", lang, "test", int(o))
                a = get(r["audio"][0]["src"])
            except Exception as e:  # noqa: BLE001
                print("skip", lang, o, e); continue
            g = {"0": "M", "1": "F"}.get(str(r["gender"]))
            if g is None:
                continue
            save(f"speech_{g}_{lang}_{i}", a, labels,
                 {"style": "speech", "gender": g, "src": f"fleurs/{lang}#{o}"})
    src = os.path.join(os.path.dirname(os.path.dirname(ROOT)), "testset", "data", "sources")
    for f in sorted(os.listdir(src)):
        if f.startswith("recitation"):
            x, sr = sf.read(os.path.join(src, f), dtype="float32", always_2d=True)
                y = resample(x.mean(1), 16000, sr).astype(np.float32)[: 8 * 16000]
            name = "recitation_M_" + f[:-4].split("_")[1]
            sf.write(os.path.join(OUT, name + ".flac"), y, 16000)
            labels[name] = {"style": "recitation", "gender": "M", "src": "testset/" + f}
    json.dump(labels, open(os.path.join(OUT, "labels.json"), "w"), indent=1, ensure_ascii=False)
    from collections import Counter
    print(Counter((v["style"], v["gender"]) for v in labels.values()))


if __name__ == "__main__":
    main()
