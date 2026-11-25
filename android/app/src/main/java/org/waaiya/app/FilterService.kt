package org.waaiya.app

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
        /**
         * Android ended filtering (not the user) and [Settings.holdSilence] is on: nothing is filtered, but the
         * service keeps running only to keep the other apps' original sound muted, until the user starts again
         * (the muter is kept, so there is no gap) or taps Stop.
         */
        SILENCED,
    }

    /** Live numbers of the running filter, for the screen and the diagnostics report. Null when stopped. */
    data class Health(
        val model: String, val mono: Boolean, val tooSlow: Boolean,
        /** Mono although the user chose stereo: this phone is too slow for stereo (now or within the last week). */
        val monoForSpeed: Boolean,
        val avgHopMs: Double, val maxHopMs: Double, val overallAvgMs: Double, val peakHopMs: Double,
        val lateShare: Double, val lateHops: Long, val busyHops: Long, val hops: Long,
        val underruns: Int, val extraBufferHops: Int, val trimmedHops: Int, val keepHops: Int, val bufferedMs: Int,
        /** Hops of silence added (LoadMonitor.takePad); sound waiting in the capture, ms (-1: Android does not say). */
        val paddedHops: Int, val captureWaitingMs: Int,
        val bufferFrames: Int, val bufferCapacityFrames: Int, val minBufferFrames: Int,
        val readErrors: Int, val captureDb: Int, val engineErrors: Long,
        /** Share of the time the women's-singing filter muted the sound (0..1), -1 when it is off. */
        val gateShare: Double,
        val muter: SessionMuter.Info?,
        /** The running engine is the keep-singing model (voice_v1, setting keep_singing). */
        val keepSinging: Boolean = false,
        /** Android gives the capture zeros now (AudioRecordingConfiguration.isClientSilenced), how often, how long. */
        val captureSilenced: Boolean = false, val silencedTimes: Int = 0, val silencedSec: Long = 0,
        /** Seconds since the capture started, and the longest wait for one hop of captured sound (ms), with the count
         *  of waits over [GAP_MS]: a capture that stops delivering (not silenced, just nothing) shows here. */
        val runningSec: Long = 0, val longestGapMs: Long = 0, val gaps: Int = 0,
    )

    companion object {
        /** Capture buffer, in hops: room for clock drift to gather before LoadMonitor gives it back. */
        const val CAPTURE_HOPS = 20
        /** An output hop under this peak holds no sound; under QUIET_PEAK (-60 dBFS) it is quiet enough to skip
         *  or pad next to when no silent hop came for a while (LoadMonitor.QUIET_AFTER_HOPS). */
        const val SILENT_PEAK = 1e-4f
        const val QUIET_PEAK = 1e-3f
        const val EXTRA_CODE = "code"
        const val EXTRA_DATA = "data"
        const val ACTION_STOP = "stop"
        /** Debug builds only: ends the capture as Android does (adb shell am broadcast -a <this> -p <package>),
         *  to test what follows without a way to make Android itself stop it. */
        const val ACTION_DEBUG_END_CAPTURE = "org.waaiya.app.DEBUG_END_CAPTURE"
        const val ACTION_DEBUG_COVERS = "org.waaiya.app.DEBUG_COVERS"
        const val ACTION_DEBUG_FAIL_BLUR = "org.waaiya.app.DEBUG_FAIL_BLUR"
        /** Debug builds: the notification's Stop, for tests while another app stays in front. */
        const val ACTION_DEBUG_STOP = "org.waaiya.app.DEBUG_STOP"
        private const val CHANNEL = "filter"
        private const val CHANNEL_SILENCED = "silenced"
        private const val TAG = "IslamicMute"
        @Volatile var state = State.STOPPED
            private set
        /** Engine delay of the running filter in ms (model look-ahead; the capture/playback buffers add to it). */
        @Volatile var delayMs = 0
            private set
        /** This filtering started with "Share one app" offered (CaptureChoice): no blur until the next start. */
        @Volatile var oneAppSession = false
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

        /** The running service, for [refreshNotification]. */
        @Volatile private var instance: java.lang.ref.WeakReference<FilterService>? = null

        /** Diagnostics: the uids the running capture leaves out (apps heard unfiltered), and a list whose capture
         *  did not open (the old capture goes on: those apps stay filtered). Null when not capturing. */
        @Volatile var captureExcluded: Set<Int>? = null
            private set
        @Volatile var captureExcludeFailed: Set<Int>? = null
            private set

        /** A new capture is on its way ([restartForNotificationText]): TileStartActivity asks for it although the
         *  state says STARTING. */
        @Volatile var restartPending = false
            private set
        private const val RESTART_TIMEOUT_MS = 6000L
        /** A wait this long for one hop of captured sound is recorded (StopLog, Health.gaps). */
        private const val GAP_MS = 3000L

        /**
         * Notification text ([ScreenShareProtection]): Android reads its switch only when a capture starts, so a
         * change made while filtering used to wait for the next start. This starts a new capture now instead: the
         * capture, the filter and the blur end while the muter keeps the other apps silent (no music in between, as
         * in SILENCED), then [TileStartActivity] gets a new capture, which Android grants without asking after the
         * setup (PROJECT_MEDIA), and the switch is applied to it. Main thread. Returns the intent the caller must
         * start (the tile, or the app's screen: a service may not open activities from the background), or null
         * when the running capture already matches, or when a new one could not come without Android asking (no
         * PROJECT_MEDIA: there Waaiya lifts the protection while filtering anyway) or without the music coming back.
         * No new capture within RESTART_TIMEOUT_MS: the other apps stay muted (SILENCED) until the user starts.
         */
        fun restartForNotificationText(ctx: Context): Intent? {
            val s = instance?.get() ?: return null
            val shown = ScreenShareProtection.shownInCapture ?: return null
            if (!running || restartPending || !ScreenShareProtection.supported || !ctx.hasProjectMediaAppOp()) return null
            val after = ScreenShareProtection.protectionOff(ctx) ||
                (ScreenShareProtection.wanted(ctx) && ScreenShareProtection.canWrite(ctx))
            if (after == shown || !s.holdForRestart()) return null
            return Intent(ctx, TileStartActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        /** Builds the notification again (its fix actions changed: FixMistakes). Any thread; nothing once stopped. */
        fun refreshNotification() { main.post { instance?.get()?.updateNotification() } }

        /**
         * The filter's notification is in a group of its own. Android groups two or more notifications of one app
         * under one summary, and while the screen is captured Android 15+ hides that summary and all under it: only a
         * foreground service's notification is left visible. On its own, Stop stays visible and usable.
         */
        private const val GROUP = "filter"
        private fun notifyListeners() { main.post { listeners.forEach { it() } } }
    }

    private var projection: MediaProjection? = null
    private var worker: Thread? = null
    private var muter: SessionMuter? = null
    private var blur: ScreenBlur? = null
    @Volatile private var stop = false
    /** The capture session now running: a restart (notification text) or a new start makes a new one, and a late
     *  callback of the old projection or the old filter thread (a blocked read outlives the 500 ms join) only acts
     *  on its own session, never on the next. */
    @Volatile private var session = 0
    @Volatile private var stoppedBySystem = false
    /** Set by the audio thread when it gives up: the state to show after the service has stopped. */
    @Volatile private var failState: State? = null
    /** Main thread: filtering ended by itself and the originals are kept muted (State.SILENCED). */
    private var holding = false
    /** The kept-silent notification already popped up once for this hold. */
    private var silencedShown = false
    private var debugReceiver: android.content.BroadcastReceiver? = null

    override fun onCreate() {
        super.onCreate()
        instance = java.lang.ref.WeakReference(this)
        if (BuildConfig.DEBUG) {
            val r = object : android.content.BroadcastReceiver() {
                override fun onReceive(c: Context?, i: Intent?) {
                    when (i?.action) {
                        ACTION_DEBUG_END_CAPTURE -> { Log.i(TAG, "debug: ending the capture as Android would"); projection?.stop() }
                        // --es covers "x0,y0,x1,y1,kind;..." (0..1 of the screen), or no extra to go back to detections
                        ACTION_DEBUG_COVERS -> ScreenBlur.debugCovers = i.getStringExtra("covers")?.split(';')
                            ?.flatMap { c -> c.split(',').map { it.trim().toFloat() } }?.toFloatArray()
                        // --ez fail true: the next blur start cannot create its capture
                        ACTION_DEBUG_FAIL_BLUR -> ScreenBlur.debugFailCapture = i.getBooleanExtra("fail", true)
                        // through the same guard as the notification's Stop (Protection)
                        ACTION_DEBUG_STOP -> Protection.stopOrAsk(this@FilterService)?.let {
                            runCatching { startActivity(it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
                        }
                    }
                }
            }
            debugReceiver = r
            val f = android.content.IntentFilter(ACTION_DEBUG_END_CAPTURE).apply {
                addAction(ACTION_DEBUG_COVERS); addAction(ACTION_DEBUG_FAIL_BLUR); addAction(ACTION_DEBUG_STOP)
            }
            if (Build.VERSION.SDK_INT >= 33) registerReceiver(r, f, Context.RECEIVER_EXPORTED)
            else @Suppress("UnspecifiedRegisterReceiverFlag") registerReceiver(r, f)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) { stopSelf(); return START_NOT_STICKY }
        if (running && !holding) return START_NOT_STICKY
        restartPending = false
        // Starting again from SILENCED: the muter keeps running throughout, so the originals never come back.
        val wasHolding = holding
        holding = false
        // Android 14+: the foreground service must be running before getMediaProjection().
        startForeground(1, notification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        val code = intent?.getIntExtra(EXTRA_CODE, 0) ?: 0
        val data: Intent? = if (Build.VERSION.SDK_INT >= 33) intent?.getParcelableExtra(EXTRA_DATA, Intent::class.java)
                            else @Suppress("DEPRECATION") intent?.getParcelableExtra(EXTRA_DATA)
        failState = null
        runCatching { getSystemService(NotificationManager::class.java).cancel(3) }  // an old "stopped" notice
        if (data == null) { noCapture(wasHolding); return START_NOT_STICKY }
        // Before the capture starts: Android 15+ decides at the start whether notifications are hidden during it.
        ScreenShareProtection.apply(this)
        val mpm = getSystemService(MediaProjectionManager::class.java)
        val mp = runCatching { mpm.getMediaProjection(code, data) }
            .onFailure { Log.e(TAG, "no screen-capture token", it) }.getOrNull()
            ?: run { noCapture(wasHolding); return START_NOT_STICKY }
        val my = ++session
        mp.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                if (stop || my != session) return  // our own stop (the user's, SILENCED), or an older session's
                Log.i(TAG, "projection stopped by the system")
                StopLog.record(this@FilterService, "screen capture stopped by Android")
                endedBySystem(null, my)
            }
        }, null)
        projection = mp
        stop = false
        stoppedBySystem = false
        publish(State.STARTING)
        val settings = Settings(this)
        if (settings.simpleMode && muter == null) {
            // Simple mode (test): the media mute silences the originals; no muter, the setup is not needed
            SimpleMode.begin(this)
            muterStatus = SessionMuter.Status.OK
            notifyListeners()
        } else muter = (muter ?: SessionMuter(this, settings).also { m ->
            m.onChange = { muterChanged(m) }
            m.start()
        }).also { muterChanged(it) }
        // the first notification was built before the muter existed: now it can say whether originals are silenced
        runCatching { getSystemService(NotificationManager::class.java).notify(1, notification()) }
        // Screen blur shares this projection; its virtual display must be created now (Android 14+ time limit),
        // so it starts parked even when the blur is off and follows the settings live. Not when the question offered
        // "Share one app" (CaptureChoice): the capture may hold Waaiya alone, and a blur that sees nothing would
        // cover nothing; turning the blur on then asks for a restart (blurNeedsRestart).
        oneAppSession = CaptureChoice.offerOneApp(this)
        blur = if (oneAppSession) null else runCatching { ScreenBlur(this, mp, settings).also { it.start() } }
            .onFailure { Log.e(TAG, "screen blur did not start", it) }.getOrNull()
        worker = Thread({ loop(mp, my) }, "im-filter").apply { start() }
        return START_NOT_STICKY
    }

    /** No capture at start: back to the silence that was kept, or (first start) stop with the reason. */
    private fun noCapture(wasHolding: Boolean) {
        ScreenShareProtection.captureEnded(this)  // it may have been turned off for this start: no capture came
        if (wasHolding) { holding = true; publish(State.SILENCED); updateNotification() }
        else { failState = State.CAPTURE_FAILED; stopSelf() }
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
            updateNotification()
            notifyListeners()
        }
    }

    private fun updateNotification() {
        runCatching { getSystemService(NotificationManager::class.java).notify(1, notification()) }
    }

    /**
     * Android ended filtering: the projection stopped, or the capture died or failed. [fail] = the state to show
     * (null: STOPPED_BY_SYSTEM). By default ([Settings.holdSilence]) the other apps stay muted: the capture, the
     * filter and the blur end, but this service and its muter keep running (State.SILENCED) until the user starts
     * again or taps Stop. Otherwise, or without the setup (nothing can be muted), the service stops and the
     * original sound comes back, with the "stopped" notification. Any thread.
     *
     * Foreground service type: the service stays in the foreground under the mediaProjection type it was started
     * with; the notification is only updated (notify), never re-posted with startForeground, which would check the
     * type's conditions again (a projection that no longer exists). Checked on the API 35 emulator: the service
     * stays foreground with the projection gone. dataSync and shortService would bring a time limit, and
     * mediaPlayback would claim playback this service does not do.
     */
    private fun endedBySystem(fail: State?, from: Int) = main.post {
        if (stop || holding || from != session) return@post
        val m = muter
        val canHold = SimpleMode.active || (m != null && m.status != SessionMuter.Status.NO_PERMISSION)
        if (!Settings(this).holdSilence || !canHold) {
            if (fail != null) failState = fail else stoppedBySystem = true
            stopSelf()
            return@post
        }
        Log.i(TAG, "filtering ended by Android (${fail ?: State.STOPPED_BY_SYSTEM}): other apps stay muted")
        stop = true
        blur?.stop(); blur = null
        projection?.stop(); projection = null  // first: a read blocked on a quiet capture returns
        worker?.join(500); worker = null
        health = null
        holding = true
        silencedShown = false  // a new hold: pop up again
        ScreenShareProtection.captureEnded(this)  // no capture any more
        publish(State.SILENCED)
        updateNotification()
    }

    /** [restartForNotificationText]: the capture ends, the other apps stay muted, a new capture is awaited. */
    private fun holdForRestart(): Boolean {
        if (stop || holding) return false
        val m = muter
        if (!SimpleMode.active && (m == null || m.status == SessionMuter.Status.NO_PERMISSION)) return false
        Log.i(TAG, "filter: a new capture for the notification-text choice; other apps stay muted meanwhile")
        restartPending = true
        stop = true
        blur?.stop(); blur = null
        projection?.stop(); projection = null  // first: a read blocked on a quiet capture returns
        worker?.join(500); worker = null
        health = null
        holding = true
        silencedShown = true  // no "stopped" pop-up: it starts again at once
        ScreenShareProtection.captureEnded(this)
        publish(State.STARTING)
        main.postDelayed({
            if (holding && restartPending) {
                Log.w(TAG, "filter: no new capture came; other apps stay muted")
                restartPending = false
                publish(State.SILENCED)
                updateNotification()
            }
        }, RESTART_TIMEOUT_MS)
        return true
    }

    private fun loop(mp: MediaProjection, my: Int) {
        Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
        val ch = 2
        val hop = 480  // 10 ms at 48 kHz
        val frameBytes = ch * 4
        val fmt = AudioFormat.Builder().setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
            .setSampleRate(Engine.SAMPLE_RATE).setChannelMask(AudioFormat.CHANNEL_IN_STEREO).build()
        val minIn = AudioRecord.getMinBufferSize(Engine.SAMPLE_RATE, AudioFormat.CHANNEL_IN_STEREO, AudioFormat.ENCODING_PCM_FLOAT)
        // Apps the user chose to hear unfiltered (FixMistakes, setting filter_off_apps) are left out of the capture
        // (SessionMuter leaves their original alone too). Android fixes a capture's excluded uids when it is built.
        fun openRecord(excluded: Set<Int>): AudioRecord {
            val cap = AudioPlaybackCaptureConfiguration.Builder(mp)
                .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                .addMatchingUsage(AudioAttributes.USAGE_GAME)
                .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
                .excludeUid(Process.myUid())
                .apply { excluded.forEach { excludeUid(it) } }
                .build()
            return AudioRecord.Builder().setAudioFormat(fmt).setAudioPlaybackCaptureConfig(cap)
                // room for clock drift to gather while LoadMonitor gives it back (no delay unless it is used)
                .setBufferSizeInBytes(maxOf(minIn, hop * frameBytes * CAPTURE_HOPS)).build()
        }
        var excluded = FixMistakes.filterOffUids(this, Settings(this))
        var excludeFailed: Set<Int>? = null
        captureExcluded = excluded; captureExcludeFailed = null
        var record = try {
            openRecord(excluded)
        } catch (e: SecurityException) { publish(State.NO_CAPTURE_PERMISSION); stopSelf(); return
        } catch (e: Exception) {
            Log.e(TAG, "capture did not open", e)
            StopLog.record(this, "capture did not open: ${e.javaClass.simpleName}")
            // Android before 16 (or a phone like it): no sound from a one-app share. Ask for the entire screen next time.
            if (oneAppSession && e is UnsupportedOperationException) Settings(this).oneAppRefused = true
            endedBySystem(State.CAPTURE_FAILED, my); return
        }
        val outFmt = AudioFormat.Builder().setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
            .setSampleRate(Engine.SAMPLE_RATE).setChannelMask(AudioFormat.CHANNEL_OUT_STEREO).build()
        val minOut = AudioTrack.getMinBufferSize(Engine.SAMPLE_RATE, AudioFormat.CHANNEL_OUT_STEREO, AudioFormat.ENCODING_PCM_FLOAT)
        val minOutFrames = minOut / frameBytes
        fun makeTrack() = AudioTrack.Builder()
            // simple mode (test): another channel, media is muted while it filters
            .setAudioAttributes(AudioAttributes.Builder()
                .setUsage(if (SimpleMode.active) SimpleMode.usage(this) else AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE).build())
            .setAudioFormat(outFmt)
            .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)  // the only "free" latency saving
            .setTransferMode(AudioTrack.MODE_STREAM)
            // room to grow (LoadMonitor.GROW_BUFFER); the size in use starts at the minimum, as before
            .setBufferSizeInBytes(minOut + LoadMonitor.MAX_EXTRA_HOPS * hop * frameBytes)
            .build()
            .also { t -> runCatching { t.setBufferSizeInFrames(minOutFrames) } }
        // Before the loop's own try: a failure here (no output, no room to copy the model) must end filtering with
        // the reason, the other apps kept silent, never end the app (and so give the music back) with it
        var track = try { makeTrack() } catch (e: Exception) {
            Log.e(TAG, "output did not open", e)
            StopLog.record(this, "output did not open: ${e.javaClass.simpleName}")
            runCatching { record.release() }
            endedBySystem(State.CAPTURE_FAILED, my); return
        }
        var trackRebuilds = 0      // the output died and was made again (audio server restart, route change)
        var lastRebuild = 0L
        val settings = Settings(this)
        // Always created with one model instance per channel, then switched to mono: only such an engine can go
        // back to stereo, so the user's mono / stereo choice applies live in both directions.
        // Keep singing (setting keep_singing, a test): the voice_v1 model instead of the default one; a change while
        // filtering loads the other model on a helper thread while this one keeps filtering, then swaps (no gap
        // beyond the new model's own delay). A model that does not load runs silent (MODEL_FAILED), never unfiltered.
        var singing = settings.keepSinging
        var engine = try { Engine.open(this, ch, singing = singing) } catch (e: Exception) {
            Log.e(TAG, "engine did not open", e)
            StopLog.record(this, "engine did not open: ${e.javaClass.simpleName}")
            runCatching { track.release() }; runCatching { record.release() }
            endedBySystem(State.MODEL_FAILED, my); return
        }
        val swapLock = Object()
        var loaded: Pair<Engine, Boolean>? = null  // swapLock: the engine the helper thread made, and its model choice
        var loopDone = false                       // swapLock: the loop has ended, a late engine closes itself
        var loading = false                        // audio thread: a helper thread is loading a model
        // Mono unless the user chose stereo; a phone that needed mono last time starts in mono: no second round of cuts
        var stereoChosen = settings.audioStereo
        val monitor = LoadMonitor(hopMs = hop * 1000.0 / Engine.SAMPLE_RATE, mono = !stereoChosen || settings.audioMono,
            hopFrames = hop)
        if (monitor.mono) engine.setMono(true)
        delayMs = engine.alignedLatency * 1000 / Engine.SAMPLE_RATE  // the loop uses the hop-aligned path
        publish(if (engine.failed) State.MODEL_FAILED else State.FILTERING); if (engine.failed) updateNotification()
        // Android 12+: tells the scheduler this thread has 10 ms deadlines, so it gets a fast core at a high clock
        val hint = if (Build.VERSION.SDK_INT >= 31) runCatching {
            getSystemService(android.os.PerformanceHintManager::class.java)
                ?.createHintSession(intArrayOf(Process.myTid()), hop * 1_000_000_000L / Engine.SAMPLE_RATE)
        }.getOrNull() else null
        var policy = Engine.policy(settings)
        var hops = 0
        var written = 0L          // frames written to the track
        var framesRead = 0L       // frames read from the capture since it started
        var backlog = -1          // frames captured but not read yet (-1: unknown)
        val stamp = android.media.AudioTimestamp()
        val silence = FloatArray(hop * ch)
        var readErrors = 0
        var readErrorsInARow = 0
        var gateOn = 0; var gateSamples = 0
        var lastReport = android.os.SystemClock.elapsedRealtime()
        val loopStart = lastReport
        // Android may keep the capture running but give it zeros (a silenced client), for example when a phone limits
        // an app at screen lock: the originals are muted and the filtered copy is silence. Watched every 0.5 s.
        var silenced = false; var silencedTimes = 0; var silencedMs = 0L; var silencedAt = 0L
        var longestGapMs = 0L; var gaps = 0
        var lastLog = lastReport
        var peak = 0f             // capture level over the report interval
        var captureDb = -120
        val inBuf = FloatArray(hop * ch)
        val outBuf = FloatArray(hop * ch)
        fun report() {
            if (SimpleMode.active) SimpleMode.routed = track.routedDevice
            val buffered = (written - (track.playbackHeadPosition.toLong() and 0xFFFFFFFFL)).coerceAtLeast(0)
            health = Health(
                model = engine.modelName, mono = monitor.mono, tooSlow = monitor.tooSlow,
                monoForSpeed = monitor.mono && stereoChosen,
                avgHopMs = monitor.avgMs, maxHopMs = monitor.maxMs, overallAvgMs = monitor.overallAvgMs,
                peakHopMs = monitor.peakMs, lateShare = monitor.lateShare, lateHops = monitor.lateHops,
                busyHops = monitor.busyHops, hops = monitor.hops, underruns = monitor.underruns,
                extraBufferHops = monitor.extraHops, trimmedHops = monitor.trimmedHops, keepHops = monitor.keepHops,
                paddedHops = monitor.paddedHops,
                captureWaitingMs = if (backlog < 0) -1 else backlog * 1000 / Engine.SAMPLE_RATE,
                bufferedMs = (buffered * 1000 / Engine.SAMPLE_RATE).toInt(),
                bufferFrames = track.bufferSizeInFrames, bufferCapacityFrames = track.bufferCapacityInFrames,
                minBufferFrames = minOutFrames, readErrors = readErrors, captureDb = captureDb,
                captureSilenced = silenced, silencedTimes = silencedTimes,
                silencedSec = (silencedMs + if (silenced) android.os.SystemClock.elapsedRealtime() - silencedAt else 0) / 1000,
                runningSec = (android.os.SystemClock.elapsedRealtime() - loopStart) / 1000,
                longestGapMs = longestGapMs, gaps = gaps,
                engineErrors = engine.runErrors,
                gateShare = if (policy == 0) -1.0 else if (gateSamples == 0) 0.0 else gateOn.toDouble() / gateSamples,
                muter = muter?.info(), keepSinging = singing)
            Diagnostics.power?.noteRun(engine.modelName, monitor.mono)
        }
        Diagnostics.filterStarted(this)
        report()
        var simpleGain = -1f
        try {
            record.startRecording()
            track.play()
            while (!stop && my == session) {
                if (SimpleMode.active) {  // simple mode: the volume keys set this track's gain
                    val g = SimpleMode.gain
                    if (g != simpleGain) { track.setVolume(g); simpleGain = g }
                }
                // collect exactly one hop so the engine can return it at once (hop-aligned: one hop less delay)
                var got = 0
                val waitFrom = android.os.SystemClock.elapsedRealtime()
                while (got < inBuf.size && !stop && my == session) {
                    val n = record.read(inBuf, got, inBuf.size - got, AudioRecord.READ_BLOCKING)
                    if (n < 0) {
                        if (stop || my != session) break  // our own stop ended this capture: not a fault
                        // the capture is gone (projection revoked, audio server restarted): say so instead of
                        // staying "on" with no sound
                        readErrors++
                        Log.w(TAG, "capture read failed: $n")
                        if (n == AudioRecord.ERROR_DEAD_OBJECT || ++readErrorsInARow >= 20) {
                            StopLog.record(this, "capture read failed $n")
                            endedBySystem(State.CAPTURE_FAILED, my); return
                        }
                        Thread.sleep(10)
                        continue
                    }
                    readErrorsInARow = 0
                    got += n
                }
                if (got < inBuf.size) continue
                val waited = android.os.SystemClock.elapsedRealtime() - waitFrom
                if (waited > longestGapMs) longestGapMs = waited
                if (waited >= GAP_MS) {
                    gaps++
                    // counted only: on some phones the capture simply waits while nothing plays (not a fault), and
                    // the stop log keeps few lines
                    Log.i(TAG, "capture: no sound came for $waited ms")
                }
                framesRead += hop
                backlog = captureBacklog(record, stamp, framesRead)
                if (++hops % 50 == 0) {  // every 0.5 s: settings changed in the app apply live
                    val sil = Build.VERSION.SDK_INT >= 29 &&
                        runCatching { record.activeRecordingConfiguration?.isClientSilenced }.getOrNull() == true
                    if (sil != silenced) {
                        val now = android.os.SystemClock.elapsedRealtime()
                        silenced = sil
                        if (sil) { silencedTimes++; silencedAt = now } else silencedMs += now - silencedAt
                        Log.w(TAG, "capture: ${if (sil) "silenced by Android" else "heard again"}")
                        if (silencedTimes <= 20) StopLog.eventWithState(this,
                            if (sil) "Android silenced the capture (filtering gives silence)" else "capture heard again")
                        report(); notifyListeners()
                    }
                    val p = Engine.policy(settings)
                    if (p != policy) { policy = p; engine.setPolicy(p); gateOn = 0; gateSamples = 0 }
                    val st = settings.audioStereo
                    if (st != stereoChosen) {
                        // the user's choice is a fresh start: stereo is tried again even on a phone that needed mono
                        // before; LoadMonitor switches back to mono if it still cannot keep up
                        stereoChosen = st
                        if (st) settings.audioMono = false
                        monitor.choose(!st)
                        engine.setMono(!st)
                        Log.i(TAG, "filter: ${if (st) "stereo" else "mono"} chosen")
                        report(); notifyListeners()
                    }
                    if (policy != 0) { gateSamples++; if (engine.detectorStatus() == 1) gateOn++ }
                    val ks = settings.keepSinging
                    if (ks != singing && !loading) {
                        loading = true
                        Log.i(TAG, "filter: keep singing ${if (ks) "on" else "off"}, loading the model")
                        Thread({
                            Process.setThreadPriority(Process.THREAD_PRIORITY_BACKGROUND)
                            // an exception here (no room to copy the model out) keeps the running engine: its sound is
                            // still filtered, by the model chosen before
                            val e = try { Engine.open(this, ch, singing = ks) }
                                    catch (t: Throwable) { Log.e(TAG, "filter: model reload failed", t); return@Thread }
                            synchronized(swapLock) { if (loopDone) e.close() else loaded = e to ks }
                        }, "im-model-load").start()
                    }
                    // the apps left unfiltered changed (FixMistakes): a new capture with the new list on the same
                    // projection, opened and started before the old one is released, so there is no gap. If it cannot
                    // open, the old capture goes on: an app just added stays filtered (fail-closed); it is not
                    // retried until the list changes again.
                    val ex = FixMistakes.filterOffUids(this, settings)
                    if (ex != excluded && ex != excludeFailed) {
                        runCatching {
                            val r = openRecord(ex)
                            try { r.startRecording(); r } catch (t: Throwable) { r.release(); throw t }
                        }
                            .onSuccess { r ->
                                runCatching { record.stop() }; record.release()
                                record = r; excluded = ex; excludeFailed = null; framesRead = 0
                                captureExcluded = ex; captureExcludeFailed = null
                                Log.i(TAG, "filter: capture rebuilt, ${ex.size} app(s) left unfiltered")
                            }
                            .onFailure { excludeFailed = ex; captureExcludeFailed = ex; Log.w(TAG, "filter: capture with the new app list did not open", it) }
                    }
                }
                if (loading) synchronized(swapLock) { loaded.also { loaded = null } }?.let { (e, ks) ->
                    // hop boundary: the new engine takes over; the old one is closed on this thread, which used it
                    val old = engine
                    engine = e; singing = ks; loading = false
                    if (monitor.mono) engine.setMono(true)
                    engine.setPolicy(policy)
                    old.close()
                    delayMs = engine.alignedLatency * 1000 / Engine.SAMPLE_RATE
                    Log.i(TAG, "filter: model reloaded: ${engine.modelName}, keep singing $ks, failed ${engine.failed}")
                    report()  // before publish: the screen reads the new health when it hears of the change
                    publish(if (engine.failed) State.MODEL_FAILED else State.FILTERING); if (engine.failed) updateNotification()
                }
                for (x in inBuf) { val a = if (x < 0) -x else x; if (a > peak) peak = a }
                val t0 = System.nanoTime()
                engine.processHops(inBuf, outBuf, 1)
                val work = System.nanoTime() - t0
                if (Build.VERSION.SDK_INT >= 31) hint?.let { h -> runCatching { h.reportActualWorkDuration(work.coerceAtLeast(1)) } }
                muter?.gate?.let { engine.setGate(it) }
                // delay that is no longer needed is given back by skipping one hop that holds no sound
                val outPeak = peakOf(outBuf)
                val silent = outPeak <= SILENT_PEAK
                val quiet = outPeak <= QUIET_PEAK
                if (!monitor.takeTrim(silent, quiet)) {
                    val w = track.write(outBuf, 0, outBuf.size, AudioTrack.WRITE_BLOCKING)
                    if (w < 0) {
                        // the output is gone (audio server restarted, the phone moved the stream): nothing would be
                        // heard while the originals stay muted. Make it again; when that keeps failing, say so.
                        val now = android.os.SystemClock.elapsedRealtime()
                        Log.w(TAG, "output write failed: $w, making the output again")
                        if (now - lastRebuild < 10_000 && ++trackRebuilds >= 3) {
                            StopLog.record(this, "output failed $w")
                            endedBySystem(State.CAPTURE_FAILED, my); return
                        }
                        if (now - lastRebuild >= 10_000) trackRebuilds = 0
                        lastRebuild = now
                        runCatching { track.release() }
                        track = makeTrack()
                        track.play()
                        if (SimpleMode.active) track.setVolume(simpleGain)
                        written = 0
                        StopLog.event(this, "output made again after write error $w")
                        continue
                    }
                    written += hop
                    // too little sound waiting (the capture runs slower than the output): one hop of silence more
                    if (monitor.takePad(silent, quiet) && track.write(silence, 0, silence.size, AudioTrack.WRITE_BLOCKING) > 0)
                        written += hop
                }
                // all the sound waiting: in the output, and in the capture (clock drift gathers there)
                val fill = (written - (track.playbackHeadPosition.toLong() and 0xFFFFFFFFL)).toInt() +
                    (if (backlog > 0) backlog else 0)
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
                            "capture waiting %d ms, trimmed %d, padded %d, mono %b, slow %b, capture %d dB, muter %s")
                            .format(java.util.Locale.ROOT, h.avgHopMs, h.maxHopMs, h.lateShare * 100, h.underruns,
                                h.bufferedMs, h.captureWaitingMs, h.trimmedHops, h.paddedHops, h.mono, h.tooSlow,
                                h.captureDb, muterStatus))
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "filter loop failed", e)
            StopLog.record(this, "filter loop failed: ${e.javaClass.simpleName}")
            endedBySystem(State.CAPTURE_FAILED, my)
        } finally {
            if (my == session) { captureExcluded = null; captureExcludeFailed = null }
            if (Build.VERSION.SDK_INT >= 31) runCatching { hint?.close() }
            runCatching { record.stop() }; record.release()
            runCatching { track.stop() }; track.release()
            synchronized(swapLock) { loopDone = true; loaded?.first?.close(); loaded = null }
            engine.close()
        }
    }

    private fun peakOf(buf: FloatArray): Float {
        var p = 0f
        for (x in buf) { val a = if (x < 0) -x else x; if (a > p) p = a }
        return p
    }

    /** Frames the capture holds that were not read yet, from its timestamp; -1 if Android does not say or the
     *  numbers make no sense. */
    private fun captureBacklog(r: AudioRecord, ts: android.media.AudioTimestamp, read: Long): Int {
        if (runCatching { r.getTimestamp(ts, android.media.AudioTimestamp.TIMEBASE_MONOTONIC) }.getOrNull() != AudioRecord.SUCCESS)
            return -1
        val captured = ts.framePosition + (System.nanoTime() - ts.nanoTime) * Engine.SAMPLE_RATE / 1_000_000_000L
        val b = captured - read
        return if (b < -Engine.SAMPLE_RATE / 50 || b > Engine.SAMPLE_RATE * 5L) -1 else b.coerceAtLeast(0).toInt()
    }

    override fun onDestroy() {
        instance = null
        stop = true
        holding = false
        debugReceiver?.let { runCatching { unregisterReceiver(it) } }
        worker?.join(500)
        blur?.stop(); blur = null
        muter?.stop()           // un-mutes the original sessions: an explicit stop restores normal audio
        SimpleMode.end(this)    // simple mode: the media sound back
        projection?.stop()
        ScreenShareProtection.captureEnded(this)
        health = null
        muterStatus = SessionMuter.Status.NO_PERMISSION
        blockedApps = emptyList()
        if (state != State.NO_CAPTURE_PERMISSION)
            publish(failState ?: if (stoppedBySystem) State.STOPPED_BY_SYSTEM else State.STOPPED)
        // Not stopped by the user: the sound is unfiltered again from now on, and the "on" notification is gone.
        // Say so where it will be seen.
        if (failState != null || stoppedBySystem) runCatching {
            val open = PendingIntent.getActivity(this, 0, UiActivity.main(this), PendingIntent.FLAG_IMMUTABLE)
            getSystemService(NotificationManager::class.java).notify(3, Notification.Builder(this, CHANNEL)
                .setContentTitle(getString(R.string.notif_stopped_title))
                .setContentText(getString(R.string.notif_stopped_text))
                .setStyle(Notification.BigTextStyle().bigText(getString(R.string.notif_stopped_text)))
                .setSmallIcon(R.drawable.ic_notification).setColor(getColor(R.color.error))
                .setContentIntent(open).setAutoCancel(true).build())
        }
        super.onDestroy()
    }

    private fun notification(): Notification {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(NotificationChannel(CHANNEL, getString(R.string.notif_channel), NotificationManager.IMPORTANCE_LOW))
        // Stop goes through the waiting period and the PIN (Protection), in an invisible activity: when they hold it
        // back, Waaiya opens at its Settings page, which a service started from a notification may not do (Android 12+)
        val stopIntent = PendingIntent.getActivity(this, 1, Intent(this, TileStartActivity::class.java)
            .setAction(TileStartActivity.ACTION_STOP_FILTER).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_IMMUTABLE)
        val open = PendingIntent.getActivity(this, 0, UiActivity.main(this), PendingIntent.FLAG_IMMUTABLE)
        // Pops up once on screen (its own high-importance channel): sharing was stopped from Android's own control
        // (the status-bar chip) and the other apps stay silent on purpose; without this, people took it for lost sound
        if (holding) nm.createNotificationChannel(NotificationChannel(CHANNEL_SILENCED,
            getString(R.string.notif_channel_silenced), NotificationManager.IMPORTANCE_HIGH).apply { setSound(null, null) })
        if (holding) return Notification.Builder(this, CHANNEL_SILENCED)
            .setOnlyAlertOnce(silencedShown).also { silencedShown = true }  // later updates stay quiet
            .setContentTitle(getString(R.string.notif_silenced_title))
            .setContentText(getString(R.string.notif_silenced_text))
            .setStyle(Notification.BigTextStyle().bigText(getString(R.string.notif_silenced_text)))
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(getColor(R.color.error))
            .setContentIntent(open)
            // filter again (the other apps stay muted meanwhile): Android's question, or none after the setup
            .addAction(Notification.Action.Builder(null, getString(R.string.notif_resume), PendingIntent.getActivity(this, 2,
                Intent(this, TileStartActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                PendingIntent.FLAG_IMMUTABLE)).build())
            .addAction(Notification.Action.Builder(null, getString(R.string.notif_stop), stopIntent).build())
            .setOngoing(true)
            .setGroup(GROUP)
            .build()
        val b = Notification.Builder(this, CHANNEL)
            .setContentTitle(getString(R.string.notif_title))
            .setContentText(getString(when {
                // the model did not load: the sound is muted for safety, not filtered (the notification said "on")
                state == State.MODEL_FAILED -> R.string.state_model_failed
                health?.tooSlow == true -> R.string.notif_too_slow
                muter != null && muterStatus == SessionMuter.Status.NO_PERMISSION ->
                    if (helperMissing()) R.string.notif_helper_missing else R.string.notif_not_muted
                muterStatus == SessionMuter.Status.FAILING -> R.string.notif_mute_failing
                else -> R.string.notif_text
            }))
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(getColor(R.color.primary))
            .setContentIntent(open)
            .addAction(Notification.Action.Builder(null, getString(R.string.notif_stop), stopIntent).build())
            .setOngoing(true)
            .setGroup(GROUP)
        // "Cover an area" / "Missed something"... (FixMistakes): here, not on a notification of their own (see GROUP)
        FixMistakes.notificationActions(this).forEach { b.addAction(it) }
        return b.build()
    }
}

fun Context.hasDumpPermission(): Boolean =
    checkSelfPermission(android.Manifest.permission.DUMP) == android.content.pm.PackageManager.PERMISSION_GRANTED
