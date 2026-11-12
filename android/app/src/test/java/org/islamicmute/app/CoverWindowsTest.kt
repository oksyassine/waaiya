package org.islamicmute.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CoverWindowsTest {
    private fun box(l: Int, t: Int, r: Int, b: Int) = intArrayOf(l, t, r, b)
    private fun inside(p: IntArray, x: Int, y: Int) = x >= p[0] && x < p[2] && y >= p[1] && y < p[3]

    @Test fun separateCoversGetSeparateWindowsAndTheGapStaysFree() {
        val g = CoverWindows.group(listOf(box(0, 0, 100, 300), box(500, 0, 600, 300)), 8)
        assertEquals(2, g.size)
        assertTrue("the space between the covers is in no window", g.none { inside(it, 300, 150) })
    }

    @Test fun touchingStripsShareOneWindow() {
        // an outlined person: strips that overlap by a seam, and a bridge reaching the next person
        val strips = listOf(box(100, 0, 140, 50), box(90, 49, 150, 200), box(95, 199, 145, 400), box(150, 100, 300, 150),
            box(300, 0, 340, 400))
        assertEquals(1, CoverWindows.group(strips, 8).size)
    }

    @Test fun neverMoreThanMaxWindowsAndEveryCoverInside() {
        val boxes = (0 until 20).map { box(it * 50, it * 50, it * 50 + 20, it * 50 + 20) }
        val g = CoverWindows.group(boxes, 8)
        assertTrue(g.size <= 8)
        for (b in boxes) assertTrue("cover ${b.toList()} drawn", g.any { b[0] >= it[0] && b[1] >= it[1] && b[2] <= it[2] && b[3] <= it[3] })
        for (i in g.indices) for (j in i + 1 until g.size) {
            val a = g[i]; val c = g[j]
            assertTrue("windows do not overlap", a[2] < c[0] || c[2] < a[0] || a[3] < c[1] || c[3] < a[1])
        }
    }

    @Test fun emptyBoxesIgnored() {
        assertEquals(0, CoverWindows.group(listOf(box(5, 5, 5, 10)), 8).size)
    }

    @Test fun windowsStayOnTheirGroup() {
        val current = listOf(box(0, 0, 1, 1), box(500, 0, 600, 300), box(0, 0, 100, 300))
        val groups = listOf(box(2, 0, 102, 300), box(505, 0, 605, 300))
        val slot = CoverWindows.assign(groups, current)
        assertNull("the parked window stays parked", slot[0])
        assertEquals(505, slot[1]!![0])
        assertEquals(2, slot[2]!![0])
    }

    @Test fun newGroupTakesAFreeWindow() {
        val slot = CoverWindows.assign(listOf(box(10, 10, 20, 20)), listOf(box(0, 0, 1, 1), box(0, 0, 1, 1)))
        assertNotNull(slot.firstOrNull { it != null })
        assertEquals(1, slot.count { it != null })
    }
}
