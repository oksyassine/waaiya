package org.waaiya.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.waaiya.app.StuckDetector.Action
import org.waaiya.app.StuckDetector.Phase
import org.waaiya.app.StuckDetector.Second

class StuckDetectorTest {
    private fun flowing(inDb: Int = -20, playing: Int = 1) = Second(100, inDb, playing, Phase.READ, 5, true)

    private fun run(d: StuckDetector, s: Second, n: Int): List<Action> = (1..n).map { d.second(s) }

    @Test fun normalSoundDoesNothing() {
        val d = StuckDetector()
        assertTrue(run(d, flowing(), 600).all { it == Action.NONE })
    }

    @Test fun silenceWithNothingPlayingDoesNothing() {
        val d = StuckDetector()
        assertTrue(run(d, flowing(inDb = -120, playing = 0), 600).all { it == Action.NONE })
    }

    @Test fun silentCaptureWhileAMutedAppPlaysRebuildsTheCaptureOnce() {
        val d = StuckDetector()
        val acts = run(d, flowing(inDb = -120), 50)
        assertEquals(listOf(Action.REBUILD_CAPTURE), acts.filter { it != Action.NONE })
        assertEquals("after 5 s", Action.REBUILD_CAPTURE, acts[StuckDetector.SILENT_S - 1])
        assertTrue("never ends filtering", Action.END !in acts)
    }

    @Test fun silentCaptureEpisodesAreRebuiltAtMostOnceAMinute() {
        // a feed of muted autoplaying videos: silence while "playing" again and again
        val d = StuckDetector()
        val acts = ArrayList<Action>()
        repeat(20) {
            acts += run(d, flowing(inDb = -120), 8)
            acts += run(d, flowing(inDb = -20), 2)
        }
        val rebuilds = acts.count { it == Action.REBUILD_CAPTURE }
        assertTrue("200 s: at most 4 rebuilds, was $rebuilds", rebuilds in 1..4)
    }

    @Test fun aSilenceWithinTheBackoffLeavesNoTrace() {
        val d = StuckDetector()
        run(d, flowing(inDb = -120), 8)
        run(d, flowing(inDb = -20), 2)
        val events = ArrayList<String>()
        var started = false
        repeat(10) { d.second(flowing(inDb = -120)); d.event?.let { events += it }; started = started || d.episodeStarted }
        d.second(flowing(inDb = -20)); d.event?.let { events += it }
        assertTrue("no event: $events", events.isEmpty())
        assertTrue("no snapshot", !started)
    }

    @Test fun soundBackIsLogged() {
        val d = StuckDetector()
        run(d, flowing(inDb = -120), 8)
        d.second(flowing(inDb = -30))
        assertTrue(d.event!!.startsWith("sound from the capture again"))
    }

    @Test fun outputThatDoesNotPlayIsRebuiltTwiceThenEnds() {
        val d = StuckDetector()
        val acts = ArrayList<Action>()
        for (t in 1..12) acts += d.second(Second(0, -20, 1, Phase.WRITE, t * 1000L % 4000, false))
        val done = acts.filter { it != Action.NONE }
        assertEquals(Action.REBUILD_OUTPUT, done[0])
        assertEquals(Action.REBUILD_OUTPUT, done[1])
        assertEquals(Action.END, done[2])
    }

    private val stuckWrite = Second(0, -20, 1, Phase.WRITE, 2500, false)

    @Test fun outputRebuildThatHelpsStartsOver() {
        val d = StuckDetector()
        assertEquals(listOf(Action.NONE, Action.REBUILD_OUTPUT), run(d, stuckWrite, 2))
        run(d, flowing(), 3)
        assertEquals(listOf(Action.NONE, Action.REBUILD_OUTPUT), run(d, stuckWrite, 2))
        run(d, flowing(), 3)
        assertEquals("the count started over", listOf(Action.NONE, Action.REBUILD_OUTPUT), run(d, stuckWrite, 2))
    }

    @Test fun outputThatTakesNothingWhileTheLoopRunsIsFound() {
        // Android 16, a paused track: writing returns at once, the loop runs at full speed, nothing is heard
        val d = StuckDetector()
        val acts = run(d, Second(100, -20, 1, Phase.OTHER, 1, false), 8)
        assertEquals(listOf(Action.REBUILD_OUTPUT, Action.REBUILD_OUTPUT, Action.END), acts.filter { it != Action.NONE }.take(3))
    }

    @Test fun silenceWithNothingWrittenIsNotAStuckOutput() {
        // the capture gives nothing (nothing plays): the output drains and stands still, which is normal
        val d = StuckDetector()
        assertTrue(run(d, Second(0, -120, 0, Phase.READ, 5000, false), 60).all { it == Action.NONE })
    }

    @Test fun aWriteThatWaitsWhileTheOutputPlaysIsNotStuck() {
        // a slow phone (17 ms hops): writes wait, but the output plays (its position moves)
        val d = StuckDetector()
        assertTrue(run(d, Second(55, -20, 1, Phase.WRITE, 2500, true), 60).all { it == Action.NONE })
    }

    @Test fun aSlowPhoneIsNotStuck() {
        // ARM translation on the emulator: about 55 hops a second, each 17 ms
        val d = StuckDetector()
        assertTrue(run(d, Second(55, -20, 1, Phase.ENGINE, 17, true), 600).all { it == Action.NONE })
    }

    @Test fun captureThatGivesNothingWhileAppPlaysIsRebuiltOncePerEpisode() {
        val d = StuckDetector()
        val acts = (1..10).map { d.second(Second(0, -120, 1, Phase.READ, it * 1000L, true)) }
        assertEquals(listOf(Action.REBUILD_CAPTURE), acts.filter { it != Action.NONE })
    }

    @Test fun captureThatWaitsWhileNothingPlaysIsNormal() {
        val d = StuckDetector()
        assertTrue((1..60).map { d.second(Second(0, -120, 0, Phase.READ, it * 1000L, true)) }.all { it == Action.NONE })
    }

    @Test fun aLongModelCallIsLoggedOnly() {
        val d = StuckDetector()
        val acts = (1..5).map { d.second(Second(0, -20, 1, Phase.ENGINE, it * 1000L, true)) }
        assertTrue(acts.all { it == Action.NONE })
        d.second(Second(0, -20, 1, Phase.ENGINE, 3000, true))
        assertEquals(null, d.event)  // said once
    }
}
