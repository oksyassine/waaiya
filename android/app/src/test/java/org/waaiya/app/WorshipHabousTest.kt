package org.waaiya.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneOffset
import kotlin.math.abs

/**
 * Morocco: the Ministry of Habous's published times (src/test/resources/habous_times.tsv: every third day of
 * October and November 2026, all 190 cities, copied from habous.gov.ma) against Waaiya's own computation for the
 * same city of the list, with the Morocco method. The positions and horizons in cities.tsv were fitted to these
 * tables (scripts/habous/make_habous.py), so this checks that the Kotlin formula is the fitted one and that every
 * city of the ministry is in the list.
 */
class WorshipHabousTest {
    private val cities by lazy { WorshipCities.parse(File("src/main/assets/cities.tsv").readText()) }

    private class Row(val code: Int, val date: LocalDate, val times: List<LocalTime>)

    private val rows by lazy {
        val lines = File("src/test/resources/habous_times.tsv").readLines().filter { it.isNotBlank() && !it.startsWith("#") }
        lines.drop(1).map { l ->
            val f = l.split('\t')
            Row(f[0].toInt(), LocalDate.parse(f[1]), f.drop(2).map { LocalTime.parse(it) })
        }
    }

    @Test
    fun everyHabousCityIsListedWithItsHorizon() {
        val codes = rows.map { it.code }.toSet()
        assertEquals(190, codes.size)
        for (code in codes) {
            val c = cities.singleOrNull { it.habous == code }
            assertNotNull("Habous city $code", c)
            assertNotNull(c!!.id, c.horizon)
            assertEquals(c.id, WorshipCities.MOROCCO, WorshipCities.suggestedMethod(c))
        }
        // the cities Waaiya had before keep their ids (they are stored in settings)
        for (id in listOf("rabat", "casablanca", "fez", "marrakesh", "oujda", "tangier", "laayoune"))
            assertTrue(id, cities.single { it.id == id }.habous > 0)
    }

    @Test
    fun matchesTheMinistrysTablesWithinOneMinute() {
        var exact = 0
        var all = 0
        for (r in rows) {
            val c = cities.single { it.habous == r.code }
            val place = WorshipCities.place(c.id, cities)!!
            val day = WorshipTimes.compute(r.date, place.lat, place.lon, place.zone, WorshipCities.MOROCCO, 0, place.horizon)!!
            for ((i, p) in WorshipTimes.Prayer.entries.withIndex()) {
                // the published clock is GMT (Morocco's legal time since 2026-09-20)
                val published = r.date.atTime(r.times[i]).toInstant(ZoneOffset.UTC)
                val diff = (day[p].epochSecond - published.epochSecond) / 60
                assertTrue("${c.id} ${r.date} ${p.key}: ${day[p]} vs $published", abs(diff) <= 1)
                if (diff == 0L) exact++
                all++
            }
        }
        assertTrue("to the minute: $exact of $all", exact >= all * 95 / 100)
    }

    @Test
    fun otherMethodsIgnoreTheCitysHorizon() {
        val rabat = WorshipCities.place("rabat", cities)!!
        val date = LocalDate.parse("2026-11-20")
        val with = WorshipTimes.compute(date, rabat.lat, rabat.lon, rabat.zone, 0, 0, rabat.horizon)!!
        val without = WorshipTimes.compute(date, rabat.lat, rabat.lon, rabat.zone, 0, 0)!!
        assertEquals(without.times, with.times)
    }
}
