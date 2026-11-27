/* JNI bridge: org.waaiya.app.CaptionsNative <-> engine/src/im_captions.c (live captions, docs/CAPTIONS.md). */
#include <android/log.h>
#include <jni.h>
#include <stdint.h>
#include "im_captions.h"

#define TAG "IslamicMute"
#define K(h) ((im_captions *)(intptr_t)(h))

JNIEXPORT jlong JNICALL Java_org_waaiya_app_CaptionsNative_nativeCreate(JNIEnv *env, jclass cls, jstring path,
                                                                       jint rate, jint threads) {
    (void)cls;
    const char *p = (*env)->GetStringUTFChars(env, path, NULL);
    char err[512] = {0};
    im_captions_config cfg;
    im_captions_default_config(&cfg);
    cfg.in_rate = rate;
    im_captions *k = im_captions_create_asr(&cfg, p, threads, err, sizeof err);
    (*env)->ReleaseStringUTFChars(env, path, p);
    if (!k) __android_log_print(ANDROID_LOG_ERROR, TAG, "captions: %s", err);
    return (jlong)(intptr_t)k;
}

JNIEXPORT jint JNICALL Java_org_waaiya_app_CaptionsNative_nativePush(JNIEnv *env, jclass cls, jlong h, jfloatArray x,
                                                                    jint n) {
    (void)cls;
    if (!h || n <= 0) return 0;
    if (n > (*env)->GetArrayLength(env, x)) return -1;
    jfloat *p = (*env)->GetFloatArrayElements(env, x, NULL);
    int r = im_captions_push(K(h), p, n);
    (*env)->ReleaseFloatArrayElements(env, x, p, JNI_ABORT);
    return r;
}

JNIEXPORT jint JNICALL Java_org_waaiya_app_CaptionsNative_nativeFlush(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    return h ? im_captions_flush(K(h)) : 0;
}

JNIEXPORT void JNICALL Java_org_waaiya_app_CaptionsNative_nativeReset(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    if (h) im_captions_reset(K(h));
}

static jstring utf(JNIEnv *env, const char *s) {
    /* NewStringUTF wants modified UTF-8; the engine's text is plain UTF-8, which differs only above U+FFFF (never in
     * Arabic captions). Characters above it are dropped rather than handed over malformed. */
    char buf[4096];
    size_t j = 0;
    for (size_t i = 0; s[i] && j + 4 < sizeof buf;) {
        unsigned char c = (unsigned char)s[i];
        if (c >= 0xF0) { i++; while ((s[i] & 0xC0) == 0x80) i++; continue; }
        buf[j++] = s[i++];
    }
    buf[j] = 0;
    return (*env)->NewStringUTF(env, buf);
}

JNIEXPORT jstring JNICALL Java_org_waaiya_app_CaptionsNative_nativePartial(JNIEnv *env, jclass cls, jlong h) {
    (void)cls;
    return utf(env, h ? im_captions_partial(K(h)) : "");
}

/* The oldest finished line not yet taken, or null when there is none. */
JNIEXPORT jstring JNICALL Java_org_waaiya_app_CaptionsNative_nativeTakeFinal(JNIEnv *env, jclass cls, jlong h) {
    (void)cls;
    char line[4096];
    if (!h || im_captions_take_final(K(h), line, sizeof line) <= 0) return NULL;
    return utf(env, line);
}

JNIEXPORT jboolean JNICALL Java_org_waaiya_app_CaptionsNative_nativeSpeaking(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    return h && im_captions_speaking(K(h)) ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jfloat JNICALL Java_org_waaiya_app_CaptionsNative_nativeLevelDb(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    return h ? im_captions_level_db(K(h)) : -120.0f;
}

/* Time of the last recognition in ms, and the seconds of audio it read. */
JNIEXPORT jfloat JNICALL Java_org_waaiya_app_CaptionsNative_nativeLastMs(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    return h ? (jfloat)im_captions_last_ms(K(h)) : 0.0f;
}

JNIEXPORT jfloat JNICALL Java_org_waaiya_app_CaptionsNative_nativeLastAudioS(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    return h ? (jfloat)im_captions_last_audio_s(K(h)) : 0.0f;
}

JNIEXPORT void JNICALL Java_org_waaiya_app_CaptionsNative_nativeDestroy(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    if (h) im_captions_destroy(K(h));
}
