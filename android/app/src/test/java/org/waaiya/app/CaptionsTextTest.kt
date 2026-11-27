package org.waaiya.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** The captions screen's text, sizes, colours and "slow phone" note (CaptionsText in Captions.kt). */
class CaptionsTextTest {
    @Test fun linesAreAddedTrimmedAndCapped() {
        var shown = CaptionsText.append(emptyList(), listOf(" الحمد لله ", "", "  "))
        assertEquals(listOf("الحمد لله"), shown)
        shown = CaptionsText.append(shown, (1..5).map { "سطر $it" }, max = 3)
        assertEquals(listOf("سطر 3", "سطر 4", "سطر 5"), shown)
    }

    @Test fun sizesStayInRange() {
        var sp = CaptionsText.DEFAULT_SP
        repeat(20) { sp = CaptionsText.bigger(sp) }
        assertEquals(CaptionsText.MAX_SP, sp)
        repeat(20) { sp = CaptionsText.smaller(sp) }
        assertEquals(CaptionsText.MIN_SP, sp)
        // up then down comes back to where it was
        for (start in listOf(24, 34, 40, 48)) assertEquals(start, CaptionsText.smaller(CaptionsText.bigger(start)))
    }

    @Test fun coloursGoRound() {
        var i = 0
        val seen = mutableSetOf<Int>()
        repeat(CaptionsText.SCHEMES.size) { seen += i; i = CaptionsText.nextScheme(i) }
        assertEquals(0, i)
        assertEquals(CaptionsText.SCHEMES.size, seen.size)
        for ((fg, bg) in CaptionsText.SCHEMES) assertTrue(fg != bg)
    }

    @Test fun slowOnlyAfterSeveralSlowRuns() {
        val m = CaptionsText.SlowMeter()
        assertFalse(m.add(2000f, 2f))          // one cold start is not "slow"
        assertFalse(m.add(300f, 2f))
        assertFalse(m.add(300f, 2f))
        assertFalse(m.add(300f, 2f))
        val s = CaptionsText.SlowMeter()
        repeat(3) { s.add(1500f, 2f) }
        assertTrue(s.add(1500f, 2f))
        assertFalse(CaptionsText.SlowMeter().add(5000f, 0.2f))  // a short line's time says nothing
    }
}
