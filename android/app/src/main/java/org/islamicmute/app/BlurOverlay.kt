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
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.SurfaceControl
import android.view.View
import android.view.WindowManager
import org.lsposed.hiddenapibypass.HiddenApiBypass

/**
 * The screen-blur covers, drawn over every app.
 *
 * Window: an accessibility overlay when [BlurAccessibilityService] runs (full screen; Android lets touches pass
 * through accessibility overlays), otherwise an app overlay ("display over other apps") sized to the covers only,
 * because Android 12+ drops touches that land on an opaque app overlay.
 *
 * Capture: the overlay's surface gets the hidden "skip screenshot" flag, so the screen capture (and so the
 * detector) sees what is under the covers. Whether that worked is measured by ScreenBlur's self-test, not assumed.
 * All calls on the main thread.
 */
class BlurOverlay(private val context: Context) {
    enum class Host { ACCESSIBILITY, APP_OVERLAY }

    private val main = Handler(Looper.getMainLooper())
    private var wm: WindowManager? = null
    private var view: CoverView? = null
    private var params: WindowManager.LayoutParams? = null
    var host: Host? = null
        private set
    /** True once the skip-screenshot flag was applied without error (the self-test still decides). */
    var skipApplied = false
        private set

    /** Attaches the window. Returns false when neither an accessibility service nor the overlay permission is there. */
    fun attach(): Boolean {
        if (view != null) return true
        val a11y = BlurAccessibilityService.instance
        val (ctx, type, h) = when {
            a11y != null -> Triple<Context, Int, Host>(a11y, WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY, Host.ACCESSIBILITY)
            android.provider.Settings.canDrawOverlays(context) ->
                Triple(context, WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY, Host.APP_OVERLAY)
            else -> return false
        }
        val w = ctx.getSystemService(WindowManager::class.java)
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
        if (h == Host.APP_OVERLAY) { p.width = 1; p.height = 1 } // grows to the covers in show()
        val v = CoverView(ctx)
        try {
            w.addView(v, p)
        } catch (e: Exception) {
            Log.w(TAG, "blur overlay: addView failed", e)
            return false
        }
        wm = w; view = v; params = p; host = h
        v.post { applySkipScreenshot() }
        return true
    }

    fun detach() {
        val v = view ?: return
        runCatching { wm?.removeViewImmediate(v) }
        view = null; wm = null; params = null; host = null; skipApplied = false
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

    /** Changes only the failure display, keeping the current covers. */
    fun setFailMode(failMode: Int) {
        if (failMode != lastFail) show(lastRects, lastCount, lastThumb, failMode, false)
    }

    /**
     * New covers. rects: x0,y0,x1,y1 (0..1 of the screen), kind; thumb: the frame shrunk (drawn enlarged = blurred).
     * failMode: 0 none, 1 cover everything (the blur cannot keep up and the user chose "cover"), 2 warning badge.
     */
    fun show(rects: FloatArray, count: Int, thumb: Bitmap?, failMode: Int, testSquare: Boolean) {
        lastRects = rects; lastCount = count; lastThumb = thumb; lastFail = failMode
        val v = view ?: return
        val scr = screen()
        v.set(rects, count, thumb, failMode, testSquare, scr)
        if (host == Host.APP_OVERLAY) {
            // window = union of the covers (touches elsewhere reach the app); hidden when there is nothing to draw
            val u = v.union(scr)
            val p = params ?: return
            val want = if (u.isEmpty) Rect(0, 0, 1, 1) else u
            if (p.x != want.left || p.y != want.top || p.width != want.width() || p.height != want.height()) {
                p.x = want.left; p.y = want.top; p.width = want.width(); p.height = want.height()
                v.origin(want.left, want.top)
                runCatching { wm?.updateViewLayout(v, p) }
                v.post { applySkipScreenshot() } // a relayout may give the window a new surface
            }
        }
        v.invalidate()
    }

    /** Hidden API: SurfaceControl.Transaction#setSkipScreenshot on the overlay window's surface (Android 12+). */
    private fun applySkipScreenshot() {
        val v = view ?: return
        if (Build.VERSION.SDK_INT < 31) return
        try {
            HiddenApiBypass.addHiddenApiExemptions("Landroid/view/")
            val vri = HiddenApiBypass.invoke(View::class.java, v, "getViewRootImpl") ?: return
            val sc = HiddenApiBypass.invoke(vri.javaClass, vri, "getSurfaceControl") as? SurfaceControl ?: return
            if (!sc.isValid) { v.postDelayed({ applySkipScreenshot() }, 100); return }
            val tx = SurfaceControl.Transaction()
            HiddenApiBypass.invoke(SurfaceControl.Transaction::class.java, tx, "setSkipScreenshot", sc, true)
            tx.apply()
            skipApplied = true
        } catch (t: Throwable) {
            Log.w(TAG, "blur overlay: skip-screenshot not available: $t")
            skipApplied = false
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
        private val tint = Paint().apply { color = Color.argb(70, 30, 30, 30) }
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
        private val dst = Rect()
        private val density = ctx.resources.displayMetrics.density

        init { importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO }

        fun set(rects: FloatArray, count: Int, thumb: Bitmap?, failMode: Int, testSquare: Boolean, scr: Rect) {
            if (this.rects.size < count * 5) this.rects = FloatArray(count * 5)
            System.arraycopy(rects, 0, this.rects, 0, count * 5)
            this.count = count; this.thumb = thumb; this.failMode = failMode; this.testSquare = testSquare; this.scr = scr
        }

        fun origin(x: Int, y: Int) { ox = x; oy = y }

        fun union(scr: Rect): Rect {
            if (failMode == 1) return Rect(scr)
            val u = Rect()
            for (i in 0 until count) {
                u.union((rects[i * 5] * scr.width()).toInt(), (rects[i * 5 + 1] * scr.height()).toInt(),
                    Math.ceil((rects[i * 5 + 2] * scr.width()).toDouble()).toInt(),
                    Math.ceil((rects[i * 5 + 3] * scr.height()).toDouble()).toInt())
            }
            if (failMode == 2) u.union(badgeRect(scr))
            if (testSquare) {
                val sq = (TEST_SQUARE_DP * density).toInt() + 1
                u.union(0, scr.height() / 2, sq, scr.height() / 2 + sq)
            }
            return u
        }

        private fun badgeRect(scr: Rect): Rect {
            val w = (180 * density).toInt(); val h = (28 * density).toInt()
            val top = (40 * density).toInt()
            return Rect(scr.centerX() - w / 2, top, scr.centerX() + w / 2, top + h)
        }

        override fun onDraw(c: Canvas) {
            c.translate(-ox.toFloat(), -oy.toFloat())
            val w = scr.width().toFloat(); val h = scr.height().toFloat()
            if (failMode == 1) {
                c.drawRect(0f, 0f, w, h, solid)
                c.drawText(context.getString(R.string.blur_cover_slow), w / 2, h / 2, text)
                return
            }
            dst.set(0, 0, scr.width(), scr.height())
            val radius = 12 * density
            for (i in 0 until count) {
                r.set(rects[i * 5] * w, rects[i * 5 + 1] * h, rects[i * 5 + 2] * w, rects[i * 5 + 3] * h)
                val full = rects[i * 5 + 4].toInt() == Vision.KIND_FULL
                c.save()
                if (!full) {
                    path.reset(); path.addRoundRect(r, radius, radius, android.graphics.Path.Direction.CW); c.clipPath(path)
                } else c.clipRect(r)
                val t = thumb
                if (t != null && !t.isRecycled) c.drawBitmap(t, null, dst, bmp) else c.drawRect(r, solid)
                c.drawRect(r, tint)
                c.restore()
                if (full) c.drawText(context.getString(R.string.blur_cover_full), w / 2, h / 2, text)
            }
            if (failMode == 2) {
                val b = badgeRect(scr)
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
    }
}

/**
 * Only hosts the screen-blur overlay window: Android lets touches pass through accessibility overlays, and it does
 * not read, log or act on any screen content or event.
 */
class BlurAccessibilityService : AccessibilityService() {
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

/** True when the user (or Shizuku) turned on [BlurAccessibilityService]. */
fun Context.blurAccessibilityEnabled(): Boolean {
    val me = android.content.ComponentName(this, BlurAccessibilityService::class.java)
    val list = android.provider.Settings.Secure.getString(contentResolver,
        android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) ?: return false
    return list.split(':').any { android.content.ComponentName.unflattenFromString(it) == me }
}
