package org.waaiya.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.time.Instant
import java.time.ZoneId

/** The bundled city list (assets/cities.tsv), the search, and the place setting. */
class WorshipCitiesTest {
    private val cities by lazy { WorshipCities.parse(File("src/main/assets/cities.tsv").readText()) }

    @Test
    fun theListIsWholeAndValid() {
        assertTrue("${cities.size} cities", cities.size >= 300)
        assertEquals("ids are unique", cities.size, cities.map { it.id }.toSet().size)
        val now = Instant.parse("2026-11-20T12:00:00Z")
        for (c in cities) {
            assertTrue(c.id, Regex("^[a-z0-9_]+$").matches(c.id))  // never a comma or colon: prayer_place
            assertTrue(c.id, Regex("^[A-Z]{2}$").matches(c.cc))
            assertTrue(c.id, c.lat in -90.0..90.0 && c.lon in -180.0..180.0)
            val zone = ZoneId.of(c.tz)  // throws on an unknown zone
            // a clock more than 3 hours from the sun's time would mean a wrong zone or swapped coordinates
            // (modulo 24 h: Tonga's clock is UTC+13 at longitude -175)
            val offsetH = zone.rules.getOffset(now).totalSeconds / 3600.0
            val gap = Math.floorMod(Math.round((offsetH - c.lon / 15.0) * 60).toInt() + 720, 1440) / 60.0 - 12.0
            assertTrue("${c.id}: ${c.tz} vs lon ${c.lon}", kotlin.math.abs(gap) < 3.0)
            assertTrue(c.id, c.name("en").isNotBlank() && c.name("ar").isNotBlank())
            assertTrue(WorshipCities.suggestedMethod(c.cc) in WorshipTimes.METHODS.indices)
            // every listed city has prayer times today (no polar day or night in the list in November)
            val date = java.time.LocalDate.parse("2026-11-20")
            val day = WorshipTimes.compute(date, c.lat, c.lon, zone, 0, 0)
            assertNotNull(c.id, day)
            // the times are on that local day, in order, with Dhuhr near the clock's noon
            val local = WorshipTimes.Prayer.entries.map { day!![it].atZone(zone) }
            assertTrue(c.id, local.all { it.toLocalDate() == date })
            assertEquals(c.id, local.sortedBy { it.toInstant() }, local)
            assertTrue("${c.id}: dhuhr ${local[2]}", local[2].hour in 10..14)
        }
        for (id in listOf("makkah", "madinah", "jerusalem", "cairo", "istanbul", "jakarta", "kuala_lumpur", "paris",
            "london", "new_york", "toronto", "karachi", "dhaka", "tehran", "dubai", "singapore", "rabat", "kuwait_city", "doha"))
            assertTrue("$id missing", cities.any { it.id == id })
    }

    @Test
    fun searchInAnyLanguageAndSpelling() {
        fun first(q: String, lang: String = "en") = WorshipCities.search(cities, q, lang).firstOrNull()?.id
        assertEquals("makkah", first("Makkah"))
        assertEquals("makkah", first("mecca"))
        assertEquals("makkah", first("مكة"))
        assertEquals("makkah", first("مكه"))           // ة typed as ه
        assertEquals("madinah", first("المدينة المنورة"))
        assertEquals("istanbul", first("İstanbul"))
        assertEquals("istanbul", first("istanbul"))
        assertEquals("cairo", first("Kairo"))          // the Indonesian name
        assertEquals("cairo", first("القاهره"))
        assertEquals("cairo", first("Le Caire"))
        assertEquals("jerusalem", first("al-quds"))
        assertTrue(WorshipCities.search(cities, "zzzz", "en").isEmpty())
        // the name follows the app's language; Malay falls back to Indonesian, then English
        val cairo = cities.first { it.id == "cairo" }
        assertEquals("القاهرة", cairo.name("ar"))
        assertEquals(cairo.name("id").ifEmpty { cairo.name("en") }, cairo.name("ms"))
        // an empty query lists the phone's time zone first
        assertEquals("Africa/Cairo", WorshipCities.search(cities, "", "en", 5, "Africa/Cairo").first().tz)
    }

    @Test
    fun placeSetting() {
        assertNull(WorshipCities.place("", cities))
        assertNull(WorshipCities.place("atlantis", cities))
        val makkah = WorshipCities.place("makkah", cities)!!
        assertEquals(ZoneId.of("Asia/Riyadh"), makkah.zone)
        assertEquals("مكة المكرمة", makkah.label("ar"))
        assertEquals(3, WorshipCities.suggestedMethod(makkah.city!!.cc))
        val s = WorshipCities.customSetting(-6.2, 106.816666, "Asia/Jakarta")
        assertEquals("custom:-6.2000,106.8167,Asia/Jakarta", s)
        val p = WorshipCities.place(s, cities)!!
        assertNull(p.city)
        assertEquals(-6.2, p.lat, 1e-9)
        assertEquals("-6.2000, 106.8167", p.label("en"))
        for (bad in listOf("custom:", "custom:1,2", "custom:91,0,UTC", "custom:0,181,UTC", "custom:0,0,Nowhere/Town",
            "custom:a,b,UTC"))
            assertNull(bad, WorshipCities.place(bad, cities))
    }

    @Test
    fun myLocationInMoroccoIsTheNearestHabousCity() {
        // Salé, across the river from Rabat: the ministry's table for Rabat
        val sale = WorshipCities.fromLocation(34.04, -6.80, "Africa/Casablanca", cities)
        assertEquals("rabat", sale.setting)
        assertTrue(sale.habous)
        assertEquals(WorshipCities.MOROCCO, sale.method)
        // a village in the Atlas: the nearest of the ministry's cities, whatever its size
        val atlas = WorshipCities.fromLocation(31.06, -7.91, "Africa/Casablanca", cities)
        assertTrue(atlas.habous)
        assertTrue(atlas.setting, cities.single { it.id == atlas.setting }.habous > 0)
        // Dakhla, on Western Sahara's zone id (the same clock)
        assertEquals("dakhla", WorshipCities.fromLocation(23.70, -15.95, "Africa/El_Aaiun", cities).setting)
        // Ceuta is in the ministry's list
        assertEquals("ceuta", WorshipCities.fromLocation(35.89, -5.32, "Africa/Ceuta", cities).setting)
    }

    @Test
    fun myLocationElsewhereIsTheCoordinatesAndTheCountrysUsualMethod() {
        // Tarifa, Spain: nearer to Tangier than to any Spanish city in the list, but on Spain's clock
        val tarifa = WorshipCities.fromLocation(36.0143, -5.6044, "Europe/Madrid", cities)
        assertFalse(tarifa.habous)
        assertEquals("custom:36.0143,-5.6044,Europe/Madrid", tarifa.setting)
        assertEquals(WorshipCities.suggestedMethod("ES"), tarifa.method)
        // Saint-Denis, next to Paris: named after Paris, France's usual method
        val stDenis = WorshipCities.fromLocation(48.9362, 2.3574, "Europe/Paris", cities)
        assertEquals(11, stDenis.method)
        assertEquals("paris", stDenis.near?.id)
        val place = WorshipCities.place(stDenis.setting, cities)!!
        assertEquals("paris", place.near?.id)
        assertNull(place.city)
        // Cairo's suburbs: Egypt
        assertEquals(2, WorshipCities.fromLocation(30.0, 31.3, "Africa/Cairo", cities).method)
        // the middle of nowhere on a clock without listed cities: Muslim World League, no name
        val sea = WorshipCities.fromLocation(-40.0, -30.0, "Atlantic/South_Georgia", cities)
        assertEquals(0, sea.method)
        assertNull(sea.near)
    }

    @Test
    fun coordinatesInMoroccoTakeTheNearestHabousHorizon() {
        val ifrane = cities.single { it.id == "ifrane" }
        val p = WorshipCities.place(WorshipCities.customSetting(ifrane.lat + 0.05, ifrane.lon, "Africa/Casablanca"), cities)!!
        assertEquals(ifrane.horizon!!.rise, p.horizon!!.rise, 1e-9)
        // far from any of the ministry's cities: none (the method's sea-level horizon applies)
        assertNull(WorshipCities.place("custom:48.8566,2.3522,Europe/Paris", cities)!!.horizon)
    }

    @Test
    fun moroccoIsOnGmtEvenWithOldTimeZoneData() {
        val casa = ZoneId.of("Africa/Casablanca")
        assertEquals(java.time.ZoneOffset.UTC, WorshipCities.clockZone(casa, "2024a"))
        assertEquals(java.time.ZoneOffset.UTC, WorshipCities.clockZone(ZoneId.of("Africa/El_Aaiun"), "2026b"))
        assertEquals(casa, WorshipCities.clockZone(casa, "2026c"))   // the data that knows it
        assertEquals(casa, WorshipCities.clockZone(casa, null))      // unknown: as it is
        val paris = ZoneId.of("Europe/Paris")
        assertEquals(paris, WorshipCities.clockZone(paris, "2024a"))
    }

    @Test
    fun countryMethodsAreAChoiceShownToTheUser() {
        assertEquals(3, WorshipCities.suggestedMethod("SA"))
        assertEquals(2, WorshipCities.suggestedMethod("eg"))
        assertEquals(10, WorshipCities.suggestedMethod("TR"))
        assertEquals(11, WorshipCities.suggestedMethod("FR"))
        assertEquals(1, WorshipCities.suggestedMethod("US"))
        assertEquals(0, WorshipCities.suggestedMethod("GB"))
        assertEquals(0, WorshipCities.suggestedMethod("ZZ"))
    }
}
