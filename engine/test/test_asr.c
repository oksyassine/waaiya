/* The ASR model runner through ONNX Runtime (im_asr), on the made-up model of models/asr/make_test_model.py:
 * text, the contract's metadata, refusals, and the whole caption path at 48 kHz.
 * Usage: test-asr DIR   (DIR holds test_asr.onnx and test_asr_nometa.onnx) */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "im_captions.h"

static int fails;
#define CHECK(c, ...) do { if (c) { printf("ok: "); printf(__VA_ARGS__); printf("\n"); } \
                           else { printf("FAIL: "); printf(__VA_ARGS__); printf("\n"); fails++; } } while (0)

/* quiet, +0.2 for 0.4 s, quiet 0.3 s, -0.2 for 0.4 s, quiet: the model hears "سلام عليكم" */
static float *greeting(int rate, double lead, double tail, long *n) {
    long m = (long)((lead + 0.4 + 0.3 + 0.4 + tail) * rate);
    float *x = calloc((size_t)m, sizeof(float));
    long a = (long)(lead * rate), b = a + (long)(0.4 * rate), c = b + (long)(0.3 * rate), d = c + (long)(0.4 * rate);
    for (long i = a; i < b; i++) x[i] = 0.2f;
    for (long i = c; i < d; i++) x[i] = -0.2f;
    *n = m;
    return x;
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: test-asr DIR\n"); return 2; }
    char path[1024], bad[1024], err[512];
    snprintf(path, sizeof path, "%s/test_asr.onnx", argv[1]);
    snprintf(bad, sizeof bad, "%s/test_asr_nometa.onnx", argv[1]);

    im_asr *a = im_asr_create(path, 1, err, sizeof err);
    CHECK(a != NULL, "model loads%s%s", a ? "" : ": ", a ? "" : err);
    if (!a) return 1;
    CHECK(im_asr_sample_rate(a) == 16000 && strcmp(im_asr_model_name(a), "asr-test") == 0, "metadata: %d Hz, \"%s\"",
          im_asr_sample_rate(a), im_asr_model_name(a));
    long n;
    float *x = greeting(16000, 0.2, 0.5, &n);
    char out[256];
    int len = im_asr_transcribe(a, x, (int)n, out, sizeof out);
    CHECK(len > 0 && strcmp(out, "سلام عليكم") == 0, "transcribe: \"%s\"", out);
    len = im_asr_transcribe(a, x, 800, out, sizeof out);
    CHECK(len == 0 && out[0] == 0, "under 0.1 s: no text, no run");
    len = im_asr_transcribe(a, x, (int)n, out, 5);
    CHECK(len == 4 && strlen(out) == 4, "a short buffer: cut between letters (\"%s\")", out);
    free(x);
    im_asr_destroy(a);

    err[0] = 0;
    CHECK(im_asr_create(bad, 1, err, sizeof err) == NULL && strstr(err, "asr.contract"), "a model without the contract is refused (%s)", err);
    err[0] = 0;
    CHECK(im_asr_create("/nonexistent/model.onnx", 1, err, sizeof err) == NULL && err[0], "a missing file is refused");

    /* the whole path, as on the phone: 48 kHz, decimated, gated, recognised */
    im_captions_config cfg;
    im_captions_default_config(&cfg);
    cfg.in_rate = 48000;
    im_captions *k = im_captions_create_asr(&cfg, path, 1, err, sizeof err);
    CHECK(k != NULL, "captions with the model%s%s", k ? "" : ": ", k ? "" : err);
    if (k) {
        x = greeting(48000, 1.0, 1.5, &n);
        int finals = 0, partial = 0;
        char line[512], first[512] = "";
        for (long i = 0; i < n; i += 960) {
            int r = im_captions_push(k, x + i, (int)(n - i < 960 ? n - i : 960));
            if (r > 0 && (r & IM_CAPTIONS_PARTIAL) && im_captions_partial(k)[0]) partial = 1;
            while (im_captions_take_final(k, line, sizeof line) > 0) {
                if (!finals) snprintf(first, sizeof first, "%s", line);
                finals++;
            }
        }
        CHECK(finals == 1 && strcmp(first, "سلام عليكم") == 0, "48 kHz captions: %d line, \"%s\"", finals, first);
        CHECK(partial, "the line showed as it was spoken");
        free(x);
        im_captions_destroy(k);
    }
    err[0] = 0;
    CHECK(im_captions_create_asr(&cfg, bad, 1, err, sizeof err) == NULL && err[0], "captions refuse a bad model");
    printf(fails ? "%d FAILED\n" : "all passed\n", fails);
    return fails ? 1 : 0;
}
