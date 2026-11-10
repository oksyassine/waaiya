import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.chaquo.python")
}

val ortVersion = "1.19.2"
// yt-dlp bundled in the APK. The app updates itself from PyPI at run time (src/main/python/im_update.py);
// this is the floor it starts from.
val ytDlpVersion = "2026.10.26"
val ytDlpEjsVersion = "0.8.0"
val ort: Configuration by configurations.creating
val releaseAbis = listOf("arm64-v8a", "armeabi-v7a")
val abiSplit = providers.gradleProperty("imAbiSplit").map { it != "false" }.getOrElse(false)

// Release signing: a keystore.properties (storeFile, storePassword, keyAlias, keyPassword) outside the repo,
// by default ~/.config/islamic-mute-signing/keystore.properties, or -PimSigning=/path/keystore.properties.
// Without it, assembleRelease writes app-release-unsigned.apk. Keep the key safe: updates need the same key.
val signingProps = Properties().apply {
    val f = file(providers.gradleProperty("imSigning").getOrElse(
        System.getProperty("user.home") + "/.config/islamic-mute-signing/keystore.properties"))
    if (f.isFile) f.inputStream().use { load(it) }
}

// Screen blur: declare the accessibility service only on request (Play Protect blocks sideloaded apps that have one).
val blurA11y = providers.gradleProperty("imBlurA11y").isPresent

android {
    namespace = "org.islamicmute.app"
    compileSdk = 35
    ndkVersion = "27.1.12297006"

    defaultConfig {
        applicationId = "org.islamicmute.app"
        minSdk = 29          // AudioPlaybackCapture
        targetSdk = 35
        versionCode = 5
        versionName = "0.2.3"
        buildConfigField("String", "YTDLP_VERSION", "\"$ytDlpVersion\"")
        buildConfigField("boolean", "BLUR_A11Y", blurA11y.toString())
        if (blurA11y) versionNameSuffix = "-a11y"
        externalNativeBuild { cmake { arguments += "-DORT_DIR=${layout.buildDirectory.get().asFile}/ort" } }
        // Phones: 64- and 32-bit ARM (armeabi-v7a limits Chaquopy to Python <= 3.11). Chaquopy reads the ABIs here,
        // not per build type, so emulator builds add x86_64 with -PimX86.
        ndk { abiFilters += releaseAbis + (if (providers.gradleProperty("imX86").isPresent) listOf("x86_64") else emptyList()) }
    }
    if (!signingProps.isEmpty) signingConfigs.create("release") {
        storeFile = file(signingProps.getProperty("storeFile"))
        storePassword = signingProps.getProperty("storePassword")
        keyAlias = signingProps.getProperty("keyAlias")
        keyPassword = signingProps.getProperty("keyPassword")
    }
    buildTypes {
        debug {}
        release {
            // Phones only (32- and 64-bit ARM). Also limits the universal APK when -PimAbiSplit is set.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.findByName("release")  // null (unsigned APK) without keystore.properties
        }
    }
    // `./gradlew assembleRelease -PimAbiSplit`: one APK per ABI plus the universal one (about 10 MB instead of
    // 16 MB per download). Meant for release builds. Per-ABI versionCodes are not set here; add them before
    // publishing split APKs to a store that needs distinct codes (F-Droid, Play with multiple APKs).
    splits {
        abi {
            isEnable = abiSplit
            reset()
            include(*releaseAbis.toTypedArray())
            isUniversalApk = true
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    externalNativeBuild { cmake { path = file("src/main/cpp/CMakeLists.txt"); version = "3.22.1" } }
    packaging {
        jniLibs {
            useLegacyPackaging = true
            // ONNX Runtime's Java binding: unused (the engine calls the C API in libonnxruntime.so directly).
            excludes += "**/libonnxruntime4j_jni.so"
        }
    }
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
    implementation("androidx.media3:media3-transformer:1.5.1")  // "Save without music": filter audio, copy video
    // Shizuku: one-tap setup (DUMP + PROJECT_MEDIA) without a computer. See ShizukuSetup.kt.
    val shizukuVersion = "13.1.5"
    implementation("dev.rikka.shizuku:api:$shizukuVersion")
    implementation("dev.rikka.shizuku:provider:$shizukuVersion")
    // Screen blur: sets the hidden "skip screenshot" flag on our overlay so the screen capture shows what is under it.
    implementation("org.lsposed.hiddenapibypass:hiddenapibypass:4.3")
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

// Bundle the voice model: -PimModel=/path/model.onnx (default: the int8 DeepFilterNet3 streaming export).
val modelAssets = layout.buildDirectory.dir("modelAssets")
val copyModel by tasks.registering(Copy::class) {
    val model = providers.gradleProperty("imModel").orElse(rootProject.file("../models/dfn3/dfn3_stream_int8.onnx").path)
    from(model) { rename { "voice.onnx" } }
    from(model.map { it.removeSuffix(".onnx") + ".state_init.bin" }) { rename { "voice.state_init.bin" } }
    // Women's-singing detector: -PimDetector=/path/detector.onnx (default: models/detector/detector_v1.onnx if present).
    val detector = providers.gradleProperty("imDetector").orElse(rootProject.file("../models/detector/detector_v1.onnx").path)
    from(detector) { rename { "detector.onnx" } }
    // Screen blur (models/vision/export_vision.py): person detector, woman/man classifier, nudity classifier.
    // -PimBlurPerson / -PimBlurGender / -PimBlurNsfw override; a missing file just leaves that part out
    // (no gender model = every person covered; no nudity model = the nudity option reports "not available").
    val vision = rootProject.file("../models/vision")
    from(providers.gradleProperty("imBlurPerson").orElse(vision.resolve("person_yolox_nano.onnx").path)) { rename { "blur_person.onnx" } }
    from(providers.gradleProperty("imBlurGender").orElse(vision.resolve("gender.onnx").path)) { rename { "blur_gender.onnx" } }
    from(providers.gradleProperty("imBlurNsfw").orElse(vision.resolve("nsfw_marqo_int8.onnx").path)) { rename { "blur_nsfw.onnx" } }
    into(modelAssets)
}
android.sourceSets["main"].assets.srcDir(modelAssets)

// -PimBlurA11y: also declare the screen blur's accessibility service (touches pass through the covers).
androidComponents {
    onVariants { v -> if (blurA11y) v.sources.manifests.addStaticManifestFile("src/blurA11y/AndroidManifest.xml") }
}

// Link feature: yt-dlp (+ EJS scripts) under Python 3.11, and QuickJS shipped as an executable named lib*.so so it
// is extracted to nativeLibraryDir, the only place an app may execute files from.
chaquopy {
    defaultConfig {
        version = "3.11"
        providers.gradleProperty("imBuildPython").orNull?.let { buildPython(it) }
        pip {
            install("yt-dlp==$ytDlpVersion")
            install("yt-dlp-ejs==$ytDlpEjsVersion")
        }
    }
}
val qjsLibs = layout.buildDirectory.dir("qjsLibs")
val buildQjs by tasks.registering(Exec::class) {
    val abis = android.defaultConfig.ndk.abiFilters.toList().sorted()
    inputs.file("../tools/build_qjs.sh")
    inputs.property("abis", abis)
    outputs.dir(qjsLibs)
    executable = "bash"
    args(listOf(file("../tools/build_qjs.sh").path, android.sdkDirectory.path, android.ndkDirectory.path,
        layout.buildDirectory.dir("qjs").get().asFile.path, qjsLibs.get().asFile.path) + abis)
}
android.sourceSets["main"].jniLibs.srcDir(qjsLibs)
tasks.named("preBuild") { dependsOn(buildQjs) }
android.packaging.jniLibs.useLegacyPackaging = true
android.androidResources.noCompress += listOf("onnx", "bin")
tasks.named("preBuild") { dependsOn(copyModel) }

// Open-source licences screen (LicencesActivity): the texts are copied from the repository at build time so the
// app always shows the current NOTICE / THIRD_PARTY_LICENSES.md. android/app/licences/ holds the licence texts
// that exist nowhere else in the repository (Shizuku-API, DeepFilterNet).
// ONNX Runtime's LICENSE and ThirdPartyNotices.txt are not in the AAR: they are taken from the ONNX Runtime
// release unpacked in third_party/onnxruntime/ (or -PimOrtDir=...), which must be the same version as the AAR.
// A release build fails without them; a debug build gets a placeholder pointing to the upstream file.
val licenceAssets = layout.buildDirectory.dir("licenceAssets")
val copyLicences by tasks.registering(Sync::class) {
    val repo = rootProject.file("..")
    val ortDir = file(providers.gradleProperty("imOrtDir").getOrElse(repo.resolve("third_party/onnxruntime").path))
    val rootTexts = mapOf(
        "NOTICE" to "NOTICE.txt",
        "LICENSE" to "LICENSE-Apache-2.0.txt",
        "THIRD_PARTY_LICENSES.md" to "THIRD_PARTY_LICENSES.txt",  // .txt: WebView shows it as plain text
        "models/detector/efficientat/LICENSE" to "EfficientAT-LICENSE.txt",
    )
    val ortVersionFile = ortDir.resolve("VERSION_NUMBER")
    val ortOk = ortVersionFile.isFile && ortVersionFile.readText().trim() == ortVersion &&
        ortDir.resolve("LICENSE").isFile && ortDir.resolve("ThirdPartyNotices.txt").isFile
    rootTexts.forEach { (src, dst) -> from(repo.resolve(src)) { rename { dst } } }
    from("licences")
    if (ortOk) from(ortDir) { include("LICENSE", "ThirdPartyNotices.txt"); rename { "onnxruntime-${it.removeSuffix(".txt")}.txt" } }
    into(licenceAssets.map { it.dir("licences") })
    outputs.upToDateWhen { false }  // cheap, and the release/debug check below must run every time
    doFirst {
        val missing = rootTexts.keys.filterNot { repo.resolve(it).isFile }
        if (missing.isNotEmpty()) throw GradleException("Licence texts missing: $missing")
        if (!ortOk) {
            val msg = "ONNX Runtime $ortVersion LICENSE / ThirdPartyNotices.txt not found in $ortDir " +
                "(unpack onnxruntime-linux-x64-$ortVersion.tgz there, or pass -PimOrtDir=...)"
            if (gradle.taskGraph.allTasks.any { it.name.contains("Release") }) throw GradleException(msg)
            logger.warn("warning: $msg; using a placeholder (debug only)")
        }
    }
    doLast {
        if (!ortOk) {
            val url = "https://github.com/microsoft/onnxruntime/blob/v$ortVersion"
            val dir = licenceAssets.get().dir("licences").asFile
            dir.resolve("onnxruntime-LICENSE.txt").writeText("MIT License, Copyright (c) Microsoft Corporation.\n$url/LICENSE\n")
            dir.resolve("onnxruntime-ThirdPartyNotices.txt").writeText("Debug build without the notices file.\n$url/ThirdPartyNotices.txt\n")
        }
    }
}
android.sourceSets["main"].assets.srcDir(licenceAssets)
tasks.named("preBuild") { dependsOn(copyLicences) }
