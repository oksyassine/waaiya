# R8 keep rules for the release build (isMinifyEnabled). The default proguard-android-optimize.txt already keeps
# native method names; the rules below make the app's own requirements explicit.

# JNI: src/main/cpp/im_jni.c exports Java_org_islamicmute_app_Engine_native*, bound by class and method name.
# The C side makes no calls back into Java (no FindClass / GetMethodID).
-keepclasseswithmembernames,includedescriptorclasses class org.islamicmute.app.Engine {
    native <methods>;
}

# Shizuku UserService: Shizuku loads SetupService by class name from this APK in its own process and calls its
# constructor reflectively (ShizukuSetup.grant passes SetupService::class.java.name). Nothing in the app calls
# the constructor, so without this R8 would remove the class.
-keep class org.islamicmute.app.SetupService {
    <init>(...);
    public *;
}
# AIDL interface of that service (ISetupService.aidl): the Stub runs in the Shizuku process, the Proxy in ours.
-keep class org.islamicmute.app.ISetupService { *; }
-keep class org.islamicmute.app.ISetupService$** { *; }

# Reflection: SessionMuter reaches android.os.ServiceManager (a framework class, nothing to keep in the APK).
# ONNX Runtime's Java API (ai.onnxruntime.*) is unused and may be removed; only libonnxruntime.so is loaded.
