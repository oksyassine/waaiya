package org.waaiya.app

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.util.AttributeSet
import android.view.View

/** The clip as a bar, with the parts where music (or percussion only) was heard marked. Time runs left to right
 *  in every language, as on a player's seek bar. */
class MusicTimelineView @JvmOverloads constructor(ctx: Context, attrs: AttributeSet? = null) : View(ctx, attrs) {
    private var durationS = 0.0
    private var parts: List<MusicRule.Part> = emptyList()
    private var percussion = false
    private val track = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = ctx.getColor(R.color.surface_variant) }
    private val mark = Paint(Paint.ANTI_ALIAS_FLAG)
    private val r = RectF()

    fun set(durationS: Double, parts: List<MusicRule.Part>, percussion: Boolean) {
        this.durationS = durationS
        this.parts = parts
        this.percussion = percussion
        mark.color = context.getColor(if (percussion) R.color.on_warning_container else R.color.primary)
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        val h = height.toFloat()
        val w = width.toFloat()
        val rad = h / 2f
        r.set(0f, 0f, w, h)
        canvas.drawRoundRect(r, rad, rad, track)
        if (durationS <= 0) return
        canvas.save()
        canvas.clipPath(android.graphics.Path().apply { addRoundRect(r, rad, rad, android.graphics.Path.Direction.CW) })
        for (p in parts) {
            val a = (p.start / durationS * w).toFloat()
            val b = (p.end / durationS * w).toFloat().coerceAtLeast(a + 2f)
            canvas.drawRect(a, 0f, b, h, mark)
        }
        canvas.restore()
    }
}
