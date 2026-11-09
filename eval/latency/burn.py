import multiprocessing as mp, time, sys
def f(t):
    e = time.time() + t
    while time.time() < e: pass
if __name__ == "__main__":
    ps = [mp.Process(target=f, args=(float(sys.argv[1]),)) for _ in range(8)]
    [p.start() for p in ps]; [p.join() for p in ps]
