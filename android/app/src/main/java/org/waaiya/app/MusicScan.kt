package org.waaiya.app

import android.content.Context
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import java.io.Closeable
import java.nio.ByteOrder

/**
 * "Check for music" analysis of one file (docs/MUSIC_CHECK.md): decodes its sound track on the phone, tags 1 s
 * windows every 0.5 s (engine/src/im_music.c, the AudioSet tagger models/music/tagger_mn04.onnx) and decides with
 * [MusicRule]. Nothing leaves the phone.
 */
class MusicScan private constructor(private var h: Long) : Closeable {
    companion object {
        init {
            System.loadLibrary("onnxruntime")
            System.loadLibrary("imengine")
        }

        /** Longer recordings are not checked (about 7 MB of tags per 30 min). */
        const val MAX_SECONDS = 30 * 60

        @JvmStatic private external fun nativeCreate(path: String, rate: Int): Long
        @JvmStatic private external fun nativeClasses(h: Long): Int
        @JvmStatic private external fun nativePush(h: Long, x: FloatArray, n: Int): Int
        @JvmStatic private external fun nativeFinish(h: Long): Int
        @JvmStatic private external fun nativeTake(h: Long, probs: FloatArray, levels: FloatArray, max: Int): Int
        @JvmStatic private external fun nativeDestroy(h: Long)

        fun open(tagger: String, rate: Int): MusicScan? = nativeCreate(tagger, rate).takeIf { it != 0L }?.let { MusicScan(it) }

        sealed class Outcome {
            data class Done(val result: MusicRule.Result, val durationS: Double) : Outcome()
            object NoModel : Outcome()
            object NoSound : Outcome()
            object TooLong : Outcome()
            object Unreadable : Outcome()
            object Cancelled : Outcome()
        }

        /** Runs on the caller's thread (not the main one). progress: 0..1. */
        fun analyze(ctx: Context, uri: Uri, progress: (Float) -> Unit, cancelled: () -> Boolean): Outcome {
            val tagger = ModelStore.musicTaggerPath(ctx) ?: return Outcome.NoModel
            val ex = MediaExtractor()
            var codec: MediaCodec? = null
            var scan: MusicScan? = null
            try {
                try { ex.setDataSource(ctx, uri, null) } catch (e: Exception) { return Outcome.Unreadable }
                val track = (0 until ex.trackCount).firstOrNull {
                    ex.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true
                } ?: return Outcome.NoSound
                val fmt = ex.getTrackFormat(track)
                val durUs = if (fmt.containsKey(MediaFormat.KEY_DURATION)) fmt.getLong(MediaFormat.KEY_DURATION) else -1L
                if (durUs > MAX_SECONDS * 1_000_000L) return Outcome.TooLong
                ex.selectTrack(track)
                val c = try {
                    MediaCodec.createDecoderByType(fmt.getString(MediaFormat.KEY_MIME)!!).also { it.configure(fmt, null, null, 0); it.start() }
                } catch (e: Exception) { return Outcome.Unreadable }
                codec = c
                val info = MediaCodec.BufferInfo()
                var channels = fmt.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                var rate = fmt.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                var floatPcm = false
                val probs = ArrayList<FloatArray>()
                val levels = ArrayList<Float>()
                var mono = FloatArray(0)
                var samples = 0L
                val tp = FloatArray(MusicRule.CLASSES * 64)
                val tl = FloatArray(64)
                fun take(s: MusicScan) {
                    while (true) {
                        val k = nativeTake(s.h, tp, tl, 64)
                        if (k <= 0) break
                        for (j in 0 until k) {
                            probs.add(tp.copyOfRange(j * MusicRule.CLASSES, (j + 1) * MusicRule.CLASSES))
                            levels.add(tl[j])
                        }
                    }
                }
                var inputDone = false
                var outputDone = false
                while (!outputDone) {
                    if (cancelled()) return Outcome.Cancelled
                    if (!inputDone) {
                        val i = c.dequeueInputBuffer(10_000)
                        if (i >= 0) {
                            val n = ex.readSampleData(c.getInputBuffer(i)!!, 0)
                            if (n < 0) {
                                c.queueInputBuffer(i, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                                inputDone = true
                            } else {
                                c.queueInputBuffer(i, 0, n, ex.sampleTime, 0)
                                ex.advance()
                            }
                        }
                    }
                    val o = c.dequeueOutputBuffer(info, 10_000)
                    when {
                        o == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                            val f = c.outputFormat
                            channels = f.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                            rate = f.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                            floatPcm = f.containsKey(MediaFormat.KEY_PCM_ENCODING) &&
                                f.getInteger(MediaFormat.KEY_PCM_ENCODING) == AudioFormat.ENCODING_PCM_FLOAT
                        }
                        o >= 0 -> {
                            val buf = c.getOutputBuffer(o)!!.order(ByteOrder.nativeOrder())
                            buf.position(info.offset); buf.limit(info.offset + info.size)
                            val s = scan ?: (open(tagger, rate) ?: return Outcome.NoModel).also { scan = it }
                            val frames = if (floatPcm) info.size / 4 / channels else info.size / 2 / channels
                            if (mono.size < frames) mono = FloatArray(frames)
                            if (floatPcm) {
                                val fb = buf.asFloatBuffer()
                                for (t in 0 until frames) {
                                    var sum = 0f
                                    for (ch in 0 until channels) sum += fb.get(t * channels + ch)
                                    mono[t] = sum / channels
                                }
                            } else {
                                val sb = buf.asShortBuffer()
                                for (t in 0 until frames) {
                                    var sum = 0f
                                    for (ch in 0 until channels) sum += sb.get(t * channels + ch)
                                    mono[t] = sum / channels / 32768f
                                }
                            }
                            c.releaseOutputBuffer(o, false)
                            if (frames > 0) {
                                if (nativePush(s.h, mono, frames) < 0) return Outcome.Unreadable
                                take(s)
                                samples += frames
                                if (samples > MAX_SECONDS.toLong() * rate) return Outcome.TooLong
                                if (durUs > 0) progress((samples.toDouble() / rate * 1e6 / durUs).toFloat().coerceIn(0f, 1f))
                            }
                            if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) outputDone = true
                        }
                    }
                }
                val s = scan ?: return Outcome.NoSound
                if (nativeFinish(s.h) < 0) return Outcome.Unreadable
                take(s)
                val durationS = samples.toDouble() / rate
                if (samples == 0L) return Outcome.NoSound
                // only the windows that start inside the recording
                val n = minOf(probs.size, (durationS / MusicRule.STEP_S).toInt() + 1)
                val result = MusicRule.decide(probs.subList(0, n), levels.subList(0, n).toFloatArray(), durationS)
                progress(1f)
                return Outcome.Done(result, durationS)
            } catch (e: Exception) {
                android.util.Log.w("IslamicMute", "music check failed", e)
                return Outcome.Unreadable
            } finally {
                runCatching { codec?.stop() }
                runCatching { codec?.release() }
                ex.release()
                scan?.close()
            }
        }
    }

    override fun close() {
        if (h != 0L) { nativeDestroy(h); h = 0L }
    }
}
