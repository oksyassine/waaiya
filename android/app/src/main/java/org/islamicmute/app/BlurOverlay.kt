package org.islamicmute.app

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.RectF
import android.os.Build
import android.util.Log
import android.view.Gravity
import android.view.SurfaceControl
import android.view.View
import android.view.WindowManager
import org.lsposed.hiddenapibypass.HiddenApiBypass

/**
 * The screen-blur covers, drawn over every app.
 *
 * Best host (Android 12+, Shizuku running): [ShizukuCovers], a layer owned by the shell, which touches pass through
 * and which is left out of the screen capture, with no accessibility service and no overlay permission.
 *
 * Otherwise windows: an accessibility overlay when [BlurAccessibilityService] runs (one, full screen; Android lets
 * touches pass through accessibility overlays), otherwise app overlays ("display over other apps"): Android 12+ drops
 * every touch that lands inside an opaque app overlay, so there is one window per group of touching covers (at most
 * [MAX_WINDOWS], see [CoverWindows]), each sized to its group, and the space between groups stays touchable.
 *
 * Capture: each overlay surface gets the hidden "skip screenshot" flag, so the screen capture (and so the
 * detector) sees what is under the covers. Whether that worked is measured by ScreenBlur's self-test, not assumed.
 * All calls on the main thread.
 */
class BlurOverlay(private val context: Context) {
    enum class Host { SHIZUKU, ACCESSIBILITY, APP_OVERLAY }

    private var wm: WindowManager? = null
    /** One window, its layout and whether the skip-screenshot flag is on its current surface. */
    private class Win(val v: CoverView, val p: WindowManager.LayoutParams) { var skip = false }
    private val wins = ArrayList<Win>()
    /** The host that is drawing now; null while nothing draws, including while the Shizuku layer is still being
     *  set up and checked (up to 8 s): the blur must not say "on" before covers can appear. Read by ScreenBlur's
     *  worker thread too. */
    @Volatile var host: Host? = null
        private set
    /** True once the skip-screenshot flag was applied without error on every window (the self-test still decides).
     *  Shizuku layer: true once its start() and probe cover worked. */
    val skipApplied: Boolean
        get() = when (host) {
            null -> false
            Host.SHIZUKU -> true
            else -> wins.isNotEmpty() && wins.all { it.skip }
        }

    private var layer: ShizukuCovers? = null
    /** After the Shizuku layer failed, windows are used for a while instead of retrying every watchdog tick. */
    private var layerFailedAt = -1_000_000L

    /** The Shizuku layer is being bound and probed: nothing draws yet, and attach() must not start another. */
    val connecting: Boolean get() = layer != null && host == null

    /** Picks the host: the Shizuku layer when possible (decided asynchronously, falling back to windows), else
     *  windows. Returns false when nothing can draw (no Shizuku, no accessibility service, no overlay permission). */
    fun attach(): Boolean {
        if (wins.isNotEmpty() || layer != null) return true
        if (Build.VERSION.SDK_INT >= 31 && ShizukuSetup.state(context) == ShizukuSetup.State.READY &&
            android.os.SystemClock.uptimeMillis() - layerFailedAt > 30_000) {
            val l = ShizukuCovers(context)
            layer = l
            l.connect { ok ->
                if (layer !== l) return@connect                 // detached meanwhile
                if (ok) {
                    host = Host.SHIZUKU
                    show(lastRects, lastCount, lastThumb, lastFail, lastTest)
                } else {
                    Log.w(TAG, "blur: Shizuku layer unavailable, using a window")
                    layerFailedAt = android.os.SystemClock.uptimeMillis()
                    layer = null
                    attachWindow()
                }
            }
            return true
        }
        return attachWindow()
    }

    private fun attachWindow(): Boolean {
        if (wins.isNotEmpty()) return true
        val a11y = BlurAccessibilityService.instance
        val (ctx, type, h) = when {
            a11y != null -> Triple<Context, Int, Host>(a11y, WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY, Host.ACCESSIBILITY)
            android.provider.Settings.canDrawOverlays(context) ->
                Triple(context, WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY, Host.APP_OVERLAY)
            else -> return false
        }
        val w = ctx.getSystemService(WindowManager::class.java)
        // App overlays: the whole pool is added now, each 1x1 until it gets a group of covers, so every surface has
        // its skip-screenshot flag before it first shows a cover (a window added on demand would be in the capture
        // until its flag lands).
        val n = if (h == Host.APP_OVERLAY) MAX_WINDOWS else 1
        for (i in 0 until n) {
            val p = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT, type,
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                PixelFormat.TRANSLUCENT)
            p.gravity = Gravity.TOP or Gravity.START
            p.title = "Waaiya blur"
            p.layoutInDisplayCutoutMode = if (Build.VERSION.SDK_INT >= 30) WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                                          else WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            if (Build.VERSION.SDK_INT >= 30) p.fitInsetsTypes = 0
            if (h == Host.APP_OVERLAY) { p.x = 0; p.y = 0; p.width = 1; p.height = 1 } // sized to its group in show()
            val v = CoverView(ctx)
            try {
                w.addView(v, p)
            } catch (e: Exception) {
                Log.w(TAG, "blur overlay: addView failed", e)
                wins.forEach { runCatching { w.removeViewImmediate(it.v) } }
                wins.clear()
                return false
            }
            val win = Win(v, p)
            wins += win
            v.post { applySkipScreenshot(win) }
        }
        wm = w; host = h
        return true
    }

    fun detach() {
        layer?.stop(); layer = null
        wins.forEach { runCatching { wm?.removeViewImmediate(it.v) } }
        wins.clear()
        wm = null; host = null
    }

    /** The real display size: covers arrive normalised to it. */
    fun screen(): Rect {
        val w = wm ?: context.getSystemService(WindowManager::class.java)
        if (Build.VERSION.SDK_INT >= 30) return w.maximumWindowMetrics.bounds
        val p = android.graphics.Point()
        @Suppress("DEPRECATION") w.defaultDisplay.getRealSize(p)
        return Rect(0, 0, p.x, p.y)
    }

    private var lastRects = FloatArray(0)
    private var lastCount = 0
    private var lastThumb: Bitmap? = null
    private var lastFail = 0
    private var lastTest = false

    /** Called twice a second: keeps the Shizuku layer's covers alive (it hides them when the app goes quiet), asks
     *  it whether they were drawn, and replaces a host that stopped working: a dead or failing Shizuku layer by
     *  windows, a switched-off accessibility service by an app overlay (or nothing, which ScreenBlur reports).
     *  ScreenBlur sees the host change and runs its "are covers in the capture" self-test again. */
    fun heartbeat() {
        if (host == Host.ACCESSIBILITY && BlurAccessibilityService.instance == null) {
            Log.w(TAG, "blur: accessibility service turned off, changing host")
            detach()
            if (attach()) show(lastRects, lastCount, lastThumb, lastFail, lastTest)
            return
        }
        val l = layer ?: return
        if (host != Host.SHIZUKU) return               // still connecting
        if (!l.alive || l.failed) {
            Log.w(TAG, "blur: Shizuku layer ${if (l.failed) "cannot draw" else "died (Shizuku stopped?)"}, using a window")
            layerFailedAt = android.os.SystemClock.uptimeMillis()
            l.stop(); layer = null; host = null
            if (attachWindow()) show(lastRects, lastCount, lastThumb, lastFail, lastTest)
            return
        }
        show(lastRects, lastCount, lastThumb, lastFail, lastTest)
        l.checkHealth()
    }

    /** Changes only the failure display, keeping the current covers. */
    fun setFailMode(failMode: Int) {
        if (failMode != lastFail) show(lastRects, lastCount, lastThumb, failMode, false)
    }

    /**
     * New covers. rects: x0,y0,x1,y1 (0..1 of the screen), kind; thumb: the frame shrunk (drawn enlarged = blurred).
     * failMode: 0 none, 1 cover everything (the blur cannot keep up and the user chose "cover"), 2 warning badge.
     */
    fun show(rects: FloatArray, count: Int, thumb: Bitmap?, failMode: Int, testSquare: Boolean) {
        lastRects = rects; lastCount = count; lastThumb = thumb; lastFail = failMode; lastTest = testSquare
        val scr = screen()
        if (host == Host.SHIZUKU) { layer?.let { showOnLayer(it, rects, count, thumb, failMode, testSquare, scr) }; return }
        if (wins.isEmpty()) return
        if (host != Host.APP_OVERLAY) {
            wins[0].v.set(rects, count, thumb, failMode, testSquare, scr)
            wins[0].v.invalidate()
            return
        }
        // here a cover swallows touches: a whole-screen (nudity) cover leaves the bottom free so people can
        // still scroll or leave
        val rs = rects.copyOf(count * 5)
        for (i in 0 until count) if (rs[i * 5 + 4].toInt() == Vision.KIND_FULL) rs[i * 5 + 3] = minOf(rs[i * 5 + 3], FULL_COVER_BOTTOM)
        // one window per group of touching covers (touches between groups reach the app)
        val d = context.resources.displayMetrics.density
        val boxes = ArrayList<IntArray>()
        if (failMode == 1) boxes += intArrayOf(0, 0, scr.width(), scr.height())
        else for (i in 0 until count) boxes += intArrayOf((rs[i * 5] * scr.width()).toInt(), (rs[i * 5 + 1] * scr.height()).toInt(),
            Math.ceil((rs[i * 5 + 2] * scr.width()).toDouble()).toInt(), Math.ceil((rs[i * 5 + 3] * scr.height()).toDouble()).toInt())
        if (failMode == 2) boxes += CoverView.badgeRect(scr, d).let { intArrayOf(it.left, it.top, it.right, it.bottom) }
        if (testSquare) {
            val sq = (TEST_SQUARE_DP * d).toInt() + 1
            boxes += intArrayOf(0, scr.height() / 2, sq, scr.height() / 2 + sq)
        }
        val groups = CoverWindows.group(boxes, wins.size)
        val slot = CoverWindows.assign(groups, wins.map { intArrayOf(it.p.x, it.p.y, it.p.x + it.p.width, it.p.y + it.p.height) })
        for ((k, win) in wins.withIndex()) {
            val g = slot[k]
            val want = g ?: PARKED
            val p = win.p
            if (p.x != want[0] || p.y != want[1] || p.width != want[2] - want[0] || p.height != want[3] - want[1]) {
                p.x = want[0]; p.y = want[1]; p.width = want[2] - want[0]; p.height = want[3] - want[1]
                win.v.origin(want[0], want[1])
                runCatching { wm?.updateViewLayout(win.v, p) }
                win.v.post { applySkipScreenshot(win) } // a relayout may give the window a new surface
            }
            // every window draws all covers that reach into it, so overlapping groups still look like one cover
            if (g != null) win.v.set(rs, count, thumb, failMode, testSquare, scr)
            else win.v.set(rs, 0, null, 0, false, scr)
            win.v.invalidate()
        }
    }

    private var layerBuf = FloatArray(0)

    /** Covers as solid shell layers, each tinted with the mean colour of what it hides (from the thumbnail). */
    private fun showOnLayer(l: ShizukuCovers, rects: FloatArray, count: Int, thumb: Bitmap?, failMode: Int,
                            testSquare: Boolean, scr: Rect) {
        val n = count + 2
        if (layerBuf.size < n * ShizukuCovers.RECORD) layerBuf = FloatArray(n * ShizukuCovers.RECORD)
        val b = layerBuf
        var k = 0
        fun put(x0: Float, y0: Float, x1: Float, y1: Float, kind: Int, rgb: Int) {
            val o = k++ * ShizukuCovers.RECORD
            b[o] = x0; b[o + 1] = y0; b[o + 2] = x1; b[o + 3] = y1; b[o + 4] = kind.toFloat()
            b[o + 5] = Color.red(rgb) / 255f; b[o + 6] = Color.green(rgb) / 255f; b[o + 7] = Color.blue(rgb) / 255f
        }
        val w = scr.width().toFloat(); val h = scr.height().toFloat()
        val fallback = context.getColor(R.color.surface)
        if (failMode == 1) put(0f, 0f, w, h, ShizukuCovers.KIND_FAIL_COVER, fallback)
        else for (i in 0 until count) {
            val x0 = rects[i * 5]; val y0 = rects[i * 5 + 1]; val x1 = rects[i * 5 + 2]; val y1 = rects[i * 5 + 3]
            put(x0 * w, y0 * h, x1 * w, y1 * h, rects[i * 5 + 4].toInt(), meanColor(thumb, x0, y0, x1, y1) ?: fallback)
        }
        if (failMode == 2) {
            val d = context.resources.displayMetrics.density
            put(0f, 0f, w, 6 * d, ShizukuCovers.KIND_BADGE, Color.RED) // thin red bar at the top: blur not working
        }
        if (testSquare) {
            val s = BlurOverlay.TEST_SQUARE_DP * context.resources.displayMetrics.density
            put(0f, h / 2, s, h / 2 + s, ShizukuCovers.KIND_TEST, Color.MAGENTA)
        }
        l.update(b, k)
    }

    /** Mean colour of the thumbnail cells under a cover, darkened a little (a calm, opaque tint). */
    private fun meanColor(t: Bitmap?, x0: Float, y0: Float, x1: Float, y1: Float): Int? {
        if (t == null || t.isRecycled) return null
        val cx0 = (x0 * t.width).toInt().coerceIn(0, t.width - 1); val cx1 = (x1 * t.width).toInt().coerceIn(cx0, t.width - 1)
        val cy0 = (y0 * t.height).toInt().coerceIn(0, t.height - 1); val cy1 = (y1 * t.height).toInt().coerceIn(cy0, t.height - 1)
        var r = 0L; var g = 0L; var bl = 0L; var n = 0
        for (y in cy0..cy1) for (x in cx0..cx1) { val p = t.getPixel(x, y); r += Color.red(p); g += Color.green(p); bl += Color.blue(p); n++ }
        if (n == 0) return null
        return Color.rgb((r / n * 0.8).toInt(), (g / n * 0.8).toInt(), (bl / n * 0.8).toInt())
    }

    /** Hidden API: SurfaceControl.Transaction#setSkipScreenshot on an overlay window's surface (Android 12+). */
    private fun applySkipScreenshot(win: Win) {
        val v = win.v
        if (Build.VERSION.SDK_INT < 31 || wins.none { it === win }) return
        try {
            HiddenApiBypass.addHiddenApiExemptions("Landroid/view/")
            val vri = HiddenApiBypass.invoke(View::class.java, v, "getViewRootImpl") ?: return
            val sc = HiddenApiBypass.invoke(vri.javaClass, vri, "getSurfaceControl") as? SurfaceControl ?: return
            if (!sc.isValid) { v.postDelayed({ applySkipScreenshot(win) }, 100); return }
            val tx = SurfaceControl.Transaction()
            HiddenApiBypass.invoke(SurfaceControl.Transaction::class.java, tx, "setSkipScreenshot", sc, true)
            tx.apply()
            win.skip = true
        } catch (t: Throwable) {
            Log.w(TAG, "blur overlay: skip-screenshot not available: $t")
            win.skip = false
        }
    }

    private class CoverView(ctx: Context) : View(ctx) {
        private var rects = FloatArray(0)
        private var count = 0
        private var thumb: Bitmap? = null
        private var failMode = 0
        private var testSquare = false
        private var scr = Rect()
        private var ox = 0
        private var oy = 0
        private val bmp = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)
        private val tint = Paint().apply { color = Color.argb(200, 30, 30, 30) } // mostly opaque: shapes and colours do not show through
        // Heavy blur: each cover shows its own area averaged into a few big cells (about BLUR_CELL_DP each),
        // smoothed by bitmap filtering, so faces, hair and outlines melt into the surroundings.
        private var thumbPx = IntArray(0)
        private var thumbW = 0
        private var thumbH = 0
        private val cells = Bitmap.createBitmap(MAX_CELLS, MAX_CELLS, Bitmap.Config.ARGB_8888)
        private val cellPx = IntArray(MAX_CELLS * MAX_CELLS)
        private val cellSrc = Rect()
        private val solid = Paint().apply { color = ctx.getColor(R.color.surface) }
        private val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = ctx.getColor(R.color.text_primary); textAlign = Paint.Align.CENTER
            textSize = 16 * ctx.resources.displayMetrics.scaledDensity
        }
        private val badge = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = ctx.getColor(R.color.error) }
        private val badgeText = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE; textAlign = Paint.Align.CENTER; textSize = 12 * ctx.resources.displayMetrics.scaledDensity
        }
        private val magenta = Paint().apply { color = Color.rgb(255, 0, 255) }
        private val r = RectF()
        private val rb = RectF()
        private val path = android.graphics.Path()
        private val parts = android.graphics.Region()  // strips of outlined people: tinted once, as one shape
        private val partsPath = android.graphics.Path()
        private val dst = Rect()
        private val density = ctx.resources.displayMetrics.density

        init { importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO }

        fun set(rects: FloatArray, count: Int, thumb: Bitmap?, failMode: Int, testSquare: Boolean, scr: Rect) {
            if (this.rects.size < count * 5) this.rects = FloatArray(count * 5)
            System.arraycopy(rects, 0, this.rects, 0, count * 5)
            this.count = count; this.thumb = thumb; this.failMode = failMode; this.testSquare = testSquare; this.scr = scr
            if (thumb != null && !thumb.isRecycled) {
                thumbW = thumb.width; thumbH = thumb.height
                if (thumbPx.size < thumbW * thumbH) thumbPx = IntArray(thumbW * thumbH)
                thumb.getPixels(thumbPx, 0, thumbW, 0, 0, thumbW, thumbH)
            } else { thumbW = 0; thumbH = 0 }
        }

        /** Averages the thumbnail under r (screen pixels) into nx * ny cells of [cells]; false without a thumbnail. */
        private fun fillCells(r: RectF, w: Float, h: Float, nx: Int, ny: Int): Boolean {
            if (thumbW == 0 || thumbH == 0) return false
            for (j in 0 until ny) for (i in 0 until nx) {
                val x0 = ((r.left + r.width() * i / nx) / w * thumbW).toInt().coerceIn(0, thumbW - 1)
                val x1 = ((r.left + r.width() * (i + 1) / nx) / w * thumbW).toInt().coerceIn(x0 + 1, thumbW)
                val y0 = ((r.top + r.height() * j / ny) / h * thumbH).toInt().coerceIn(0, thumbH - 1)
                val y1 = ((r.top + r.height() * (j + 1) / ny) / h * thumbH).toInt().coerceIn(y0 + 1, thumbH)
                var sr = 0; var sg = 0; var sb = 0; var n = 0
                for (y in y0 until y1) for (x in x0 until x1) {
                    val p = thumbPx[y * thumbW + x]
                    sr += Color.red(p); sg += Color.green(p); sb += Color.blue(p); n++
                }
                cellPx[j * MAX_CELLS + i] = Color.rgb(sr / n, sg / n, sb / n)
            }
            cells.setPixels(cellPx, 0, MAX_CELLS, 0, 0, MAX_CELLS, MAX_CELLS)
            cellSrc.set(0, 0, nx, ny)
            return true
        }

        fun origin(x: Int, y: Int) { ox = x; oy = y }

        companion object {
            fun badgeRect(scr: Rect, density: Float): Rect {
                val w = (180 * density).toInt(); val h = (28 * density).toInt()
                val top = (40 * density).toInt()
                return Rect(scr.centerX() - w / 2, top, scr.centerX() + w / 2, top + h)
            }
        }

        override fun onDraw(c: Canvas) {
            c.translate(-ox.toFloat(), -oy.toFloat())
            val w = scr.width().toFloat(); val h = scr.height().toFloat()
            if (failMode == 1) {
                c.drawRect(0f, 0f, w, h, solid)
                c.drawText(context.getString(R.string.blur_cover_slow), w / 2, h / 2, text)
                return
            }
            val radius = 12 * density
            val cell = BLUR_CELL_DP * density
            for (i in 0 until count) {
                r.set(rects[i * 5] * w, rects[i * 5 + 1] * h, rects[i * 5 + 2] * w, rects[i * 5 + 3] * h)
                // outside this window (another window of the pool draws it): skip the cell averaging
                if (r.right < ox || r.bottom < oy || r.left > ox + width || r.top > oy + height) continue
                val full = rects[i * 5 + 4].toInt() == Vision.KIND_FULL
                val part = (rects[i * 5 + 4].toInt() and Vision.KIND_PART) != 0
                c.save()
                if (!full && !part) {
                    path.reset(); path.addRoundRect(r, radius, radius, android.graphics.Path.Direction.CW); c.clipPath(path)
                } else c.clipRect(r) // strips: square, so the stack reads as one shape
                if (full) {
                    c.drawRect(r, solid) // nudity: opaque, nothing of the picture shows
                } else {
                    val nx = Math.round(r.width() / cell).coerceIn(1, MAX_CELLS)
                    val ny = Math.round(r.height() / cell).coerceIn(1, MAX_CELLS)
                    if (fillCells(r, w, h, nx, ny)) {
                        // stretch by half a cell beyond the cover so the filtered edge cells keep their full colour
                        dst.set((r.left - r.width() / nx / 2).toInt(), (r.top - r.height() / ny / 2).toInt(),
                            (r.right + r.width() / nx / 2).toInt(), (r.bottom + r.height() / ny / 2).toInt())
                        c.save(); c.clipRect(r)
                        c.drawBitmap(cells, cellSrc, dst, bmp)
                        c.restore()
                    } else c.drawRect(r, solid)
                    // strips overlap a little (no gaps): their tint is drawn once over their union, below
                    if (part) parts.op(r.left.toInt(), r.top.toInt(), Math.ceil(r.right.toDouble()).toInt(),
                        Math.ceil(r.bottom.toDouble()).toInt(), android.graphics.Region.Op.UNION)
                    else c.drawRect(r, tint)
                }
                c.restore()
                if (full) c.drawText(context.getString(R.string.blur_cover_full), w / 2, h / 2, text)
            }
            if (!parts.isEmpty) {
                partsPath.rewind()
                parts.getBoundaryPath(partsPath)
                c.drawPath(partsPath, tint)
                parts.setEmpty()
            }
            if (failMode == 2) {
                val b = badgeRect(scr, density)
                rb.set(b)
                c.drawRoundRect(rb, b.height() / 2f, b.height() / 2f, badge)
                c.drawText(context.getString(R.string.blur_not_working), b.exactCenterX(),
                    b.exactCenterY() - (badgeText.ascent() + badgeText.descent()) / 2, badgeText)
            }
            if (testSquare) c.drawRect(0f, h / 2, TEST_SQUARE_DP * density, h / 2 + TEST_SQUARE_DP * density, magenta)
        }
    }

    companion object {
        private const val TAG = "IslamicMute"
        /** Self-test square, drawn at the left edge, half-way down, for at most a second when the blur starts
         *  (not at the top: an app overlay may sit under the status bar). */
        const val TEST_SQUARE_DP = 16f
        /** Window hosts: blur cell size; a person's cover shows only a few soft blobs of colour. */
        const val BLUR_CELL_DP = 140f
        const val MAX_CELLS = 8
        /** App-overlay host: a whole-screen cover stops here (fraction of the height), leaving the bottom touchable. */
        const val FULL_COVER_BOTTOM = 0.88f
        /** App-overlay host: windows in the pool (groups beyond this are joined, see [CoverWindows]). */
        const val MAX_WINDOWS = 8
        /** An idle pool window: 1x1 at the corner, drawing nothing. */
        private val PARKED = intArrayOf(0, 0, 1, 1)
    }
}

/**
 * Only hosts the screen-blur overlay window: Android lets touches pass through accessibility overlays, and it does
 * not read, log or act on any screen content or event.
 */
class BlurAccessibilityService : AccessibilityService() {
    override fun attachBaseContext(base: android.content.Context) { super.attachBaseContext(Lang.wrap(base)) }

    companion object {
        @Volatile var instance: BlurAccessibilityService? = null
            private set
    }

    override fun onServiceConnected() { instance = this }
    override fun onAccessibilityEvent(event: android.view.accessibility.AccessibilityEvent?) {}
    override fun onInterrupt() {}
    override fun onDestroy() { instance = null; super.onDestroy() }
    override fun onUnbind(intent: android.content.Intent?): Boolean { instance = null; return super.onUnbind(intent) }
}

/**
 * Touches reach the app under the covers only through the accessibility overlay. Without it, a full-screen cover would
 * block every touch, so the "cover the screen" fail setting is off and greyed out.
 */
fun Context.blurTouchPassThrough(): Boolean =
    (Build.VERSION.SDK_INT >= 31 && ShizukuSetup.state(this) == ShizukuSetup.State.READY) ||
        (BuildConfig.BLUR_A11Y && blurAccessibilityEnabled())

/** True when the user (or Shizuku) turned on [BlurAccessibilityService]. */
fun Context.blurAccessibilityEnabled(): Boolean {
    val me = android.content.ComponentName(this, BlurAccessibilityService::class.java)
    val list = android.provider.Settings.Secure.getString(contentResolver,
        android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) ?: return false
    return list.split(':').any { android.content.ComponentName.unflattenFromString(it) == me }
}
