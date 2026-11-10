/* Screen blur models: person detector -> woman/man classifier, frame nudity classifier. See im_vision.h. */
#include "im_vision.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "onnxruntime_c_api.h"

#define MAX_DETS 64
#define MAX_LABELS 8

typedef struct {
    OrtSession *sess;
    int in_w, in_h;
    float pad;
    int n_labels;
    char labels[MAX_LABELS][24];
    char in_name[32], out_name[32];
    float *buf; /* input tensor, 3 * in_h * in_w */
    int ok;
} vmodel;

struct im_vision {
    const OrtApi *api;
    OrtEnv *env;
    OrtMemoryInfo *mem;
    vmodel person, gender, nsfw;
    unsigned policy;
    im_vision_params prm;
    int male_idx[MAX_LABELS], n_male;
    float last_nsfw;
    int nsfw_idx;
    char err[512];
};

static void seterr(im_vision *v, const char *what, OrtStatus *st) {
    const char *m = st ? v->api->GetErrorMessage(st) : "";
    size_t n = strlen(v->err);
    if (n < sizeof v->err - 2)
        snprintf(v->err + n, sizeof v->err - n, "%s%s%s%s", n ? "; " : "", what, *m ? ": " : "", m);
    if (st) v->api->ReleaseStatus(st);
}

static void quiet(im_vision *v, OrtStatus *st) { if (st) v->api->ReleaseStatus(st); }

static int meta(im_vision *v, OrtModelMetadata *md, OrtAllocator *al, const char *key, char *out, size_t n) {
    char *val = NULL;
    OrtStatus *st = v->api->ModelMetadataLookupCustomMetadataMap(md, al, key, &val);
    if (st) { v->api->ReleaseStatus(st); return 0; }
    if (!val) return 0;
    snprintf(out, n, "%s", val);
    quiet(v, v->api->AllocatorFree(al, val));
    return 1;
}

/* Loads one contract model; kind = "detector" or "classifier". */
static int load(im_vision *v, vmodel *m, const char *path, const char *kind, int threads) {
    const OrtApi *api = v->api;
    if (!path || !*path) return 0;
    OrtSessionOptions *so = NULL;
    OrtStatus *st = api->CreateSessionOptions(&so);
    if (st) { seterr(v, "session options", st); return 0; }
    OrtStatus *o[3] = {api->SetIntraOpNumThreads(so, threads), api->SetInterOpNumThreads(so, 1),
                       api->SetSessionGraphOptimizationLevel(so, ORT_ENABLE_ALL)};
    for (int i = 0; i < 3; i++)
        if (o[i]) api->ReleaseStatus(o[i]);
    st = api->CreateSession(v->env, path, so, &m->sess);
    api->ReleaseSessionOptions(so);
    if (st) { seterr(v, path, st); m->sess = NULL; return 0; }

    OrtAllocator *al = NULL;
    OrtModelMetadata *md = NULL;
    char s[256] = {0}, k[32] = {0};
    if ((st = api->GetAllocatorWithDefaultOptions(&al)) || (st = api->SessionGetModelMetadata(m->sess, &md))) {
        seterr(v, path, st);
        return 0;
    }
    int good = meta(v, md, al, "im.vision", s, sizeof s) && atoi(s) == 1 && meta(v, md, al, "im.kind", k, sizeof k) &&
               !strcmp(k, kind);
    if (good && meta(v, md, al, "im.input_w", s, sizeof s)) m->in_w = atoi(s);
    if (good && meta(v, md, al, "im.input_h", s, sizeof s)) m->in_h = atoi(s);
    m->pad = 0.5f;
    if (meta(v, md, al, "im.pad", s, sizeof s)) m->pad = (float)atof(s);
    if (meta(v, md, al, "im.labels", s, sizeof s)) {
        char *save = NULL;
        for (char *t = strtok_r(s, ",", &save); t && m->n_labels < MAX_LABELS; t = strtok_r(NULL, ",", &save))
            snprintf(m->labels[m->n_labels++], sizeof m->labels[0], "%s", t);
    }
    api->ReleaseModelMetadata(md);
    char *name = NULL;
    if (!(st = api->SessionGetInputName(m->sess, 0, al, &name))) {
        snprintf(m->in_name, sizeof m->in_name, "%s", name);
        quiet(v, api->AllocatorFree(al, name));
    } else seterr(v, path, st);
    if (!(st = api->SessionGetOutputName(m->sess, 0, al, &name))) {
        snprintf(m->out_name, sizeof m->out_name, "%s", name);
        quiet(v, api->AllocatorFree(al, name));
    } else seterr(v, path, st);
    if (!good || m->in_w <= 0 || m->in_h <= 0 || m->in_w > 2048 || m->in_h > 2048 ||
        (!strcmp(kind, "classifier") && m->n_labels < 2)) {
        char e[300];
        snprintf(e, sizeof e, "%s: not an im.vision %s model", path, kind);
        seterr(v, e, NULL);
        return 0;
    }
    m->buf = malloc(sizeof(float) * 3 * (size_t)m->in_w * m->in_h);
    if (!m->buf) return 0;
    m->ok = 1;
    return 1;
}

static void unload(im_vision *v, vmodel *m) {
    if (m->sess) v->api->ReleaseSession(m->sess);
    free(m->buf);
    memset(m, 0, sizeof *m);
}

im_vision *im_vision_create(const im_vision_config *cfg, char *err, size_t errlen) {
    im_vision *v = calloc(1, sizeof *v);
    if (!v) { if (err && errlen) snprintf(err, errlen, "out of memory"); return NULL; }
    v->prm = (im_vision_params){0.10f, 0.5f, 0.98f, 0.6f, 12};
    v->last_nsfw = -1;
    v->nsfw_idx = -1;
    v->policy = cfg ? cfg->policy : 0;
    v->api = OrtGetApiBase()->GetApi(ORT_API_VERSION);
    if (!v->api) { snprintf(v->err, sizeof v->err, "ONNX Runtime API version mismatch"); goto done; }
    OrtStatus *st = v->api->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "waaiya-vision", &v->env);
    if (st) { seterr(v, "CreateEnv", st); v->env = NULL; goto done; }
    if ((st = v->api->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &v->mem))) {
        seterr(v, "memory info", st);
        goto done;
    }
    if (!cfg) goto done;
    int th = cfg->threads > 0 ? cfg->threads : 2;
    load(v, &v->person, cfg->person_model, "detector", th);
    if (load(v, &v->gender, cfg->gender_model, "classifier", th)) {
        for (int i = 0; i < v->gender.n_labels; i++)
            if (!strcmp(v->gender.labels[i], "man") || !strcmp(v->gender.labels[i], "boy") ||
                !strcmp(v->gender.labels[i], "male"))
                v->male_idx[v->n_male++] = i;
        if (!v->n_male) { seterr(v, "gender model has no 'man' label", NULL); unload(v, &v->gender); }
    }
    if (load(v, &v->nsfw, cfg->nsfw_model, "classifier", th)) {
        for (int i = 0; i < v->nsfw.n_labels; i++)
            if (!strcmp(v->nsfw.labels[i], "nsfw")) v->nsfw_idx = i;
        if (v->nsfw_idx < 0) { seterr(v, "nudity model has no 'nsfw' label", NULL); unload(v, &v->nsfw); }
    }
done:
    if (err && errlen) snprintf(err, errlen, "%s", v->err);
    return v;
}

void im_vision_destroy(im_vision *v) {
    if (!v) return;
    if (v->api) {
        unload(v, &v->person);
        unload(v, &v->gender);
        unload(v, &v->nsfw);
        if (v->mem) v->api->ReleaseMemoryInfo(v->mem);
        if (v->env) v->api->ReleaseEnv(v->env);
    }
    free(v);
}

void im_vision_set_policy(im_vision *v, unsigned p) { if (v) v->policy = p; }
void im_vision_get_params(const im_vision *v, im_vision_params *p) { if (v && p) *p = v->prm; }
void im_vision_set_params(im_vision *v, const im_vision_params *p) { if (v && p) v->prm = *p; }
const char *im_vision_error(const im_vision *v) { return v ? v->err : "no vision"; }
float im_vision_last_nsfw(const im_vision *v) { return v ? v->last_nsfw : -1; }

unsigned im_vision_status(const im_vision *v) {
    if (!v) return IM_VISION_WOMEN | IM_VISION_NSFW;
    unsigned bad = 0;
    if ((v->policy & IM_VISION_WOMEN) && !v->person.ok) bad |= IM_VISION_WOMEN;
    if ((v->policy & IM_VISION_NSFW) && !v->nsfw.ok) bad |= IM_VISION_NSFW;
    return bad;
}

/* Bilinear sample of the source rect (sx0,sy0)-(sx1,sy1) (source pixels) into a dw x dh region of the model input
 * at (ox, oy); the rest of the input keeps whatever was there (padding). RGB 0..1, planar. */
static void sample(const uint8_t *rgba, int w, int h, int stride, float sx0, float sy0, float sx1, float sy1,
                   float *dst, int in_w, int in_h, int ox, int oy, int dw, int dh) {
    size_t plane = (size_t)in_w * in_h;
    float fx = (sx1 - sx0) / dw, fy = (sy1 - sy0) / dh;
    /* box-average when shrinking a lot (> 2x), to avoid aliasing on text and fine patterns */
    int ax = fx > 2 ? (int)(fx / 2) : 0, ay = fy > 2 ? (int)(fy / 2) : 0;
    const float k = 1.0f / 255.0f;
    for (int y = 0; y < dh; y++) {
        float sy = sy0 + (y + 0.5f) * fy - 0.5f;
        if (sy < 0) sy = 0;
        if (sy > h - 1) sy = (float)(h - 1);
        int y0 = (int)sy, y1 = y0 + 1 < h ? y0 + 1 : y0;
        float wy = sy - y0;
        float *pr = dst + (size_t)(oy + y) * in_w + ox, *pg = pr + plane, *pb = pg + plane;
        for (int x = 0; x < dw; x++) {
            float sx = sx0 + (x + 0.5f) * fx - 0.5f;
            if (sx < 0) sx = 0;
            if (sx > w - 1) sx = (float)(w - 1);
            int x0 = (int)sx, x1 = x0 + 1 < w ? x0 + 1 : x0;
            float wx = sx - x0;
            float c[3];
            if (ax || ay) {
                int n = 0;
                float acc[3] = {0, 0, 0};
                for (int yy = y0 - ay; yy <= y0 + ay; yy++) {
                    if (yy < 0 || yy >= h) continue;
                    for (int xx = x0 - ax; xx <= x0 + ax; xx++) {
                        if (xx < 0 || xx >= w) continue;
                        const uint8_t *p = rgba + (size_t)yy * stride + (size_t)xx * 4;
                        acc[0] += p[0]; acc[1] += p[1]; acc[2] += p[2];
                        n++;
                    }
                }
                for (int i = 0; i < 3; i++) c[i] = acc[i] / (n ? n : 1);
            } else {
                const uint8_t *a = rgba + (size_t)y0 * stride + (size_t)x0 * 4, *b = rgba + (size_t)y0 * stride + (size_t)x1 * 4;
                const uint8_t *cc = rgba + (size_t)y1 * stride + (size_t)x0 * 4, *d = rgba + (size_t)y1 * stride + (size_t)x1 * 4;
                for (int i = 0; i < 3; i++)
                    c[i] = (a[i] * (1 - wx) + b[i] * wx) * (1 - wy) + (cc[i] * (1 - wx) + d[i] * wx) * wy;
            }
            pr[x] = c[0] * k; pg[x] = c[1] * k; pb[x] = c[2] * k;
        }
    }
}

/* Runs a model on its filled input buffer. Returns a pointer into the output tensor (valid until *out_val is
 * released) and the element count. */
static const float *run(im_vision *v, vmodel *m, OrtValue **out_val, size_t *count) {
    const OrtApi *api = v->api;
    int64_t shape[4] = {1, 3, m->in_h, m->in_w};
    OrtValue *in = NULL;
    *out_val = NULL;
    OrtStatus *st = api->CreateTensorWithDataAsOrtValue(v->mem, m->buf, sizeof(float) * 3 * (size_t)m->in_w * m->in_h,
                                                        shape, 4, ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, &in);
    if (st) { seterr(v, "input tensor", st); return NULL; }
    const char *in_names[1] = {m->in_name}, *out_names[1] = {m->out_name};
    st = api->Run(m->sess, NULL, in_names, (const OrtValue *const *)&in, 1, out_names, 1, out_val);
    api->ReleaseValue(in);
    if (st) { seterr(v, "run", st); *out_val = NULL; return NULL; }
    float *p = NULL;
    OrtTensorTypeAndShapeInfo *info = NULL;
    if ((st = api->GetTensorMutableData(*out_val, (void **)&p)) || (st = api->GetTensorTypeAndShape(*out_val, &info))) {
        seterr(v, "output", st);
        api->ReleaseValue(*out_val);
        *out_val = NULL;
        return NULL;
    }
    quiet(v, api->GetTensorShapeElementCount(info, count));
    api->ReleaseTensorTypeAndShapeInfo(info);
    return p;
}

/* Letterbox the whole frame into the model input (top-left, pad elsewhere). Returns the scale. */
static float letterbox(vmodel *m, const uint8_t *rgba, int w, int h, int stride) {
    float s = fminf((float)m->in_w / w, (float)m->in_h / h);
    int dw = (int)lroundf(w * s), dh = (int)lroundf(h * s);
    if (dw < 1) dw = 1;
    if (dh < 1) dh = 1;
    if (dw > m->in_w) dw = m->in_w;
    if (dh > m->in_h) dh = m->in_h;
    size_t n = 3 * (size_t)m->in_w * m->in_h;
    for (size_t i = 0; i < n; i++) m->buf[i] = m->pad;
    sample(rgba, w, h, stride, 0, 0, (float)w, (float)h, m->buf, m->in_w, m->in_h, 0, 0, dw, dh);
    return s;
}

static float iou(const im_vrect *a, const im_vrect *b) {
    float ix = fminf(a->x1, b->x1) - fmaxf(a->x0, b->x0), iy = fminf(a->y1, b->y1) - fmaxf(a->y0, b->y0);
    if (ix <= 0 || iy <= 0) return 0;
    float i = ix * iy, u = (a->x1 - a->x0) * (a->y1 - a->y0) + (b->x1 - b->x0) * (b->y1 - b->y0) - i;
    return u > 0 ? i / u : 0;
}

static int by_score(const void *a, const void *b) {
    float d = ((const im_vrect *)b)->score - ((const im_vrect *)a)->score;
    return (d > 0) - (d < 0);
}

static float area(const im_vrect *r) { return (r->x1 - r->x0) * (r->y1 - r->y0); }

static int by_area(const void *a, const void *b) {
    float d = area((const im_vrect *)b) - area((const im_vrect *)a);
    return (d > 0) - (d < 0);
}

/* Person boxes, normalised to the frame, after threshold + NMS. */
static int detect_people(im_vision *v, const uint8_t *rgba, int w, int h, int stride, im_vrect *out, int max) {
    vmodel *m = &v->person;
    float s = letterbox(m, rgba, w, h, stride);
    OrtValue *ov = NULL;
    size_t cnt = 0;
    const float *d = run(v, m, &ov, &cnt);
    if (!d) return -1;
    im_vrect cand[256];
    int nc = 0;
    for (size_t i = 0; i + 5 <= cnt; i += 5) {
        if (d[i + 4] < v->prm.person_score) continue;
        im_vrect r = {d[i] / s / w, d[i + 1] / s / h, d[i + 2] / s / w, d[i + 3] / s / h, IM_VK_UNSURE, d[i + 4], -1};
        r.x0 = fmaxf(r.x0, 0); r.y0 = fmaxf(r.y0, 0); r.x1 = fminf(r.x1, 1); r.y1 = fminf(r.y1, 1);
        if (r.x1 <= r.x0 || r.y1 <= r.y0) continue;
        if (nc < 256) cand[nc++] = r;
        else { /* keep the best 256 */
            int lo = 0;
            for (int j = 1; j < nc; j++) if (cand[j].score < cand[lo].score) lo = j;
            if (r.score > cand[lo].score) cand[lo] = r;
        }
    }
    v->api->ReleaseValue(ov);
    qsort(cand, nc, sizeof cand[0], by_score);
    int n = 0;
    for (int i = 0; i < nc && n < max; i++) {
        int keep = 1;
        for (int j = 0; j < n && keep; j++)
            if (iou(&cand[i], &out[j]) > v->prm.nms_iou) keep = 0;
        if (keep) out[n++] = cand[i];
    }
    return n;
}

/* p(man or boy) for one person box, with the same 10% context as training (fetch_openimages.py). */
static float classify(im_vision *v, const uint8_t *rgba, int w, int h, int stride, const im_vrect *r) {
    vmodel *m = &v->gender;
    float bw = (r->x1 - r->x0) * w, bh = (r->y1 - r->y0) * h;
    float x0 = fmaxf(0, r->x0 * w - 0.1f * bw), x1 = fminf((float)w, r->x1 * w + 0.1f * bw);
    float y0 = fmaxf(0, r->y0 * h - 0.1f * bh), y1 = fminf((float)h, r->y1 * h + 0.1f * bh);
    if (x1 - x0 < 2 || y1 - y0 < 2) return 0;
    sample(rgba, w, h, stride, x0, y0, x1, y1, m->buf, m->in_w, m->in_h, 0, 0, m->in_w, m->in_h);
    OrtValue *ov = NULL;
    size_t cnt = 0;
    const float *p = run(v, m, &ov, &cnt);
    if (!p) return -1;
    float male = 0;
    for (int i = 0; i < v->n_male; i++)
        if ((size_t)v->male_idx[i] < cnt) male += p[v->male_idx[i]];
    v->api->ReleaseValue(ov);
    return male;
}

int im_vision_detect(im_vision *v, const uint8_t *rgba, int w, int h, int stride, int run_nsfw, im_vrect *out,
                     int max) {
    if (!v || !rgba || w < 8 || h < 8 || stride < w * 4 || !out || max < 1) return -1;
    v->err[0] = 0;
    int n = 0, failed = 0;
    if ((v->policy & IM_VISION_WOMEN) && v->person.ok) {
        im_vrect people[MAX_DETS];
        int np = detect_people(v, rgba, w, h, stride, people, MAX_DETS);
        if (np < 0) failed = 1;
        if (np > 0) {
            qsort(people, np, sizeof people[0], by_area);
            for (int i = 0; i < np; i++) {
                im_vrect r = people[i];
                r.kind = IM_VK_UNSURE; /* fail-closed default */
                if (v->gender.ok && i < v->prm.max_people) {
                    float pm = classify(v, rgba, w, h, stride, &r);
                    if (pm < 0) failed = 1;
                    else {
                        r.p_male = pm;
                        r.kind = pm >= v->prm.male_clear ? IM_VK_CLEAR : pm <= 1 - v->prm.male_clear ? IM_VK_WOMAN
                                                                                                      : IM_VK_UNSURE;
                    }
                }
                if (n < max) out[n++] = r;
            }
        }
    }
    if ((v->policy & IM_VISION_NSFW) && v->nsfw.ok && run_nsfw) {
        letterbox(&v->nsfw, rgba, w, h, stride);
        OrtValue *ov = NULL;
        size_t cnt = 0;
        const float *p = run(v, &v->nsfw, &ov, &cnt);
        if (!p) failed = 1;
        else {
            v->last_nsfw = (size_t)v->nsfw_idx < cnt ? p[v->nsfw_idx] : 0;
            v->api->ReleaseValue(ov);
            if (v->last_nsfw >= v->prm.nsfw_score && n < max)
                out[n++] = (im_vrect){0, 0, 1, 1, IM_VK_FULL, v->last_nsfw, -1};
        }
    }
    return failed ? -1 : n;
}
