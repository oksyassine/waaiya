"""Record two PulseAudio sources at once with per-chunk capture timestamps (pa_simple latency-corrected),
so the two recordings can be placed on one clock.  usage: rec2.py dev1 dev2 seconds outprefix"""
import ctypes as C, sys, threading, time, numpy as np
pa = C.CDLL("libpulse-simple.so.0"); pc = C.CDLL("libpulse.so.0")
class SS(C.Structure): _fields_ = [("format", C.c_int), ("rate", C.c_uint32), ("channels", C.c_uint8)]
class BA(C.Structure): _fields_ = [("maxlength", C.c_uint32), ("tlength", C.c_uint32), ("prebuf", C.c_uint32), ("minreq", C.c_uint32), ("fragsize", C.c_uint32)]
pa.pa_simple_new.restype = C.c_void_p
pa.pa_simple_new.argtypes = [C.c_char_p, C.c_char_p, C.c_int, C.c_char_p, C.c_char_p, C.POINTER(SS), C.c_void_p, C.POINTER(BA), C.POINTER(C.c_int)]
pa.pa_simple_read.argtypes = [C.c_void_p, C.c_void_p, C.c_size_t, C.POINTER(C.c_int)]
pa.pa_simple_get_latency.restype = C.c_uint64
pa.pa_simple_get_latency.argtypes = [C.c_void_p, C.POINTER(C.c_int)]
pa.pa_simple_free.argtypes = [C.c_void_p]
R, CH, FR = 48000, 2, 96            # 2 ms chunks
dev1, dev2, secs, out = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4]
res = {}
go = threading.Barrier(2)
def rec(name, dev):
    go.wait()
    if name == "s2" and len(sys.argv) > 5: time.sleep(float(sys.argv[5]))
    err = C.c_int(0); ss = SS(5, R, CH); M = 0xFFFFFFFF
    ba = BA(M, M, M, M, FR * CH * 4)
    s = pa.pa_simple_new(None, b"im-latency", 2, dev.encode(), name.encode(), C.byref(ss), None, C.byref(ba), C.byref(err))
    if not s: raise SystemExit(f"pa_simple_new {dev} failed {err.value}")
    print(name, "connected", time.monotonic(), file=sys.stderr)
    n = int(secs * R / FR); buf = (C.c_float * (FR * CH))(); data = np.zeros((n * FR, CH), np.float32); stamps = []
    for i in range(n):
        if pa.pa_simple_read(s, buf, FR * CH * 4, C.byref(err)) < 0: raise SystemExit("read failed")
        t = time.monotonic(); lat = pa.pa_simple_get_latency(s, C.byref(err))
        data[i * FR:(i + 1) * FR] = np.frombuffer(buf, np.float32).reshape(FR, CH)
        stamps.append(((i + 1) * FR, t, lat / 1e6))
    pa.pa_simple_free(s)
    res[name] = (data, np.array(stamps))
th = [threading.Thread(target=rec, args=(f"s{k}", d)) for k, d in ((1, dev1), (2, dev2))]
[t.start() for t in th]; [t.join() for t in th]
for k in ("s1", "s2"):
    d, st = res[k]
    np.save(f"{out}_{k}.npy", d); np.save(f"{out}_{k}_ts.npy", st)
