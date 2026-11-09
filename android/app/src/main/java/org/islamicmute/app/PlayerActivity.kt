package org.islamicmute.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.AudioProcessor.AudioFormat
import androidx.media3.common.audio.BaseAudioProcessor
import androidx.media3.common.audio.SonicAudioProcessor
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.DefaultAudioSink
import androidx.media3.exoplayer.audio.SilenceSkippingAudioProcessor
import androidx.media3.ui.PlayerView
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * "Share to" / "Open with" player. The filter runs inside the player's audio pipeline and its delay is
 * removed exactly (priming samples dropped, tail flushed), so audio and video stay in perfect sync on
 * any output (speaker, wired, Bluetooth).
 */
@OptIn(UnstableApi::class)
class PlayerActivity : Activity() {
    private var player: ExoPlayer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val uri: Uri = when (intent?.action) {
            Intent.ACTION_SEND -> if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                                  else @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_STREAM)
            else -> intent?.data
        } ?: run { finish(); return }

        val renderers = object : DefaultRenderersFactory(this) {
            override fun buildAudioSink(context: Context, enableFloatOutput: Boolean, enableAudioTrackPlaybackParams: Boolean): AudioSink {
                val to48k = SonicAudioProcessor().apply { setOutputSampleRateHz(Engine.SAMPLE_RATE) }
                val chain = DefaultAudioSink.DefaultAudioProcessorChain(
                    arrayOf(to48k, VoiceFilterProcessor(context)), SilenceSkippingAudioProcessor(), SonicAudioProcessor())
                return DefaultAudioSink.Builder(context).setAudioProcessorChain(chain).build()
            }
        }
        val p = ExoPlayer.Builder(this, renderers).build()
        player = p
        setContentView(PlayerView(this).apply { this.player = p })
        p.setMediaItem(MediaItem.fromUri(uri))
        p.prepare()
        p.play()
    }

    override fun onDestroy() { player?.release(); player = null; super.onDestroy() }
}

/** Media3 audio processor running the engine with exact delay compensation. Fail-closed on unsupported formats. */
@OptIn(UnstableApi::class)
class VoiceFilterProcessor(private val context: Context) : BaseAudioProcessor() {
    private var engine: Engine? = null
    private var channels = 0
    private var dropFrames = 0
    private var inF = FloatArray(0)
    private var outF = FloatArray(0)

    override fun onConfigure(inputAudioFormat: AudioFormat): AudioFormat {
        if (inputAudioFormat.encoding != C.ENCODING_PCM_16BIT || inputAudioFormat.sampleRate != Engine.SAMPLE_RATE ||
            inputAudioFormat.channelCount !in 1..2) {
            // Refuse instead of passing audio through unfiltered.
            throw AudioProcessor.UnhandledAudioFormatException(inputAudioFormat)
        }
        channels = inputAudioFormat.channelCount
        return inputAudioFormat
    }

    override fun onFlush() {
        engine?.close()
        engine = Engine.open(context, channels)
        dropFrames = engine!!.latency
    }

    override fun queueInput(inputBuffer: ByteBuffer) {
        val e = engine ?: return
        val shorts = inputBuffer.order(ByteOrder.nativeOrder()).asShortBuffer()
        val n = shorts.remaining()
        if (inF.size < n) { inF = FloatArray(n); outF = FloatArray(n) }
        for (i in 0 until n) inF[i] = shorts.get(i) / 32768f
        inputBuffer.position(inputBuffer.limit())
        e.process(inF, outF, n / channels)
        emit(n)
    }

    override fun onQueueEndOfStream() {
        val e = engine ?: return
        val n = e.latency * channels  // push zeros through so the last part of the audio comes out
        if (inF.size < n) { inF = FloatArray(n); outF = FloatArray(n) }
        java.util.Arrays.fill(inF, 0, n, 0f)
        e.process(inF, outF, n / channels)
        emit(n)
    }

    private fun emit(n: Int) {
        var start = 0
        if (dropFrames > 0) {  // the first `latency` frames are the engine's priming delay
            val d = minOf(dropFrames * channels, n)
            start = d; dropFrames -= d / channels
        }
        val count = n - start
        if (count <= 0) return
        val out = replaceOutputBuffer(count * 2).order(ByteOrder.nativeOrder())
        for (i in start until n) out.putShort((outF[i].coerceIn(-1f, 1f) * 32767f).toInt().toShort())
        out.flip()
    }

    override fun onReset() { engine?.close(); engine = null }
}
