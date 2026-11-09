/* im-process: run the streaming engine over a WAV file, exactly as a live sink would,
 * then remove the engine delay so the output lines up with the input.
 * Usage: im-process -m model.onnx [--mono] [-d detector.onnx --mute-female-singing|--mute-female-voice [--fail-closed]] [--keep-delay] [--block N] in.wav out.wav */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "im_engine.h"
#include "wav.h"

static double now(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec + t.tv_nsec * 1e-9; }

int main(int argc, char **argv) {
    const char *detector = NULL;
    unsigned policy = 0;
    const char *model = NULL, *inp = NULL, *outp = NULL;
    int mono = 0, keep_delay = 0, block = 256;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-m") && i + 1 < argc) model = argv[++i];
        else if (!strcmp(argv[i], "--mono")) mono = 1;
        else if (!strcmp(argv[i], "-d") && i + 1 < argc) detector = argv[++i];
        else if (!strcmp(argv[i], "--mute-female-singing")) policy |= IM_POLICY_MUTE_FEMALE_SINGING;
        else if (!strcmp(argv[i], "--mute-female-voice")) policy |= IM_POLICY_MUTE_FEMALE_VOICE;
        else if (!strcmp(argv[i], "--fail-closed")) policy |= IM_POLICY_FAIL_CLOSED;
        else if (!strcmp(argv[i], "--keep-delay")) keep_delay = 1;
        else if (!strcmp(argv[i], "--block") && i + 1 < argc) block = atoi(argv[++i]);
        else if (!inp) inp = argv[i];
        else if (!outp) outp = argv[i];
    }
    if (!model || !inp || !outp || block <= 0) {
        fprintf(stderr, "usage: im-process -m model.onnx [--mono] [-d detector.onnx --mute-female-singing|--mute-female-voice [--fail-closed]] [--keep-delay] [--block N] in.wav out.wav\n");
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
    int lat = im_engine_latency(e), ch = w.channels;
    long total = w.frames + (keep_delay ? 0 : lat);
    float *in = calloc((size_t)total * ch, sizeof(float));
    float *out = calloc((size_t)total * ch, sizeof(float));
    if (!in || !out) { fprintf(stderr, "out of memory\n"); return 1; }
    memcpy(in, w.data, sizeof(float) * (size_t)w.frames * ch);
    double t0 = now();
    for (long i = 0; i < total; i += block) {
        int n = (int)(total - i < block ? total - i : block);
        im_engine_process_interleaved(e, in + (size_t)i * ch, out + (size_t)i * ch, n);
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
