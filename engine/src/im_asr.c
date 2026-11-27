/* Speech to text with an ASR-contract model (im_captions.h): one ONNX Runtime run per piece of audio, then greedy
 * CTC decoding. */
#include "im_captions.h"
#include "im_ctc.h"
#include "im_path.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_TOKENS 65536

struct im_asr {
    const OrtApi *api;
    OrtEnv *env;
    OrtSession *sess;
    OrtMemoryInfo *mem;
    int rate, blank, ntok;
    char **tokens;          /* [ntok] */
    char *token_text;       /* storage of the tokens */
    char name[128];
};

static int meta(const OrtApi *api, OrtModelMetadata *md, OrtAllocator *al, const char *key, char **val) {
    *val = NULL;
    OrtStatus *st = api->ModelMetadataLookupCustomMetadataMap(md, al, key, val);
    if (st) { api->ReleaseStatus(st); return 0; }
    return *val != NULL;
}

static void meta_free(const OrtApi *api, OrtAllocator *al, char *v) {
    if (!v) return;
    OrtStatus *st = api->AllocatorFree(al, v);
    if (st) api->ReleaseStatus(st);
}

#define FAIL(...) do { if (err) snprintf(err, errlen, __VA_ARGS__); goto fail; } while (0)
#define ORT(call, what) do { OrtStatus *s_ = (call); if (s_) { if (err) snprintf(err, errlen, "asr: %s: %s", what, \
    a->api->GetErrorMessage(s_)); a->api->ReleaseStatus(s_); goto fail; } } while (0)

im_asr *im_asr_create(const char *path, int threads, char *err, size_t errlen) {
    im_asr *a = calloc(1, sizeof(*a));
    OrtSessionOptions *so = NULL;
    OrtModelMetadata *md = NULL;
    OrtAllocator *al = NULL;
    char *v = NULL;
    if (!a) return NULL;
    a->api = OrtGetApiBase()->GetApi(ORT_API_VERSION);
    if (!a->api) FAIL("asr: ONNX Runtime API %d not available", ORT_API_VERSION);
    ORT(a->api->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "waaiya-asr", &a->env), "CreateEnv");
    ORT(a->api->CreateSessionOptions(&so), "CreateSessionOptions");
    if (threads > 0) ORT(a->api->SetIntraOpNumThreads(so, threads), "SetIntraOpNumThreads");
    ORT(a->api->SetInterOpNumThreads(so, 1), "SetInterOpNumThreads");
    ORT(a->api->SetSessionGraphOptimizationLevel(so, ORT_ENABLE_ALL), "SetSessionGraphOptimizationLevel");
    ORT(im_create_session(a->api, a->env, path, so, &a->sess), "CreateSession");
    ORT(a->api->GetAllocatorWithDefaultOptions(&al), "GetAllocator");
    ORT(a->api->SessionGetModelMetadata(a->sess, &md), "GetModelMetadata");

    if (!meta(a->api, md, al, "asr.contract", &v) || strcmp(v, "1") != 0) FAIL("asr: not an asr.contract=1 model");
    meta_free(a->api, al, v), v = NULL;
    if (!meta(a->api, md, al, "asr.sample_rate", &v)) FAIL("asr: no asr.sample_rate");
    a->rate = atoi(v);
    meta_free(a->api, al, v), v = NULL;
    if (a->rate != 16000) FAIL("asr: sample rate %d (16000 expected)", a->rate);
    if (!meta(a->api, md, al, "asr.blank", &v)) FAIL("asr: no asr.blank");
    a->blank = atoi(v);
    meta_free(a->api, al, v), v = NULL;
    if (meta(a->api, md, al, "asr.model_name", &v)) snprintf(a->name, sizeof a->name, "%s", v);
    else snprintf(a->name, sizeof a->name, "asr");
    meta_free(a->api, al, v), v = NULL;
    if (!meta(a->api, md, al, "asr.tokens", &v)) FAIL("asr: no asr.tokens");
    a->token_text = strdup(v);
    meta_free(a->api, al, v), v = NULL;
    if (!a->token_text) FAIL("asr: out of memory");
    /* one token per line; an empty line is an empty token (kept, so that indices stay right) */
    int n = 1;
    for (const char *p = a->token_text; *p; p++) n += *p == '\n';
    if (n > MAX_TOKENS) FAIL("asr: %d tokens", n);
    a->tokens = calloc((size_t)n, sizeof(char *));
    if (!a->tokens) FAIL("asr: out of memory");
    char *p = a->token_text;
    for (int i = 0; i < n; i++) {
        a->tokens[i] = p;
        char *nl = strchr(p, '\n');
        if (nl) { *nl = 0; p = nl + 1; } else p += strlen(p);
    }
    a->ntok = n;
    /* a trailing newline makes one empty last token too many */
    if (a->ntok > 1 && a->tokens[a->ntok - 1][0] == 0) a->ntok--;
    if (a->blank < 0 || a->blank >= a->ntok) FAIL("asr: blank %d outside %d tokens", a->blank, a->ntok);
    ORT(a->api->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &a->mem), "CreateCpuMemoryInfo");
    a->api->ReleaseModelMetadata(md);
    a->api->ReleaseSessionOptions(so);
    return a;
fail:
    if (v && al) meta_free(a->api, al, v);
    if (md) a->api->ReleaseModelMetadata(md);
    if (so) a->api->ReleaseSessionOptions(so);
    im_asr_destroy(a);
    return NULL;
}

void im_asr_destroy(im_asr *a) {
    if (!a) return;
    if (a->api) {
        if (a->mem) a->api->ReleaseMemoryInfo(a->mem);
        if (a->sess) a->api->ReleaseSession(a->sess);
        if (a->env) a->api->ReleaseEnv(a->env);
    }
    free(a->tokens);
    free(a->token_text);
    free(a);
}

int im_asr_sample_rate(const im_asr *a) { return a ? a->rate : 0; }
const char *im_asr_model_name(const im_asr *a) { return a ? a->name : ""; }

int im_asr_transcribe(im_asr *a, const float *x, int n, char *out, size_t cap) {
    if (!out || cap == 0) return -1;
    out[0] = 0;
    if (!a) return -1;
    if (n < a->rate / 10) return 0;   /* under 0.1 s: nothing to say (and a model may refuse so few frames) */
    const OrtApi *api = a->api;
    int64_t shape[2] = {1, n};
    OrtValue *in = NULL, *res = NULL;
    OrtTensorTypeAndShapeInfo *info = NULL;
    int r = -1;
    OrtStatus *st = api->CreateTensorWithDataAsOrtValue(a->mem, (void *)x, sizeof(float) * (size_t)n, shape, 2,
                                                        ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, &in);
    if (st) goto done;
    const char *in_names[] = {"audio"}, *out_names[] = {"logits"};
    if ((st = api->Run(a->sess, NULL, in_names, (const OrtValue *const *)&in, 1, out_names, 1, &res))) goto done;
    if ((st = api->GetTensorTypeAndShape(res, &info))) goto done;
    size_t dims = 0;
    if ((st = api->GetDimensionsCount(info, &dims))) goto done;
    if (dims != 3) goto done;
    int64_t d[3];
    if ((st = api->GetDimensions(info, d, 3))) goto done;
    if (d[0] != 1 || d[2] != a->ntok || d[1] < 0) goto done;
    float *logits = NULL;
    if ((st = api->GetTensorMutableData(res, (void **)&logits))) goto done;
    r = im_ctc_decode(logits, (int)d[1], a->ntok, a->blank, (const char *const *)a->tokens, out, cap);
done:
    if (st) {
        fprintf(stderr, "asr: %s\n", api->GetErrorMessage(st));
        api->ReleaseStatus(st);
        r = -1;
    }
    if (info) api->ReleaseTensorTypeAndShapeInfo(info);
    if (res) api->ReleaseValue(res);
    if (in) api->ReleaseValue(in);
    if (r < 0) out[0] = 0;
    return r;
}
