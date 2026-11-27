package org.waaiya.app

import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import java.io.Closeable

/**
 * Live captions (docs/CAPTIONS.md): Arabic speech from the microphone written as large text on the screen, for deaf
 * and hard-of-hearing listeners at a khutba or a lesson. Everything runs on the phone; nothing is sent.
 *
 * Snapshot `features.captions`: `available` = this build bundles the Arabic speech model. Method `captions.open`
 * opens [CaptionsActivity]; it refuses with `unsupported` when there is no model.
 */
object Captions : Feature {
    override val name = "captions"

    override fun snapshot(host: FeatureHost): Map<String, Any?> = mapOf(
        "available" to ModelStore.hasAsset(host.activity, ModelStore.CAPTIONS),
        "running" to (Listener.current != null),
    )

    override fun call(host: FeatureHost, method: String, args: Map<String, Any?>): Any? {
        val c = host.activity
        when (method) {
            "open" -> {
                if (!ModelStore.hasAsset(c, ModelStore.CAPTIONS))
                    throw FeatureException("unsupported", "this build has no Arabic speech model")
                c.startActivity(Intent(c, CaptionsActivity::class.java))
            }
            else -> throw FeatureException("unsupported", "captions.$method")
        }
        return null
    }

    /**
     * Listens to the microphone on its own thread and hands the text to [onText] (on that thread). [clean]: first keep
     * only the voice with the engine (the voice model, as the filter does); if the engine cannot open, the raw
     * microphone is used rather than no captions at all, since the captions only show text and never decide what the
     * user hears. Stop with [close].
     */
    class Listener(
        private val context: Context,
        /** Called on the listening thread: the first call copies the model out of the APK (large). */
        private val modelPath: () -> String?,
        @Volatile var clean: Boolean,
        private val onText: (Update) -> Unit,
        private val onError: (Problem) -> Unit,
    ) : Closeable {
        enum class Problem { NO_MODEL, NO_MIC, FAILED }

        /** A new finished line (or null), the line being spoken, and whether the phone keeps up. */
        data class Update(val finals: List<String>, val partial: String, val speaking: Boolean, val slow: Boolean)

        @Volatile private var stopping = false
        @Volatile var paused = false
        @Volatile private var clearAsked = false
        private var thread: Thread? = null

        fun start() {
            current = this
            thread = Thread({ run() }, "im-captions").also { it.start() }
        }

        /** Drops the line being spoken (the screen's Clear). */
        fun clear() { clearAsked = true }

        override fun close() {
            stopping = true
            thread?.join(3000)
            thread = null
            if (current === this) current = null
        }

        private fun run() {
            val path = modelPath() ?: run { onError(Problem.NO_MODEL); return }
            val native = CaptionsNative.open(path, Engine.SAMPLE_RATE, THREADS)
            if (native == null) { onError(Problem.FAILED); return }
            native.use { k ->
                val rec = openMic() ?: run { onError(Problem.NO_MIC); return }
                var engine: Engine? = null
                var engineTried = false
                val block = Engine.SAMPLE_RATE / 50  // 20 ms
                val raw = FloatArray(block)
                val out = FloatArray(block)
                val slow = CaptionsText.SlowMeter()
                try {
                    rec.startRecording()
                    while (!stopping) {
                        val n = rec.read(raw, 0, block, AudioRecord.READ_BLOCKING)
                        if (n < 0) { onError(Problem.NO_MIC); break }
                        if (n == 0) continue
                        if (clearAsked) { clearAsked = false; k.reset() }
                        if (paused) continue
                        if (clean && !engineTried) {
                            engineTried = true
                            val opened = runCatching { Engine.open(context, 1, mono = true) }.getOrNull()
                            if (opened != null && opened.failed) opened.close()
                            engine = opened?.takeIf { !it.failed }
                            if (engine == null) Log.w(TAG, "captions: voice model failed, raw microphone")
                        }
                        val e = if (clean) engine else null
                        val x = if (e != null) { e.process(raw, out, n); out } else raw
                        val r = k.push(x, n)
                        if (r < 0) Log.w(TAG, "captions: recognition failed on one line")
                        if (r != 0) {
                            val finals = generateSequence { k.takeFinal() }.toList()
                            onText(Update(finals, k.partial(), k.speaking(), slow.add(k.lastMs(), k.lastAudioS())))
                        }
                    }
                    if (!paused) {
                        k.flush()
                        val finals = generateSequence { k.takeFinal() }.toList()
                        if (finals.isNotEmpty()) onText(Update(finals, "", false, false))
                    }
                } catch (t: Throwable) {
                    Log.e(TAG, "captions", t)
                    onError(Problem.FAILED)
                } finally {
                    runCatching { rec.stop() }
                    rec.release()
                    engine?.close()
                }
            }
        }

        @Suppress("MissingPermission")  // the screen asks for RECORD_AUDIO before it starts a listener
        private fun openMic(): AudioRecord? = runCatching {
            val rate = Engine.SAMPLE_RATE
            val min = AudioRecord.getMinBufferSize(rate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_FLOAT)
            // a few seconds of room: a recognition can take a while and the microphone must not drop audio meanwhile
            val bytes = maxOf(min, rate * 4 * 4)
            // VOICE_RECOGNITION: no automatic gain or noise suppression shaping the sound for a call
            AudioRecord(MediaRecorder.AudioSource.VOICE_RECOGNITION, rate, AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_FLOAT, bytes).takeIf { it.state == AudioRecord.STATE_INITIALIZED }
                ?: run { Log.w(TAG, "captions: microphone did not open"); null }
        }.getOrNull()

        companion object {
            private const val TAG = "IslamicMute"
            /** Recognition threads: two leave room for the voice model and the screen on a mid-range phone. */
            private const val THREADS = 2
            @Volatile var current: Listener? = null
                private set
        }
    }
}

/** engine/include/im_captions.h through captions_jni.c. */
class CaptionsNative private constructor(private var h: Long) : Closeable {
    companion object {
        init {
            System.loadLibrary("onnxruntime")
            System.loadLibrary("imengine")
        }

        @JvmStatic private external fun nativeCreate(path: String, rate: Int, threads: Int): Long
        @JvmStatic private external fun nativePush(h: Long, x: FloatArray, n: Int): Int
        @JvmStatic private external fun nativeFlush(h: Long): Int
        @JvmStatic private external fun nativeReset(h: Long)
        @JvmStatic private external fun nativePartial(h: Long): String
        @JvmStatic private external fun nativeTakeFinal(h: Long): String?
        @JvmStatic private external fun nativeSpeaking(h: Long): Boolean
        @JvmStatic private external fun nativeLevelDb(h: Long): Float
        @JvmStatic private external fun nativeLastMs(h: Long): Float
        @JvmStatic private external fun nativeLastAudioS(h: Long): Float
        @JvmStatic private external fun nativeDestroy(h: Long)

        /** Null when the model does not load or does not follow the contract (the log says why). */
        fun open(path: String, rate: Int, threads: Int): CaptionsNative? =
            nativeCreate(path, rate, threads).takeIf { it != 0L }?.let { CaptionsNative(it) }
    }

    /** Flags: 1 = the partial line changed, 2 = a line finished; -1 = the recogniser failed on a line. */
    fun push(x: FloatArray, n: Int): Int = nativePush(h, x, n)
    fun flush(): Int = nativeFlush(h)
    fun reset() = nativeReset(h)
    fun partial(): String = nativePartial(h)
    fun takeFinal(): String? = nativeTakeFinal(h)
    fun speaking(): Boolean = nativeSpeaking(h)
    fun levelDb(): Float = nativeLevelDb(h)
    fun lastMs(): Float = nativeLastMs(h)
    fun lastAudioS(): Float = nativeLastAudioS(h)

    override fun close() {
        if (h != 0L) { nativeDestroy(h); h = 0L }
    }
}

/** The screen's text, kept apart from Android so it can be tested on its own (CaptionsTextTest). */
object CaptionsText {
    /** Lines kept on the screen: enough to read back a few minutes, small enough to stay quick. */
    const val MAX_LINES = 200

    /** Adds the finished [lines] (blank ones dropped) to [shown] and keeps the last [max]. */
    fun append(shown: List<String>, lines: List<String>, max: Int = MAX_LINES): List<String> {
        val all = shown + lines.map { it.trim() }.filter { it.isNotEmpty() }
        return if (all.size > max) all.subList(all.size - max, all.size) else all
    }

    /** Font sizes the screen steps through, in sp. */
    const val MIN_SP = 20
    const val MAX_SP = 72
    const val DEFAULT_SP = 34
    fun bigger(sp: Int): Int = (sp + step(sp)).coerceAtMost(MAX_SP)
    fun smaller(sp: Int): Int = (sp - step(sp - 1)).coerceAtLeast(MIN_SP)
    private fun step(sp: Int): Int = if (sp < 40) 4 else 8

    /** Colours: text on background, as ARGB. White on black first: easiest to read in a dim mosque. */
    val SCHEMES = listOf(0xFFFFFFFF.toInt() to 0xFF000000.toInt(), 0xFF000000.toInt() to 0xFFFFFFFF.toInt(),
        0xFFFFEB3B.toInt() to 0xFF000000.toInt())

    fun nextScheme(i: Int): Int = (i + 1).mod(SCHEMES.size)

    /**
     * "The phone is slow": the last few recognitions took longer than half the audio they read, so the text falls
     * behind the speaker. One slow run (a cold start) is not enough.
     */
    class SlowMeter(private val window: Int = 5) {
        private val ratios = ArrayDeque<Float>()

        fun add(ms: Float, audioS: Float): Boolean {
            if (audioS > 0.5f && ms > 0f) {
                ratios.addLast(ms / 1000f / audioS)
                while (ratios.size > window) ratios.removeFirst()
            }
            return ratios.size >= 3 && ratios.sorted()[ratios.size / 2] > 0.5f
        }
    }
}
