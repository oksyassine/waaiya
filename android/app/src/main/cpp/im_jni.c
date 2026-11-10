/* JNI bridge: org.islamicmute.app.Engine <-> C engine (same code as desktop). */
#include <stdlib.h>
#include <android/log.h>
#include <jni.h>
#include <stdint.h>
#include "im_engine.h"

#define TAG "IslamicMute"

JNIEXPORT jlong JNICALL Java_org_islamicmute_app_Engine_nativeCreate(JNIEnv *env, jclass cls, jstring path,
                                                                       jstring detector, jint channels, jint rate,
                                                                       jboolean mono, jint policy) {
    (void)cls;
    const char *p = (*env)->GetStringUTFChars(env, path, NULL);
    const char *d = detector ? (*env)->GetStringUTFChars(env, detector, NULL) : NULL;
    char err[512] = {0};
    im_config cfg = {p, channels, rate, 1, mono ? 1 : 0, d};
    im_engine *e = NULL;
    if (im_engine_create(&cfg, &e, err, sizeof err) != IM_OK)
        __android_log_print(ANDROID_LOG_ERROR, TAG, "engine: %s -> output muted (fail-closed)", err);
    else
        __android_log_print(ANDROID_LOG_INFO, TAG, "engine: %s, latency %d", im_engine_model_name(e), im_engine_latency(e));
    if (d && im_engine_detector_status(e, NULL) < 0)
        __android_log_print(ANDROID_LOG_ERROR, TAG, "%s", im_engine_detector_error(e));
    im_engine_set_policy(e, (unsigned)policy);
    if (d) (*env)->ReleaseStringUTFChars(env, detector, d);
    (*env)->ReleaseStringUTFChars(env, path, p);
    return (jlong)(intptr_t)e;
}

JNIEXPORT void JNICALL Java_org_islamicmute_app_Engine_nativeSetPolicy(JNIEnv *env, jclass cls, jlong h, jint policy) {
    (void)env; (void)cls;
    im_engine_set_policy((im_engine *)(intptr_t)h, (unsigned)policy);
}

/* probs: float[4] (female, speech, singing, recitation). Returns 1 muting, 0 not, -1 no detector. */
JNIEXPORT jint JNICALL Java_org_islamicmute_app_Engine_nativeDetectorStatus(JNIEnv *env, jclass cls, jlong h,
                                                                             jfloatArray probs) {
    (void)cls;
    float p[4];
    int r = im_engine_detector_status((im_engine *)(intptr_t)h, p);
    if (probs && (*env)->GetArrayLength(env, probs) >= 4) (*env)->SetFloatArrayRegion(env, probs, 0, 4, p);
    return r;
}

JNIEXPORT void JNICALL Java_org_islamicmute_app_Engine_nativeProcess(JNIEnv *env, jclass cls, jlong h, jfloatArray in,
                                                                      jfloatArray out, jint frames) {
    (void)cls;
    jfloat *pi = (*env)->GetPrimitiveArrayCritical(env, in, NULL);
    jfloat *po = (*env)->GetPrimitiveArrayCritical(env, out, NULL);
    im_engine_process_interleaved((im_engine *)(intptr_t)h, pi, po, frames);
    (*env)->ReleasePrimitiveArrayCritical(env, out, po, 0);
    (*env)->ReleasePrimitiveArrayCritical(env, in, pi, JNI_ABORT);
}

/* Hop-aligned: in/out hold hops * hop frames; one hop less delay than nativeProcess. Returns 0 or -1. */
JNIEXPORT jint JNICALL Java_org_islamicmute_app_Engine_nativeProcessHops(JNIEnv *env, jclass cls, jlong h, jfloatArray in,
                                                                         jfloatArray out, jint hops) {
    (void)cls;
    /* copies instead of GetPrimitiveArrayCritical: the engine run (several ms) must not hold the GC lock
     * ("JNI critical lock held for 16-26 ms" on a Galaxy S24), and a hop is only a few KB */
    im_engine *e = (im_engine *)(intptr_t)h;
    jsize n = (*env)->GetArrayLength(env, in);
    if (hops <= 0 || n != (*env)->GetArrayLength(env, out) || n < hops * im_engine_hop(e)) return -1;
    float stack[2 * 480 * 2];
    float *buf = (size_t)n <= sizeof stack / sizeof *stack ? stack : malloc((size_t)n * sizeof *buf);
    if (!buf) return -1;
    (*env)->GetFloatArrayRegion(env, in, 0, n, buf);
    int r = im_engine_process_hops_interleaved(e, buf, buf, hops); /* in-place is allowed */
    if (r == 0) (*env)->SetFloatArrayRegion(env, out, 0, n, buf);
    if (buf != stack) free(buf);
    return r;
}

JNIEXPORT jint JNICALL Java_org_islamicmute_app_Engine_nativeAlignedLatency(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    return im_engine_aligned_latency((im_engine *)(intptr_t)h);
}

JNIEXPORT jint JNICALL Java_org_islamicmute_app_Engine_nativeLatency(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    return im_engine_latency((im_engine *)(intptr_t)h);
}

JNIEXPORT jboolean JNICALL Java_org_islamicmute_app_Engine_nativeFailed(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    return im_engine_failed((im_engine *)(intptr_t)h) ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT void JNICALL Java_org_islamicmute_app_Engine_nativeSetGate(JNIEnv *env, jclass cls, jlong h, jfloat g) {
    (void)env; (void)cls;
    im_engine_set_gate((im_engine *)(intptr_t)h, g);
}

JNIEXPORT void JNICALL Java_org_islamicmute_app_Engine_nativeReset(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    im_engine_reset((im_engine *)(intptr_t)h);
}

JNIEXPORT void JNICALL Java_org_islamicmute_app_Engine_nativeDestroy(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    im_engine_destroy((im_engine *)(intptr_t)h);
}
