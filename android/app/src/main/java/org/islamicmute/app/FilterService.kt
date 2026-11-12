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
    override fun attachBaseContext(base: android.content.Context) { super.attachBaseContext(Lang.wrap(base)) }

    /** What the screen shows. Published on the main thread to the companion's listeners. */
    enum class State {
        STOPPED, STARTING, FILTERING, MODEL_FAILED, NO_CAPTURE_PERMISSION, STOPPED_BY_SYSTEM,
        /** Android refused the screen-capture token, or stopped handing over the other apps' sound. */
        CAPTURE_FAILED,
    }

    /** Live numbers of the running filter, for the screen and the diagnostics report. Null when stopped. */
    data class Health(
        val model: String, val mono: Boolean, val tooSlow: Boolean,
        val avgHopMs: Double, val maxHopMs: Double, val overallAvgMs: Double, val peakHopMs: Double,
        val lateShare: Double, val lateHops: Long, val busyHops: Long, val hops: Long,
        val underruns: Int, val extraBufferHops: Int, val trimmedHops: Int, val keepHops: Int, val bufferedMs: Int,
        val bufferFrames: Int, val bufferCapacityFrames: Int, val minBufferFrames: Int,
        val readErrors: Int, val captureDb: Int, val engineErrors: Long,
        /** Share of the time the women's-singing filter muted the sound (0..1), -1 when it is off. */
        val gateShare: Double,
        val muter: SessionMuter.Info?,
    )

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
        @Volatile var health: Health? = null
            private set
        /** The original sound of other apps is being silenced (the one-time setup is done and works). */
        @Volatile var muterStatus: SessionMuter.Status = SessionMuter.Status.NO_PERMISSION
            private set
        /** Apps playing now whose sound cannot be filtered (they refuse capture). */
        @Volatile var blockedApps: List<String> = emptyList()
            private set
        private val listeners = java.util.concurrent.CopyOnWriteArraySet<() -> Unit>()
        private val main = android.os.Handler(android.os.Looper.getMainLooper())
        fun addListener(l: () -> Unit) { listeners += l }
        fun removeListener(l: () -> Unit) { listeners -= l }
        private fun publish(s: State) { state = s; notifyListeners() }
        private fun notifyListeners() { main.post { listeners.forEach { it() } } }
    }

    private var projection: MediaProjection? = null
    private var worker: Thread? = null
    private var muter: SessionMuter? = null
    private var blur: ScreenBlur? = null
    @Volatile private var stop = false
    @Volatile private var stoppedBySystem = false
    /** Set by the audio thread when it gives up: the state to show after the service has stopped. */
    @Volatile private var failState: State? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) { stopSelf(); return START_NOT_STICKY }
        if (running) return START_NOT_STICKY
        // Android 14+: the foreground service must be running before getMediaProjection().
        startForeground(1, notification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        val code = intent?.getIntExtra(EXTRA_CODE, 0) ?: 0
        val data: Intent? = if (Build.VERSION.SDK_INT >= 33) intent?.getParcelableExtra(EXTRA_DATA, Intent::class.java)
                            else @Suppress("DEPRECATION") intent?.getParcelableExtra(EXTRA_DATA)
        failState = null
        if (data == null) { failState = State.CAPTURE_FAILED; stopSelf(); return START_NOT_STICKY }
        val mpm = getSystemService(MediaProjectionManager::class.java)
        val mp = runCatching { mpm.getMediaProjection(code, data) }
            .onFailure { Log.e(TAG, "no screen-capture token", it) }.getOrNull()
            ?: run { failState = State.CAPTURE_FAILED; stopSelf(); return START_NOT_STICKY }
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
        muter = SessionMuter(this, settings).also { m ->
            m.onChange = { muterChanged(m) }
            m.start()
            muterChanged(m)
        }
        // the first notification was built before the muter existed: now it can say whether originals are silenced
        runCatching { getSystemService(NotificationManager::class.java).notify(1, notification()) }
        // Screen blur shares this projection; its virtual display must be created now (Android 14+ time limit),
        // so it starts parked even when the blur is off and follows the settings live.
        blur = runCatching { ScreenBlur(this, mp, settings).also { it.start() } }
            .onFailure { Log.e(TAG, "screen blur did not start", it) }.getOrNull()
        worker = Thread({ loop(mp) }, "im-filter").apply { start() }
        return START_NOT_STICKY
    }

    /** The muter's state for the screen and the notification; app names instead of uids. */
    private fun muterChanged(m: SessionMuter) {
        val before = muterStatus to blockedApps
        muterStatus = m.status
        blockedApps = m.blockedUids.mapNotNull { uid ->
            runCatching {
                val pkg = packageManager.getPackagesForUid(uid)?.firstOrNull() ?: return@runCatching null
                packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
            }.getOrNull()
        }.distinct().sorted()
        if (before != muterStatus to blockedApps) {
            runCatching { getSystemService(NotificationManager::class.java).notify(1, notification()) }
            notifyListeners()
        }
    }

    private fun loop(mp: MediaProjection) {
        Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
        val ch = 2
        val hop = 480  // 10 ms at 48 kHz
        val frameBytes = ch * 4
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
                .setBufferSizeInBytes(maxOf(minIn, hop * frameBytes * 4)).build()
        } catch (e: SecurityException) { publish(State.NO_CAPTURE_PERMISSION); stopSelf(); return
        } catch (e: Exception) { Log.e(TAG, "capture did not open", e); failState = State.CAPTURE_FAILED; stopSelf(); return }
        val outFmt = AudioFormat.Builder().setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
            .setSampleRate(Engine.SAMPLE_RATE).setChannelMask(AudioFormat.CHANNEL_OUT_STEREO).build()
        val minOut = AudioTrack.getMinBufferSize(Engine.SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO, AudioFormat.ENCODING_PCM_FLOAT)
        val minOutFrames = minOut / frameBytes
        val track = AudioTrack.Builder()
            .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE).build())
            .setAudioFormat(outFmt)
            .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)  // the only "free" latency saving
            .setTransferMode(AudioTrack.MODE_STREAM)
            // room to grow (LoadMonitor.GROW_BUFFER); the size in use starts at the minimum, as before
            .setBufferSizeInBytes(minOut + LoadMonitor.MAX_EXTRA_HOPS * hop * frameBytes)
            .build()
        runCatching { track.setBufferSizeInFrames(minOutFrames) }
        val settings = Settings(this)
        val engine = Engine.open(this, ch)
        // a phone that needed mono last time starts in mono: no second round of cuts
        val monitor = LoadMonitor(hopMs = hop * 1000.0 / Engine.SAMPLE_RATE, mono = settings.audioMono, hopFrames = hop)
        if (monitor.mono) engine.setMono(true)
        delayMs = engine.alignedLatency * 1000 / Engine.SAMPLE_RATE  // the loop uses the hop-aligned path
        publish(if (engine.failed) State.MODEL_FAILED else State.FILTERING)
        // Android 12+: tells the scheduler this thread has 10 ms deadlines, so it gets a fast core at a high clock
        val hint = if (Build.VERSION.SDK_INT >= 31) runCatching {
            getSystemService(android.os.PerformanceHintManager::class.java)
                ?.createHintSession(intArrayOf(Process.myTid()), hop * 1_000_000_000L / Engine.SAMPLE_RATE)
        }.getOrNull() else null
        var policy = Engine.policy(settings)
        var hops = 0
        var written = 0L          // frames written to the track
        var readErrors = 0
        var readErrorsInARow = 0
        var gateOn = 0; var gateSamples = 0
        var lastReport = android.os.SystemClock.elapsedRealtime()
        var lastLog = lastReport
        var peak = 0f             // capture level over the report interval
        var captureDb = -120
        val inBuf = FloatArray(hop * ch)
        val outBuf = FloatArray(hop * ch)
        fun report() {
            val buffered = (written - (track.playbackHeadPosition.toLong() and 0xFFFFFFFFL)).coerceAtLeast(0)
            health = Health(
                model = engine.modelName, mono = monitor.mono, tooSlow = monitor.tooSlow,
                avgHopMs = monitor.avgMs, maxHopMs = monitor.maxMs, overallAvgMs = monitor.overallAvgMs,
                peakHopMs = monitor.peakMs, lateShare = monitor.lateShare, lateHops = monitor.lateHops,
                busyHops = monitor.busyHops, hops = monitor.hops, underruns = monitor.underruns,
                extraBufferHops = monitor.extraHops, trimmedHops = monitor.trimmedHops, keepHops = monitor.keepHops,
                bufferedMs = (buffered * 1000 / Engine.SAMPLE_RATE).toInt(),
                bufferFrames = track.bufferSizeInFrames, bufferCapacityFrames = track.bufferCapacityInFrames,
                minBufferFrames = minOutFrames, readErrors = readErrors, captureDb = captureDb,
                engineErrors = engine.runErrors,
                gateShare = if (policy == 0) -1.0 else if (gateSamples == 0) 0.0 else gateOn.toDouble() / gateSamples,
                muter = muter?.info())
        }
        report()
        try {
            record.startRecording()
            track.play()
            while (!stop) {
                // collect exactly one hop so the engine can return it at once (hop-aligned: one hop less delay)
                var got = 0
                while (got < inBuf.size && !stop) {
                    val n = record.read(inBuf, got, inBuf.size - got, AudioRecord.READ_BLOCKING)
                    if (n < 0) {
                        // the capture is gone (projection revoked, audio server restarted): say so instead of
                        // staying "on" with no sound
                        readErrors++
                        Log.w(TAG, "capture read failed: $n")
                        if (n == AudioRecord.ERROR_DEAD_OBJECT || ++readErrorsInARow >= 20) {
                            failState = State.CAPTURE_FAILED; stopSelf(); return
                        }
                        Thread.sleep(10)
                        continue
                    }
                    readErrorsInARow = 0
                    got += n
                }
                if (got < inBuf.size) continue
                if (++hops % 50 == 0) {  // every 0.5 s: settings changed in the app apply live
                    val p = Engine.policy(settings)
                    if (p != policy) { policy = p; engine.setPolicy(p); gateOn = 0; gateSamples = 0 }
                    if (policy != 0) { gateSamples++; if (engine.detectorStatus() == 1) gateOn++ }
                }
                for (x in inBuf) { val a = if (x < 0) -x else x; if (a > peak) peak = a }
                val t0 = System.nanoTime()
                engine.processHops(inBuf, outBuf, 1)
                val work = System.nanoTime() - t0
                hint?.let { h -> runCatching { h.reportActualWorkDuration(work.coerceAtLeast(1)) } }
                muter?.gate?.let { engine.setGate(it) }
                // delay that is no longer needed is given back by skipping one hop that holds no sound
                if (!monitor.takeTrim(isSilent(outBuf))) {
                    track.write(outBuf, 0, outBuf.size, AudioTrack.WRITE_BLOCKING)
                    written += hop
                }
                val fill = (written - (track.playbackHeadPosition.toLong() and 0xFFFFFFFFL)).toInt()
                when (monitor.hop(work, track.underrunCount, fill)) {
                    LoadMonitor.Action.GO_MONO -> {
                        engine.setMono(true)
                        settings.audioMono = true
                        Log.i(TAG, "filter: hops take %.1f ms, now mixing to mono".format(java.util.Locale.ROOT, monitor.avgMs))
                        report(); notifyListeners()
                    }
                    LoadMonitor.Action.GROW_BUFFER -> runCatching {
                        track.setBufferSizeInFrames(minOutFrames + monitor.extraHops * hop)
                    }
                    LoadMonitor.Action.NONE -> {}
                }
                // the report follows the clock, not the hop count: on a slow phone 200 hops can take 20 s
                val now = android.os.SystemClock.elapsedRealtime()
                if (now - lastReport >= 2000) {
                    lastReport = now
                    val wasSlow = health?.tooSlow == true
                    captureDb = if (peak <= 1e-6f) -120 else (20 * Math.log10(peak.toDouble())).toInt()
                    peak = 0f
                    report()
                    if (wasSlow != monitor.tooSlow) {
                        runCatching { getSystemService(NotificationManager::class.java).notify(1, notification()) }
                        notifyListeners()
                    }
                    if (now - lastLog >= 10_000) health?.let { h ->  // for adb logcat and android/tools/emu_check.py
                        lastLog = now
                        Log.i(TAG, ("stats: hop avg %.1f max %.1f ms, late %.0f%%, underruns %d, buffered %d ms, " +
                            "mono %b, slow %b, capture %d dB, muter %s").format(java.util.Locale.ROOT, h.avgHopMs, h.maxHopMs,
                            h.lateShare * 100, h.underruns, h.bufferedMs, h.mono, h.tooSlow, h.captureDb, muterStatus))
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "filter loop failed", e)
            failState = State.CAPTURE_FAILED
            stopSelf()
        } finally {
            runCatching { hint?.close() }
            runCatching { record.stop() }; record.release()
            runCatching { track.stop() }; track.release()
            engine.close()
        }
    }

    private fun isSilent(buf: FloatArray): Boolean {
        for (x in buf) if (x > 1e-4f || x < -1e-4f) return false
        return true
    }

    override fun onDestroy() {
        stop = true
        worker?.join(500)
        blur?.stop(); blur = null
        muter?.stop()           // un-mutes the original sessions: an explicit stop restores normal audio
        projection?.stop()
        health = null
        muterStatus = SessionMuter.Status.NO_PERMISSION
        blockedApps = emptyList()
        if (state != State.NO_CAPTURE_PERMISSION)
            publish(failState ?: if (stoppedBySystem) State.STOPPED_BY_SYSTEM else State.STOPPED)
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
            .setContentText(getString(when {
                health?.tooSlow == true -> R.string.notif_too_slow
                muter != null && muterStatus == SessionMuter.Status.NO_PERMISSION -> R.string.notif_not_muted
                muterStatus == SessionMuter.Status.FAILING -> R.string.notif_mute_failing
                else -> R.string.notif_text
            }))
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
