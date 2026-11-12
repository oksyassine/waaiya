package org.islamicmute.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LoadMonitorTest {
    private val ms = 1_000_000L

    /** Feeds [hops] hops of [workMs] each; returns the actions that were not NONE. */
    private fun LoadMonitor.run(hops: Int, workMs: Double, underruns: () -> Int = { 0 }, fill: Int = -1) =
        (0 until hops).map { hop((workMs * ms).toLong(), underruns(), fill) }.filter { it != LoadMonitor.Action.NONE }

    @Test fun fastPhoneStaysStereo() {
        val m = LoadMonitor()
        assertTrue(m.run(3000, 3.0).isEmpty())
        assertFalse(m.mono); assertFalse(m.tooSlow)
        assertEquals(3.0, m.avgMs, 0.01)
        assertEquals(0.0, m.lateShare, 0.0)
    }

    @Test fun warmUpIsNotJudged() {
        val m = LoadMonitor()
        // the first second is slow (model warm-up: 25 hops of 40 ms), then the phone is fast
        assertTrue(m.run(25, 40.0).isEmpty())
        assertTrue(m.run(1000, 2.0).isEmpty())
        assertFalse(m.mono)
    }

    @Test fun slowPhoneGoesMonoOnce() {
        val m = LoadMonitor()
        m.run(LoadMonitor.WARMUP_HOPS, 9.0)
        val actions = m.run(LoadMonitor.WINDOW_HOPS, 9.0)
        assertEquals(listOf(LoadMonitor.Action.GO_MONO), actions)
        assertTrue(m.mono); assertFalse(m.tooSlow)
        // mono halves the work: fine from here on
        assertTrue(m.run(2000, 4.5).isEmpty())
        assertFalse(m.tooSlow)
    }

    @Test fun tooSlowEvenInMono() {
        val m = LoadMonitor()
        m.run(50, 20.0)  // the warm-up second
        // 50 late hops in a row are enough: no waiting for the end of a 2 s window (which would last 4 s here)
        assertEquals(listOf(LoadMonitor.Action.GO_MONO), m.run(LoadMonitor.EARLY_LATE_HOPS, 20.0))
        m.run(LoadMonitor.EARLY_LATE_HOPS, 11.0)
        assertFalse("one slow stretch in mono is not enough", m.tooSlow)
        m.run(LoadMonitor.EARLY_LATE_HOPS, 11.0)
        assertTrue(m.tooSlow)
        // it recovers only after several clearly fast windows (the phone cooled down, another app stopped)
        m.run(LoadMonitor.WINDOW_HOPS * 2, 5.0)
        assertTrue(m.tooSlow)
        m.run(LoadMonitor.WINDOW_HOPS, 5.0)
        assertFalse(m.tooSlow)
    }

    @Test fun aHopelessPhoneIsToldWithinSeconds() {
        // 94 ms per hop in stereo, 47 ms in mono (the release build on an emulator): count the real time
        val m = LoadMonitor()
        var wallMs = 0.0
        var monoAt = -1.0
        while (!m.tooSlow && wallMs < 60_000) {
            val work = if (m.mono) 47.0 else 94.0
            wallMs += work
            if (m.hop((work * ms).toLong(), 0) == LoadMonitor.Action.GO_MONO) monoAt = wallMs
        }
        assertTrue("mono within 8 s, was ${monoAt / 1000} s", monoAt in 0.0..8000.0)
        assertTrue("told within 12 s, was ${wallMs / 1000} s", m.tooSlow && wallMs < 12_000)
    }

    @Test fun startsInMonoWhenLearned() {
        val m = LoadMonitor(mono = true)
        m.run(LoadMonitor.WARMUP_HOPS, 11.0)
        assertTrue(m.run(LoadMonitor.WINDOW_HOPS, 11.0).isEmpty())  // nothing lighter than mono to switch to
        m.run(LoadMonitor.WINDOW_HOPS, 11.0)
        assertTrue(m.tooSlow)
    }

    @Test fun manyLateHopsCountEvenWithALowAverage() {
        val m = LoadMonitor()
        m.run(LoadMonitor.WARMUP_HOPS, 2.0)
        // 1 hop in 5 takes 14 ms (a small core, a busy phone): the average is 4.4 ms but 20% of the hops are late
        val actions = (0 until LoadMonitor.WINDOW_HOPS).map {
            m.hop(((if (it % 5 == 0) 14.0 else 2.0) * ms).toLong(), 0)
        }.filter { it != LoadMonitor.Action.NONE }
        assertEquals(listOf(LoadMonitor.Action.GO_MONO), actions)
    }

    @Test fun silenceIsNotJudged() {
        val m = LoadMonitor()
        m.run(LoadMonitor.WARMUP_HOPS, 0.0)
        // 2 s with only 20 hops of sound, all slow: too little to judge the phone
        val actions = (0 until LoadMonitor.WINDOW_HOPS).map { m.hop(((if (it < 20) 12.0 else 0.01) * ms).toLong(), 0) }
        assertTrue(actions.all { it == LoadMonitor.Action.NONE })
        assertFalse(m.mono)
    }

    @Test fun gapsOnAFastPhoneGrowTheBuffer() {
        val m = LoadMonitor()
        var u = 0
        m.run(LoadMonitor.WARMUP_HOPS, 3.0)
        // a gap in every window although the phone is fast enough
        repeat(6) { i ->
            u++
            val a = m.run(LoadMonitor.WINDOW_HOPS, 3.0, { u })
            if (i < LoadMonitor.MAX_EXTRA_HOPS) assertEquals(listOf(LoadMonitor.Action.GROW_BUFFER), a)
            else assertTrue("the buffer stops growing at its limit", a.isEmpty())
        }
        assertEquals(LoadMonitor.MAX_EXTRA_HOPS, m.extraHops)
        assertEquals(6, m.underruns)
        assertFalse(m.mono)
    }

    @Test fun gapsDuringWarmUpAreNotCounted() {
        val m = LoadMonitor()
        var u = 0
        m.run(LoadMonitor.WARMUP_HOPS, 3.0, { ++u })
        assertTrue(m.run(LoadMonitor.WINDOW_HOPS, 3.0, { u }).isEmpty())
        assertEquals(0, m.underruns)
    }

    @Test fun unusedDelayIsGivenBackDuringSilence() {
        val m = LoadMonitor(hopFrames = 480)
        m.run(LoadMonitor.WARMUP_HOPS, 3.0)
        // 5 hops (50 ms) wait in the output buffer the whole time; hops take 3 ms, so 2 are kept: 3 to spare
        m.run(LoadMonitor.WINDOW_HOPS * (LoadMonitor.CALM_WINDOWS - 1), 3.0, fill = 5 * 480)
        assertFalse("not before the calm stretch is over", m.takeTrim(silent = true))
        m.run(LoadMonitor.WINDOW_HOPS, 3.0, fill = 5 * 480)
        assertFalse("never in the middle of sound", m.takeTrim(silent = false))
        repeat(3) { assertTrue(m.takeTrim(silent = true)) }
        assertFalse("only what is spare", m.takeTrim(silent = true))
        assertEquals(3, m.trimmedHops)
    }

    @Test fun aPhoneWithUnevenHopsKeepsMoreWaiting() {
        val m = LoadMonitor(hopFrames = 480)
        m.run(LoadMonitor.WARMUP_HOPS, 3.0)
        m.hop(34 * ms, 0, 6 * 480)  // one hop took 34 ms: 4 hops of sound are needed to cover it, plus one
        m.run(LoadMonitor.WINDOW_HOPS * LoadMonitor.CALM_WINDOWS, 3.0, fill = 6 * 480)
        assertEquals(5, m.keepHops)
        assertTrue(m.takeTrim(silent = true))
        assertFalse("6 waiting, 5 kept: one to spare", m.takeTrim(silent = true))
        // a minute later the slow hop is forgotten
        m.run(LoadMonitor.WINDOW_HOPS * LoadMonitor.JITTER_WINDOWS, 3.0, fill = 2 * 480)
        assertEquals(LoadMonitor.KEEP_HOPS, m.keepHops)
    }

    @Test fun noGiveBackWhenLittleIsWaitingOrGapsHappen() {
        val m = LoadMonitor(hopFrames = 480)
        m.run(LoadMonitor.WARMUP_HOPS, 3.0)
        m.run(LoadMonitor.WINDOW_HOPS * LoadMonitor.CALM_WINDOWS, 3.0, fill = 2 * 480)
        assertFalse(m.takeTrim(silent = true))
        // plenty waiting, but a gap in every window: the count never gets to the end
        var u = 0
        repeat(LoadMonitor.CALM_WINDOWS * 2) {
            u++
            m.run(LoadMonitor.WINDOW_HOPS, 3.0, { u }, fill = 6 * 480)
        }
        assertFalse(m.takeTrim(silent = true))
    }
}
