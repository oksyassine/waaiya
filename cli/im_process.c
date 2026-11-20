/* im-process: run the streaming engine over a WAV file, exactly as a live sink would,
 * then remove the engine delay so the output lines up with the input.
 * Usage: im-process -m model.onnx [--mono] [-d detector.onnx --mute-female-singing|--mute-female-voice [--fail-closed]] [--keep-delay] [--block N] [--aligned] in.wav out.wav
 *
 * --raw [--channels N] [--rate R]: float32 interleaved samples from stdin to stdout instead of WAV files, in
 * blocks, so a long recording never has to fit in memory (the desktop app's "save a link without music": a decoder
 * pipes into it and an encoder reads from it). The output has exactly as many frames as the input and lines up
 * with it (the engine delay is dropped at the start and flushed with silence at the end). Stats go to stderr. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "im_engine.h"
#include "wav.h"
#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#endif

static double now(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec + t.tv_nsec * 1e-9; }

/* --raw: stdin -> engine -> stdout, block by block; returns the exit code */
static int run_raw(im_engine *e, int ch, int block, int keep_delay) {
#ifdef _WIN32
    _setmode(_fileno(stdin), _O_BINARY);
    _setmode(_fileno(stdout), _O_BINARY);
#endif
    int lat = keep_delay ? 0 : im_engine_latency(e);
    float *in = calloc((size_t)block * ch, sizeof(float)), *out = calloc((size_t)block * ch, sizeof(float));
    if (!in || !out) { fprintf(stderr, "out of memory\n"); return 1; }
    long skip = lat, flush = lat, frames = 0;
    int eof = 0;
    while (!eof || flush > 0) {
        int n = 0;
        if (!eof) {
            n = (int)fread(in, sizeof(float) * ch, (size_t)block, stdin);
            if (n < block) eof = 1;
            frames += n;
        }
        if (eof && n < block && flush > 0) { /* past the end: silence pushes the delayed tail out */
            int z = (int)(block - n < flush ? block - n : flush);
            memset(in + (size_t)n * ch, 0, sizeof(float) * (size_t)z * ch);
            n += z;
            flush -= z;
        }
        if (n == 0) break;
        im_engine_process_interleaved(e, in, out, n);
        int from = (int)(skip < n ? skip : n);
        skip -= from;
        if (n - from > 0 && fwrite(out + (size_t)from * ch, sizeof(float) * ch, (size_t)(n - from), stdout) != (size_t)(n - from)) {
            fprintf(stderr, "write failed\n");
            return 1;
        }
    }
    fflush(stdout);
    fprintf(stderr, "model=\"%s\" channels=%d frames=%ld latency=%d run_errors=%lu\n", im_engine_model_name(e), ch,
            frames, lat, im_engine_run_errors(e));
    return im_engine_run_errors(e) ? 1 : 0;
}

int main(int argc, char **argv) {
    const char *detector = NULL;
    unsigned policy = 0;
    const char *model = NULL, *inp = NULL, *outp = NULL;
    int mono = 0, keep_delay = 0, block = 256, aligned = 0, raw = 0, raw_ch = 2, raw_rate = 48000;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-m") && i + 1 < argc) model = argv[++i];
        else if (!strcmp(argv[i], "--mono")) mono = 1;
        else if (!strcmp(argv[i], "-d") && i + 1 < argc) detector = argv[++i];
        else if (!strcmp(argv[i], "--mute-female-singing")) policy |= IM_POLICY_MUTE_FEMALE_SINGING;
        else if (!strcmp(argv[i], "--mute-female-voice")) policy |= IM_POLICY_MUTE_FEMALE_VOICE;
        else if (!strcmp(argv[i], "--fail-closed")) policy |= IM_POLICY_FAIL_CLOSED;
        else if (!strcmp(argv[i], "--keep-delay")) keep_delay = 1;
        else if (!strcmp(argv[i], "--aligned")) aligned = 1; /* hop-aligned path, one hop less delay */
        else if (!strcmp(argv[i], "--block") && i + 1 < argc) block = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--raw")) raw = 1;
        else if (!strcmp(argv[i], "--channels") && i + 1 < argc) raw_ch = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--rate") && i + 1 < argc) raw_rate = atoi(argv[++i]);
        else if (!inp) inp = argv[i];
        else if (!outp) outp = argv[i];
    }
    if (raw) {
        if (!model || block <= 0 || raw_ch < 1 || raw_ch > 2 || raw_rate <= 0) {
            fprintf(stderr, "usage: im-process -m model.onnx [--mono] [-d ...] --raw [--channels 1|2] [--rate 48000] < in.f32 > out.f32\n");
            return 2;
        }
        char err[512];
        im_config cfg = {model, raw_ch, raw_rate, 1, mono, detector};
        im_engine *e = NULL;
        if (im_engine_create(&cfg, &e, err, sizeof err) != IM_OK) {
            fprintf(stderr, "engine: %s\n", err);
            im_engine_destroy(e);
            return 1;
        }
        if (detector && im_engine_detector_status(e, NULL) < 0) {
            fprintf(stderr, "%s\n", im_engine_detector_error(e));
            if (policy & IM_POLICY_FAIL_CLOSED) { im_engine_destroy(e); return 1; }
        }
        im_engine_set_policy(e, policy);
        int r = run_raw(e, raw_ch, block, keep_delay);
        im_engine_destroy(e);
        return r;
    }
    if (!model || !inp || !outp || block <= 0) {
        fprintf(stderr, "usage: im-process -m model.onnx [--mono] [-d detector.onnx --mute-female-singing|--mute-female-voice [--fail-closed]] [--keep-delay] [--block N] [--aligned] in.wav out.wav\n");
        return 2;
    }
    char err[512];
    wav_t w;
    if (!wav_read(inp, &w, err, sizeof err)) { fprintf(stderr, "read: %s\n", err); return 1; }
    im_config cfg = {model, w.channels, w.rate, 1, mono, detector};
    im_engine *e = NULL;
    if (im_engine_create(&cfg, &e, err, sizeof err) != IM_OK) {
        fprintf(stderr, "engine: %s\n", err);
        im_engine_destroy(e);
        wav_free(&w);
        return 1;
    }
    if (detector && im_engine_detector_status(e, NULL) < 0) fprintf(stderr, "%s\n", im_engine_detector_error(e));
    im_engine_set_policy(e, policy);
    long muted = 0, chunks = 0;
    int lat = aligned ? im_engine_aligned_latency(e) : im_engine_latency(e), ch = w.channels, hop = im_engine_hop(e);
    if (aligned) block = hop * (block / hop > 0 ? block / hop : 1);
    long total = w.frames + (keep_delay ? 0 : lat);
    if (aligned) total = (total + hop - 1) / hop * hop;
    float *in = calloc((size_t)total * ch, sizeof(float));
    float *out = calloc((size_t)total * ch, sizeof(float));
    if (!in || !out) { fprintf(stderr, "out of memory\n"); return 1; }
    memcpy(in, w.data, sizeof(float) * (size_t)w.frames * ch);
    double t0 = now();
    for (long i = 0; i < total; i += block) {
        int n = (int)(total - i < block ? total - i : block);
        if (aligned) im_engine_process_hops_interleaved(e, in + (size_t)i * ch, out + (size_t)i * ch, n / hop);
        else im_engine_process_interleaved(e, in + (size_t)i * ch, out + (size_t)i * ch, n);
        if (policy) { muted += im_engine_detector_status(e, NULL) == 1; chunks++; }
    }
    double dt = now() - t0;
    wav_t o = {ch, w.rate, w.frames, out + (keep_delay ? 0 : (size_t)lat * ch)};
    if (!wav_write_f32(outp, &o)) { fprintf(stderr, "write failed\n"); return 1; }
    double audio = (double)w.frames / w.rate;
    printf("model=\"%s\" channels=%d mono_mix=%d latency=%d samples (%.1f ms) rtf=%.3f run_errors=%lu\n",
           im_engine_model_name(e), ch, mono, lat, 1000.0 * lat / w.rate, dt / audio, im_engine_run_errors(e));
    if (policy) printf("policy=%u muted=%.1f%% of the time\n", policy, chunks ? 100.0 * muted / chunks : 0.0);
    im_engine_destroy(e);
    free(in); free(out); wav_free(&w);
    return 0;
}
