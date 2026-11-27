/* Live caption lines from a stream of voice (im_captions.h). */
#include "im_captions.h"
#include "im_ctc.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define RATE 16000
#define FRAME 320          /* 20 ms at 16 kHz: the level gate's step */
#define PREROLL 15         /* frames kept before speech starts (0.3 s), so a line does not lose its first sound */
#define TAIL 10            /* frames of the pause kept at a line's end (0.2 s) */
#define TEXT_CAP 4096      /* bytes of one line's text */

struct im_captions {
    im_captions_config c;
    im_recognize_fn fn;
    void *user;
    im_asr *asr;            /* owned, when made by im_captions_create_asr */

    /* decimation to 16 kHz: a windowed-sinc low-pass, then every factor-th sample */
    int factor, taps, hpos, phase;
    float *fir, *hist;      /* hist: [2 * taps], each sample written twice so a window is contiguous */

    float frame[FRAME];
    int frame_len;
    float level_db, floor_db;

    float pre[PREROLL * FRAME];
    int pre_frames, pre_head; /* ring of the last frames heard outside a line */

    int open;               /* a line is open */
    float *line;            /* the open line's samples */
    long line_len, line_cap;/* in samples (a multiple of FRAME) */
    float *fdb;             /* per frame of the line: level */
    unsigned char *fspeech; /* per frame of the line: speech */
    long frames_cap;
    long silence;           /* samples of pause at the line's end */
    long speech;            /* samples of speech in the line */
    long since_partial;     /* samples added since the line was last recognised */
    double partial_every;   /* seconds; grows when recognition is slow */

    char partial[TEXT_CAP];
    char text[TEXT_CAP];
    char **finals;
    int n_finals, cap_finals;
    int failed;             /* the recogniser failed during this call */
    double last_ms, last_audio_s;
};

void im_captions_default_config(im_captions_config *c) {
    c->in_rate = 48000;
    c->partial_every_s = 0.8f;
    c->end_silence_s = 0.7f;
    c->max_line_s = 12.0f;
    c->min_speech_s = 0.3f;
    c->gate_db = -50.0f;
    c->gate_above_floor_db = 9.0f;
}

static double now_ms(void) {
    struct timespec t;
#if defined(CLOCK_MONOTONIC)
    clock_gettime(CLOCK_MONOTONIC, &t);
#else
    timespec_get(&t, TIME_UTC);
#endif
    return (double)t.tv_sec * 1e3 + (double)t.tv_nsec / 1e6;
}

static double bessel_i0(double x) {
    double s = 1.0, t = 1.0;
    for (int k = 1; k < 40; k++) {
        t *= (x / (2.0 * k)) * (x / (2.0 * k));
        s += t;
    }
    return s;
}

static int asr_fn(void *user, const float *x, int n, char *out, size_t cap) {
    return im_asr_transcribe((im_asr *)user, x, n, out, cap);
}

im_captions *im_captions_create(const im_captions_config *c, im_recognize_fn fn, void *user) {
    if (!c || !fn || c->in_rate < RATE || c->in_rate % RATE || c->in_rate / RATE > 12 || c->partial_every_s <= 0 ||
        c->end_silence_s <= 0 || c->max_line_s < 2.0f || c->min_speech_s < 0)
        return NULL;
    im_captions *k = calloc(1, sizeof(*k));
    if (!k) return NULL;
    k->c = *c;
    k->fn = fn;
    k->user = user;
    k->factor = c->in_rate / RATE;
    k->floor_db = -90.0f;
    k->level_db = -120.0f;
    k->partial_every = c->partial_every_s;
    if (k->factor > 1) {
        /* pass band to 7.2 kHz, Kaiser window (beta 8): -80 dB stop band above 8 kHz */
        k->taps = 24 * k->factor + 1;
        k->fir = malloc(sizeof(float) * (size_t)k->taps);
        k->hist = calloc((size_t)k->taps * 2, sizeof(float));
        if (!k->fir || !k->hist) { im_captions_destroy(k); return NULL; }
        double fc = 0.9 / k->factor;   /* cutoff, as a fraction of the input Nyquist */
        int m = k->taps / 2;
        double i0b = bessel_i0(8.0), sum = 0;
        for (int j = 0; j < k->taps; j++) {
            double x = j - m, u = x / m;
            double w = bessel_i0(8.0 * sqrt(fmax(0.0, 1.0 - u * u))) / i0b;
            double s = x == 0 ? fc : sin(M_PI * fc * x) / (M_PI * x);
            k->fir[j] = (float)(s * w);
            sum += s * w;
        }
        for (int j = 0; j < k->taps; j++) k->fir[j] = (float)(k->fir[j] / sum);   /* unity gain at 0 Hz */
    }
    return k;
}

im_captions *im_captions_create_asr(const im_captions_config *c, const char *path, int threads, char *err,
                                    size_t errlen) {
    im_asr *a = im_asr_create(path, threads, err, errlen);
    if (!a) return NULL;
    im_captions *k = im_captions_create(c, asr_fn, a);
    if (!k) {
        if (err) snprintf(err, errlen, "captions: bad configuration");
        im_asr_destroy(a);
        return NULL;
    }
    k->asr = a;
    return k;
}

static void drop_finals(im_captions *k) {
    for (int i = 0; i < k->n_finals; i++) free(k->finals[i]);
    k->n_finals = 0;
}

void im_captions_destroy(im_captions *k) {
    if (!k) return;
    drop_finals(k);
    free(k->finals);
    free(k->fir);
    free(k->hist);
    free(k->line);
    free(k->fdb);
    free(k->fspeech);
    im_asr_destroy(k->asr);
    free(k);
}

void im_captions_reset(im_captions *k) {
    if (!k) return;
    k->open = 0;
    k->line_len = k->silence = k->speech = k->since_partial = 0;
    k->pre_frames = k->pre_head = 0;
    k->partial[0] = 0;
    drop_finals(k);
}

static int recognise(im_captions *k, long n, char *out) {
    double t0 = now_ms();
    int r = k->fn(k->user, k->line, (int)n, out, TEXT_CAP);
    k->last_ms = now_ms() - t0;
    k->last_audio_s = (double)n / RATE;
    if (r < 0) { k->failed = 1; out[0] = 0; return -1; }
    out[im_utf8_fit(out, (size_t)r < TEXT_CAP ? (size_t)r : TEXT_CAP - 1)] = 0;
    return r;
}

static int push_final(im_captions *k, const char *s) {
    if (k->n_finals == k->cap_finals) {
        int cap = k->cap_finals ? k->cap_finals * 2 : 8;
        char **f = realloc(k->finals, sizeof(char *) * (size_t)cap);
        if (!f) return 0;
        k->finals = f, k->cap_finals = cap;
    }
    char *d = malloc(strlen(s) + 1);
    if (!d) return 0;
    strcpy(d, s);
    k->finals[k->n_finals++] = d;
    return 1;
}

/* The first n samples of the line become a final line (if they hold enough speech); they leave the line. */
static int finish(im_captions *k, long n) {
    int flags = 0;
    long nf = n / FRAME;
    long speech = 0;
    for (long f = 0; f < nf; f++) speech += k->fspeech[f] ? FRAME : 0;
    if (speech >= (long)(k->c.min_speech_s * RATE) && recognise(k, n, k->text) > 0 && push_final(k, k->text))
        flags |= IM_CAPTIONS_FINAL;
    if (k->partial[0]) { k->partial[0] = 0; flags |= IM_CAPTIONS_PARTIAL; }
    /* keep the rest */
    long rest = k->line_len - nf * FRAME;
    memmove(k->line, k->line + nf * FRAME, sizeof(float) * (size_t)rest);
    memmove(k->fdb, k->fdb + nf, sizeof(float) * (size_t)(k->line_len / FRAME - nf));
    memmove(k->fspeech, k->fspeech + nf, (size_t)(k->line_len / FRAME - nf));
    k->line_len = rest;
    k->speech = 0;
    for (long f = 0; f < rest / FRAME; f++) k->speech += k->fspeech[f] ? FRAME : 0;
    k->since_partial = rest;
    return flags;
}

static int append(im_captions *k, const float *x, float db, int speech) {
    long nf = k->line_len / FRAME;
    if (k->line_len + FRAME > k->line_cap) {
        long cap = k->line_cap ? k->line_cap * 2 : RATE * 16;
        float *l = realloc(k->line, sizeof(float) * (size_t)cap);
        if (!l) return 0;
        k->line = l, k->line_cap = cap;
    }
    if (nf + 1 > k->frames_cap) {
        long cap = k->frames_cap ? k->frames_cap * 2 : 1024;
        float *d = realloc(k->fdb, sizeof(float) * (size_t)cap);
        if (!d) return 0;
        k->fdb = d;
        unsigned char *s = realloc(k->fspeech, (size_t)cap);
        if (!s) return 0;
        k->fspeech = s, k->frames_cap = cap;
    }
    memcpy(k->line + k->line_len, x, sizeof(float) * FRAME);
    k->line_len += FRAME;
    k->fdb[nf] = db;
    k->fspeech[nf] = (unsigned char)speech;
    k->speech += speech ? FRAME : 0;
    k->since_partial += FRAME;
    return 1;
}

static int frame_done(im_captions *k) {
    double e = 0;
    for (int i = 0; i < FRAME; i++) e += (double)k->frame[i] * k->frame[i];
    float db = (float)(10.0 * log10(e / FRAME + 1e-12));
    k->level_db = db;
    /* background level: follows quiet moments quickly, rises 1 dB per second */
    if (db < k->floor_db) k->floor_db = 0.7f * k->floor_db + 0.3f * db;
    else k->floor_db += 0.02f;
    if (k->floor_db > -30.0f) k->floor_db = -30.0f;
    int speech = db > k->c.gate_db && db > k->floor_db + k->c.gate_above_floor_db;
    int flags = 0;

    if (!k->open) {
        if (!speech) {
            memcpy(k->pre + (size_t)k->pre_head * FRAME, k->frame, sizeof k->frame);
            k->pre_head = (k->pre_head + 1) % PREROLL;
            if (k->pre_frames < PREROLL) k->pre_frames++;
            return 0;
        }
        k->open = 1;
        k->line_len = k->speech = k->silence = k->since_partial = 0;
        for (int i = 0; i < k->pre_frames; i++) {
            int f = (k->pre_head - k->pre_frames + i + PREROLL) % PREROLL;
            const float *p = k->pre + (size_t)f * FRAME;
            double pe = 0;
            for (int j = 0; j < FRAME; j++) pe += (double)p[j] * p[j];
            if (!append(k, p, (float)(10.0 * log10(pe / FRAME + 1e-12)), 0)) return -1;
        }
        k->pre_frames = k->pre_head = 0;
    }
    if (!append(k, k->frame, db, speech)) return -1;
    k->silence = speech ? 0 : k->silence + FRAME;

    if (k->silence >= (long)(k->c.end_silence_s * RATE)) {
        /* the pause ends the line: keep a little of it, drop the rest */
        long keep = k->line_len - k->silence + TAIL * FRAME;
        if (keep > k->line_len) keep = k->line_len;
        k->line_len = keep;
        flags |= finish(k, keep);
        k->open = 0;
        k->line_len = 0;
        k->partial_every = k->c.partial_every_s;
        return flags;
    }
    if (k->line_len >= (long)(k->c.max_line_s * RATE)) {
        /* too long: cut at the quietest frame of the last 3 s, at least 1 s into the line */
        long nf = k->line_len / FRAME, lo = nf - 3 * RATE / FRAME, hi = nf - TAIL;
        if (lo < RATE / FRAME) lo = RATE / FRAME;
        long cut = hi;
        for (long f = lo; f < hi; f++)
            if (k->fdb[f] < k->fdb[cut]) cut = f;
        flags |= finish(k, cut * FRAME);
        return flags;
    }
    if (k->since_partial >= (long)(k->partial_every * RATE) && k->speech >= (long)(k->c.min_speech_s * RATE)) {
        k->since_partial = 0;
        if (recognise(k, k->line_len, k->text) >= 0 && strcmp(k->text, k->partial) != 0) {
            memcpy(k->partial, k->text, strlen(k->text) + 1);
            flags |= IM_CAPTIONS_PARTIAL;
        }
        /* a slow phone: recognise less often, so that the audio keeps up (each run covers the whole line) */
        double need = 1.5 * k->last_ms / 1000.0;
        k->partial_every = need > k->c.partial_every_s ? need : k->c.partial_every_s;
    }
    return flags;
}

static int add_sample(im_captions *k, float y) {
    k->frame[k->frame_len++] = y;
    if (k->frame_len < FRAME) return 0;
    k->frame_len = 0;
    return frame_done(k);
}

int im_captions_push(im_captions *k, const float *x, int n) {
    if (!k || n < 0) return -1;
    int flags = 0;
    k->failed = 0;
    for (int i = 0; i < n; i++) {
        int r;
        if (k->factor == 1) {
            r = add_sample(k, x[i]);
        } else {
            k->hist[k->hpos] = k->hist[k->hpos + k->taps] = x[i];
            k->hpos = (k->hpos + 1) % k->taps;
            if (++k->phase < k->factor) continue;
            k->phase = 0;
            const float *w = k->hist + k->hpos;   /* the last taps samples, oldest first */
            float y = 0;
            for (int j = 0; j < k->taps; j++) y += w[j] * k->fir[j];
            r = add_sample(k, y);
        }
        if (r < 0) return -1;
        flags |= r;
    }
    return k->failed ? -1 : flags;
}

int im_captions_flush(im_captions *k) {
    if (!k) return -1;
    k->failed = 0;
    int flags = 0;
    if (k->open) {
        long keep = k->line_len - k->silence + TAIL * FRAME;
        if (keep > k->line_len) keep = k->line_len;
        k->line_len = keep;
        flags = finish(k, keep);
        k->open = 0;
        k->line_len = 0;
    } else if (k->partial[0]) {
        k->partial[0] = 0;
        flags = IM_CAPTIONS_PARTIAL;
    }
    return k->failed ? -1 : flags;
}

const char *im_captions_partial(const im_captions *k) { return k ? k->partial : ""; }

int im_captions_take_final(im_captions *k, char *out, size_t cap) {
    if (!k || !out || cap == 0 || k->n_finals == 0) { if (out && cap) out[0] = 0; return 0; }
    char *s = k->finals[0];
    size_t n = im_utf8_fit(s, cap - 1);
    memcpy(out, s, n);
    out[n] = 0;
    free(s);
    memmove(k->finals, k->finals + 1, sizeof(char *) * (size_t)(k->n_finals - 1));
    k->n_finals--;
    return (int)n;
}

int im_captions_speaking(const im_captions *k) { return k ? k->open : 0; }
float im_captions_level_db(const im_captions *k) { return k ? k->level_db : -120.0f; }
double im_captions_last_ms(const im_captions *k) { return k ? k->last_ms : 0; }
double im_captions_last_audio_s(const im_captions *k) { return k ? k->last_audio_s : 0; }
