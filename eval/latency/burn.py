import multiprocessing as mp, time, sys
def f(t):
    e = time.time() + t
    while time.time() < e: pass
if __name__ == "__main__":
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 8   # busy processes (default: one per thread here)
    ps = [mp.Process(target=f, args=(float(sys.argv[1]),)) for _ in range(n)]
    [p.start() for p in ps]; [p.join() for p in ps]
