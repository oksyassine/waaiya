"""A tiny made-up model that follows the ASR contract (engine/include/im_captions.h), for the engine's tests.

It cuts the audio into 80 ms frames and "hears" a word in each loud frame: "▁سلام" when the frame's mean is above
zero, "▁عليكم" when it is below, blank when the frame is quiet. engine/test/test_asr.c feeds it steps of +0.2 and
-0.2 and checks the text. It also writes a model without the contract's metadata, which the engine must refuse.

Usage: python3 models/asr/make_test_model.py OUT_DIR   (writes test_asr.onnx and test_asr_nometa.onnx)
"""
import os
import sys

import numpy as np
import onnx
from onnx import TensorProto, helper, numpy_helper

FRAME = 1280  # 80 ms at 16 kHz
TOKENS = ["<blk>", "▁سلام", "▁عليكم"]


def build(with_meta: bool) -> onnx.ModelProto:
    inits = [
        numpy_helper.from_array(np.array([FRAME], dtype=np.int64), "frame"),
        numpy_helper.from_array(np.array([0], dtype=np.int64), "zero"),
        numpy_helper.from_array(np.array([1], dtype=np.int64), "one"),
        numpy_helper.from_array(np.array([1, -1, FRAME], dtype=np.int64), "shape3"),
        # features [energy, mean] -> scores [blank, سلام, عليكم]
        numpy_helper.from_array(np.array([[-1000.0, 500.0, 500.0], [0.0, 1000.0, -1000.0]], dtype=np.float32), "w"),
        numpy_helper.from_array(np.array([0.5, 0.0, 0.0], dtype=np.float32), "b"),
    ]
    nodes = [
        # keep whole frames: n - n % FRAME samples
        helper.make_node("Shape", ["audio"], ["shp"]),
        helper.make_node("Slice", ["shp", "one", "shape3_end"], ["n"], name="n_of"),
        helper.make_node("Mod", ["n", "frame"], ["rem"]),
        helper.make_node("Sub", ["n", "rem"], ["whole"]),
        helper.make_node("Slice", ["audio", "zero", "whole", "one"], ["trimmed"]),
        helper.make_node("Reshape", ["trimmed", "shape3"], ["frames"]),
        helper.make_node("Mul", ["frames", "frames"], ["sq"]),
        helper.make_node("ReduceMean", ["sq"], ["energy"], axes=[-1], keepdims=1),
        helper.make_node("ReduceMean", ["frames"], ["mean"], axes=[-1], keepdims=1),
        helper.make_node("Concat", ["energy", "mean"], ["feat"], axis=2),
        helper.make_node("MatMul", ["feat", "w"], ["mm"]),
        helper.make_node("Add", ["mm", "b"], ["logits"]),
    ]
    inits += [
        numpy_helper.from_array(np.array([2], dtype=np.int64), "shape3_end"),
    ]
    graph = helper.make_graph(
        nodes, "asr_test",
        [helper.make_tensor_value_info("audio", TensorProto.FLOAT, [1, "samples"])],
        [helper.make_tensor_value_info("logits", TensorProto.FLOAT, [1, "frames", len(TOKENS)])],
        inits,
    )
    m = helper.make_model(graph, opset_imports=[helper.make_opsetid("", 17)])
    m.ir_version = 8  # readable by ONNX Runtime 1.19 / 1.20
    if with_meta:
        meta = {
            "asr.contract": "1",
            "asr.sample_rate": "16000",
            "asr.blank": "0",
            "asr.frame_ms": "80",
            "asr.model_name": "asr-test",
            "asr.tokens": "\n".join(TOKENS),
        }
        for k, v in meta.items():
            p = m.metadata_props.add()
            p.key, p.value = k, v
    onnx.checker.check_model(m)
    return m


def main() -> None:
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out, exist_ok=True)
    onnx.save(build(True), os.path.join(out, "test_asr.onnx"))
    onnx.save(build(False), os.path.join(out, "test_asr_nometa.onnx"))
    print("wrote", os.path.join(out, "test_asr.onnx"), "and test_asr_nometa.onnx")


if __name__ == "__main__":
    main()
