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
    companion object {
        const val EXTRA_CODE = "code"
        const val EXTRA_DATA = "data"
        const val ACTION_STOP = "stop"
        private const val CHANNEL = "filter"
        private const val TAG = "IslamicMute"
        @Volatile var running = false
            private set
        @Volatile var status = "stopped"
            private set
    }

    private var projection: MediaProjection? = null
    private var worker: Thread? = null
    private var muter: SessionMuter? = null
    @Volatile private var stop = false

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
            override fun onStop() { Log.i(TAG, "projection stopped by the system"); stopSelf() }
        }, null)
        projection = mp
        running = true
        stop = false
        muter = SessionMuter(this, Settings(this)).also { it.start() }
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
        } catch (e: SecurityException) { status = "microphone/capture permission missing"; stopSelf(); return }
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
        status = if (engine.failed) "model failed to load: output muted" else "filtering (delay ${engine.latency * 1000 / Engine.SAMPLE_RATE} ms + capture)"
        val inBuf = FloatArray(hop * ch)
        val outBuf = FloatArray(hop * ch)
        try {
            record.startRecording()
            track.play()
            while (!stop) {
                val n = record.read(inBuf, 0, inBuf.size, AudioRecord.READ_BLOCKING)
                if (n <= 0) continue
                engine.process(inBuf, outBuf, n / ch)
                muter?.gate?.let { engine.setGate(it) }
                track.write(outBuf, 0, n, AudioTrack.WRITE_BLOCKING)
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
        muter?.stop()           // un-mutes the original sessions: an explicit stop restores normal audio
        projection?.stop()
        running = false
        status = "stopped"
        super.onDestroy()
    }

    private fun notification(): Notification {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(NotificationChannel(CHANNEL, "Filter", NotificationManager.IMPORTANCE_LOW))
        val stopIntent = PendingIntent.getService(this, 1, Intent(this, FilterService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE)
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        return Notification.Builder(this, CHANNEL)
            .setContentTitle("Islamic Mute is on")
            .setContentText("Instruments are being removed from all apps")
            .setSmallIcon(android.R.drawable.ic_lock_silent_mode)
            .setContentIntent(open)
            .addAction(Notification.Action.Builder(null, "Stop", stopIntent).build())
            .setOngoing(true)
            .build()
    }
}

fun Context.hasDumpPermission(): Boolean =
    checkSelfPermission(android.Manifest.permission.DUMP) == android.content.pm.PackageManager.PERMISSION_GRANTED
