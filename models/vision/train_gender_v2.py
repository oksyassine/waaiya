"""Woman/man person-crop classifier v2 for the screen blur (crops from prep_train_crops.py), GPU or CPU.

Differences from train_gender.py (v1):
  - data: Open Images *train* split, crops cut from the 640-px frame; the runtime's 10% context is applied here
    around a jittered box (detector boxes are not the annotators' boxes);
  - strong low-resolution augmentation (a 16:9 video in a portrait phone shows people 3-4x smaller);
  - loss on the decision the blur makes: binary cross-entropy on p(man)+p(boy), plus a small 4-class term
    (the 4 labels stay: the C side sums man+boy); no label smoothing (it pulls confident scores down, toward the male_clear threshold);
  - checkpoint selection on a holdout of *train* images (never on the validation images the scorer uses):
    men left clear when at most 0.5% of women/girls are left clear;
  - pretrained weights only from Hugging Face safetensors (no pickles); mean/std from the timm pretrained_cfg;
  - wall-clock budget with warmup + cosine by time, EMA weights, AMP on CUDA.

    python models/vision/train_gender_v2.py --data /kaggle/tmp/gcrops --out out --arch mobilenetv3_large_100 \
        --tag miil_in21k_ft_in1k --minutes 90

Writes <out>/<name>.pt ({state_dict, labels, size, mean, std, arch}: loadable with weights_only=True, input of
export_vision.py gender) and <out>/<name>_eval.json.
"""
import argparse
import copy
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
MALE, FEMALE = [1, 3], [0, 2]
CONTEXT = 0.10  # im_vision.c classify()


def read_index(root):
    tr, ho = [], []
    with open(os.path.join(root, "index.csv"), newline="") as f:
        for r in csv.DictReader(f):
            item = (os.path.join(root, r["crop"]), LABELS.index(r["label"]),
                    tuple(float(r[k]) for k in ("bx0", "by0", "bx1", "by1")), float(r["h_frame"]))
            (ho if r["holdout"] == "1" else tr).append(item)
    return tr, ho


class Crops(Dataset):
    """uint8 CHW crops, stretched to the model input like the C side. mode: train | eval | lowres (eval at 1/3)."""

    def __init__(self, items, size, mode):
        self.items, self.size, self.mode = items, size, mode

    def __len__(self):
        return len(self.items)

    def __getitem__(self, i):
        path, y, (bx0, by0, bx1, by1), _ = self.items[i]
        im = Image.open(path).convert("RGB")
        W, H = im.size
        x0, y0, x1, y1 = bx0 * W, by0 * H, bx1 * W, by1 * H
        bw, bh = x1 - x0, y1 - y0
        train = self.mode == "train"
        if train:  # detector-like box error: each side moves by ~5% of the box size
            x0 += random.gauss(0, 0.05) * bw
            x1 += random.gauss(0, 0.05) * bw
            y0 += random.gauss(0, 0.05) * bh
            y1 += random.gauss(0, 0.05) * bh
            if x1 - x0 < 2 or y1 - y0 < 2:
                x0, y0, x1, y1 = bx0 * W, by0 * H, bx1 * W, by1 * H
            bw, bh = x1 - x0, y1 - y0
        c = (max(0, x0 - CONTEXT * bw), max(0, y0 - CONTEXT * bh), min(W, x1 + CONTEXT * bw), min(H, y1 + CONTEXT * bh))
        im = im.crop(tuple(int(round(v)) for v in c))
        f = 1.0
        if train and random.random() < 0.5:  # smaller on screen: portrait video strips, small capture sizes
            f = math.exp(random.uniform(math.log(0.2), 0))
        elif self.mode == "lowres":
            f = 1 / 3
        if f < 1:
            im = im.resize((max(3, round(im.size[0] * f)), max(3, round(im.size[1] * f))), Image.BILINEAR)
        if train:
            if random.random() < 0.5:
                im = im.transpose(Image.FLIP_LEFT_RIGHT)
            if random.random() < 0.1:
                im = im.filter(ImageFilter.GaussianBlur(random.uniform(0.5, 1.5)))
            if random.random() < 0.05:
                im = im.convert("L").convert("RGB")
        h, w = self.size
        im = im.resize((w, h), Image.BILINEAR)  # stretched, like im_vision.c classify()
        return torch.from_numpy(np.asarray(im, np.uint8).copy()).permute(2, 0, 1), y


def to_input(x, mean, std, train):
    x = x.float() / 255.0
    if train:  # per-sample brightness / contrast / colour cast
        b = x.shape[0]
        g = torch.empty(b, 1, 1, 1, device=x.device).uniform_(0.7, 1.3)
        m = x.mean((1, 2, 3), keepdim=True)
        x = (x - m) * torch.empty(b, 1, 1, 1, device=x.device).uniform_(0.7, 1.3) + m
        x = x * g * torch.empty(b, 3, 1, 1, device=x.device).uniform_(0.92, 1.08)
        x = x.clamp(0, 1)
    return (x - mean) / std


def male_logit(logits):
    return torch.logsumexp(logits[:, MALE], 1) - torch.logsumexp(logits[:, FEMALE], 1)


def metrics(pm, y):
    female = np.isin(y, FEMALE)
    pf, pmm = pm[female], pm[~female]
    order = np.concatenate([pf, pmm]).argsort().argsort() + 1
    auc = (order[len(pf):].sum() - len(pmm) * (len(pmm) + 1) / 2) / max(1, len(pf) * len(pmm))
    rep = {"n_female": int(len(pf)), "n_male": int(len(pmm)), "auc": float(auc),
           "male_vs_female_acc": float(((pm >= 0.5) == ~female).mean()), "at_women_clear": {}, "thresholds": {}}
    for q in (0.0025, 0.005, 0.01):
        t = float(np.sort(pf)[int(math.ceil((1 - q) * len(pf))) - 1]) if len(pf) else 1.0
        rep["at_women_clear"][str(q)] = {"male_clear": t, "men_left_clear": float((pmm > t).mean())}
    for t in (0.9, 0.95, 0.98, 0.99, 0.995, 0.999):
        rep["thresholds"][str(t)] = {"women_left_clear": float((pf >= t).mean()), "men_left_clear": float((pmm >= t).mean())}
    return rep


@torch.no_grad()
def predict(net, loader, mean, std, dev, amp):
    net.eval()
    ps, ys = [], []
    for x, y in loader:
        with torch.autocast("cuda", dtype=torch.float16, enabled=amp):
            z = male_logit(net(to_input(x.to(dev, non_blocking=True), mean, std, False).float()).float())
        ps.append(torch.sigmoid(z).cpu())
        ys.append(y)
    return torch.cat(ps).numpy(), torch.cat(ys).numpy()


def build(arch, tag):
    """timm model with ImageNet weights from the Hugging Face safetensors file (no pickle)."""
    from huggingface_hub import hf_hub_download
    from safetensors.torch import load_file

    net = timm.create_model(f"{arch}.{tag}" if tag else arch, pretrained=False, num_classes=len(LABELS))
    pc = net.pretrained_cfg
    if tag:
        sd = load_file(hf_hub_download(pc["hf_hub_id"], "model.safetensors"))
        head = pc.get("classifier", "classifier")
        sd = {k: v for k, v in sd.items() if not k.startswith(head + ".")}
        missing, unexpected = net.load_state_dict(sd, strict=False)
        assert not unexpected and all(k.startswith(head + ".") for k in missing), (missing, unexpected)
    return net, list(pc.get("mean", (0.485, 0.456, 0.406))), list(pc.get("std", (0.229, 0.224, 0.225)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--arch", default="mobilenetv3_large_100")
    ap.add_argument("--tag", default="miil_in21k_ft_in1k", help="timm pretrained tag ('' = from scratch, tests)")
    ap.add_argument("--name", default=None, help="output file stem (default gender_v2_<arch>)")
    ap.add_argument("--height", type=int, default=192)
    ap.add_argument("--width", type=int, default=128)
    ap.add_argument("--minutes", type=float, default=90, help="training wall-clock budget")
    ap.add_argument("--max-steps", type=int, default=0, help="stop after this many steps (tests)")
    ap.add_argument("--epoch-size", type=int, default=0, help="samples per epoch (default: all training crops)")
    ap.add_argument("--batch", type=int, default=256)
    ap.add_argument("--lr", type=float, default=1.5e-3)
    ap.add_argument("--wd", type=float, default=0.05)
    ap.add_argument("--aux", type=float, default=0.2, help="weight of the 4-class loss")
    ap.add_argument("--ema", type=float, default=0.9995)
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--device", default="cuda" if torch.cuda.is_available() else "cpu")
    a = ap.parse_args()
    random.seed(0)
    torch.manual_seed(0)
    os.makedirs(a.out, exist_ok=True)
    name = a.name or f"gender_v2_{a.arch}"
    dev = torch.device(a.device)
    amp = dev.type == "cuda"
    size = (a.height, a.width)

    train, hold = read_index(a.data)
    counts = np.bincount([y for _, y, _, _ in train], minlength=4)
    print(f"train {dict(zip(LABELS, counts.tolist()))}, holdout {len(hold)}", flush=True)
    side = np.array([counts[0] + counts[2], counts[1] + counts[3]], np.float64)
    wts = [1.0 / side[0 if y in FEMALE else 1] for _, y, _, _ in train]
    sampler = WeightedRandomSampler(wts, num_samples=a.epoch_size or len(train), replacement=True)
    kw = dict(num_workers=a.workers, pin_memory=amp, persistent_workers=a.workers > 0)
    tl = DataLoader(Crops(train, size, "train"), batch_size=a.batch, sampler=sampler, drop_last=True, **kw)
    hl = DataLoader(Crops(hold, size, "eval"), batch_size=512, **kw)
    ll = DataLoader(Crops(hold, size, "lowres"), batch_size=512, **kw)

    net, mean_l, std_l = build(a.arch, a.tag)
    print(f"{a.arch}.{a.tag}: mean {mean_l} std {std_l}", flush=True)
    net = net.to(dev).to(memory_format=torch.channels_last)
    ema = copy.deepcopy(net).eval()
    mean = torch.tensor(mean_l, device=dev).view(1, 3, 1, 1)
    std = torch.tensor(std_l, device=dev).view(1, 3, 1, 1)
    decay, no_decay = [], []
    for n_, p in net.named_parameters():
        (no_decay if p.ndim <= 1 else decay).append(p)
    opt = torch.optim.AdamW([{"params": decay, "weight_decay": a.wd}, {"params": no_decay, "weight_decay": 0}], lr=a.lr)
    scaler = torch.cuda.amp.GradScaler(enabled=amp)
    budget = a.minutes * 60

    def lr_at(frac):  # warmup 3% of the budget, then cosine by wall time
        return frac / 0.03 if frac < 0.03 else 0.5 * (1 + math.cos(math.pi * min(1.0, (frac - 0.03) / 0.97)))

    t0, step, best, ep, done = time.time(), 0, None, 0, False
    hist = []
    while not done:
        net.train()
        tot, n = 0.0, 0
        for x, y in tl:
            frac = (time.time() - t0) / budget
            for g in opt.param_groups:
                g["lr"] = a.lr * max(0.0, lr_at(frac)) + 1e-6
            x = to_input(x.to(dev, non_blocking=True), mean, std, True).contiguous(memory_format=torch.channels_last)
            y = y.to(dev, non_blocking=True)
            with torch.autocast("cuda", dtype=torch.float16, enabled=amp):
                logits = net(x).float()
            loss = F.binary_cross_entropy_with_logits(male_logit(logits), (y % 2 == 1).float()) \
                + a.aux * F.cross_entropy(logits, y)
            opt.zero_grad(set_to_none=True)
            scaler.scale(loss).backward()
            scaler.step(opt)
            scaler.update()
            step += 1
            d = min(a.ema, (1 + step) / (10 + step))
            with torch.no_grad():
                for pe, p in zip(ema.parameters(), net.parameters()):
                    pe.mul_(d).add_(p.detach(), alpha=1 - d)
                for be, b in zip(ema.buffers(), net.buffers()):
                    be.copy_(b)
            tot += loss.item() * len(y)
            n += len(y)
            if step % 200 == 0:
                print(f"ep {ep} step {step} loss {tot / n:.4f} lr {opt.param_groups[0]['lr']:.2e} "
                      f"{time.time() - t0:.0f} s", flush=True)
            if time.time() - t0 > budget or (a.max_steps and step >= a.max_steps):
                done = True
                break
        # save before the (slower) evaluation, so a killed session still leaves weights
        meta = {"labels": LABELS, "size": list(size), "mean": mean_l, "std": std_l, "arch": a.arch}
        torch.save({"state_dict": ema.state_dict(), **meta}, os.path.join(a.out, f"{name}_last.pt"))
        rep = {"epoch": ep, "step": step, "minutes": (time.time() - t0) / 60, "train_loss": tot / max(1, n)}
        for tag_, m in (("raw", net), ("ema", ema)):
            pm, yy = predict(m, hl, mean, std, dev, amp)
            rep[tag_] = metrics(pm, yy)
        pm, yy = predict(ema, ll, mean, std, dev, amp)
        rep["ema_lowres"] = metrics(pm, yy)
        hist.append(rep)
        print(json.dumps({k: (v["at_women_clear"] | {"auc": v["auc"]} if isinstance(v, dict) else v)
                          for k, v in rep.items()}), flush=True)
        for tag_, m in (("raw", net), ("ema", ema)):
            score = rep[tag_]["at_women_clear"]["0.005"]["men_left_clear"]
            if best is None or score > best[0]:
                best = (score, ep, tag_)
                torch.save({"state_dict": m.state_dict(), **meta}, os.path.join(a.out, f"{name}.pt"))
        json.dump({"best": {"men_left_clear_at_women_0.5pct": best[0], "epoch": best[1], "weights": best[2]},
                   "arch": a.arch, "tag": a.tag, "args": vars(a), "history": hist},
                  open(os.path.join(a.out, f"{name}_eval.json"), "w"), indent=1)
        ep += 1
    print(f"best: men left clear {best[0]:.4f} at 0.5% women (epoch {best[1]}, {best[2]})", flush=True)


if __name__ == "__main__":
    main()
