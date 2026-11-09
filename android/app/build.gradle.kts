plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

val ortVersion = "1.19.2"
val ort: Configuration by configurations.creating

android {
    namespace = "org.islamicmute.app"
    compileSdk = 35
    ndkVersion = "27.1.12297006"

    defaultConfig {
        applicationId = "org.islamicmute.app"
        minSdk = 29          // AudioPlaybackCapture
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
        ndk { abiFilters += listOf("arm64-v8a", "x86_64") }
        externalNativeBuild { cmake { arguments += "-DORT_DIR=${layout.buildDirectory.get().asFile}/ort" } }
    }
    buildTypes {
        release { isMinifyEnabled = false }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    externalNativeBuild { cmake { path = file("src/main/cpp/CMakeLists.txt"); version = "3.22.1" } }
    packaging { jniLibs { useLegacyPackaging = true } }
    buildFeatures {
        aidl = true         // ISetupService: the Shizuku UserService interface
        buildConfig = true  // APPLICATION_ID / VERSION_CODE for the UserService
    }
}

dependencies {
    implementation("com.microsoft.onnxruntime:onnxruntime-android:$ortVersion")  // ships libonnxruntime.so (C API)
    ort("com.microsoft.onnxruntime:onnxruntime-android:$ortVersion@aar")
    implementation("androidx.media3:media3-exoplayer:1.5.1")
    implementation("androidx.media3:media3-ui:1.5.1")
    // Shizuku: one-tap setup (DUMP + PROJECT_MEDIA) without a computer. See ShizukuSetup.kt.
    val shizukuVersion = "13.1.5"
    implementation("dev.rikka.shizuku:api:$shizukuVersion")
    implementation("dev.rikka.shizuku:provider:$shizukuVersion")
}

// The engine links ONNX Runtime's C API: unpack headers and .so files from the AAR for CMake.
val extractOrt by tasks.registering(Copy::class) {
    from({ zipTree(ort.singleFile) }) {
        include("headers/**", "jni/**")
    }
    into(layout.buildDirectory.dir("ort"))
}
tasks.matching { it.name.startsWith("configureCMake") || it.name.startsWith("buildCMake") }.configureEach {
    dependsOn(extractOrt)
}

// Bundle the voice model: -PimModel=/path/model.onnx (default: the DeepFilterNet3 streaming export).
val modelAssets = layout.buildDirectory.dir("modelAssets")
val copyModel by tasks.registering(Copy::class) {
    val model = providers.gradleProperty("imModel").orElse(rootProject.file("../models/dfn3/dfn3_stream.onnx").path)
    from(model) { rename { "voice.onnx" } }
    from(model.map { it.removeSuffix(".onnx") + ".state_init.bin" }) { rename { "voice.state_init.bin" } }
    // Women's-singing detector: -PimDetector=/path/detector.onnx (default: models/detector/detector_v1.onnx if present).
    val detector = providers.gradleProperty("imDetector").orElse(rootProject.file("../models/detector/detector_v1.onnx").path)
    from(detector) { rename { "detector.onnx" } }
    into(modelAssets)
}
android.sourceSets["main"].assets.srcDir(modelAssets)
android.androidResources.noCompress += listOf("onnx", "bin")
tasks.named("preBuild") { dependsOn(copyModel) }
