""""other" crops for the classifier: what the person detector boxes in Open Images photos with no people.

The blur covers every box the classifier is unsure about, so a dog, a monkey or a fish the detector takes for a
person is covered (eval/results/blur_animals.md). These crops teach the classifier a fifth label, "other", that the
engine leaves clear like a man (im_vision.c sums man, boy and other), with the same strict male_clear.

Photos: Open Images *train* images with an animal box (Animal in the box hierarchy) and no box or human-verified
image label that names a person, a body part, clothing or a likeness of a person (doll, statue, poster...;
PERSONISH below, on the class names). That filter alone is not enough: Open Images does not box every person
(drivers, passers-by in the background), so a detector box becomes an "other" crop only when it matches an
annotator's animal box (IoU >= MATCH; not a group box, not an animal people ride; images with a generic Animal /
Mammal box are skipped, as annotators put those on people too). Each image is resized to the
640-px screen frame, the detector runs on it as the app's whole-frame pass does (letterbox, person_score, NMS),
and each kept box is cut like a person crop (prep_train_crops.cut). Images are split by md5(image id) like the
person crops (1 in 100 to the holdout).

    python models/vision/prep_other_crops.py --boxes ID_LABEL.csv --imagelabels ID_LABEL.csv \
        --classes oidv7-class-descriptions.csv --hierarchy bbox_labels_600_hierarchy.json \
        --detector person_yolox_nano.onnx --out /kaggle/tmp/gcrops [--images 150000] [--max-minutes 25]

--boxes: ImageID,LabelName,XMin,XMax,YMin,YMax,IsGroupOf columns of the train box CSV; --imagelabels: ImageID,LabelName rows of the positive
(Confidence 1) human-verified image labels. Writes <out>/index_other.csv (index.csv columns, label "other") and
the crops under <out>/other/.
"""
import argparse
import csv
import json
import os
import random
import re
import sys
import time
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from multiprocessing import Pool

import numpy as np
import onnxruntime as ort
from PIL import Image

from prep_train_crops import cut, fetch, frame, is_holdout

PERSONISH = re.compile(
    r"(?i)\b(person|people|human|man|men|woman|women|boy|girl|child|children|kid|baby|toddler|infant|face|smile|"
    r"selfie|fashion|model|dress|clothing|beauty|hair|skin|lady|gentleman|crowd|team|player|bride|groom|wedding|"
    r"portrait|dancer|singer|actor|actress|doll|mannequin|sculpture|statue|toy|poster|costume|muscle|tattoo|lip|"
    r"eyelash|hand|finger|leg|arm|shoulder|neck|ear|nose|mouth|eye|cheek|chin|forehead|thigh|knee|foot|feet|"
    r"abdomen|chest|beard|moustache|cosplay|swimwear|bikini|lingerie|undergarment|brassiere|jeans|shirt|skirt|"
    r"suit|jacket|coat|hat|cap|sunglasses|glasses|footwear|shoe|boot|sandal|sock|glove|scarf|tie|uniform|soldier|"
    r"police|monk|nun|priest|athlete|sport|sports|painting|art|drawing|illustration|cartoon|comics|anime)\b")
ANIMAL = "/m/0jbk"
RIDDEN = {"/m/03k3r", "/m/01x_v", "/m/0bwd_0j", "/m/0ffhf", "/m/0dbzx"}  # horse, camel, elephant, donkey, mule
# Annotators also put these on people (Animal, Mammal, Carnivore) or they are a likeness (Teddy bear): an image with
# one of them is skipped, like an image with a person
GENERIC = {"/m/0jbk", "/m/04rky", "/m/01lrl", "/m/0kmg4"}
NMS, MAX_PER_IMAGE = 0.5, 8  # im_vision.c default; a cap so one photo cannot dominate
PERSON_SCORE = 0.03  # below the app's 0.10: near misses are the same kind of box (each is matched to an animal)
MATCH = 0.6  # IoU between a detector box and an annotated animal box


def personish(classes_csv):
    mids = set()
    with open(classes_csv, newline="") as f:
        for row in csv.reader(f):
            if len(row) >= 2 and PERSONISH.search(row[1]):
                mids.add(row[0])
    return mids


def animals(hierarchy_json):
    def walk(node, inside, out):
        inside = inside or node.get("LabelName") == ANIMAL
        if inside:
            out.add(node["LabelName"])
        for k in ("Subcategory", "Part"):
            for c in node.get(k, []):
                walk(c, inside, out)
        return out
    return walk(json.load(open(hierarchy_json)), False, set())


def pick(boxes_csv, labels_csv, bad_mids, animal_mids, n_images, seed=0):
    """(holdout, train) lists of (image id, animal boxes as (x0, y0, x1, y1) 0..1)."""
    bad, ridden, an = set(), set(), defaultdict(list)
    for path in (boxes_csv, labels_csv):
        with open(path, newline="") as f:
            for row in csv.reader(f):
                if len(row) < 2 or row[0] == "ImageID":
                    continue
                if row[1] in bad_mids:
                    bad.add(row[0])
                elif path == boxes_csv and (row[1] in RIDDEN or row[1] in GENERIC):
                    ridden.add(row[0])
                elif path == boxes_csv and row[1] in animal_mids and row[6] == "0":
                    x0, x1, y0, y1 = map(float, row[2:6])
                    an[row[0]].append((x0, y0, x1, y1))
    ok = sorted(set(an) - bad - ridden)
    random.Random(seed).shuffle(ok)
    print(f"{len(an)} images with an animal box; {len(ok)} kept (no people, likenesses or ridden animals)", flush=True)
    hold = [(i, an[i]) for i in ok if is_holdout(i)]
    train = [(i, an[i]) for i in ok if not is_holdout(i)]
    k = max(1, n_images // 100)
    return hold[:k], train[: n_images - k]


def letterbox(im, size):
    W, H = im.size
    s = min(size / W, size / H)
    w, h = max(1, round(W * s)), max(1, round(H * s))
    x = np.full((size, size, 3), 114, np.float32)
    x[:h, :w] = np.asarray(im.resize((w, h), Image.BILINEAR), np.float32)  # im_vision.c samples bilinearly
    return (x / 255.0).transpose(2, 0, 1)[None], s


def iou(a, b):
    ix, iy = min(a[2], b[2]) - max(a[0], b[0]), min(a[3], b[3]) - max(a[1], b[1])
    if ix <= 0 or iy <= 0:
        return 0.0
    return ix * iy / ((a[2] - a[0]) * (a[3] - a[1]) + (b[2] - b[0]) * (b[3] - b[1]) - ix * iy)


def detect(sess, im):
    """Person boxes (0..1 of the frame), like im_vision.c detect_region on the whole frame plus NMS."""
    inp = sess.get_inputs()[0]
    x, s = letterbox(im, inp.shape[2])
    d = sess.run(None, {inp.name: x})[0].reshape(-1, 5)
    W, H = im.size
    d = d[d[:, 4] >= PERSON_SCORE]
    keep = []
    for r in d[np.argsort(-d[:, 4])]:
        b = (max(0.0, r[0] / s / W), max(0.0, r[1] / s / H), min(1.0, r[2] / s / W), min(1.0, r[3] / s / H))
        if b[2] > b[0] and b[3] > b[1] and all(iou(b, k) <= NMS for k in keep):
            keep.append(b)
        if len(keep) >= MAX_PER_IMAGE:
            break
    return keep


_G = {}


def _init(out, split, detector, threads):
    o = ort.SessionOptions()
    o.intra_op_num_threads = o.inter_op_num_threads = 1
    _G.update(out=out, split=split, pool=ThreadPoolExecutor(threads),
              sess=ort.InferenceSession(detector, o, providers=["CPUExecutionProvider"]))


def one(job):
    image_id, animal_boxes, hold = job
    data = fetch(_G["split"], image_id)
    im = frame(data, image_id) if data is not None else None
    if im is None:
        return []
    boxes = [("other",) + b for b in detect(_G["sess"], im) if max(iou(b, a) for a in animal_boxes) >= MATCH]
    return cut(im, image_id, boxes, hold, _G["out"], folder="other")


def batch(jobs):
    return [r for rows in _G["pool"].map(one, jobs) for r in rows]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--boxes", required=True)
    ap.add_argument("--imagelabels", required=True)
    ap.add_argument("--classes", required=True)
    ap.add_argument("--hierarchy", required=True)
    ap.add_argument("--detector", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--split", default="train", help="Open Images split the ids come from (train; validation for tests)")
    ap.add_argument("--images", type=int, default=150000, help="photos to fetch (1%% holdout)")
    ap.add_argument("--max-minutes", type=float, default=0, help="stop fetching after this time (0 = no limit)")
    ap.add_argument("--procs", type=int, default=0, help="worker processes (default 2 x CPUs)")
    ap.add_argument("--threads", type=int, default=12, help="download threads per process")
    a = ap.parse_args()

    # A worker whose _init raises is replaced by another that raises too, and imap waits forever: load the
    # detector here first so a bad model path fails now
    ort.InferenceSession(a.detector, providers=["CPUExecutionProvider"])
    t0 = time.time()
    hold, train = pick(a.boxes, a.imagelabels, personish(a.classes), animals(a.hierarchy), a.images)
    print(f"holdout {len(hold)} images, train {len(train)} images; parse {time.time() - t0:.0f} s", flush=True)
    jobs = [(i, b, True) for i, b in hold] + [(i, b, False) for i, b in train]
    chunks = [jobs[k:k + 48] for k in range(0, len(jobs), 48)]
    t0, done, counts = time.time(), 0, defaultdict(int)
    with open(os.path.join(a.out, "index_other.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["image", "label", "holdout", "bx0", "by0", "bx1", "by1", "h_frame", "crop"])
        pool = Pool(a.procs or 2 * os.cpu_count(), _init, (a.out, a.split, a.detector, a.threads))
        try:
            for rows in pool.imap(batch, chunks):  # in order: the holdout comes first and is complete
                w.writerows(rows)
                for r in rows:
                    counts[r[2]] += 1
                done += 48
                if done % 4800 < 48:
                    f.flush()
                    print(f"{min(done, len(jobs))}/{len(jobs)} images, {sum(counts.values())} crops, "
                          f"{time.time() - t0:.0f} s", flush=True)
                if a.max_minutes and time.time() - t0 > a.max_minutes * 60:
                    print("time limit: stopping the fetch", flush=True)
                    break
        finally:
            pool.terminate()
    print(f"other crops: train {counts[0]}, holdout {counts[1]}; {time.time() - t0:.0f} s", flush=True)
    if not counts[1]:
        sys.exit("no holdout crops")


if __name__ == "__main__":
    main()
