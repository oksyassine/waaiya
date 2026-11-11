"""ctypes binding to build/libimvision.so (engine/src/im_vision.c + im_cover.c), for tests and the scorer.

    v = Vision(person="person_yolox_nano.onnx", gender="gender.onnx", nsfw="nsfw_marqo.onnx", policy=WOMEN|NSFW,
               seg="seg.onnx")
    rects = v.detect(rgba)            # numpy uint8 HxWx4
    dets, shapes = v.detect_shapes(rgba)   # with outlines (VShape per detection; rows = 0: none)
    c = Cover(covers_visible=False); c.update(t_ms, rgba, dets, shapes)
"""
import ctypes as C
import os

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
WOMEN, NSFW = 1, 2
KINDS = {0: "clear", 1: "woman", 2: "unsure", 3: "nsfw", 4: "full"}
SHAPE_ROWS = 16
PART = 16  # IM_VK_PART: a strip of an outline or a bridge
OUT_MAX = 256  # rects per frame, as the app's buffers (vision_jni.c)


class VRect(C.Structure):
    _fields_ = [("x0", C.c_float), ("y0", C.c_float), ("x1", C.c_float), ("y1", C.c_float), ("kind", C.c_int),
                ("score", C.c_float), ("p_male", C.c_float)]

    def as_tuple(self):
        return (self.x0, self.y0, self.x1, self.y1, KINDS[self.kind & ~PART], self.score, self.p_male, bool(self.kind & PART))


class VShape(C.Structure):
    _fields_ = [("rows", C.c_int), ("flags", C.c_uint), ("y0", C.c_float), ("y1", C.c_float),
                ("l", C.c_float * SHAPE_ROWS), ("r", C.c_float * SHAPE_ROWS)]


class Config(C.Structure):
    _fields_ = [("person_model", C.c_char_p), ("gender_model", C.c_char_p), ("nsfw_model", C.c_char_p),
                ("threads", C.c_int), ("policy", C.c_uint), ("seg_model", C.c_char_p)]


class Params(C.Structure):
    _fields_ = [("person_score", C.c_float), ("nms_iou", C.c_float), ("male_clear", C.c_float),
                ("nsfw_score", C.c_float), ("max_people", C.c_int), ("tiles", C.c_int),
                ("tiles_per_frame", C.c_int), ("nest", C.c_float),
                ("tile_score", C.c_float), ("seg", C.c_int), ("seg_threshold", C.c_float),
                ("seg_min_fill", C.c_float), ("seg_max_people", C.c_int),
                ("seg_min_px", C.c_int)]


class CoverParams(C.Structure):
    _fields_ = [("margin", C.c_float), ("margin_min", C.c_float), ("lead_ms", C.c_float), ("hold_ms", C.c_float),
                ("full_hold_ms", C.c_float), ("cut_level", C.c_float), ("merge_gap", C.c_float),
                ("strip_margin", C.c_float), ("bridge_gap", C.c_float), ("open_reach", C.c_float),
                ("still_frac", C.c_float), ("shrink_rate", C.c_float),
                ("static_level", C.c_float)]


def _lib(path=None):
    lib = C.CDLL(path or os.path.join(ROOT, "build", "libimvision.so"))
    lib.im_vision_create.restype = C.c_void_p
    lib.im_vision_create.argtypes = [C.POINTER(Config), C.c_char_p, C.c_size_t]
    lib.im_vision_destroy.argtypes = [C.c_void_p]
    lib.im_vision_status.argtypes = [C.c_void_p]
    lib.im_vision_status.restype = C.c_uint
    lib.im_vision_error.argtypes = [C.c_void_p]
    lib.im_vision_error.restype = C.c_char_p
    lib.im_vision_get_params.argtypes = lib.im_vision_set_params.argtypes = [C.c_void_p, C.POINTER(Params)]
    lib.im_vision_detect.argtypes = [C.c_void_p, C.c_void_p, C.c_int, C.c_int, C.c_int, C.c_int, C.POINTER(VRect), C.c_int]
    lib.im_vision_detect_shapes.argtypes = [C.c_void_p, C.c_void_p, C.c_int, C.c_int, C.c_int, C.c_int,
                                            C.POINTER(VRect), C.POINTER(VShape), C.c_int]
    lib.im_vision_last_nsfw.argtypes = [C.c_void_p]
    lib.im_vision_last_nsfw.restype = C.c_float
    lib.im_cover_create.restype = C.c_void_p
    lib.im_cover_create.argtypes = [C.c_int]
    lib.im_cover_destroy.argtypes = [C.c_void_p]
    lib.im_cover_reset.argtypes = [C.c_void_p]
    lib.im_cover_get_params.argtypes = lib.im_cover_set_params.argtypes = [C.c_void_p, C.POINTER(CoverParams)]
    lib.im_cover_update.argtypes = [C.c_void_p, C.c_double, C.c_void_p, C.c_int, C.c_int, C.c_int,
                                    C.POINTER(VRect), C.c_int, C.POINTER(VRect), C.c_int]
    lib.im_cover_update_shapes.argtypes = [C.c_void_p, C.c_double, C.c_void_p, C.c_int, C.c_int, C.c_int,
                                           C.POINTER(VRect), C.POINTER(VShape), C.c_int, C.POINTER(VRect), C.c_int]
    return lib


class Vision:
    def __init__(self, person=None, gender=None, nsfw=None, policy=WOMEN | NSFW, threads=2, lib=None, seg=None):
        self.lib = _lib(lib)
        enc = lambda p: p.encode() if p else None  # noqa: E731
        cfg = Config(enc(person), enc(gender), enc(nsfw), threads, policy, enc(seg))
        err = C.create_string_buffer(512)
        self.h = self.lib.im_vision_create(C.byref(cfg), err, 512)
        self.out = (VRect * 128)()
        self.shapes = (VShape * 128)()

    @property
    def status(self):
        return self.lib.im_vision_status(self.h)

    @property
    def error(self):
        return self.lib.im_vision_error(self.h).decode()

    def params(self, **kw):
        p = Params()
        self.lib.im_vision_get_params(self.h, C.byref(p))
        for k, v in kw.items():
            setattr(p, k, v)
        self.lib.im_vision_set_params(self.h, C.byref(p))
        return {k: getattr(p, k) for k, _ in Params._fields_}

    def detect_raw(self, rgba, run_nsfw=True):
        rgba = np.ascontiguousarray(rgba, dtype=np.uint8)
        h, w = rgba.shape[:2]
        n = self.lib.im_vision_detect(self.h, rgba.ctypes.data, w, h, w * 4, int(run_nsfw), self.out, 128)
        if n < 0:
            raise RuntimeError(self.error)
        return list(self.out[:n]), n

    def detect_shapes(self, rgba, run_nsfw=True):
        """(dets, shapes): lists of VRect and VShape (copies), index-aligned."""
        rgba = np.ascontiguousarray(rgba, dtype=np.uint8)
        h, w = rgba.shape[:2]
        n = self.lib.im_vision_detect_shapes(self.h, rgba.ctypes.data, w, h, w * 4, int(run_nsfw), self.out,
                                             self.shapes, 128)
        if n < 0:
            raise RuntimeError(self.error)
        return [VRect.from_buffer_copy(r) for r in self.out[:n]], [VShape.from_buffer_copy(s) for s in self.shapes[:n]]

    def detect(self, rgba, run_nsfw=True):
        return [r.as_tuple() for r in self.detect_raw(rgba, run_nsfw)[0]]

    @property
    def last_nsfw(self):
        return self.lib.im_vision_last_nsfw(self.h)

    def __del__(self):
        if getattr(self, "h", None):
            self.lib.im_vision_destroy(self.h)


class Cover:
    def __init__(self, covers_visible=False, lib=None, **params):
        self.lib = _lib(lib)
        self.h = self.lib.im_cover_create(int(covers_visible))
        p = CoverParams()
        self.lib.im_cover_get_params(self.h, C.byref(p))
        for k, v in params.items():
            setattr(p, k, v)
        self.lib.im_cover_set_params(self.h, C.byref(p))
        self.out = (VRect * OUT_MAX)()

    def params(self):
        p = CoverParams()
        self.lib.im_cover_get_params(self.h, C.byref(p))
        return {k: getattr(p, k) for k, _ in CoverParams._fields_}

    def reset(self):
        self.lib.im_cover_reset(self.h)

    def update(self, t_ms, rgba, dets, shapes=None, max_out=OUT_MAX):
        """dets: list of VRect from Vision.detect_raw, or None when the models were not run on this frame.
        shapes: optional list of VShape, one per detection (Vision.detect_shapes)."""
        rgba = np.ascontiguousarray(rgba, dtype=np.uint8)
        h, w = rgba.shape[:2]
        n = -1 if dets is None else len(dets)
        arr = (VRect * max(1, n))(*(dets or []))
        sh = (VShape * max(1, n))(*shapes) if shapes is not None and n > 0 else None
        m = self.lib.im_cover_update_shapes(self.h, t_ms, rgba.ctypes.data, w, h, w * 4, arr, sh, n, self.out,
                                            min(max_out, OUT_MAX))
        return [r.as_tuple() for r in self.out[:m]]

    def __del__(self):
        if getattr(self, "h", None):
            self.lib.im_cover_destroy(self.h)


def load_rgba(path, long_side=None):
    from PIL import Image

    im = Image.open(path).convert("RGB")
    if long_side:
        s = long_side / max(im.size)
        im = im.resize((round(im.size[0] * s), round(im.size[1] * s)), Image.BILINEAR)
    a = np.asarray(im)
    return np.concatenate([a, np.full(a.shape[:2] + (1,), 255, np.uint8)], 2)
