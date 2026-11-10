package org.islamicmute.app

import android.content.Context
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.os.Build
import android.util.Log
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Delay (frames at 48 kHz) that this phone's AAC encoder + decoder add at the start of a stream ("priming").
 * Saved files are written without an edit list for it, so players would play the audio this much late; the
 * exporter starts the filtered audio earlier by the same amount instead. Measured once per device and codec
 * (encode a click, decode it, see where it lands) and cached; 2048 on the Android emulator's codecs.
 */
object AacDelay {
    private const val RATE = 48000
    private const val CLICK_AT = 4800  // 100 ms of silence first

    fun get(ctx: Context): Int {
        val p = ctx.getSharedPreferences("codec", Context.MODE_PRIVATE)
        val key = "aac_delay_" + Build.FINGERPRINT.hashCode()
        p.getInt(key, -1).takeIf { it >= 0 }?.let { return it }
        val d = runCatching { measure() }.onFailure { Log.w("IslamicMute", "AAC delay measurement failed", it) }.getOrNull()
            ?: return 0
        p.edit().putInt(key, d).apply()
        Log.i("IslamicMute", "AAC encoder+decoder delay: $d frames")
        return d
    }

    private fun measure(): Int {
        val frames = RATE / 2
        val pcm = ShortArray(frames * 2).also { for (i in 0 until 48) { it[(CLICK_AT + i) * 2] = 24000; it[(CLICK_AT + i) * 2 + 1] = 24000 } }
        val fmt = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, RATE, 2).apply {
            setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
            setInteger(MediaFormat.KEY_BIT_RATE, 128_000)
        }
        val enc = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
        enc.configure(fmt, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE); enc.start()
        val packets = ArrayList<ByteArray>()
        var csd: ByteBuffer? = null
        run(enc, pcmBytes(pcm), { b -> packets += b }, { f -> csd = f.getByteBuffer("csd-0") })
        enc.release()
        val dfmt = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, RATE, 2).apply { setByteBuffer("csd-0", csd) }
        val dec = MediaCodec.createDecoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
        dec.configure(dfmt, null, null, 0); dec.start()
        val out = java.io.ByteArrayOutputStream()
        runPackets(dec, packets) { out.write(it) }
        dec.release()
        val s = ByteBuffer.wrap(out.toByteArray()).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        var first = -1
        for (i in 0 until s.limit() / 2) if (kotlin.math.abs(s.get(i * 2).toInt()) > 6000) { first = i; break }
        check(first >= 0) { "click not found" }
        return (first - CLICK_AT).coerceIn(0, 8192)
    }

    private fun pcmBytes(p: ShortArray): ByteArray =
        ByteBuffer.allocate(p.size * 2).order(ByteOrder.LITTLE_ENDIAN).also { it.asShortBuffer().put(p) }.array()

    /** Feeds raw bytes, collects output buffers (codec-config buffers excluded). */
    private fun run(c: MediaCodec, input: ByteArray, out: (ByteArray) -> Unit, format: (MediaFormat) -> Unit) {
        val info = MediaCodec.BufferInfo()
        var pos = 0; var inDone = false
        while (true) {
            if (!inDone) {
                val i = c.dequeueInputBuffer(10_000)
                if (i >= 0) {
                    val b = c.getInputBuffer(i)!!
                    val n = minOf(b.capacity(), input.size - pos)
                    b.put(input, pos, n); pos += n
                    val ts = pos / 4 * 1_000_000L / RATE
                    if (pos >= input.size) { c.queueInputBuffer(i, 0, n, ts, MediaCodec.BUFFER_FLAG_END_OF_STREAM); inDone = true }
                    else c.queueInputBuffer(i, 0, n, ts, 0)
                }
            }
            val o = c.dequeueOutputBuffer(info, 10_000)
            if (o == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) format(c.outputFormat)
            if (o >= 0) {
                if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0 && info.size > 0)
                    out(ByteArray(info.size).also { c.getOutputBuffer(o)!!.get(it) })
                c.releaseOutputBuffer(o, false)
                if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) return
            }
        }
    }

    private fun runPackets(c: MediaCodec, packets: List<ByteArray>, out: (ByteArray) -> Unit) {
        val info = MediaCodec.BufferInfo()
        var k = 0; var inDone = false
        while (true) {
            if (!inDone) {
                val i = c.dequeueInputBuffer(10_000)
                if (i >= 0) {
                    if (k < packets.size) { c.getInputBuffer(i)!!.put(packets[k]); c.queueInputBuffer(i, 0, packets[k].size, k * 21_333L, 0); k++ }
                    else { c.queueInputBuffer(i, 0, 0, k * 21_333L, MediaCodec.BUFFER_FLAG_END_OF_STREAM); inDone = true }
                }
            }
            val o = c.dequeueOutputBuffer(info, 10_000)
            if (o >= 0) {
                if (info.size > 0) out(ByteArray(info.size).also { c.getOutputBuffer(o)!!.get(it) })
                c.releaseOutputBuffer(o, false)
                if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) return
            }
        }
    }
}
