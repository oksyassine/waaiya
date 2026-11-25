"""Exports the shipping rules of the music check for the app's port (Kotlin), from the tune split only:
  eval/dm_weights.json        Dm's logistic weights (527 + bias) and both rules' thresholds (Cg, Dmg) and class lists
  eval/music_rule_vectors.json clips as per-window inputs (level, sparse tags) with the expected per-window flags,
                               music parts and verdict under Cg and Dmg, computed by music_check_eval.py itself

    python eval/export_rule.py --set /srv/build/music/set2 --feat /srv/build/music/feat
"""
import argparse, json, os, sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import music_check_eval as M  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
VECTOR_CLIPS = ["music_song", "music_instr", "background", "adhan", "adhan", "recitation", "recitation_hall", "percussion",
                "duff_nasheed", "speech", "noise", "acapella"]


def quantize(P):
    """Tags rounded to 4 decimals, values under 0.002 dropped (sparse): the expectations are computed from these."""
    return np.where(P < 0.002, 0.0, np.round(P.astype(np.float64), 4)).astype(np.float32)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--set", default="/srv/build/music/set2")
    ap.add_argument("--feat", default="/srv/build/music/feat")
    a = ap.parse_args()
    rows = list({r["id"]: r for r in map(json.loads, open(os.path.join(a.set, "manifest.jsonl")))}.values())
    feats = {r["id"]: dict(np.load(os.path.join(a.feat, r["id"] + ".npz"))) for r in rows
             if os.path.exists(os.path.join(a.feat, r["id"] + ".npz"))}
    rows = [r for r in rows if r["id"] in feats]
    tune_rows = [r for r in rows if r["split"] == "tune"]
    test_rows = [r for r in rows if r["split"] == "test"]
    M._D["Dm"] = M.train_d(tune_rows, feats, mix_only=True)
    th = {}
    for ap_name in ("Cg", "Dmg"):
        th[ap_name] = M.tune_guard(tune_rows, feats, ap_name, M.tune(tune_rows, feats, ap_name[:-1]))
    W, b = M._D["Dm"]
    out = {
        "about": "Music check rules Cg and Dmg (docs/MUSIC_CHECK.md, reports/music_check.md). Input: per 1 s window "
                 "every 0.5 s, the input level (dBFS) and the 527 AudioSet probabilities of EfficientAT mn04 "
                 "(sigmoid outputs) for the input at 32 kHz. Windows quieter than min_level_db are ignored.",
        "window_s": 1.0, "step_s": 0.5, "min_level_db": M.MIN_LIN, "min_part_s": 3.0, "bridge_gap_s": 2.0,
        "classes": {"music": M.MUSIC, "vocal": M.VOCAL, "tonal_instr": M.TONAL_INSTR, "perc": M.PERC,
                    "perc_no_gong": M.PERC_NG, "genre": M.GENRE, "specific": M.SPECIFIC},
        "Cg": th["Cg"], "Dmg": th["Dmg"],
        "dm_logistic": {"W": [round(float(w), 7) for w in W], "b": round(float(b), 7),
                        "note": "score = sigmoid(tags . W + b), then the mean over `smooth` windows centred on the "
                                "window (edges repeated)"},
    }
    json.dump(out, open(os.path.join(HERE, "dm_weights.json"), "w"), indent=1)
    vec, used = [], set()
    for g in VECTOR_CLIPS:
        cand = [r for r in test_rows if r["group"] == g and r["id"] not in used]
        if g == "adhan":                       # one the unguarded rules flag, one they do not
            flagged = [r for r in cand if M.verdict(feats[r["id"]], "Dm", dict(th["Dmg"]))[0] != "none"]
            cand = (flagged if not any(v["group"] == "adhan" for v in vec) else cand) or cand
        if not cand:
            continue
        r = cand[0]
        used.add(r["id"])
        z = feats[r["id"]]
        P = quantize(z["tag_mix"])
        zq = dict(t=z["t"], lin=np.round(z["lin"], 3), lres=np.round(z["lin"], 3), tag_mix=P, tag_res=P)
        item = {"id": r["id"], "group": r["group"], "expect": r["expect"],
                "t": [float(x) for x in z["t"]], "level_db": [float(x) for x in zq["lin"]],
                "tags": [{str(i): float(P[w, i]) for i in np.nonzero(P[w])[0]} for w in range(len(P))]}
        for ap_name in ("Cg", "Dmg"):
            mus, perc = M.evidence(zq, ap_name, th[ap_name])
            v, parts = M.verdict(zq, ap_name, th[ap_name])
            item[ap_name] = {"music_windows": [int(x) for x in mus], "percussion_windows": [int(x) for x in perc],
                             "parts": [[float(p[0]), float(p[1])] for p in parts], "verdict": v}
        if True:
            sc = 1 / (1 + np.exp(-(P @ W + b)))
            item["Dm_window_score"] = [round(float(x), 5) for x in sc]
        vec.append(item)
    json.dump({"rules": "eval/dm_weights.json", "clips": vec}, open(os.path.join(HERE, "music_rule_vectors.json"), "w"))
    print(json.dumps({k: out[k] for k in ("Cg", "Dmg")}))
    print("vectors:", [(v["id"], v["Cg"]["verdict"], v["Dmg"]["verdict"]) for v in vec])


if __name__ == "__main__":
    main()
