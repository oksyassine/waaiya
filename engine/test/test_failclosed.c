/* Fail-closed behaviour of the engine (see im_engine.h):
 *  (a) an engine whose model did not load (bad path, not an ONNX file, wrong sample rate) reports the error,
 *      im_engine_failed() == 1, and outputs exact zeros (bitwise +0.0f) for a loud input through every
 *      processing path, with a delay that does not change from call to call. A failed engine has no model
 *      look-ahead: im_engine_latency() == hop and im_engine_aligned_latency() == 0 (a working engine reports
 *      look-ahead + hop), so the failed delay is shorter than the working one; its output is silence anyway.
 *  (b) a working voice model with IM_POLICY_MUTE_FEMALE_SINGING | IM_POLICY_FAIL_CLOSED and no usable detector
 *      (none given, or a path that does not load) mutes the voice and im_engine_detector_status() returns 1;
 *      the same policy without IM_POLICY_FAIL_CLOSED lets the voice through, so the flag is what mutes.
 * Usage: test-failclosed model.onnx   (e.g. models/dfn3/dfn3_stream_int8.onnx) */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "im_engine.h"

static int fails;
#define CHECK(c, ...) do { if (c) printf("ok: "); else { printf("FAIL: "); fails++; } printf(__VA_ARGS__); printf("\n"); } while (0)

#define CH 2
#define RATE 48000
#define BLOCK 333 /* odd block size for the any-block-size path */
#define SENTINEL 0.75f

/* A loud voiced sound: harmonics of f0 with a slow tremolo, different in each channel (as in test_mono.c). */
static void fill(float *buf, int frames, long pos) {
    for (int i = 0; i < frames; i++) {
        double t = (double)(pos + i) / RATE, l = 0, r = 0;
        for (int h = 1; h <= 8; h++) {
            l += sin(2 * M_PI * 140.0 * h * t) / h;
            r += sin(2 * M_PI * 215.0 * h * t) / h;
        }
        double env = 0.6 + 0.4 * sin(2 * M_PI * 4.0 * t);
        buf[CH * i] = (float)(0.2 * env * l);
        buf[CH * i + 1] = (float)(0.2 * env * r);
    }
}

static void set_all(float *buf, size_t n, float v) {
    for (size_t i = 0; i < n; i++) buf[i] = v;
}

/* 1 if every byte is zero: +0.0f only (no -0.0f, no denormal, no untouched sentinel). */
static int all_zero_bits(const float *buf, size_t n) {
    const unsigned char *b = (const unsigned char *)buf;
    for (size_t i = 0; i < n * sizeof(float); i++)
        if (b[i]) return 0;
    return 1;
}

static int same_delay(const im_engine *e, int lat, int alat, int hop) {
    return im_engine_latency(e) == lat && im_engine_aligned_latency(e) == alat && im_engine_hop(e) == hop;
}

/* Case (a) on one failed engine. */
static void check_failed(const char *what, im_engine *e, int rc, const char *err) {
    CHECK(rc != IM_OK, "%s: im_engine_create returns an error (%d: %s)", what, rc, err);
    CHECK(e != NULL, "%s: an engine is still returned", what);
    if (!e) return;
    CHECK(im_engine_failed(e) == 1, "%s: im_engine_failed() == 1", what);
    const int hop = im_engine_hop(e), lat = im_engine_latency(e), alat = im_engine_aligned_latency(e);
    CHECK(hop > 0 && lat == hop && alat == 0,
          "%s: delay without a model is one hop (latency %d, aligned %d, hop %d)", what, lat, alat, hop);

    /* any-block-size interleaved path, odd blocks, separate in/out buffers */
    float *in = malloc(sizeof(float) * BLOCK * CH), *out = malloc(sizeof(float) * BLOCK * CH);
    long pos = 0;
    int zero = 1, steady = 1;
    for (int k = 0; k < 300; k++) { /* about 2 s */
        fill(in, BLOCK, pos);
        pos += BLOCK;
        set_all(out, (size_t)BLOCK * CH, SENTINEL);
        im_engine_process_interleaved(e, in, out, BLOCK);
        zero &= all_zero_bits(out, (size_t)BLOCK * CH);
        steady &= same_delay(e, lat, alat, hop);
    }
    CHECK(zero, "%s: im_engine_process_interleaved output is exact zeros (300 blocks of %d)", what, BLOCK);
    CHECK(steady, "%s: delay is the same after every interleaved call", what);

    /* planar path, in place */
    float *pl[CH], *plo[CH];
    for (int c = 0; c < CH; c++) { pl[c] = malloc(sizeof(float) * BLOCK); plo[c] = pl[c]; }
    zero = 1;
    for (int k = 0; k < 100; k++) {
        fill(in, BLOCK, pos);
        pos += BLOCK;
        for (int c = 0; c < CH; c++)
            for (int i = 0; i < BLOCK; i++) pl[c][i] = in[CH * i + c];
        im_engine_process(e, (const float *const *)pl, plo, BLOCK);
        for (int c = 0; c < CH; c++) zero &= all_zero_bits(plo[c], BLOCK);
        steady &= same_delay(e, lat, alat, hop);
    }
    CHECK(zero, "%s: im_engine_process (planar, in place) output is exact zeros", what);
    for (int c = 0; c < CH; c++) free(pl[c]);

    /* hop-aligned path: needs no partial hop held, so restart the stream first (as the header says) */
    im_engine_reset(e);
    float *hin = malloc(sizeof(float) * (size_t)hop * CH * 2), *hout = malloc(sizeof(float) * (size_t)hop * CH * 2);
    int rc_ok = 1;
    zero = 1;
    for (int k = 0; k < 100; k++) { /* 2 hops per call */
        fill(hin, hop * 2, pos);
        pos += hop * 2;
        set_all(hout, (size_t)hop * CH * 2, SENTINEL);
        rc_ok &= im_engine_process_hops_interleaved(e, hin, hout, 2) == 0;
        zero &= all_zero_bits(hout, (size_t)hop * CH * 2);
        steady &= same_delay(e, lat, alat, hop);
    }
    CHECK(rc_ok, "%s: im_engine_process_hops_interleaved accepts the hops (returns 0)", what);
    CHECK(zero, "%s: im_engine_process_hops_interleaved output is exact zeros", what);
    zero = 1;
    for (int k = 0; k < 50; k++) { /* in place */
        fill(hin, hop, pos);
        pos += hop;
        rc_ok &= im_engine_process_hops_interleaved(e, hin, hin, 1) == 0;
        zero &= all_zero_bits(hin, (size_t)hop * CH);
    }
    CHECK(rc_ok && zero, "%s: hop-aligned path in place is exact zeros", what);
    CHECK(steady && same_delay(e, lat, alat, hop), "%s: delay never changed (latency %d, aligned %d)", what, lat, alat);
    CHECK(im_engine_failed(e) == 1, "%s: still failed after processing", what);

    /* a failed engine with the fail-closed voice policy is silent too */
    im_engine_set_policy(e, IM_POLICY_MUTE_FEMALE_SINGING | IM_POLICY_FAIL_CLOSED);
    zero = 1;
    for (int k = 0; k < 20; k++) {
        fill(hin, hop, pos);
        pos += hop;
        im_engine_process_hops_interleaved(e, hin, hin, 1);
        zero &= all_zero_bits(hin, (size_t)hop * CH);
    }
    CHECK(zero, "%s: exact zeros with the fail-closed policy as well", what);
    free(in); free(out); free(hin); free(hout);
}

/* Runs `seconds` of the voiced signal through e (hop-aligned or any-block-size path) and returns the peak and RMS
 * of the output after `settle` samples. */
static void run_voice(im_engine *e, int aligned, double seconds, long settle, double *peak, double *rms) {
    const int hop = im_engine_hop(e), blk = aligned ? hop : BLOCK;
    float *buf = malloc(sizeof(float) * (size_t)blk * CH);
    long pos = 0, total = (long)(seconds * RATE), counted = 0;
    double pk = 0, sum = 0;
    while (pos < total) {
        fill(buf, blk, pos);
        if (aligned) im_engine_process_hops_interleaved(e, buf, buf, 1);
        else im_engine_process_interleaved(e, buf, buf, blk);
        for (int i = 0; i < blk; i++, pos++) {
            if (pos < settle) continue;
            for (int c = 0; c < CH; c++) {
                double a = fabs((double)buf[CH * i + c]);
                if (a > pk) pk = a;
                sum += a * a;
            }
            counted += CH;
        }
    }
    *peak = pk;
    *rms = counted ? sqrt(sum / (double)counted) : 0;
    free(buf);
}

/* Case (b): one engine on the working model with the given detector path and policy. */
static void check_policy(const char *model, const char *what, const char *det, unsigned policy, int aligned,
                         int expect_mute, double *rms_out) {
    char err[512];
    im_config cfg = {model, CH, RATE, 1, 0, det};
    im_engine *e = NULL;
    int rc = im_engine_create(&cfg, &e, err, sizeof err);
    CHECK(rc == IM_OK && e && !im_engine_failed(e), "%s: voice model loads (%s)", what, rc == IM_OK ? "ok" : err);
    if (rc != IM_OK || !e) { im_engine_destroy(e); return; }
    if (det) CHECK(im_engine_detector_error(e)[0] != 0, "%s: detector load error is reported (\"%s\")", what,
                   im_engine_detector_error(e));
    im_engine_set_policy(e, policy);
    /* settle: the model look-ahead plus 200 ms for the ~5 ms mute ramp (smoothed gain, not a hard cut) */
    long settle = im_engine_aligned_latency(e) + im_engine_hop(e) + RATE / 5;
    double peak, rms;
    run_voice(e, aligned, 3.0, settle, &peak, &rms);
    int st = im_engine_detector_status(e, NULL);
    *rms_out = rms;
    if (expect_mute) {
        CHECK(st == 1, "%s: im_engine_detector_status == 1 (muting without a detector), got %d", what, st);
        CHECK(peak < 1e-6, "%s: voice is muted after the delay (peak %.3g, rms %.3g)", what, peak, rms);
    } else {
        CHECK(st == -1, "%s: im_engine_detector_status == -1 (no detector, nothing muted), got %d", what, st);
        CHECK(peak > 1e-3 && rms > 1e-4, "%s: voice passes (peak %.3g, rms %.3g)", what, peak, rms);
    }
    CHECK(im_engine_run_errors(e) == 0, "%s: no model run errors", what);
    im_engine_destroy(e);
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: test-failclosed model.onnx\n"); return 2; }
    const char *model = argv[1];
    char err[512];
    im_engine *e;
    int rc;

    /* the delay a working engine reports, for the record */
    im_config good = {model, CH, RATE, 1, 0, NULL};
    e = NULL;
    rc = im_engine_create(&good, &e, err, sizeof err);
    if (rc != IM_OK) { fprintf(stderr, "cannot load %s: %s\n", model, err); im_engine_destroy(e); return 2; }
    printf("working engine: hop %d, latency %d, aligned latency %d\n", im_engine_hop(e), im_engine_latency(e),
           im_engine_aligned_latency(e));
    int model_hop = im_engine_hop(e);
    im_engine_destroy(e);

    /* (a) failed engines */
    im_config bad = {"/nonexistent/waaiya-test/model.onnx", CH, RATE, 1, 0, NULL};
    err[0] = 0; e = NULL;
    rc = im_engine_create(&bad, &e, err, sizeof err);
    check_failed("bad model path", e, rc, err);
    im_engine_destroy(e);

    im_config notonnx = {argv[0], CH, RATE, 1, 0, NULL}; /* this test binary: a file, but not a model */
    err[0] = 0; e = NULL;
    rc = im_engine_create(&notonnx, &e, err, sizeof err);
    check_failed("not an ONNX file", e, rc, err);
    im_engine_destroy(e);

    im_config wrongrate = {model, CH, 44100, 1, 0, NULL};
    err[0] = 0; e = NULL;
    rc = im_engine_create(&wrongrate, &e, err, sizeof err);
    check_failed("wrong sample rate", e, rc, err);
    if (e) CHECK(im_engine_hop(e) == model_hop, "wrong sample rate: hop is the model's (%d)", im_engine_hop(e));
    im_engine_destroy(e);

    /* (b) voice policy without a usable detector */
    const unsigned sing = IM_POLICY_MUTE_FEMALE_SINGING, closed = IM_POLICY_MUTE_FEMALE_SINGING | IM_POLICY_FAIL_CLOSED;
    const char *bad_det = "/nonexistent/waaiya-test/detector.onnx";
    double r_closed_none, r_closed_bad, r_open_none, r_open_bad;
    check_policy(model, "fail-closed, no detector, hop path", NULL, closed, 1, 1, &r_closed_none);
    check_policy(model, "fail-closed, bad detector path, any-block path", bad_det, closed, 0, 1, &r_closed_bad);
    check_policy(model, "no fail-closed, no detector, hop path", NULL, sing, 1, 0, &r_open_none);
    check_policy(model, "no fail-closed, bad detector path, any-block path", bad_det, sing, 0, 0, &r_open_bad);
    CHECK(r_open_none > 1000 * r_closed_none && r_open_bad > 1000 * r_closed_bad,
          "IM_POLICY_FAIL_CLOSED is what mutes (rms %.3g / %.3g with it, %.3g / %.3g without)", r_closed_none,
          r_closed_bad, r_open_none, r_open_bad);

    printf(fails ? "%d FAILED\n" : "all passed\n", fails);
    return fails ? 1 : 0;
}
