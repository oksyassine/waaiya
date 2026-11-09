"""Export DeepFilterNet3 as a streaming, stateful ONNX model for the engine.

Engine model contract (every model the engine loads follows it):
  inputs : audio_in  float32 [hop]         one hop of mono audio at the model rate
           state_in  float32 [state_size]  opaque state, zeros at start
  outputs: audio_out float32 [hop]
           state_out float32 [state_size]
  metadata_props: im.contract=1, im.sample_rate, im.hop, im.state_size,
                  im.latency_samples, im.model_name, im.licence

All DSP (STFT, features, ISTFT) lives inside the graph, so the engine only
loops hops and threads state. This file uses the official `deepfilternet`
package (PyPI) for weights and layers and adds per-frame caches for the
causal convolutions, the GRU hidden states and the 2-frame look-ahead.
"""
import argparse
import inspect
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import numpy as np
import torch
import torch.nn as nn

import df_compat  # noqa: F401  (newer torchaudio)
from df.enhance import init_df
from df.deepfilternet3 import ModelParams

PAD_TYPES = (nn.ConstantPad2d,)


def run_nopad(seq: nn.Sequential, x: torch.Tensor) -> torch.Tensor:
    """Run a Conv*NormAct Sequential without its causal time padding.

    The caller supplies the past frames explicitly instead of zero padding."""
    for layer in seq:
        if isinstance(layer, PAD_TYPES):
            continue
        x = layer(x)
    return x


def norm_alpha(sr: int, hop: int, tau: float) -> float:
    """Same rounding as libDF calc_norm_alpha."""
    alpha = math.exp(-(hop / sr) / tau)
    a, precision = 1.0, 3
    while a >= 1.0:
        a = round(alpha * 10**precision) / 10**precision
        precision += 1
    return a


class StreamDFN3(nn.Module):
    def __init__(self, model: nn.Module, df_state):
        super().__init__()
        p = ModelParams()
        self.m = model.eval()
        self.sr = df_state.sr()
        self.hop = df_state.hop_size()
        self.n_fft = df_state.fft_size()
        self.nf = self.n_fft // 2 + 1
        self.nb_erb = p.nb_erb
        self.nb_df = p.nb_df
        self.order = p.df_order
        assert p.conv_lookahead == p.df_lookahead == 2, "export assumes 2-frame look-ahead"
        assert self.n_fft == 2 * self.hop
        self.la = p.df_lookahead
        self.alpha = norm_alpha(self.sr, self.hop, p.norm_tau)
        ch = p.conv_ch
        kt = p.df_pathway_kernel_size_t
        self.kt = kt
        self.ch = ch

        widths = df_state.erb_widths()
        fb = torch.zeros(self.nf, self.nb_erb)
        start = 0
        for i, w in enumerate(widths.tolist()):
            fb[start:start + w, i] = 1.0 / w  # mean power per band (libDF compute_band_corr)
            start += w
        self.register_buffer("erb_mean_fb", fb)

        n = torch.arange(self.n_fft, dtype=torch.float64)
        win = torch.sin(0.5 * math.pi * torch.sin(math.pi * (n + 0.5) / self.n_fft) ** 2)
        self.register_buffer("win", win.float())
        wnorm = 1.0 / (self.n_fft ** 2 / (2 * self.hop))
        k = torch.arange(self.nf, dtype=torch.float64)
        ang = 2 * math.pi * torch.outer(n, k) / self.n_fft  # [N, F]
        self.register_buffer("fwd_re", (torch.cos(ang) * wnorm).float())
        self.register_buffer("fwd_im", (-torch.sin(ang) * wnorm).float())
        ck = torch.full((self.nf,), 2.0, dtype=torch.float64)
        ck[0] = 1.0
        ck[-1] = 1.0
        self.register_buffer("inv_re", (torch.cos(ang).T * ck[:, None]).float())  # [F, N]
        self.register_buffer("inv_im", (-torch.sin(ang).T * ck[:, None]).float())

        erb_init = torch.linspace(-60.0, -90.0, self.nb_erb)
        unit_init = torch.linspace(0.001, 0.0001, self.nb_df)
        gru_h = 256
        n_enc = self.m.enc.emb_gru.gru.num_layers
        n_erb = self.m.erb_dec.emb_gru.gru.num_layers
        n_df = self.m.df_dec.df_gru.gru.num_layers
        assert self.m.enc.emb_gru.gru.hidden_size == gru_h

        # name -> shape; order defines the flat state layout
        self.layout = [
            ("ana_mem", (self.n_fft - self.hop,)),
            ("syn_mem", (self.n_fft - self.hop,)),
            ("erb_norm", (self.nb_erb,)),
            ("unit_norm", (self.nb_df,)),
            ("erb_hist", (2, self.nb_erb)),          # conv_kernel_inp time 3 -> 2 past frames
            ("specf_hist", (2, 2, self.nb_df)),      # [T, re/im, F]
            ("c0_hist", (kt - 1, ch, self.nb_df)),   # df_convp time kernel kt
            ("spec_hist", (2 * self.la, 2, self.nf)),  # spec frames n-4..n-1, [T, re/im, F]
            ("h_enc", (n_enc, 1, gru_h)),
            ("h_erb", (n_erb, 1, gru_h)),
            ("h_df", (n_df, 1, gru_h)),
        ]
        self.offsets = {}
        off = 0
        for name, shape in self.layout:
            size = int(np.prod(shape))
            self.offsets[name] = (off, size, shape)
            off += size
        self.state_size = off
        init = torch.zeros(self.state_size)
        o, s, _ = self.offsets["erb_norm"]
        init[o:o + s] = erb_init
        o, s, _ = self.offsets["unit_norm"]
        init[o:o + s] = unit_init
        self.register_buffer("state_init", init)
        # algorithmic delay: STFT overlap (n_fft - hop) + look-ahead frames
        self.latency_samples = (self.n_fft - self.hop) + self.la * self.hop

    def get(self, state, name):
        o, s, shape = self.offsets[name]
        return state[o:o + s].reshape(shape)

    def forward(self, audio_in: torch.Tensor, state_in: torch.Tensor):
        m = self.m
        a = self.alpha
        ana_mem = self.get(state_in, "ana_mem")
        syn_mem = self.get(state_in, "syn_mem")
        erb_norm = self.get(state_in, "erb_norm")
        unit_norm = self.get(state_in, "unit_norm")
        erb_hist = self.get(state_in, "erb_hist")
        specf_hist = self.get(state_in, "specf_hist")
        c0_hist = self.get(state_in, "c0_hist")
        spec_hist = self.get(state_in, "spec_hist")
        h_enc = self.get(state_in, "h_enc")
        h_erb = self.get(state_in, "h_erb")
        h_df = self.get(state_in, "h_df")

        # analysis
        frame = torch.cat([ana_mem, audio_in]) * self.win
        re = frame @ self.fwd_re
        im = frame @ self.fwd_im

        # features (libDF erb + band_mean_norm_erb, band_unit_norm)
        erb = (re * re + im * im) @ self.erb_mean_fb
        erb_db = 10.0 * torch.log10(erb + 1e-10)
        erb_norm_new = erb_db * (1 - a) + erb_norm * a
        feat_erb = (erb_db - erb_norm_new) / 40.0
        re_l = re[: self.nb_df]
        im_l = im[: self.nb_df]
        mag = torch.sqrt(re_l * re_l + im_l * im_l)
        unit_new = mag * (1 - a) + unit_norm * a
        sq = torch.sqrt(unit_new)
        feat_spec = torch.stack([re_l / sq, im_l / sq])  # [2, F']

        # encoder (convs see frames n-2..n, i.e. the 2-frame look-ahead)
        fe = torch.cat([erb_hist, feat_erb[None]]).reshape(1, 1, 3, self.nb_erb)
        e0 = run_nopad(m.enc.erb_conv0, fe)
        e1 = m.enc.erb_conv1(e0)
        e2 = m.enc.erb_conv2(e1)
        e3 = m.enc.erb_conv3(e2)
        fs = torch.cat([specf_hist, feat_spec[None]]).permute(1, 0, 2).reshape(1, 2, 3, self.nb_df)
        c0 = run_nopad(m.enc.df_conv0, fs)  # [1, ch, 1, F']
        c1 = m.enc.df_conv1(c0)
        cemb = m.enc.df_fc_emb(c1.permute(0, 2, 3, 1).flatten(2))
        emb = m.enc.combine(e3.permute(0, 2, 3, 1).flatten(2), cemb)
        emb, h_enc_new = m.enc.emb_gru(emb, h_enc)

        # ERB decoder
        emb_d, h_erb_new = m.erb_dec.emb_gru(emb, h_erb)
        f8 = e3.shape[3]
        emb_d = emb_d.view(1, 1, f8, -1).permute(0, 3, 1, 2)
        d3 = m.erb_dec.convt3(m.erb_dec.conv3p(e3) + emb_d)
        d2 = m.erb_dec.convt2(m.erb_dec.conv2p(e2) + d3)
        d1 = m.erb_dec.convt1(m.erb_dec.conv1p(e1) + d2)
        mask = m.erb_dec.conv0_out(m.erb_dec.conv0p(e0) + d1)  # [1,1,1,E]

        # DF decoder
        c, h_df_new = m.df_dec.df_gru(emb, h_df)
        if m.df_dec.df_skip is not None:
            c = c + m.df_dec.df_skip(emb)
        c0_seq = torch.cat([c0_hist, c0[0, :, 0][None]]).permute(1, 0, 2).reshape(1, self.ch, self.kt, self.nb_df)
        c0p = run_nopad(m.df_dec.df_convp, c0_seq).permute(0, 2, 3, 1)  # [1,1,F',O*2]
        c = m.df_dec.df_out(c).view(1, 1, self.nb_df, self.order * 2) + c0p
        coefs = c.view(self.nb_df, self.order, 2)  # [F', O, re/im]

        # apply to spectrum frame n-2
        spec_cur = torch.stack([re, im])[None]  # [1, 2, F]
        spec_win = torch.cat([spec_hist, spec_cur])  # [5, 2, F] frames n-4..n
        target = spec_win[self.la]  # [2, F]
        gain = mask.reshape(1, self.nb_erb) @ m.mask.erb_inv_fb  # [1, F]
        out_re = target[0] * gain[0]
        out_im = target[1] * gain[0]
        sw = spec_win[:, :, : self.nb_df]  # [O, 2, F']
        cr = coefs[:, :, 0].T  # [O, F']
        ci = coefs[:, :, 1].T
        df_re = (sw[:, 0] * cr - sw[:, 1] * ci).sum(0)
        df_im = (sw[:, 0] * ci + sw[:, 1] * cr).sum(0)
        out_re = torch.cat([df_re, out_re[self.nb_df:]])
        out_im = torch.cat([df_im, out_im[self.nb_df:]])

        # synthesis
        y = (out_re @ self.inv_re + out_im @ self.inv_im) * self.win
        hop = self.hop
        audio_out = y[:hop] + syn_mem
        new_state = torch.cat([
            audio_in,
            y[hop:],
            erb_norm_new,
            unit_new,
            torch.cat([erb_hist[1:], feat_erb[None]]).flatten(),
            torch.cat([specf_hist[1:], feat_spec[None]]).flatten(),
            torch.cat([c0_hist[1:], c0[0, :, 0][None]]).flatten(),
            spec_win[1:].flatten(),
            h_enc_new.flatten(),
            h_erb_new.flatten(),
            h_df_new.flatten(),
        ])
        return audio_out, new_state


def build(checkpoint: str = ""):
    model, df_state, _ = init_df(log_level="ERROR")
    if checkpoint:  # fine-tuned weights from models/voice/train.py
        model.load_state_dict(torch.load(checkpoint, map_location="cpu")["model"])
    model = model.cpu().eval()
    return StreamDFN3(model, df_state), model, df_state


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="dfn3_stream.onnx")
    ap.add_argument("--checkpoint", default="", help="fine-tuned weights (models/voice/train.py)")
    ap.add_argument("--name", default="DeepFilterNet3 (speech mode)")
    ap.add_argument("--keeps", default="speech")
    args = ap.parse_args()
    s, _, _ = build(args.checkpoint)
    x = torch.zeros(s.hop)
    st = s.state_init.clone()
    with torch.no_grad():
        s(x, st)
        torch.onnx.export(
            s, (x, st), args.out, input_names=["audio_in", "state_in"],
            output_names=["audio_out", "state_out"], opset_version=17, do_constant_folding=True,
            **({"dynamo": False} if "dynamo" in inspect.signature(torch.onnx.export).parameters else {}),
        )
    import onnx
    mp = onnx.load(args.out)
    meta = {
        "im.contract": "1", "im.sample_rate": str(s.sr), "im.hop": str(s.hop),
        "im.state_size": str(s.state_size), "im.latency_samples": str(s.latency_samples),
        "im.model_name": args.name, "im.licence": "MIT OR Apache-2.0",
        "im.keeps": args.keeps,
    }
    for k, v in meta.items():
        e = mp.metadata_props.add()
        e.key, e.value = k, v
    onnx.save(mp, args.out)
    s.state_init.numpy().astype("<f4").tofile(args.out.replace(".onnx", ".state_init.bin"))
    print(f"exported {args.out}: state_size={s.state_size} latency={s.latency_samples} samples")


if __name__ == "__main__":
    main()
