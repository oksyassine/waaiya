/* im-caption: live captions of a WAV file, exactly as the phone makes them from the microphone (docs/CAPTIONS.md).
 * Usage: im-caption -a asr.onnx [-m voice.onnx] [--partials] [--threads N] in.wav
 *
 * -m: first keep only the voice with the engine (as the app does; needs a 48 kHz file). Without it the file goes to
 * the captions as it is (16 kHz or a multiple). Each final line is printed as "[m:ss] text" at the time it would
 * have appeared on the screen; --partials also prints the growing line, prefixed "  ...". The last line on stderr
 * gives the time spent per second of audio (below 1.0: faster than live). */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "im_captions.h"
#include "im_engine.h"
#include "wav.h"

static double now(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec + t.tv_nsec * 1e-9; }

static void stamp(double s) { printf("[%d:%02d] ", (int)s / 60, (int)s % 60); }

int main(int argc, char **argv) {
    const char *asr = NULL, *voice = NULL, *in = NULL;
    int partials = 0, threads = 2;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-a") && i + 1 < argc) asr = argv[++i];
        else if (!strcmp(argv[i], "-m") && i + 1 < argc) voice = argv[++i];
        else if (!strcmp(argv[i], "--threads") && i + 1 < argc) threads = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--partials")) partials = 1;
        else if (argv[i][0] != '-' && !in) in = argv[i];
        else { fprintf(stderr, "unknown argument: %s\n", argv[i]); return 2; }
    }
    if (!asr || !in) {
        fprintf(stderr, "usage: im-caption -a asr.onnx [-m voice.onnx] [--partials] [--threads N] in.wav\n");
        return 2;
    }
    char err[512] = {0};
    wav_t w = {0};
    if (!wav_read(in, &w, err, sizeof err)) { fprintf(stderr, "read: %s\n", err); return 1; }
    /* mono */
    float *x = malloc(sizeof(float) * (size_t)(w.frames > 0 ? w.frames : 1));
    if (!x) return 1;
    for (long f = 0; f < w.frames; f++) {
        float s = 0;
        for (int c = 0; c < w.channels; c++) s += w.data[f * w.channels + c];
        x[f] = s / w.channels;
    }
    im_engine *e = NULL;
    if (voice) {
        if (w.rate != 48000) { fprintf(stderr, "-m needs a 48 kHz file (this one: %d Hz)\n", w.rate); return 1; }
        im_config cfg = {voice, 1, 48000, threads, 0, NULL};
        if (im_engine_create(&cfg, &e, err, sizeof err) != IM_OK) { fprintf(stderr, "voice model: %s\n", err); return 1; }
    }
    im_captions_config cc;
    im_captions_default_config(&cc);
    cc.in_rate = w.rate;
    im_captions *k = im_captions_create_asr(&cc, asr, threads, err, sizeof err);
    if (!k) {
        fprintf(stderr, "%s%s\n", err[0] ? err : "captions: cannot start",
                w.rate % 16000 ? " (the file must be at 16 kHz or a multiple, e.g. 48 kHz)" : "");
        return 1;
    }
    int block = w.rate / 50;   /* 20 ms, as the microphone delivers it */
    float *buf = malloc(sizeof(float) * (size_t)block);
    char line[4096], last[4096] = "";
    double t0 = now();
    int lines = 0, failures = 0;
    for (long i = 0; i <= w.frames; i += block) {
        int n = (int)(w.frames - i < block ? w.frames - i : block);
        int r;
        if (n > 0) {
            if (e) im_engine_process_interleaved(e, x + i, buf, n);
            else memcpy(buf, x + i, sizeof(float) * (size_t)n);
            r = im_captions_push(k, buf, n);
        } else {
            r = im_captions_flush(k);
        }
        double at = (double)(i + (n > 0 ? n : 0)) / w.rate;
        if (r < 0) failures++;
        if (partials && r > 0 && (r & IM_CAPTIONS_PARTIAL) && strcmp(im_captions_partial(k), last)) {
            snprintf(last, sizeof last, "%s", im_captions_partial(k));
            if (last[0]) { stamp(at); printf("  ... %s\n", last); }
        }
        while (im_captions_take_final(k, line, sizeof line) > 0) {
            stamp(at);
            printf("%s\n", line);
            lines++;
        }
        fflush(stdout);
        if (n <= 0) break;
    }
    double dur = (double)w.frames / w.rate, took = now() - t0;
    fprintf(stderr, "lines=%d failures=%d audio=%.1fs took=%.1fs per_second=%.3f\n", lines, failures, dur, took,
            dur > 0 ? took / dur : 0);
    im_captions_destroy(k);
    if (e) im_engine_destroy(e);
    free(buf);
    free(x);
    wav_free(&w);
    return failures ? 1 : 0;
}
