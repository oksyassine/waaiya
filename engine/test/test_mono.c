/* Runtime mono switch (im_engine_set_mono): the delay stays, both channels come out equal, stereo comes back,
 * and an engine created with mono_mix refuses stereo. Prints the time per hop in each mode.
 * Usage: test-mono model.onnx */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "im_engine.h"

static int fails;
#define CHECK(c, msg) do { if (c) printf("ok: %s\n", msg); else { printf("FAIL: %s\n", msg); fails++; } } while (0)

static double now_ms(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec * 1e3 + (double)t.tv_nsec / 1e6;
}

/* A voiced sound: harmonics of f0 with a slow tremolo, different in each channel. */
static void fill(float *buf, int hop, long pos, double f0l, double f0r) {
    for (int i = 0; i < hop; i++) {
        double t = (double)(pos + i) / 48000.0, l = 0, r = 0;
        for (int h = 1; h <= 8; h++) {
            l += sin(2 * M_PI * f0l * h * t) / h;
            r += sin(2 * M_PI * f0r * h * t) / h;
        }
        double env = 0.6 + 0.4 * sin(2 * M_PI * 4.0 * t);
        buf[2 * i] = (float)(0.2 * env * l);
        buf[2 * i + 1] = (float)(0.2 * env * r);
    }
}

/* Runs n hops; returns the largest |L - R| and adds the output energy to *energy. */
static double run(im_engine *e, float *buf, int hop, long *pos, int n, double *energy, double *ms) {
    double diff = 0, t0 = now_ms();
    for (int k = 0; k < n; k++) {
        fill(buf, hop, *pos, 140.0, 215.0);
        *pos += hop;
        im_engine_process_hops_interleaved(e, buf, buf, 1);
        for (int i = 0; i < hop; i++) {
            double d = fabs((double)buf[2 * i] - (double)buf[2 * i + 1]);
            if (d > diff) diff = d;
            if (energy) *energy += (double)buf[2 * i] * buf[2 * i];
        }
    }
    if (ms) *ms = (now_ms() - t0) / n;
    return diff;
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: test-mono model.onnx\n"); return 2; }
    char err[256];
    im_config cfg = {argv[1], 2, 48000, 1, 0, NULL};
    im_engine *e = NULL;
    if (im_engine_create(&cfg, &e, err, sizeof err) != IM_OK) { fprintf(stderr, "%s\n", err); return 2; }
    int hop = im_engine_hop(e), lat = im_engine_aligned_latency(e);
    float *buf = malloc(sizeof(float) * (size_t)hop * 2);
    long pos = 0;
    double en = 0, ms_stereo = 0, ms_mono = 0;

    double d = run(e, buf, hop, &pos, 200, &en, &ms_stereo);
    CHECK(d > 1e-5, "stereo: the two channels differ");
    CHECK(en > 0, "stereo: output is not silent");

    CHECK(im_engine_set_mono(e, 1) == 1, "switch to mono is accepted");
    CHECK(im_engine_aligned_latency(e) == lat, "mono: same delay");
    run(e, buf, hop, &pos, 2, NULL, NULL); /* hops already inside the engine leave first */
    en = 0;
    d = run(e, buf, hop, &pos, 200, &en, &ms_mono);
    CHECK(d == 0, "mono: both channels are identical");
    CHECK(en > 0, "mono: output is not silent");
    CHECK(im_engine_run_errors(e) == 0, "no model errors");

    CHECK(im_engine_set_mono(e, 0) == 0, "switch back to stereo is accepted");
    run(e, buf, hop, &pos, 2, NULL, NULL);
    d = run(e, buf, hop, &pos, 100, NULL, NULL);
    CHECK(d > 1e-5, "stereo again: the two channels differ");
    im_engine_destroy(e);

    cfg.mono_mix = 1;
    if (im_engine_create(&cfg, &e, err, sizeof err) != IM_OK) { fprintf(stderr, "%s\n", err); return 2; }
    CHECK(im_engine_set_mono(e, 0) == 1, "an engine created mono refuses stereo");
    im_engine_destroy(e);
    free(buf);

    printf("per hop: stereo %.2f ms, mono %.2f ms (hop = %.0f ms)\n", ms_stereo, ms_mono, hop / 48.0);
    printf(fails ? "%d FAILED\n" : "all passed\n", fails);
    return fails ? 1 : 0;
}
