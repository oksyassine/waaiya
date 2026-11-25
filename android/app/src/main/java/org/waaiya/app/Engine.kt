package org.waaiya.app

import android.content.Context
import java.io.File

/** The shared C engine (engine/src/im_engine.c) through JNI. Fail-closed: a failed engine outputs silence. */
class Engine private constructor(private var handle: Long) : AutoCloseable {
    companion object {
        init {
            System.loadLibrary("onnxruntime")
            System.loadLibrary("imengine")
        }

        @JvmStatic private external fun nativeCreate(
            path: String, detector: String?, channels: Int, rate: Int, mono: Boolean, policy: Int,
        ): Long
        @JvmStatic private external fun nativeSetPolicy(h: Long, policy: Int)
        @JvmStatic private external fun nativeDetectorStatus(h: Long, probs: FloatArray?): Int
        @JvmStatic private external fun nativeProcess(h: Long, input: FloatArray, output: FloatArray, frames: Int)
        @JvmStatic private external fun nativeProcessHops(h: Long, input: FloatArray, output: FloatArray, hops: Int): Int
        @JvmStatic private external fun nativeAlignedLatency(h: Long): Int
        @JvmStatic private external fun nativeLatency(h: Long): Int
        @JvmStatic private external fun nativeFailed(h: Long): Boolean
        @JvmStatic private external fun nativeSetGate(h: Long, gain: Float)
        @JvmStatic private external fun nativeReset(h: Long)
        @JvmStatic private external fun nativeSetMono(h: Long, mono: Boolean): Boolean
        @JvmStatic private external fun nativeRunErrors(h: Long): Long
        @JvmStatic private external fun nativeModelName(h: Long): String?
        @JvmStatic private external fun nativeDestroy(h: Long)

        const val SAMPLE_RATE = 48000

        // engine/include/im_engine.h
        const val POLICY_MUTE_FEMALE_SINGING = 1
        const val POLICY_MUTE_FEMALE_VOICE = 2
        const val POLICY_FAIL_CLOSED = 4

        /** The voice policy chosen in Settings (men who enabled it: mute women's singing, fail-closed). */
        fun policy(settings: Settings): Int =
            if (settings.gender == "man" && settings.muteWomenSinging) POLICY_MUTE_FEMALE_SINGING or POLICY_FAIL_CLOSED else 0

        /**
         * [singing]: the "keep singing" model (voice_v1, setting keep_singing) instead of the default one. Fail-closed:
         * when that model is not bundled or does not load, the engine is created failed and outputs silence; it never
         * falls back to another model.
         */
        fun open(context: Context, channels: Int, mono: Boolean = false, singing: Boolean = false): Engine {
            val policy = policy(Settings(context))
            // always loaded when bundled: the policy can be switched on later without restarting (FilterService)
            val detector = ModelStore.detectorPath(context)
            val model = if (singing) ModelStore.singingPath(context) else ModelStore.modelPath(context)
            return Engine(nativeCreate(model, detector, channels, SAMPLE_RATE, mono, policy))
        }
    }

    /** Input-to-output delay in frames. */
    val latency: Int get() = nativeLatency(handle)
    val failed: Boolean get() = nativeFailed(handle)

    /** Interleaved float audio, any block size. */
    fun process(input: FloatArray, output: FloatArray, frames: Int) = nativeProcess(handle, input, output, frames)

    /** Whole hops only (frames = hops * hop): each hop leaves in the same call, so the delay is
     *  [alignedLatency] (one hop less than [latency]). Do not mix with [process] on one stream. */
    fun processHops(input: FloatArray, output: FloatArray, hops: Int): Int = nativeProcessHops(handle, input, output, hops)
    val alignedLatency: Int get() = nativeAlignedLatency(handle)
    fun setGate(gain: Float) = nativeSetGate(handle, gain)
    fun setPolicy(policy: Int) = nativeSetPolicy(handle, policy)

    /** 1 = the women's-singing filter is muting now, 0 = not, -1 = no detector. probs: female, speech, singing, recitation. */
    fun detectorStatus(probs: FloatArray? = null): Int = nativeDetectorStatus(handle, probs)
    fun reset() = nativeReset(handle)

    /** True = mix the channels and run the model once per hop (half the work). Returns the mode now in effect. */
    fun setMono(mono: Boolean): Boolean = nativeSetMono(handle, mono)
    /** Hops the model failed on (their output was silence). */
    val runErrors: Long get() = nativeRunErrors(handle)
    val modelName: String get() = nativeModelName(handle) ?: "?"

    override fun close() {
        if (handle != 0L) { nativeDestroy(handle); handle = 0L }
    }
}

/** Copies the bundled voice model out of the APK once (ONNX Runtime loads from a file path). */
object ModelStore {
    private const val MODEL = "voice.onnx"
    private const val STATE = "voice.state_init.bin"
    private const val DETECTOR = "detector.onnx"
    /** "Check for music": the AudioSet tagger (models/music/export_tagger.py). */
    private const val MUSIC_TAGGER = "music_tagger.onnx"
    /** Keep singing (voice_v1): the engine finds voice_singing.state_init.bin next to it. */
    private const val SINGING = "voice_singing.onnx"
    private const val SINGING_STATE = "voice_singing.state_init.bin"
    const val BLUR_PERSON = "blur_person.onnx"
    const val BLUR_GENDER = "blur_gender.onnx"
    const val BLUR_NSFW = "blur_nsfw.onnx"
    const val BLUR_SEG = "blur_seg.onnx"
    private val BLUR_MODELS = listOf(BLUR_PERSON, BLUR_GENDER, BLUR_NSFW, BLUR_SEG)

    /** One copy at a time: the audio thread, the blur and a model reload call this at once at a start, and two
     *  copies writing the same file would leave a model half written. */
    @Synchronized
    fun modelPath(context: Context): String {
        val dir = File(context.filesDir, "models").apply { mkdirs() }
        val version = context.packageManager.getPackageInfo(context.packageName, 0).longVersionCode
        val stamp = File(dir, "version")
        // copied again on a new version, or when a bundled model is missing here (a debug reinstall keeps the version)
        val names = listOf(MODEL, STATE, DETECTOR, SINGING, SINGING_STATE, MUSIC_TAGGER) + BLUR_MODELS
        if (stamp.takeIf { it.exists() }?.readText() != version.toString() ||
            names.any { !File(dir, it).exists() && hasAsset(context, it) }) {
            for (name in names) {
                runCatching { context.assets.open(name).use { i -> File(dir, name).outputStream().use { i.copyTo(it) } } }
            }
            // a full disk: the models are copied again next time instead of ending the caller's thread
            runCatching { stamp.writeText(version.toString()) }
        }
        return File(dir, MODEL).absolutePath
    }

    /**
     * The keep-singing model's path. Returned even when this build does not bundle it: the engine then fails to load
     * and stays silent (fail-closed), it never falls back to the default model.
     */
    fun singingPath(context: Context): String {
        modelPath(context)
        val f = File(File(context.filesDir, "models"), SINGING)
        if (!hasSinging(context)) f.delete()  // a copy left by an older build is not this build's model
        return f.absolutePath
    }

    /** This build bundles the keep-singing model (both files). */
    fun hasSinging(context: Context): Boolean = hasAsset(context, SINGING) && hasAsset(context, SINGING_STATE)

    /** The women's-singing detector, or null if this build does not bundle one. */
    fun detectorPath(context: Context): String? {
        modelPath(context)
        return File(File(context.filesDir, "models"), DETECTOR).takeIf { it.exists() }?.absolutePath
    }

    /** A screen-blur model copied out of the APK, or null when this build does not bundle it. */
    fun blurModel(context: Context, name: String): String? {
        modelPath(context)
        return File(File(context.filesDir, "models"), name).takeIf { it.exists() }?.absolutePath
    }

    /** The "check for music" tagger, or null when this build does not bundle it. */
    fun musicTaggerPath(context: Context): String? {
        modelPath(context)
        val f = File(File(context.filesDir, "models"), MUSIC_TAGGER)
        if (!hasAsset(context, MUSIC_TAGGER)) { f.delete(); return null }
        return f.takeIf { it.exists() }?.absolutePath
    }

    fun hasAsset(context: Context, name: String): Boolean = runCatching { context.assets.open(name).close() }.isSuccess

    fun hasDetector(context: Context): Boolean = runCatching { context.assets.open(DETECTOR).close() }.isSuccess
}
