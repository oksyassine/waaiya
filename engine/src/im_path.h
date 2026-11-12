/* File paths are UTF-8 everywhere in the engine. On Windows, ONNX Runtime takes wide (UTF-16) paths and fopen
 * takes the ANSI code page, so a model under a user folder with Arabic letters would not open: these two helpers
 * convert. Elsewhere they are the plain calls. */
#ifndef IM_PATH_H
#define IM_PATH_H

#include <stdio.h>
#include <stdlib.h>

#include "onnxruntime_c_api.h"

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

/* malloc'ed UTF-16 copy of a UTF-8 string, NULL on failure */
static inline wchar_t *im_widen(const char *s) {
    int n = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, s, -1, NULL, 0);
    if (n <= 0) return NULL;
    wchar_t *w = (wchar_t *)malloc(sizeof(wchar_t) * (size_t)n);
    if (w && MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, s, -1, w, n) != n) {
        free(w);
        w = NULL;
    }
    return w;
}
#endif

static inline FILE *im_fopen(const char *path, const char *mode) {
#ifdef _WIN32
    wchar_t *wp = im_widen(path), *wm = im_widen(mode);
    FILE *f = wp && wm ? _wfopen(wp, wm) : NULL;
    free(wp);
    free(wm);
    return f;
#else
    return fopen(path, mode);
#endif
}

static inline OrtStatus *im_create_session(const OrtApi *api, OrtEnv *env, const char *path,
                                           const OrtSessionOptions *so, OrtSession **out) {
#ifdef _WIN32
    wchar_t *wp = im_widen(path);
    if (!wp) return api->CreateStatus(ORT_INVALID_ARGUMENT, "model path is not valid UTF-8");
    OrtStatus *st = api->CreateSession(env, wp, so, out);
    free(wp);
    return st;
#else
    return api->CreateSession(env, path, so, out);
#endif
}

#endif
