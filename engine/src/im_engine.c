/* islamic-mute streaming engine. See include/im_engine.h for the contract. */
#include "im_engine.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "im_detector.h"
#include "onnxruntime_c_api.h"

#define IM_MAX_CH 8
/* Digital silence handling: after IM_SILENT_HOPS silent hops the model state is reset to its
 * start values and the model is skipped until sound returns. Long silence otherwise drifts the
 * model's running normalisation far from where it was trained (measured: instrument suppression
 * falls from ~24 dB to ~17 dB after 20 s of silence), and skipping saves CPU/battery when idle. */
#define IM_SILENT_HOPS 50
#define IM_SILENT_LEVEL 1e-5f /* about -100 dBFS peak */

struct im_engine {
    const OrtApi *api;
    OrtEnv *env;
    OrtSession *sess;
    OrtMemoryInfo *mem;
    OrtIoBinding *bind;

    int failed;
    unsigned long run_errors;
    char model_name[128];

    int channels, mono_mix, nmodel; /* nmodel = model instances (1 if mono_mix) */
    int rate, hop, state_size, model_latency;

    float *state_init;              /* [state_size] */
    float *state[IM_MAX_CH][2];     /* ping-pong state per model instance */
    int cur[IM_MAX_CH];             /* which state buffer is current */
    int silent[IM_MAX_CH];          /* consecutive silent hops per model instance */
    OrtValue *v_state[IM_MAX_CH][2];
    float *in_hop, *out_hop;        /* [hop] model I/O scratch */
    OrtValue *v_in, *v_out;

    float *in_buf[IM_MAX_CH];       /* [hop] collected input */
    float *dry_buf[IM_MAX_CH];      /* [hop + model_latency] delay line for bypass */
    float *out_buf[IM_MAX_CH];      /* [hop] last processed hop */
    int fill;                       /* samples in in_buf */
    int dry_len, dry_pos;

    int enabled;
    float gate_target, gate;        /* smoothed output gain */
    float gate_coef;

    im_detector *det;               /* optional women's-singing detector */
    char det_err[256];
    unsigned policy;
    int det_requested;
    int det_muted;                  /* policy currently mutes the output */
    long det_hold;                  /* samples left before unmuting */
    unsigned long det_errors;
    float *det_mono;                /* [hop] mono voice fed to the detector */
};

static void set_err(char *err, size_t n, const char *msg, const char *detail) {
    if (err && n) snprintf(err, n, "%s%s%s", msg, detail ? ": " : "", detail ? detail : "");
}

static int ort_ok(const OrtApi *api, OrtStatus *st, char *err, size_t n, const char *what) {
    if (!st) return 1;
    set_err(err, n, what, api->GetErrorMessage(st));
    api->ReleaseStatus(st);
    return 0;
}

static int meta_int(im_engine *e, OrtModelMetadata *md, OrtAllocator *al, const char *key, int *out) {
    char *val = NULL;
    OrtStatus *st = e->api->ModelMetadataLookupCustomMetadataMap(md, al, key, &val);
    if (st) { e->api->ReleaseStatus(st); return 0; }
    if (!val) return 0;
    *out = atoi(val);
    OrtStatus *fs = e->api->AllocatorFree(al, val);
    if (fs) e->api->ReleaseStatus(fs);
    return 1;
}

static void meta_str(im_engine *e, OrtModelMetadata *md, OrtAllocator *al, const char *key, char *dst, size_t n) {
    char *val = NULL;
    OrtStatus *st = e->api->ModelMetadataLookupCustomMetadataMap(md, al, key, &val);
    if (st) { e->api->ReleaseStatus(st); return; }
    if (!val) return;
    snprintf(dst, n, "%s", val);
    OrtStatus *fs = e->api->AllocatorFree(al, val);
    if (fs) e->api->ReleaseStatus(fs);
}

static void load_state_init(im_engine *e, const char *model_path) {
    size_t n = strlen(model_path);
    char *p = malloc(n + 32);
    if (!p) return;
    memcpy(p, model_path, n + 1);
    if (n > 5 && strcmp(p + n - 5, ".onnx") == 0) p[n - 5] = 0;
    strcat(p, ".state_init.bin");
    FILE *f = fopen(p, "rb");
    free(p);
    if (!f) return; /* zeros */
    size_t got = fread(e->state_init, sizeof(float), (size_t)e->state_size, f);
    fclose(f);
    if (got != (size_t)e->state_size) memset(e->state_init, 0, sizeof(float) * e->state_size);
}

void im_engine_reset(im_engine *e) {
    if (!e) return;
    for (int m = 0; m < e->nmodel; m++) {
        if (e->state[m][0]) memcpy(e->state[m][0], e->state_init, sizeof(float) * e->state_size);
        e->cur[m] = 0;
        e->silent[m] = 0;
    }
    for (int c = 0; c < e->channels; c++) {
        if (e->in_buf[c]) memset(e->in_buf[c], 0, sizeof(float) * e->hop);
        if (e->out_buf[c]) memset(e->out_buf[c], 0, sizeof(float) * e->hop);
        if (e->dry_buf[c]) memset(e->dry_buf[c], 0, sizeof(float) * e->dry_len);
    }
    e->fill = 0;
    e->dry_pos = 0;
    if (e->det) im_detector_reset(e->det);
    e->det_muted = 0;
    e->det_hold = 0;
}

static int alloc_buffers(im_engine *e) {
    e->state_init = calloc((size_t)e->state_size, sizeof(float));
    e->in_hop = calloc((size_t)e->hop, sizeof(float));
    e->out_hop = calloc((size_t)e->hop, sizeof(float));
    if (!e->state_init || !e->in_hop || !e->out_hop) return 0;
    for (int m = 0; m < e->nmodel; m++)
        for (int k = 0; k < 2; k++)
            if (!(e->state[m][k] = calloc((size_t)e->state_size, sizeof(float)))) return 0;
    e->dry_len = e->model_latency + e->hop;
    for (int c = 0; c < e->channels; c++) {
        e->in_buf[c] = calloc((size_t)e->hop, sizeof(float));
        e->out_buf[c] = calloc((size_t)e->hop, sizeof(float));
        e->dry_buf[c] = calloc((size_t)e->dry_len, sizeof(float));
        if (!e->in_buf[c] || !e->out_buf[c] || !e->dry_buf[c]) return 0;
    }
    return 1;
}

static int make_tensor(im_engine *e, float *data, int n, OrtValue **out) {
    int64_t shape[1] = {n};
    OrtStatus *st = e->api->CreateTensorWithDataAsOrtValue(e->mem, data, sizeof(float) * (size_t)n, shape, 1,
                                                          ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, out);
    if (st) { e->api->ReleaseStatus(st); return 0; }
    return 1;
}

int im_engine_create(const im_config *cfg, im_engine **out, char *err, size_t errlen) {
    im_engine *e = calloc(1, sizeof(*e));
    if (!e) { set_err(err, errlen, "out of memory", NULL); if (out) *out = NULL; return IM_ERR_MEM; }
    if (out) *out = e;
    e->failed = 1;
    e->enabled = 1;
    e->gate = e->gate_target = 1.0f;
    e->hop = 480; /* placeholder until the model loads, keeps failed mode well defined */
    e->channels = cfg && cfg->channels > 0 && cfg->channels <= IM_MAX_CH ? cfg->channels : 2;
    e->rate = cfg && cfg->sample_rate > 0 ? cfg->sample_rate : 48000;
    snprintf(e->model_name, sizeof e->model_name, "none");

    if (!cfg || !cfg->model_path) { set_err(err, errlen, "no model path", NULL); goto fail_buffers; }
    e->api = OrtGetApiBase()->GetApi(ORT_API_VERSION);
    if (!e->api) { set_err(err, errlen, "ONNX Runtime API version mismatch", NULL); goto fail_buffers; }
    const OrtApi *api = e->api;
    if (!ort_ok(api, api->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "islamic-mute", &e->env), err, errlen, "CreateEnv"))
        goto fail_buffers;
    OrtSessionOptions *so = NULL;
    if (!ort_ok(api, api->CreateSessionOptions(&so), err, errlen, "SessionOptions")) goto fail_buffers;
    {
        OrtStatus *o[4] = {api->SetIntraOpNumThreads(so, cfg->threads > 0 ? cfg->threads : 1),
                           api->SetInterOpNumThreads(so, 1), api->SetSessionExecutionMode(so, ORT_SEQUENTIAL),
                           api->SetSessionGraphOptimizationLevel(so, ORT_ENABLE_ALL)};
        for (int i = 0; i < 4; i++)
            if (o[i]) api->ReleaseStatus(o[i]);
    }
    OrtStatus *st = api->CreateSession(e->env, cfg->model_path, so, &e->sess);
    api->ReleaseSessionOptions(so);
    if (!ort_ok(api, st, err, errlen, "cannot load model")) goto fail_buffers;

    OrtAllocator *al = NULL;
    if (!ort_ok(api, api->GetAllocatorWithDefaultOptions(&al), err, errlen, "allocator")) goto fail_buffers;
    OrtModelMetadata *md = NULL;
    if (!ort_ok(api, api->SessionGetModelMetadata(e->sess, &md), err, errlen, "metadata")) goto fail_buffers;
    int contract = 0, rate = 0, hop = 0, ssz = 0, lat = 0;
    int ok = meta_int(e, md, al, "im.contract", &contract) && meta_int(e, md, al, "im.sample_rate", &rate) &&
             meta_int(e, md, al, "im.hop", &hop) && meta_int(e, md, al, "im.state_size", &ssz);
    meta_int(e, md, al, "im.latency_samples", &lat);
    meta_str(e, md, al, "im.model_name", e->model_name, sizeof e->model_name);
    api->ReleaseModelMetadata(md);
    if (!ok || contract != 1 || hop <= 0 || ssz < 0) {
        set_err(err, errlen, "model does not follow im.contract=1", NULL);
        goto fail_buffers;
    }
    if (rate != e->rate) {
        char d[96];
        snprintf(d, sizeof d, "model wants %d Hz, host gives %d Hz", rate, e->rate);
        set_err(err, errlen, "sample rate mismatch", d);
        e->hop = hop;
        goto fail_buffers;
    }
    e->hop = hop;
    e->state_size = ssz;
    e->model_latency = lat;
    e->mono_mix = cfg->mono_mix && e->channels > 1;
    e->nmodel = e->mono_mix ? 1 : e->channels;
    if (!alloc_buffers(e)) { set_err(err, errlen, "out of memory", NULL); goto fail_buffers; }
    load_state_init(e, cfg->model_path);

    if (!ort_ok(api, api->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &e->mem), err, errlen, "mem"))
        goto fail_buffers;
    if (!make_tensor(e, e->in_hop, hop, &e->v_in) || !make_tensor(e, e->out_hop, hop, &e->v_out)) goto fail_buffers;
    for (int m = 0; m < e->nmodel; m++)
        for (int k = 0; k < 2; k++)
            if (!make_tensor(e, e->state[m][k], ssz > 0 ? ssz : 1, &e->v_state[m][k])) goto fail_buffers;
    if (!ort_ok(api, api->CreateIoBinding(e->sess, &e->bind), err, errlen, "IoBinding")) goto fail_buffers;

    e->gate_coef = 1.0f - expf(-1.0f / (0.005f * (float)e->rate));
    if (cfg->detector_path && cfg->detector_path[0]) {
        e->det_requested = 1;
        e->det = im_detector_create(api, e->env, cfg->detector_path, e->rate, e->det_err, sizeof e->det_err);
        e->det_mono = calloc((size_t)hop, sizeof(float));
        if (!e->det_mono) { im_detector_destroy(e->det); e->det = NULL; }
    }
    e->failed = 0;
    im_engine_reset(e);
    if (err && errlen) err[0] = 0;
    return IM_OK;

fail_buffers:
    /* failed mode still needs buffers to emit silence with a stable delay */
    if (!e->in_buf[0]) {
        e->nmodel = 0;
        e->model_latency = 0;
        e->dry_len = e->hop;
        for (int c = 0; c < e->channels; c++) {
            e->in_buf[c] = calloc((size_t)e->hop, sizeof(float));
            e->out_buf[c] = calloc((size_t)e->hop, sizeof(float));
            e->dry_buf[c] = calloc((size_t)e->dry_len, sizeof(float));
        }
    }
    e->failed = 1;
    return IM_ERR_MODEL;
}

void im_engine_destroy(im_engine *e) {
    if (!e) return;
    const OrtApi *api = e->api;
    if (api) {
        if (e->bind) api->ReleaseIoBinding(e->bind);
        if (e->v_in) api->ReleaseValue(e->v_in);
        if (e->v_out) api->ReleaseValue(e->v_out);
        for (int m = 0; m < IM_MAX_CH; m++)
            for (int k = 0; k < 2; k++)
                if (e->v_state[m][k]) api->ReleaseValue(e->v_state[m][k]);
        if (e->mem) api->ReleaseMemoryInfo(e->mem);
        if (e->sess) api->ReleaseSession(e->sess);
        if (e->env) api->ReleaseEnv(e->env);
    }
    im_detector_destroy(e->det);
    free(e->det_mono);
    for (int m = 0; m < IM_MAX_CH; m++) { free(e->state[m][0]); free(e->state[m][1]); }
    for (int c = 0; c < IM_MAX_CH; c++) { free(e->in_buf[c]); free(e->out_buf[c]); free(e->dry_buf[c]); }
    free(e->state_init);
    free(e->in_hop);
    free(e->out_hop);
    free(e);
}

/* Runs one hop for model instance m: in_hop -> out_hop. Returns 0 on failure. */
static int run_model(im_engine *e, int m) {
    const OrtApi *api = e->api;
    int c = e->cur[m];
    OrtStatus *st;
    api->ClearBoundInputs(e->bind);
    api->ClearBoundOutputs(e->bind);
    if ((st = api->BindInput(e->bind, "audio_in", e->v_in))) goto bad;
    if ((st = api->BindInput(e->bind, "state_in", e->v_state[m][c]))) goto bad;
    if ((st = api->BindOutput(e->bind, "audio_out", e->v_out))) goto bad;
    if ((st = api->BindOutput(e->bind, "state_out", e->v_state[m][1 - c]))) goto bad;
    if ((st = api->RunWithBinding(e->sess, NULL, e->bind))) goto bad;
    e->cur[m] = 1 - c;
    for (int i = 0; i < e->hop; i++)
        if (!isfinite(e->out_hop[i])) return 0;
    return 1;
bad:
    api->ReleaseStatus(st);
    return 0;
}

static int hop_is_silent(const float *x, int n) {
    for (int i = 0; i < n; i++)
        if (x[i] > IM_SILENT_LEVEL || x[i] < -IM_SILENT_LEVEL) return 0;
    return 1;
}

/* Returns 1 if model instance m should run on in_hop, 0 if it is idle (output silence). */
static int should_run(im_engine *e, int m) {
    if (!hop_is_silent(e->in_hop, e->hop)) {
        e->silent[m] = 0;
        return 1;
    }
    if (e->silent[m] < IM_SILENT_HOPS) {
        if (++e->silent[m] == IM_SILENT_HOPS) {
            memcpy(e->state[m][0], e->state_init, sizeof(float) * e->state_size);
            e->cur[m] = 0;
            return 0;
        }
        return 1; /* keep running briefly so reverb tails and short pauses behave normally */
    }
    return 0;
}

static void detector_hop(im_engine *e);
static void process_hop_model(im_engine *e);

static void process_hop(im_engine *e) {
    process_hop_model(e);
    detector_hop(e);
}

/* Feeds the separated voice to the detector and updates the policy mute. */
static void detector_hop(im_engine *e) {
    const unsigned want = e->policy & (IM_POLICY_MUTE_FEMALE_SINGING | IM_POLICY_MUTE_FEMALE_VOICE);
    if (!want) { e->det_muted = 0; return; }
    if (!e->det || e->failed) {
        e->det_muted = (e->policy & IM_POLICY_FAIL_CLOSED) ? 1 : 0;
        return;
    }
    float g = 1.0f / (float)e->channels;
    for (int i = 0; i < e->hop; i++) {
        float s = 0;
        for (int c = 0; c < e->channels; c++) s += e->out_buf[c][i];
        e->det_mono[i] = s * g;
    }
    int r = im_detector_push(e->det, e->det_mono, e->hop);
    long release = (long)(im_detector_release_s(e->det) * (float)e->rate);
    if (r < 0) {
        e->det_errors++;
        if (e->policy & IM_POLICY_FAIL_CLOSED) { e->det_muted = 1; e->det_hold = release; }
    } else if (r > 0) {
        const float *p = im_detector_probs(e->det);
        float score = (want & IM_POLICY_MUTE_FEMALE_VOICE) ? p[IM_DET_FEMALE] : p[IM_DET_FEMALE] * p[IM_DET_SINGING];
        if (score >= im_detector_threshold(e->det)) { e->det_muted = 1; e->det_hold = release; }
    }
    if (e->det_muted) {
        e->det_hold -= e->hop;
        if (e->det_hold <= 0) { e->det_muted = 0; e->det_hold = 0; }
    }
}

static void process_hop_model(im_engine *e) {
    const int hop = e->hop;
    if (e->failed) {
        for (int c = 0; c < e->channels; c++) memset(e->out_buf[c], 0, sizeof(float) * hop);
        return;
    }
    if (e->mono_mix) {
        float g = 1.0f / (float)e->channels;
        for (int i = 0; i < hop; i++) {
            float s = 0;
            for (int c = 0; c < e->channels; c++) s += e->in_buf[c][i];
            e->in_hop[i] = s * g;
        }
        int active = should_run(e, 0);
        int ok = active ? run_model(e, 0) : 0;
        if (active && !ok) { e->run_errors++; im_engine_reset(e); }
        for (int c = 0; c < e->channels; c++) {
            if (ok) memcpy(e->out_buf[c], e->out_hop, sizeof(float) * hop);
            else memset(e->out_buf[c], 0, sizeof(float) * hop);
        }
        return;
    }
    for (int c = 0; c < e->channels; c++) {
        memcpy(e->in_hop, e->in_buf[c], sizeof(float) * hop);
        if (!should_run(e, c)) {
            memset(e->out_buf[c], 0, sizeof(float) * hop);
        } else if (run_model(e, c)) {
            memcpy(e->out_buf[c], e->out_hop, sizeof(float) * hop);
        } else {
            e->run_errors++;
            memset(e->out_buf[c], 0, sizeof(float) * hop);
            memcpy(e->state[c][0], e->state_init, sizeof(float) * e->state_size);
            e->cur[c] = 0;
        }
    }
}

/* Core loop: per sample, emit the matching sample of the previous hop's output,
 * so any host block size works and the added buffering delay is exactly one hop. */
static void process_core(im_engine *e, const float *const *in, float *const *out, int n, const float *iin,
                         float *iout) {
    const int ch = e->channels, hop = e->hop;
    for (int i = 0; i < n; i++) {
        float g;
        e->gate += ((e->det_muted && e->enabled ? 0.0f : e->gate_target) - e->gate) * e->gate_coef;
        g = e->gate;
        for (int c = 0; c < ch; c++) {
            float x = iin ? iin[(size_t)i * ch + c] : in[c][i];
            float y;
            if (e->enabled) {
                y = e->out_buf[c][e->fill];
            } else {
                /* dry path delayed by the same total latency */
                y = e->dry_buf[c][e->dry_pos];
            }
            e->dry_buf[c][e->dry_pos] = x;
            e->in_buf[c][e->fill] = x;
            y *= g;
            if (iout) iout[(size_t)i * ch + c] = y;
            else out[c][i] = y;
        }
        if (++e->dry_pos >= e->dry_len) e->dry_pos = 0;
        if (++e->fill == hop) {
            e->fill = 0;
            process_hop(e);
        }
    }
}

void im_engine_process(im_engine *e, const float *const *in, float *const *out, int nframes) {
    if (!e || nframes <= 0) return;
    process_core(e, in, out, nframes, NULL, NULL);
}

void im_engine_process_interleaved(im_engine *e, const float *in, float *out, int nframes) {
    if (!e || nframes <= 0) return;
    process_core(e, NULL, NULL, nframes, in, out);
}

/* Hop-aligned path: collect a whole hop, run it, return its output at once (no extra hop of buffering).
 * The dry path reads the shared delay line `hop` samples ahead, i.e. model_latency samples back. */
int im_engine_process_hops_interleaved(im_engine *e, const float *in, float *out, int nhops) {
    if (!e || nhops < 0) return -1;
    if (e->fill != 0) return -1;
    const int ch = e->channels, hop = e->hop;
    for (int k = 0; k < nhops; k++) {
        const float *x = in + (size_t)k * hop * ch;
        float *y = out + (size_t)k * hop * ch;
        float dry[IM_MAX_CH];
        int pos = e->dry_pos;
        for (int i = 0; i < hop; i++)
            for (int c = 0; c < ch; c++) e->in_buf[c][i] = x[(size_t)i * ch + c];
        process_hop(e);
        for (int i = 0; i < hop; i++) {
            e->gate += ((e->det_muted && e->enabled ? 0.0f : e->gate_target) - e->gate) * e->gate_coef;
            int rd = (pos + hop) % e->dry_len;
            for (int c = 0; c < ch; c++) {
                float xi = e->in_buf[c][i];
                dry[c] = e->model_latency > 0 ? e->dry_buf[c][rd] : xi;
                e->dry_buf[c][pos] = xi;
                y[(size_t)i * ch + c] = (e->enabled ? e->out_buf[c][i] : dry[c]) * e->gate;
            }
            if (++pos >= e->dry_len) pos = 0;
        }
        e->dry_pos = pos;
    }
    return 0;
}

int im_engine_latency(const im_engine *e) { return e ? e->model_latency + e->hop : 0; }
int im_engine_aligned_latency(const im_engine *e) { return e ? e->model_latency : 0; }
int im_engine_hop(const im_engine *e) { return e ? e->hop : 0; }
int im_engine_model_rate(const im_engine *e) { return e ? e->rate : 0; }
int im_engine_failed(const im_engine *e) { return e ? e->failed : 1; }
unsigned long im_engine_run_errors(const im_engine *e) { return e ? e->run_errors : 0; }
const char *im_engine_model_name(const im_engine *e) { return e ? e->model_name : ""; }
void im_engine_set_enabled(im_engine *e, int enabled) { if (e) e->enabled = enabled ? 1 : 0; }

int im_engine_set_mono(im_engine *e, int mono) {
    if (!e) return 0;
    mono = mono && e->channels > 1;
    /* one instance per channel exists only when the engine was created without mono_mix */
    if (e->failed || mono == e->mono_mix || (!mono && e->nmodel < e->channels)) return e->mono_mix;
    e->mono_mix = mono;
    /* same as a stream restart for the model (instance 0 now sees the mix); the audio buffers keep their place,
     * so the delay does not move */
    for (int m = 0; m < e->nmodel; m++) {
        if (e->state[m][0]) memcpy(e->state[m][0], e->state_init, sizeof(float) * e->state_size);
        e->cur[m] = 0;
        e->silent[m] = 0;
    }
    return e->mono_mix;
}
void im_engine_set_gate(im_engine *e, float gain) {
    if (!e) return;
    if (gain < 0) gain = 0;
    if (gain > 1) gain = 1;
    e->gate_target = gain;
}

void im_engine_set_policy(im_engine *e, unsigned policy) {
    if (!e) return;
    e->policy = policy;
    if (!(policy & (IM_POLICY_MUTE_FEMALE_SINGING | IM_POLICY_MUTE_FEMALE_VOICE))) e->det_muted = 0;
}
int im_engine_detector_status(const im_engine *e, float probs[4]) {
    if (!e || !e->det) {
        if (probs) memset(probs, 0, sizeof(float) * 4);
        return e && e->det_muted ? 1 : -1; /* fail-closed muting without a detector */
    }
    if (probs) memcpy(probs, im_detector_probs(e->det), sizeof(float) * 4);
    return e->det_muted;
}
const char *im_engine_detector_error(const im_engine *e) { return e ? e->det_err : ""; }
