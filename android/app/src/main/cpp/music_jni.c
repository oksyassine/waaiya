/* JNI bridge: org.waaiya.app.MusicScan <-> engine/src/im_music.c ("Check for music", docs/MUSIC_CHECK.md). */
#include <android/log.h>
#include <jni.h>
#include <stdint.h>
#include "im_music.h"

#define TAG "IslamicMute"

JNIEXPORT jlong JNICALL Java_org_waaiya_app_MusicScan_nativeCreate(JNIEnv *env, jclass cls, jstring path, jint rate) {
    (void)cls;
    const char *p = (*env)->GetStringUTFChars(env, path, NULL);
    char err[512] = {0};
    im_music *m = im_music_create(p, rate, err, sizeof err);
    (*env)->ReleaseStringUTFChars(env, path, p);
    if (!m) __android_log_print(ANDROID_LOG_ERROR, TAG, "music check: %s", err);
    return (jlong)(intptr_t)m;
}

JNIEXPORT jint JNICALL Java_org_waaiya_app_MusicScan_nativeClasses(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    return im_music_classes((im_music *)(intptr_t)h);
}

JNIEXPORT jint JNICALL Java_org_waaiya_app_MusicScan_nativePush(JNIEnv *env, jclass cls, jlong h, jfloatArray x, jint n) {
    (void)cls;
    if (n <= 0) return 0;
    if (n > (*env)->GetArrayLength(env, x)) return -1;
    jfloat *p = (*env)->GetFloatArrayElements(env, x, NULL);
    int r = im_music_push((im_music *)(intptr_t)h, p, n);
    (*env)->ReleaseFloatArrayElements(env, x, p, JNI_ABORT);
    return r;
}

JNIEXPORT jint JNICALL Java_org_waaiya_app_MusicScan_nativeFinish(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    return im_music_finish((im_music *)(intptr_t)h);
}

/* probs: max * classes floats, levels: max floats. Returns the windows taken. */
JNIEXPORT jint JNICALL Java_org_waaiya_app_MusicScan_nativeTake(JNIEnv *env, jclass cls, jlong h, jfloatArray probs,
                                                                 jfloatArray levels, jint max) {
    (void)cls;
    im_music *m = (im_music *)(intptr_t)h;
    int c = im_music_classes(m);
    if (max <= 0 || (*env)->GetArrayLength(env, probs) < (jsize)max * c || (*env)->GetArrayLength(env, levels) < max) return 0;
    jfloat *p = (*env)->GetFloatArrayElements(env, probs, NULL);
    jfloat *l = (*env)->GetFloatArrayElements(env, levels, NULL);
    int k = im_music_take(m, p, l, max);
    (*env)->ReleaseFloatArrayElements(env, probs, p, 0);
    (*env)->ReleaseFloatArrayElements(env, levels, l, 0);
    return k;
}

JNIEXPORT void JNICALL Java_org_waaiya_app_MusicScan_nativeDestroy(JNIEnv *env, jclass cls, jlong h) {
    (void)env; (void)cls;
    im_music_destroy((im_music *)(intptr_t)h);
}
