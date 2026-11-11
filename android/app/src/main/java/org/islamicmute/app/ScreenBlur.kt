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
    enum class State { STARTING, ON, ON_COVERS_VISIBLE, NO_OVERLAY, MODELS_MISSING, FAILING }

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
        @Volatile var state: State? = null
            private set
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

    // worker-thread state
    private val frame = Vision.Frame(FloatArray(64 * 5), 0, false)
    private var lastNsfw = -1e9
    private var failStreak = 0
    private var frameMs = 0.0          // moving average of the model time per frame
    private var tilesTakeTurns = false
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
        size(overlay.screen())
        val r = ImageReader.newInstance(capW, capH, PixelFormat.RGBA_8888, 3)
        r.setOnImageAvailableListener({ schedule() }, worker)
        reader = r
        display = projection.createVirtualDisplay("waaiya-blur", capW, capH, context.resources.displayMetrics.densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR, null, null, worker)
        dm.registerDisplayListener(displayListener, worker)
        main.post(watchdog)
    }

    /** Applies the blur settings (main thread): off parks everything, on/changed (re)loads the models. */
    private fun apply(p: Int) {
        if (p == policy) return
        val was = policy
        policy = p
        if (p == 0) {
            overlay.detach()
            worker.post {
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
        }
        worker.post {
            if (policy != p) return@post // changed again meanwhile
            if (turningOn) { testDone = false; coversVisible = false; testUntil = SystemClock.uptimeMillis() + SELF_TEST_MS }
            vision?.close()
            vision = Vision.open(context, p, coversVisible).also {
                modelsBad = it.status != 0
                if (modelsBad) Log.e(TAG, "blur models: ${it.error}")
                if (tilesTakeTurns) it.setTilesPerFrame(1)
            }
            failStreak = 0
            if (turningOn) runCatching { display?.surface = reader?.surface }
        }
    }

    fun stop() {
        stopped = true
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
        val w = scr.width().coerceAtLeast(1); val h = scr.height().coerceAtLeast(1)
        val s = LONG_SIDE.toFloat() / maxOf(w, h)
        capW = (w * s).toInt() / 2 * 2; capH = (h * s).toInt() / 2 * 2
        thumbW = if (capW <= capH) THUMB_W else THUMB_W * capW / capH
        thumbH = maxOf(1, thumbW * capH / capW)
        thumbPx = IntArray(thumbW * thumbH)
    }

    /** Rotation: the virtual display keeps the screen's shape, otherwise the capture is letterboxed. */
    private fun resizeIfNeeded() {
        if (stopped) return
        val scr = overlay.screen()
        val landscape = scr.width() > scr.height()
        if (landscape == (capW > capH)) return
        size(scr)
        val r = ImageReader.newInstance(capW, capH, PixelFormat.RGBA_8888, 3)
        r.setOnImageAvailableListener({ schedule() }, worker)
        display?.resize(capW, capH, context.resources.displayMetrics.densityDpi)
        if (policy > 0) display?.surface = r.surface
        reader?.close()
        reader = r
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
            val buf = plane.buffer
            val now = SystemClock.uptimeMillis()
            busySince = now

            if (!testDone) {
                // Self-test: is our overlay in the capture? Look for the magenta square at the top-left corner.
                if (overlay.host == null) { testDone = true } else {
                    val px = (BlurOverlay.TEST_SQUARE_DP * context.resources.displayMetrics.density * capW /
                        overlay.screen().width()).toInt().coerceAtLeast(2)
                    val p = px / 2
                    val off = (capH / 2 + p) * plane.rowStride + p * 4
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
                        return
                    }
                }
            }

            val t = img.timestamp / 1e6
            val runNsfw = t - lastNsfw >= NSFW_EVERY_MS
            if (runNsfw) lastNsfw = t
            val t0 = SystemClock.elapsedRealtimeNanos()
            v.frame(buf, capW, capH, plane.rowStride, t, true, runNsfw, frame, thumbPx, thumbW, thumbH)
            val ms = (SystemClock.elapsedRealtimeNanos() - t0) / 1e6
            frameMs = if (frameMs == 0.0) ms else frameMs * 0.9 + ms * 0.1
            if (!tilesTakeTurns && frameMs > SLOW_FRAME_MS) {
                tilesTakeTurns = true // for the rest of this session
                v.setTilesPerFrame(1)
                Log.i(TAG, "blur: frames take ${frameMs.toInt()} ms, detector tiles now take turns")
            }
            failStreak = if (frame.failed) failStreak + 1 else 0
            if (!frame.failed) lastOk = SystemClock.uptimeMillis()
            val bm = Bitmap.createBitmap(thumbPx, thumbW, thumbH, Bitmap.Config.ARGB_8888)
            val rects = frame.rects.copyOf(frame.count * 5)
            val n = frame.count
            main.post { if (!stopped) overlay.show(rects, n, bm, failMode(), false) }
        } finally {
            busySince = 0
            img.close()
        }
    }

    /** 0 fine, 1 cover the screen, 2 warning badge (Settings.blurFailCover decides between 1 and 2). */
    private fun failMode(): Int {
        val now = SystemClock.uptimeMillis()
        val busy = busySince
        val failing = modelsBad || failStreak >= 3 || (busy != 0L && now - busy > STALL_MS)
        // a full-screen cover only where touches pass through it (accessibility overlay): otherwise the phone is stuck
        val canCover = settings.blurFailCover &&
            (overlay.host == BlurOverlay.Host.ACCESSIBILITY || overlay.host == BlurOverlay.Host.SHIZUKU)
        return if (!failing) 0 else if (canCover) 1 else 2
    }

    private val watchdog = object : Runnable {
        override fun run() {
            if (stopped) return
            apply(if (settings.blurOn) Vision.policy(settings) else 0) // settings apply live
            if (policy <= 0) { main.postDelayed(this, 500); return }
            if (overlay.host == null && overlay.attach()) {
                Log.i(TAG, "blur overlay attached late (${overlay.host})")
                overlay.show(FloatArray(0), 0, null, 0, true)
                worker.post { testDone = false; coversVisible = false; testUntil = SystemClock.uptimeMillis() + SELF_TEST_MS }
            }
            val fm = failMode()
            overlay.setFailMode(fm)
            overlay.heartbeat()
            publish(when {
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
