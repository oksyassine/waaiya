package org.islamicmute.app

import org.islamicmute.app.WorshipSmsRules.Decision
import org.islamicmute.app.WorshipSmsRules.Ringing
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** When the SMS reply during prayer goes out (WorshipSmsRules). */
class WorshipSmsRulesTest {
    private val min = 60_000L
    private val dhuhr = 1_795_000_000_000L
    private val prayers = listOf(
        WorshipSchedule.PrayerTime("fajr", dhuhr - 7 * 60 * min),
        WorshipSchedule.PrayerTime("dhuhr", dhuhr),
        WorshipSchedule.PrayerTime("asr", dhuhr + 3 * 60 * min),
    )

    @Test
    fun theWindowIsTheSilentMinutesFromEachPrayerTime() {
        assertEquals(dhuhr, WorshipSmsRules.window(dhuhr, prayers, 20))
        assertEquals(dhuhr, WorshipSmsRules.window(dhuhr + 19 * min, prayers, 20))
        assertNull(WorshipSmsRules.window(dhuhr + 20 * min, prayers, 20))
        assertNull(WorshipSmsRules.window(dhuhr - 1, prayers, 20))
        assertEquals(dhuhr + 3 * 60 * min, WorshipSmsRules.window(dhuhr + 3 * 60 * min + 5 * min, prayers, 20))
    }

    @Test
    fun numbersThatMayGetAnSms() {
        assertEquals("+201001234567", WorshipSmsRules.normalize("+20 100 123 4567"))
        assertEquals("+201001234567", WorshipSmsRules.normalize("00201001234567"))
        assertEquals("0612345678", WorshipSmsRules.normalize("06 12 34 56 78"))
        assertEquals("2125550123", WorshipSmsRules.normalize("(212) 555-0123"))
        for (bad in listOf(null, "", "  ", "-1", "-2", "Private", "Unknown", "UNKNOWN", "12345", "3434", "*123#", "Bank"))
            assertNull(bad.toString(), WorshipSmsRules.normalize(bad))
    }

    private fun decide(
        now: Long = dhuhr + 2 * min,
        ringing: Ringing? = Ringing("+201001234567", dhuhr + 2 * min - 5_000),
        delay: Int = 5,
        window: Long? = dhuhr,
        sent: Set<String> = emptySet(),
        roaming: Boolean = false,
        enabled: Boolean = true,
    ) = WorshipSmsRules.decide(enabled, now, ringing, delay, window, sent, roaming)

    @Test
    fun aCallStillRingingAfterTheDelayInsideAPrayerGetsOneSms() {
        assertEquals(Decision.SEND, decide())
        assertEquals(Decision.ALREADY_SENT, decide(sent = setOf("+201001234567")))  // once per number per prayer
        assertEquals(Decision.SEND, decide(sent = setOf("+201009999999")))           // another number
    }

    @Test
    fun answeredRejectedOrEndedCallsGetNothing() {
        assertEquals(Decision.NOT_RINGING, decide(ringing = null))
        // still ringing but not long enough yet
        assertEquals(Decision.TOO_EARLY, decide(ringing = Ringing("+201001234567", dhuhr + 2 * min - 2_000)))
        assertEquals(Decision.TOO_EARLY, decide(delay = 10))
    }

    @Test
    fun outsidePrayerHiddenNumbersRoamingAndOffGetNothing() {
        assertEquals(Decision.OUTSIDE_PRAYER, decide(window = null))
        assertEquals(Decision.NO_NUMBER, decide(ringing = Ringing(null, dhuhr)))
        assertEquals(Decision.NO_NUMBER, decide(ringing = Ringing("-2", dhuhr)))
        assertEquals(Decision.NO_NUMBER, decide(ringing = Ringing("88888", dhuhr)))
        assertEquals(Decision.ROAMING, decide(roaming = true))
        assertEquals(Decision.OFF, decide(enabled = false))
    }
}
