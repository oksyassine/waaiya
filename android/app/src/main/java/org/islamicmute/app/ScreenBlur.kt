package org.islamicmute.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.graphics.Rect
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import android.util.Log
import android.view.Display
import java.nio.ByteBuffer

/**
 * System-wide screen blur: captures the screen (same MediaProjection as the audio filter, small size), finds women /
 * people not confidently men / immodest frames ([Vision]) and covers them ([BlurOverlay]).
 *
 * Fail-closed knobs are the user's: when the models are missing or failing, or a frame waits too long, the screen is
 * either fully covered or shown with a warning badge (Settings.blurFailCover).
 * The overlay is drawn after the frame was captured (~1 frame + model time), so new content can show uncovered for
 * that long: covers are widened and moved ahead by the measured motion to limit it.
 */
class ScreenBlur(private val context: Context, private val projection: MediaProjection, private val settings: Settings) {
    enum class State {
        STARTING, ON, ON_COVERS_VISIBLE, NO_OVERLAY, MODELS_MISSING, FAILING,
        /** Android refused the screen capture for the blur (its virtual display could not be created). */
        NO_CAPTURE,
    }

    companion object {
        private const val TAG = "IslamicMute"
        private const val LONG_SIDE = 640           // capture size: long side in pixels
        private const val NSFW_EVERY_MS = 300.0     // the nudity model is slower: a few times a second
        private const val STALL_MS = 1500L          // a frame waiting longer than this = "cannot keep up"
        private const val SELF_TEST_MS = 1000L
        private const val THUMB_W = 24              // blurred picture: the frame shrunk to 24 cells wide
        private const val MIN_INTERVAL_MS = 50L     // at most ~20 analysed frames a second (battery)
        // Portrait screens: the person detector also runs on 3 tiles (small people). When a frame takes longer than
        // this on average with all of them, they take turns, one per frame (the tracker holds people in between).
        private const val SLOW_FRAME_MS = 60.0
        private const val TILES = 3                 // im_vision_params.tiles: passes for all tiles to have run once
        @Volatile var state: State? = null
            private set
        /** One line for the diagnostics report: the model time per frame. Null until a frame was analysed. */
        @Volatile var stats: String? = null
            private set
        /** One line for the diagnostics report: who draws the covers and what the self-test found. */
        @Volatile var coverInfo: String? = null
            private set
        /** Debug builds only (FilterService's debug receiver): covers drawn instead of the detections (x0, y0, x1, y1,
         *  kind per cover), to test the windows and touches without the models; and a forced capture failure. */
        @Volatile var debugCovers: FloatArray? = null
        @Volatile var debugFailCapture = false
        private val listeners = java.util.concurrent.CopyOnWriteArraySet<() -> Unit>()
        private val mainH = Handler(Looper.getMainLooper())
        fun addListener(l: () -> Unit) { listeners += l }
        fun removeListener(l: () -> Unit) { listeners -= l }
        private fun publish(s: State?) { if (state != s) { state = s; mainH.post { listeners.forEach { it() } } } }
    }

    private val main = Handler(Looper.getMainLooper())
    private val thread = HandlerThread("im-blur", Process.THREAD_PRIORITY_DEFAULT).apply { start() }
    private val worker = Handler(thread.looper)
    private val overlay = BlurOverlay(context)
    private var display: VirtualDisplay? = null
    private var reader: ImageReader? = null
    private var vision: Vision? = null
    private var capW = 0
    private var capH = 0
    @Volatile private var stopped = false
    /** start() could not create the capture: nothing is analysed; the watchdog only reports it. */
    private var captureFailed = false
    /** Main thread: the overlay host the self-test last ran for (a new host needs a new test). */
    private var testedHost: BlurOverlay.Host? = null

    // worker-thread state
    private val frame = Vision.Frame(FloatArray(Vision.MAX_RECTS * 5), 0, false)
    private var lastNsfw = -1e9
    private var failStreak = 0
    private var frameMs = 0.0          // moving average of the model time per frame
    private var tilesTakeTurns = false
    private var maleClear = 0f         // main thread: the strictness last sent to the worker
    private var thumbW = THUMB_W
    private var thumbH = THUMB_W * 2
    private var thumbPx = IntArray(thumbW * thumbH)
    private var testUntil = 0L
    private var testDone = false
    private var coversVisible = false
    @Volatile private var busySince = 0L
    @Volatile private var lastOk = SystemClock.uptimeMillis()
    @Volatile private var modelsBad = false
    private var lastStart = 0L
    private var pending = false
    // the last frame, kept for the passes a still screen would never get (worker thread)
    private var gen = 0
    private var stillBuf: ByteBuffer? = null
    private var stillStride = 0
    private var stillT = 0.0
    private var stillAt = 0L
    private var tilePasses = 0
    private var stillPasses = 0
    /** Policy in force (main thread writes): 0 = blur off, the virtual display is parked (no surface, no cost). */
    @Volatile private var policy = -1

    private val dm = context.getSystemService(DisplayManager::class.java)
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayChanged(id: Int) { if (id == Display.DEFAULT_DISPLAY) worker.post { resizeIfNeeded() } }
        override fun onDisplayAdded(id: Int) {}
        override fun onDisplayRemoved(id: Int) {}
    }

    /**
     * Runs whenever filtering starts, even with the blur off: Android 14+ stops the whole projection (audio too) when
     * its virtual display is created more than a few minutes after consent, so the display is created now, parked
     * without a surface while the blur is off. The settings are then followed live (watchdog -> [apply]).
     */
    fun start() {
        try {
            if (BuildConfig.DEBUG && debugFailCapture) throw SecurityException("debug: capture refused")
            size(overlay.screen())
            val r = ImageReader.newInstance(capW, capH, PixelFormat.RGBA_8888, 3)
            reader = r
            r.setOnImageAvailableListener({ schedule() }, worker)
            display = projection.createVirtualDisplay("waaiya-blur", capW, capH, context.resources.displayMetrics.densityDpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR, null, null, worker)
            dm.registerDisplayListener(displayListener, worker)
        } catch (e: Exception) {
            // e.g. a SecurityException when the projection was already stopped or Android refuses a second display.
            // Without this the thread and reader leaked and the screen said "starting" for the whole session.
            Log.e(TAG, "blur: cannot create the capture", e)
            captureFailed = true
            runCatching { reader?.close() }; reader = null
            thread.quitSafely()
        }
        main.post(watchdog)
    }

    /** Applies the blur settings (main thread): off parks everything, on/changed (re)loads the models. */
    private fun apply(p: Int) {
        if (p == policy) return
        val was = policy
        policy = p
        if (p == 0) {
            overlay.detach()
            testedHost = null
            worker.post {
                gen++
                runCatching { display?.surface = null }
                vision?.close(); vision = null
                modelsBad = false; failStreak = 0
            }
            publish(null)
            return
        }
        val turningOn = was <= 0
        if (turningOn) {
            publish(State.STARTING)
            if (overlay.attach()) overlay.show(FloatArray(0), 0, null, 0, true) // self-test square
            testedHost = overlay.host // null while the Shizuku layer connects: the watchdog tests it once it draws
        }
        worker.post {
            if (policy != p) return@post // changed again meanwhile
            if (turningOn) { testDone = false; coversVisible = false; testUntil = SystemClock.uptimeMillis() + SELF_TEST_MS }
            vision?.close()
            vision = Vision.open(context, p, coversVisible).also {
                modelsBad = it.status != 0
                if (modelsBad) Log.e(TAG, "blur models: ${it.error}")
                if (tilesTakeTurns) it.setTilesPerFrame(1)
                it.setMaleClear(settings.blurMaleClear)
            }
            failStreak = 0
            if (turningOn) runCatching { display?.surface = reader?.surface }
        }
    }

    fun stop() {
        stopped = true
        stats = null
        coverInfo = null
        main.removeCallbacks(watchdog)
        runCatching { dm.unregisterDisplayListener(displayListener) }
        worker.post {
            runCatching { display?.release() }
            runCatching { reader?.close() }
            vision?.close(); vision = null
        }
        thread.quitSafely()
        main.post { overlay.detach() }
        publish(null)
    }

    private fun size(scr: Rect) {
        val (cw, ch) = captureSize(scr.width(), scr.height())
        capW = cw; capH = ch
        thumbW = if (capW <= capH) THUMB_W else THUMB_W * capW / capH
        thumbH = maxOf(1, thumbW * capH / capW)
        thumbPx = IntArray(thumbW * thumbH)
    }

    /** The virtual display keeps the screen's shape (rotation, a foldable unfolding without rotating, a resolution
     *  change), otherwise the capture is letterboxed and the covers land in the wrong place. Worker thread. */
    private fun resizeIfNeeded() {
        if (stopped || captureFailed) return
        val scr = overlay.screen()
        val (w, h) = captureSize(scr.width(), scr.height())
        if (w == capW && h == capH) return
        Log.i(TAG, "blur: screen ${scr.width()}x${scr.height()}, capture ${capW}x$capH -> ${w}x$h")
        gen++ // the kept frame has the old shape
        size(scr)
        val r = ImageReader.newInstance(capW, capH, PixelFormat.RGBA_8888, 3)
        r.setOnImageAvailableListener({ schedule() }, worker)
        display?.resize(capW, capH, context.resources.displayMetrics.densityDpi)
        if (policy > 0) display?.surface = r.surface
        reader?.close()
        reader = r
    }

    /** Capture size for a screen: long side [LONG_SIDE], same shape, even sizes. */
    private fun captureSize(sw: Int, sh: Int): Pair<Int, Int> {
        val w = sw.coerceAtLeast(1); val h = sh.coerceAtLeast(1)
        val s = LONG_SIDE.toFloat() / maxOf(w, h)
        return ((w * s).toInt() / 2 * 2).coerceAtLeast(2) to ((h * s).toInt() / 2 * 2).coerceAtLeast(2)
    }

    /** A new frame: analyse it now, or (frame-rate cap) the newest frame as soon as the interval is over. Never
     *  dropped outright: the last frame before the screen goes still must be analysed. */
    private fun schedule() {
        if (pending || stopped) return
        val wait = lastStart + MIN_INTERVAL_MS - SystemClock.uptimeMillis()
        if (wait <= 0) reader?.let { onImage(it) }
        else { pending = true; worker.postDelayed({ pending = false; reader?.let { onImage(it) } }, wait) }
    }

    private fun onImage(r: ImageReader) {
        if (stopped) return
        lastStart = SystemClock.uptimeMillis()
        val img = runCatching { r.acquireLatestImage() }.getOrNull() ?: return
        try {
            val v = vision ?: return
            if (img.width != capW || img.height != capH) return // a frame from before a resize
            val plane = img.planes[0]
            gen++ // a newer frame: passes still planned on the previous one are dropped
            busySince = SystemClock.uptimeMillis()
            process(v, plane.buffer, plane.rowStride, img.timestamp / 1e6, false)
        } finally {
            busySince = 0
            img.close()
        }
    }

    /**
     * Analyses one frame. [still] = it is the kept copy of the last frame (the screen sent nothing newer).
     *
     * Android sends a frame only when the screen changes, and one pass does not do everything: the nudity model
     * runs a few times a second, the detector tiles may take turns, and the self-test only looks for its square.
     * So when a pass skipped something, the frame is kept and passed again shortly after, unless a newer frame
     * came: the last frame before the screen goes still is always analysed in full.
     */
    private fun process(v: Vision, buf: ByteBuffer, stride: Int, t: Double, still: Boolean) {
        val now = SystemClock.uptimeMillis()
        if (!testDone) {
            // Self-test: is our overlay in the capture? Look for the magenta square at the top-left corner.
            if (overlay.host == null) { testDone = true } else {
                val px = (BlurOverlay.TEST_SQUARE_DP * context.resources.displayMetrics.density * capW /
                    overlay.screen().width()).toInt().coerceAtLeast(2)
                val p = px / 2
                val off = (capH / 2 + p) * stride + p * 4
                val rr = buf.get(off).toInt() and 255; val gg = buf.get(off + 1).toInt() and 255
                val bb = buf.get(off + 2).toInt() and 255
                if (rr > 200 && gg < 60 && bb > 200) { coversVisible = true; testDone = true }
                else if (now >= testUntil) testDone = true
                if (testDone) {
                    v.setCoversVisible(coversVisible)
                    Log.i(TAG, "blur: covers ${if (coversVisible) "VISIBLE" else "not visible"} in the capture " +
                        "(host ${overlay.host}, skip flag applied ${overlay.skipApplied})")
                } else {
                    main.post { overlay.show(frame.rects, 0, null, 0, true) }
                    again(buf, stride, t, still, (testUntil - now).coerceAtLeast(0) + 20)
                    return
                }
            }
        }

        val runNsfw = t - lastNsfw >= NSFW_EVERY_MS
        if (runNsfw) lastNsfw = t
        val t0 = SystemClock.elapsedRealtimeNanos()
        v.frame(buf, capW, capH, stride, t, true, runNsfw, frame, thumbPx, thumbW, thumbH)
        val ms = (SystemClock.elapsedRealtimeNanos() - t0) / 1e6
        frameMs = if (frameMs == 0.0) ms else frameMs * 0.9 + ms * 0.1
        if (!tilesTakeTurns && frameMs > SLOW_FRAME_MS) {
            tilesTakeTurns = true // for the rest of this session
            v.setTilesPerFrame(1)
            Log.i(TAG, "blur: frames take ${frameMs.toInt()} ms, detector tiles now take turns")
        }
        if (still) stillPasses++
        stats = "Frames: %.0f ms each on average (last %.0f ms), tiles take turns %s, capture %dx%d, still-screen passes %d"
            .format(java.util.Locale.ROOT, frameMs, ms, if (tilesTakeTurns) "yes" else "no", capW, capH, stillPasses)
        failStreak = if (frame.failed) failStreak + 1 else 0
        if (!frame.failed) lastOk = SystemClock.uptimeMillis()
        val bm = Bitmap.createBitmap(thumbPx, thumbW, thumbH, Bitmap.Config.ARGB_8888)
        val dbg = if (BuildConfig.DEBUG) debugCovers else null
        val rects = dbg ?: frame.rects.copyOf(frame.count * 5)
        val n = dbg?.let { it.size / 5 } ?: frame.count
        main.post { if (!stopped) overlay.show(rects, n, bm, failMode(), false) }

        // what this pass skipped: the nudity model (it ran too recently), the other detector tiles
        val needNsfw = !runNsfw && policy and Vision.POLICY_NSFW != 0
        tilePasses = if (!tilesTakeTurns) 0 else if (still) tilePasses - 1 else TILES - 1
        if (needNsfw) again(buf, stride, t, still, (NSFW_EVERY_MS - (t - lastNsfw)).toLong().coerceAtLeast(MIN_INTERVAL_MS))
        else if (tilePasses > 0) again(buf, stride, t, still, MIN_INTERVAL_MS)
    }

    /** Keeps the frame and passes it through [process] again after [delayMs], unless a newer frame arrives first. */
    private fun again(buf: ByteBuffer, stride: Int, t: Double, still: Boolean, delayMs: Long) {
        if (!still) {
            val copy = stillBuf?.takeIf { it.capacity() == buf.capacity() }
                ?: ByteBuffer.allocateDirect(buf.capacity()).also { stillBuf = it }
            copy.clear(); buf.rewind(); copy.put(buf); copy.rewind()
            stillStride = stride; stillT = t; stillAt = SystemClock.uptimeMillis()
        }
        val g = gen
        worker.postDelayed({
            val v = vision
            val b = stillBuf
            if (!stopped && g == gen && v != null && b != null && policy > 0) {
                busySince = SystemClock.uptimeMillis()
                // the kept frame's time moves on with the clock: covers and tracks age as on a live frame
                try { process(v, b, stillStride, stillT + (SystemClock.uptimeMillis() - stillAt), true) }
                finally { busySince = 0 }
            }
        }, delayMs)
    }

    /** start() failed: with the blur on, say so and show the warning badge (a whole-screen cover could never lift,
     *  since nothing is analysed); with it off, nothing. */
    private fun reportNoCapture() {
        if (!settings.blurOn) { overlay.detach(); publish(null); return }
        if (overlay.host == null && !overlay.connecting) overlay.attach()
        overlay.setFailMode(2)
        overlay.heartbeat()
        publish(State.NO_CAPTURE)
    }

    /** 0 fine, 1 cover the screen, 2 warning badge (Settings.blurFailCover decides between 1 and 2). */
    private fun failMode(): Int {
        val now = SystemClock.uptimeMillis()
        val busy = busySince
        // A model missing from this build never comes back: a whole-screen cover would hide the app's own switch
        // for good, so that case gets the badge (and the status line says which model is missing).
        if (modelsBad) return 2
        val failing = failStreak >= 3 || (busy != 0L && now - busy > STALL_MS)
        // a full-screen cover only where touches pass through it (accessibility overlay): otherwise the phone is stuck
        val canCover = settings.blurFailCover &&
            (overlay.host == BlurOverlay.Host.ACCESSIBILITY || overlay.host == BlurOverlay.Host.SHIZUKU)
        return if (!failing) 0 else if (canCover) 1 else 2
    }

    private val watchdog = object : Runnable {
        override fun run() {
            if (stopped) return
            if (captureFailed) { reportNoCapture(); main.postDelayed(this, 500); return }
            apply(if (settings.blurOn) Vision.policy(settings) else 0) // settings apply live
            val mc = settings.blurMaleClear
            if (mc != maleClear) { maleClear = mc; worker.post { vision?.setMaleClear(mc) } }
            if (policy <= 0) { main.postDelayed(this, 500); return }
            if (overlay.host == null && !overlay.connecting && overlay.attach())
                Log.i(TAG, "blur overlay attached late (${overlay.host ?: "Shizuku layer connecting"})")
            val fm = failMode()
            overlay.setFailMode(fm)
            overlay.heartbeat()           // may replace a host that stopped drawing
            // A new host (attached late, the Shizuku layer confirmed, or a fallback from it to a window, or from a
            // switched-off accessibility service): whether its covers show in the capture is not known, so the
            // self-test runs again. Without this a window that replaced the Shizuku layer on Android 10/11-like
            // behaviour kept "covers not visible", and the tracker uncovered whatever its own covers hid.
            val h = overlay.host
            if (h != testedHost) {
                testedHost = h
                if (h != null) {
                    Log.i(TAG, "blur: covers now drawn by $h, testing the capture again")
                    overlay.show(FloatArray(0), 0, null, 0, true)
                    worker.post { testDone = false; coversVisible = false; testUntil = SystemClock.uptimeMillis() + SELF_TEST_MS }
                }
            }
            // Shizuku layer: "drawing" only means its calls did not fail (the layer is left out of the capture, so
            // the app cannot see it on screen)
            coverInfo = "Covers drawn by: ${overlay.host ?: if (overlay.connecting) "Shizuku layer (connecting)" else "nothing"}" +
                ", skip-screenshot flag ${if (overlay.skipApplied) "on" else "off"}, covers in the capture " +
                (if (!testDone) "being tested" else if (coversVisible) "yes" else "no")
            worker.post { resizeIfNeeded() } // a shape change that sent no display event (e.g. some foldables)
            publish(when {
                overlay.connecting -> State.STARTING
                overlay.host == null -> State.NO_OVERLAY
                modelsBad -> State.MODELS_MISSING
                fm != 0 -> State.FAILING
                !testDone -> State.STARTING
                coversVisible -> State.ON_COVERS_VISIBLE
                else -> State.ON
            })
            main.postDelayed(this, 500)
        }
    }
}
