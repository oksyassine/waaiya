/* im-stream: real-time filter for raw float32 interleaved audio on stdin -> stdout.
 * Used by the Linux daemon:  parec (virtual output monitor) | im-stream | pacat (real output).
 * If the model cannot load it still runs and outputs silence (fail-closed).
 * Latency guard: audio waiting in the input or output pipe is pure added delay, and nothing downstream ever
 * removes it (measured: up to 2 s when playback and the filter start together). When either pipe holds more
 * than --max-backlog ms, whole blocks are dropped until it is back under the limit (0 = never drop).
 * Usage: im-stream -m model.onnx [--channels 2] [--rate 48000] [--block 480] [--mono] [--max-backlog 30] [-d detector.onnx --mute-female-singing|--mute-female-voice [--fail-closed]] */
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
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

/* Bytes waiting in a pipe (either end), or -1 if fd is not a pipe (files and terminals are never trimmed). */
static long pipe_queued(int fd) {
    struct stat st;
    int n = 0;
    if (fstat(fd, &st) != 0 || !S_ISFIFO(st.st_mode) || ioctl(fd, FIONREAD, &n) != 0) return -1;
    return n;
}

/* --status-file: what the engine loaded, for 'waaiya status' (one line: ok | model_failed <why> |
 * detector_failed <why>), written once at start, atomically. */
static void write_status(const char *path, const char *what, const char *why) {
    if (!path) return;
    char tmp[4096];
    snprintf(tmp, sizeof tmp, "%s.tmp", path);
    FILE *f = fopen(tmp, "w");
    if (!f) return;
    fprintf(f, "%s%s%s\n", what, why && *why ? " " : "", why ? why : "");
    if (fclose(f) == 0) rename(tmp, path);
    else remove(tmp);
}

int main(int argc, char **argv) {
    const char *detector = NULL;
    unsigned policy = 0;
    const char *model = NULL, *status_file = NULL;
    int ch = 2, rate = 48000, block = 480, mono = 0, threads = 1, max_backlog_ms = 30;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-m") && i + 1 < argc) model = argv[++i];
        else if (!strcmp(argv[i], "--channels") && i + 1 < argc) ch = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--rate") && i + 1 < argc) rate = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--block") && i + 1 < argc) block = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--threads") && i + 1 < argc) threads = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--max-backlog") && i + 1 < argc) max_backlog_ms = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--mono")) mono = 1;
        else if (!strcmp(argv[i], "--status-file") && i + 1 < argc) status_file = argv[++i];
        else if (!strcmp(argv[i], "-d") && i + 1 < argc) detector = argv[++i];
        else if (!strcmp(argv[i], "--mute-female-singing")) policy |= IM_POLICY_MUTE_FEMALE_SINGING;
        else if (!strcmp(argv[i], "--mute-female-voice")) policy |= IM_POLICY_MUTE_FEMALE_VOICE;
        else if (!strcmp(argv[i], "--fail-closed")) policy |= IM_POLICY_FAIL_CLOSED;
    }
    if (!model || ch < 1 || ch > 8 || block < 1) {
        fprintf(stderr, "usage: im-stream -m model.onnx [--channels 2] [--rate 48000] [--block 480] [--mono] [--max-backlog 30] [-d detector.onnx --mute-female-singing|--mute-female-voice [--fail-closed]] [--status-file PATH]\n");
        return 2;
    }
    char err[512];
    im_config cfg = {model, ch, rate, threads, mono, detector};
    im_engine *e = NULL;
    int created = im_engine_create(&cfg, &e, err, sizeof err) == IM_OK;
    /* whole hops per block: each hop's output leaves in the same call (one hop less delay) */
    int hop = im_engine_hop(e), aligned = hop > 0 && block % hop == 0;
    int lat = aligned ? im_engine_aligned_latency(e) : im_engine_latency(e);
    if (!created)
        fprintf(stderr, "im-stream: %s -> output muted (fail-closed)\n", err);
    else
        fprintf(stderr, "im-stream: \"%s\" ready, latency %d samples (%.1f ms)%s\n", im_engine_model_name(e),
                lat, 1000.0 * lat / rate, aligned ? ", hop-aligned" : "");
    if (detector && e && im_engine_detector_status(e, NULL) < 0)
        fprintf(stderr, "im-stream: %s%s\n", im_engine_detector_error(e),
                (policy & IM_POLICY_FAIL_CLOSED) ? " -> voice muted while the policy is on (fail-closed)" : "");
    im_engine_set_policy(e, policy);
    if (!created) write_status(status_file, "model_failed", err);
    else if (detector && im_engine_detector_status(e, NULL) < 0)
        write_status(status_file, "detector_failed", im_engine_detector_error(e));
    else write_status(status_file, "ok", NULL);
    size_t bytes = sizeof(float) * (size_t)block * ch;
    float *in = malloc(bytes), *out = malloc(bytes);
    if (!in || !out) return 1;
    long limit = (long)max_backlog_ms * rate / 1000 * ch * (long)sizeof(float);
    unsigned long dropped_in = 0, dropped_out = 0, reported = 0, since_report = 0;
    while (read_full(0, in, bytes)) {
        if (limit > 0) {
            /* behind on input: skip whole blocks so the next one processed is close to "now" */
            long q = pipe_queued(0);
            while (q > limit && q >= (long)bytes && read_full(0, in, bytes)) { dropped_in++; q -= (long)bytes; }
        }
        if (aligned) im_engine_process_hops_interleaved(e, in, out, block / hop);
        else im_engine_process_interleaved(e, in, out, block);
        /* output backlog (player side not draining fast enough): drop this block instead of queueing it */
        if (limit > 0 && pipe_queued(1) > limit) { dropped_out++; }
        else if (!write_full(1, out, bytes)) break;
        /* log drops at most once per ~10 s of audio so a misbehaving sound server cannot flood the log */
        if (dropped_in + dropped_out != reported && (reported == 0 || ++since_report * (unsigned long)block >= 10UL * (unsigned long)rate)) {
            since_report = 0;
            reported = dropped_in + dropped_out;
            fprintf(stderr, "im-stream: over %d ms behind, dropped %.0f ms so far (input %lu, output %lu blocks)\n",
                    max_backlog_ms, 1000.0 * (dropped_in + dropped_out) * block / rate, dropped_in, dropped_out);
        }
    }
    im_engine_destroy(e);
    free(in);
    free(out);
    return 0;
}
