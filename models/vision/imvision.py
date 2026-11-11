"""ctypes binding to build/libimvision.so (engine/src/im_vision.c + im_cover.c), for tests and the scorer.

    v = Vision(person="person_yolox_nano.onnx", gender="gender.onnx", nsfw="nsfw_marqo.onnx", policy=WOMEN|NSFW)
    rects = v.detect(rgba)            # numpy uint8 HxWx4
    c = Cover(covers_visible=False); c.update(t_ms, rgba, rects)
"""
import ctypes as C
import os

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
WOMEN, NSFW = 1, 2
KINDS = {0: "clear", 1: "woman", 2: "unsure", 3: "nsfw", 4: "full"}


class VRect(C.Structure):
    _fields_ = [("x0", C.c_float), ("y0", C.c_float), ("x1", C.c_float), ("y1", C.c_float), ("kind", C.c_int),
                ("score", C.c_float), ("p_male", C.c_float)]

    def as_tuple(self):
        return (self.x0, self.y0, self.x1, self.y1, KINDS[self.kind], self.score, self.p_male)


class Config(C.Structure):
    _fields_ = [("person_model", C.c_char_p), ("gender_model", C.c_char_p), ("nsfw_model", C.c_char_p),
                ("threads", C.c_int), ("policy", C.c_uint)]


class Params(C.Structure):
    _fields_ = [("person_score", C.c_float), ("nms_iou", C.c_float), ("male_clear", C.c_float),
                ("nsfw_score", C.c_float), ("max_people", C.c_int), ("tiles", C.c_int)]


class CoverParams(C.Structure):
    _fields_ = [("margin", C.c_float), ("margin_min", C.c_float), ("lead_ms", C.c_float), ("hold_ms", C.c_float),
                ("full_hold_ms", C.c_float), ("cut_level", C.c_float), ("merge_gap", C.c_float)]


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
    lib.im_vision_last_nsfw.argtypes = [C.c_void_p]
    lib.im_vision_last_nsfw.restype = C.c_float
    lib.im_cover_create.restype = C.c_void_p
    lib.im_cover_create.argtypes = [C.c_int]
    lib.im_cover_destroy.argtypes = [C.c_void_p]
    lib.im_cover_reset.argtypes = [C.c_void_p]
    lib.im_cover_get_params.argtypes = lib.im_cover_set_params.argtypes = [C.c_void_p, C.POINTER(CoverParams)]
    lib.im_cover_update.argtypes = [C.c_void_p, C.c_double, C.c_void_p, C.c_int, C.c_int, C.c_int,
                                    C.POINTER(VRect), C.c_int, C.POINTER(VRect), C.c_int]
    return lib


class Vision:
    def __init__(self, person=None, gender=None, nsfw=None, policy=WOMEN | NSFW, threads=2, lib=None):
        self.lib = _lib(lib)
        enc = lambda p: p.encode() if p else None  # noqa: E731
        cfg = Config(enc(person), enc(gender), enc(nsfw), threads, policy)
        err = C.create_string_buffer(512)
        self.h = self.lib.im_vision_create(C.byref(cfg), err, 512)
        self.out = (VRect * 128)()

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
        self.out = (VRect * 64)()

    def params(self):
        p = CoverParams()
        self.lib.im_cover_get_params(self.h, C.byref(p))
        return {k: getattr(p, k) for k, _ in CoverParams._fields_}

    def reset(self):
        self.lib.im_cover_reset(self.h)

    def update(self, t_ms, rgba, dets):
        """dets: list of VRect from Vision.detect_raw, or None when the models were not run on this frame."""
        rgba = np.ascontiguousarray(rgba, dtype=np.uint8)
        h, w = rgba.shape[:2]
        n = -1 if dets is None else len(dets)
        arr = (VRect * max(1, n))(*(dets or []))
        m = self.lib.im_cover_update(self.h, t_ms, rgba.ctypes.data, w, h, w * 4, arr, n, self.out, 64)
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
