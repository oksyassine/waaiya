"""Exports the AudioSet tagger used by "Check for music" (docs/MUSIC_CHECK.md, approach C) to ONNX for the engine.

    python models/music/export_tagger.py --weights <mn04_as_mAP_432.pt> --out models/music/tagger_mn04.onnx

EfficientAT mn04 (MIT, pretrained on AudioSet: 527 classes, class_labels_indices.csv). The engine's C front end
(engine/src/im_detector.c: pre-emphasis 0.97, symmetric Hann window centred in the n_fft frame, power spectrum) feeds
"power" [1, 513, 100] = 1 s at 32 kHz (10 ms hop); the mel filterbank, log and the network are in the graph, and the
output "probs" [1, 527] are the sigmoid scores. Metadata im.det_* describe the front end (as for detector_v1.onnx);
im.music=1 marks the tagger.
"""
import argparse, os, sys

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "detector"))
from mobilenet import MelFrontEnd, load_pretrained  # noqa: E402

SR, N_FFT, WIN, HOP, FRAMES = 32000, 1024, 800, 320, 100


class Tagger(nn.Module):
    def __init__(self, net):
        super().__init__()
        self.front = MelFrontEnd(SR, N_FFT, WIN, HOP)
        self.net = net

    def forward(self, power):                       # (1, 513, frames) -> (1, 527)
        mel = (torch.log(self.front.fb @ power + 1e-5) + 4.5) / 5.0
        return torch.sigmoid(self.net(mel))

    def power(self, audio):                         # what the C front end computes (center=False)
        x = audio[:, 1:] - 0.97 * audio[:, :-1]
        X = torch.stft(x, N_FFT, HOP, N_FFT, self.front.window, center=False, return_complex=True)
        return X.real ** 2 + X.imag ** 2


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--weights", required=True)
    ap.add_argument("--out", default=os.path.join(HERE, "tagger_mn04.onnx"))
    a = ap.parse_args()
    import onnx
    t = Tagger(load_pretrained(a.weights, 0.4)).eval()
    torch.onnx.export(t, (torch.rand(1, N_FFT // 2 + 1, FRAMES),), a.out, input_names=["power"], output_names=["probs"],
                      opset_version=17, dynamic_axes=None)
    m = onnx.load(a.out)
    meta = {"im.detector": "1", "im.music": "1", "im.det_sample_rate": str(SR), "im.det_n_fft": str(N_FFT),
            "im.det_win": str(WIN), "im.det_hop": str(HOP), "im.det_frames": str(FRAMES), "im.det_preemph": "0.97",
            "im.det_window": "hann_symmetric_centered", "im.det_eval_every_hops": "50",
            "im.model_name": "AudioSet tagger (EfficientAT mn04_as, mAP .432)",
            "im.licence": "MIT (EfficientAT, Florian Schmid et al.; AudioSet ontology CC BY-SA 4.0)"}
    for k, v in meta.items():
        e = m.metadata_props.add()
        e.key, e.value = k, v
    onnx.save(m, a.out)
    import onnxruntime as ort
    sess = ort.InferenceSession(a.out, providers=["CPUExecutionProvider"])
    err = 0.0
    for _ in range(4):
        audio = torch.randn(1, (FRAMES - 1) * HOP + N_FFT + 1) * 10 ** float(np.random.uniform(-3, 0))
        p = t.power(audio)
        err = max(err, float(np.abs(sess.run(None, {"power": p.numpy()})[0] - t(p).detach().numpy()).max()))
    print(a.out, os.path.getsize(a.out) // 1024, "KB; ONNX Runtime vs PyTorch max abs diff", f"{err:.1e}")
    assert err < 1e-4


if __name__ == "__main__":
    main()
