package org.waaiya.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Battery and heat figures of the diagnostics report (PowerUse) and the keep-singing snapshot (Singing.active). */
class DiagnosticsPowerTest {
    private val min = 60_000L

    @Test fun batteryPercent() {
        assertEquals(57.0, PowerUse.batteryPercent(57, 100)!!, 1e-9)
        assertEquals(50.0, PowerUse.batteryPercent(128, 256)!!, 1e-9)
        assertNull(PowerUse.batteryPercent(-1, 100))
        assertNull(PowerUse.batteryPercent(50, 0))
        assertNull(PowerUse.batteryPercent(150, 100))
    }

    @Test fun batteryPerHour() {
        // 6 % in 30 minutes = 12 % per hour
        assertEquals(12.0, PowerUse.batteryPerHour(80.0, 74.0, 30 * min, false)!!, 1e-9)
        // nothing used yet after an hour: 0 %/h, not "unknown"
        assertEquals(0.0, PowerUse.batteryPerHour(80.0, 80.0, 60 * min, false)!!, 1e-9)
        assertNull("charging", PowerUse.batteryPerHour(80.0, 74.0, 30 * min, true))
        assertNull("too short for whole percents", PowerUse.batteryPerHour(80.0, 79.0, 9 * min, false))
        assertNull("charged in between", PowerUse.batteryPerHour(70.0, 75.0, 30 * min, false))
        assertNull(PowerUse.batteryPerHour(null, 75.0, 30 * min, false))
        assertNull(PowerUse.batteryPerHour(80.0, null, 30 * min, false))
    }

    @Test fun cpuShare() {
        // 30 s of CPU in 2 minutes = a quarter of one core
        assertEquals(25.0, PowerUse.cpuShare(30_000, 2 * min)!!, 1e-9)
        // two cores busy = 200 %
        assertEquals(200.0, PowerUse.cpuShare(240_000, 2 * min)!!, 1e-9)
        assertNull(PowerUse.cpuShare(1000, 0))
        assertNull(PowerUse.cpuShare(-1, min))
    }

    @Test fun thermalNames() {
        assertEquals("none", PowerUse.thermalName(0))
        assertEquals("severe", PowerUse.thermalName(3))
        assertEquals("shutdown", PowerUse.thermalName(6))
        assertEquals("unknown (9)", PowerUse.thermalName(9))
    }

    @Test fun reportLines() {
        val p = PowerUse(startMs = 0, startCpuMs = 1_000, startPercent = 80.0, startCharging = false)
        p.noteRun("dfn3_stream_int8", mono = true)
        p.noteRun("dfn3_stream_int8", mono = true)
        p.noteRun("voice_v1_int8", mono = true)
        val r = p.report(30 * min, 1_000 + 9 * min, PowerUse.Battery(74.0, false, 365), "light")
        assertTrue(r, r.contains("(30 min)"))
        assertTrue(r, r.contains("battery 12.0% per hour (80% to 74%)"))
        assertTrue(r, r.contains("temperature 36.5 C"))
        assertTrue(r, r.contains("thermal light"))
        assertTrue(r, r.contains("30% of one core (18.0 s per minute)"))
        assertTrue(r, r.contains("ran: dfn3_stream_int8 mono, voice_v1_int8 mono"))
        assertEquals(2, r.lines().size)
    }

    @Test fun reportWhileChargingOrEarly() {
        val charging = PowerUse(0, 0, 50.0, startCharging = true)
        assertTrue(charging.report(30 * min, 0, PowerUse.Battery(60.0, false, 300), "none").contains("battery charging"))
        val plugged = PowerUse(0, 0, 50.0, startCharging = false)
        assertTrue(plugged.report(30 * min, 0, PowerUse.Battery(52.0, true, 300), "none").contains("battery charging"))
        val early = PowerUse(0, 0, 50.0, startCharging = false)
        val r = early.report(3 * min, 0, PowerUse.Battery(50.0, false, Int.MIN_VALUE), "none")
        assertTrue(r, r.contains("battery measuring"))
        assertTrue(r, r.contains("temperature not known"))
        assertTrue(r, r.contains("ran: ?"))
        assertTrue(early.report(30 * min, 0, null, "none").contains("battery not known"))
    }

    @Test fun singingActiveOnlyWhenItsModelFilters() {
        assertTrue(Singing.active(true, FilterService.State.FILTERING))
        assertFalse("failed model: silent, not active", Singing.active(true, FilterService.State.MODEL_FAILED))
        assertFalse(Singing.active(false, FilterService.State.FILTERING))
        assertFalse("not running", Singing.active(null, FilterService.State.STOPPED))
    }
}
