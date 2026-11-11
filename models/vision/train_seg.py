"""Fine-tunes the silhouette-cover segmenter: torchvision LR-ASPP MobileNetV3-large (COCO with VOC labels, BSD-3)
on Open Images V7 person masks (prep_seg_crops.py), as one "this person" output.

The input is what the runtime gives it (engine/src/im_vision.c): the detector's box plus CONTEXT on each side,
stretched to H x W. Training jitters the annotated box (detector boxes are not exact) and samples the context inside
the crop's saved margin. Target: the person's own mask; pixels inside other people's boxes are ignored.
The new 1-channel head starts from the COCO model's person-minus-background logit.

    python models/vision/train_seg.py --data /kaggle/tmp/segcrops --weights lraspp_mobilenet_v3_large-d234d4ea.pth \
        --out out [--size 192 128] [--minutes 90] [--tag s192]

Writes <out>/seg_<tag>.pt (state_dict of the 1-class LRASPP, size, mean/std, context) and seg_<tag>_eval.json.
Checkpoints are chosen on the holdout images (1 in 100, never trained on).
"""
import argparse
import csv
import json
import math
import os
import random
import time

import numpy as np
import torch
import torch.nn.functional as F
from PIL import Image, ImageFilter
from torch.utils.data import DataLoader, Dataset

MEAN, STD = [0.485, 0.456, 0.406], [0.229, 0.224, 0.225]
CONTEXT = 0.20  # runtime context around the detector box, each side, fraction of the box size
PERSON, BG = 15, 0


def build(weights=None):
    from torchvision.models.segmentation import lraspp_mobilenet_v3_large

    net = lraspp_mobilenet_v3_large(weights=None, weights_backbone=None, num_classes=21)
    if weights:
        net.load_state_dict(torch.load(weights, map_location="cpu", weights_only=True))
    head = net.classifier
    for name in ("low_classifier", "high_classifier"):
        old = getattr(head, name)
        new = torch.nn.Conv2d(old.in_channels, 1, 1)
        with torch.no_grad():
            new.weight.copy_(old.weight[PERSON:PERSON + 1] - old.weight[BG:BG + 1])
            new.bias.copy_(old.bias[PERSON:PERSON + 1] - old.bias[BG:BG + 1])
        setattr(head, name, new)
    return net


def low_res(net, x):
    """Logits at 1/8 of the input (the head's own resolution, before LR-ASPP's final upsampling)."""
    return net.classifier(net.backbone(x))


class Crops(Dataset):
    def __init__(self, root, rows, size, train):
        self.root, self.rows, self.size, self.train = root, rows, size, train

    def __len__(self):
        return len(self.rows)

    def __getitem__(self, i):
        r = self.rows[i]
        img = Image.open(os.path.join(self.root, "crops", r["crop"])).convert("RGB")
        lab = Image.open(os.path.join(self.root, "crops", r["mask"]))
        W, H = img.size
        bx0, by0, bx1, by1 = (float(r[k]) for k in ("bx0", "by0", "bx1", "by1"))
        bw, bh = bx1 - bx0, by1 - by0
        rnd = random.Random(None if self.train else i)
        if self.train:  # a detector box: each edge moved by up to 8% of the size
            j = lambda: rnd.uniform(-0.08, 0.08)  # noqa: E731
            bx0, bx1, by0, by1 = bx0 + j() * bw, bx1 + j() * bw, by0 + j() * bh, by1 + j() * bh
            bw, bh = bx1 - bx0, by1 - by0
        ctx = CONTEXT
        x0, x1 = max(0.0, bx0 - ctx * bw) * W, min(1.0, bx1 + ctx * bw) * W
        y0, y1 = max(0.0, by0 - ctx * bh) * H, min(1.0, by1 + ctx * bh) * H
        if x1 - x0 < 2 or y1 - y0 < 2:
            x0, y0, x1, y1 = 0, 0, W, H
        h, w = self.size
        box = (int(x0), int(y0), max(int(x0) + 2, int(round(x1))), max(int(y0) + 2, int(round(y1))))
        img = img.resize((w, h), Image.BILINEAR, box=box)
        lab = lab.resize((w, h), Image.NEAREST, box=box)
        if self.train:
            if rnd.random() < 0.5:
                img, lab = img.transpose(Image.FLIP_LEFT_RIGHT), lab.transpose(Image.FLIP_LEFT_RIGHT)
            if rnd.random() < 0.2:
                img = img.filter(ImageFilter.GaussianBlur(rnd.uniform(0.3, 1.2)))
        x = torch.from_numpy(np.asarray(img, np.float32) / 255).permute(2, 0, 1)
        if self.train:  # brightness / contrast / saturation
            x = x * rnd.uniform(0.75, 1.25) + rnd.uniform(-0.08, 0.08)
            g = x.mean(0, keepdim=True)
            x = (g + (x - g) * rnd.uniform(0.7, 1.3)).clamp(0, 1)
        y = torch.from_numpy(np.asarray(lab, np.uint8).copy())
        return x, y


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True)
    ap.add_argument("--weights", required=True, help="torchvision lraspp_mobilenet_v3_large COCO checkpoint")
    ap.add_argument("--out", required=True)
    ap.add_argument("--size", type=int, nargs=2, default=[192, 128], metavar=("H", "W"))
    ap.add_argument("--tag", default="s192")
    ap.add_argument("--minutes", type=float, default=90)
    ap.add_argument("--batch", type=int, default=96)
    ap.add_argument("--lr", type=float, default=6e-4)
    ap.add_argument("--pos-weight", type=float, default=1.5, help="> 1 favours covering")
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--limit", type=int, default=0)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    dev = "cuda" if torch.cuda.is_available() else "cpu"
    rows = list(csv.DictReader(open(os.path.join(a.data, "index.csv"), newline="")))
    if a.limit:
        rows = rows[: a.limit]
    tr = [r for r in rows if r["holdout"] == "0"]
    ho = [r for r in rows if r["holdout"] == "1"]
    print(f"train {len(tr)} crops, holdout {len(ho)}", flush=True)
    size = tuple(a.size)
    dl = DataLoader(Crops(a.data, tr, size, True), a.batch, shuffle=True, num_workers=a.workers, drop_last=True,
                    persistent_workers=a.workers > 0, pin_memory=dev == "cuda")
    dh = DataLoader(Crops(a.data, ho, size, False), 128, num_workers=a.workers)
    net = build(a.weights).to(dev)
    mean = torch.tensor(MEAN, device=dev).view(1, 3, 1, 1)
    std = torch.tensor(STD, device=dev).view(1, 3, 1, 1)
    opt = torch.optim.AdamW(net.parameters(), lr=a.lr, weight_decay=1e-4)
    scaler = torch.cuda.amp.GradScaler(enabled=dev == "cuda")
    budget, warm = a.minutes * 60, 300
    t0, step, best, ep = time.time(), 0, -1.0, 0
    log = []

    def evaluate():
        net.eval()
        tp = fp = fn = 0.0
        rec_lo = []
        with torch.no_grad():
            for x, y in dh:
                x, y = x.to(dev), y.to(dev)
                p = torch.sigmoid(F.interpolate(low_res(net, (x - mean) / std), size=size, mode="bilinear",
                                                align_corners=False))[:, 0]
                valid, pos = y != 128, y == 255
                pr = p >= 0.5
                tp += (pr & pos).sum().item()
                fp += (pr & ~pos & valid).sum().item()
                fn += (~pr & pos).sum().item()
                for k in range(len(y)):  # per person: share of the mask above a low (covering) threshold
                    n = pos[k].sum().item()
                    if n:
                        rec_lo.append(((p[k] >= 0.2) & pos[k]).sum().item() / n)
        net.train()
        return {"iou": tp / max(1, tp + fp + fn), "recall@0.2": float(np.mean(rec_lo)),
                "p5_recall@0.2": float(np.percentile(rec_lo, 5))}

    print("start", evaluate(), flush=True)
    net.train()
    done = False
    while not done:
        ep += 1
        for x, y in dl:
            el = time.time() - t0
            if el > budget:
                done = True
                break
            lr = a.lr * min(1, (step + 1) / warm) * 0.5 * (1 + math.cos(math.pi * min(1, el / budget)))
            for g in opt.param_groups:
                g["lr"] = lr
            x, y = x.to(dev, non_blocking=True), y.to(dev, non_blocking=True)
            with torch.autocast(dev, enabled=dev == "cuda"):
                lo = F.interpolate(low_res(net, (x - mean) / std), size=size, mode="bilinear", align_corners=False)
            lo = lo[:, 0].float()
            valid = (y != 128).float()
            tgt = (y == 255).float()
            w = valid * (1 + (a.pos_weight - 1) * tgt)
            loss = (F.binary_cross_entropy_with_logits(lo, tgt, reduction="none") * w).sum() / valid.sum().clamp(min=1)
            opt.zero_grad(set_to_none=True)
            scaler.scale(loss).backward()
            scaler.step(opt)
            scaler.update()
            step += 1
            if step % 200 == 0:
                print(f"ep {ep} step {step} loss {loss.item():.4f} lr {lr:.2e} {el / 60:.1f} min", flush=True)
        ev = evaluate()
        ev.update(epoch=ep, step=step, minutes=(time.time() - t0) / 60)
        log.append(ev)
        print("eval", ev, flush=True)
        if ev["iou"] > best:
            best = ev["iou"]
            torch.save({"state_dict": net.state_dict(), "size": list(size), "mean": MEAN, "std": STD,
                        "context": CONTEXT, "eval": ev}, os.path.join(a.out, f"seg_{a.tag}.pt"))
    json.dump(log, open(os.path.join(a.out, f"seg_{a.tag}_eval.json"), "w"), indent=1)
    print("best", best, flush=True)


if __name__ == "__main__":
    main()
