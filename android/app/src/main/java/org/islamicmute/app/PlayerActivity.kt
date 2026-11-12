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
import androidx.media3.exoplayer.audio.AudioCapabilities
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.DefaultAudioSink
import androidx.media3.exoplayer.audio.SilenceSkippingAudioProcessor
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.source.MergingMediaSource
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.ui.PlayerView
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * "Share to" / "Open with" player. The filter runs inside the player's audio pipeline and its delay is
 * removed exactly (priming samples dropped, tail flushed), so audio and video stay in perfect sync on
 * any output (speaker, wired, Bluetooth).
 */
@OptIn(UnstableApi::class)
open class PlayerActivity : Activity() {
    override fun attachBaseContext(base: android.content.Context) { super.attachBaseContext(Lang.wrap(base)) }

    private var player: ExoPlayer? = null

    companion object {
        /** Streams from [Links.resolve], as JSON (see [Links.streamsJson]): plays a web link instead of a file.
         *  Read only by [LinkPlayerActivity] (not exported), never from another app's intent. */
        const val EXTRA_STREAMS = "streams"
        const val EXTRA_TITLE = "title"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // This activity is exported (share / open with): another app could otherwise hand it any URLs with any
        // request headers to fetch in Waaiya's name. A stream list is taken only through the non-exported entry.
        val streams = if (this is LinkPlayerActivity) intent?.getStringExtra(EXTRA_STREAMS) else null
        val uri: Uri? = when (intent?.action) {
            Intent.ACTION_SEND -> if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                                  else @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_STREAM)
            else -> intent?.data
        }
        if (streams == null && uri == null) { finish(); return }

        val renderers = object : DefaultRenderersFactory(this) {
            override fun buildAudioSink(context: Context, enableFloatOutput: Boolean, enableAudioTrackPlaybackParams: Boolean): AudioSink {
                val to48k = SonicAudioProcessor().apply { setOutputSampleRateHz(Engine.SAMPLE_RATE) }
                val chain = DefaultAudioSink.DefaultAudioProcessorChain(
                    arrayOf(to48k, VoiceFilterProcessor(context)), SilenceSkippingAudioProcessor(), SonicAudioProcessor())
                // No Context: with one, the sink reads the output's capabilities and plays AC-3 / E-AC-3 / DTS
                // tracks encoded ("passthrough") to a TV or soundbar that takes them, around the processor chain,
                // so the sound would be unfiltered. Without one it uses the given capabilities: PCM only, so every
                // track is decoded and filtered (a phone with no decoder for it fails to play, which is safe).
                @Suppress("DEPRECATION")
                return DefaultAudioSink.Builder().setAudioCapabilities(AudioCapabilities.DEFAULT_AUDIO_CAPABILITIES)
                    .setAudioProcessorChain(chain).build()
            }
        }
        val p = ExoPlayer.Builder(this, renderers).build()
        player = p
        setContentView(PlayerView(this).apply { this.player = p })
        // A link that cannot be played (expired, blocked, unsupported audio): say so instead of a black screen.
        p.addListener(object : androidx.media3.common.Player.Listener {
            override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
                android.util.Log.w("IslamicMute", "playback failed", error)
                android.widget.Toast.makeText(this@PlayerActivity, R.string.link_play_failed, android.widget.Toast.LENGTH_LONG).show()
                finish()
            }
        })
        // the activity is exported (share / open with): a malformed or empty request closes it instead of crashing
        val ok = runCatching {
            if (streams != null) p.setMediaSource(webSource(Links.streamsFromJson(streams)))
            else p.setMediaItem(MediaItem.fromUri(uri!!))
        }.isSuccess
        if (!ok) {
            android.widget.Toast.makeText(this, R.string.link_play_failed, android.widget.Toast.LENGTH_LONG).show()
            finish()
            return
        }
        p.prepare()
        p.play()
    }

    /** Leaving the player (home, another app, screen off) pauses it: there is no background playback control. */
    override fun onStop() { player?.pause(); super.onStop() }

    override fun onDestroy() { player?.release(); player = null; super.onDestroy() }

    /** Separate video + audio streams are merged; each request carries the headers the site expects. */
    private fun webSource(st: Links.Streams): MediaSource {
        fun source(s: Links.Stream): MediaSource {
            val http = DefaultHttpDataSource.Factory().setAllowCrossProtocolRedirects(true)
                .setDefaultRequestProperties(s.headers - "User-Agent")
                .setUserAgent(s.headers["User-Agent"] ?: "Mozilla/5.0")
            return ProgressiveMediaSource.Factory(http).createMediaSource(MediaItem.fromUri(s.url))
        }
        val parts = listOfNotNull(st.progressive, st.video, st.audio).map(::source)
        return if (parts.size == 1) parts[0] else MergingMediaSource(*parts.toTypedArray())
    }
}

/** The player for a resolved web link, started only by [LinkActivity] (not exported: see the manifest). */
class LinkPlayerActivity : PlayerActivity()

/** Media3 audio processor running the engine with exact delay compensation. Fail-closed on unsupported formats. */
@OptIn(UnstableApi::class)
class VoiceFilterProcessor(
    private val context: Context,
    private val strict: Boolean = false,
    /** Extra frames to drop at the start: the AAC encoder's priming when saving a file (see [AacDelay]). */
    private val extraDropFrames: Int = 0,
) : BaseAudioProcessor() {
    private var engine: Engine? = null
    private var channels = 0
    private var dropFrames = 0
    /** The delayed tail is pushed out once per stream. Transformer calls queueEndOfStream() again until isEnded();
     *  pushing zeros on every call made the audio endless and the export never finished. */
    private var tailQueued = false
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
        // Saved files must never be silent or unfiltered by accident: refuse instead (the export then fails).
        if (strict && engine!!.failed) throw IllegalStateException("voice model failed to load")
        dropFrames = engine!!.latency + extraDropFrames
        tailQueued = false
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
        if (tailQueued) return
        tailQueued = true
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
