/* JNI for AppUpdatePatch.apply (Kotlin): returns null on success, else the reason. */
#include <jni.h>
#include "zpatch.h"

JNIEXPORT jstring JNICALL
Java_org_islamicmute_app_AppUpdatePatch_nativeApply(JNIEnv *env, jclass cls, jstring old_path, jstring patch_path,
                                                     jstring out_path, jlong out_size) {
    (void)cls;
    const char *o = (*env)->GetStringUTFChars(env, old_path, NULL);
    const char *p = (*env)->GetStringUTFChars(env, patch_path, NULL);
    const char *n = (*env)->GetStringUTFChars(env, out_path, NULL);
    char err[256] = {0};
    int rc = (o && p && n) ? zpatch_apply(o, p, n, (long long)out_size, err, sizeof err) : -1;
    if (o) (*env)->ReleaseStringUTFChars(env, old_path, o);
    if (p) (*env)->ReleaseStringUTFChars(env, patch_path, p);
    if (n) (*env)->ReleaseStringUTFChars(env, out_path, n);
    if (rc == 0) return NULL;
    return (*env)->NewStringUTF(env, err[0] ? err : "out of memory");
}
