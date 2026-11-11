/* JNI bridge: org.islamicmute.app.Vision <-> screen blur (engine/src/im_vision.c, im_cover.c). */
#include <android/log.h>
#include <jni.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "im_vision.h"

#define TAG "IslamicMute"
#define MAX_DETS 64
#define MAX_RECTS 256 /* covers per frame: outlined people are drawn as several strips (Vision.kt sizes its buffer the same) */

typedef struct {
    im_vision *v;
    im_cover *c;
} blur;

static const char *str(JNIEnv *env, jstring s) { return s ? (*env)->GetStringUTFChars(env, s, NULL) : NULL; }
static void unstr(JNIEnv *env, jstring s, const char *c) { if (s) (*env)->ReleaseStringUTFChars(env, s, c); }

JNIEXPORT jlong JNICALL Java_org_islamicmute_app_Vision_nativeCreate(JNIEnv *env, jclass cls, jstring person,
                                                                       jstring gender, jstring nsfw, jstring seg,
                                                                       jint threads, jint policy, jboolean coversVisible) {
    (void)cls;
    blur *b = calloc(1, sizeof *b);
    if (!b) return 0;
    const char *p = str(env, person), *g = str(env, gender), *n = str(env, nsfw), *sg = str(env, seg);
    im_vision_config cfg = {p, g, n, threads, (unsigned)policy, sg};
    char err[512] = {0};
    b->v = im_vision_create(&cfg, err, sizeof err);
    b->c = im_cover_create(coversVisible ? 1 : 0);
    unstr(env, person, p);
    unstr(env, gender, g);
    unstr(env, nsfw, n);
    unstr(env, seg, sg);
    if (err[0]) __android_log_print(ANDROID_LOG_ERROR, TAG, "blur models: %s", err);
    return (jlong)(intptr_t)b;
}

JNIEXPORT void JNICALL Java_org_islamicmute_app_Vision_nativeDestroy(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    blur *b = (blur *)(intptr_t)h;
    if (!b) return;
    im_vision_destroy(b->v);
    im_cover_destroy(b->c);
    free(b);
}

/* Bits of the policy the models cannot serve (0 = fine). */
JNIEXPORT jint JNICALL Java_org_islamicmute_app_Vision_nativeStatus(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    blur *b = (blur *)(intptr_t)h;
    return b && b->v && b->c ? (jint)im_vision_status(b->v) : -1;
}

JNIEXPORT jstring JNICALL Java_org_islamicmute_app_Vision_nativeError(JNIEnv *env, jclass cls, jlong h) {
    (void)cls;
    blur *b = (blur *)(intptr_t)h;
    return (*env)->NewStringUTF(env, b && b->v ? im_vision_error(b->v) : "out of memory");
}

JNIEXPORT void JNICALL Java_org_islamicmute_app_Vision_nativeSetCoversVisible(JNIEnv *env, jclass cls, jlong h,
                                                                                jboolean visible) {
    (void)env; (void)cls;
    blur *b = (blur *)(intptr_t)h;
    if (!b) return;
    im_cover_params p;
    im_cover_get_params(b->c, &p);
    im_cover_destroy(b->c);
    b->c = im_cover_create(visible ? 1 : 0);
    if (b->c) im_cover_set_params(b->c, &p);
}

/* Person-detector tiles run per frame on elongated frames: 0 = all every frame, n = n per frame taking turns. */
JNIEXPORT void JNICALL Java_org_islamicmute_app_Vision_nativeSetTilesPerFrame(JNIEnv *env, jclass cls, jlong h,
                                                                               jint n) {
    (void)env; (void)cls;
    blur *b = (blur *)(intptr_t)h;
    if (!b || !b->v) return;
    im_vision_params p;
    im_vision_get_params(b->v, &p);
    p.tiles_per_frame = n < 0 ? 0 : n;
    im_vision_set_params(b->v, &p);
}

/* Classifier threshold: a person is left uncovered only when p(man or boy) >= this (the user's strictness). */
JNIEXPORT void JNICALL Java_org_islamicmute_app_Vision_nativeSetMaleClear(JNIEnv *env, jclass cls, jlong h,
                                                                           jfloat t) {
    (void)env; (void)cls;
    blur *b = (blur *)(intptr_t)h;
    if (!b || !b->v || !(t > 0.5f && t <= 1.0f)) return; /* never below 0.5: that would clear people judged women */
    im_vision_params p;
    im_vision_get_params(b->v, &p);
    p.male_clear = t;
    im_vision_set_params(b->v, &p);
}

/* One captured frame (direct ByteBuffer, RGBA8888). models = run the person models, nsfw = also the nudity model.
 * out: float[max * 5] = x0, y0, x1, y1 (0..1), kind (| IM_VK_PART for a strip of an outlined person or a bridge). thumb: optional int[tw * th] ARGB, the frame shrunk by area
 * averaging (the overlay draws it enlarged as the blurred picture). Returns the rect count m, or -(m + 1) when the
 * models failed on this frame (the tracker still ran and the rects are still valid: held covers). */
JNIEXPORT jint JNICALL Java_org_islamicmute_app_Vision_nativeFrame(JNIEnv *env, jclass cls, jlong h, jobject buf,
                                                                     jint w, jint hh, jint stride, jdouble tMs,
                                                                     jboolean models, jboolean nsfw, jfloatArray out,
                                                                     jintArray thumb, jint tw, jint th) {
    (void)cls;
    blur *b = (blur *)(intptr_t)h;
    const uint8_t *px = buf ? (const uint8_t *)(*env)->GetDirectBufferAddress(env, buf) : NULL;
    if (!b || !b->v || !b->c || !px) return -1; /* = failed, no rects */
    im_vrect dets[MAX_DETS], rects[MAX_RECTS]; /* ~21 KB on the stack in all */
    im_vshape shapes[MAX_DETS];
    float tmp[MAX_RECTS * 5];
    int n = -1, failed = 0;
    if (models) {
        n = im_vision_detect_shapes(b->v, px, w, hh, stride, nsfw ? 1 : 0, dets, shapes, MAX_DETS);
        if (n < 0) failed = 1;
    }
    jint cap = (*env)->GetArrayLength(env, out) / 5;
    /* the tracker writes no more than the caller can take (it falls back to whole rectangles, never cuts an outline) */
    int m = im_cover_update_shapes(b->c, tMs, px, w, hh, stride, dets, shapes, n, rects,
                                   cap < MAX_RECTS ? (cap > 0 ? cap : 1) : MAX_RECTS);
    if (m > cap) m = cap;
    for (int i = 0; i < m; i++) {
        tmp[i * 5] = rects[i].x0; tmp[i * 5 + 1] = rects[i].y0;
        tmp[i * 5 + 2] = rects[i].x1; tmp[i * 5 + 3] = rects[i].y1;
        tmp[i * 5 + 4] = (float)rects[i].kind;
    }
    if (m > 0) (*env)->SetFloatArrayRegion(env, out, 0, m * 5, tmp);
    if (thumb && tw > 0 && th > 0 && (*env)->GetArrayLength(env, thumb) >= tw * th) {
        jint *t = malloc(sizeof(jint) * (size_t)tw * th);
        if (t) {
            for (int y = 0; y < th; y++) {
                int y0 = y * hh / th, y1 = (y + 1) * hh / th;
                if (y1 <= y0) y1 = y0 + 1;
                for (int x = 0; x < tw; x++) {
                    int x0 = x * w / tw, x1 = (x + 1) * w / tw;
                    if (x1 <= x0) x1 = x0 + 1;
                    unsigned r = 0, g = 0, bl = 0, cnt = 0;
                    /* every second pixel is plenty for a blur */
                    for (int yy = y0; yy < y1 && yy < hh; yy += 2)
                        for (int xx = x0; xx < x1 && xx < w; xx += 2) {
                            const uint8_t *q = px + (size_t)yy * stride + (size_t)xx * 4;
                            r += q[0]; g += q[1]; bl += q[2]; cnt++;
                        }
                    if (!cnt) cnt = 1;
                    t[y * tw + x] = (jint)(0xFF000000u | ((r / cnt) << 16) | ((g / cnt) << 8) | (bl / cnt));
                }
            }
            (*env)->SetIntArrayRegion(env, thumb, 0, tw * th, t);
            free(t);
        }
    }
    return failed ? -(m + 1) : m;
}
