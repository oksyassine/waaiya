package org.waaiya.app

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

    /**
     * The live loop over [hours] of sound, with the capture's clock off the output's by [ppm] (parts per million,
     * + = the capture runs faster). Reads a hop (waiting while the capture fills), skips it or writes it (waiting
     * while the output buffer of [bufferHops] is full), adds a hop of silence when told. One hop in [silentEvery] holds
     * no sound (0: none; then every hop is merely quiet). Returns (sound lost to a full capture, output dropouts after
     * the warm-up, the most sound ever waiting in the capture, in hops).
     */
    private fun drift(m: LoadMonitor, ppm: Double, hours: Double, bufferHops: Int = 2, silentEvery: Int = 20):
        Triple<Double, Int, Double> {
        val hop = 480.0
        val r = 1 + ppm * 1e-6           // capture frames per output frame
        val capacity = FilterService.CAPTURE_HOPS * hop
        val buffer = bufferHops * hop
        var fill = buffer; var backlog = 0.0; var lost = 0.0; var dropouts = 0; var most = 0.0
        val hops = (hours * 3600 * 100).toLong()
        fun pass(dt: Double) {          // dt output frames of time
            fill -= dt
            if (fill < 0) { if (m.hops > LoadMonitor.WARMUP_HOPS) dropouts++; fill = 0.0 }
            backlog += r * dt
            if (backlog > capacity) { lost += backlog - capacity; backlog = capacity }
            if (backlog > most) most = backlog
        }
        fun write() { if (fill + hop > buffer) pass(fill + hop - buffer); fill += hop }
        for (k in 0 until hops) {
            if (backlog < hop) pass((hop - backlog) / r)
            backlog -= hop
            val silent = silentEvery > 0 && k % silentEvery == 0L
            if (!m.takeTrim(silent, quiet = true)) {
                write()
                if (m.takePad(silent, quiet = true)) write()
            }
            m.hop(3 * ms, dropouts, (fill + backlog).toInt())
        }
        return Triple(lost, dropouts, most / hop)
    }

    @Test fun captureFasterThanTheOutput() {
        val m = LoadMonitor(hopFrames = 480)
        val (lost, dropouts, most) = drift(m, ppm = 60.0, hours = 3.0)
        assertEquals("no sound lost to a full capture", 0.0, lost, 0.0)
        assertEquals(0, dropouts)
        assertTrue("the delay stays short (most waiting in the capture: $most hops)", most < 3.0)
        // 60 ppm x 3 h x 48 kHz = 31 104 frames = 64.8 hops: what drifted is given back, no more
        assertTrue("given back: ${m.trimmedHops}", m.trimmedHops in 60..70)
    }

    @Test fun captureSlowerThanTheOutput() {
        val m = LoadMonitor(hopFrames = 480)
        val (lost, dropouts, _) = drift(m, ppm = -60.0, hours = 3.0)
        assertEquals(0.0, lost, 0.0)
        assertEquals("the output never runs dry", 0, dropouts)
        assertTrue("silence added: ${m.paddedHops}", m.paddedHops in 60..70)
    }

    @Test fun noDriftNothingToDo() {
        for (b in listOf(1, 2, 4)) {
            val m = LoadMonitor(hopFrames = 480)
            val (lost, dropouts, _) = drift(m, ppm = 0.0, hours = 1.0, bufferHops = b)
            assertEquals(0.0, lost, 0.0)
            assertEquals(0, dropouts)
            assertTrue("buffer $b: at most a hop or two set once (trim ${m.trimmedHops}, pad ${m.paddedHops})",
                m.trimmedHops + m.paddedHops <= 2)
        }
    }

    @Test fun driftWithoutSilentHops() {
        // a recording with no hop of digital silence for hours: quiet hops are taken after 10 s
        for (ppm in listOf(60.0, -60.0)) {
            val m = LoadMonitor(hopFrames = 480)
            val (lost, dropouts, _) = drift(m, ppm = ppm, hours = 2.0, silentEvery = 0)
            assertEquals("ppm $ppm", 0.0, lost, 0.0)
            assertEquals("ppm $ppm", 0, dropouts)
        }
    }

    @Test fun padOnlyWhenTooLittleWaits() {
        val m = LoadMonitor(hopFrames = 480)
        m.run(LoadMonitor.WARMUP_HOPS, 3.0)
        m.run(LoadMonitor.WINDOW_HOPS * LoadMonitor.CALM_WINDOWS, 3.0, fill = 2 * 480)
        assertFalse("2 hops waiting, 2 kept: nothing to add", m.takePad(silent = true))
        m.run(LoadMonitor.WINDOW_HOPS * LoadMonitor.CALM_WINDOWS, 3.0, fill = 480 + 100)
        assertFalse("never in the middle of sound", m.takePad(silent = false, quiet = false))
        assertTrue(m.takePad(silent = true))
        assertFalse("one hop was missing", m.takePad(silent = true))
        assertEquals(1, m.paddedHops)
    }
}
