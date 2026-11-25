package org.waaiya.app

import java.text.Normalizer
import java.time.ZoneId
import java.time.ZoneOffset
import java.util.Locale
import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * The bundled city list (assets/cities.tsv) and the place setting, without Android classes (WorshipCitiesTest).
 * No network: the user picks a city, types coordinates and a time zone, or taps "Use my location" (the phone's
 * approximate position, read once: [fromLocation]).
 *
 * Morocco (and Ceuta, Melilla): the list holds the Ministry of Habous's 190 prayer-time cities ([City.habous]) with
 * the horizon that reproduces their published tables ([City.horizon]). A position in Morocco becomes the nearest of
 * them, as the ministry's tables are meant to be used.
 *
 * Settings.prayerPlace is a city id, or `custom:LAT,LON,TZID` (decimal degrees, north and east positive, an IANA
 * time-zone id), or "" (not chosen).
 */
object WorshipCities {
    class City(
        val id: String,
        val cc: String,
        val lat: Double,
        val lon: Double,
        val tz: String,
        /** Names by app language tag (en, ar, fr, tr, id, fa, ur, bn; ms falls back to id): "" when unknown. */
        val names: Map<String, String>,
        /** The Ministry of Habous's city code (its prayer-time tables), 0 for other cities. */
        val habous: Int = 0,
        /** Sunrise and Maghrib as in the Ministry of Habous's table of this city; null for other cities. */
        val horizon: WorshipTimes.Horizon? = null,
    ) {
        fun name(lang: String): String = names[lang]?.takeIf { it.isNotEmpty() }
            ?: (if (lang == "ms") names["id"]?.takeIf { it.isNotEmpty() } else null)
            ?: names.getValue("en")

        internal val search: List<String> by lazy { names.values.filter { it.isNotEmpty() }.map(::normalize).distinct() }
    }

    /** TSV columns -> language tag ("id_name" because "id" is the city id column). */
    private val NAME_COLUMNS = mapOf("en" to "en", "ar" to "ar", "fr" to "fr", "tr" to "tr", "id_name" to "id",
        "fa" to "fa", "ur" to "ur", "bn" to "bn", "alt" to "alt")

    /** Lines starting with `#` are comments; the first other line names the columns (id, cc, lat, lon, tz, en, ...). */
    fun parse(text: String): List<City> {
        val lines = text.lineSequence().filter { it.isNotBlank() && !it.startsWith("#") }.toList()
        if (lines.isEmpty()) return emptyList()
        val header = lines.first().split('\t').map { it.trim() }
        fun col(name: String) = header.indexOf(name).also { require(it >= 0) { "cities.tsv: no column $name" } }
        val id = col("id"); val cc = col("cc"); val lat = col("lat"); val lon = col("lon"); val tz = col("tz")
        val habous = header.indexOf("habous"); val rise = header.indexOf("rise"); val set = header.indexOf("set")
        val nameCols = NAME_COLUMNS.mapNotNull { (c, tag) -> header.indexOf(c).takeIf { it >= 0 }?.let { tag to it } }
        return lines.drop(1).map { line ->
            val f = line.split('\t')
            fun num(i: Int) = f.getOrNull(i)?.trim()?.toDoubleOrNull()
            val r = num(rise); val s = num(set)
            City(f[id], f[cc], f[lat].toDouble(), f[lon].toDouble(), f[tz],
                nameCols.associate { (tag, i) -> tag to (f.getOrNull(i)?.trim() ?: "") },
                habous = f.getOrNull(habous)?.trim()?.toIntOrNull() ?: 0,
                horizon = if (r != null && s != null) WorshipTimes.Horizon(r, s) else null)
        }
    }

    /**
     * For matching what the user types: lower case, no Latin accents (İstanbul, Düsseldorf), and Arabic-script
     * letters folded (no short vowels or tatweel; أ إ آ ٱ -> ا, ة -> ه, ى ی -> ي, ک -> ك, ؤ -> و, ئ -> ي).
     */
    fun normalize(s: String): String {
        val decomposed = Normalizer.normalize(s.lowercase(Locale.ROOT).replace('ı', 'i'), Normalizer.Form.NFD)
        val out = StringBuilder(decomposed.length)
        for (c in decomposed) {
            when {
                Character.getType(c) == Character.NON_SPACING_MARK.toInt() -> {}  // accents, Arabic short vowels
                c == 'ـ' -> {}  // tatweel
                c in "أإآٱ" -> out.append('ا')
                c == 'ة' -> out.append('ه')
                c == 'ى' || c == 'ی' || c == 'ئ' -> out.append('ي')
                c == 'ک' -> out.append('ك')
                c == 'ؤ' -> out.append('و')
                c == '-' || c == '\'' || c == '’' -> out.append(' ')
                else -> out.append(c)
            }
        }
        // NFD splits أ into ا + hamza above (a mark, dropped above): the same result as the explicit fold
        return out.toString().replace(Regex("\\s+"), " ").trim()
    }

    /**
     * Cities whose name in any language matches [query]: whole name first, then names that start with it, then a
     * word that starts with it, then anywhere. Ties: cities in [preferZone] (the phone's time zone) first, then by
     * name in [lang]. An empty query lists the cities in [preferZone], then the rest, by name.
     */
    fun search(cities: List<City>, query: String, lang: String, limit: Int = 50, preferZone: String? = null): List<City> {
        val q = normalize(query)
        fun rank(c: City): Int {
            if (q.isEmpty()) return 0
            var best = Int.MAX_VALUE
            for (n in c.search) {
                val r = when {
                    n == q -> 0
                    n.startsWith(q) -> 1
                    n.split(' ').any { it.startsWith(q) } -> 2
                    n.contains(q) -> 3
                    else -> Int.MAX_VALUE
                }
                if (r < best) best = r
            }
            return best
        }
        return cities.asSequence()
            .map { it to rank(it) }
            .filter { it.second != Int.MAX_VALUE }
            .sortedWith(compareBy<Pair<City, Int>> { it.second }
                .thenBy { if (it.first.tz == preferZone) 0 else 1 }
                .thenBy { normalize(it.first.name(lang)) })
            .take(limit)
            .map { it.first }
            .toList()
    }

    /**
     * A resolved place: a bundled city, or custom coordinates ([city] null; [near]: the closest listed city within
     * [NEAR_KM], to name it). [horizon]: the city's own, or for coordinates the nearest Habous city's within
     * [HABOUS_KM] (used only by the Morocco method).
     */
    class Place(val setting: String, val city: City?, val lat: Double, val lon: Double, val zone: ZoneId,
                val horizon: WorshipTimes.Horizon? = null, val near: City? = null) {
        fun label(lang: String): String = city?.name(lang) ?: String.format(Locale.ROOT, "%.4f, %.4f", lat, lon)
    }

    /** The place of Settings.prayerPlace; null when not chosen or not valid (then nothing is scheduled). */
    fun place(setting: String, cities: List<City>): Place? {
        if (setting.startsWith(CUSTOM)) {
            val parts = setting.removePrefix(CUSTOM).split(',')
            if (parts.size != 3) return null
            val lat = parts[0].trim().toDoubleOrNull()?.takeIf { it in -90.0..90.0 } ?: return null
            val lon = parts[1].trim().toDoubleOrNull()?.takeIf { it in -180.0..180.0 } ?: return null
            val zone = runCatching { clockZone(ZoneId.of(parts[2].trim())) }.getOrNull() ?: return null
            val habous = nearest(cities.filter { it.habous > 0 }, lat, lon)?.takeIf { it.second <= HABOUS_KM }?.first
            val near = nearest(cities, lat, lon)?.takeIf { it.second <= NEAR_KM }?.first
            return Place(setting, null, lat, lon, zone, habous?.horizon, near)
        }
        val c = cities.firstOrNull { it.id == setting } ?: return null
        val zone = runCatching { clockZone(ZoneId.of(c.tz)) }.getOrNull() ?: return null
        return Place(setting, c, c.lat, c.lon, zone, c.horizon)
    }

    /**
     * The version of the phone's time-zone data (IANA, e.g. "2024a"); set by Worship.cities on Android, null in tests
     * (the JVM's own data is used as it is).
     */
    @Volatile var tzdata: String? = null

    /**
     * Morocco's legal time is GMT all year since 2026-09-20 (decree 2.26.530), first in IANA tzdata 2026c. With
     * older data a phone still puts Africa/Casablanca (and Africa/El_Aaiun) at +01, and every time would show an hour
     * late: then the place is on GMT, as the Ministry of Habous's site does. Alarms do not depend on it (instants).
     */
    fun clockZone(zone: ZoneId, data: String? = tzdata): ZoneId =
        if (zone.id in MOROCCO_CLOCK && data != null && data < "2026c") ZoneOffset.UTC else zone

    private val MOROCCO_CLOCK = setOf("Africa/Casablanca", "Africa/El_Aaiun")

    /** Coordinates within this distance of a listed city are named after it ("near Paris"). */
    const val NEAR_KM = 40.0
    /** A Habous city's horizon also serves coordinates within this distance (similar altitude around a town). */
    const val HABOUS_KM = 40.0
    /** A position this close to a Habous city, on Morocco's clock (or Ceuta's), takes that city's official table. */
    const val HABOUS_SNAP_KM = 60.0
    /** The time zones of the Ministry of Habous's cities. */
    val HABOUS_ZONES = setOf("Africa/Casablanca", "Africa/El_Aaiun", "Africa/Ceuta")

    /** Great-circle distance in km. */
    fun distanceKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val p1 = Math.toRadians(lat1); val p2 = Math.toRadians(lat2)
        val dp = p2 - p1; val dl = Math.toRadians(lon2 - lon1)
        val a = sin(dp / 2) * sin(dp / 2) + cos(p1) * cos(p2) * sin(dl / 2) * sin(dl / 2)
        return 2 * 6371.0 * asin(sqrt(a.coerceIn(0.0, 1.0)))
    }

    /** The closest city and its distance in km; null for an empty list. */
    fun nearest(cities: List<City>, lat: Double, lon: Double): Pair<City, Double>? =
        cities.asSequence().map { it to distanceKm(lat, lon, it.lat, it.lon) }.minByOrNull { it.second }

    /**
     * What "Use my location" sets. [setting] for Settings.prayerPlace, [method] to preselect, [habous] true when it is
     * one of the Ministry of Habous's cities (its official table: nothing to choose), [near] the closest listed city.
     */
    class Located(val setting: String, val method: Int, val habous: Boolean, val near: City?)

    /**
     * The place for a position read from the phone ([lat], [lon]) on the phone's clock [zone]. In Morocco (on its
     * clock, or Ceuta's, and within [HABOUS_SNAP_KM] of one of the ministry's cities): the nearest of those cities,
     * the Morocco method. Elsewhere: the coordinates themselves on the phone's clock, and the method usually used in
     * the country of the nearest listed city (the user is then asked to choose).
     */
    fun fromLocation(lat: Double, lon: Double, zone: String, cities: List<City>): Located {
        val habous = nearest(cities.filter { it.habous > 0 }, lat, lon)
        if (habous != null && habous.second <= HABOUS_SNAP_KM && zone in HABOUS_ZONES) {
            return Located(habous.first.id, MOROCCO, true, habous.first)
        }
        val near = nearest(cities, lat, lon)?.takeIf { it.second <= NEAR_KM }?.first
        // the country: of the nearest listed city on the phone's clock (Tarifa, on Spain's, is nearer to Tangier
        // than to any Spanish city), else of the nearest city if close, else the default
        val cc = nearest(cities.filter { it.tz == zone }, lat, lon)?.first?.cc ?: near?.cc
        return Located(customSetting(lat, lon, zone), cc?.let { suggestedMethod(it) } ?: 0, false, near)
    }

    /** WorshipTimes.METHODS index of the Ministry of Habous. */
    const val MOROCCO = 12

    /** The method to preselect for a listed city: the Habous cities' own table, else the country's usual method. */
    fun suggestedMethod(city: City): Int = if (city.habous > 0) MOROCCO else suggestedMethod(city.cc)

    const val CUSTOM = "custom:"

    /** `custom:LAT,LON,TZID` with 4 decimals (about 10 m). */
    fun customSetting(lat: Double, lon: Double, tz: String): String =
        String.format(Locale.ROOT, "%s%.4f,%.4f,%s", CUSTOM, lat, lon, tz)

    /**
     * The method most often used in a country (ISO 3166 code), preselected when a city is picked; the user can
     * change it. Index into WorshipTimes.METHODS. Countries not listed: Muslim World League (0).
     */
    fun suggestedMethod(cc: String): Int = when (cc.uppercase(Locale.ROOT)) {
        "US", "CA" -> 1                                                       // ISNA
        "EG", "SD", "SS", "LY", "SY", "LB", "IQ", "JO", "PS" -> 2              // Egypt
        "SA", "YE" -> 3                                                       // Umm al-Qura
        "PK", "IN", "BD", "AF" -> 4                                           // Karachi
        "IR" -> 5                                                             // Tehran
        "BH", "OM" -> 6                                                       // Gulf
        "KW" -> 7
        "QA" -> 8
        "SG", "BN" -> 9                                                       // MUIS
        "TR" -> 10                                                            // Diyanet
        "FR" -> 11                                                            // UOIF
        "MA" -> 12
        "ID" -> 13                                                            // Kemenag
        "MY" -> 14                                                            // JAKIM
        "AE" -> 15                                                            // Dubai
        else -> 0                                                             // Muslim World League
    }
}
