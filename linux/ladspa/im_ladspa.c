/* LADSPA wrapper around the islamic-mute engine.
 * Labels: islamic_mute_stereo (2 in / 2 out), islamic_mute_mono (1 in / 1 out).
 * Model path: $IM_MODEL, else the first line of $XDG_CONFIG_HOME/islamic-mute/model,
 * else ~/.local/share/islamic-mute/models/default.onnx.
 * Fail-closed: if the model cannot run, the plugin outputs silence.
 * The "latency" output port reports the delay so PipeWire can compensate video. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sched.h>

#include "im_engine.h"
#include "ladspa_abi.h"

#define VISIBLE __attribute__((visibility("default")))

enum { MAXP = 6 };

typedef struct {
    int ch;
    im_engine *e;
    LADSPA_Data *in[2], *out[2];
    LADSPA_Data *enabled, *latency;
    double busy_ms; /* compute time since our last voluntary sleep (spans calls) */
} inst_t;

static void model_path(char *buf, size_t n) {
    const char *env = getenv("IM_MODEL");
    if (env && *env) { snprintf(buf, n, "%s", env); return; }
    const char *home = getenv("HOME");
    const char *xdg = getenv("XDG_CONFIG_HOME");
    char cfg[1024];
    if (xdg && *xdg) snprintf(cfg, sizeof cfg, "%s/islamic-mute/model", xdg);
    else snprintf(cfg, sizeof cfg, "%s/.config/islamic-mute/model", home ? home : "");
    FILE *f = fopen(cfg, "r");
    if (f) {
        if (fgets(buf, (int)n, f)) {
            buf[strcspn(buf, "\r\n")] = 0;
            fclose(f);
            if (*buf) return;
        } else {
            fclose(f);
        }
    }
    snprintf(buf, n, "%s/.local/share/islamic-mute/models/default.onnx", home ? home : "");
}

static int debug_on(void) { const char *v = getenv("IM_DEBUG"); return v && *v == '1'; }
static double now_ms(void);

static LADSPA_Handle instantiate(const LADSPA_Descriptor *d, unsigned long rate) {
    double t_start = now_ms();
    inst_t *p = calloc(1, sizeof *p);
    if (!p) return NULL;
    p->ch = (int)(long)d->ImplementationData;
    char path[1024], err[512];
    model_path(path, sizeof path);
    const char *mono = getenv("IM_MONO_MIX");
    im_config cfg = {path, p->ch, (int)rate, 1, mono && *mono == '1', NULL};
    if (im_engine_create(&cfg, &p->e, err, sizeof err) != IM_OK)
        fprintf(stderr, "islamic-mute: %s (model %s) -> output muted\n", err, path);
    else
        fprintf(stderr, "islamic-mute: loaded \"%s\" latency %d samples in %.0f ms (sched policy %d)\n",
                im_engine_model_name(p->e), im_engine_latency(p->e), now_ms() - t_start, sched_getscheduler(0));
    return p;
}

static void connect_port(LADSPA_Handle h, unsigned long port, LADSPA_Data *data) {
    inst_t *p = h;
    int ch = p->ch;
    if ((int)port < ch) p->in[port] = data;
    else if ((int)port < 2 * ch) p->out[port - ch] = data;
    else if ((int)port == 2 * ch) p->enabled = data;
    else if ((int)port == 2 * ch + 1) p->latency = data;
}

static void activate(LADSPA_Handle h) { im_engine_reset(((inst_t *)h)->e); }

static double now_ms(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1e3 + t.tv_nsec / 1e6;
}

/* Sound servers run plugins on a real-time thread, and the kernel kills a process whose
 * real-time thread computes for more than RLIMIT_RTTIME (PulseAudio: 200 ms) without
 * blocking. Servers render ahead in long back-to-back calls, so the plugin counts its own
 * compute time across calls and sleeps 0.1 ms whenever it passes ~40 ms, which resets
 * that counter. In steady playback this is one sleep per ~160 ms of audio. */
#define SLICE 2048
#define BUDGET_MS 40.0

static void run(LADSPA_Handle h, unsigned long n) {
    inst_t *p = h;
    if (p->latency) *p->latency = (LADSPA_Data)im_engine_latency(p->e);
    im_engine_set_enabled(p->e, !p->enabled || *p->enabled >= 0.5f);
    double t_begin = now_ms();
    for (unsigned long done = 0; done < n;) {
        int k = (int)(n - done < SLICE ? n - done : SLICE);
        const float *in[2] = {p->in[0] + done, p->ch > 1 ? p->in[1] + done : NULL};
        float *out[2] = {p->out[0] + done, p->ch > 1 ? p->out[1] + done : NULL};
        double t0 = now_ms();
        im_engine_process(p->e, in, out, k);
        p->busy_ms += now_ms() - t0;
        done += (unsigned long)k;
        if (p->busy_ms > BUDGET_MS) {
            struct timespec ts = {0, 100000};
            nanosleep(&ts, NULL);
            p->busy_ms = 0;
        }
    }
    if (debug_on()) {
        double dt = now_ms() - t_begin;
        if (dt > 20) fprintf(stderr, "islamic-mute: run(%lu) took %.1f ms (policy %d)\n", n, dt, sched_getscheduler(0));
    }
}

static void cleanup(LADSPA_Handle h) {
    inst_t *p = h;
    im_engine_destroy(p->e);
    free(p);
}

static const LADSPA_PortDescriptor pd_stereo[MAXP] = {
    LADSPA_PORT_INPUT | LADSPA_PORT_AUDIO, LADSPA_PORT_INPUT | LADSPA_PORT_AUDIO,
    LADSPA_PORT_OUTPUT | LADSPA_PORT_AUDIO, LADSPA_PORT_OUTPUT | LADSPA_PORT_AUDIO,
    LADSPA_PORT_INPUT | LADSPA_PORT_CONTROL, LADSPA_PORT_OUTPUT | LADSPA_PORT_CONTROL};
static const char *const pn_stereo[MAXP] = {"In L", "In R", "Out L", "Out R", "Enabled", "latency"};
static const LADSPA_PortDescriptor pd_mono[4] = {
    LADSPA_PORT_INPUT | LADSPA_PORT_AUDIO, LADSPA_PORT_OUTPUT | LADSPA_PORT_AUDIO,
    LADSPA_PORT_INPUT | LADSPA_PORT_CONTROL, LADSPA_PORT_OUTPUT | LADSPA_PORT_CONTROL};
static const char *const pn_mono[4] = {"In", "Out", "Enabled", "latency"};
static const LADSPA_PortRangeHint ph_stereo[MAXP] = {
    {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0},
    {LADSPA_HINT_TOGGLED | LADSPA_HINT_DEFAULT_1, 0, 1}, {0, 0, 0}};
static const LADSPA_PortRangeHint ph_mono[4] = {
    {0, 0, 0}, {0, 0, 0}, {LADSPA_HINT_TOGGLED | LADSPA_HINT_DEFAULT_1, 0, 1}, {0, 0, 0}};

static const LADSPA_Descriptor desc[2] = {
    {7531001, "islamic_mute_stereo", LADSPA_PROPERTY_REALTIME, "Islamic Mute voice filter (stereo)",
     "islamic-mute project", "GPL-3.0-or-later", 6, pd_stereo, pn_stereo, ph_stereo, (void *)2L, instantiate,
     connect_port, activate, run, NULL, NULL, NULL, cleanup},
    {7531002, "islamic_mute_mono", LADSPA_PROPERTY_REALTIME, "Islamic Mute voice filter (mono)",
     "islamic-mute project", "GPL-3.0-or-later", 4, pd_mono, pn_mono, ph_mono, (void *)1L, instantiate,
     connect_port, activate, run, NULL, NULL, NULL, cleanup},
};

VISIBLE const LADSPA_Descriptor *ladspa_descriptor(unsigned long i) { return i < 2 ? &desc[i] : NULL; }
