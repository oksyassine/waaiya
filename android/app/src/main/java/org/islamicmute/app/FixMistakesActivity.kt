package org.islamicmute.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

/**
 * "Cover an area": a full-screen, see-through screen over the app the user is in. He drags a rectangle; "Cover it"
 * adds it as a hand cover ([FixMistakes.addHandCover]), drawn opaque by the blur's cover host until "Remove hand
 * covers" or until the blur stops. Opened from the filter's notification and from the Screen page.
 *
 * Coordinates are the touch's raw screen position over the real display size, the same frame as the blur's covers
 * ([BlurOverlay.screen]).
 */
class FixMistakesActivity : Activity() {
    override fun attachBaseContext(base: Context) { super.attachBaseContext(Lang.wrap(base)) }

    companion object {
        fun intent(ctx: Context): Intent = Intent(ctx, FixMistakesActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_HISTORY or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
    }

    private lateinit var picker: PickerView
    private lateinit var cover: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (ScreenBlur.state == null) {
            Toast.makeText(this, R.string.notif_fix_picker_no_blur, Toast.LENGTH_LONG).show()
            finish()
            return
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN)
        if (Build.VERSION.SDK_INT >= 28) window.attributes = window.attributes.apply {
            layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
        val d = resources.displayMetrics.density
        val root = FrameLayout(this)
        picker = PickerView(this) { has -> cover.isEnabled = has }
        root.addView(picker, FrameLayout.LayoutParams(-1, -1))
        val hint = TextView(this).apply {
            text = getString(R.string.notif_fix_picker_hint)
            setTextColor(Color.WHITE)
            textSize = 16f
            gravity = Gravity.CENTER
            setPadding((16 * d).toInt(), (12 * d).toInt(), (16 * d).toInt(), (12 * d).toInt())
            setBackgroundColor(Color.argb(200, 20, 20, 20))
        }
        root.addView(hint, FrameLayout.LayoutParams(-1, -2, Gravity.TOP).apply { topMargin = (48 * d).toInt() })
        val bar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.argb(200, 20, 20, 20))
            setPadding((8 * d).toInt(), (8 * d).toInt(), (8 * d).toInt(), (8 * d).toInt())
        }
        // the screen's theme is see-through and plain: the buttons take the phone's own look
        val themed = android.view.ContextThemeWrapper(this, android.R.style.Theme_DeviceDefault)
        fun button(text: Int, onClick: () -> Unit) = Button(themed).apply {
            setText(text)
            setOnClickListener { onClick() }
            bar.addView(this, LinearLayout.LayoutParams(0, -2, 1f).apply { marginStart = (4 * d).toInt(); marginEnd = (4 * d).toInt() })
        }
        button(R.string.notif_fix_picker_cancel) { finish() }
        if (FixMistakes.handCoverCount > 0) button(R.string.notif_fix_remove_covers) { FixMistakes.clearHandCovers(this); finish() }
        cover = button(R.string.notif_fix_picker_cover) { coverIt() }
        cover.isEnabled = false
        root.addView(bar, FrameLayout.LayoutParams(-1, -2, Gravity.BOTTOM).apply { bottomMargin = (56 * d).toInt() })
        setContentView(root)
    }

    private fun coverIt() {
        val r = picker.rect() ?: return
        val scr = screen()
        val ok = FixMistakes.addHandCover(this, r.left / scr.width(), r.top / scr.height(),
            r.right / scr.width(), r.bottom / scr.height())
        if (!ok) Toast.makeText(this, R.string.notif_fix_picker_no_blur, Toast.LENGTH_LONG).show()
        finish()
    }

    private fun screen(): Rect {
        val wm = getSystemService(WindowManager::class.java)
        if (Build.VERSION.SDK_INT >= 30) return wm.maximumWindowMetrics.bounds
        val p = android.graphics.Point()
        @Suppress("DEPRECATION") wm.defaultDisplay.getRealSize(p)
        return Rect(0, 0, p.x, p.y)
    }

    /** Dims the screen a little and shows the rectangle being dragged (in raw screen coordinates). */
    private class PickerView(ctx: Context, val onRect: (Boolean) -> Unit) : View(ctx) {
        private var x0 = 0f; private var y0 = 0f; private var x1 = 0f; private var y1 = 0f
        private var has = false
        private val scrim = Paint().apply { color = Color.argb(70, 0, 0, 0) }
        private val fill = Paint().apply { color = ctx.getColor(R.color.surface) }
        private val edge = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = ctx.getColor(R.color.primary); style = Paint.Style.STROKE; strokeWidth = 3 * ctx.resources.displayMetrics.density
        }
        private val loc = IntArray(2)
        private val r = RectF()

        /** The rectangle in screen pixels, or null when none was dragged. */
        fun rect(): RectF? = if (!has) null else RectF(minOf(x0, x1), minOf(y0, y1), maxOf(x0, x1), maxOf(y0, y1))

        override fun onTouchEvent(e: MotionEvent): Boolean {
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> { x0 = e.rawX; y0 = e.rawY; x1 = x0; y1 = y0; has = false }
                MotionEvent.ACTION_MOVE, MotionEvent.ACTION_UP -> {
                    x1 = e.rawX; y1 = e.rawY
                    val min = 12 * resources.displayMetrics.density
                    has = Math.abs(x1 - x0) >= min && Math.abs(y1 - y0) >= min
                    onRect(has)
                }
            }
            invalidate()
            return true
        }

        override fun onDraw(c: Canvas) {
            c.drawRect(0f, 0f, width.toFloat(), height.toFloat(), scrim)
            if (x0 == x1 && y0 == y1) return
            getLocationOnScreen(loc)
            r.set(minOf(x0, x1) - loc[0], minOf(y0, y1) - loc[1], maxOf(x0, x1) - loc[0], maxOf(y0, y1) - loc[1])
            c.drawRect(r, fill)   // as it will look: opaque
            c.drawRect(r, edge)
        }
    }
}
