/* JNI bridge: org.islamicmute.app.Engine <-> C engine (same code as desktop). */
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
