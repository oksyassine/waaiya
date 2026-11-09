/* im-stream: real-time filter for raw float32 interleaved audio on stdin -> stdout.
 * Used by the Linux daemon:  parec (virtual output monitor) | im-stream | pacat (real output).
 * If the model cannot load it still runs and outputs silence (fail-closed).
 * Usage: im-stream -m model.onnx [--channels 2] [--rate 48000] [--block 480] [--mono] [-d detector.onnx --mute-female-singing|--mute-female-voice [--fail-closed]] */
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "im_engine.h"

static int read_full(int fd, void *buf, size_t n) {
    size_t got = 0;
    while (got < n) {
        ssize_t r = read(fd, (char *)buf + got, n - got);
        if (r == 0) return 0;
        if (r < 0) { if (errno == EINTR) continue; return 0; }
        got += (size_t)r;
    }
    return 1;
}

static int write_full(int fd, const void *buf, size_t n) {
    size_t put = 0;
    while (put < n) {
        ssize_t r = write(fd, (const char *)buf + put, n - put);
        if (r < 0) { if (errno == EINTR) continue; return 0; }
        put += (size_t)r;
    }
    return 1;
}

int main(int argc, char **argv) {
    const char *detector = NULL;
    unsigned policy = 0;
    const char *model = NULL;
    int ch = 2, rate = 48000, block = 480, mono = 0, threads = 1;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-m") && i + 1 < argc) model = argv[++i];
        else if (!strcmp(argv[i], "--channels") && i + 1 < argc) ch = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--rate") && i + 1 < argc) rate = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--block") && i + 1 < argc) block = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--threads") && i + 1 < argc) threads = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--mono")) mono = 1;
        else if (!strcmp(argv[i], "-d") && i + 1 < argc) detector = argv[++i];
        else if (!strcmp(argv[i], "--mute-female-singing")) policy |= IM_POLICY_MUTE_FEMALE_SINGING;
        else if (!strcmp(argv[i], "--mute-female-voice")) policy |= IM_POLICY_MUTE_FEMALE_VOICE;
        else if (!strcmp(argv[i], "--fail-closed")) policy |= IM_POLICY_FAIL_CLOSED;
    }
    if (!model || ch < 1 || ch > 8 || block < 1) {
        fprintf(stderr, "usage: im-stream -m model.onnx [--channels 2] [--rate 48000] [--block 480] [--mono] [-d detector.onnx --mute-female-singing|--mute-female-voice [--fail-closed]]\n");
        return 2;
    }
    char err[512];
    im_config cfg = {model, ch, rate, threads, mono, detector};
    im_engine *e = NULL;
    if (im_engine_create(&cfg, &e, err, sizeof err) != IM_OK)
        fprintf(stderr, "im-stream: %s -> output muted (fail-closed)\n", err);
    else
        fprintf(stderr, "im-stream: \"%s\" ready, latency %d samples (%.1f ms)\n", im_engine_model_name(e),
                im_engine_latency(e), 1000.0 * im_engine_latency(e) / rate);
    if (detector && e && im_engine_detector_status(e, NULL) < 0)
        fprintf(stderr, "im-stream: %s%s\n", im_engine_detector_error(e),
                (policy & IM_POLICY_FAIL_CLOSED) ? " -> voice muted while the policy is on (fail-closed)" : "");
    im_engine_set_policy(e, policy);
    size_t bytes = sizeof(float) * (size_t)block * ch;
    float *in = malloc(bytes), *out = malloc(bytes);
    if (!in || !out) return 1;
    while (read_full(0, in, bytes)) {
        im_engine_process_interleaved(e, in, out, block);
        if (!write_full(1, out, bytes)) break;
    }
    im_engine_destroy(e);
    free(in);
    free(out);
    return 0;
}
