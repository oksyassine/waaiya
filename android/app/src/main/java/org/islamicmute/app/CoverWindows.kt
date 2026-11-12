package org.islamicmute.app

/**
 * App-overlay host of the screen blur (no Shizuku, no accessibility service): which windows to draw the covers in.
 *
 * App-overlay covers must take the touches that land on them to stay opaque (BlurOverlay), and a window takes them
 * everywhere inside its bounds, transparent parts included. One window spanning all covers would therefore make the
 * space between two people untouchable. So covers that touch or overlap
 * (the strips of one outlined person, a bridge, a group) share a window sized to them, and separate groups get their
 * own window. Windows cost memory and a relayout each, so there are at most `max`: beyond that the two groups whose
 * joined box grows least are joined. Pure functions on [l, t, r, b] boxes in screen pixels (JVM-testable).
 */
object CoverWindows {
    /** Groups of touching boxes, at most [max], as their bounding boxes. Empty boxes are ignored. */
    fun group(boxes: List<IntArray>, max: Int): List<IntArray> {
        val g = ArrayList<IntArray>()
        for (b in boxes) if (b[2] > b[0] && b[3] > b[1]) g += b.copyOf()
        // join touching or overlapping boxes until none touch (a joined box may now reach another one)
        var again = true
        while (again) {
            again = false
            loop@ for (i in g.indices) for (j in i + 1 until g.size) {
                if (touch(g[i], g[j])) { g[i] = join(g[i], g[j]); g.removeAt(j); again = true; break@loop }
            }
        }
        while (g.size > max.coerceAtLeast(1)) {
            var bi = 0; var bj = 1; var best = Long.MAX_VALUE
            for (i in g.indices) for (j in i + 1 until g.size) {
                val grow = area(join(g[i], g[j])) - area(g[i]) - area(g[j])
                if (grow < best) { best = grow; bi = i; bj = j }
            }
            g[bi] = join(g[bi], g[bj]); g.removeAt(bj)
            // the joined box may now overlap others: join those too, so no area is drawn by two windows' edges only
            var more = true
            while (more) {
                more = false
                for (k in g.indices) if (k != bi && touch(g[bi], g[k])) {
                    g[bi] = join(g[bi], g[k]); g.removeAt(k); if (k < bi) bi--; more = true; break
                }
            }
        }
        return g
    }

    /**
     * Gives each group a window, keeping a window on the group that overlaps its current box most (fewer
     * relayouts and new surfaces from frame to frame). Returns, per window, its group or null (park it).
     */
    fun assign(groups: List<IntArray>, current: List<IntArray>): Array<IntArray?> {
        val slot = arrayOfNulls<IntArray>(current.size)
        val left = groups.toMutableList()
        while (left.isNotEmpty()) {
            var bg = -1; var bw = -1; var bo = 0L
            for ((gi, g) in left.withIndex()) for ((w, c) in current.withIndex()) {
                if (slot[w] != null) continue
                val o = overlapArea(g, c)
                if (o > bo) { bo = o; bg = gi; bw = w }
            }
            if (bg < 0) break
            slot[bw] = left.removeAt(bg)
        }
        for (g in left) {
            val w = slot.indexOfFirst { it == null }
            if (w < 0) break // cannot happen: group() made at most current.size groups
            slot[w] = g
        }
        return slot
    }

    private fun touch(a: IntArray, b: IntArray) = a[0] <= b[2] && b[0] <= a[2] && a[1] <= b[3] && b[1] <= a[3]
    private fun join(a: IntArray, b: IntArray) =
        intArrayOf(minOf(a[0], b[0]), minOf(a[1], b[1]), maxOf(a[2], b[2]), maxOf(a[3], b[3]))
    private fun area(a: IntArray) = (a[2] - a[0]).toLong() * (a[3] - a[1])
    private fun overlapArea(a: IntArray, b: IntArray): Long {
        val w = minOf(a[2], b[2]) - maxOf(a[0], b[0]); val h = minOf(a[3], b[3]) - maxOf(a[1], b[1])
        return if (w > 0 && h > 0) w.toLong() * h else 0
    }
}
