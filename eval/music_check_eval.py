"""Score the "check for music" candidates on the test set (docs/MUSIC_CHECK.md) from music_check_features.py output.

    python eval/music_check_eval.py --set /srv/build/music/set --feat /srv/build/music/feat --report reports/music_check.md

Each approach turns per-window evidence into music / percussion parts (the spec's decision rules: windows of 1 s every
0.5 s, input louder than -45 dBFS, gaps under 2 s bridged, parts under 3 s dropped) and a verdict per clip. Its
thresholds are chosen on the "tune" split only (the most music found while false alarms stay within the bar), then
judged on the "test" split, whose speakers, reciters, recordists and artists the tuning never saw.

  A  residual signal features: residual level, tonality (sustained peaks), onset periodicity. No extra model.
  B  AudioSet tagger on the residual (input minus the voice the engine keeps).
  C  AudioSet tagger on the input itself (no engine run: the cheapest).
  BC the tagger on both: music when either says so (B for quiet music under voices, C where the engine removes voice)
  D  a logistic model over both tag vectors and the residual level, trained on the tune split's windows only (on the
     phone: one dot product per window after the tagger), its score averaged over a few windows
  Dm the same model on the input's tags only: no engine run
"""
import argparse, itertools, json, os
from collections import defaultdict

import numpy as np

# AudioSet class groups (class_labels_indices.csv)
MUSIC = 137
TONAL_INSTR = list(range(138, 161)) + list(range(178, 200)) + list(range(208, 214))  # strings, keys, mallets, brass,
                                                   # bowed, wind, harmonica..theremin; no bells, chimes, singing bowl
PERC = list(range(161, 178))                       # Percussion .. Gong (drums, cymbals, tabla, tambourine, rattles)
GENRE = [i for i in range(216, 283) if i not in (218, 238, 254, 255, 271)]  # music genres and moods; no beatboxing,
                                                   # opera, vocal music, a capella, lullaby (voice-only possible)
VOCAL = [27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 254, 255]  # singing, choir, chant, mantra... vocal music, a capella

NO_MUSIC = {"speech", "speech_room", "recitation", "recitation_hall", "adhan", "acapella"}
NOISY = {"noise", "noisy_speech"}
MUSIC_G = {"music_song", "music_instr", "background"}
PERC_G = {"percussion", "duff_nasheed"}
MIN_LIN = -45.0


def parts_from(flags, t, min_part=3.0, gap=2.0):
    """Flagged 1 s windows (every 0.5 s) -> [[start, end]] with gaps under `gap` bridged and parts under `min_part` dropped."""
    segs = []
    for f, s in zip(flags, t):
        if not f:
            continue
        if segs and s <= segs[-1][1] + gap:
            segs[-1][1] = s + 1.0
        else:
            segs.append([s, s + 1.0])
    return [p for p in segs if p[1] - p[0] >= min_part]


_D = {}                                            # approach D's weights, trained on the tune split


def d_features(z, mix_only=False):
    if mix_only:                                   # approach Dm: the input's tags only (no engine run)
        return z["tag_mix"].astype(np.float32)
    rel = np.clip(z["lres"] - z["lin"], -40, 0)[:, None] / 40.0
    return np.concatenate([z["tag_res"].astype(np.float32), z["tag_mix"].astype(np.float32), rel.astype(np.float32)], 1)


def train_d(rows, feats, epochs=300, wd=1e-3, mix_only=False):
    """Logistic regression on 1 s windows of the tune split. Labels from the hand labels: windows inside a music or
    percussion part are 1, windows of a clip without music 0. Each group weighs the same, so the big groups do not
    decide alone."""
    import torch
    X, y, w = [], [], []
    groups = sorted({r["group"] for r in rows})
    for r in rows:
        z = feats[r["id"]]
        loud = z["lin"] > MIN_LIN
        t = z["t"] + 0.5
        lab = np.zeros(len(t), np.float32)
        for a, b, _ in r["parts"]:
            lab[(t >= a) & (t < b)] = 1
        n = int(loud.sum())
        if n == 0:
            continue
        X.append(d_features(z, mix_only)[loud]); y.append(lab[loud]); w.append(np.full(n, 1.0 / n, np.float32))
    cnt = {g: sum(1 for r in rows if r["group"] == g) for g in groups}
    w = [wi / cnt[r["group"]] for wi, r in zip(w, [r for r in rows if (feats[r["id"]]["lin"] > MIN_LIN).any()])]
    X, y, w = (torch.from_numpy(np.concatenate(v).astype(np.float32)) for v in (X, y, w))
    w = w / w.sum()
    torch.manual_seed(0)
    lin = torch.nn.Linear(X.shape[1], 1)
    opt = torch.optim.Adam(lin.parameters(), lr=0.01, weight_decay=wd)
    for _ in range(epochs):
        opt.zero_grad()
        loss = (torch.nn.functional.binary_cross_entropy_with_logits(lin(X)[:, 0], y, reduction="none") * w).sum()
        loss.backward()
        opt.step()
    return lin.weight.detach().numpy()[0], float(lin.bias.detach())


def evidence(z, approach, th):
    """Per window: (music flag, percussion-like flag)."""
    lin, rel = z["lin"], z["lres"] - z["lin"]
    loud = lin > MIN_LIN
    if approach == "A":
        res_ok = loud & (rel > th["rel"])
        tonal = res_ok & (z["tonal"] > th["tonal"])
        rhy = res_ok & (z["rhythm"] > th["rhythm"])
        return tonal | rhy, rhy & ~tonal
    if approach in ("D", "Dm"):
        W, b = _D[approach]
        sc = 1 / (1 + np.exp(-(d_features(z, approach == "Dm") @ W + b)))
        k = th.get("smooth", 1)                    # mean over k windows (k = 5: 3 s), so one window alone decides less
        if k > 1:
            sc = np.convolve(np.pad(sc, (k // 2, k // 2), mode="edge"), np.ones(k) / k, mode="valid")
        P = z["tag_mix"].astype(np.float32)
        p = loud & (P[:, PERC].max(1) > th["perc"]) & (P[:, TONAL_INSTR].max(1) < th["tonal_max"])
        return loud & (sc > th["music"]) | p, p
    tags = []
    if approach in ("B", "BC"):
        tags.append((z["tag_res"].astype(np.float32), loud & (rel > th["rel"])))
    if approach in ("C", "BC"):
        tags.append((z["tag_mix"].astype(np.float32), loud))
    mus = np.zeros(len(lin), bool)
    perc = np.zeros(len(lin), bool)
    for P, ok in tags:
        ton, drums = P[:, TONAL_INSTR].max(1), P[:, PERC].max(1)
        # "Music" also answers to singing and chant: a voice-only window loses part of it
        score = np.maximum.reduce([P[:, MUSIC] - th["vocal"] * P[:, VOCAL].max(1), ton, P[:, GENRE].max(1)])
        p = ok & (drums > th["perc"]) & (ton < th["tonal_max"])
        mus |= ok & (score > th["music"]) | p
        perc |= p
    return mus, perc


def verdict(z, approach, th):
    mus, perc = evidence(z, approach, th)
    t = z["t"]
    mparts = parts_from(mus, t)
    if not mparts:
        return "none", []
    # percussion only: in every part, a large share of the windows look like drums without a melodic instrument
    share = th.get("pshare", 0.6)
    pc = all(perc[(t >= a) & (t < b)].mean() >= share for a, b in mparts)
    return ("percussion" if pc else "music"), mparts


_TAG = dict(music=[0.35, 0.45, 0.55, 0.65, 0.75], vocal=[0.0, 0.5, 1.0], perc=[0.1, 0.2, 0.3],
            tonal_max=[0.1, 0.2, 0.3], pshare=[0.3, 0.5])
GRIDS = {
    "A": dict(rel=[-35, -30, -25, -20], tonal=[0.3, 0.4, 0.5, 0.6, 0.7], rhythm=[0.3, 0.4, 0.5, 0.6]),
    "B": dict(rel=[-30, -25, -20], **_TAG),
    "C": dict(rel=[-99], **_TAG),
    "BC": dict(rel=[-25, -20], **_TAG),
    "Dm": dict(music=[0.3, 0.35, 0.4, 0.45, 0.5, 0.6, 0.7, 0.8], smooth=[1, 5, 9], perc=[0.1, 0.2, 0.3],
               tonal_max=[0.1, 0.2, 0.3], pshare=[0.3, 0.5]),
    "D": dict(music=[0.3, 0.35, 0.4, 0.45, 0.5, 0.6, 0.7, 0.8], smooth=[1, 5, 9], perc=[0.1, 0.2, 0.3],
              tonal_max=[0.1, 0.2, 0.3], pshare=[0.3, 0.5]),
}


def score(rows, feats, approach, th):
    """Rates per group and the bar's numbers."""
    by = defaultdict(lambda: [0, 0])          # group -> [flagged (or found), total]
    res = {}
    for r in rows:
        v, parts = verdict(feats[r["id"]], approach, th)
        res[r["id"]] = (v, parts)
        g = r["group"]
        if r["expect"] == "none":
            by[g][0] += v != "none"
        elif r["expect"] == "music":
            by[g][0] += v != "none"
        else:
            by[g][0] += v == "percussion"
        by[g][1] += 1
    rate = lambda gs: (sum(by[g][0] for g in gs), sum(by[g][1] for g in gs))
    return by, res, rate


def ok_rate(n_d):
    n, d = n_d
    return n / d if d else 0.0


def tune(rows, feats, approach, margin=True):
    """Thresholds from the tune split. A grid point passes when false alarms stay at half the bar (1 % clean voice,
    2.5 % noisy) so the test split has room; among the passing points, the one that finds the most music, and on a tie
    the median of the tied points (the middle of the plateau, not its loosest edge). With nothing passing, the
    point with the fewest false alarms."""
    keys = list(GRIDS[approach])
    lim_c, lim_n = (0.01, 0.025) if margin else (0.02, 0.05)
    scored = []
    for vals in itertools.product(*(GRIDS[approach][k] for k in keys)):
        th = dict(zip(keys, vals))
        _, _, rate = score(rows, feats, approach, th)
        fa, fan = ok_rate(rate(NO_MUSIC)), ok_rate(rate(NOISY))
        found, perc = ok_rate(rate(MUSIC_G)), ok_rate(rate(PERC_G))
        scored.append((fa <= lim_c and fan <= lim_n, round(found + 0.25 * perc, 6), -(fa + fan), th))
    ok = [x for x in scored if x[0]]
    if not ok:
        return max(scored, key=lambda x: (x[2], x[1]))[3]
    top = max(x[1] for x in ok)
    tied = [x for x in ok if x[1] == top]
    tied.sort(key=lambda x: x[2])                      # loosest .. strictest
    return tied[len(tied) // 2][3]


def part_error(r, parts):
    """Largest boundary error (s) between the hand-labelled music parts and the detected ones, None if none found."""
    worst = 0.0
    for a, b, _ in r["parts"]:
        hit = [p for p in parts if p[0] < b and p[1] > a]
        if not hit:
            return None
        worst = max(worst, abs(min(p[0] for p in hit) - a), abs(min(max(p[1] for p in hit), r["seconds"]) - b))
    return worst


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--set", default="/srv/build/music/set")
    ap.add_argument("--feat", default="/srv/build/music/feat")
    ap.add_argument("--report", default=None)
    ap.add_argument("--approaches", default="A,B,C,BC,D,Dm")
    a = ap.parse_args()
    rows = list({r["id"]: r for r in map(json.loads, open(os.path.join(a.set, "manifest.jsonl")))}.values())
    feats = {}
    for r in rows:
        p = os.path.join(a.feat, r["id"] + ".npz")
        if os.path.exists(p):
            feats[r["id"]] = dict(np.load(p))
    rows = [r for r in rows if r["id"] in feats]
    tune_rows = [r for r in rows if r["split"] == "tune"]
    test_rows = [r for r in rows if r["split"] == "test"]
    groups = sorted({r["group"] for r in rows})
    out = ["# Check for music: evaluation", "",
           f"{len(rows)} clips measured ({len(tune_rows)} tune, {len(test_rows)} test). Rates below are on the test split; "
           "thresholds were chosen on the tune split. A clip is about 20 s.", ""]
    out += ["## Clips per group and split", "", "| Group | Tune | Test | Sources (test) |", "| --- | --- | --- | --- |"]
    for g in groups:
        nt = sum(r["group"] == g for r in tune_rows)
        ns = sum(r["group"] == g for r in test_rows)
        src_t = {r.get("source") for r in tune_rows if r["group"] == g}
        src_s = {r.get("source") for r in test_rows if r["group"] == g}
        leak = len((src_t & src_s) - {None})
        out.append(f"| {g} | {nt} | {ns} | {len(src_s - {None})}" + (f" ({leak} shared with tune!)" if leak else "") + " |")
    out.append("")
    summary = []
    for ap_name in a.approaches.split(","):
        if ap_name in ("D", "Dm"):
            _D[ap_name] = train_d(tune_rows, feats, mix_only=ap_name == "Dm")
        th = tune(tune_rows, feats, ap_name)
        by, res, rate = score(test_rows, feats, ap_name, th)
        fa, fan = rate(NO_MUSIC), rate(NOISY)
        found, perc = rate(MUSIC_G), rate(PERC_G)
        errs = [part_error(r, res[r["id"]][1]) for r in test_rows if r["expect"] == "music" and r.get("kind") == "introoutro"]
        within = [e is not None and e <= 2.0 for e in errs]
        perc_none = sum(1 for r in test_rows if r["group"] in PERC_G and res[r["id"]][0] == "none")
        summary.append((ap_name, th, fa, fan, found, perc, within, perc_none))
        tby, _, _ = score(tune_rows, feats, ap_name, th)
        out += [f"## Approach {ap_name}", "", f"Thresholds (from tune): `{json.dumps(th)}`", "",
                "| Group | Expected | Meaning | Tune | Test |", "| --- | --- | --- | --- | --- |"]
        for g in groups:
            exp = next(r["expect"] for r in rows if r["group"] == g)
            meaning = {"none": "false alarms", "music": "found", "percussion": "labelled percussion only"}[exp]
            cell = lambda nd: f"{nd[0]}/{nd[1]} = {nd[0] / nd[1]:.0%}" if nd[1] else "none"
            out.append(f"| {g} | {exp} | {meaning} | {cell(tby[g])} | {cell(by[g])} |")
        bg = defaultdict(lambda: [0, 0])
        for r in test_rows:
            if r["group"] == "background":
                k = f"{r['music_under_db']:+.0f} dB" if r.get("kind") == "all" else "intro/outro"
                bg[k][0] += res[r["id"]][0] != "none"
                bg[k][1] += 1
        out += ["", "Background music by level: " + ", ".join(f"{k}: {v[0]}/{v[1]}" for k, v in sorted(bg.items())),
                f"Intro/outro parts placed within 2 s: {sum(within)}/{len(within)}",
                f"Percussion clips reported as no instruments: {perc_none}", ""]
        out += ["Misses and false alarms (test):", ""]
        for r in test_rows:
            v, parts = res[r["id"]]
            wrong = (r["expect"] == "none" and v != "none") or (r["expect"] == "music" and v == "none") or \
                    (r["expect"] == "percussion" and v != "percussion")
            if wrong:
                ps = ", ".join(f"{p[0]:.1f}-{p[1]:.1f}" for p in parts)
                out.append(f"- `{r['id']}` ({r['group']}, {r['codec']}): expected {r['expect']}, got {v}" + (f" at {ps} s" if ps else ""))
        out.append("")
    head = ["## Summary (test split)", "", "| Approach | False alarms, clean voice (bar 2 %) | False alarms, noisy (bar 5 %) | "
            "Music found (bar 95 %) | Percussion only labelled (bar 85 %) | Parts within 2 s |", "| --- | --- | --- | --- | --- | --- |"]
    for ap_name, th, fa, fan, found, perc, within, _ in summary:
        f = lambda nd: f"{nd[0]}/{nd[1]} = {ok_rate(nd):.1%}"
        head.append(f"| {ap_name} | {f(fa)} | {f(fan)} | {f(found)} | {f(perc)} | {sum(within)}/{len(within)} |")
    text = "\n".join(out[:4] + head + [""] + out[4:])
    print(text)
    if a.report:
        open(a.report, "w").write(text + "\n")


if __name__ == "__main__":
    main()
