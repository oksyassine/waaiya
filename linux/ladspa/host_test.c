/* Minimal LADSPA host: loads the plugin like a sound server would and runs blocks of a given size. */
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "ladspa_abi.h"
int main(int argc, char **argv) {
    const char *so = argc > 1 ? argv[1] : "build/islamic_mute_ladspa.so";
    int block = argc > 2 ? atoi(argv[2]) : 1024;
    void *h = dlopen(so, RTLD_NOW);
    if (!h) { printf("dlopen: %s\n", dlerror()); return 1; }
    const LADSPA_Descriptor *(*fn)(unsigned long) = (const LADSPA_Descriptor *(*)(unsigned long))dlsym(h, "ladspa_descriptor");
    const LADSPA_Descriptor *d = fn(0);
    printf("plugin: %s (%lu ports)\n", d->Name, d->PortCount);
    LADSPA_Handle p = d->instantiate(d, 48000);
    float *in[2], *out[2], en = 1, lat = 0;
    for (int c = 0; c < 2; c++) { in[c] = calloc(block, 4); out[c] = calloc(block, 4); }
    d->connect_port(p, 0, in[0]); d->connect_port(p, 1, in[1]);
    d->connect_port(p, 2, out[0]); d->connect_port(p, 3, out[1]);
    d->connect_port(p, 4, &en); d->connect_port(p, 5, &lat);
    d->activate(p);
    struct timespec a, b; double worst = 0;
    for (int k = 0; k < 20; k++) {
        for (int i = 0; i < block; i++) in[0][i] = in[1][i] = (float)(rand() % 2000 - 1000) / 10000.f;
        clock_gettime(CLOCK_MONOTONIC, &a);
        d->run(p, block);
        clock_gettime(CLOCK_MONOTONIC, &b);
        double ms = (b.tv_sec - a.tv_sec) * 1e3 + (b.tv_nsec - a.tv_nsec) / 1e6;
        if (ms > worst) worst = ms;
    }
    printf("block %d: worst run() %.1f ms for %.1f ms of audio, latency port %.0f\n", block, worst, block / 48.0, lat);
    d->cleanup(p);
    return 0;
}
