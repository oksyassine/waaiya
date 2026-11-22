package org.waaiya.app

import org.waaiya.app.WorshipSchedule.Options
import org.waaiya.app.WorshipSchedule.PrayerTime
import org.waaiya.app.WorshipSchedule.State
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Duration
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime

/** When the silence and the media mute start and end (WorshipSchedule), and the restore-only-if-unchanged rule. */
class WorshipScheduleTest {
    private val zone = ZoneId.of("Africa/Cairo")
    private fun at(date: String, hm: String) = ZonedDateTime.of(LocalDate.parse(date), LocalTime.parse(hm), zone)
        .toInstant().toEpochMilli()
    private val min = 60_000L

    /** A plain day: Fajr 05:00, Dhuhr 12:00, Asr 15:00, Maghrib 17:00, Isha 18:15, on three days. */
    private val prayers = listOf("2026-11-19", "2026-11-20", "2026-11-21").flatMap { d ->
        listOf("fajr" to "05:00", "dhuhr" to "12:00", "asr" to "15:00", "maghrib" to "17:00", "isha" to "18:15")
            .map { (p, hm) -> PrayerTime(p, at(d, hm)) }
    }
    private val silent20 = Options(silent = true, silentMinutes = 20, mute = false, muteMinutes = 5)
    private val both = Options(silent = true, silentMinutes = 20, mute = true, muteMinutes = 5)

    @Test
    fun beforeAPrayerNothingHappensAndTheAlarmIsSetForIt() {
        val p = WorshipSchedule.plan(at("2026-11-20", "11:00"), prayers, silent20, State(lastPrayer = at("2026-11-20", "05:00")))
        assertFalse(p.startSilent || p.endSilent || p.startMute || p.endMute)
        assertEquals("dhuhr", p.next!!.prayer)
        assertEquals(at("2026-11-20", "12:00"), p.wake)
    }

    @Test
    fun atThePrayerTheWindowsOpenAndEndOnTime() {
        val now = at("2026-11-20", "12:00")
        val p = WorshipSchedule.plan(now, prayers, both, State(lastPrayer = at("2026-11-20", "05:00")))
        assertTrue(p.startSilent); assertTrue(p.startMute)
        assertEquals("dhuhr", p.prayer!!.prayer)
        assertEquals(now + 20 * min, p.state.silentEnd)
        assertEquals(now + 5 * min, p.state.muteEnd)
        assertEquals(now + 5 * min, p.wake)  // the mute ends first
        assertEquals("asr", p.next!!.prayer)
        // the mute's end
        val p2 = WorshipSchedule.plan(now + 5 * min, prayers, both, p.state)
        assertTrue(p2.endMute); assertFalse(p2.endSilent); assertFalse(p2.startSilent)
        assertEquals(0L, p2.state.muteEnd)
        assertEquals(now + 20 * min, p2.wake)
        // the silence's end, then the alarm for Asr
        val p3 = WorshipSchedule.plan(now + 20 * min, prayers, both, p2.state)
        assertTrue(p3.endSilent)
        assertEquals(State(0, 0, now), p3.state)
        assertEquals(at("2026-11-20", "15:00"), p3.wake)
    }

    @Test
    fun aLateAlarmKeepsTheWindowCountedFromThePrayerTime() {
        val p = WorshipSchedule.plan(at("2026-11-20", "12:08"), prayers, silent20, State(lastPrayer = at("2026-11-20", "05:00")))
        assertTrue(p.startSilent)
        assertEquals(at("2026-11-20", "12:20"), p.state.silentEnd)
        // so late that the window is over: nothing, and that prayer is not tried again
        val q = WorshipSchedule.plan(at("2026-11-20", "12:25"), prayers, silent20, State(lastPrayer = at("2026-11-20", "05:00")))
        assertFalse(q.startSilent)
        assertEquals(at("2026-11-20", "12:00"), q.state.lastPrayer)
        assertEquals(at("2026-11-20", "15:00"), q.wake)
    }

    @Test
    fun aWindowStillOpenAtTheNextPrayerIsExtendedNotRestarted() {
        val o = Options(silent = true, silentMinutes = 90, mute = false, muteMinutes = 5)
        val maghrib = WorshipSchedule.plan(at("2026-11-20", "17:00"), prayers, o, State(lastPrayer = at("2026-11-20", "15:00")))
        assertTrue(maghrib.startSilent)
        assertEquals(at("2026-11-20", "18:15"), maghrib.wake)  // Isha comes before the end (18:30)...
        val isha = WorshipSchedule.plan(at("2026-11-20", "18:15"), prayers, o, maghrib.state)
        assertFalse(isha.startSilent); assertFalse(isha.endSilent)  // ...so Isha only moves the end
        assertTrue(isha.extendedSilent)
        assertEquals(at("2026-11-20", "19:45"), isha.state.silentEnd)
        val end = WorshipSchedule.plan(at("2026-11-20", "19:45"), prayers, o, isha.state)
        assertTrue(end.endSilent)
        assertEquals(at("2026-11-21", "05:00"), end.wake)
    }

    @Test
    fun switchingOffEndsAtOnceAndBothOffSchedulesNothing() {
        val open = State(silentEnd = at("2026-11-20", "12:20"), muteEnd = at("2026-11-20", "12:05"), lastPrayer = at("2026-11-20", "12:00"))
        val off = Options(silent = false, silentMinutes = 20, mute = false, muteMinutes = 5)
        val p = WorshipSchedule.plan(at("2026-11-20", "12:02"), prayers, off, open)
        assertTrue(p.endSilent); assertTrue(p.endMute)
        assertEquals(0L, p.wake)
        assertNull(p.next)
        // nothing open and both off: nothing at all
        val q = WorshipSchedule.plan(at("2026-11-20", "11:00"), prayers, off, State())
        assertEquals(0L, q.wake)
        assertFalse(q.startSilent || q.startMute || q.endSilent || q.endMute)
        // only one switched off: the other window goes on
        val r = WorshipSchedule.plan(at("2026-11-20", "12:02"), prayers, silent20, open)
        assertTrue(r.endMute); assertFalse(r.endSilent)
        assertEquals(at("2026-11-20", "12:20"), r.wake)
    }

    @Test
    fun aRestartInTheMiddleOfAWindowWaitsForItsEnd() {
        val open = State(silentEnd = at("2026-11-20", "12:20"), lastPrayer = at("2026-11-20", "12:00"))
        val p = WorshipSchedule.plan(at("2026-11-20", "12:10"), prayers, silent20, open)
        assertFalse(p.startSilent); assertFalse(p.endSilent)
        assertEquals(at("2026-11-20", "12:20"), p.wake)
        // back on after the end: restore at once
        val q = WorshipSchedule.plan(at("2026-11-20", "13:00"), prayers, silent20, open)
        assertTrue(q.endSilent)
        // the phone was off at the prayer time and comes back inside the window: it starts
        val r = WorshipSchedule.plan(at("2026-11-20", "12:10"), prayers, silent20, State(lastPrayer = at("2026-11-20", "05:00")))
        assertTrue(r.startSilent)
    }

    @Test
    fun turningAnOptionOnDoesNotActOnAPrayerAlreadyPassed() {
        val now = at("2026-11-20", "12:05")
        val s = WorshipSchedule.onSettingsChanged(now, State(lastPrayer = at("2026-11-19", "18:15")))
        val p = WorshipSchedule.plan(now, prayers, silent20, s)
        assertFalse(p.startSilent)
        assertEquals("asr", p.next!!.prayer)
    }

    @Test
    fun restoreOnlyWhatWaaiyaSetAndStillIs() {
        val all = WorshipSchedule.FILTER_ALL
        val priority = WorshipSchedule.FILTER_PRIORITY
        assertTrue(WorshipSchedule.shouldSilence(all))
        assertFalse(WorshipSchedule.shouldSilence(priority))   // the user's own Do Not Disturb: not ours
        assertFalse(WorshipSchedule.shouldSilence(3))          // "alarms only" / "total silence"
        assertTrue(WorshipSchedule.restoreDnd(34, priority, priority))
        assertFalse(WorshipSchedule.restoreDnd(34, all, priority))  // the user turned it off already
        assertFalse(WorshipSchedule.restoreDnd(33, 3, priority))    // the user chose another mode
        assertTrue(WorshipSchedule.restoreDnd(35, all, priority))   // Android 15: only Waaiya's own rule ends
        assertTrue(WorshipSchedule.shouldMute(mutedNow = false, volume = 7))
        assertFalse(WorshipSchedule.shouldMute(mutedNow = true, volume = 7))
        assertFalse(WorshipSchedule.shouldMute(mutedNow = false, volume = 0))
        assertTrue(WorshipSchedule.restoreMedia(mutedNow = true))
        assertFalse(WorshipSchedule.restoreMedia(mutedNow = false))   // the user raised the volume meanwhile
    }

    /** Paris, the night clocks go forward (2026-03-29 02:00 -> 03:00): no prayer is lost or doubled. */
    @Test
    fun daylightSavingNightInParis() {
        val paris = ZoneId.of("Europe/Paris")
        val now = ZonedDateTime.of(LocalDate.parse("2026-03-29"), LocalTime.parse("01:30"), paris).toInstant()
        val list = WorshipSchedule.prayersAround(now, 48.8566, 2.3522, paris, 11, 0)
        assertEquals(15, list.size)
        assertEquals(list.sortedBy { it.at }, list)
        val fajr29 = list.first { it.prayer == "fajr" && it.at > now.toEpochMilli() }
        val local = java.time.Instant.ofEpochMilli(fajr29.at).atZone(paris)
        assertEquals(LocalDate.parse("2026-03-29"), local.toLocalDate())
        assertEquals(2, local.offset.totalSeconds / 3600)  // summer time already
        val p = WorshipSchedule.plan(now.toEpochMilli(), list, silent20, State(lastPrayer = now.toEpochMilli() - 3600_000))
        assertEquals(fajr29.at, p.wake)
        // the same moment of the sun, one clock hour later: Dhuhr moves from about 13:4x to 14:4x local time,
        // but only about 20 s in real time
        val dhuhr = list.filter { it.prayer == "dhuhr" }.map { java.time.Instant.ofEpochMilli(it.at) }
        val realGap = Duration.between(dhuhr[0], dhuhr[1]).toMinutes()
        assertTrue("$realGap", realGap in 1439..1440)
        assertEquals(1, dhuhr[1].atZone(paris).hour - dhuhr[0].atZone(paris).hour)
    }

    /** New York, the night clocks go back (2026-11-01 02:00 -> 01:00): the 25-hour day has its five prayers once. */
    @Test
    fun daylightSavingNightInNewYork() {
        val ny = ZoneId.of("America/New_York")
        val now = ZonedDateTime.of(LocalDate.parse("2026-11-01"), LocalTime.parse("12:00"), ny).toInstant()
        val list = WorshipSchedule.prayersAround(now, 40.7128, -74.0060, ny, 1, 0)
        val nov1 = list.filter { java.time.Instant.ofEpochMilli(it.at).atZone(ny).toLocalDate() == LocalDate.parse("2026-11-01") }
        assertEquals(listOf("fajr", "dhuhr", "asr", "maghrib", "isha"), nov1.map { it.prayer })
        val fajr = java.time.Instant.ofEpochMilli(nov1[0].at).atZone(ny)
        assertEquals(-5, fajr.offset.totalSeconds / 3600)  // after the change (02:00 EDT -> 01:00 EST)
    }
}
