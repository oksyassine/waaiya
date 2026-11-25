/* "Check for music": resampler + tagger windows. See im_music.h. */
#include "im_music.h"
#include "im_detector.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define PHASES 256   /* kernel table resolution (positions per input sample) */
#define ZEROS 16     /* sinc zero crossings on each side, at the output rate */

typedef struct {
    double step;            /* input samples per output sample */
    double pos;             /* next output position, in input samples from buf[0] */
    int half;               /* kernel half width in input samples */
    float *table;           /* [(PHASES + 1) * 2 * half] kernel taps by phase */
    float *buf;             /* pending input */
    int len, cap;
} resampler;

struct im_music {
    const OrtApi *api;
    OrtEnv *env;
    im_detector *det;
    int classes, rate, in_rate, hop, eval_every, frames;
    resampler rs;
    int bypass;             /* in_rate == rate */
    float *chunk;           /* [hop] resampled samples waiting for a full hop */
    int chunk_len;
    long hops;              /* hops pushed to the tagger */
    double *energy;         /* [cap_e] sum of squares per hop */
    long cap_e;
    long evals;             /* tagger runs so far */
    float *out;             /* [cap_out * classes] waiting windows */
    float *out_db;          /* [cap_out] */
    int n_out, cap_out;
    long next_window;       /* index of the next window to output */
    int failed;
};

static double bessel_i0(double x) {
    double s = 1.0, t = 1.0;
    for (int k = 1; k < 40; k++) {
        t *= (x / (2.0 * k)) * (x / (2.0 * k));
        s += t;
    }
    return s;
}

static int rs_init(resampler *r, int in_rate, int out_rate) {
    double c = out_rate < in_rate ? (double)out_rate / in_rate : 1.0;  /* cutoff as a fraction of the input Nyquist */
    c *= 0.95;
    r->step = (double)in_rate / out_rate;
    r->half = (int)ceil(ZEROS / c);
    int taps = 2 * r->half;
    r->table = malloc(sizeof(float) * (size_t)(PHASES + 1) * (size_t)taps);
    r->cap = 1 << 16;
    r->buf = malloc(sizeof(float) * (size_t)r->cap);
    if (!r->table || !r->buf) return 0;
    const double beta = 8.0, i0b = bessel_i0(beta);
    for (int p = 0; p <= PHASES; p++) {
        double frac = (double)p / PHASES;    /* output position = tap base + frac */
        for (int j = 0; j < taps; j++) {
            double x = (j - r->half + 1) - frac;   /* input sample offset from the output position */
            double u = x / r->half;
            double w = fabs(u) >= 1.0 ? 0.0 : bessel_i0(beta * sqrt(1.0 - u * u)) / i0b;
            double s = x == 0.0 ? 1.0 : sin(M_PI * c * x) / (M_PI * c * x);
            r->table[(size_t)p * (size_t)taps + (size_t)j] = (float)(c * s * w);
        }
    }
    /* history before the start: zeros, so the first output is centred on the first input sample */
    r->len = r->half - 1;
    memset(r->buf, 0, sizeof(float) * (size_t)r->len);
    r->pos = r->half - 1;
    return 1;
}

/* appends input; writes outputs through emit() */
static int rs_push(resampler *r, const float *x, int n, im_music *m, int (*emit)(im_music *, float)) {
    if (r->len + n > r->cap) {
        int cap = r->cap;
        while (r->len + n > cap) cap *= 2;
        float *b = realloc(r->buf, sizeof(float) * (size_t)cap);
        if (!b) return -1;
        r->buf = b, r->cap = cap;
    }
    memcpy(r->buf + r->len, x, sizeof(float) * (size_t)n);
    r->len += n;
    int taps = 2 * r->half;
    while (r->pos + r->half < r->len) {
        int base = (int)floor(r->pos);
        double frac = r->pos - base;
        double pf = frac * PHASES;
        int p = (int)pf;
        float a = (float)(pf - p);
        const float *t0 = r->table + (size_t)p * (size_t)taps, *t1 = t0 + taps;
        const float *s = r->buf + base - r->half + 1;
        float y0 = 0.0f, y1 = 0.0f;
        for (int j = 0; j < taps; j++) {
            y0 += s[j] * t0[j];
            y1 += s[j] * t1[j];
        }
        if (emit(m, y0 + a * (y1 - y0)) < 0) return -1;
        r->pos += r->step;
    }
    /* drop what no future output needs */
    int keep_from = (int)floor(r->pos) - r->half + 1;
    if (keep_from > 0) {
        memmove(r->buf, r->buf + keep_from, sizeof(float) * (size_t)(r->len - keep_from));
        r->len -= keep_from;
        r->pos -= keep_from;
    }
    return 0;
}

static int grow(void **p, size_t elem, long need, long *cap) {
    if (need <= *cap) return 1;
    long c = *cap ? *cap : 1024;
    while (c < need) c *= 2;
    void *q = realloc(*p, elem * (size_t)c);
    if (!q) return 0;
    *p = q, *cap = c;
    return 1;
}

/* a full hop: energy, tagger; a classification completes window (evals - 2) */
static int hop_done(im_music *m) {
    if (!grow((void **)&m->energy, sizeof(double), m->hops + 1, &m->cap_e)) return -1;
    double e = 0.0;
    for (int i = 0; i < m->hop; i++) e += (double)m->chunk[i] * m->chunk[i];
    m->energy[m->hops++] = e;
    int r = im_detector_push(m->det, m->chunk, m->hop);
    m->chunk_len = 0;
    if (r < 0) { m->failed = 1; return -1; }
    if (r == 0) return 0;
    long k = m->evals++ - (m->frames / m->eval_every - 1);   /* the first runs see a partly empty window */
    if (k < 0) return 0;
    long c = m->cap_out;
    if (!grow((void **)&m->out, sizeof(float) * (size_t)m->classes, m->n_out + 1, &c)) return -1;
    long c2 = m->cap_out;
    if (!grow((void **)&m->out_db, sizeof(float), m->n_out + 1, &c2)) return -1;
    m->cap_out = (int)(c < c2 ? c : c2);
    memcpy(m->out + (size_t)m->n_out * (size_t)m->classes, im_detector_probs(m->det), sizeof(float) * (size_t)m->classes);
    /* the window's level: its frames' hops (window k starts at hop k * eval_every) */
    long h0 = k * m->eval_every, h1 = h0 + m->frames;
    if (h1 > m->hops) h1 = m->hops;
    double s = 0.0;
    for (long h = h0; h < h1; h++) s += m->energy[h];
    double n = (double)(h1 - h0) * m->hop;
    m->out_db[m->n_out] = (float)(10.0 * log10(s / (n > 0 ? n : 1) + 1e-12));
    m->n_out++;
    return 0;
}

static int emit(im_music *m, float y) {
    m->chunk[m->chunk_len++] = y;
    if (m->chunk_len == m->hop) return hop_done(m);
    return 0;
}

im_music *im_music_create(const char *path, int in_rate, char *err, size_t errlen) {
    if (in_rate < 4000 || in_rate > 384000) { if (err) snprintf(err, errlen, "music: bad sample rate %d", in_rate); return NULL; }
    im_music *m = calloc(1, sizeof(*m));
    if (!m) return NULL;
    m->api = OrtGetApiBase()->GetApi(ORT_API_VERSION);
    OrtStatus *st = m->api->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "waaiya-music", &m->env);
    if (st) {
        if (err) snprintf(err, errlen, "music: CreateEnv: %s", m->api->GetErrorMessage(st));
        m->api->ReleaseStatus(st);
        m->env = NULL;
        im_music_destroy(m);
        return NULL;
    }
    /* the tagger's own rate: try 32 kHz (models/music/export_tagger.py); im_detector refuses another */
    m->rate = 32000;
    m->det = im_detector_create(m->api, m->env, path, m->rate, err, errlen);
    if (!m->det) { im_music_destroy(m); return NULL; }
    m->classes = im_detector_nout(m->det);
    m->hop = im_detector_hop(m->det);
    m->eval_every = im_detector_eval_every(m->det);
    /* frames per window: the tagger's input is [bins, frames]; one second at 10 ms hops */
    m->frames = m->rate / m->hop;
    m->in_rate = in_rate;
    m->bypass = in_rate == m->rate;
    m->chunk = calloc((size_t)m->hop, sizeof(float));
    if (!m->chunk || (!m->bypass && !rs_init(&m->rs, in_rate, m->rate)) || m->classes < 2 || m->eval_every <= 0 ||
        m->frames % m->eval_every) {
        if (err) snprintf(err, errlen, "music: setup failed");
        im_music_destroy(m);
        return NULL;
    }
    return m;
}

void im_music_destroy(im_music *m) {
    if (!m) return;
    im_detector_destroy(m->det);
    if (m->env) m->api->ReleaseEnv(m->env);
    free(m->rs.table); free(m->rs.buf); free(m->chunk); free(m->energy); free(m->out); free(m->out_db);
    free(m);
}

int im_music_classes(const im_music *m) { return m ? m->classes : 0; }

int im_music_push(im_music *m, const float *x, int n) {
    if (!m || m->failed) return -1;
    if (m->bypass) {
        for (int i = 0; i < n; i++)
            if (emit(m, x[i]) < 0) return -1;
    } else if (rs_push(&m->rs, x, n, m, emit) < 0) {
        return -1;
    }
    return m->n_out;
}

int im_music_finish(im_music *m) {
    if (!m || m->failed) return -1;
    /* about one second of silence: the last partial window is tagged; windows past the end are not wanted, but the
     * caller knows the duration and drops them */
    float z[1024] = {0};
    long target = (long)m->in_rate + 2L * (m->bypass ? 0 : m->rs.half);
    for (long done = 0; done < target; done += 1024)
        if (im_music_push(m, z, 1024) < 0) return -1;
    return m->n_out;
}

int im_music_take(im_music *m, float *probs, float *level_db, int max) {
    if (!m || max <= 0) return 0;
    int k = m->n_out < max ? m->n_out : max;
    memcpy(probs, m->out, sizeof(float) * (size_t)k * (size_t)m->classes);
    if (level_db) memcpy(level_db, m->out_db, sizeof(float) * (size_t)k);
    memmove(m->out, m->out + (size_t)k * (size_t)m->classes, sizeof(float) * (size_t)(m->n_out - k) * (size_t)m->classes);
    memmove(m->out_db, m->out_db + k, sizeof(float) * (size_t)(m->n_out - k));
    m->n_out -= k;
    return k;
}
