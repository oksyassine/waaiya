# R8 keep rules for the release build (isMinifyEnabled). The default proguard-android-optimize.txt already keeps
# native method names; the rules below make the app's own requirements explicit.

# JNI: src/main/cpp/im_jni.c exports Java_org_waaiya_app_Engine_native*, bound by class and method name.
# The C side makes no calls back into Java (no FindClass / GetMethodID).
-keepclasseswithmembernames,includedescriptorclasses class org.waaiya.app.Engine {
    native <methods>;
}

# Shizuku UserService: Shizuku loads SetupService by class name from this APK in its own process and calls its
# constructor reflectively (ShizukuSetup.grant passes SetupService::class.java.name). Nothing in the app calls
# the constructor, so without this R8 would remove the class.
-keep class org.waaiya.app.SetupService {
    <init>(...);
    public *;
}
# AIDL interface of that service (ISetupService.aidl): the Stub runs in the Shizuku process, the Proxy in ours.
-keep class org.waaiya.app.ISetupService { *; }
-keep class org.waaiya.app.ISetupService$** { *; }

# Reflection: SessionMuter reaches android.os.ServiceManager (a framework class, nothing to keep in the APK).
# ONNX Runtime's Java API (ai.onnxruntime.*) is unused and may be removed; only libonnxruntime.so is loaded.

# Screen blur JNI: src/main/cpp/vision_jni.c exports Java_org_waaiya_app_Vision_native*.
-keepclasseswithmembernames,includedescriptorclasses class org.waaiya.app.Vision {
    native <methods>;
}

# Screen-blur covers drawn by the shell: Shizuku instantiates CoverService by class name in its own process.
-keep class org.waaiya.app.CoverService {
    <init>(...);
    public *;
}
-keep class org.waaiya.app.ICoverService { *; }
-keep class org.waaiya.app.ICoverService$** { *; }

# Waaiya's own cover helper: started by class name with app_process (CoverHelper.startCommand), so nothing in the
# app calls its main. CoverHelperProvider is declared in the manifest (kept by aapt's rules).
-keep class org.waaiya.app.CoverHelper {
    public static void main(java.lang.String[]);
}
