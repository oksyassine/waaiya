package org.islamicmute.app

import org.islamicmute.app.WorshipTimes.Prayer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.time.Duration
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId

/**
 * The prayer times against independently published timetables (src/test/resources/worship_reference.tsv: each
 * row names its source, the URL and the day it was fetched), within ±2 minutes. Plus the method table's order, the
 * Umm al-Qura Ramadan rule, the Hanafi Asr and the high-latitude rule.
 */
class WorshipTimesTest {
    @Test
    fun methodIndicesNeverMove() {
        // Settings.prayerMethod stores the index: the order is part of the saved settings (and of worship.dart)
        assertEquals(listOf("mwl", "isna", "egypt", "umm_al_qura", "karachi", "tehran", "gulf", "kuwait", "qatar",
            "singapore", "turkey", "france", "morocco", "indonesia", "malaysia", "dubai"), WorshipTimes.METHODS.map { it.key })
    }

    private class Row(val line: Int, val f: Map<String, String>)

    private fun reference(): List<Row> {
        val lines = File("src/test/resources/worship_reference.tsv").readLines()
        val body = lines.withIndex().filter { (_, l) -> l.isNotBlank() && !l.startsWith("#") }
        val header = body.first().value.split('\t')
        return body.drop(1).map { (i, l) -> Row(i + 1, header.zip(l.split('\t')).toMap()) }
    }

    @Test
    fun matchesPublishedTimetables() {
        val rows = reference()
        assertTrue("${rows.size} reference days", rows.size >= 40)
        val failures = mutableListOf<String>()
        var compared = 0
        assertTrue("every official source is asserted", rows.filter { it.f["source_kind"] == "official" }.all { it.f["checked"] == "yes" })
        for (r in rows) {
            val f = r.f
            val zone = ZoneId.of(f.getValue("tz"))
            val date = LocalDate.parse(f.getValue("date"))
            // the published table's clock (DST change days included) is the time zone's
            assertEquals("line ${r.line}", java.time.ZoneOffset.of(f.getValue("utc_offset")),
                zone.rules.getOffset(date.atTime(12, 0)))
            if (f["checked"] != "yes") continue  // recorded only: the reason is in the file's header
            val day = WorshipTimes.compute(date, f.getValue("lat").toDouble(), f.getValue("lon").toDouble(), zone,
                f.getValue("method").toInt(), f.getValue("asr_rule").toInt())
            if (day == null) { failures += "line ${r.line}: no times"; continue }
            for (p in Prayer.entries) {
                val want = f[p.key]?.takeIf { it.isNotBlank() } ?: continue
                val got = day[p].atZone(zone)
                val wanted = date.atTime(LocalTime.parse(want)).atZone(zone)
                val diff = Duration.between(wanted, got).toMinutes()
                compared++
                if (kotlin.math.abs(diff) > 2)
                    failures += "line ${r.line} ${f["city"]} $date ${p.key}: published $want, computed ${got.toLocalTime()} ($diff min)"
            }
        }
        assertTrue("only $compared times compared", compared >= 200)
        assertTrue(failures.joinToString("\n"), failures.isEmpty())
    }

    @Test
    fun ummAlQuraIshaIs120MinutesInRamadan() {
        val makkah = ZoneId.of("Asia/Riyadh")
        fun ishaAfterMaghrib(d: String): Long {
            val day = WorshipTimes.compute(LocalDate.parse(d), 21.4225, 39.8262, makkah, 3, 0)!!
            return Duration.between(day[Prayer.MAGHRIB], day[Prayer.ISHA]).toMinutes()
        }
        assertTrue(WorshipTimes.isRamadan(LocalDate.parse("2027-02-20")))
        assertEquals(120, ishaAfterMaghrib("2027-02-20"))  // 13 Ramadan 1448
        assertEquals(90, ishaAfterMaghrib("2026-11-20"))
        // the Gulf method has no Ramadan rule
        val gulf = WorshipTimes.compute(LocalDate.parse("2027-02-20"), 25.2048, 55.2708, ZoneId.of("Asia/Dubai"), 6, 0)!!
        assertEquals(90, Duration.between(gulf[Prayer.MAGHRIB], gulf[Prayer.ISHA]).toMinutes())
    }

    @Test
    fun hanafiAsrIsLater() {
        val karachi = ZoneId.of("Asia/Karachi")
        val d = LocalDate.parse("2026-11-20")
        val standard = WorshipTimes.compute(d, 24.86, 67.01, karachi, 4, 0)!!
        val hanafi = WorshipTimes.compute(d, 24.86, 67.01, karachi, 4, 1)!!
        val later = Duration.between(standard[Prayer.ASR], hanafi[Prayer.ASR]).toMinutes()
        assertTrue("$later", later in 35..70)
        for (p in Prayer.entries) if (p != Prayer.ASR) assertEquals(standard[p], hanafi[p])
    }

    /** London at midsummer: the sun never goes 18° below the horizon, so the angle-based rule gives the times. */
    @Test
    fun highLatitudeAngleBasedRule() {
        val london = ZoneId.of("Europe/London")
        val day = WorshipTimes.compute(LocalDate.parse("2026-06-21"), 51.5074, -0.1278, london, 0, 0)!!
        val night = Duration.ofDays(1).minus(Duration.between(day[Prayer.SUNRISE], day[Prayer.MAGHRIB])).toMinutes()
        val fajrGap = Duration.between(day[Prayer.FAJR], day[Prayer.SUNRISE]).toMinutes()
        val ishaGap = Duration.between(day[Prayer.MAGHRIB], day[Prayer.ISHA]).toMinutes()
        assertTrue("fajr $fajrGap of $night", kotlin.math.abs(fajrGap - night * 18 / 60) <= 2)
        assertTrue("isha $ishaGap of $night", kotlin.math.abs(ishaGap - night * 17 / 60) <= 2)
        // in winter the angles are reached and the rule changes nothing: Fajr is well within 18/60 of the night
        val winter = WorshipTimes.compute(LocalDate.parse("2026-12-21"), 51.5074, -0.1278, london, 0, 0)!!
        assertTrue(Duration.between(winter[Prayer.FAJR], winter[Prayer.SUNRISE]).toMinutes() in 100..130)
        // polar day: no sunset, no times
        assertNull(WorshipTimes.compute(LocalDate.parse("2026-06-21"), 69.65, 18.96, ZoneId.of("Europe/Oslo"), 0, 0))
    }

    @Test
    fun timesAreInOrderEverywhereAllYear() {
        val places = listOf(Triple(21.4225, 39.8262, "Asia/Riyadh"), Triple(59.33, 18.07, "Europe/Stockholm"),
            Triple(-33.87, 151.21, "Australia/Sydney"), Triple(64.15, -21.94, "Atlantic/Reykjavik"),
            Triple(-21.14, -175.2, "Pacific/Tongatapu"), Triple(49.28, -123.12, "America/Vancouver"))
        for ((lat, lon, tz) in places) for (m in WorshipTimes.METHODS.indices) {
            var d = LocalDate.parse("2026-01-01")
            while (d.year == 2026) {
                val day = WorshipTimes.compute(d, lat, lon, ZoneId.of(tz), m, 0)
                if (day != null) {
                    val t = Prayer.entries.map { day[it] }
                    assertEquals("$tz $d method $m", t.sorted(), t)
                    // Dhuhr is on that day; near the Arctic circle in June, sunset itself can come after midnight
                    assertEquals("$tz $d", d, day[Prayer.DHUHR].atZone(ZoneId.of(tz)).toLocalDate())
                    assertTrue("$tz $d", Duration.between(t[0], t[5]).toHours() < 24)
                }
                d = d.plusDays(7)
            }
        }
    }
}
