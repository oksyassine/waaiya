"""Ceiling of the screen blur if detector *part boxes* (a head or torso box inside a man's box) were cleared.

The oracle in blur_diag.py clears only detections matched (IoU >= 0.5) to a man/boy box; every other detection
stays covered. This also clears unmatched detections that lie >= 70% inside a man/boy box (IsGroupOf = 0) and
touch no woman/girl/group box, with the oracle and with the real classifier. Reporting half, real C code.

    python models/vision/blur_parts.py photo|portrait   (results: eval/results/blur_parts.md)
"""
import sys, os, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blur_diag as B
from imvision import Cover, Vision, WOMEN
layout = sys.argv[1]; TS = [0.98, 0.999]
gt = B.read_gt(); full = os.path.join(B.DATA, "crops/validation/full")
rep = [i for i in sorted(gt) if B.half(i) == "report" and os.path.exists(os.path.join(full, i + ".jpg"))]
v = Vision(person=os.path.join(B.ROOT, "person_yolox_nano.onnx"), gender=os.path.join(B.ROOT, "gender_v3.onnx"), policy=WOMEN, threads=4)
cover = Cover(covers_visible=False)
def contain(a, b):
    ix, iy = min(a[2], b[2]) - max(a[0], b[0]), min(a[3], b[3]) - max(a[1], b[1])
    return 0 if ix <= 0 or iy <= 0 else ix * iy / ((a[2] - a[0]) * (a[3] - a[1]))
def kind(p, T): return B.UNSURE if p < 0 else B.CLEAR if p >= T else B.WOMAN if p <= 1 - T else B.UNSURE
cols = ["every covered", "oracle (shipped)", "oracle + man parts"] + [f"{T} real" for T in TS] + [f"{T} real + man parts" for T in TS]
W = {c: [0, 0] for c in cols}; M = {c: [0, 0] for c in cols}; nparts = [0, 0]
for i in rep:
    rgba, mp = B.frame(os.path.join(full, i + ".jpg"), layout)
    dets, _ = v.detect_raw(rgba, run_nsfw=False)
    dets = [type(x).from_buffer_copy(x) for x in dets]
    db = [(x.x0, x.y0, x.x1, x.y1) for x in dets]
    G = gt[i]; boxes = [mp(b) for _, _, b in G]
    m = B.match(boxes, db); used = set(m.values())
    male_m = {m[g] for g, (l, _, _) in enumerate(G) if g in m and l in ("man", "boy")}
    part = set()  # unmatched det inside exactly a man/boy (non-group) box and not touching any woman/girl/group box
    for j in range(len(dets)):
        if j in used: continue
        nparts[1] += 1
        inm = any(contain(db[j], boxes[g]) >= 0.7 and l in ("man", "boy") and not grp for g, (l, grp, _) in enumerate(G))
        inf = any(contain(db[j], boxes[g]) >= 0.1 and (l in ("woman", "girl") or grp) for g, (l, grp, _) in enumerate(G))
        if inm and not inf: part.add(j); nparts[0] += 1
    rules = {"every covered": lambda j, p: B.UNSURE,
             "oracle (shipped)": lambda j, p: B.CLEAR if j in male_m else B.UNSURE,
             "oracle + man parts": lambda j, p: B.CLEAR if j in male_m or j in part else B.UNSURE}
    for T in TS:
        rules[f"{T} real"] = lambda j, p, T=T: kind(p, T)
        rules[f"{T} real + man parts"] = lambda j, p, T=T: B.CLEAR if j in part else kind(p, T)
    for c, f in rules.items():
        for j, x in enumerate(dets): x.kind = f(j, x.p_male)
        r = cover.update(0.0, rgba, dets); cover.reset()
        for g, (l, grp, _) in enumerate(G):
            fr = B.covered_fraction(boxes[g], r)
            if l in ("woman", "girl"): W[c][0] += fr >= 0.9; W[c][1] += 1
            else: M[c][0] += fr < 0.1; M[c][1] += 1
print(f"## {layout}, report half ({len(rep)} images); unmatched dets that are man parts: {nparts[0]}/{nparts[1]}")
print("| rule | women covered | men left clear |\n|---|---|---|")
for c in cols: print(f"| {c} | {W[c][0]/W[c][1]:.1%} | {M[c][0]/M[c][1]:.1%} |")
