package org.waaiya.app

import java.text.Normalizer
import java.time.ZoneId
import java.util.Locale

/**
 * The bundled city list (assets/cities.tsv) and the place setting, without Android classes (WorshipCitiesTest).
 * No location permission and no network: the user picks a city, or types coordinates and a time zone.
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
        val nameCols = NAME_COLUMNS.mapNotNull { (c, tag) -> header.indexOf(c).takeIf { it >= 0 }?.let { tag to it } }
        return lines.drop(1).map { line ->
            val f = line.split('\t')
            City(f[id], f[cc], f[lat].toDouble(), f[lon].toDouble(), f[tz],
                nameCols.associate { (tag, i) -> tag to (f.getOrNull(i)?.trim() ?: "") })
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

    /** A resolved place: a bundled city, or custom coordinates ([city] null). */
    class Place(val setting: String, val city: City?, val lat: Double, val lon: Double, val zone: ZoneId) {
        fun label(lang: String): String = city?.name(lang) ?: String.format(Locale.ROOT, "%.4f, %.4f", lat, lon)
    }

    /** The place of Settings.prayerPlace; null when not chosen or not valid (then nothing is scheduled). */
    fun place(setting: String, cities: List<City>): Place? {
        if (setting.startsWith(CUSTOM)) {
            val parts = setting.removePrefix(CUSTOM).split(',')
            if (parts.size != 3) return null
            val lat = parts[0].trim().toDoubleOrNull()?.takeIf { it in -90.0..90.0 } ?: return null
            val lon = parts[1].trim().toDoubleOrNull()?.takeIf { it in -180.0..180.0 } ?: return null
            val zone = runCatching { ZoneId.of(parts[2].trim()) }.getOrNull() ?: return null
            return Place(setting, null, lat, lon, zone)
        }
        val c = cities.firstOrNull { it.id == setting } ?: return null
        val zone = runCatching { ZoneId.of(c.tz) }.getOrNull() ?: return null
        return Place(setting, c, c.lat, c.lon, zone)
    }

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
