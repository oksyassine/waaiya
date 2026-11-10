"""Person-crop classifier woman / man / girl / boy for the screen blur (crops from fetch_openimages.py).

Trains on the Open Images *test* split crops and scores on the *validation* split crops (held out; the end-to-end
scorer eval_blur.py also uses validation images). Small on purpose: it runs once per person per frame on a phone.

    python models/vision/train_gender.py --data models/vision/data/openimages/crops --out models/vision/gender \
        [--arch mobilenetv3_small_100] [--epochs 12]

Writes <out>/gender.pt (state_dict + labels + input size + normalisation, loadable with weights_only=True),
<out>/gender_eval.json, then export: python models/vision/export_vision.py gender --src <out>/gender.pt ...

The blur leaves a person clear only when p(man) + p(boy) >= male_clear. The report gives, per threshold, the share
of women/girls that would be left clear (must be tiny) and the share of men/boys left clear (the useful part).
"""
import argparse
import csv
import json
import math
import os
import random
import time

import numpy as np
import timm
import torch
import torch.nn.functional as F
from PIL import Image, ImageFilter
from torch.utils.data import DataLoader, Dataset, WeightedRandomSampler

LABELS = ["woman", "man", "girl", "boy"]
MALE = [1, 3]
MEAN, STD = [0.485, 0.456, 0.406], [0.229, 0.224, 0.225]


def rows(split_dir):
    with open(os.path.join(split_dir, "index.csv"), newline="") as f:
        return [(os.path.join(split_dir, r["crop"]), LABELS.index(r["label"])) for r in csv.DictReader(f)
                if os.path.exists(os.path.join(split_dir, r["crop"]))]


class Crops(Dataset):
    def __init__(self, items, size, train):
        self.items, self.size, self.train = items, size, train

    def __len__(self):
        return len(self.items)

    def __getitem__(self, i):
        path, y = self.items[i]
        im = Image.open(path).convert("RGB")
        h, w = self.size
        if self.train:
            W, H = im.size
            # jitter the box: the detector's boxes are not the annotators' boxes
            s = random.uniform(0.8, 1.0)
            cw, ch = max(2, int(W * random.uniform(s, 1.0))), max(2, int(H * random.uniform(s, 1.0)))
            x0, y0 = random.randint(0, W - cw), random.randint(0, H - ch)
            im = im.crop((x0, y0, x0 + cw, y0 + ch))
            if random.random() < 0.5:
                im = im.transpose(Image.FLIP_LEFT_RIGHT)
            if random.random() < 0.3:  # small people on a phone screen: low resolution
                f = random.uniform(0.15, 0.5)
                im = im.resize((max(4, int(im.size[0] * f)), max(4, int(im.size[1] * f))), Image.BILINEAR)
            if random.random() < 0.15:
                im = im.filter(ImageFilter.GaussianBlur(random.uniform(0.5, 1.5)))
            if random.random() < 0.1:
                im = im.convert("L").convert("RGB")
        im = im.resize((w, h), Image.BILINEAR)  # stretched, like the C side (im_vision.c classify)
        x = torch.from_numpy(np.asarray(im, np.float32) / 255.0).permute(2, 0, 1)
        if self.train:
            x = x * random.uniform(0.75, 1.25) + random.uniform(-0.1, 0.1)
            x = x.clamp(0, 1)
        return (x - torch.tensor(MEAN).view(3, 1, 1)) / torch.tensor(STD).view(3, 1, 1), y


def evaluate(net, loader):
    net.eval()
    ps, ys = [], []
    with torch.no_grad():
        for x, y in loader:
            ps.append(F.softmax(net(x), 1))
            ys.append(y)
    p, y = torch.cat(ps).numpy(), torch.cat(ys).numpy()
    pm = p[:, MALE].sum(1)
    female = np.isin(y, [0, 2])
    rep = {"accuracy4": float((p.argmax(1) == y).mean()),
           "male_vs_female_acc": float(((pm >= 0.5) == ~female).mean()), "n": int(len(y)), "thresholds": {}}
    for t in (0.5, 0.7, 0.8, 0.85, 0.9, 0.95, 0.97):
        rep["thresholds"][str(t)] = {"women_left_clear": float((pm[female] >= t).mean()),
                                     "men_left_clear": float((pm[~female] >= t).mean())}
    # the threshold that leaves at most 1% of women/girls clear
    ts = np.sort(pm[female])
    t1 = float(ts[int(math.ceil(0.99 * len(ts))) - 1]) if len(ts) else 0.9
    rep["t_women_1pct"] = {"male_clear": t1, "men_left_clear": float((pm[~female] >= t1).mean())}
    return rep


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--arch", default="mobilenetv3_small_100")
    ap.add_argument("--height", type=int, default=192)
    ap.add_argument("--width", type=int, default=128)
    ap.add_argument("--epochs", type=int, default=12)
    ap.add_argument("--batch", type=int, default=64)
    ap.add_argument("--lr", type=float, default=2e-3)
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--threads", type=int, default=6)
    ap.add_argument("--max-minutes", type=float, default=0, help="stop training after this wall time (0 = no limit)")
    a = ap.parse_args()
    torch.set_num_threads(a.threads)
    random.seed(0)
    torch.manual_seed(0)
    os.makedirs(a.out, exist_ok=True)
    size = (a.height, a.width)

    train, val = rows(os.path.join(a.data, "test")), rows(os.path.join(a.data, "validation"))
    counts = np.bincount([y for _, y in train], minlength=4)
    print("train", dict(zip(LABELS, counts.tolist())), "val", len(val), flush=True)
    # balance female vs male (the decision the blur makes), keep the age split inside each side
    side = np.array([counts[0] + counts[2], counts[1] + counts[3]], np.float64)
    wts = [1.0 / side[0 if y in (0, 2) else 1] for _, y in train]
    sampler = WeightedRandomSampler(wts, num_samples=len(train), replacement=True)
    tl = DataLoader(Crops(train, size, True), batch_size=a.batch, sampler=sampler, num_workers=a.workers,
                    drop_last=True, persistent_workers=a.workers > 0)
    vl = DataLoader(Crops(val, size, False), batch_size=128, num_workers=a.workers)

    net = timm.create_model(a.arch, pretrained=True, num_classes=len(LABELS))
    opt = torch.optim.AdamW(net.parameters(), lr=a.lr, weight_decay=0.02)
    steps = a.epochs * len(tl)
    warm = min(300, steps // 10)
    sched = torch.optim.lr_scheduler.LambdaLR(
        opt, lambda s: (s + 1) / warm if s < warm else 0.5 * (1 + math.cos(math.pi * (s - warm) / max(1, steps - warm))))
    t0, step, best = time.time(), 0, None
    for ep in range(a.epochs):
        net.train()
        tot, n = 0.0, 0
        for x, y in tl:
            loss = F.cross_entropy(net(x), y, label_smoothing=0.05)
            opt.zero_grad()
            loss.backward()
            opt.step()
            sched.step()
            step += 1
            tot += loss.item() * len(y)
            n += len(y)
            if step % 100 == 0:
                print(f"ep {ep} step {step}/{steps} loss {tot / n:.4f} {time.time() - t0:.0f} s", flush=True)
            if a.max_minutes and time.time() - t0 > a.max_minutes * 60:
                break
        rep = evaluate(net, vl)
        rep["epoch"] = ep
        print(json.dumps(rep), flush=True)
        score = rep["t_women_1pct"]["men_left_clear"]
        if best is None or score > best:
            best = score
            torch.save({"state_dict": net.state_dict(), "labels": LABELS, "size": list(size), "mean": MEAN, "std": STD,
                        "arch": a.arch}, os.path.join(a.out, "gender.pt"))
            json.dump(rep, open(os.path.join(a.out, "gender_eval.json"), "w"), indent=1)
        if a.max_minutes and time.time() - t0 > a.max_minutes * 60:
            break
    print("best men_left_clear at 1% women", best)


if __name__ == "__main__":
    main()
