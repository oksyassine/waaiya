package org.islamicmute.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import android.os.Process
import android.util.Log

/**
 * System-wide filter: captures other apps' audio (AudioPlaybackCapture), removes instruments with the
 * engine, and plays the result on a low-latency track. SessionMuter silences the original streams.
 */
class FilterService : Service() {
    /** What the screen shows. Published on the main thread to the companion's listeners. */
    enum class State { STOPPED, STARTING, FILTERING, MODEL_FAILED, NO_CAPTURE_PERMISSION, STOPPED_BY_SYSTEM }

    companion object {
        const val EXTRA_CODE = "code"
        const val EXTRA_DATA = "data"
        const val ACTION_STOP = "stop"
        private const val CHANNEL = "filter"
        private const val TAG = "IslamicMute"
        @Volatile var state = State.STOPPED
            private set
        /** Engine delay of the running filter in ms (model look-ahead; the capture/playback buffers add to it). */
        @Volatile var delayMs = 0
            private set
        val running: Boolean get() = state == State.STARTING || state == State.FILTERING || state == State.MODEL_FAILED
        private val listeners = java.util.concurrent.CopyOnWriteArraySet<() -> Unit>()
        private val main = android.os.Handler(android.os.Looper.getMainLooper())
        fun addListener(l: () -> Unit) { listeners += l }
        fun removeListener(l: () -> Unit) { listeners -= l }
        private fun publish(s: State) { state = s; main.post { listeners.forEach { it() } } }
    }

    private var projection: MediaProjection? = null
    private var worker: Thread? = null
    private var muter: SessionMuter? = null
    private var blur: ScreenBlur? = null
    @Volatile private var stop = false
    @Volatile private var stoppedBySystem = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) { stopSelf(); return START_NOT_STICKY }
        if (running) return START_NOT_STICKY
        // Android 14+: the foreground service must be running before getMediaProjection().
        startForeground(1, notification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        val code = intent?.getIntExtra(EXTRA_CODE, 0) ?: 0
        val data: Intent? = if (Build.VERSION.SDK_INT >= 33) intent?.getParcelableExtra(EXTRA_DATA, Intent::class.java)
                            else @Suppress("DEPRECATION") intent?.getParcelableExtra(EXTRA_DATA)
        if (data == null) { stopSelf(); return START_NOT_STICKY }
        val mpm = getSystemService(MediaProjectionManager::class.java)
        val mp = mpm.getMediaProjection(code, data) ?: run { stopSelf(); return START_NOT_STICKY }
        mp.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                Log.i(TAG, "projection stopped by the system")
                if (!stop) stoppedBySystem = true
                stopSelf()
            }
        }, null)
        projection = mp
        stop = false
        stoppedBySystem = false
        publish(State.STARTING)
        val settings = Settings(this)
        muter = SessionMuter(this, settings).also { it.start() }
        // Screen blur shares this projection; its virtual display must be created now (Android 14+ time limit).
        if (settings.blurOn) blur = runCatching { ScreenBlur(this, mp, settings).also { it.start() } }
            .onFailure { Log.e(TAG, "screen blur did not start", it) }.getOrNull()
        worker = Thread({ loop(mp) }, "im-filter").apply { start() }
        return START_NOT_STICKY
    }

    private fun loop(mp: MediaProjection) {
        Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
        val ch = 2
        val hop = 480  // 10 ms at 48 kHz
        val fmt = AudioFormat.Builder().setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
            .setSampleRate(Engine.SAMPLE_RATE).setChannelMask(AudioFormat.CHANNEL_IN_STEREO).build()
        val cap = AudioPlaybackCaptureConfiguration.Builder(mp)
            .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
            .addMatchingUsage(AudioAttributes.USAGE_GAME)
            .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
            .excludeUid(Process.myUid())
            .build()
        val minIn = AudioRecord.getMinBufferSize(Engine.SAMPLE_RATE, AudioFormat.CHANNEL_IN_STEREO, AudioFormat.ENCODING_PCM_FLOAT)
        val record = try {
            AudioRecord.Builder().setAudioFormat(fmt).setAudioPlaybackCaptureConfig(cap)
                .setBufferSizeInBytes(maxOf(minIn, hop * ch * 4 * 4)).build()
        } catch (e: SecurityException) { publish(State.NO_CAPTURE_PERMISSION); stopSelf(); return }
        val outFmt = AudioFormat.Builder().setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
            .setSampleRate(Engine.SAMPLE_RATE).setChannelMask(AudioFormat.CHANNEL_OUT_STEREO).build()
        val minOut = AudioTrack.getMinBufferSize(Engine.SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO, AudioFormat.ENCODING_PCM_FLOAT)
        val track = AudioTrack.Builder()
            .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE).build())
            .setAudioFormat(outFmt)
            .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)  // the only "free" latency saving
            .setTransferMode(AudioTrack.MODE_STREAM)
            .setBufferSizeInBytes(minOut)
            .build()
        val engine = Engine.open(this, ch)
        delayMs = engine.alignedLatency * 1000 / Engine.SAMPLE_RATE  // the loop uses the hop-aligned path
        publish(if (engine.failed) State.MODEL_FAILED else State.FILTERING)
        val inBuf = FloatArray(hop * ch)
        val outBuf = FloatArray(hop * ch)
        try {
            record.startRecording()
            track.play()
            while (!stop) {
                // collect exactly one hop so the engine can return it at once (hop-aligned: one hop less delay)
                var got = 0
                while (got < inBuf.size && !stop) {
                    val n = record.read(inBuf, got, inBuf.size - got, AudioRecord.READ_BLOCKING)
                    if (n < 0) break
                    got += n
                }
                if (got < inBuf.size) continue
                engine.processHops(inBuf, outBuf, 1)
                muter?.gate?.let { engine.setGate(it) }
                track.write(outBuf, 0, outBuf.size, AudioTrack.WRITE_BLOCKING)
            }
        } finally {
            runCatching { record.stop() }; record.release()
            runCatching { track.stop() }; track.release()
            engine.close()
        }
    }

    override fun onDestroy() {
        stop = true
        worker?.join(500)
        blur?.stop(); blur = null
        muter?.stop()           // un-mutes the original sessions: an explicit stop restores normal audio
        projection?.stop()
        if (state != State.NO_CAPTURE_PERMISSION) publish(if (stoppedBySystem) State.STOPPED_BY_SYSTEM else State.STOPPED)
        super.onDestroy()
    }

    private fun notification(): Notification {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(NotificationChannel(CHANNEL, getString(R.string.notif_channel), NotificationManager.IMPORTANCE_LOW))
        val stopIntent = PendingIntent.getService(this, 1, Intent(this, FilterService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE)
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        return Notification.Builder(this, CHANNEL)
            .setContentTitle(getString(R.string.notif_title))
            .setContentText(getString(R.string.notif_text))
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(getColor(R.color.primary))
            .setContentIntent(open)
            .addAction(Notification.Action.Builder(null, getString(R.string.notif_stop), stopIntent).build())
            .setOngoing(true)
            .build()
    }
}

fun Context.hasDumpPermission(): Boolean =
    checkSelfPermission(android.Manifest.permission.DUMP) == android.content.pm.PackageManager.PERMISSION_GRANTED
