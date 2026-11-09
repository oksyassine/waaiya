"""Check the streaming export against libDF features and the official offline enhance()."""
import numpy as np
import torch
from libdf import erb, erb_norm, unit_norm
from df.enhance import enhance

from export_stream import build

torch.manual_seed(0)
s, model, df_state = build()
sr, hop = s.sr, s.hop

# test signal: 3 s of noise-modulated harmonics + noise (any signal works for parity)
t = np.arange(3 * sr) / sr
sig = 0.3 * np.sin(2 * np.pi * 220 * t) * (1 + np.sin(2 * np.pi * 3 * t)) + 0.05 * np.random.default_rng(0).standard_normal(t.size)
sig = sig.astype(np.float32)

# 1) features vs libDF
spec = df_state.analysis(sig[None])  # [1, T, F] complex
a = s.alpha
ref_erb = erb_norm(erb(spec, df_state.erb_widths()), a)[0]
ref_unit = unit_norm(spec[..., : s.nb_df], a)[0]
st = s.state_init.clone()
my_erb, my_unit, my_spec = [], [], []
with torch.no_grad():
    for i in range(spec.shape[1]):
        x = torch.from_numpy(sig[i * hop:(i + 1) * hop])
        frame = torch.cat([s.get(st, "ana_mem"), x]) * s.win
        re, im = frame @ s.fwd_re, frame @ s.fwd_im
        my_spec.append(torch.complex(re, im).numpy())
        _, st = s(x, st)
        fe = s.get(st, "erb_hist")[-1].numpy()
        fsp = s.get(st, "specf_hist")[-1].numpy()
        my_erb.append(fe)
        my_unit.append(fsp[0] + 1j * fsp[1])
my_spec, my_erb, my_unit = map(np.array, (my_spec, my_erb, my_unit))
print("spec  max abs err", np.abs(my_spec - spec[0]).max(), "ref max", np.abs(spec).max())
print("erb   max abs err", np.abs(my_erb - ref_erb).max())
print("unit  max abs err", np.abs(my_unit - ref_unit).max())

# 2) streaming vs offline enhance (pad=False keeps the raw STFT delay)
off = enhance(model, df_state, torch.from_numpy(sig[None]), pad=False)[0].numpy()
st = s.state_init.clone()
outs = []
with torch.no_grad():
    for i in range(len(sig) // hop):
        y, st = s(torch.from_numpy(sig[i * hop:(i + 1) * hop]), st)
        if i < s.la:  # offline enhance() zero-pads the shifted features at the start; mimic it
            for name in ["erb_hist", "specf_hist", "c0_hist", "h_enc", "h_erb", "h_df"]:
                o, k, _ = s.offsets[name]
                st[o:o + k] = 0
        outs.append(y.numpy())
stream = np.concatenate(outs)
# streaming adds the look-ahead (2 hops) on top of the offline output timeline
d = s.la * hop
n = min(len(off), len(stream) - d)
a_, b_ = off[hop * 4:n], stream[d + hop * 4:d + n]
err = np.abs(a_ - b_).max()
snr = 10 * np.log10(np.sum(a_ ** 2) / np.sum((a_ - b_) ** 2 + 1e-20))
print(f"stream vs offline: max abs err {err:.2e}, match SNR {snr:.1f} dB, latency {s.latency_samples} samples = {1000*s.latency_samples/sr:.0f} ms")
assert snr > 80, "streaming export diverges from the official model"
print("PARITY OK")
