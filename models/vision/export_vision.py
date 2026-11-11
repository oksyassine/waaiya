"""Wraps third-party vision models into the screen-blur model contract (`im.vision = 1`), so the C side
(engine/src/im_vision.c) stays model-agnostic, like the audio contract: all model-specific pre/post-processing
lives inside the graph.

Detector  (im.kind = detector):   input  image float32 [1,3,H,W], RGB in 0..1, letterboxed at the top-left
                                   with im.pad (0..1);
                                   output dets  float32 [1,N,5] = x0, y0, x1, y1 (input pixels), person score.
                                   The caller does the score threshold and NMS.
Classifier (im.kind = classifier): input  image float32 [1,3,H,W], RGB in 0..1 (stretched crop, no letterbox
                                   unless im.letterbox = 1);
                                   output probs float32 [1,K], softmax; im.labels = comma-separated names.
Segmenter (im.kind = segmenter):   input  image float32 [1,3,H,W], RGB in 0..1: one person's box plus im.context
                                   (fraction of the box size, each side) of context, stretched;
                                   output prob float32 [1,1,h,w], p(this person) on a grid over that input
                                   (any h, w >= 2; the runtime interpolates).

Usage:
  python models/vision/export_vision.py yolox  --src downloads/yolox_nano.onnx --out person_yolox_nano.onnx
  python models/vision/export_vision.py marqo  --src downloads/marqo --out nsfw_marqo.onnx
  python models/vision/export_vision.py gender --src gender.pt --arch mobilenetv3_small_100 --out gender.onnx
  python models/vision/export_vision.py int8   --src nsfw_marqo.onnx --out nsfw_marqo_int8.onnx
  python models/vision/export_vision.py seg    --src seg_s192.pt --out seg.onnx   (train_seg.py output, or the
                                               torchvision COCO lraspp_mobilenet_v3_large .pth with --size H W)
"""
import argparse
import json
import os

import numpy as np
import onnx
from onnx import TensorProto, compose, helper, numpy_helper

OPSET = 17


def set_meta(model, **kv):
    del model.metadata_props[:]
    kv.setdefault("im.vision", "1")
    for k, v in kv.items():
        p = model.metadata_props.add()
        p.key, p.value = k, str(v)


def export_yolox(src, out, person_class=0):
    """YOLOX official ONNX (Megvii, Apache-2.0): input `images` [1,3,S,S] BGR 0..255, output raw [1,N,85]."""
    m = onnx.load(src)
    m = onnx.version_converter.convert_version(m, OPSET) if m.opset_import[0].version < 11 else m
    inp = m.graph.input[0]
    size = inp.type.tensor_type.shape.dim[2].dim_value
    in_name, out_name = inp.name, m.graph.output[0].name

    # pre: RGB 0..1 -> BGR 0..255
    pre = helper.make_graph(
        [helper.make_node("Mul", ["image", "k255"], ["scaled"]),
         helper.make_node("Gather", ["scaled", "bgr"], [in_name], axis=1)],
        "pre",
        [helper.make_tensor_value_info("image", TensorProto.FLOAT, [1, 3, size, size])],
        [helper.make_tensor_value_info(in_name, TensorProto.FLOAT, [1, 3, size, size])],
        [numpy_helper.from_array(np.array(255.0, np.float32), "k255"),
         numpy_helper.from_array(np.array([2, 1, 0], np.int64), "bgr")])

    # post: decode grid (demo_postprocess in the YOLOX repo), person score = obj * cls[person]
    grids, strides = [], []
    for s in (8, 16, 32):
        n = size // s
        yv, xv = np.meshgrid(np.arange(n), np.arange(n), indexing="ij")
        grids.append(np.stack((xv, yv), 2).reshape(-1, 2))
        strides.append(np.full((n * n, 1), s))
    grid = np.concatenate(grids).astype(np.float32)[None]
    stride = np.concatenate(strides).astype(np.float32)[None]
    nodes = [
        helper.make_node("Slice", [out_name, "s0", "s2", "ax"], ["xy"]),
        helper.make_node("Slice", [out_name, "s2", "s4", "ax"], ["wh"]),
        helper.make_node("Slice", [out_name, "s4", "s5", "ax"], ["obj"]),
        helper.make_node("Slice", [out_name, "c0", "c1", "ax"], ["cls"]),
        helper.make_node("Add", ["xy", "grid"], ["xyg"]),
        helper.make_node("Mul", ["xyg", "stride"], ["cxy"]),
        helper.make_node("Exp", ["wh"], ["ewh"]),
        helper.make_node("Mul", ["ewh", "stride"], ["bwh"]),
        helper.make_node("Mul", ["bwh", "half"], ["hwh"]),
        helper.make_node("Sub", ["cxy", "hwh"], ["p0"]),
        helper.make_node("Add", ["cxy", "hwh"], ["p1"]),
        helper.make_node("Mul", ["obj", "cls"], ["score"]),
        helper.make_node("Concat", ["p0", "p1", "score"], ["dets"], axis=2),
    ]
    c = 5 + person_class
    inits = [numpy_helper.from_array(np.array(v, np.int64), k) for k, v in
             dict(s0=[0], s2=[2], s4=[4], s5=[5], c0=[c], c1=[c + 1], ax=[2]).items()]
    inits += [numpy_helper.from_array(grid, "grid"), numpy_helper.from_array(stride, "stride"),
              numpy_helper.from_array(np.array(0.5, np.float32), "half")]
    n_anchor = grid.shape[1]
    post = helper.make_graph(
        nodes, "post",
        [helper.make_tensor_value_info(out_name, TensorProto.FLOAT, [1, n_anchor, 85])],
        [helper.make_tensor_value_info("dets", TensorProto.FLOAT, [1, n_anchor, 5])], inits)

    ops = [helper.make_opsetid("", max(OPSET, m.opset_import[0].version))]
    pre_m = helper.make_model(pre, opset_imports=ops, ir_version=m.ir_version)
    post_m = helper.make_model(post, opset_imports=ops, ir_version=m.ir_version)
    m.opset_import[0].version = ops[0].version
    full = compose.merge_models(pre_m, m, io_map=[(in_name, in_name)])
    full = compose.merge_models(full, post_m, io_map=[(out_name, out_name)])
    onnx.checker.check_model(full)
    set_meta(full, **{"im.kind": "detector", "im.input_w": size, "im.input_h": size, "im.pad": 114 / 255,
                      "im.model_name": os.path.basename(src).removesuffix(".onnx"),
                      "im.source": "YOLOX (Megvii), Apache-2.0, COCO person class"})
    onnx.save(full, out)


def export_torch_classifier(model, size, mean, std, labels, out, name, source):
    import torch

    class Wrap(torch.nn.Module):
        def __init__(self, net):
            super().__init__()
            self.net = net
            self.register_buffer("mean", torch.tensor(mean).view(1, 3, 1, 1))
            self.register_buffer("std", torch.tensor(std).view(1, 3, 1, 1))

        def forward(self, image):
            return torch.softmax(self.net((image - self.mean) / self.std), dim=1)

    w = Wrap(model).eval()
    h, wd = size
    x = torch.rand(1, 3, h, wd)
    torch.onnx.export(w, x, out, input_names=["image"], output_names=["probs"], opset_version=OPSET)
    m = onnx.load(out)
    set_meta(m, **{"im.kind": "classifier", "im.input_w": wd, "im.input_h": h, "im.labels": ",".join(labels),
                   "im.model_name": name, "im.source": source})
    onnx.save(m, out)


def export_marqo(src, out):
    """Marqo/nsfw-image-detection-384 (Apache-2.0): timm vit_tiny_patch16_384, safetensors (no pickle)."""
    import timm
    from safetensors.torch import load_file

    cfg = json.load(open(os.path.join(src, "config.json")))
    net = timm.create_model(cfg["architecture"], pretrained=False, num_classes=cfg["num_classes"])
    sd = load_file(os.path.join(src, "model.safetensors"))
    net.load_state_dict(sd, strict=True)
    pc = cfg["pretrained_cfg"]
    labels = [s.lower() for s in cfg["label_names"]]
    export_torch_classifier(net, pc["input_size"][1:], pc["mean"], pc["std"], labels, out, "nsfw_marqo_vit_tiny",
                            "Marqo/nsfw-image-detection-384, Apache-2.0")


def export_gender(src, arch, out):
    """Our own person-crop classifier (train_gender.py): state_dict saved with torch.save, loaded weights_only."""
    import timm
    import torch

    ck = torch.load(src, map_location="cpu", weights_only=True)
    labels = ck["labels"]
    net = timm.create_model(arch, pretrained=False, num_classes=len(labels))
    net.load_state_dict(ck["state_dict"])
    export_torch_classifier(net, tuple(ck["size"]), ck["mean"], ck["std"], labels, out, f"gender_{arch}",
                            "Waaiya person-crop classifier, trained on Open Images V7 boxes (CC BY 4.0)")


def export_seg(src, out, size=None):
    """Person segmenter: LR-ASPP MobileNetV3-large (torchvision, BSD-3), either fine-tuned by train_seg.py (a .pt with
    state_dict/size/mean/std/context) or torchvision's COCO checkpoint as is (--src *.pth: person-minus-background
    logit, input --size, context 0.2). Output: p(person) at the head's own 1/8 resolution."""
    import torch

    import train_seg

    ck = torch.load(src, map_location="cpu", weights_only=True)
    if "state_dict" in ck:
        net = train_seg.build()
        net.load_state_dict(ck["state_dict"])
        hw, mean, std, ctx, name = tuple(ck["size"]), ck["mean"], ck["std"], ck["context"], "seg_lraspp_mnv3l_oi"
        source = ("LR-ASPP MobileNetV3-large (torchvision, BSD-3, COCO weights) fine-tuned on Open Images V7 person "
                  "masks (CC BY 4.0)")
    else:
        net = train_seg.build(src)
        hw, mean, std, ctx, name = tuple(size or (192, 128)), train_seg.MEAN, train_seg.STD, train_seg.CONTEXT, \
            "seg_lraspp_mnv3l_coco"
        source = "LR-ASPP MobileNetV3-large, torchvision COCO_WITH_VOC_LABELS_V1 weights (BSD-3), person - background"

    class Wrap(torch.nn.Module):
        def __init__(self):
            super().__init__()
            self.net = net
            self.register_buffer("mean", torch.tensor(mean).view(1, 3, 1, 1))
            self.register_buffer("std", torch.tensor(std).view(1, 3, 1, 1))

        def forward(self, image):
            return torch.sigmoid(train_seg.low_res(self.net, (image - self.mean) / self.std))

    w = Wrap().eval()
    torch.onnx.export(w, torch.rand(1, 3, *hw), out, input_names=["image"], output_names=["prob"], opset_version=OPSET)
    m = onnx.load(out)
    set_meta(m, **{"im.kind": "segmenter", "im.input_w": hw[1], "im.input_h": hw[0], "im.context": ctx,
                   "im.model_name": name, "im.source": source})
    onnx.save(m, out)


def export_int8(src, out):
    """Dynamic int8 of MatMul/Gemm only (ONNX Runtime has no int8 ConvInteger kernel on CPU); keeps the metadata."""
    from onnxruntime.quantization import QuantType, quantize_dynamic

    quantize_dynamic(src, out, weight_type=QuantType.QInt8, op_types_to_quantize=["MatMul", "Gemm"])
    m, q = onnx.load(src), onnx.load(out)
    meta = {p.key: p.value for p in m.metadata_props}
    meta["im.model_name"] = meta.get("im.model_name", "model") + "_int8"
    set_meta(q, **meta)
    onnx.save(q, out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("kind", choices=["yolox", "marqo", "gender", "int8", "seg"])
    ap.add_argument("--src", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--arch", default="mobilenetv3_small_100")
    ap.add_argument("--size", type=int, nargs=2, metavar=("H", "W"), help="seg from the COCO checkpoint: input size")
    a = ap.parse_args()
    {"yolox": lambda: export_yolox(a.src, a.out), "marqo": lambda: export_marqo(a.src, a.out),
     "gender": lambda: export_gender(a.src, a.arch, a.out), "int8": lambda: export_int8(a.src, a.out),
     "seg": lambda: export_seg(a.src, a.out, a.size)}[a.kind]()
    print("wrote", a.out)


if __name__ == "__main__":
    main()
