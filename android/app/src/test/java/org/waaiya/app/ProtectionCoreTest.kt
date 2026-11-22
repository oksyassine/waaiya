package org.waaiya.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Protection that survives a weak moment (ProtectionCore.kt): what weakens, the waiting period on a clock that a
 * reboot or a clock change cannot shorten, confirming within 15 minutes, and the PIN with its lockout.
 */
class ProtectionCoreTest {
    private class Clock(var wall: Long = 1_700_000_000_000, var elapsed: Long = 5_000_000, var boot: Int = 7) : ProtectionClock {
        override fun wallMs() = wall
        override fun elapsedMs() = elapsed
        override fun bootCount() = boot
        fun pass(ms: Long) { wall += ms; elapsed += ms }
        /** Off for [offMs], then on again for [upMs] in a new boot. */
        fun reboot(offMs: Long, upMs: Long) { wall += offMs + upMs; elapsed = upMs; boot++ }
    }

    private class Store : ProtectionStore {
        val map = HashMap<String, String>()
        override fun get(key: String) = map[key]
        override fun put(key: String, value: String?) { if (value == null) map.remove(key) else map[key] = value }
    }

    private val min = 60_000L
    private val clock = Clock()
    private val store = Store()
    private val settings = HashMap<String, Any?>(mapOf("protect_delay_minutes" to 0, "blur_women" to true,
        "blur_strictness" to 0, "filter_off_apps" to "", "gender" to "man", "keep_singing" to false))
    private val core = ProtectionCore(store, clock, { settings["protect_delay_minutes"] as Int }, { settings[it] },
        iterations = 1000)

    private fun applied(o: ProtectionCore.Outcome) { o.apply?.let { if (it.what != "stop") settings[it.what] = it.value } }

    // --- what weakens ---

    @Test fun weakeningTable() {
        val w = ProtectionRules::isWeakening
        for (k in listOf("blur_women", "blur_nudity", "blur_fail_cover", "silence_unfilterable", "hold_silence", "mute_women_singing")) {
            assertTrue(k, w(k, true, false))
            assertFalse(k, w(k, false, true))
            assertFalse(k, w(k, true, true))
        }
        assertTrue(w("keep_singing", false, true))
        assertFalse(w("keep_singing", true, false))
        assertTrue(w("blur_strictness", 0, 2))
        assertFalse(w("blur_strictness", 2, 0))
        assertTrue(w("filter_off_apps", "a", "a,b"))
        assertTrue(w("blur_off_apps", "", "x"))
        assertFalse(w("filter_off_apps", "a,b", "b"))
        assertFalse(w("filter_off_apps", "a,b", "b,a"))
        assertTrue(w("gender", "man", "woman"))
        assertFalse("first answer", w("gender", "", "man"))
        assertTrue(w("protect_delay_minutes", 60, 0))
        assertFalse(w("protect_delay_minutes", 0, 60))
        for (k in listOf("prayer_silent", "audio_stereo", "prayer_place", "prayer_sms_reply", "language"))
            assertFalse(k, w(k, true, false))
        // a value of the wrong type is refused for its type, not held back
        assertFalse(w("blur_women", true, "no"))
        assertFalse(w("gender", "man", "child"))
    }

    @Test fun gates() {
        val g = ProtectionRules::gate
        assertTrue(g("blur_women", true, false, false, 0).free)
        assertEquals(ProtectionRules.Gate(pin = false, wait = true), g("blur_women", true, false, false, 5))
        assertEquals(ProtectionRules.Gate(pin = true, wait = true), g("blur_women", true, false, true, 5))
        // raising the waiting period needs the PIN but no wait; strengthening is free without a PIN
        assertEquals(ProtectionRules.Gate(pin = true, wait = false), g("protect_delay_minutes", 5, 60, true, 5))
        assertTrue(g("protect_delay_minutes", 5, 60, false, 5).free)
        assertTrue(g("blur_women", false, true, true, 60).free)
        assertTrue(ProtectionRules.stopGate(false, 0).free)
        assertEquals(ProtectionRules.Gate(pin = true, wait = false), ProtectionRules.stopGate(true, 0))
    }

    // --- the clock ---

    @Test fun countdownSameBootIgnoresWallClock() {
        val cd = Countdown.start(10 * min, clock)
        clock.wall += 24 * 60 * min  // the wall clock moved a day forward
        assertEquals(10 * min, cd.remaining(clock))
        clock.elapsed += 3 * min
        assertEquals(7 * min, cd.remaining(clock))
    }

    @Test fun rebootCountsOnlyTimeSinceBootFromTheLastCheckpoint() {
        var cd = Countdown.start(60 * min, clock)
        clock.pass(10 * min)
        cd = cd.checkpoint(clock)  // 50 min left saved
        clock.pass(5 * min)  // not saved before the shutdown: lost, never counted
        clock.reboot(offMs = 8 * 60 * min, upMs = 2 * min)
        assertEquals(48 * min, cd.remaining(clock))
    }

    @Test fun elapsedGoingBackIsAReboot() {
        val cd = Countdown.start(30 * min, clock)
        clock.elapsed = min  // no boot count on this phone (-1 both times), but elapsed restarted
        clock.boot = 7
        assertEquals(29 * min, cd.remaining(clock))
    }

    @Test fun countdownEncoding() {
        val cd = Countdown(123, 456, -1)
        assertEquals(cd, Countdown.decode(cd.encode()))
        assertNull(Countdown.decode("x"))
    }

    // --- the waiting period ---

    @Test fun noProtectionAppliesAtOnce() {
        assertNull(core.check("blur_women", false))
        assertTrue(core.mayStop())
        assertNull(core.checkStop())
    }

    @Test fun weakeningWaitsThenNeedsConfirming() {
        settings["protect_delay_minutes"] = 15
        assertNotNull(core.check("blur_women", false))
        assertNull("strengthening goes through", core.check("blur_strictness", 0))
        val o = core.request("blur_women", false, null)
        assertEquals("pending", o.status)
        assertEquals(clock.wall + 15 * min, o.dueAt)
        assertNull(o.apply)
        clock.pass(14 * min)
        assertEquals("waiting", core.confirm().status)
        // the same request again does not restart the wait
        assertEquals("waiting", core.request("blur_women", false, null).status)
        clock.pass(min)
        assertEquals(true, core.snapshot().let { (it["pending"] as Map<*, *>)["ready"] })
        val c = core.confirm()
        assertEquals("done", c.status)
        assertEquals(ProtectionCore.Apply("blur_women", false), c.apply)
        assertNull(core.pending())
    }

    @Test fun notConfirmedInTimeLapses() {
        settings["protect_delay_minutes"] = 5
        core.request("stop", null, null)
        clock.pass(5 * min + 15 * min)
        assertNull(core.pending())
        assertEquals("none", core.confirm().status)
        assertFalse(core.mayStop())
    }

    @Test fun repeatingAReadyRequestConfirmsIt() {
        settings["protect_delay_minutes"] = 1
        assertNotNull(core.checkStop())
        core.request("stop", null, null)
        assertFalse(core.mayStop())
        clock.pass(min)
        assertTrue(core.mayStop())
        assertNull(core.checkStop())
        assertNull(core.pending())
    }

    @Test fun rebootAndClockChangeNeverShortenTheWait() {
        settings["protect_delay_minutes"] = 60
        core.request("blur_women", false, null)
        clock.pass(20 * min)
        core.checkpoint()
        clock.wall += 10 * 60 * min  // clock moved forward
        clock.reboot(offMs = 3 * 60 * min, upMs = 5 * min)
        assertEquals("waiting", core.confirm().status)
        assertEquals(35 * min, core.pending()!!.left(clock))
        clock.pass(35 * min)
        assertEquals("done", core.confirm().status)
    }

    @Test fun loweringTheDelayWaitsTheCurrentDelay() {
        settings["protect_delay_minutes"] = 240
        assertNotNull(core.check("protect_delay_minutes", 0))
        assertEquals("pending", core.request("protect_delay_minutes", 0, null).status)
        clock.pass(239 * min)
        assertEquals("waiting", core.confirm().status)
        clock.pass(min)
        applied(core.confirm())
        assertEquals(0, settings["protect_delay_minutes"])
    }

    @Test fun anAllowedChangeOfTheSameSettingDropsItsRequest() {
        settings["protect_delay_minutes"] = 5
        settings["filter_off_apps"] = "a,b"
        core.request("filter_off_apps", "a,b,c", null)
        assertNull(core.check("filter_off_apps", "a"))  // removing is allowed, and the request was about "a,b"
        assertNull(core.pending())
    }

    @Test fun cancelNeedsNothing() {
        settings["protect_delay_minutes"] = 5
        core.setPin("1234", null)
        core.request("stop", null, "1234")
        core.cancel()
        assertNull(core.pending())
    }

    @Test fun badValuesAreRefused() {
        settings["protect_delay_minutes"] = 5
        assertEquals(IllegalArgumentException::class.java,
            runCatching { core.request("blur_women", "off", null) }.exceptionOrNull()?.javaClass)
        assertEquals(IllegalArgumentException::class.java,
            runCatching { core.request("prayer_silent", false, null) }.exceptionOrNull()?.javaClass)
    }

    // --- the PIN ---

    @Test fun pbkdf2MatchesPython() {
        // python3 -c "import hashlib;print(hashlib.pbkdf2_hmac('sha256',b'1234',bytes(range(16)),1000).hex())"
        assertEquals("2240ea2a22754a3c4610356ef8e4d7acf25af2ac3d2d11866de97a8b7812c52c",
            ProtectionPin.hex(ProtectionPin.hash("1234", ByteArray(16) { it.toByte() }, 1000)))
    }

    @Test fun pinRecordHasNoDigitsAndDefaultIterations() {
        val r = ProtectionPin.record("12345678", ProtectionRules.ITERATIONS)
        val p = r.split(':')
        assertEquals("120000", p[0])
        assertEquals(32, p[1].length)  // 16-byte salt
        assertEquals(64, p[2].length)
        assertTrue(ProtectionPin.matches("12345678", r))
        assertFalse(ProtectionPin.matches("12345679", r))
        assertFalse(r.contains("12345678"))
        assertTrue(ProtectionRules.ITERATIONS >= 120_000)
    }

    @Test fun pinFormat() {
        assertFalse(ProtectionRules.pinValid("123"))
        assertFalse(ProtectionRules.pinValid("123456789"))
        assertFalse(ProtectionRules.pinValid("12a4"))
        assertTrue(ProtectionRules.pinValid("0000"))
        assertEquals(IllegalArgumentException::class.java, runCatching { core.setPin("12", null) }.exceptionOrNull()?.javaClass)
    }

    @Test fun pinWithoutDelayAsksThePinThenApplies() {
        assertEquals("done", core.setPin("4321", null).status)
        assertTrue(store.map["pin"]!!.startsWith("1000:"))
        assertEquals(ProtectionRules.Gate(pin = true, wait = false), core.check("blur_women", false))
        assertEquals("pin_needed", core.request("blur_women", false, null).status)
        assertEquals("pin_wrong", core.request("blur_women", false, "1111").status)
        val o = core.request("blur_women", false, "4321")
        assertEquals("done", o.status)
        assertEquals(ProtectionCore.Apply("blur_women", false), o.apply)
        // strengthening needs nothing, even with a PIN
        assertNull(core.check("blur_nudity", true))
        // raising the delay needs the PIN, then applies at once
        assertNotNull(core.check("protect_delay_minutes", 60))
        assertEquals(ProtectionCore.Apply("protect_delay_minutes", 60), core.request("protect_delay_minutes", 60, "4321").apply)
    }

    @Test fun pinThenWait() {
        core.setPin("4321", null)
        settings["protect_delay_minutes"] = 30
        assertEquals("pending", core.request("keep_singing", true, "4321").status)
        clock.pass(30 * min)
        assertEquals(ProtectionCore.Apply("keep_singing", true), core.confirm().apply)
    }

    @Test fun lockoutDoublesAndSurvivesTheClock() {
        core.setPin("4321", null)
        repeat(4) { assertEquals("pin_wrong", core.request("stop", null, "0000").status) }
        val first = core.request("stop", null, "0000")
        assertEquals("locked", first.status)
        assertEquals(clock.wall + 30_000, first.lockedUntil)
        // the right PIN does not help while locked, and moving the clock forward does not end it
        clock.wall += 3_600_000
        assertEquals("locked", core.request("stop", null, "4321").status)
        clock.elapsed += 30_000
        repeat(4) { assertEquals("pin_wrong", core.request("stop", null, "0000").status) }
        assertEquals(clock.wall + 60_000, core.request("stop", null, "0000").lockedUntil)
        clock.elapsed += 60_000
        assertEquals("done", core.request("stop", null, "4321").status)
        assertNull(store.map["pin_fails"])  // the right PIN resets the count
        assertEquals(30_000L, ProtectionRules.lockMs(5))
        assertEquals(120_000L, ProtectionRules.lockMs(15))
        assertEquals(0L, ProtectionRules.lockMs(6))
    }

    @Test fun changingOrRemovingThePinWaitsAndHidesTheNewOne() {
        core.setPin("4321", null)
        settings["protect_delay_minutes"] = 5
        assertEquals("pin_wrong", core.setPin("9999", "1111").status)
        assertEquals("pending", core.setPin("9999", "4321").status)
        val pend = core.snapshot()["pending"] as Map<*, *>
        assertEquals("pin_change", pend["what"])
        assertNull(pend["value"])
        clock.pass(5 * min)
        assertEquals("done", core.confirm().status)
        assertTrue(ProtectionPin.matches("9999", store.map["pin"]))
        assertEquals("pending", core.clearPin("9999").status)
        clock.pass(5 * min)
        core.confirm()
        assertFalse(core.pinSet)
    }

    @Test fun valueEncoding() {
        for (v in listOf(true, false, 3, "a,b", "", null))
            assertEquals(v, ProtectionCore.decodeValue(ProtectionCore.encodeValue(v)))
    }
}
