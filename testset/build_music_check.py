"""Build the "check for music" test set (docs/MUSIC_CHECK.md): real clips, each labelled with what a listener would
say (music, percussion only, or no instruments) and, where music is mixed in, where its parts are.

    python testset/build_music_check.py --out /srv/build/music/set [--only GROUP,...]

Sources (licence kept per clip in manifest.jsonl; "eval only" ones are never trained on or shipped):
  speech       FLEURS test (google/fleurs, CC BY 4.0), 9 languages; Freesound talks and conversations (CC0 / CC BY)
  recitation   held-out reciters of the recitation work (fawazahmed0/quran-audio, CC0 tag) and testset/ sources
  adhan        Freesound call-to-prayer recordings (CC0 / CC BY) and Wikimedia Commons ones (eval only)
  a cappella   OpenSinger (CC BY-NC-SA, eval only) and the testset/ singing sources
  noise        Freesound (CC0 / CC BY): rain, wind, traffic, crowd, applause, cafe, kitchen, market, playground...
  music        FMA songs and instrumentals (CC BY / CC0 only, models/detector/fma_permissive.tsv on recitation-mode)
  percussion   Freesound darbuka, frame drum, bendir, clapping (CC0 / CC BY), alone and under a cappella singing
  background   speech or recitation with an FMA instrumental 25, 20 or 15 dB below it, all along or only in an
               intro and an outro (labelled parts)
  noisy speech speech with Freesound noise 5 to 15 dB below it
A third of the clips go through AAC 64 kbit/s and a sixth through Opus 32 kbit/s, as a shared clip would.

Split: "tune" and "test" by source (speaker language for FLEURS, reciter, recordist, artist), never by clip, so the
thresholds chosen on "tune" are judged on people and recordings they never saw.
"""
import argparse, concurrent.futures as cf, csv, hashlib, io, json, os, random, re, subprocess, sys, tempfile, time
import urllib.parse, urllib.request

import numpy as np
import soundfile as sf

SR = 48000
CLIP_S = 20.0
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECITE = "/srv/build/recite"                       # data of the recitation work (held-out sets)
HOLDOUT = RECITE + "/kout3/out/holdout"
# testset/data is not in git: the main checkout's copy when this worktree has none
TS = next(p for p in (os.path.join(ROOT, "testset/data/sources"), "/srv/projects/islamic_mute/testset/data/sources") if os.path.isdir(p))
FMA_TSV = "/srv/build/wt-recite/models/detector/fma_permissive.tsv"
ADHAN_TSV = "/srv/build/wt-recite/models/detector/adhan_train.tsv"
FMA_PARQUET = "https://huggingface.co/datasets/benjamin-paine/free-music-archive-medium/resolve/refs%2Fconvert%2Fparquet/default/train/{:04d}.parquet"
ROWS = "https://datasets-server.huggingface.co/rows?dataset={d}&config={c}&split={s}&offset={o}&length=1"
FIRST = "https://datasets-server.huggingface.co/first-rows?dataset={d}&config={c}&split={s}"
OPENVERSE = "https://api.openverse.org/v1/audio/?q={q}&license=cc0,by&source=freesound&page_size=20&page={p}"
UA = {"User-Agent": "waaiya-testset/1.0"}
# words in a title or tag that mean the recording may hold music: never used as a "no music" clip
MUSICAL = re.compile(r"music|song|sing|radio|band|busk|guitar|piano|concert|orchestra|melod|tune|jazz|choir|"
                     r"festival|party|club|dj|beat|loop|bpm|drum|bell|organ|violin|flute|nasheed|chant|carol|hymn", re.I)


def get(url, tries=6, timeout=90):
    for i in range(tries):
        try:
            time.sleep(0.4)
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=timeout) as r:
                return r.read()
        except Exception as e:  # noqa: BLE001
            if i == tries - 1:
                raise
            time.sleep(min(60, 5 * 2 ** i) if "429" in str(e) else 2 + 3 * i)


def decode(data_or_path, max_s=None, start=0.0):
    """Any audio file -> 48 kHz mono float32 (ffmpeg)."""
    with tempfile.TemporaryDirectory() as d:
        src = data_or_path
        if isinstance(data_or_path, bytes):
            src = os.path.join(d, "in.bin")
            open(src, "wb").write(data_or_path)
        cmd = ["ffmpeg", "-v", "error", "-y", "-ss", str(start), "-i", src]
        if max_s:
            cmd += ["-t", str(max_s)]
        subprocess.run(cmd + ["-ac", "1", "-ar", str(SR), "-c:a", "pcm_f32le", os.path.join(d, "o.wav")], check=True)
        return sf.read(os.path.join(d, "o.wav"), dtype="float32")[0]


def codec_roundtrip(x, kind):
    """A shared clip is recompressed: AAC 64 kbit/s (video) or Opus 32 kbit/s (voice notes)."""
    if kind == "none":
        return x
    with tempfile.TemporaryDirectory() as d:
        sf.write(d + "/i.wav", x, SR, subtype="FLOAT")
        enc = ["-c:a", "aac", "-b:a", "64k", d + "/e.m4a"] if kind == "aac64" else ["-c:a", "libopus", "-b:a", "32k", d + "/e.ogg"]
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", d + "/i.wav", *enc], check=True)
        y = decode(enc[-1])
    n = min(len(x), len(y))
    return np.pad(y[:n], (0, len(x) - n))


def db(x):
    return 10 * np.log10(np.mean(np.asarray(x, np.float64) ** 2) + 1e-12)


def level(x, target_db):
    return x * 10 ** ((target_db - db(x)) / 20)


def active(x):
    """The loudest part of a clip, for setting levels: speech pauses must not make the music louder than asked."""
    w = SR // 2
    e = np.array([db(x[i:i + w]) for i in range(0, max(1, len(x) - w), w)])
    return db(np.concatenate([x[i * w:(i + 1) * w] for i in np.where(e > e.max() - 20)[0]])) if len(e) else db(x)


def loop_to(x, n):
    if len(x) == 0:
        return np.zeros(n, np.float32)
    if len(x) >= n:
        return x[:n]
    k = int(np.ceil(n / len(x)))
    return np.tile(x, k)[:n]


class Set:
    def __init__(self, out):
        self.out, self.clips = out, os.path.join(out, "clips")
        os.makedirs(self.clips, exist_ok=True)
        self.man_path = os.path.join(out, "manifest.jsonl")
        self.rows = {}
        if os.path.exists(self.man_path):
            for l in open(self.man_path):
                r = json.loads(l)
                self.rows[r["id"]] = r

    def has(self, cid):
        return cid in self.rows and os.path.exists(os.path.join(self.clips, cid + ".flac"))

    def add(self, cid, x, group, expect, split, source, licence, credit, url, parts=None, codec=None, **extra):
        """expect: music | percussion | none. parts: [[start_s, end_s, kind]] with kind music | percussion."""
        if codec is None:
            h = int(hashlib.sha1(cid.encode()).hexdigest(), 16) % 6
            codec = "aac64" if h < 2 else "opus32" if h == 2 else "none"
        x = np.asarray(x, np.float32)
        if len(x) < SR * 3:
            return False
        if parts is None:
            parts = [[0.0, round(len(x) / SR, 2), expect]] if expect != "none" else []
        x = codec_roundtrip(x, codec)
        peak = np.max(np.abs(x)) + 1e-9
        if peak > 0.99:
            x = x * (0.99 / peak)
        sf.write(os.path.join(self.clips, cid + ".flac"), x, SR, subtype="PCM_16")
        r = dict(id=cid, group=group, expect=expect, parts=parts, split=split, source=source, licence=licence,
                 credit=credit, url=url, codec=codec, seconds=round(len(x) / SR, 2), **extra)
        self.rows[cid] = r
        with open(self.man_path, "a") as fh:
            fh.write(json.dumps(r, ensure_ascii=False) + "\n")
        return True


def split_of(key, test_frac=0.6, salt="mc1"):
    """Stable split by source key: most sources go to "test", the rest to "tune"."""
    return "test" if int(hashlib.sha1((salt + key).encode()).hexdigest(), 16) % 100 < test_frac * 100 else "tune"


MIXED = {"background", "noisy_speech", "duff_nasheed", "recitation_hall"}


def rebalance(S, tune_frac=0.4):
    """Per group, about 40 % of its sources (never clips) to "tune", the rest to "test", so a group with few sources
    (5 reciters) still has both sides. Mixed groups keep the split of the clips they were made from."""
    by = {}
    for r in S.rows.values():
        if r["group"] not in MIXED:
            by.setdefault(r["group"], set()).add(r["source"])
    side = {}
    for g, srcs in by.items():
        order = sorted(srcs, key=lambda k: hashlib.sha1(("mc1" + k).encode()).hexdigest())
        k = max(1, round(tune_frac * len(order))) if len(order) > 1 else 0
        for i, src in enumerate(order):
            side[(g, src)] = "tune" if i < k else "test"
    for r in S.rows.values():
        if r["group"] == "recitation_hall":
            r["split"] = S.rows.get("recitation_" + r["id"][len("recitation_hall_"):], r)["split"]
        elif (r["group"], r["source"]) in side:
            r["split"] = side[(r["group"], r["source"])]
    with open(S.man_path, "w") as fh:
        for r in S.rows.values():
            fh.write(json.dumps(r, ensure_ascii=False) + "\n")


# ----------------------------------------------------------------------------- Freesound via Openverse
def openverse(query, want, min_s=6, max_s=600, exclude=None, require=None, cache=None):
    """Freesound recordings (CC0 / CC BY) for a query, longest first within the limits."""
    key = f"{query}|{min_s}|{max_s}"
    if cache is not None and key in cache:
        return cache[key][:want]
    out, seen = [], set()
    for p in range(1, 6):
        try:
            # later pages often fail for anonymous clients (HTTP 500): no retries there
            d = json.loads(get(OPENVERSE.format(q=urllib.parse.quote(query), p=p), tries=3 if p == 1 else 1))
        except Exception as e:  # noqa: BLE001
            print(f"  openverse {query} p{p}: {e}", flush=True)
            break
        for r in d.get("results", []):
            dur = (r.get("duration") or 0) / 1000
            text = r["title"] + " " + " ".join(t["name"] for t in r.get("tags") or [])
            if not (min_s <= dur <= max_s) or r["id"] in seen:
                continue
            if exclude is not None and exclude.search(text):
                continue
            if require is not None and not require.search(text):
                continue
            seen.add(r["id"])
            out.append(dict(id=r["id"], title=r["title"], creator=r.get("creator") or "", url=r["url"],
                            page=r.get("foreign_landing_url") or "", licence=f"CC {r['license'].upper()} {r.get('license_version') or ''}".strip(),
                            seconds=dur))
        if len(out) >= want * 2 or not d.get("results") or p >= (d.get("page_count") or 1):
            break
    if cache is not None:
        cache[key] = out
    return out[:want]


def freesound_group(S, group, expect, queries, per_query, min_s, exclude=None, require=None, cache=None,
                    max_clips_per_file=2):
    n = 0
    for q in queries:
        for it in openverse(q, per_query, min_s=min_s, exclude=exclude, require=require, cache=cache):
            for k in range(max_clips_per_file):
                cid = f"{group}_fs{it['id'][:8]}_{k}"
                if S.has(cid):
                    n += 1
                    continue
                if k * CLIP_S + 3 > it["seconds"]:
                    break
                try:
                    x = decode(get(it["url"]), max_s=CLIP_S, start=k * CLIP_S)
                except Exception as e:  # noqa: BLE001
                    print(f"  skip {it['url']}: {e}", flush=True)
                    break
                if expect != "none" and len(x) < SR * 10:
                    x = loop_to(x, int(SR * 12))   # short loops: a 12 s clip of the rhythm
                if db(x) < -55:
                    break
                n += S.add(cid, x, group, expect, split_of(it["creator"] or it["id"]), it["creator"] or it["id"],
                           it["licence"], f"{it['title']} by {it['creator']} (Freesound)", it["page"], query=q)
    print(f"{group}: {n} clips", flush=True)


# ----------------------------------------------------------------------------- the groups
FLEURS_LANGS = {"ar_eg": 428, "en_us": 647, "fr_fr": 676, "ur_pk": 401, "id_id": 687, "tr_tr": 743, "bn_in": 920,
                "fa_ir": 871, "ms_my": 749}


def speech(S, per_lang=20, cache=None):
    n, first = 0, {}
    for lang, total in FLEURS_LANGS.items():
        for i, o in enumerate(np.linspace(0, total - 1, per_lang).astype(int)):
            cid = f"speech_fleurs_{lang}_{i}"
            if S.has(cid):
                n += 1
                continue
            try:
                # the rows API refuses FLEURS (its parquet row groups exceed the server's scan limit): the first
                # 100 rows of the test split, spread over them, the same rows on every run
                if lang not in first:
                    first[lang] = []
                    for split in ("test", "validation"):    # the server cannot always serve the test split
                        try:
                            first[lang] = json.loads(get(FIRST.format(d="google/fleurs", c=lang, s=split), tries=2))["rows"]
                            break
                        except Exception:  # noqa: BLE001
                            continue
                if not first[lang]:
                    raise RuntimeError("no rows")
                r = first[lang][i * len(first[lang]) // per_lang]["row"]
                x = decode(get(r["audio"][0]["src"]), max_s=CLIP_S)
            except Exception as e:  # noqa: BLE001
                print(f"  skip fleurs {lang} {o}: {e}", flush=True)
                continue
            n += S.add(cid, x, "speech", "none", split_of("fleurs-" + lang), "fleurs-" + lang, "CC BY 4.0",
                       "FLEURS (Google), test split", f"https://huggingface.co/datasets/google/fleurs#{lang}/test/{r['id']}")
    for f in sorted(os.listdir(TS)):
        if f.startswith("speech"):
            cid = "speech_asc_" + f[:-4]
            if not S.has(cid):
                n += S.add(cid, decode(os.path.join(TS, f), max_s=CLIP_S), "speech", "none",
                           split_of("testset-" + f[:9]), "testset-" + f[:9], "CC BY 4.0",
                           "testset/data/sources (see SOURCES.json)", "testset/data/sources/" + f)
    print(f"speech (FLEURS + testset): {n} clips", flush=True)
    freesound_group(S, "speech_room", "none", ["lecture", "conversation", "interview", "people talking", "speech",
                    "sermon", "talking cafe", "phone call", "storytelling", "classroom"], 8, 8, exclude=MUSICAL, cache=cache)


def recitation(S, per_reciter=24):
    n = 0
    for d in sorted(os.listdir(HOLDOUT)):
        if not d.startswith("recitation_"):
            continue
        reciter = d[len("recitation_"):]
        for f in sorted(os.listdir(os.path.join(HOLDOUT, d)))[:per_reciter]:
            cid = "recitation_" + f[:-4]
            if not S.has(cid):
                n += S.add(cid, decode(os.path.join(HOLDOUT, d, f), max_s=CLIP_S), "recitation", "none",
                           split_of("reciter-" + reciter), "reciter-" + reciter, "CC0 (dataset tag; no stated licence upstream)",
                           f"{reciter} (fawazahmed0/quran-audio)", "https://huggingface.co/datasets/fawazahmed0/quran-audio")
            else:
                n += 1
    for f in sorted(os.listdir(TS)):
        if f.startswith("recitation"):
            cid = "recitation_ts_" + f[:-4]
            if not S.has(cid):
                n += S.add(cid, decode(os.path.join(TS, f), max_s=CLIP_S), "recitation", "none",
                           split_of("testset-recitation"), "testset-recitation", "see SOURCES.json",
                           "testset/data/sources", "testset/data/sources/" + f)
    print(f"recitation: {n} clips", flush=True)


def reverb(x, rt60, wet_db, rng):
    """A mosque-like hall: exponentially decaying noise impulse response."""
    n = int(rt60 * SR)
    t = np.arange(n) / SR
    ir = rng.standard_normal(n) * np.exp(-6.9 * t / rt60)
    ir[: int(0.01 * SR)] *= np.linspace(0, 1, int(0.01 * SR))
    wet = np.convolve(x, ir)[: len(x)]
    return (x + level(wet, db(x) + wet_db)).astype(np.float32)


def recitation_echo(S, n_clips=40):
    """Studio recitation in a hall (RT60 1.5-3 s): the echo tail is the kind of residual that may look tonal."""
    rng = random.Random(7)
    nrng = np.random.default_rng(7)
    src = [r for r in S.rows.values() if r["group"] == "recitation"]
    rng.shuffle(src)
    n = 0
    for r in src[:n_clips]:
        cid = "recitation_hall_" + r["id"][len("recitation_"):]
        if S.has(cid):
            n += 1
            continue
        x = sf.read(os.path.join(S.clips, r["id"] + ".flac"), dtype="float32")[0]
        n += S.add(cid, reverb(x, rng.uniform(1.5, 3.0), rng.uniform(-8, -2), nrng), "recitation_hall", "none",
                   r["split"], r["source"], r["licence"], r["credit"] + ", with a simulated hall", r["url"])
    print(f"recitation in a hall: {n} clips", flush=True)


def adhan(S, cache=None, max_chunks=4):
    n = 0
    rows = list(csv.DictReader(open(ADHAN_TSV), delimiter="\t"))
    for r in rows:
        for k in range(max_chunks):
            cid = f"adhan_fs{r['id']}_{k}"
            if S.has(cid):
                n += 1
                continue
            if (k + 0.5) * CLIP_S > float(r["seconds"]) * 0.9:
                break
            try:
                x = decode(get(r["url"]), max_s=CLIP_S, start=15 + k * CLIP_S * 1.5)
            except Exception as e:  # noqa: BLE001
                print(f"  skip adhan {r['id']}: {e}", flush=True)
                break
            if db(x) < -50:
                continue
            lic = {"cc01.0": "CC0 1.0"}.get(r["licence"], r["licence"])
            n += S.add(cid, x, "adhan", "none", split_of("recordist-" + r["creator"]), "recordist-" + r["creator"],
                       lic, f"{r['title']} by {r['creator']} (Freesound)", r["page"])
    wiki = os.path.join(RECITE, "eval/adhan")
    for f in sorted(os.listdir(wiki)):
        for k in range(max_chunks):
            cid = f"adhan_wiki_{re.sub(r'[^A-Za-z0-9]+', '_', f)[:30]}_{k}"
            if S.has(cid):
                n += 1
                continue
            x = decode(os.path.join(wiki, f), max_s=CLIP_S, start=k * CLIP_S)
            if len(x) < SR * 5 or db(x) < -50:
                break
            n += S.add(cid, x, "adhan", "none", split_of("wiki-" + f), "wiki-" + f,
                       "Wikimedia Commons (see adhan_eval.tsv); evaluation only", f, "https://commons.wikimedia.org/wiki/File:" + f)
    print(f"adhan: {n} clips", flush=True)


def acapella(S):
    n = 0
    for g in ("os_F", "os_M"):
        d = os.path.join(RECITE, "eval", g)
        for f in sorted(os.listdir(d)):
            cid = f"acapella_{g}_{f.split('.')[0]}"
            if not S.has(cid):
                n += S.add(cid, decode(os.path.join(d, f)), "acapella", "none", split_of("os-" + f), "opensinger-" + f,  # rows far apart in OpenSinger: other singers
                           "CC BY-NC-SA 4.0 (OpenSinger); evaluation only", "OpenSinger (Multi-Singer)",
                           "https://huggingface.co/datasets/CodecSR/opensinger_" + ("female" if g == "os_F" else "male"))
            else:
                n += 1
    for f in sorted(os.listdir(TS)):
        if f.startswith("singing"):
            cid = "acapella_ts_" + f[:-4]
            if not S.has(cid):
                n += S.add(cid, decode(os.path.join(TS, f), max_s=CLIP_S), "acapella", "none",
                           split_of("testset-singing"), "testset-singing", "see SOURCES.json", "testset/data/sources",
                           "testset/data/sources/" + f)
    print(f"a cappella: {n} clips", flush=True)


NOISE_QUERIES = ["rain", "wind", "traffic", "street ambience", "crowd", "applause", "cafe ambience", "restaurant",
                 "kitchen", "market", "playground children", "car interior", "train station", "airport", "office ambience",
                 "construction", "vacuum cleaner", "washing machine", "birds", "waves sea", "thunderstorm", "fan noise",
                 "footsteps", "typing keyboard"]


def noise(S, cache=None):
    freesound_group(S, "noise", "none", NOISE_QUERIES, 5, 10, exclude=MUSICAL, cache=cache, max_clips_per_file=1)


PERC_QUERIES = ["darbuka", "doumbek", "frame drum", "bendir", "daf drum", "riq", "tar drum", "clapping rhythm",
                "hand clap rhythm", "djembe rhythm", "tabla", "tambourine rhythm", "cajon", "bongo"]
NOT_PERC = re.compile(r"music|song|sing|guitar|piano|oud|violin|flute|synth|bass line|melod|chord|ney|saz|band", re.I)


def percussion(S, cache=None):
    freesound_group(S, "percussion", "percussion", PERC_QUERIES, 6, 4, exclude=NOT_PERC, cache=cache, max_clips_per_file=1)


def fma_tracks(instrumental):
    rows = list(csv.DictReader(open(FMA_TSV), delimiter="\t"))
    return [r for r in rows if r["instrumental"] == ("1" if instrumental else "0")]


def fma_instrumentals(S, want=110):
    """FMA instrumentals (CC BY / CC0), read row group by row group from the Hugging Face parquet."""
    import fsspec, pyarrow.parquet as pq
    fs = fsspec.filesystem("https")
    rows = fma_tracks(True)
    by_shard = {}
    for r in rows:
        by_shard.setdefault(int(r["shard"]), []).append(r)
    n = sum(1 for r in S.rows.values() if r["group"] == "music_instr")
    per_artist = {}
    for shard in sorted(by_shard, key=lambda s: -len(by_shard[s])):
        if n >= want:
            break
        url = FMA_PARQUET.format(shard)
        try:
            with fs.open(url, block_size=1 << 20) as fh:
                pf = pq.ParquetFile(fh)
                bounds, s = [], 0
                for g in range(pf.metadata.num_row_groups):
                    bounds.append((s, s + pf.metadata.row_group(g).num_rows))
                    s += pf.metadata.row_group(g).num_rows
                need = {}
                for r in by_shard[shard]:
                    i = int(r["row"])
                    g = next(k for k, (a, b) in enumerate(bounds) if a <= i < b)
                    need.setdefault(g, []).append(r)
                for g, rs in need.items():
                    rs = [r for r in rs if not S.has(f"music_instr_fma{r['fma_id']}") and per_artist.get(r["artist"], 0) < 3]
                    if not rs or n >= want:
                        continue
                    t = pf.read_row_group(g, columns=["audio", "title", "artist"])
                    titles, arts, audio = (t.column(c).to_pylist() for c in ("title", "artist", "audio"))
                    for r in rs:
                        i = int(r["row"]) - bounds[g][0]
                        if titles[i] != r["title"] or arts[i] != r["artist"]:
                            print(f"  FMA mismatch shard {shard} row {r['row']}", flush=True)
                            continue
                        x = decode(audio[i]["bytes"], max_s=CLIP_S, start=5)
                        if db(x) < -45:
                            continue
                        per_artist[r["artist"]] = per_artist.get(r["artist"], 0) + 1
                        n += S.add(f"music_instr_fma{r['fma_id']}", x, "music_instr", "music",
                                   split_of("artist-" + r["artist"]), "artist-" + r["artist"], r["licence"],
                                   f"{r['title']} by {r['artist']} (Free Music Archive)", r["url"], genres=r["genres"])
        except Exception as e:  # noqa: BLE001
            print(f"  FMA shard {shard}: {type(e).__name__}: {str(e)[:150]}", flush=True)
    print(f"music (FMA instrumentals): {n} clips", flush=True)


def songs(S):
    """FMA songs of the held-out artists of the recitation work (sung genres, CC BY / CC0)."""
    meta = {r["fma_id"]: r for r in fma_tracks(False)}
    n = 0
    d = os.path.join(HOLDOUT, "songs_val")
    for f in sorted(os.listdir(d)):
        r = meta.get(f[:-4])
        if r is None:
            continue
        cid = "music_song_fma" + f[:-4]
        if not S.has(cid):
            n += S.add(cid, decode(os.path.join(d, f), max_s=CLIP_S), "music_song", "music", split_of("artist-" + r["artist"]),
                       "artist-" + r["artist"], r["licence"], f"{r['title']} by {r['artist']} (Free Music Archive)", r["url"],
                       genres=r["genres"])
        else:
            n += 1
    print(f"music (FMA songs): {n} clips", flush=True)


def pick(S, groups, split, rng):
    c = [r for r in S.rows.values() if r["group"] in groups and r["split"] == split and r["codec"] == "none"]
    return rng.choice(c) if c else None


def load_clip(S, r):
    return sf.read(os.path.join(S.clips, r["id"] + ".flac"), dtype="float32")[0]


def background(S, n_per_split=(30, 45)):
    """Voice with an instrumental under it, all along or only in an intro and an outro. Same split on both sides."""
    rng = random.Random(11)
    made = 0
    for split, n in zip(("tune", "test"), n_per_split):
        for i in range(n):
            cid = f"background_{split}_{i}"
            if S.has(cid):
                made += 1
                continue
            v = pick(S, ("speech", "speech_room", "recitation"), split, rng)
            m = pick(S, ("music_instr",), split, rng)
            if v is None or m is None:
                break
            x, y = load_clip(S, v), load_clip(S, m)
            if len(y) < len(x):
                y = loop_to(y, len(x))
            y = y[: len(x)]
            under = rng.choice([-25.0, -20.0, -15.0])
            kind = rng.choice(["all", "all", "introoutro"])
            mus = level(y, active(x) + under)
            if kind == "introoutro":
                # 4 s of music alone (at the voice's level), the voice, then 4 s of music again
                lead = level(y[: 4 * SR], active(x))
                tail = level(y[-4 * SR:], active(x))
                fade = np.linspace(1, 0, SR // 2)
                lead[-len(fade):] *= fade
                tail[: len(fade)] *= fade[::-1]
                z = np.concatenate([lead, x, tail])
                L = len(z) / SR
                parts = [[0.0, 4.0, "music"], [round(L - 4.0, 2), round(L, 2), "music"]]
            else:
                z = x + mus
                parts = [[0.0, round(len(z) / SR, 2), "music"]]
            made += S.add(cid, z, "background", "music", split, v["source"] + "+" + m["source"],
                          f"{v['licence']} + {m['licence']}", f"{v['credit']} + {m['credit']}", v["url"] + " + " + m["url"],
                          parts=parts, music_under_db=under if kind == "all" else 0.0, kind=kind, voice=v["id"], music=m["id"])
    print(f"background music: {made} clips", flush=True)


def noisy_speech(S, n_per_split=(25, 40)):
    rng = random.Random(13)
    made = 0
    for split, n in zip(("tune", "test"), n_per_split):
        for i in range(n):
            cid = f"noisyspeech_{split}_{i}"
            if S.has(cid):
                made += 1
                continue
            v = pick(S, ("speech", "speech_room", "recitation"), split, rng)
            z = pick(S, ("noise",), split, rng)
            if v is None or z is None:
                break
            x = load_clip(S, v)
            y = loop_to(load_clip(S, z), len(x))
            snr = rng.uniform(5, 15)
            made += S.add(cid, x + level(y, active(x) - snr), "noisy_speech", "none", split, v["source"] + "+" + z["source"],
                          f"{v['licence']} + {z['licence']}", f"{v['credit']} + {z['credit']}", v["url"] + " + " + z["url"],
                          snr_db=round(snr, 1), voice=v["id"], noise=z["id"])
    print(f"noisy speech: {made} clips", flush=True)


def duff_nasheed(S, n_per_split=(15, 25)):
    """A cappella singing with a frame-drum or clapping rhythm: "only percussion"."""
    rng = random.Random(17)
    made = 0
    for split, n in zip(("tune", "test"), n_per_split):
        for i in range(n):
            cid = f"duffnasheed_{split}_{i}"
            if S.has(cid):
                made += 1
                continue
            v = pick(S, ("acapella", "recitation"), split, rng)
            p = pick(S, ("percussion",), split, rng)
            if v is None or p is None:
                break
            x = load_clip(S, v)
            y = loop_to(load_clip(S, p), len(x))
            made += S.add(cid, x + level(y, active(x) + rng.uniform(-12, -3)), "duff_nasheed", "percussion", split,
                          v["source"] + "+" + p["source"], f"{v['licence']} + {p['licence']}", f"{v['credit']} + {p['credit']}",
                          v["url"] + " + " + p["url"], voice=v["id"], perc=p["id"])
    print(f"voice with percussion: {made} clips", flush=True)


GROUPS = ["speech", "recitation", "adhan", "acapella", "noise", "percussion", "songs", "instrumentals",
          "recitation_echo", "background", "noisy_speech", "duff_nasheed"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="/srv/build/music/set")
    ap.add_argument("--only", default=",".join(GROUPS))
    a = ap.parse_args()
    S = Set(a.out)
    cpath = os.path.join(a.out, "openverse_cache.json")
    cache = json.load(open(cpath)) if os.path.exists(cpath) else {}
    try:
        for g in a.only.split(","):
            if g in ("background", "noisy_speech", "duff_nasheed"):
                rebalance(S)
            {"speech": lambda: speech(S, cache=cache), "recitation": lambda: recitation(S),
             "adhan": lambda: adhan(S, cache=cache), "acapella": lambda: acapella(S), "noise": lambda: noise(S, cache=cache),
             "percussion": lambda: percussion(S, cache=cache), "songs": lambda: songs(S),
             "instrumentals": lambda: fma_instrumentals(S), "recitation_echo": lambda: recitation_echo(S),
             "background": lambda: background(S), "noisy_speech": lambda: noisy_speech(S),
             "duff_nasheed": lambda: duff_nasheed(S)}[g]()
    finally:
        json.dump(cache, open(cpath, "w"))
    rebalance(S)
    from collections import Counter
    c = Counter((r["group"], r["split"]) for r in S.rows.values())
    for g in sorted({k[0] for k in c}):
        print(f"  {g:16} tune {c[(g, 'tune')]:4}  test {c[(g, 'test')]:4}")


if __name__ == "__main__":
    main()
