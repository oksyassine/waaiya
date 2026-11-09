/* im-pulse: the Linux live filter in one process, talking to PulseAudio (or pipewire-pulse) directly.
 *
 *   record <source> (the "Islamic Mute" null-sink monitor) -> engine, whole hops -> play <sink> (real output)
 *
 * Replaces  parec | im-stream | pacat.  Why: pipes and pacat's server-side buffer hide how much audio is
 * queued, so every playback underrun added 6-10 ms of delay that stayed until restart. Here the record
 * callback hands whole hops to a worker thread, which runs the engine (outside the mainloop lock) and writes
 * straight to the playback stream. Before each write the playback latency (pa_stream_get_latency, timing
 * refreshed after every write) is held at --target-ms: more than half a hop above it for ~100 ms, or more than
 * two hops above at once (the late audio after an underrun or a stall), the oldest pending input is dropped;
 * below it for ~100 ms, silence is written first. While the stream is stopped (start, after an underrun) the
 * queue is filled to the target and no more. Optional (--max-target-ms above the target): clusters of underruns
 * (3 within 10 s) raise the target by 5 ms up to that maximum, and it decays by 1 ms per quiet 10 s. Off by
 * default: under CPU load it raised the delay to the pipe's level without reducing underruns. Every correction is logged, with
 * stats every --stats-s seconds.
 * Total delay is about engine look-ahead (30 ms) + target + 3 ms.
 * Fail-closed: if the engine cannot load or a call fails, silence is written, never the unfiltered input.
 * Exits 1 if the server connection or a stream fails (the daemon restarts it), 3 if libpulse.so.0 is missing.
 *
 * Usage: im-pulse -m model.onnx --sink <real sink> [--source islamic_mute.monitor] [--target-ms 35] [--max-target-ms 0]
 *                 [--mono] [--threads 1] [-d detector.onnx --mute-female-singing|--mute-female-voice [--fail-closed]]
 *                 [--channels 2] [--rate 48000] [--minreq-ms 10] [--stats-s 10]
 * libpulse is loaded with dlopen (cli/pulse_dl.h), so building needs no libpulse-dev. */
#include <dlfcn.h>
#include <math.h>
#include <pthread.h>
#include <signal.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "im_engine.h"
#include "pulse_dl.h"

/* ---- libpulse loaded at run time ---- */
static struct {
#define IMPA_PTR(r, n, a) r (*n) a;
    IMPA_FUNCS(IMPA_PTR)
#undef IMPA_PTR
} pa;

static int load_libpulse(char *err, size_t errlen) {
    void *h = dlopen("libpulse.so.0", RTLD_NOW | RTLD_LOCAL);
    if (!h) { snprintf(err, errlen, "cannot load libpulse.so.0 (%s)", dlerror()); return -1; }
#define IMPA_SYM(r, n, a) \
    if (!(*(void **)&pa.n = dlsym(h, #n))) { snprintf(err, errlen, "libpulse.so.0 lacks %s", #n); return -1; }
    IMPA_FUNCS(IMPA_SYM)
#undef IMPA_SYM
    return 0;
}

/* ---- state: touched only with the mainloop lock held (the mainloop thread holds it during callbacks) ---- */
typedef struct {
    int ch, rate, hop;
    size_t frame, hop_bytes;
    pa_usec_t hop_us, target_us;
    /* Optional adaptive target (--max-target-ms > --target-ms): raised by 5 ms when underruns come in clusters
     * (3 within 10 s) up to the maximum, lowered by 1 ms per 10 s without an underrun. */
    double cur_target_us, max_target_us, last_raise_t, last_under_t, last_decay_t;
    int cluster;
    pa_threaded_mainloop *ml;
    pa_context *ctx;
    pa_stream *rec, *play;
    im_engine *e;
    unsigned char *acc; /* captured, not yet processed input */
    size_t acc_len, acc_cap;
    float *work, *out;  /* engine input and output (worker thread only), acc_cap bytes each */
    pthread_t worker;
    int worker_started, stop;
    float *zeros;       /* pad_max silent hops */
    int pad_max, trace;
    int hi_run, lo_run;  /* controller state */
    double compute_us;   /* engine time per hop, smoothed */
    int failed;         /* a stream or the connection failed: exit and let the daemon restart us */
    char why[256];
    double t0;
    /* totals */
    unsigned long hops, underflows, overflows, engine_fail_hops, holes, corrections;
    double dropped_us, padded_us;
    /* window since the last stats line */
    unsigned long w_corr_logged, w_under, w_n;
    double w_drop_us, w_pad_us;
    double w_lvl_sum, w_lvl_min, w_lvl_max, w_rec_sum;
} app_t;

static app_t A;

static double now_s(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec * 1e-9;
}

static void logf_(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "im-pulse [%8.1f s]: ", now_s() - A.t0);
    vfprintf(stderr, fmt, ap);
    fputc('\n', stderr);
    va_end(ap);
}

static void fail(const char *what) {
    if (!A.failed) {
        A.failed = 1;
        snprintf(A.why, sizeof A.why, "%s: %s", what, A.ctx ? pa.pa_strerror(pa.pa_context_errno(A.ctx)) : "?");
    }
    pa.pa_threaded_mainloop_signal(A.ml, 0);
}

/* Playback latency in µs (queued + sink), or -1 if PulseAudio has no timing data yet. */
static double play_latency_us(void) {
    pa_usec_t l = 0;
    int neg = 0;
    if (pa.pa_stream_get_latency(A.play, &l, &neg) < 0) return -1;
    return neg ? 0.0 : (double)l;
}

static void log_correction(const char *fmt, ...) {
    /* every correction is logged, up to 5 lines per stats window; the rest are counted in the stats line */
    if (A.w_corr_logged++ >= 5) {
        if (A.w_corr_logged == 6) logf_("more corrections in this window, counted in the next stats line");
        return;
    }
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "im-pulse [%8.1f s]: ", now_s() - A.t0);
    vfprintf(stderr, fmt, ap);
    fputc('\n', stderr);
    va_end(ap);
}

/* How much of the n pending hops to drop, or how much silence to write first (frames), so that the playback
 * latency right after the write is at the target. Lock held. */
static void decide(int n, long *drop_out, long *pad_out) {
    double now = now_s();
    if (A.cur_target_us > A.target_us && now - A.last_under_t > 10 && now - A.last_decay_t > 10) {
        A.cur_target_us = fmax((double)A.target_us, A.cur_target_us - 1000);
        A.last_decay_t = now;
        if (A.cur_target_us == A.target_us) logf_("target back to %.1f ms", A.cur_target_us / 1e3);
    }
    double lat = play_latency_us(), hop = (double)A.hop_us, target = A.cur_target_us, fr_us = 1e6 / A.rate;
    long drop = 0, pad = 0; /* frames */
    double shown = lat;     /* playback latency (or queue while stopped) for the log */
    const pa_timing_info *ti = pa.pa_stream_get_timing_info(A.play);
    if (!ti || !ti->playing) {
        /* Stopped (start, or prebuffering after an underrun): the reported latency is not moving, so use the
         * queue itself and fill it up to the target only; audio that arrives late after a stall is cut here
         * instead of being queued and played late. At least one hop is always written, so the queue reaches
         * prebuf (<= target) and the stream restarts. */
        lat = -1;
        A.hi_run = A.lo_run = 0;
        if (ti && !ti->write_index_corrupt && !ti->read_index_corrupt) {
            double queued = (double)(ti->write_index - ti->read_index) / (double)A.frame * fr_us;
            shown = queued;
            long keep = lround((target - queued) / fr_us);
            if (keep < A.hop) keep = A.hop;
            if (keep < (long)n * A.hop) drop = (long)n * A.hop - keep;
            if (A.trace)
                fprintf(stderr, "trace %.4f new %d stopped, queued %.2f ms -> drop %.2f ms\n", now_s() - A.t0, n,
                        queued / 1e3, drop * fr_us / 1e3);
        }
    }
    if (lat >= 0) {
        /* The playback latency right after this write (latency now + new audio - compute time) is held at the
         * target. Too high: drop the oldest pending input (whole hops before the engine, a remainder from the
         * start of its output); this removes the delay an underrun or a stall left behind. Too low (start, clock
         * drift): write the missing time as silence first. A burst of more than 2 hops is cut at once; a deviation
         * of more than half a hop only once it has lasted PERSIST callbacks (~100 ms), so arrival jitter and
         * small phase shifts cause no audible corrections. Nothing is inserted right after an underrun: the late
         * audio is still on its way and would only be cut again. */
        enum { PERSIST = 10 };
        const double tol = hop / 2;
        double lvl = lat + n * (hop - A.compute_us), dev = lvl - target;
        A.hi_run = dev > tol ? A.hi_run + 1 : 0;
        A.lo_run = dev < -tol ? A.lo_run + 1 : 0;
        if (dev > 2 * hop || A.hi_run >= PERSIST) {
            drop = lround(dev / fr_us);
            if (drop > (long)n * A.hop) drop = (long)n * A.hop;
        } else if (A.lo_run >= PERSIST) {
            pad = lround(-dev / fr_us);
            if (pad > (long)A.pad_max * A.hop) pad = (long)A.pad_max * A.hop;
        }
        if (drop || pad) A.hi_run = A.lo_run = 0;
        lvl += (pad - drop) * fr_us;
        if (A.w_n == 0 || lvl < A.w_lvl_min) A.w_lvl_min = lvl;
        if (A.w_n == 0 || lvl > A.w_lvl_max) A.w_lvl_max = lvl;
        A.w_lvl_sum += lvl;
        A.w_n++;
        if (A.trace)
            fprintf(stderr, "trace %.4f new %d latency %.2f compute %.2f -> level %.2f ms, drop %.2f pad %.2f ms\n",
                    now_s() - A.t0, n, lat / 1e3, A.compute_us / 1e3, lvl / 1e3, drop * fr_us / 1e3, pad * fr_us / 1e3);
    }
    if (drop > 0) {
        A.dropped_us += drop * fr_us;
        A.w_drop_us += drop * fr_us;
        A.corrections++;
        log_correction("correction: playback %.1f ms + %d new hops, target %.1f ms -> dropped %.1f ms of input",
                       shown / 1e3, n, target / 1e3, drop * fr_us / 1e3);
    }
    if (pad > 0) {
        A.padded_us += pad * fr_us;
        A.w_pad_us += pad * fr_us;
        A.corrections++;
        log_correction("correction: playback %.1f ms + %d new hops, target %.1f ms -> inserted %.1f ms of silence",
                       shown / 1e3, n, target / 1e3, pad * fr_us / 1e3);
    }
    *drop_out = drop;
    *pad_out = pad;
}

/* Worker thread: takes pending hops, runs the engine without the lock (so the mainloop thread keeps serving the
 * server while the engine computes; computing inside the read callback caused many more underruns) and writes. */
static void *worker_main(void *arg) {
    (void)arg;
    pa.pa_threaded_mainloop_lock(A.ml);
    while (!A.stop && !A.failed) {
        int n = (int)(A.acc_len / A.hop_bytes);
        if (n == 0) {
            pa.pa_threaded_mainloop_wait(A.ml);
            continue;
        }
        long drop = 0, pad = 0;
        decide(n, &drop, &pad);
        int dh = (int)(drop / A.hop), np = n - dh, skip = (int)(drop % A.hop);
        if (np > 0) memcpy(A.work, A.acc + (size_t)dh * A.hop_bytes, (size_t)np * A.hop_bytes);
        size_t used = (size_t)n * A.hop_bytes;
        memmove(A.acc, A.acc + used, A.acc_len - used);
        A.acc_len -= used;
        A.hops += (unsigned long)n;
        pa.pa_threaded_mainloop_unlock(A.ml);

        double t = now_s();
        int silent = 0;
        /* fail-closed: anything the engine did not produce is written as silence, never as the input */
        if (np > 0 && (!A.e || im_engine_failed(A.e) || im_engine_process_hops_interleaved(A.e, A.work, A.out, np) != 0)) {
            memset(A.out, 0, (size_t)np * A.hop_bytes);
            silent = np;
        }
        double dt = now_s() - t;

        pa.pa_threaded_mainloop_lock(A.ml);
        if (A.stop || A.failed) break;
        if (np > 0) A.compute_us += 0.05 * (dt * 1e6 / np - A.compute_us);
        A.engine_fail_hops += (unsigned long)silent;
        size_t bytes = (size_t)np * A.hop_bytes, sb = (size_t)skip * A.frame;
        if ((pad > 0 && pa.pa_stream_write(A.play, A.zeros, (size_t)pad * A.frame, NULL, 0, PA_SEEK_RELATIVE) < 0) ||
            (sb < bytes && pa.pa_stream_write(A.play, (const char *)A.out + sb, bytes - sb, NULL, 0, PA_SEEK_RELATIVE) < 0)) {
            fail("playback write failed");
            break;
        }
        /* fresh timing data for the next decision: interpolating from the automatic updates (which back off to
         * 1.5 s apart) was measured ~10 ms off; one small request per write keeps it within a fraction of a ms */
        pa_operation *o = pa.pa_stream_update_timing_info(A.play, NULL, NULL);
        if (o) pa.pa_operation_unref(o);
    }
    pa.pa_threaded_mainloop_unlock(A.ml);
    return NULL;
}

static void append(const void *data, size_t n) {
    if (n > A.acc_cap) { /* more than the whole buffer at once: keep the newest part */
        if (data) data = (const unsigned char *)data + (n - A.acc_cap);
        n = A.acc_cap;
    }
    if (A.acc_len + n > A.acc_cap) { /* should not happen (we process on every read): drop the oldest */
        size_t over = A.acc_len + n - A.acc_cap;
        over = (over + A.hop_bytes - 1) / A.hop_bytes * A.hop_bytes;
        if (over > A.acc_len) over = A.acc_len;
        memmove(A.acc, A.acc + over, A.acc_len - over);
        A.acc_len -= over;
        A.dropped_us += (double)(over / A.frame) * 1e6 / A.rate;
    }
    if (data) memcpy(A.acc + A.acc_len, data, n);
    else memset(A.acc + A.acc_len, 0, n);
    A.acc_len += n;
}

static void read_cb(pa_stream *s, size_t nbytes, void *ud) {
    (void)nbytes; (void)ud;
    for (;;) {
        const void *data = NULL;
        size_t n = 0;
        if (pa.pa_stream_peek(s, &data, &n) < 0) { fail("capture read failed"); return; }
        if (n == 0) break;          /* nothing left */
        if (!data) A.holes++;       /* hole in the capture: treated as silence */
        append(data, n);
        pa.pa_stream_drop(s);
    }
    pa.pa_threaded_mainloop_signal(A.ml, 0); /* wake the worker */
}

static void underflow_cb(pa_stream *s, void *ud) {
    (void)s; (void)ud;
    A.underflows++;
    A.w_under++;
    if (A.trace) fprintf(stderr, "trace %.4f underrun\n", now_s() - A.t0);
    double now = now_s();
    A.cluster = now - A.last_under_t < 10 ? A.cluster + 1 : 1;
    A.last_under_t = A.last_decay_t = now;
    log_correction("underrun: playback ran dry, re-prebuffering to %.1f ms", A.cur_target_us / 1e3);
    if (A.cluster >= 3 && now - A.last_raise_t > 1 && A.cur_target_us < A.max_target_us) {
        A.cur_target_us = fmin(A.max_target_us, A.cur_target_us + 5000);
        A.last_raise_t = now;
        A.cluster = 0;
        logf_("repeated underruns: target raised to %.1f ms (max %.1f)", A.cur_target_us / 1e3, A.max_target_us / 1e3);
    }
}

static void overflow_cb(pa_stream *s, void *ud) {
    (void)s; (void)ud;
    A.overflows++;
    logf_("overflow: playback buffer full (data lost)");
}

static void ctx_state_cb(pa_context *c, void *ud) {
    (void)ud;
    pa_context_state_t st = pa.pa_context_get_state(c);
    if (st == PA_CONTEXT_FAILED || st == PA_CONTEXT_TERMINATED) fail("server connection lost");
    pa.pa_threaded_mainloop_signal(A.ml, 0);
}

static void stream_state_cb(pa_stream *s, void *ud) {
    pa_stream_state_t st = pa.pa_stream_get_state(s);
    if (st == PA_STREAM_FAILED || st == PA_STREAM_TERMINATED) fail((const char *)ud);
    pa.pa_threaded_mainloop_signal(A.ml, 0);
}

/* waits (lock held) until the stream is ready; 0 on success */
static int wait_stream(pa_stream *s) {
    for (;;) {
        pa_stream_state_t st = pa.pa_stream_get_state(s);
        if (st == PA_STREAM_READY) return 0;
        if (st == PA_STREAM_FAILED || st == PA_STREAM_TERMINATED || A.failed) return -1;
        pa.pa_threaded_mainloop_wait(A.ml);
    }
}

static void stats_line(void) {
    pa_usec_t rl = 0;
    int neg = 0;
    double rec_ms = pa.pa_stream_get_latency(A.rec, &rl, &neg) < 0 || neg ? 0 : rl / 1e3;
    double eng_ms = A.e ? 1e3 * im_engine_aligned_latency(A.e) / A.rate : 0;
    if (A.w_n) {
        double avg = A.w_lvl_sum / A.w_n / 1e3;
        logf_("stats: playback latency after write avg %.1f ms (min %.1f, max %.1f, target %.1f), capture %.1f ms,"
              " engine %.1f ms -> about %.0f ms total + compute | window: %lu underruns, %.0f ms dropped, %.0f ms inserted",
              avg, A.w_lvl_min / 1e3, A.w_lvl_max / 1e3, A.cur_target_us / 1e3, rec_ms, eng_ms, avg + rec_ms + eng_ms, A.w_under,
              A.w_drop_us / 1e3, A.w_pad_us / 1e3);
    }
    logf_("totals: %lu underruns, %lu corrections, %.0f ms dropped, %.0f ms inserted, %lu overflows, %lu silent hops"
          " from the engine (fail-closed), %lu capture holes",
          A.underflows, A.corrections, A.dropped_us / 1e3, A.padded_us / 1e3, A.overflows,
          A.engine_fail_hops, A.holes);
    A.w_n = 0; A.w_lvl_sum = 0; A.w_drop_us = 0; A.w_pad_us = 0; A.w_under = 0; A.w_corr_logged = 0;
}

static void usage(void) {
    fprintf(stderr, "usage: im-pulse -m model.onnx --sink <sink> [--source islamic_mute.monitor] [--target-ms 35] [--max-target-ms 0]\n"
                    "                [--mono] [--threads 1] [-d detector.onnx --mute-female-singing|--mute-female-voice [--fail-closed]]\n"
                    "                [--channels 2] [--rate 48000] [--minreq-ms 10] [--stats-s 10]\n");
}

int main(int argc, char **argv) {
    const char *model = NULL, *detector = NULL, *source = "islamic_mute.monitor", *sink = NULL;
    unsigned policy = 0;
    int ch = 2, rate = 48000, mono = 0, threads = 1;
    double target_ms = 35, max_target_ms = 0, minreq_ms = 10, stats_s = 10;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-m") && i + 1 < argc) model = argv[++i];
        else if (!strcmp(argv[i], "--source") && i + 1 < argc) source = argv[++i];
        else if (!strcmp(argv[i], "--sink") && i + 1 < argc) sink = argv[++i];
        else if (!strcmp(argv[i], "--target-ms") && i + 1 < argc) target_ms = atof(argv[++i]);
        else if (!strcmp(argv[i], "--max-target-ms") && i + 1 < argc) max_target_ms = atof(argv[++i]);
        else if (!strcmp(argv[i], "--minreq-ms") && i + 1 < argc) minreq_ms = atof(argv[++i]);
        else if (!strcmp(argv[i], "--stats-s") && i + 1 < argc) stats_s = atof(argv[++i]);
        else if (!strcmp(argv[i], "--channels") && i + 1 < argc) ch = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--rate") && i + 1 < argc) rate = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--threads") && i + 1 < argc) threads = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--mono")) mono = 1;
        else if (!strcmp(argv[i], "-d") && i + 1 < argc) detector = argv[++i];
        else if (!strcmp(argv[i], "--mute-female-singing")) policy |= IM_POLICY_MUTE_FEMALE_SINGING;
        else if (!strcmp(argv[i], "--mute-female-voice")) policy |= IM_POLICY_MUTE_FEMALE_VOICE;
        else if (!strcmp(argv[i], "--fail-closed")) policy |= IM_POLICY_FAIL_CLOSED;
        else { usage(); return 2; }
    }
    if (!model || !sink || ch < 1 || ch > 8 || rate < 8000 || target_ms <= 0 || minreq_ms <= 0) { usage(); return 2; }
    A.t0 = now_s();
    char err[512];
    if (load_libpulse(err, sizeof err) != 0) { logf_("%s", err); return 3; }

    im_config cfg = {model, ch, rate, threads, mono, detector};
    if (im_engine_create(&cfg, &A.e, err, sizeof err) != IM_OK) logf_("%s -> output muted (fail-closed)", err);
    im_engine_set_policy(A.e, policy);
    A.hop = im_engine_hop(A.e) > 0 ? im_engine_hop(A.e) : rate / 100; /* failed engine: still run, silent */
    if (detector && A.e && im_engine_detector_status(A.e, NULL) < 0)
        logf_("%s%s", im_engine_detector_error(A.e),
              (policy & IM_POLICY_FAIL_CLOSED) ? " -> voice muted while the policy is on (fail-closed)" : "");
    A.ch = ch; A.rate = rate;
    A.frame = sizeof(float) * (size_t)ch;
    A.hop_bytes = A.frame * (size_t)A.hop;
    A.hop_us = (pa_usec_t)A.hop * 1000000u / (pa_usec_t)rate;
    A.target_us = (pa_usec_t)(target_ms * 1000);
    A.cur_target_us = (double)A.target_us;
    A.max_target_us = fmax(max_target_ms, target_ms) * 1000;
    A.acc_cap = A.hop_bytes * (size_t)((rate + A.hop - 1) / A.hop); /* about 1 s */
    A.acc = malloc(A.acc_cap);
    A.out = malloc(A.acc_cap);
    A.work = malloc(A.acc_cap);
    A.pad_max = (int)(A.max_target_us / A.hop_us) + 2;
    A.zeros = calloc((size_t)A.pad_max, A.hop_bytes);
    A.trace = getenv("IM_PULSE_TRACE") != NULL;
    if (!A.acc || !A.out || !A.work || !A.zeros) return 1;

    /* signals are taken synchronously by the main thread; the other threads inherit the blocked mask */
    sigset_t sigs;
    sigemptyset(&sigs);
    sigaddset(&sigs, SIGINT); sigaddset(&sigs, SIGTERM); sigaddset(&sigs, SIGHUP);
    sigprocmask(SIG_BLOCK, &sigs, NULL);

    A.ml = pa.pa_threaded_mainloop_new();
    if (!A.ml) { logf_("cannot create mainloop"); return 1; }
    A.ctx = pa.pa_context_new(pa.pa_threaded_mainloop_get_api(A.ml), "Islamic Mute");
    pa.pa_context_set_state_callback(A.ctx, ctx_state_cb, NULL);
    pa.pa_threaded_mainloop_lock(A.ml);
    int rc = 1;
    if (pa.pa_threaded_mainloop_start(A.ml) < 0 || pa.pa_context_connect(A.ctx, NULL, PA_CONTEXT_NOAUTOSPAWN, NULL) < 0) {
        logf_("cannot connect to the sound server: %s", pa.pa_strerror(pa.pa_context_errno(A.ctx)));
        pa.pa_threaded_mainloop_unlock(A.ml);
        goto out;
    }
    for (;;) {
        pa_context_state_t st = pa.pa_context_get_state(A.ctx);
        if (st == PA_CONTEXT_READY) break;
        if (st == PA_CONTEXT_FAILED || st == PA_CONTEXT_TERMINATED) {
            logf_("cannot connect to the sound server: %s", pa.pa_strerror(pa.pa_context_errno(A.ctx)));
            pa.pa_threaded_mainloop_unlock(A.ml);
            goto out;
        }
        pa.pa_threaded_mainloop_wait(A.ml);
    }

    pa_sample_spec ss = {PA_SAMPLE_FLOAT32LE, (uint32_t)rate, (uint8_t)ch};
    const pa_stream_flags_t fl = PA_STREAM_ADJUST_LATENCY | PA_STREAM_INTERPOLATE_TIMING | PA_STREAM_AUTO_TIMING_UPDATE |
                                 PA_STREAM_DONT_MOVE; /* never follow a device change: we would feed ourselves */
    /* playback: tlength = target, minreq = one hop; prebuf asks for the target (the server caps it at about
     * tlength - minreq), so a restart after an underrun never waits for more than the target */
    uint32_t tbytes = (uint32_t)((double)A.target_us * rate / 1e6) * (uint32_t)A.frame;
    uint32_t mbytes = (uint32_t)(minreq_ms * rate / 1e3) * (uint32_t)A.frame;
    pa_buffer_attr pb = {(uint32_t)-1, tbytes, tbytes, mbytes, (uint32_t)-1};
    A.play = pa.pa_stream_new(A.ctx, "filtered output", &ss, NULL);
    if (!A.play) { logf_("cannot create playback stream"); pa.pa_threaded_mainloop_unlock(A.ml); goto out; }
    pa.pa_stream_set_state_callback(A.play, stream_state_cb, "playback stream failed (sink gone?)");
    pa.pa_stream_set_underflow_callback(A.play, underflow_cb, NULL);
    pa.pa_stream_set_overflow_callback(A.play, overflow_cb, NULL);
    if (pa.pa_stream_connect_playback(A.play, sink, &pb, fl, NULL, NULL) < 0 || wait_stream(A.play) < 0) {
        logf_("cannot play to %s: %s", sink, pa.pa_strerror(pa.pa_context_errno(A.ctx)));
        pa.pa_threaded_mainloop_unlock(A.ml);
        goto out;
    }
    /* refuse to play into the sink we record from (that would loop our own output back in) */
    const char *dev = pa.pa_stream_get_device_name(A.play);
    size_t dl = dev ? strlen(dev) : 0;
    if (dev && !strncmp(source, dev, dl) && !strcmp(source + dl, ".monitor")) {
        logf_("refusing to play into %s: it is the sink being filtered", dev);
        pa.pa_threaded_mainloop_unlock(A.ml);
        goto out;
    }
    /* capture: one hop per fragment */
    pa_buffer_attr rb = {(uint32_t)-1, (uint32_t)-1, (uint32_t)-1, (uint32_t)-1, (uint32_t)A.hop_bytes};
    A.rec = pa.pa_stream_new(A.ctx, "filter input", &ss, NULL);
    if (!A.rec) { logf_("cannot create capture stream"); pa.pa_threaded_mainloop_unlock(A.ml); goto out; }
    pa.pa_stream_set_state_callback(A.rec, stream_state_cb, "capture stream failed (source gone?)");
    pa.pa_stream_set_read_callback(A.rec, read_cb, NULL);
    if (pa.pa_stream_connect_record(A.rec, source, &rb, fl) < 0 || wait_stream(A.rec) < 0) {
        logf_("cannot record from %s: %s", source, pa.pa_strerror(pa.pa_context_errno(A.ctx)));
        pa.pa_threaded_mainloop_unlock(A.ml);
        goto out;
    }
    const pa_buffer_attr *pa_ = pa.pa_stream_get_buffer_attr(A.play), *ra = pa.pa_stream_get_buffer_attr(A.rec);
    double bpms = A.frame * rate / 1e3;
    logf_("\"%s\" %s, engine latency %.1f ms (hop-aligned), %s -> %s, target playback latency %.1f ms",
          A.e ? im_engine_model_name(A.e) : "?", A.e && !im_engine_failed(A.e) ? "ready" : "NOT LOADED (silent)",
          A.e ? 1e3 * im_engine_aligned_latency(A.e) / rate : 0.0, source, dev, A.target_us / 1e3);
    if (pa_ && ra)
        logf_("buffers granted: playback tlength %.1f prebuf %.1f minreq %.1f ms, capture fragsize %.1f ms",
              pa_->tlength / bpms, pa_->prebuf / bpms, pa_->minreq / bpms, ra->fragsize / bpms);
    if (pthread_create(&A.worker, NULL, worker_main, NULL) != 0) {
        logf_("cannot start the worker thread");
        pa.pa_threaded_mainloop_unlock(A.ml);
        goto out;
    }
    A.worker_started = 1;
    pa.pa_threaded_mainloop_unlock(A.ml);

    /* main thread: wait for a signal or a failure, print stats every stats_s seconds */
    double next = now_s() + stats_s;
    rc = 0;
    for (;;) {
        struct timespec to = {0, 200 * 1000000L};
        int sig = sigtimedwait(&sigs, NULL, &to);
        if (sig > 0) {
            pa.pa_threaded_mainloop_lock(A.ml);
            stats_line();
            pa.pa_threaded_mainloop_unlock(A.ml);
            logf_("signal %d, stopping", sig);
            break;
        }
        pa.pa_threaded_mainloop_lock(A.ml);
        int failed = A.failed;
        if (!failed && stats_s > 0 && now_s() >= next) { stats_line(); next += stats_s; }
        pa.pa_threaded_mainloop_unlock(A.ml);
        if (failed) { logf_("%s, exiting", A.why); rc = 1; break; }
    }

out:
    if (A.ml) {
        pa.pa_threaded_mainloop_lock(A.ml);
        A.stop = 1;
        pa.pa_threaded_mainloop_signal(A.ml, 0);
        pa.pa_threaded_mainloop_unlock(A.ml);
        if (A.worker_started) pthread_join(A.worker, NULL);
        pa.pa_threaded_mainloop_lock(A.ml);
        A.failed = 1; /* from here on, state changes are our own doing */
        if (A.rec) { pa.pa_stream_set_read_callback(A.rec, NULL, NULL); pa.pa_stream_disconnect(A.rec); pa.pa_stream_unref(A.rec); }
        if (A.play) { pa.pa_stream_disconnect(A.play); pa.pa_stream_unref(A.play); }
        if (A.ctx) { pa.pa_context_disconnect(A.ctx); pa.pa_context_unref(A.ctx); }
        pa.pa_threaded_mainloop_unlock(A.ml);
        pa.pa_threaded_mainloop_stop(A.ml);
        pa.pa_threaded_mainloop_free(A.ml);
    }
    im_engine_destroy(A.e);
    free(A.acc);
    free(A.out);
    free(A.work);
    free(A.zeros);
    return rc;
}
