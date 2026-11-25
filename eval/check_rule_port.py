"""An independent implementation of the Cg and Dmg rules from eval/dm_weights.json alone (no music_check_eval.py),
checked against eval/music_rule_vectors.json: the reference for the app's port.

    python eval/check_rule_port.py
"""
import json, math, os

HERE = os.path.dirname(os.path.abspath(__file__))


def parts_from(flags, t, min_part, gap):
    segs = []
    for f, s in zip(flags, t):
        if not f:
            continue
        if segs and s <= segs[-1][1] + gap:
            segs[-1][1] = s + 1.0
        else:
            segs.append([s, s + 1.0])
    return [p for p in segs if p[1] - p[0] >= min_part]


def rule(R, name, t, level, tags):
    c, th = R["classes"], R[name]
    n = len(t)
    get = lambda w, ids: max((tags[w].get(i, 0.0) for i in ids), default=0.0)
    loud = [level[w] > R["min_level_db"] for w in range(n)]
    perc = [loud[w] and get(w, c["perc_no_gong"]) > th["perc"] and get(w, c["tonal_instr"]) < th["tonal_max"] for w in range(n)]
    if name == "Cg":
        score = [max(tags[w].get(c["music"], 0.0) - th["vocal"] * get(w, c["vocal"]), get(w, c["tonal_instr"]), get(w, c["genre"]))
                 for w in range(n)]
        music = [loud[w] and score[w] > th["music"] or perc[w] for w in range(n)]
    else:
        W, b = R["dm_logistic"]["W"], R["dm_logistic"]["b"]
        sc = [1 / (1 + math.exp(-(sum(W[i] * v for i, v in tags[w].items()) + b))) for w in range(n)]
        k, h = th["smooth"], th["smooth"] // 2
        pad = [sc[0]] * h + sc + [sc[-1]] * h
        sm = [sum(pad[w:w + k]) / k for w in range(n)]
        music = [loud[w] and sm[w] > th["music"] or perc[w] for w in range(n)]
    parts = parts_from(music, t, R["min_part_s"], R["bridge_gap_s"])
    spec = [get(w, c["specific"]) for w in range(n)]
    parts = [p for p in parts if max([spec[w] for w in range(n) if p[0] <= t[w] < p[1]], default=0.0) > th["spec"]]
    if not parts:
        return music, perc, [], "none"
    pc = all(sum(perc[w] for w in range(n) if a <= t[w] < b) / max(1, sum(1 for w in range(n) if a <= t[w] < b)) >= th["pshare"]
             for a, b in parts)
    return music, perc, parts, "percussion" if pc else "music"


def main():
    R = json.load(open(os.path.join(HERE, "dm_weights.json")))
    V = json.load(open(os.path.join(HERE, "music_rule_vectors.json")))
    bad = 0
    for clip in V["clips"]:
        tags = [{int(k): v for k, v in w.items()} for w in clip["tags"]]
        for name in ("Cg", "Dmg"):
            music, perc, parts, verdict = rule(R, name, clip["t"], clip["level_db"], tags)
            e = clip[name]
            ok = ([int(x) for x in music] == e["music_windows"] and [int(x) for x in perc] == e["percussion_windows"]
                  and parts == e["parts"] and verdict == e["verdict"])
            bad += not ok
            print(f'{"ok  " if ok else "FAIL"} {name:3s} {clip["id"]}: {verdict} {parts}')
    print("all match" if not bad else f"{bad} mismatches")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
