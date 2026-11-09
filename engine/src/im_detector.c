/* Women's-singing detector: streaming power-spectrum front end + ONNX classifier. See im_detector.h. */
#include "im_detector.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

struct im_detector {
    const OrtApi *api;
    OrtSession *sess;
    OrtMemoryInfo *mem;
    OrtValue *v_in, *v_out;

    int rate, n_fft, win, hop, frames, bins, eval_every;
    float preemph, threshold, release_s;

    /* FFT: n_fft = radix * m, radix in {1, 3}, m a power of two */
    int radix, m;
    int *bitrev;                /* [m] */
    float *tw_re, *tw_im;       /* [m/2] twiddles of the size-m FFT */
    float *big_re, *big_im;     /* [n_fft] exp(-2 pi i k / n_fft) */
    float *sub_re, *sub_im;     /* [radix * m] sub-FFT work */
    float *window;              /* [n_fft] */

    float prev;                 /* last raw sample (pre-emphasis) */
    float *frame;               /* [n_fft] sliding pre-emphasised samples */
    int have;                   /* valid samples in frame (<= n_fft) */
    int since;                  /* new samples since the last frame */
    float *ring;                /* [frames][bins] power frames */
    int ring_pos, frames_since_eval;
    float *in;                  /* [bins * frames] classifier input */
    float out[IM_DET_NOUT];
    float probs[IM_DET_NOUT];
};

static int meta_get(const OrtApi *api, OrtModelMetadata *md, OrtAllocator *al, const char *key, char *dst, size_t n) {
    char *val = NULL;
    OrtStatus *st = api->ModelMetadataLookupCustomMetadataMap(md, al, key, &val);
    if (st) { api->ReleaseStatus(st); return 0; }
    if (!val) return 0;
    snprintf(dst, n, "%s", val);
    OrtStatus *fs = api->AllocatorFree(al, val);
    if (fs) api->ReleaseStatus(fs);
    return 1;
}

static void fail(char *err, size_t n, const char *msg, const char *detail) {
    if (err && n) snprintf(err, n, "detector: %s%s%s", msg, detail ? ": " : "", detail ? detail : "");
}

static int setup_fft(im_detector *d) {
    int n = d->n_fft;
    d->radix = (n % 3 == 0) ? 3 : 1;
    d->m = n / d->radix;
    int m = d->m, bits = 0;
    if (m < 2 || (m & (m - 1))) return 0;
    while ((1 << bits) < m) bits++;
    d->bitrev = malloc(sizeof(int) * (size_t)m);
    d->tw_re = malloc(sizeof(float) * (size_t)(m / 2));
    d->tw_im = malloc(sizeof(float) * (size_t)(m / 2));
    d->big_re = malloc(sizeof(float) * (size_t)n);
    d->big_im = malloc(sizeof(float) * (size_t)n);
    d->sub_re = malloc(sizeof(float) * (size_t)n);
    d->sub_im = malloc(sizeof(float) * (size_t)n);
    if (!d->bitrev || !d->tw_re || !d->tw_im || !d->big_re || !d->big_im || !d->sub_re || !d->sub_im) return 0;
    for (int i = 0; i < m; i++) {
        int r = 0;
        for (int b = 0; b < bits; b++) r |= ((i >> b) & 1) << (bits - 1 - b);
        d->bitrev[i] = r;
    }
    for (int i = 0; i < m / 2; i++) {
        d->tw_re[i] = (float)cos(-2.0 * M_PI * i / m);
        d->tw_im[i] = (float)sin(-2.0 * M_PI * i / m);
    }
    for (int k = 0; k < n; k++) {
        d->big_re[k] = (float)cos(-2.0 * M_PI * k / n);
        d->big_im[k] = (float)sin(-2.0 * M_PI * k / n);
    }
    return 1;
}

/* in-place radix-2 FFT of size d->m */
static void fft_m(const im_detector *d, float *re, float *im) {
    int m = d->m;
    for (int i = 0; i < m; i++) {
        int j = d->bitrev[i];
        if (j > i) {
            float t = re[i]; re[i] = re[j]; re[j] = t;
            t = im[i]; im[i] = im[j]; im[j] = t;
        }
    }
    for (int len = 2; len <= m; len <<= 1) {
        int half = len >> 1, step = m / len;
        for (int s = 0; s < m; s += len)
            for (int k = 0; k < half; k++) {
                float wr = d->tw_re[k * step], wi = d->tw_im[k * step];
                int a = s + k, b = a + half;
                float xr = re[b] * wr - im[b] * wi, xi = re[b] * wi + im[b] * wr;
                re[b] = re[a] - xr; im[b] = im[a] - xi;
                re[a] += xr; im[a] += xi;
            }
    }
}

/* power spectrum of the windowed frame -> dst[bins] */
static void power_frame(im_detector *d, float *dst) {
    int n = d->n_fft, m = d->m, R = d->radix;
    for (int r = 0; r < R; r++) {
        float *re = d->sub_re + r * m, *im = d->sub_im + r * m;
        for (int j = 0; j < m; j++) {
            int t = j * R + r;
            re[j] = d->frame[t] * d->window[t];
            im[j] = 0.0f;
        }
        fft_m(d, re, im);
    }
    for (int k = 0; k < d->bins; k++) {
        int km = k % m;
        float xr = 0.0f, xi = 0.0f;
        for (int r = 0; r < R; r++) {
            int w = (r * k) % n;
            float a = d->sub_re[r * m + km], b = d->sub_im[r * m + km];
            xr += a * d->big_re[w] - b * d->big_im[w];
            xi += a * d->big_im[w] + b * d->big_re[w];
        }
        dst[k] = xr * xr + xi * xi;
    }
}

void im_detector_reset(im_detector *d) {
    if (!d) return;
    d->prev = 0.0f;
    d->have = 0;
    d->since = 0;
    d->ring_pos = 0;
    d->frames_since_eval = 0;
    memset(d->frame, 0, sizeof(float) * (size_t)d->n_fft);
    memset(d->ring, 0, sizeof(float) * (size_t)d->frames * (size_t)d->bins);
    memset(d->probs, 0, sizeof d->probs);
}

void im_detector_destroy(im_detector *d) {
    if (!d) return;
    if (d->api) {
        if (d->v_in) d->api->ReleaseValue(d->v_in);
        if (d->v_out) d->api->ReleaseValue(d->v_out);
        if (d->mem) d->api->ReleaseMemoryInfo(d->mem);
        if (d->sess) d->api->ReleaseSession(d->sess);
    }
    free(d->bitrev); free(d->tw_re); free(d->tw_im); free(d->big_re); free(d->big_im);
    free(d->sub_re); free(d->sub_im); free(d->window); free(d->frame); free(d->ring); free(d->in);
    free(d);
}

im_detector *im_detector_create(const OrtApi *api, OrtEnv *env, const char *path, int rate, char *err, size_t errlen) {
    if (!api || !env || !path) { fail(err, errlen, "no model", NULL); return NULL; }
    im_detector *d = calloc(1, sizeof(*d));
    if (!d) { fail(err, errlen, "out of memory", NULL); return NULL; }
    d->api = api;
    OrtSessionOptions *so = NULL;
    OrtStatus *st = api->CreateSessionOptions(&so);
    if (st) { fail(err, errlen, "options", api->GetErrorMessage(st)); api->ReleaseStatus(st); goto bad; }
    {
        OrtStatus *o[3] = {api->SetIntraOpNumThreads(so, 1), api->SetInterOpNumThreads(so, 1),
                           api->SetSessionGraphOptimizationLevel(so, ORT_ENABLE_ALL)};
        for (int i = 0; i < 3; i++)
            if (o[i]) api->ReleaseStatus(o[i]);
    }
    st = api->CreateSession(env, path, so, &d->sess);
    api->ReleaseSessionOptions(so);
    if (st) { fail(err, errlen, "cannot load", api->GetErrorMessage(st)); api->ReleaseStatus(st); goto bad; }

    OrtAllocator *al = NULL;
    OrtModelMetadata *md = NULL;
    if ((st = api->GetAllocatorWithDefaultOptions(&al)) || (st = api->SessionGetModelMetadata(d->sess, &md))) {
        fail(err, errlen, "metadata", api->GetErrorMessage(st));
        api->ReleaseStatus(st);
        goto bad;
    }
    char v[10][64] = {{0}};
    const char *keys[10] = {"im.detector", "im.det_sample_rate", "im.det_n_fft", "im.det_win", "im.det_hop",
                            "im.det_frames", "im.det_preemph", "im.det_threshold", "im.det_release_s",
                            "im.det_eval_every_hops"};
    int ok = 1;
    for (int i = 0; i < 10; i++) ok &= meta_get(api, md, al, keys[i], v[i], sizeof v[i]) || i >= 7;
    api->ReleaseModelMetadata(md);
    if (!ok || atoi(v[0]) != 1) { fail(err, errlen, "not an im.detector=1 model", NULL); goto bad; }
    d->rate = atoi(v[1]);
    d->n_fft = atoi(v[2]);
    d->win = atoi(v[3]);
    d->hop = atoi(v[4]);
    d->frames = atoi(v[5]);
    d->preemph = (float)atof(v[6]);
    d->threshold = v[7][0] ? (float)atof(v[7]) : 0.5f;
    d->release_s = v[8][0] ? (float)atof(v[8]) : 2.0f;
    d->eval_every = v[9][0] ? atoi(v[9]) : 25;
    if (d->rate != rate) {
        char m[80];
        snprintf(m, sizeof m, "model wants %d Hz, engine runs at %d Hz", d->rate, rate);
        fail(err, errlen, "sample rate mismatch", m);
        goto bad;
    }
    if (d->n_fft <= 0 || d->win <= 0 || d->win > d->n_fft || d->hop <= 0 || d->hop > d->n_fft || d->frames <= 0 || d->eval_every <= 0) {
        fail(err, errlen, "bad front-end metadata", NULL);
        goto bad;
    }
    d->bins = d->n_fft / 2 + 1;
    if (!setup_fft(d)) { fail(err, errlen, "n_fft must be 2^k or 3*2^k", NULL); goto bad; }
    d->window = calloc((size_t)d->n_fft, sizeof(float));
    d->frame = calloc((size_t)d->n_fft, sizeof(float));
    d->ring = calloc((size_t)d->frames * (size_t)d->bins, sizeof(float));
    d->in = calloc((size_t)d->frames * (size_t)d->bins, sizeof(float));
    if (!d->window || !d->frame || !d->ring || !d->in) { fail(err, errlen, "out of memory", NULL); goto bad; }
    int off = (d->n_fft - d->win) / 2;
    for (int i = 0; i < d->win; i++)  /* symmetric Hann (torch.hann_window(periodic=False)) */
        d->window[off + i] = (float)(0.5 - 0.5 * cos(2.0 * M_PI * i / (d->win - 1)));

    if ((st = api->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &d->mem))) {
        fail(err, errlen, "mem", api->GetErrorMessage(st)); api->ReleaseStatus(st); goto bad;
    }
    int64_t ishape[3] = {1, d->bins, d->frames}, oshape[2] = {1, IM_DET_NOUT};
    if ((st = api->CreateTensorWithDataAsOrtValue(d->mem, d->in, sizeof(float) * (size_t)d->bins * (size_t)d->frames,
                                                  ishape, 3, ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, &d->v_in)) ||
        (st = api->CreateTensorWithDataAsOrtValue(d->mem, d->out, sizeof d->out, oshape, 2,
                                                  ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, &d->v_out))) {
        fail(err, errlen, "tensor", api->GetErrorMessage(st)); api->ReleaseStatus(st); goto bad;
    }
    im_detector_reset(d);
    return d;
bad:
    im_detector_destroy(d);
    return NULL;
}

/* assemble [bins][frames] oldest-first from the ring */
static void assemble(const im_detector *d, float *dst) {
    for (int t = 0; t < d->frames; t++) {
        const float *f = d->ring + (size_t)((d->ring_pos + t) % d->frames) * (size_t)d->bins;
        for (int b = 0; b < d->bins; b++) dst[(size_t)b * (size_t)d->frames + (size_t)t] = f[b];
    }
}

static int classify(im_detector *d) {
    assemble(d, d->in);
    double energy = 0.0;
    size_t n = (size_t)d->bins * (size_t)d->frames;
    for (size_t i = 0; i < n; i++) energy += d->in[i];
    if (energy < 1e-6 * (double)d->frames) { /* no voice in the window (separated output is silent) */
        memset(d->probs, 0, sizeof d->probs);
        return 1;
    }
    const char *in_names[1] = {"power"}, *out_names[1] = {"probs"};
    OrtStatus *st = d->api->Run(d->sess, NULL, in_names, (const OrtValue *const *)&d->v_in, 1, out_names, 1, &d->v_out);
    if (st) { d->api->ReleaseStatus(st); return -1; }
    for (int i = 0; i < IM_DET_NOUT; i++) {
        if (!isfinite(d->out[i])) return -1;
        d->probs[i] = d->out[i];
    }
    return 1;
}

int im_detector_push(im_detector *d, const float *x, int n) {
    if (!d) return 0;
    int result = 0;
    for (int i = 0; i < n; i++) {
        float y = x[i] - d->preemph * d->prev;
        d->prev = x[i];
        if (d->have < d->n_fft) { /* start-up: fill the first frame */
            d->frame[d->have++] = y;
            if (d->have < d->n_fft) continue;
        } else { /* collect a hop at the end of the (already shifted) frame */
            d->frame[d->n_fft - d->hop + d->since] = y;
            if (++d->since < d->hop) continue;
        }
        d->since = 0;
        power_frame(d, d->ring + (size_t)d->ring_pos * (size_t)d->bins);
        d->ring_pos = (d->ring_pos + 1) % d->frames;
        /* shift once per hop so the next hop's samples land at the end */
        memmove(d->frame, d->frame + d->hop, sizeof(float) * (size_t)(d->n_fft - d->hop));
        if (++d->frames_since_eval >= d->eval_every) {
            d->frames_since_eval = 0;
            int r = classify(d);
            if (r < 0) result = -1;
            else if (result == 0) result = 1;
        }
    }
    return result;
}

const float *im_detector_probs(const im_detector *d) { return d->probs; }
float im_detector_threshold(const im_detector *d) { return d->threshold; }
float im_detector_release_s(const im_detector *d) { return d->release_s; }
int im_detector_hop(const im_detector *d) { return d->hop; }
int im_detector_eval_every(const im_detector *d) { return d->eval_every; }

int im_detector_power_window(const im_detector *d, float *dst, size_t n) {
    if (!d || n < (size_t)d->bins * (size_t)d->frames) return 0;
    assemble(d, dst);
    return 1;
}
