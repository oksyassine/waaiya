package org.islamicmute.app

import android.content.Context
import java.nio.ByteBuffer

/**
 * Screen blur models and tracker (engine/src/im_vision.c + im_cover.c) through JNI. Not thread-safe: one thread
 * (ScreenBlur's worker) owns it.
 */
class Vision private constructor(private var handle: Long) : AutoCloseable {
    companion object {
        init {
            System.loadLibrary("onnxruntime")
            System.loadLibrary("imengine")
        }

        @JvmStatic private external fun nativeCreate(person: String?, gender: String?, nsfw: String?, seg: String?,
                                                     threads: Int, policy: Int, coversVisible: Boolean): Long
        @JvmStatic private external fun nativeDestroy(h: Long)
        @JvmStatic private external fun nativeStatus(h: Long): Int
        @JvmStatic private external fun nativeError(h: Long): String
        @JvmStatic private external fun nativeSetCoversVisible(h: Long, visible: Boolean)
        @JvmStatic private external fun nativeSetTilesPerFrame(h: Long, n: Int)
        @JvmStatic private external fun nativeSetMaleClear(h: Long, t: Float)
        @JvmStatic private external fun nativeFrame(h: Long, buf: ByteBuffer, w: Int, hh: Int, stride: Int, tMs: Double,
                                                    models: Boolean, nsfw: Boolean, out: FloatArray, thumb: IntArray?,
                                                    tw: Int, th: Int): Int

        // engine/include/im_vision.h
        const val POLICY_WOMEN = 1
        const val POLICY_NSFW = 2
        const val KIND_WOMAN = 1
        const val KIND_UNSURE = 2
        const val KIND_NSFW = 3
        const val KIND_FULL = 4
        /** Flag in a rect's kind: one strip of an outlined person, or a bridge between people (square corners). */
        const val KIND_PART = 16
        /** Rects per frame (vision_jni.c MAX_RECTS): an outlined person is drawn as up to 16 strips. */
        const val MAX_RECTS = 256

        fun policy(s: Settings): Int = (if (s.blurWomen) POLICY_WOMEN else 0) or (if (s.blurNudity) POLICY_NSFW else 0)

        fun open(context: Context, policy: Int, coversVisible: Boolean): Vision = Vision(nativeCreate(
            ModelStore.blurModel(context, ModelStore.BLUR_PERSON),
            ModelStore.blurModel(context, ModelStore.BLUR_GENDER),
            ModelStore.blurModel(context, ModelStore.BLUR_NSFW),
            ModelStore.blurModel(context, ModelStore.BLUR_SEG), // optional: without it, whole rectangles
            2, policy, coversVisible))
    }

    /** Policy bits the bundled models cannot serve (0 = all fine). */
    val status: Int get() = if (handle == 0L) -1 else nativeStatus(handle)
    val error: String get() = if (handle == 0L) "no memory" else nativeError(handle)

    fun setCoversVisible(v: Boolean) { if (handle != 0L) nativeSetCoversVisible(handle, v) }

    /** A person is left uncovered only when the model's p(man) is at least [t] (Settings.blurMaleClear). */
    fun setMaleClear(t: Float) { if (handle != 0L) nativeSetMaleClear(handle, t) }

    /** Portrait frames: person-detector tiles per frame (0 = all every frame, 1 = one, taking turns). */
    fun setTilesPerFrame(n: Int) { if (handle != 0L) nativeSetTilesPerFrame(handle, n) }

    /** Result of one frame: rects as x0,y0,x1,y1 (0..1), kind (maybe | [KIND_PART]); [failed] = the models failed
     *  (covers were held). */
    class Frame(val rects: FloatArray, var count: Int, var failed: Boolean)

    fun frame(buf: ByteBuffer, w: Int, h: Int, stride: Int, tMs: Double, models: Boolean, nsfw: Boolean,
              out: Frame, thumb: IntArray?, tw: Int, th: Int) {
        val r = if (handle == 0L) -1 else nativeFrame(handle, buf, w, h, stride, tMs, models, nsfw, out.rects, thumb, tw, th)
        out.failed = r < 0
        out.count = if (r < 0) -r - 1 else r
    }

    override fun close() {
        if (handle != 0L) { nativeDestroy(handle); handle = 0L }
    }
}
