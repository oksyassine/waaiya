/* im-blur: Waaiya's screen blur for the Linux desktop. Captures every monitor, finds women / people not
 * confidently men / immodest images (engine/src/im_vision.c), and draws covers over every app (im_cover.c for the
 * tracking). Started and stopped by the desktop app (desktop/lib/linux_blur.dart); same behaviour as Android's
 * ScreenBlur.kt + BlurOverlay.kt.
 *
 *   im-blur [--models DIR] [--policy N] [--strictness N] [--fail-cover 0|1] [--backend auto|x11|wayland]
 *           [--token-file PATH] [--threads N] [--nsfw-score F] [--stats-ms N]
 *
 * stdin, one command per line, applied live: "policy N" (1 women, 2 nudity, 3 both, 0 idle), "strictness N"
 * (0/1/2), "fail_cover 0|1", "quit". End of input (the app closed) also quits.
 * stdout, JSON lines: {"state": starting | on | on_covers_visible | failing | models_missing | no_capture |
 * no_overlay | idle, "error": "...", "backend", "overlay", "covers", and every few seconds "ms" (model time per
 * analysed frame), "cpu" (% of one core, whole process), "fps" (analysed frames per second)}.
 *
 * Fail closed (the user's blur_fail_cover): when the models are missing or failing, or a frame takes too long,
 * the whole screen is covered (clicks still pass through) or a red bar warns at the top. */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <poll.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <time.h>
#include <unistd.h>

#include "blur_host.h"

#define MIN_INTERVAL_MS 50.0   /* at most ~20 analysed frames a second */
#define IDLE_INTERVAL_MS 250.0 /* screen unchanged (or no damage events): look less often */
#define NSFW_EVERY_MS 300.0    /* the nudity model is slower: a few times a second */
#define STALL_MS 1500.0        /* a frame analysed longer than this = "cannot keep up" */
#define SLOW_FRAME_MS 60.0     /* above this (average), the detector tiles take turns */

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1e3 + ts.tv_nsec / 1e6;
}

static volatile sig_atomic_t g_quit;
static void on_signal(int s) { (void)s; g_quit = 1; }

/* ------------------------------------------------------------------------------------------------ state */

typedef struct {
    ib_geom g;
    int fw, fh;
    uint8_t *prev;      /* last frame handed to the models (unchanged frames are skipped) */
    int have_prev;
    /* covers on screen now and before (normalised), for the thumbnail mask */
    im_vrect drawn[2][IB_MAX_RECTS + 1];
    int ndrawn[2];
    /* worker results */
    im_vrect covers[IB_MAX_RECTS];
    ib_cellset *cells;  /* IB_MAX_RECTS */
    int ncovers;
    /* last drawn */
    ib_paint *paints;   /* IB_MAX_RECTS + 8 */
    ib_cellset *pcells; /* copy of the cells drawn */
    int npaints;
    double nsfw_at;
    double job_at;      /* last time this screen was analysed */
    /* worker-owned */
    im_cover *cov;
    ib_thumb thumb;
} screen;

typedef struct {
    /* settings (main writes, worker reads under lock) */
    ib_settings set;
    float nsfw_score; /* <= 0: engine default */
    int threads;
    char person[PATH_MAX], gender[PATH_MAX], nsfw[PATH_MAX];

    pthread_mutex_t mu;
    pthread_cond_t cv;
    pthread_t th;
    int wake[2]; /* worker -> main */

    /* job (main -> worker) */
    int job;          /* screen index, -1 none */
    uint8_t *jframe;  /* copy of the frame */
    int jw, jh;
    double jt;
    int jnsfw;
    im_vrect jmask[2 * (IB_MAX_RECTS + 1)];
    int jnmask;
    ib_geom jg;
    int covers_visible;
    int reset;        /* main: recreate trackers (layout / self-test result) */
    int stop;

    /* job result (worker -> main) */
    int done;         /* screen index of a finished job, -1 none */
    int failed;       /* the models failed on that frame */
    im_vrect rcov[IB_MAX_RECTS];
    ib_cellset *rcells;
    int rn;

    /* worker status */
    double busy_since; /* 0 idle */
    int loading;
    int models_bad;
    char model_err[256];
    double frame_ms;   /* average model time */
    int frames;        /* analysed frames since the last stats line */
    double ms_sum;

    screen s[IB_MAX_SCREENS];
    int n;
} blur;

static blur B;

/* ------------------------------------------------------------------------------------------------ worker */

static void worker_reset_screens(void) {
    for (int i = 0; i < IB_MAX_SCREENS; i++) {
        screen *s = &B.s[i];
        if (s->cov) im_cover_destroy(s->cov);
        s->cov = NULL;
        ib_thumb_free(&s->thumb);
    }
}

static void *worker(void *arg) {
    (void)arg;
    im_vision *v = NULL;
    unsigned vpolicy = 0;
    float vmale = -1;
    int tiles_turns = 0;
    pthread_mutex_lock(&B.mu);
    for (;;) {
        while (!B.stop && B.job < 0 && !B.reset && (B.set.policy == vpolicy || B.set.policy == 0))
            pthread_cond_wait(&B.cv, &B.mu);
        if (B.stop) break;
        if (B.reset) {
            worker_reset_screens();
            B.reset = 0;
        }
        unsigned want = B.set.policy;
        if (want && want != vpolicy) {
            /* (re)load the models for this policy; the main loop keeps running (self-test, drawing) */
            B.loading = 1;
            pthread_mutex_unlock(&B.mu);
            if (v) im_vision_destroy(v);
            char err[256] = "";
            im_vision_config cfg = {B.person, B.gender, B.nsfw, B.threads, want};
            v = im_vision_create(&cfg, err, sizeof err);
            pthread_mutex_lock(&B.mu);
            B.loading = 0;
            vpolicy = want;
            vmale = -1;
            B.models_bad = !v || im_vision_status(v) != 0;
            snprintf(B.model_err, sizeof B.model_err, "%s", !v ? "out of memory" : (B.models_bad ? im_vision_error(v) : ""));
            if (v) {
                im_vision_params p;
                im_vision_get_params(v, &p);
                if (B.nsfw_score > 0) p.nsfw_score = B.nsfw_score;
                if (tiles_turns) p.tiles_per_frame = 1;
                im_vision_set_params(v, &p);
            }
        }
        if (B.job < 0) continue;
        if (B.reset) { /* asked for while the models loaded: before this job, never after it (it would wipe its covers) */
            worker_reset_screens();
            B.reset = 0;
        }
        int i = B.job;
        screen *s = &B.s[i];
        float mc = ib_male_clear(B.set.strictness);
        if (v && mc != vmale) {
            im_vision_params p;
            im_vision_get_params(v, &p);
            p.male_clear = mc;
            im_vision_set_params(v, &p);
            vmale = mc;
        }
        if (!s->cov) {
            s->cov = im_cover_create(B.covers_visible);
            ib_thumb_init(&s->thumb, B.jw, B.jh);
        }
        int run_models = vpolicy != 0 && v;
        B.busy_since = now_ms();
        pthread_mutex_unlock(&B.mu);

        im_vrect det[IB_MAX_RECTS], out[IB_MAX_RECTS];
        int n = -1, failed = 0;
        double t0 = now_ms();
        struct timespec c0, c1;
        clock_gettime(CLOCK_THREAD_CPUTIME_ID, &c0);
        if (run_models) {
            n = im_vision_detect(v, B.jframe, B.jw, B.jh, B.jw * 4, B.jnsfw, det, IB_MAX_RECTS);
            if (n < 0) failed = 1;
        }
        int m = s->cov ? im_cover_update(s->cov, B.jt, B.jframe, B.jw, B.jh, B.jw * 4, det, n, out, IB_MAX_RECTS) : 0;
        double ms = now_ms() - t0;
        clock_gettime(CLOCK_THREAD_CPUTIME_ID, &c1);
        double cpu_ms = (c1.tv_sec - c0.tv_sec) * 1e3 + (c1.tv_nsec - c0.tv_nsec) / 1e6;
        if (getenv("IM_BLUR_DEBUG")) fprintf(stderr, "frame %.1f ms wall, %.1f ms worker cpu, %d dets\n", ms, cpu_ms, n);
        ib_thumb_update(&s->thumb, B.jframe, B.jw, B.jh, B.jw * 4, B.jmask, B.jnmask);
        float cell = IB_CELL_DP * (B.jg.px_per_dp > 0 ? B.jg.px_per_dp : 0.6f);
        for (int k = 0; k < m; k++) {
            ib_cellset *c = &B.rcells[k];
            ib_cell_count((out[k].x1 - out[k].x0) * B.jg.w, (out[k].y1 - out[k].y0) * B.jg.h, cell, &c->nx, &c->ny);
            ib_cells(&s->thumb, &out[k], c->nx, c->ny, c->c);
        }

        pthread_mutex_lock(&B.mu);
        B.frame_ms = B.frame_ms == 0 ? ms : B.frame_ms * 0.9 + ms * 0.1;
        B.ms_sum += ms;
        B.frames++;
        if (!tiles_turns && v && B.frame_ms > SLOW_FRAME_MS) {
            tiles_turns = 1; /* for the rest of this run, as Android */
            im_vision_params p;
            im_vision_get_params(v, &p);
            p.tiles_per_frame = 1;
            im_vision_set_params(v, &p);
        }
        memcpy(B.rcov, out, sizeof *out * (size_t)m);
        B.rn = m;
        B.failed = failed;
        B.done = i;
        B.job = -1;
        B.busy_since = 0;
        char one = 1;
        if (write(B.wake[1], &one, 1) < 0) { /* full pipe: main wakes anyway */ }
    }
    pthread_mutex_unlock(&B.mu);
    if (v) im_vision_destroy(v);
    worker_reset_screens();
    return NULL;
}

/* ------------------------------------------------------------------------------------------------ output */

static ib_state g_state = IB_ST_STARTING;
static char g_error[256];
static const char *g_backend = "", *g_overlay = "";
static int g_covers;

static void emit(int with_stats, double ms, double cpu, double fps) {
    char line[1024];
    int k = ib_state_json(line, sizeof line, g_state, g_error, g_backend, g_overlay, g_covers,
                          with_stats ? ms : -1, with_stats ? cpu : -1, with_stats ? fps : -1);
    if (fwrite(line, 1, (size_t)k, stdout) != (size_t)k || fflush(stdout) != 0) g_quit = 1; /* the app is gone */
}

static void set_state(ib_state st, const char *err) {
    if (st == g_state && !strcmp(err ? err : "", g_error)) return;
    g_state = st;
    snprintf(g_error, sizeof g_error, "%s", err ? err : "");
    emit(0, 0, 0, 0);
}

/* ------------------------------------------------------------------------------------------------ main loop */

static ib_capture *cap;
static ib_overlay *ov;

static void free_screens(void) {
    for (int i = 0; i < IB_MAX_SCREENS; i++) {
        screen *s = &B.s[i];
        free(s->prev); free(s->cells); free(s->paints); free(s->pcells);
        s->prev = NULL; s->cells = NULL; s->paints = NULL; s->pcells = NULL;
    }
}

/* (Re)reads the screens from the capture; the worker must be idle. */
static int g_wayland;

static int setup_screens(void) {
    int n = cap->count(cap);
    if (n > IB_MAX_SCREENS) n = IB_MAX_SCREENS;
    ib_geom g[IB_MAX_SCREENS];
    for (int i = 0; i < n; i++) cap->geometry(cap, i, &g[i]);
    if (g_wayland && n > 0 && ov && ov->root_w > 0) {
        /* XWayland overlay (GNOME): the portal gives logical positions; the X root may be in physical pixels
         * (mutter's xwayland-native-scaling) */
        int x1 = 0, y1 = 0;
        for (int i = 0; i < n; i++) {
            if (g[i].x + g[i].w > x1) x1 = g[i].x + g[i].w;
            if (g[i].y + g[i].h > y1) y1 = g[i].y + g[i].h;
        }
        float sx = x1 > 0 ? (float)ov->root_w / x1 : 1, sy = y1 > 0 ? (float)ov->root_h / y1 : 1;
        if (sx > 1.05f || sx < 0.95f || sy > 1.05f || sy < 0.95f)
            for (int i = 0; i < n; i++)
                g[i] = (ib_geom){(int)(g[i].x * sx), (int)(g[i].y * sy), (int)(g[i].w * sx), (int)(g[i].h * sy),
                                 g[i].px_per_dp * sx};
    }
    free_screens();
    B.n = n;
    for (int i = 0; i < n; i++) {
        screen *s = &B.s[i];
        s->g = g[i];
        s->have_prev = 0;
        s->fw = s->fh = 0;
        s->ndrawn[0] = s->ndrawn[1] = 0;
        s->ncovers = 0;
        s->npaints = 0;
        s->nsfw_at = -1e9;
        s->job_at = 0;
        s->cells = calloc(IB_MAX_RECTS, sizeof *s->cells);
        s->paints = calloc(IB_MAX_RECTS + 8, sizeof *s->paints);
        s->pcells = calloc(IB_MAX_RECTS + 8, sizeof *s->pcells);
        if (!s->cells || !s->paints || !s->pcells) return 0;
    }
    if (ov && !ov->sync(ov, g, n)) return 0;
    return 1;
}

static void wait_worker_idle(void) {
    pthread_mutex_lock(&B.mu);
    while (B.job >= 0 || B.loading) {
        pthread_mutex_unlock(&B.mu);
        usleep(5000);
        pthread_mutex_lock(&B.mu);
    }
    pthread_mutex_unlock(&B.mu);
}

static int g_fail = IB_FAIL_NONE;
static int g_test = 0; /* self-test square shown on screen 0 */

/* Draws screen i if what it shows changed. */
static void redraw(int i, int force) {
    if (!ov) return;
    screen *s = &B.s[i];
    ib_paint p[IB_MAX_RECTS + 8];
    int sq = (int)(IB_TEST_DP * s->g.px_per_dp + 0.5f);
    if (sq < 24) sq = 24;
    int bar = (int)(10 * s->g.px_per_dp + 0.5f); /* the warning bar: a thin red line at the top */
    if (bar < 6) bar = 6;
    int n = ib_layout_paint(s->covers, s->ncovers, s->g.w, s->g.h, g_fail, g_test && i == 0, sq, bar, p,
                            IB_MAX_RECTS + 8);
    int same = !force && n == s->npaints && !memcmp(p, s->paints, sizeof *p * (size_t)n);
    if (same)
        for (int k = 0; k < n && same; k++)
            if (p[k].kind == IB_PK_COVER && p[k].index >= 0)
                same = !memcmp(&s->cells[p[k].index], &s->pcells[k], sizeof *s->pcells);
    if (same) return;
    for (int k = 0; k < n; k++)
        if (p[k].kind == IB_PK_COVER && p[k].index >= 0) s->pcells[k] = s->cells[p[k].index];
    memcpy(s->paints, p, sizeof *p * (size_t)n);
    s->npaints = n;
    ov->draw(ov, i, p, n, s->cells);
    /* what the next captures will show: for the thumbnail mask */
    memcpy(s->drawn[1], s->drawn[0], sizeof s->drawn[0]);
    s->ndrawn[1] = s->ndrawn[0];
    int m = 0;
    if (g_fail == IB_FAIL_COVER) s->drawn[0][m++] = (im_vrect){0, 0, 1, 1, IM_VK_FULL, 1, -1};
    else
        for (int k = 0; k < s->ncovers && m < IB_MAX_RECTS; k++) s->drawn[0][m++] = s->covers[k];
    if (g_test && i == 0 && m <= IB_MAX_RECTS)
        s->drawn[0][m++] = (im_vrect){0, 0.5f, (float)sq / s->g.w, 0.5f + (float)sq / s->g.h, IM_VK_FULL, 1, -1};
    s->ndrawn[0] = m;
}

static void redraw_all(int force) {
    for (int i = 0; i < B.n; i++) redraw(i, force);
}

/* ---- tests: a still picture as the screen (--capture-ppm), to check an overlay without a real capture */

typedef struct {
    ib_capture base;
    int w, h, fw, fh, given;
    uint8_t *rgba;
} ppmcap;

static int ppm_count(ib_capture *b) { (void)b; return 1; }
static void ppm_geometry(ib_capture *b, int i, ib_geom *g) {
    (void)i;
    ppmcap *c = (ppmcap *)b;
    *g = (ib_geom){0, 0, c->w, c->h, 0.6f};
}
static int ppm_grab(ib_capture *b, int i, const uint8_t **rgba, int *fw, int *fh) {
    (void)i;
    ppmcap *c = (ppmcap *)b;
    if (c->given) return 0;
    c->given = 1;
    *rgba = c->rgba; *fw = c->fw; *fh = c->fh;
    return 1;
}
static int ppm_fd(ib_capture *b) { (void)b; return -1; }
static int ppm_dispatch(ib_capture *b) { (void)b; return 0; }
static int ppm_ready(ib_capture *b) { (void)b; return 0; }
static void ppm_destroy(ib_capture *b) { free(((ppmcap *)b)->rgba); free(b); }

static ib_capture *ppm_capture_new(const char *path, char *err, size_t errlen) {
    FILE *f = fopen(path, "rb");
    int w = 0, h = 0, mx = 0;
    if (!f || fscanf(f, "P6 %d %d %d", &w, &h, &mx) != 3 || w < 2 || h < 2 || mx != 255 || fgetc(f) == EOF) {
        snprintf(err, errlen, "cannot read %s (binary PPM, 8 bit)", path);
        if (f) fclose(f);
        return NULL;
    }
    size_t n = (size_t)w * h;
    uint32_t *src = malloc(n * 4);
    uint8_t *rgb = malloc(n * 3);
    ppmcap *c = calloc(1, sizeof *c);
    if (!src || !rgb || !c || fread(rgb, 3, n, f) != n) {
        snprintf(err, errlen, "cannot read %s", path);
        fclose(f); free(src); free(rgb); free(c);
        return NULL;
    }
    fclose(f);
    for (size_t k = 0; k < n; k++) src[k] = (uint32_t)rgb[k * 3] << 16 | (uint32_t)rgb[k * 3 + 1] << 8 | rgb[k * 3 + 2];
    free(rgb);
    c->w = w; c->h = h;
    ib_scale_size(w, h, IB_LONG_SIDE, &c->fw, &c->fh);
    c->rgba = malloc((size_t)c->fw * c->fh * 4);
    if (c->rgba) ib_downscale((const uint8_t *)src, w, h, w * 4, (ib_layout){16, 8, 0}, c->rgba, c->fw, c->fh, c->fw * 4);
    free(src);
    c->base = (ib_capture){.name = "ppm", .count = ppm_count, .geometry = ppm_geometry, .grab = ppm_grab, .fd = ppm_fd,
                           .dispatch = ppm_dispatch, .ready = ppm_ready, .destroy = ppm_destroy, .no_selftest = 1};
    return &c->base;
}

static void usage(void) {
    fprintf(stderr, "usage: im-blur [--models DIR] [--policy N] [--strictness N] [--fail-cover 0|1]\n"
                    "               [--backend auto|x11|wayland] [--token-file PATH] [--threads N] [--nsfw-score F]\n"
                    "               [--stats-ms N] [--dump-frame PATH]\n");
}

static void default_models_dir(char *out, size_t cap) {
    char exe[PATH_MAX];
    ssize_t k = readlink("/proc/self/exe", exe, sizeof exe - 1);
    if (k <= 0) { snprintf(out, cap, "models/vision"); return; }
    exe[k] = 0;
    char *slash = strrchr(exe, '/');
    if (slash) *slash = 0;
    /* <bundle>/engine/build/im-blur -> <bundle>/engine/models/vision; repo build/ -> models/vision */
    if (strlen(exe) + 20 < cap) {
        strcpy(out, exe);
        strcat(out, "/../models/vision");
    } else {
        snprintf(out, cap, "models/vision");
    }
}

int main(int argc, char **argv) {
    char models[PATH_MAX] = "";
    const char *backend = "auto", *token = NULL, *dump = NULL, *ppm = NULL;
    double stats_ms = 5000;
    double duty = 0.5;
    B.set = (ib_settings){IM_VISION_WOMEN | IM_VISION_NSFW, 0, 1};
    B.threads = 1; /* 2 threads: ~110% of a core on a changing screen (ORT spins), 1: ~48% (linux/blur/test_x11.py) */
    for (int i = 1; i < argc; i++) {
        const char *a = argv[i], *v = i + 1 < argc ? argv[i + 1] : NULL;
        if (!v) { usage(); return 2; }
        i++;
        if (!strcmp(a, "--models")) snprintf(models, sizeof models, "%s", v);
        else if (!strcmp(a, "--policy")) B.set.policy = (unsigned)atoi(v) & 3u;
        else if (!strcmp(a, "--strictness")) B.set.strictness = atoi(v) < 0 ? 0 : (atoi(v) > 2 ? 2 : atoi(v));
        else if (!strcmp(a, "--fail-cover")) B.set.fail_cover = atoi(v) != 0;
        else if (!strcmp(a, "--backend")) backend = v;
        else if (!strcmp(a, "--token-file")) token = v;
        else if (!strcmp(a, "--threads")) B.threads = atoi(v) > 0 ? atoi(v) : 1;
        else if (!strcmp(a, "--nsfw-score")) B.nsfw_score = (float)atof(v);
        else if (!strcmp(a, "--stats-ms")) stats_ms = atof(v) > 100 ? atof(v) : 100;
        else if (!strcmp(a, "--duty")) duty = atof(v) >= 0.05 && atof(v) <= 1 ? atof(v) : 0.5;
        else if (!strcmp(a, "--capture-ppm")) ppm = v; /* tests: a still picture (P6) as the only screen */
        else if (!strcmp(a, "--dump-frame")) dump = v; /* tests: the first analysed frame of screen 1, as PPM */
        else { usage(); return 2; }
    }
    if (!models[0]) default_models_dir(models, sizeof models);
    snprintf(B.person, sizeof B.person, "%s/person_yolox_nano.onnx", models);
    snprintf(B.gender, sizeof B.gender, "%s/gender_v2.onnx", models);
    snprintf(B.nsfw, sizeof B.nsfw, "%s/nsfw_marqo_int8.onnx", models);

    signal(SIGPIPE, SIG_IGN);
    struct sigaction sa;
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = on_signal;
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGHUP, &sa, NULL);
    fcntl(0, F_SETFL, fcntl(0, F_GETFL) | O_NONBLOCK);

    emit(0, 0, 0, 0); /* starting */

    /* backends: Wayland session -> portal capture (never the X11 grab: under XWayland it shows only X clients) */
    char err[256] = "", oerr[256] = "";
    const char *wl = getenv("WAYLAND_DISPLAY"), *x = getenv("DISPLAY");
    int wayland = !strcmp(backend, "wayland") || (!strcmp(backend, "auto") && wl && *wl);
    g_wayland = wayland;
    if (wayland) {
        g_backend = "wayland";
        /* the overlay first: without one, no share dialog is shown for nothing */
        ov = ib_layer_overlay_new(oerr, sizeof oerr);
        if (!ov && x && *x) {
            /* GNOME: an override-redirect window through XWayland (mutter keeps those in its top layer) */
            char e2[256] = "";
            ov = ib_x11_overlay_new(NULL, e2, sizeof e2);
            if (!ov) snprintf(oerr + strlen(oerr), sizeof oerr - strlen(oerr), "; XWayland: %s", e2);
        } else if (!ov) {
            snprintf(oerr + strlen(oerr), sizeof oerr - strlen(oerr), "; no XWayland (DISPLAY unset)");
        }
        if (ov) cap = ppm ? ppm_capture_new(ppm, err, sizeof err) : ib_portal_capture_new(token, err, sizeof err);
    } else if (x && *x) {
        g_backend = "x11";
        cap = ib_x11_capture_new(NULL, err, sizeof err);
        if (cap) ov = ib_x11_overlay_new(NULL, oerr, sizeof oerr);
    } else {
        snprintf(err, sizeof err, "no graphical session (neither WAYLAND_DISPLAY nor DISPLAY is set)");
    }
    g_overlay = ov ? ov->name : "";

    if (wayland && !ov) set_state(IB_ST_NO_OVERLAY, oerr);
    else if (!cap) set_state(IB_ST_NO_CAPTURE, err);
    else if (!ov) set_state(IB_ST_NO_OVERLAY, oerr);

    pthread_mutex_init(&B.mu, NULL);
    pthread_cond_init(&B.cv, NULL);
    B.job = -1;
    B.done = -1;
    B.rcells = calloc(IB_MAX_RECTS, sizeof *B.rcells);
    B.jframe = malloc((size_t)IB_LONG_SIDE * IB_LONG_SIDE * 4);
    if (pipe2(B.wake, O_NONBLOCK | O_CLOEXEC) != 0 || !B.rcells || !B.jframe) return 1;
    int running = cap && ov;
    if (running) pthread_create(&B.th, NULL, worker, NULL);

    /* capture ready (the Wayland share dialog may still be open) -> screens -> self-test -> analysing */
    enum { PH_WAIT_CAPTURE, PH_SELFTEST, PH_RUN, PH_DEAD } phase = running ? PH_WAIT_CAPTURE : PH_DEAD;
    double test_until = 0, next_grab = 0, next_watch = 0, stats_at = now_ms() + stats_ms;
    int covers_visible = 1, rr = 0, idle_grabs = 0, cap_fail = 0, fail_streak = 0;
    double job_t0 = 0;
    int job_screen = -1;
    struct rusage ru0;
    getrusage(RUSAGE_SELF, &ru0);
    double wall0 = now_ms();
    char inbuf[512];
    size_t inlen = 0;
    unsigned last_policy = B.set.policy;

    while (!g_quit) {
        double t = now_ms();
        /* ---- wait */
        struct pollfd pf[4];
        int np = 0;
        pf[np++] = (struct pollfd){0, POLLIN, 0};
        pf[np++] = (struct pollfd){B.wake[0], POLLIN, 0};
        int cfd = running && cap ? cap->fd(cap) : -1, ofd = running && ov ? ov->fd(ov) : -1;
        if (cfd >= 0) pf[np++] = (struct pollfd){cfd, POLLIN, 0};
        if (ofd >= 0 && ofd != cfd) pf[np++] = (struct pollfd){ofd, POLLIN, 0};
        double until = next_watch;
        /* the next grab only matters when no frame is being analysed (a finished job wakes us through the pipe) */
        int grab_due = phase == PH_SELFTEST || (phase == PH_RUN && job_screen < 0 && B.set.policy);
        if (grab_due) until = until < next_grab ? until : next_grab;
        int timeout = (int)(until - t);
        if (timeout < 0) timeout = 0;
        if (timeout > 500) timeout = 500;
        if (poll(pf, (nfds_t)np, timeout) < 0 && errno != EINTR) break;
        t = now_ms();

        /* ---- stdin commands */
        if (pf[0].revents) {
            for (;;) {
                ssize_t k = read(0, inbuf + inlen, sizeof inbuf - 1 - inlen);
                if (k == 0) { g_quit = 1; break; } /* the app is gone */
                if (k < 0) break;
                inlen += (size_t)k;
                inbuf[inlen] = 0;
                char *nl;
                while ((nl = strchr(inbuf, '\n'))) {
                    *nl = 0;
                    ib_settings ns;
                    pthread_mutex_lock(&B.mu);
                    ns = B.set;
                    pthread_mutex_unlock(&B.mu);
                    int r = ib_command(inbuf, &ns);
                    if (r == 2) g_quit = 1;
                    else if (r == 1) {
                        pthread_mutex_lock(&B.mu);
                        B.set = ns;
                        pthread_cond_signal(&B.cv);
                        pthread_mutex_unlock(&B.mu);
                    }
                    memmove(inbuf, nl + 1, inlen - (size_t)(nl + 1 - inbuf) + 1);
                    inlen -= (size_t)(nl + 1 - inbuf);
                }
                if (inlen >= sizeof inbuf - 1) inlen = 0; /* an overlong line: dropped */
            }
            if (g_quit) break;
        }
        if (phase == PH_DEAD) {
            next_watch = t + 500;
            continue;
        }

        /* ---- backend events */
        if (cap->dispatch(cap) && phase != PH_WAIT_CAPTURE) {
            wait_worker_idle();
            pthread_mutex_lock(&B.mu);
            B.reset = 1;
            pthread_cond_signal(&B.cv);
            pthread_mutex_unlock(&B.mu);
            if (!setup_screens()) {
                set_state(IB_ST_NO_OVERLAY, ov->err);
                phase = PH_DEAD;
                continue;
            }
            redraw_all(1);
        }
        ov->dispatch(ov);

        /* ---- phases */
        if (phase == PH_WAIT_CAPTURE) {
            int r = cap->ready(cap);
            if (r == 1) set_state(IB_ST_STARTING, cap->waiting_user ? "share_dialog" : "");
            if (r < 0) { set_state(IB_ST_NO_CAPTURE, cap->err); phase = PH_DEAD; continue; }
            if (r == 0) {
                if (!setup_screens()) { set_state(IB_ST_NO_OVERLAY, ov->err); phase = PH_DEAD; continue; }
                if (cap->no_selftest) { /* tests: covers never in the capture */
                    covers_visible = 0;
                    pthread_mutex_lock(&B.mu);
                    B.covers_visible = 0;
                    B.reset = 1;
                    pthread_cond_signal(&B.cv);
                    pthread_mutex_unlock(&B.mu);
                    phase = PH_RUN;
                    next_grab = t;
                } else {
                    g_test = 1;
                    redraw_all(1);
                    test_until = t + (wayland ? 4000 : 1500);
                    next_grab = t + 50;
                    phase = PH_SELFTEST;
                }
            }
        }
        if (phase == PH_SELFTEST && t >= next_grab && B.n > 0) {
            const uint8_t *f;
            int fw, fh;
            int r = cap->grab(cap, 0, &f, &fw, &fh);
            int seen = 0;
            if (r > 0) {
                int sq = B.s[0].npaints ? B.s[0].paints[B.s[0].npaints - 1].r.w : 24;
                seen = ib_has_magenta(f, fw, fh, fw * 4, sq / 2.0f / B.s[0].g.w, 0.5f + sq / 2.0f / B.s[0].g.h);
            }
            next_grab = t + 50;
            if (seen || t >= test_until) {
                g_test = 0;
                redraw_all(1);
                if (r < 0) {
                    set_state(IB_ST_NO_CAPTURE, cap->err);
                    phase = PH_DEAD;
                    continue;
                }
                if (!seen) {
                    /* The capture shows what is on screen (X11 root, and the monitor casts of mutter, KWin and
                     * xdg-desktop-portal-wlr), so our square not being there means it is not on screen: covers
                     * would not be seen either. Said, rather than pretending to blur. */
                    set_state(IB_ST_NO_OVERLAY, g_wayland ? "self-test: the blur's covers did not show up in the "
                                                            "shared screen (not drawn above the windows?)"
                                                          : "self-test: the blur's window did not show up on screen "
                                                            "(another window or the desktop stays above it?)");
                    phase = PH_DEAD;
                    continue;
                }
                covers_visible = 1;
                pthread_mutex_lock(&B.mu);
                B.covers_visible = covers_visible;
                B.reset = 1;
                pthread_cond_signal(&B.cv);
                pthread_mutex_unlock(&B.mu);
                phase = PH_RUN;
                next_grab = t;
            }
        }

        /* ---- a finished job */
        pthread_mutex_lock(&B.mu);
        char drain[64];
        while (read(B.wake[0], drain, sizeof drain) > 0) {}
        if (B.done >= 0) {
            int i = B.done;
            if (i < B.n) {
                memcpy(B.s[i].covers, B.rcov, sizeof *B.rcov * (size_t)B.rn);
                memcpy(B.s[i].cells, B.rcells, sizeof *B.rcells * (size_t)B.rn);
                B.s[i].ncovers = B.rn;
            }
            fail_streak = B.failed ? fail_streak + 1 : 0;
            B.done = -1;
            double ms = t - job_t0;
            /* pacing: at most ~20 frames a second, and the models busy at most `duty` of the time */
            double gap = MIN_INTERVAL_MS - ms, rest = ms * (1 / duty - 1);
            if (gap < rest) gap = rest;
            next_grab = t + gap;
            job_screen = -1;
            pthread_mutex_unlock(&B.mu);
            if (i < B.n) redraw(i, 0);
        } else {
            pthread_mutex_unlock(&B.mu);
        }

        /* ---- policy 0: nothing to cover */
        if (B.set.policy != last_policy) {
            last_policy = B.set.policy;
            if (!last_policy)
                for (int i = 0; i < B.n; i++) B.s[i].ncovers = 0;
            redraw_all(0);
        }

        /* ---- next frame */
        if (phase == PH_RUN && job_screen < 0 && t >= next_grab && B.set.policy) {
            int submitted = 0;
            for (int k = 0; k < B.n && !submitted; k++) {
                int i = (rr + k) % B.n;
                screen *s = &B.s[i];
                const uint8_t *f;
                int fw, fh;
                int r = cap->grab(cap, i, &f, &fw, &fh);
                if (r < 0) { cap_fail++; continue; }
                cap_fail = 0;
                /* A nudity cover is held for a while (im_cover full_hold_ms): the tracker must see time pass, even
                 * on a still screen, to let it go. Twice a second while one is shown. */
                int full = 0;
                for (int k2 = 0; k2 < s->ncovers && !full; k2++) full = s->covers[k2].kind == IM_VK_FULL;
                int refresh = full && s->have_prev && t - s->job_at > 500;
                if (r == 0 && refresh) { f = s->prev; fw = s->fw; fh = s->fh; r = 1; }
                if (r == 0) continue;
                size_t sz = (size_t)fw * fh * 4;
                if (!refresh && s->have_prev && fw == s->fw && fh == s->fh && !memcmp(f, s->prev, sz))
                    continue; /* unchanged */
                if (!s->prev || fw != s->fw || fh != s->fh) {
                    free(s->prev);
                    s->prev = malloc(sz);
                    if (!s->prev) continue;
                    s->fw = fw; s->fh = fh;
                }
                if (f != s->prev) memcpy(s->prev, f, sz);
                s->have_prev = 1;
                s->job_at = t;
                if (dump && i == 0) {
                    FILE *df = fopen(dump, "wb");
                    if (df) {
                        fprintf(df, "P6\n%d %d\n255\n", fw, fh);
                        for (size_t q = 0; q < sz; q += 4) fwrite(f + q, 1, 3, df);
                        fclose(df);
                    }
                    dump = NULL;
                }
                pthread_mutex_lock(&B.mu);
                memcpy(B.jframe, f, sz);
                B.jw = fw; B.jh = fh;
                B.jt = t;
                B.jnsfw = t - s->nsfw_at >= NSFW_EVERY_MS;
                if (B.jnsfw) s->nsfw_at = t;
                B.jnmask = 0;
                for (int d = 0; d < 2; d++)
                    for (int k2 = 0; k2 < s->ndrawn[d]; k2++) B.jmask[B.jnmask++] = s->drawn[d][k2];
                B.jg = s->g;
                B.job = i;
                pthread_cond_signal(&B.cv);
                pthread_mutex_unlock(&B.mu);
                job_t0 = t;
                job_screen = i;
                submitted = 1;
                rr = i + 1;
            }
            if (!submitted) {
                idle_grabs++;
                next_grab = t + (idle_grabs > 20 ? IDLE_INTERVAL_MS : MIN_INTERVAL_MS);
            } else {
                idle_grabs = 0;
            }
        }

        /* ---- watchdog: fail mode and state, twice a second */
        if (t >= next_watch) {
            next_watch = t + 500;
            if (phase == PH_RUN || phase == PH_SELFTEST) {
                pthread_mutex_lock(&B.mu);
                int bad = B.models_bad, loading = B.loading;
                double busy = B.busy_since;
                char merr[256];
                snprintf(merr, sizeof merr, "%s", B.model_err);
                pthread_mutex_unlock(&B.mu);
                int stalled = busy > 0 && t - busy > STALL_MS;
                int failing = B.set.policy && (bad || fail_streak >= 3 || stalled || cap_fail >= 3);
                int fm = failing ? (B.set.fail_cover ? IB_FAIL_COVER : IB_FAIL_WARN) : IB_FAIL_NONE;
                if (fm != g_fail) {
                    g_fail = fm;
                    redraw_all(0);
                }
                ov->keep_on_top(ov);
                int nc = 0;
                for (int i = 0; i < B.n; i++) nc += B.s[i].ncovers;
                g_covers = nc;
                char why[300] = "";
                if (stalled) snprintf(why, sizeof why, "a frame has taken %.0f ms", t - busy);
                else if (fail_streak >= 3) snprintf(why, sizeof why, "the models failed on %d frames", fail_streak);
                else if (cap_fail >= 3) snprintf(why, sizeof why, "screen capture failing: %s", cap->err);
                if (!B.set.policy) set_state(IB_ST_IDLE, "");
                else if (bad) set_state(IB_ST_MODELS_MISSING, merr);
                else if (failing) set_state(IB_ST_FAILING, why);
                else if (phase == PH_SELFTEST || loading) set_state(IB_ST_STARTING, "");
                else set_state(covers_visible ? IB_ST_ON_COVERS_VISIBLE : IB_ST_ON, "");
            }
            if (t >= stats_at) {
                struct rusage ru;
                getrusage(RUSAGE_SELF, &ru);
                double cpu_ms = (ru.ru_utime.tv_sec - ru0.ru_utime.tv_sec + ru.ru_stime.tv_sec - ru0.ru_stime.tv_sec) * 1e3 +
                                (ru.ru_utime.tv_usec - ru0.ru_utime.tv_usec + ru.ru_stime.tv_usec - ru0.ru_stime.tv_usec) / 1e3;
                double wall = t - wall0;
                pthread_mutex_lock(&B.mu);
                double ms = B.frames ? B.ms_sum / B.frames : 0, fps = B.frames * 1000.0 / (wall > 1 ? wall : 1);
                B.frames = 0;
                B.ms_sum = 0;
                pthread_mutex_unlock(&B.mu);
                emit(1, ms, wall > 1 ? 100.0 * cpu_ms / wall : 0, fps);
                ru0 = ru;
                wall0 = t;
                stats_at = t + stats_ms;
            }
        }
    }

    if (running) {
        pthread_mutex_lock(&B.mu);
        B.stop = 1;
        pthread_cond_signal(&B.cv);
        pthread_mutex_unlock(&B.mu);
        pthread_join(B.th, NULL);
    }
    if (ov) ov->destroy(ov);
    if (cap) cap->destroy(cap);
    free_screens();
    return 0;
}
