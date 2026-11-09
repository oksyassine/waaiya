"""Our own implementation of the EfficientAT MobileNetV3 audio tagger (architecture from Schmid et al.,
"Efficient Large-Scale Audio Tagging via Transformer-to-CNN Knowledge Distillation", ICASSP 2023;
pretrained AudioSet weights are MIT-licensed, see efficientat/LICENSE). Parameter names match the
released checkpoints so they load with torch.load(weights_only=True) - no pickled code is executed.

Front end: the reference runs at 32 kHz (1024-pt STFT, 800-sample Hann window, hop 320). We run it at the
engine's 48 kHz with the same time/frequency grid (1536-pt STFT, 1200-sample window, hop 480 = 10 ms, so
31.25 Hz bins either way), so each 10 ms engine hop yields exactly one mel frame and nothing is resampled.
128 Kaldi mel bands 0-15 kHz, pre-emphasis 0.97, log(x+1e-5), (x+4.5)/5.  Frames are NOT centre-padded:
frame k covers samples [k*HOP, k*HOP+N_FFT), exactly what the C streaming front end computes.
"""
import torch
import torch.nn as nn
import torch.nn.functional as F
from torchaudio.compliance.kaldi import get_mel_banks

SR, N_FFT, WIN, HOP, N_MELS = 48000, 1536, 1200, 480, 128
FRAMES = 100                         # 1 s analysis window
WINDOW_SAMPLES = (FRAMES - 1) * HOP + N_FFT + 1   # +1 for the pre-emphasis tap


def make_divisible(v, d=8):
    n = max(d, int(v + d / 2) // d * d)
    return n + d if n < 0.9 * v else n


class CNA(nn.Sequential):
    """conv (0) + batch norm (1) + optional activation (2)."""

    def __init__(self, cin, cout, k=1, stride=1, groups=1, act=None):
        layers = [nn.Conv2d(cin, cout, k, stride, (k - 1) // 2, groups=groups, bias=False),
                  nn.BatchNorm2d(cout, eps=0.001, momentum=0.01)]
        if act is not None:
            layers.append(act())
        super().__init__(*layers)


class SE(nn.Module):
    """Channel squeeze-excitation (EfficientAT 'ConcurrentSEBlock' with se_dims='c')."""

    def __init__(self, c, r=4):
        super().__init__()
        s = make_divisible(c // r)
        self.conc_se_layers = nn.ModuleList([nn.Module()])
        self.conc_se_layers[0].fc1 = nn.Linear(c, s)
        self.conc_se_layers[0].fc2 = nn.Linear(s, c)

    def forward(self, x):
        se = self.conc_se_layers[0]
        w = torch.sigmoid(se.fc2(F.relu(se.fc1(x.mean((2, 3))))))
        return x * w[:, :, None, None]


class Block(nn.Module):
    def __init__(self, cin, k, cexp, cout, use_se, hs, stride):
        super().__init__()
        act = nn.Hardswish if hs else nn.ReLU
        layers = []
        if cexp != cin:
            layers.append(CNA(cin, cexp, 1, act=act))
        layers.append(CNA(cexp, cexp, k, stride, groups=cexp, act=act))
        if use_se:
            layers.append(SE(cexp))
        layers.append(CNA(cexp, cout, 1))
        self.block = nn.Sequential(*layers)
        self.res = stride == 1 and cin == cout

    def forward(self, x):
        y = self.block(x)
        return y + x if self.res else y


# input, kernel, expanded, out, SE, hard-swish, stride  (MobileNetV3-Large)
CONF = [(16, 3, 16, 16, 0, 0, 1), (16, 3, 64, 24, 0, 0, 2), (24, 3, 72, 24, 0, 0, 1), (24, 5, 72, 40, 1, 0, 2),
        (40, 5, 120, 40, 1, 0, 1), (40, 5, 120, 40, 1, 0, 1), (40, 3, 240, 80, 0, 1, 2), (80, 3, 200, 80, 0, 1, 1),
        (80, 3, 184, 80, 0, 1, 1), (80, 3, 184, 80, 0, 1, 1), (80, 3, 480, 112, 1, 1, 1),
        (112, 3, 672, 112, 1, 1, 1), (112, 5, 672, 160, 1, 1, 2), (160, 5, 960, 160, 1, 1, 1),
        (160, 5, 960, 160, 1, 1, 1)]


class MN(nn.Module):
    def __init__(self, width=1.0, num_classes=527):
        super().__init__()
        a = lambda c: make_divisible(c * width)  # noqa: E731
        layers = [CNA(1, a(16), 3, 2, act=nn.Hardswish)]
        for cin, k, ce, co, se, hs, s in CONF:
            layers.append(Block(a(cin), k, a(ce), a(co), se, hs, s))
        last_in = a(160)
        layers.append(CNA(last_in, 6 * last_in, 1, act=nn.Hardswish))
        self.features = nn.Sequential(*layers)
        self.classifier = nn.Sequential(nn.AdaptiveAvgPool2d(1), nn.Flatten(1), nn.Linear(6 * last_in, a(1280)),
                                        nn.Hardswish(), nn.Dropout(0.2), nn.Linear(a(1280), num_classes))

    def embed(self, mel):  # mel: (B, 128, T) -> (B, C) pooled features
        return self.features(mel.unsqueeze(1)).mean((2, 3))

    def forward(self, mel):
        return self.classifier(self.features(mel.unsqueeze(1)))


class MelFrontEnd(nn.Module):
    def __init__(self, sr=SR, n_fft=N_FFT, win=WIN, hop=HOP, center=False):
        super().__init__()
        self.n_fft, self.hop, self.center = n_fft, hop, center
        fb, _ = get_mel_banks(N_MELS, n_fft, float(sr), 0.0, 15000.0, 100.0, -500.0, 1.0)
        self.register_buffer("fb", F.pad(fb, (0, 1)), persistent=False)          # (128, 513)
        w = torch.hann_window(win, periodic=False)
        self.register_buffer("window", F.pad(w, ((n_fft - win) // 2,) * 2), persistent=False)

    def forward(self, x):  # x: (B, n) -> (B, 128, frames)
        x = x[:, 1:] - 0.97 * x[:, :-1]
        X = torch.stft(x, self.n_fft, self.hop, self.n_fft, self.window, center=self.center, return_complex=True)
        return (torch.log(self.fb @ X.abs().pow(2) + 1e-5) + 4.5) / 5.0


def load_pretrained(path, width):
    m = MN(width)
    sd = torch.load(path, map_location="cpu", weights_only=True)
    missing, unexpected = m.load_state_dict(sd, strict=False)
    bad = [k for k in missing if "num_batches" not in k] + [k for k in unexpected if "num_batches" not in k]
    if bad:
        raise RuntimeError(f"checkpoint mismatch: {bad[:10]}")
    return m.eval()
