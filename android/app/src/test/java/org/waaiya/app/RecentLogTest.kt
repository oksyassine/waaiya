package org.waaiya.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class RecentLogTest {
    private fun tmp() = File.createTempFile("recent", ".txt").also { it.delete(); it.deleteOnExit() }

    @Test fun keepsTheLastTwoMinutes() {
        val log = RecentLog(null)
        repeat(500) { log.second("line $it") }
        assertEquals(RecentLog.SECONDS, log.liveLines().size)
        assertEquals("line 499", log.liveLines().last())
    }

    @Test fun snapshotSurvivesAStopAndANewProcess() {
        val f = tmp()
        val log = RecentLog(f)
        repeat(90) { log.second("s$it") }
        log.event("stuck found")
        log.snapshot("user_stop", "Before the stop")
        log.clearLive()
        val next = RecentLog(f)  // a new process
        val snap = next.snapshots().single()
        assertEquals("user_stop", snap.kind)
        assertEquals("a stop keeps all it has, up to two minutes", 90, snap.lines.size)
        assertEquals("s89", snap.lines.last())
        assertEquals(listOf("stuck found"), next.eventLines())
        assertTrue("a clean stop leaves no previous-run minute", next.snapshots().none { it.kind == RecentLog.PREVIOUS_RUN })
    }

    @Test fun aProcessThatEndedWhileFilteringLeavesItsMinute() {
        val f = tmp()
        val log = RecentLog(f)
        repeat(30) { log.second("s$it") }
        log.flush()  // the watchdog saves every few seconds; then the process is gone
        val next = RecentLog(f)
        val prev = next.snapshots().single { it.kind == RecentLog.PREVIOUS_RUN }
        assertEquals(30, prev.lines.size)
        assertTrue(next.liveLines().isEmpty())
        assertTrue(next.report(live = false).contains("previous run"))
    }

    @Test fun theLastFewOfEachKindAreKept() {
        val f = tmp()
        val log = RecentLog(f)
        for (x in listOf("a", "b", "c", "d")) { log.second(x); log.snapshot("stuck", "Stuck", 60) }
        log.second("e"); log.snapshot("user_stop", "Stop")
        val kept = RecentLog(f).snapshots()
        assertEquals("three stuck, the newest", listOf("d", "c", "b"),
            kept.filter { it.kind == "stuck" }.map { it.lines.last() }.reversed())
        assertEquals(1, kept.count { it.kind == "user_stop" })
        assertTrue(RecentLog(f).report(false).contains("Stuck (saved "))
    }

    @Test fun reportHasEventsLiveLinesAndSnapshots() {
        val log = RecentLog(null)
        log.event("e1"); log.second("now"); log.snapshot("self_stop", "Before it stopped by itself")
        val r = log.report(live = true)
        assertTrue(r.contains("  e1"))
        assertTrue(r.contains("Last minute, one line per second:\n  now"))
        assertTrue(r, Regex("Before it stopped by itself \\(saved [\\d-]+ [\\d:]+\\):\n  now").containsMatchIn(r))
    }
}
