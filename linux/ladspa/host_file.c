/* Run a WAV file through the LADSPA plugin with a given block size (as a sound server would). */
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ladspa_abi.h"
#include "wav.h"
int main(int argc, char **argv) {
    if (argc < 4) { fprintf(stderr, "usage: host_file plugin.so in.wav out.wav [block]\n"); return 2; }
    int block = argc > 4 ? atoi(argv[4]) : 1024;
    void *h = dlopen(argv[1], RTLD_NOW);
    if (!h) { printf("dlopen: %s\n", dlerror()); return 1; }
    const LADSPA_Descriptor *(*fn)(unsigned long) = (const LADSPA_Descriptor *(*)(unsigned long))dlsym(h, "ladspa_descriptor");
    const LADSPA_Descriptor *d = fn(0);
    char err[256]; wav_t w;
    if (!wav_read(argv[2], &w, err, sizeof err) || w.channels != 2) { printf("need stereo wav: %s\n", err); return 1; }
    LADSPA_Handle p = d->instantiate(d, (unsigned long)w.rate);
    float *buf[2]; float en = 1, lat = 0;
    for (int c = 0; c < 2; c++) buf[c] = calloc(block, 4);
    /* in-place, like PulseAudio: input and output ports share one buffer per channel */
    d->connect_port(p, 0, buf[0]); d->connect_port(p, 1, buf[1]);
    d->connect_port(p, 2, buf[0]); d->connect_port(p, 3, buf[1]);
    d->connect_port(p, 4, &en); d->connect_port(p, 5, &lat);
    d->activate(p);
    float *out = calloc((size_t)w.frames * 2, 4);
    for (long i = 0; i < w.frames; i += block) {
        int n = (int)(w.frames - i < block ? w.frames - i : block);
        for (int k = 0; k < n; k++) { buf[0][k] = w.data[(i + k) * 2]; buf[1][k] = w.data[(i + k) * 2 + 1]; }
        d->run(p, n);
        for (int k = 0; k < n; k++) { out[(i + k) * 2] = buf[0][k]; out[(i + k) * 2 + 1] = buf[1][k]; }
    }
    wav_t o = {2, w.rate, w.frames, out};
    wav_write_f32(argv[3], &o);
    printf("latency port: %.0f\n", lat);
    d->cleanup(p);
    return 0;
}
