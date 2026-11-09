"""The batched training front end must match libDF (and therefore the streaming export)."""
import numpy as np, torch
from libdf import erb, erb_norm, unit_norm
from df.enhance import init_df
from train import FrontEnd

model, st, _ = init_df(log_level="ERROR")
fe = FrontEnd(st, model.nb_df, "cpu")
rng = np.random.default_rng(0)
x = (0.1 * rng.standard_normal(48000 * 2)).astype(np.float32)
ref = st.analysis(x[None])[0]
X = fe.stft(torch.from_numpy(x[None]))[0].numpy()
n = min(len(ref), len(X))
print("stft max err", np.abs(ref[:n] - X[:n]).max())
fe_erb, fe_spec = fe.features(torch.from_numpy(X[None]))
r_erb = erb_norm(erb(ref[None], st.erb_widths()), fe.alpha)[0]
r_un = unit_norm(ref[None, :, : model.nb_df], fe.alpha)[0]
print("erb feat max err", np.abs(fe_erb[0, 0].numpy()[:n] - r_erb[:n]).max())
print("unit feat max err", np.abs(torch.view_as_complex(fe_spec[0, 0]).numpy()[:n] - r_un[:n]).max())
y = fe.istft(torch.from_numpy(X[None]), len(x))[0].numpy()
err = np.abs(y[960:-960] - x[960:-960]).max()
print("istft(stft(x)) reconstruction max err", err)
assert err < 1e-4
print("FRONTEND OK")
