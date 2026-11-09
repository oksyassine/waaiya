"""Make smaller variants of a streaming voice model that follows the engine model contract.

Usage (from the repo root):
  PYTHONNOUSERSITE=1 .venv/bin/python models/shrink.py IN.onnx --fp16 --int8 [-o OUTDIR]
  options: --fp32 (lossless variant), --fp16-mode weights|compute,
           --int8-mode weights|dynamic|dynamic-all, --keep-float NAME[,NAME], --no-dft

Every variant keeps the contract of the input model: inputs audio_in[hop] and
state_in[state_size], outputs audio_out and state_out, all float32 at the boundary, and the
im.* metadata (re-added after conversion; im.model_name = <stem>_<variant>, plus
im.precision). The sidecar <stem>.state_init.bin is copied next to each variant as
<stem>_<variant>.state_init.bin. Each variant is loaded and checked against the input model
when written. Results for DFN3 are in eval/results/shrink.md.

Steps shared by the default variants:
  DFT rebuild: STFT/ISTFT basis matrices stored in the graph (cos/sin tables, ~46 % of DFN3's
      weights) are replaced by Range/Mod/Cos/Sin nodes that rebuild them. ORT constant-folds
      them when the session loads: lossless (float32 rounding), no run-time cost. --no-dft skips.
  DSP kept float: weights of plain MatMul nodes that are not named like a layer weight
      (ERB filterbanks, any DFT matrix not rebuilt) are never quantized; add names with --keep-float.

Variants:
  fp32               (--fp32) DFT rebuild only. Lossless.
  fp16  weights      (default) float weights stored float16, Cast back to float32 at load:
                     math stays float32, speed unchanged, output ~60 dB SNR vs input model.
  fp16  compute      (--fp16-mode compute) onnxconverter-common float16, keep_io_types=True,
                     ops without a CPU float16 kernel kept float32. Breaks DFN3 (float16
                     spectra underflow) and is slower on CPU: kept only for comparison.
  int8  weights      (default) weight-only int8: per-output-channel symmetric int8 stored,
                     Cast + Mul back to float32 at load (folded; DequantizeLinear is not
                     folded by ORT and would cost ~25 % speed). Covers GRU/Conv/Einsum/MatMul.
  int8  dynamic      (--int8-mode dynamic) onnxruntime quantize_dynamic on the supported
                     layers (Conv, MatMul), DSP excluded. ORT has no integer GRU/Einsum.
  int8  dynamic-all  (--int8-mode dynamic-all) the same with nothing excluded: naive baseline.
"""
import argparse
import os
import shutil
import sys
import tempfile

import numpy as np
import onnx
from onnx import helper, numpy_helper, TensorProto

CONTRACT_KEYS = ("im.contract", "im.sample_rate", "im.hop", "im.state_size", "im.latency_samples",
                 "im.model_name", "im.keeps", "im.licence")
MIN_WEIGHT = 1024  # initializers smaller than this (biases, norms) stay float32


def dsp_initializers(model: onnx.ModelProto) -> set:
    """Initializers that multiply the raw signal / spectrum: STFT, ISTFT, ERB filterbanks.

    Found structurally: weights of MatMul nodes that are not inside a learned layer. In DFN3
    exports these are fwd_re/fwd_im/inv_re/inv_im/erb_mean_fb/m.mask.erb_inv_fb; in other models
    the same rule (MatMul with a constant whose name does not look like a layer weight) applies.
    Override with --keep-float to list names explicitly."""
    inits = {t.name for t in model.graph.initializer}
    out = set()
    for n in model.graph.node:
        if n.op_type == "MatMul":
            for i in n.input:
                if i in inits and not i.endswith((".weight", ".bias")):
                    out.add(i)
    for name in inits:
        low = name.lower()
        if any(k in low for k in ("fwd_re", "fwd_im", "inv_re", "inv_im", "erb_fb", "erb_inv_fb",
                                  "erb_mean_fb", "window", "stft", "istft", "dft")):
            out.add(name)
    return out


def regenerate_dft(model: onnx.ModelProto) -> list:
    """Replace stored DFT basis matrices (STFT/ISTFT inside the graph) by a few nodes that
    rebuild them: scale[k] * cos|sin(2*pi*((n*k) mod N)/N). ORT constant-folds these at session
    load, so run time is unchanged and the numbers equal the stored ones to float32 rounding.
    A matrix qualifies when it is (N, N/2+1) or (N/2+1, N) and fits such a basis with a per-bin
    scale to 1e-5 relative. Returns the names replaced."""
    g = model.graph
    nodes, keep, done = [], [], []
    cache = {}

    def c(name, arr):
        g.initializer.append(numpy_helper.from_array(np.asarray(arr), name))
        return name

    for t in list(g.initializer):
        a = numpy_helper.to_array(t)
        if t.data_type != TensorProto.FLOAT or a.ndim != 2:
            continue
        for N, K, tr in ((a.shape[0], a.shape[1], False), (a.shape[1], a.shape[0], True)):
            if N < 16 or K != N // 2 + 1:
                continue
            T = a.T.astype(np.float64) if tr else a.astype(np.float64)
            ph = 2 * np.pi * ((np.arange(N)[:, None] * np.arange(K)[None, :]) % N) / N
            for fn, B in (("Cos", np.cos(ph)), ("Sin", np.sin(ph))):
                den = (B * B).sum(0)
                s = np.where(den > 1e-9, (T * B).sum(0) / np.maximum(den, 1e-9), 0.0)
                if np.abs(T - B * s).max() <= 1e-5 * np.abs(T).max():
                    break
            else:
                continue
            p = f"__dft{N}"
            if N not in cache:  # shared phase tensor (N, K) float = 2*pi*((n*k) mod N)/N
                i64 = lambda v: np.array(v, np.int64)
                nodes += [
                    helper.make_node("Range", [c(p + "_z", i64(0)), c(p + "_N", i64(N)), c(p + "_one", i64(1))], [p + "_n"]),
                    helper.make_node("Range", [p + "_z", c(p + "_K", i64(K)), p + "_one"], [p + "_k"]),
                    helper.make_node("Unsqueeze", [p + "_n", c(p + "_ax1", i64([1]))], [p + "_nc"]),
                    helper.make_node("Unsqueeze", [p + "_k", c(p + "_ax0", i64([0]))], [p + "_kr"]),
                    helper.make_node("Mul", [p + "_nc", p + "_kr"], [p + "_nk"]),
                    helper.make_node("Mod", [p + "_nk", p + "_N"], [p + "_m"]),
                    helper.make_node("Cast", [p + "_m"], [p + "_mf"], to=TensorProto.FLOAT),
                    helper.make_node("Mul", [p + "_mf", c(p + "_w", np.float32(2 * np.pi / N))], [p + "_ph"]),
                ]
                cache[N] = p + "_ph"
            q = f"{t.name}__dft"
            out = q + "_nt" if tr else t.name
            nodes += [helper.make_node(fn, [cache[N]], [q + "_b"]),
                      helper.make_node("Mul", [q + "_b", c(q + "_s", s.astype(np.float32))], [out])]
            if tr:
                nodes.append(helper.make_node("Transpose", [out], [t.name], perm=[1, 0]))
            g.initializer.remove(t)
            done.append(t.name)
            break
    for i, n in enumerate(nodes):
        n.name = n.output[0] + "__node"
    rest = list(g.node)
    del g.node[:]
    g.node.extend(nodes + rest)
    return done


def nodes_using(model, names):
    return [n.name for n in model.graph.node if any(i in names for i in n.input)]


def set_meta(model: onnx.ModelProto, src_meta: dict, variant: str, stem: str):
    meta = dict(src_meta)
    meta["im.model_name"] = f"{stem}_{variant}"
    meta["im.precision"] = variant
    del model.metadata_props[:]
    for k, v in meta.items():
        e = model.metadata_props.add()
        e.key, e.value = k, v
    missing = [k for k in CONTRACT_KEYS if k not in meta]
    if missing:
        print(f"warning: source model lacks metadata {missing}", file=sys.stderr)


def save(model, path):
    onnx.checker.check_model(model)
    onnx.save(model, path)


# ---------------------------------------------------------------- fp16

def fp16_weights(model: onnx.ModelProto) -> onnx.ModelProto:
    """Store float initializers >= MIN_WEIGHT as float16 + Cast(to float)."""
    g = model.graph
    new_inits, casts = [], []
    for t in g.initializer:
        a = numpy_helper.to_array(t)
        if t.data_type == TensorProto.FLOAT and a.size >= MIN_WEIGHT:
            h = numpy_helper.from_array(a.astype(np.float16), t.name + "__fp16")
            new_inits.append(h)
            casts.append(helper.make_node("Cast", [h.name], [t.name], to=TensorProto.FLOAT,
                                          name=t.name + "__cast"))
        else:
            new_inits.append(t)
    del g.initializer[:]
    g.initializer.extend(new_inits)
    nodes = casts + list(g.node)
    del g.node[:]
    g.node.extend(nodes)
    return model


def fp16_compute(path: str) -> onnx.ModelProto:
    """Full float16 conversion (onnxconverter-common, keep_io_types=True). Ops for which this
    ONNX Runtime build has no float16 CPU kernel are found by trial and kept float32."""
    import re
    import onnxruntime as ort
    from onnxconverter_common import float16
    block = list(float16.DEFAULT_OP_BLOCK_LIST)
    for _ in range(50):
        m = float16.convert_float_to_float16(onnx.load(path), keep_io_types=True, op_block_list=block)
        try:
            ort.InferenceSession(m.SerializeToString(), providers=["CPUExecutionProvider"])
            return m
        except Exception as e:
            hit = re.search(r"implementation for (\w+)\(", str(e))
            if not hit or hit.group(1) in block:
                raise
            print(f"fp16: no CPU float16 kernel for {hit.group(1)}, keeping it float32", file=sys.stderr)
            block.append(hit.group(1))
    raise RuntimeError("fp16 conversion did not converge")


# ---------------------------------------------------------------- int8

def int8_weights(model: onnx.ModelProto, keep_float: set) -> onnx.ModelProto:
    """Weight-only int8: symmetric per-output-channel int8, rebuilt as Cast(int8->float) * scale."""
    g = model.graph
    consumers = {}
    for n in g.node:
        for i in n.input:
            consumers.setdefault(i, []).append(n)
    new_inits, deq = [], []
    for t in g.initializer:
        a = numpy_helper.to_array(t)
        ops = {n.op_type for n in consumers.get(t.name, [])}
        if (t.data_type != TensorProto.FLOAT or a.size < MIN_WEIGHT or t.name in keep_float
                or not ops or not ops <= {"Conv", "ConvTranspose", "GRU", "LSTM", "MatMul", "Gemm", "Einsum"}):
            new_inits.append(t)
            continue
        # One scale per output channel (per output row for GRU/LSTM, per group and output
        # for grouped-linear Einsum weights [G, I, O]).
        nd = a.ndim
        if ops & {"GRU", "LSTM"}:
            keep = (0, 1)
        elif "ConvTranspose" in ops:
            keep = (1,)
        elif "Conv" in ops:
            keep = (0,)
        elif "Einsum" in ops and nd >= 3:
            keep = (0, nd - 1)
        else:
            keep = (nd - 1,)
        red = tuple(i for i in range(nd) if i not in keep)
        amax = np.abs(a).max(axis=red, keepdims=True)
        scale = np.where(amax > 0, amax / 127.0, 1.0).astype(np.float32)
        q = np.clip(np.round(a / scale), -127, 127).astype(np.int8)
        qi = numpy_helper.from_array(q, t.name + "__q")
        si = numpy_helper.from_array(scale, t.name + "__scale")
        new_inits += [qi, si]
        # Cast + Mul rather than DequantizeLinear: ORT constant-folds these at load, but keeps
        # DequantizeLinear unfolded (it waits for QDQ fusion), which costs ~25 % run time.
        deq += [helper.make_node("Cast", [qi.name], [t.name + "__f"], to=TensorProto.FLOAT, name=t.name + "__cast"),
                helper.make_node("Mul", [t.name + "__f", si.name], [t.name], name=t.name + "__dq")]
    del g.initializer[:]
    g.initializer.extend(new_inits)
    nodes = deq + list(g.node)
    del g.node[:]
    g.node.extend(nodes)
    return model


def int8_dynamic(in_path: str, out_path: str, exclude_nodes: list):
    from onnxruntime.quantization import quantize_dynamic, QuantType
    from onnxruntime.quantization.shape_inference import quant_pre_process
    with tempfile.TemporaryDirectory() as td:
        pre = os.path.join(td, "pre.onnx")
        try:
            quant_pre_process(in_path, pre, skip_symbolic_shape=True)
        except Exception as e:  # pre-processing is an optimisation, not required
            print(f"quant_pre_process skipped: {e}", file=sys.stderr)
            shutil.copy(in_path, pre)
        # ORT CPU ConvInteger only takes uint8 x uint8, so weights are uint8 here.
        quantize_dynamic(pre, out_path, weight_type=QuantType.QUInt8, per_channel=True,
                         nodes_to_exclude=exclude_nodes,
                         extra_options={"MatMulConstBOnly": True})


# ---------------------------------------------------------------- main

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("model", help="input .onnx (engine contract)")
    ap.add_argument("--fp16", action="store_true")
    ap.add_argument("--int8", action="store_true")
    ap.add_argument("--fp32", action="store_true", help="lossless variant: only rebuild DFT bases in-graph")
    ap.add_argument("--no-dft", action="store_true", help="keep stored DFT basis matrices as they are")
    ap.add_argument("--fp16-mode", choices=["weights", "compute"], default="weights")
    ap.add_argument("--int8-mode", choices=["weights", "dynamic", "dynamic-all"], default="weights")
    ap.add_argument("--keep-float", default="", help="comma-separated extra initializer names to keep float32")
    ap.add_argument("-o", "--out-dir", default=None, help="output directory (default: next to input)")
    a = ap.parse_args(argv)
    if not (a.fp16 or a.int8 or a.fp32):
        ap.error("choose --fp16 and/or --int8 (and/or --fp32)")

    src = onnx.load(a.model)
    src_meta = {p.key: p.value for p in src.metadata_props}
    stem = os.path.basename(a.model)[:-5]
    out_dir = a.out_dir or os.path.dirname(os.path.abspath(a.model))
    os.makedirs(out_dir, exist_ok=True)
    state_init = a.model[:-5] + ".state_init.bin"
    keep_float = dsp_initializers(src) | {s for s in a.keep_float.split(",") if s}
    print(f"never quantized (DSP): {sorted(keep_float)}")

    def dft(m):
        if not a.no_dft:
            names = regenerate_dft(m)
            print(f"DFT bases rebuilt in-graph instead of stored: {names or 'none found'}")

    jobs = ["fp32"] if a.fp32 else []
    if a.fp16:
        jobs.append("fp16" if a.fp16_mode == "weights" else "fp16c")
    if a.int8:
        jobs.append({"weights": "int8", "dynamic": "int8dyn", "dynamic-all": "int8dynall"}[a.int8_mode])

    for variant in jobs:
        out = os.path.join(out_dir, f"{stem}_{variant}.onnx")
        if variant == "fp16":
            m = onnx.load(a.model)
            dft(m)
            m = fp16_weights(m)
        elif variant == "fp16c":
            m = fp16_compute(a.model)
        elif variant == "int8":
            m = onnx.load(a.model)
            dft(m)
            m = int8_weights(m, keep_float)
        elif variant == "fp32":
            m = onnx.load(a.model)
            dft(m)
        else:
            excl = [] if variant == "int8dynall" else nodes_using(src, keep_float)
            int8_dynamic(a.model, out, excl)
            m = onnx.load(out)
        set_meta(m, src_meta, variant, stem)
        save(m, out)
        if os.path.exists(state_init):
            shutil.copy(state_init, out[:-5] + ".state_init.bin")
        else:
            print(f"warning: no {state_init}; runtime will start from zeros", file=sys.stderr)
        verify(out, a.model)


def verify(path, ref_path, seconds=3.0):
    """Load the variant, check the contract, and report output SNR against the input model."""
    import onnxruntime as ort
    so = ort.SessionOptions()
    so.intra_op_num_threads = 1
    s = ort.InferenceSession(path, so, providers=["CPUExecutionProvider"])
    r = ort.InferenceSession(ref_path, so, providers=["CPUExecutionProvider"])
    meta = s.get_modelmeta().custom_metadata_map
    for k in CONTRACT_KEYS:
        assert k in meta or k in ("im.keeps", "im.licence"), f"{path}: missing {k}"
    ins = {i.name: i.type for i in s.get_inputs()}
    outs = {o.name: o.type for o in s.get_outputs()}
    assert ins == {"audio_in": "tensor(float)", "state_in": "tensor(float)"}, ins
    assert outs == {"audio_out": "tensor(float)", "state_out": "tensor(float)"}, outs
    hop, n = int(meta["im.hop"]), int(meta["im.state_size"])
    init_p = path[:-5] + ".state_init.bin"
    st0 = np.fromfile(init_p, "<f4") if os.path.exists(init_p) else np.zeros(n, np.float32)
    rng = np.random.default_rng(0)
    sr = int(meta["im.sample_rate"])
    t = np.arange(int(seconds * sr)) / sr
    x = (0.1 * np.sin(2 * np.pi * 220 * t) * (1 + np.sin(2 * np.pi * 3 * t)) + 0.02 * rng.standard_normal(t.size)).astype(np.float32)
    ys, yr, a_st, b_st = [], [], st0.copy(), st0.copy()
    for k in range(0, x.size - hop + 1, hop):
        h = x[k:k + hop]
        y, a_st = s.run(None, {"audio_in": h, "state_in": a_st})
        z, b_st = r.run(None, {"audio_in": h, "state_in": b_st})
        ys.append(y), yr.append(z)
    y, z = np.concatenate(ys), np.concatenate(yr)
    assert a_st.shape == (n,), a_st.shape
    snr = 10 * np.log10((z ** 2).sum() / (((y - z) ** 2).sum() + 1e-20) + 1e-20)
    print(f"{path}: {os.path.getsize(path) / 1e6:.2f} MB, model_name={meta['im.model_name']}, "
          f"output SNR vs input model {snr:.1f} dB")


if __name__ == "__main__":
    main()
