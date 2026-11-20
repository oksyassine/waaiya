package org.islamicmute.app

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.chrono.HijrahDate
import java.time.temporal.ChronoField
import kotlin.math.abs
import kotlin.math.acos
import kotlin.math.asin
import kotlin.math.atan
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.round
import kotlin.math.sin
import kotlin.math.tan

/**
 * Prayer times computed on the phone, offline (docs/ROADMAP.md item 8). Written for Waaiya from the standard
 * astronomical method: the sun's declination and the equation of time from the low-precision solar coordinates
 * (Astronomical Almanac, about 1 arc-minute between 1950 and 2050), then the hour angle at which the sun reaches
 * each prayer's altitude. No Android classes here, so the JVM tests (WorshipTimesTest) run it directly.
 *
 * The method, the Asr rule and so the times are the user's choice (Settings.prayerMethod, Settings.prayerAsr); the
 * app only preselects the method usually used in the chosen city's country ([WorshipCities.suggestedMethod]).
 *
 * Places where the sun does not go low enough for Fajr or Isha (summer at high latitudes): the angle-based rule.
 * The night (sunset to next sunrise) is split in 60 parts; Fajr is at most angle/60 of the night before sunrise
 * and Isha at most angle/60 of the night after sunset (e.g. 18° = 18/60 = 0.3 of the night). It is applied when
 * the angle is never reached, or when it would give a longer twilight than that portion. Days with no sunrise or no
 * sunset (polar day or night) have no times at all.
 */
object WorshipTimes {
    /** In the order of a day. Names are the snapshot's ("fajr"...) and the Flutter strings' keys. */
    enum class Prayer(val key: String) {
        FAJR("fajr"), SUNRISE("sunrise"), DHUHR("dhuhr"), ASR("asr"), MAGHRIB("maghrib"), ISHA("isha");
    }

    /** The five prayers that the silence and the media mute follow (sunrise is shown, never acted on). */
    val FIVE = listOf(Prayer.FAJR, Prayer.DHUHR, Prayer.ASR, Prayer.MAGHRIB, Prayer.ISHA)

    /**
     * One calculation method. Angles are degrees of the sun below the horizon.
     * @param key stable id, used for the Flutter string `worshipMethod_<key>` (never shown as such).
     * @param ishaMinutes Isha this many minutes after Maghrib instead of an angle (0 = use [isha]).
     * @param ishaMinutesRamadan the same in the month of Ramadan (Umm al-Qura: 120); 0 = as [ishaMinutes].
     * @param maghribAngle Maghrib when the sun is this far below the horizon (Tehran 4.5°); 0 = at sunset.
     * @param offsets minutes added to each time of [Prayer] (in that order) after the calculation: the publisher's
     *   own precaution minutes (ihtiyat, temkin), as documented in docs and checked against its timetables.
     */
    class Method(
        val key: String,
        val fajr: Double,
        val isha: Double,
        val ishaMinutes: Int = 0,
        val ishaMinutesRamadan: Int = 0,
        val maghribAngle: Double = 0.0,
        val offsets: IntArray = IntArray(6),
    )

    /**
     * Settings.prayerMethod is an index into this list: the order never changes (it is stored), new methods would
     * only be appended (the setting's range is 0..15 today). WorshipTimesTest pins the keys and the order.
     *
     * | # | key | Fajr | Isha | Notes, offsets (minutes: sunrise, dhuhr, asr, maghrib, isha) |
     * |---|---|---|---|---|
     * | 0 | mwl | 18° | 17° | Muslim World League |
     * | 1 | isna | 15° | 15° | Islamic Society of North America |
     * | 2 | egypt | 19.5° | 17.5° | Egyptian General Authority of Survey |
     * | 3 | umm_al_qura | 18.5° | 90 min | Makkah; 120 min in Ramadan (Umm al-Qura calendar, java.time.chrono.HijrahDate) |
     * | 4 | karachi | 18° | 18° | University of Islamic Sciences, Karachi |
     * | 5 | tehran | 17.7° | 14° | Institute of Geophysics, University of Tehran; Maghrib at 4.5° |
     * | 6 | gulf | 19.5° | 90 min | Gulf region |
     * | 7 | kuwait | 18° | 17.5° | Kuwait |
     * | 8 | qatar | 18° | 90 min | Qatar |
     * | 9 | singapore | 20° | 18° | Majlis Ugama Islam Singapura (MUIS); dhuhr +1 (MUIS's table is about 1 min later still) |
     * | 10 | turkey | 18° | 17° | Diyanet İşleri Başkanlığı; temkin: sunrise −7, dhuhr +5, asr +4, maghrib +7, isha +0 |
     * | 11 | france | 12° | 12° | Union des organisations islamiques de France (UOIF) |
     * | 12 | morocco | 19° | 17° | Ministry of Habous; sunrise −3, dhuhr +5, maghrib +5 |
     * | 13 | indonesia | 20° | 18° | Kementerian Agama (Kemenag); ihtiyat +2 on every time, sunrise −2 |
     * | 14 | malaysia | 18° | 18° | JAKIM: Subuh at 18° since the MKI decision of 2019 (before: 20°); ihtiyat +2 on the five prayers |
     * | 15 | dubai | 18.2° | 18.2° | Dubai (IACAD); sunrise −3, dhuhr +3, asr +3, maghrib +3 |
     *
     * Checked against published timetables in src/test/resources/worship_reference.tsv (Umm al-Qura, Egypt,
     * Diyanet, JAKIM, MUIS, Kemenag; ISNA and UOIF through calculators that state the method): within 2 minutes.
     * MWL has no independent timetable yet: a London calculator's rows match these to the minute but one day off
     * (the page's dates are shifted), so they are kept there but not asserted.
     * The Kemenag, Morocco and Dubai offsets are the usual published precaution minutes; Morocco, Dubai, Karachi,
     * Tehran, Gulf, Kuwait and Qatar have no fetched timetable yet.
     */
    val METHODS: List<Method> = listOf(
        Method("mwl", 18.0, 17.0),
        Method("isna", 15.0, 15.0),
        Method("egypt", 19.5, 17.5),
        Method("umm_al_qura", 18.5, 0.0, ishaMinutes = 90, ishaMinutesRamadan = 120),
        Method("karachi", 18.0, 18.0),
        Method("tehran", 17.7, 14.0, maghribAngle = 4.5),
        Method("gulf", 19.5, 0.0, ishaMinutes = 90),
        Method("kuwait", 18.0, 17.5),
        Method("qatar", 18.0, 0.0, ishaMinutes = 90),
        Method("singapore", 20.0, 18.0, offsets = intArrayOf(0, 0, 1, 0, 0, 0)),
        Method("turkey", 18.0, 17.0, offsets = intArrayOf(0, -7, 5, 4, 7, 0)),
        Method("france", 12.0, 12.0),
        Method("morocco", 19.0, 17.0, offsets = intArrayOf(0, -3, 5, 0, 5, 0)),
        Method("indonesia", 20.0, 18.0, offsets = intArrayOf(2, -2, 2, 2, 2, 2)),
        Method("malaysia", 18.0, 18.0, offsets = intArrayOf(2, 0, 2, 2, 2, 2)),
        Method("dubai", 18.2, 18.2, offsets = intArrayOf(0, -3, 3, 3, 3, 0)),
    )

    /** Asr: the shadow is this many times the object's length plus its noon shadow. 0 standard (1), 1 Hanafi (2). */
    fun shadowFactor(asr: Int) = if (asr == 1) 2.0 else 1.0

    /** One day's times at a place, each rounded to the minute; null on a day with no sunrise or no sunset. */
    class Day(val date: LocalDate, val zone: ZoneId, val times: Map<Prayer, Instant>) {
        operator fun get(p: Prayer): Instant = times.getValue(p)
    }

    /** True when [date] is in Ramadan by the Umm al-Qura calendar (Java's Hijrah chronology); false if unknown. */
    fun isRamadan(date: LocalDate): Boolean =
        runCatching { HijrahDate.from(date).get(ChronoField.MONTH_OF_YEAR) == 9 }.getOrDefault(false)

    /**
     * The times of the local [date] at [lat], [lon] (degrees, east and north positive) in [zone].
     * @param method index into [METHODS]; @param asr 0 standard, 1 Hanafi.
     */
    fun compute(date: LocalDate, lat: Double, lon: Double, zone: ZoneId, method: Int, asr: Int): Day? {
        val m = METHODS[method.coerceIn(0, METHODS.size - 1)]
        val day = Solar(date, lat, lon)
        val factor = shadowFactor(asr)

        // first guesses (hours, local mean solar time turned into UTC), then refined: the sun's position is taken
        // again at each found time, twice
        val g = -lon / 15.0
        var fajr = 5.0 + g; var sunrise = 6.0 + g; var dhuhr = 12.0 + g; var asrT = 13.0 + g
        var sunset = 18.0 + g; var maghrib = 18.0 + g; var isha = 18.0 + g
        repeat(3) {
            dhuhr = day.noon(dhuhr)
            fajr = day.noon(fajr) - day.hourAngle(fajr, m.fajr)
            sunrise = day.noon(sunrise) - day.hourAngle(sunrise, RISE_SET)
            asrT = day.noon(asrT) + day.asrHourAngle(asrT, factor)
            sunset = day.noon(sunset) + day.hourAngle(sunset, RISE_SET)
            maghrib = if (m.maghribAngle > 0) day.noon(maghrib) + day.hourAngle(maghrib, m.maghribAngle) else sunset
            isha = if (m.ishaMinutes == 0) day.noon(isha) + day.hourAngle(isha, m.isha) else isha
            // NaN in a guess would poison the next round: start again from sunrise/sunset there
            if (fajr.isNaN() && !sunrise.isNaN()) fajr = sunrise
            if (isha.isNaN() && !sunset.isNaN()) isha = sunset
            if (maghrib.isNaN() && !sunset.isNaN()) maghrib = sunset
        }
        if (sunrise.isNaN() || sunset.isNaN() || dhuhr.isNaN() || asrT.isNaN()) return null
        // recompute the angle-based ones once more from the settled guesses, keeping NaN where never reached
        fajr = day.noon(fajr) - day.hourAngle(fajr, m.fajr)
        if (m.ishaMinutes == 0) isha = day.noon(isha) + day.hourAngle(isha, m.isha)
        if (m.maghribAngle > 0) maghrib = day.noon(maghrib) + day.hourAngle(maghrib, m.maghribAngle)

        // high latitudes: angle-based rule (see the class comment)
        val night = 24.0 - (sunset - sunrise)
        fun limitBefore(t: Double, angle: Double): Double {
            val portion = angle / 60.0 * night
            return if (t.isNaN() || sunrise - t > portion) sunrise - portion else t
        }
        fun limitAfter(t: Double, angle: Double): Double {
            val portion = angle / 60.0 * night
            return if (t.isNaN() || t - sunset > portion) sunset + portion else t
        }
        fajr = limitBefore(fajr, m.fajr)
        if (m.maghribAngle > 0) maghrib = limitAfter(maghrib, m.maghribAngle)
        isha = if (m.ishaMinutes > 0) {
            val minutes = if (m.ishaMinutesRamadan > 0 && isRamadan(date)) m.ishaMinutesRamadan else m.ishaMinutes
            maghrib + minutes / 60.0
        } else limitAfter(isha, m.isha)

        val hours = doubleArrayOf(fajr, sunrise, dhuhr, asrT, maghrib, isha)
        val base = date.atStartOfDay(java.time.ZoneOffset.UTC).toInstant()
        val times = Prayer.entries.associateWith { p ->
            val minutes = round(hours[p.ordinal] * 60.0).toLong() + m.offsets[p.ordinal]
            base.plusSeconds(minutes * 60)
        }
        return Day(date, zone, fixLocalDate(times, date, zone))
    }

    /**
     * The hours above are counted from 00:00 UTC of [date]. For a place whose clock is far from its solar time
     * the result can land on the neighbouring local day; move it by whole days so that Dhuhr is on [date].
     */
    private fun fixLocalDate(times: Map<Prayer, Instant>, date: LocalDate, zone: ZoneId): Map<Prayer, Instant> {
        val dhuhrDate = times.getValue(Prayer.DHUHR).atZone(zone).toLocalDate()
        val shift = date.toEpochDay() - dhuhrDate.toEpochDay()
        return if (shift == 0L) times else times.mapValues { it.value.plusSeconds(shift * 86400) }
    }

    /** Sun just touching the horizon: refraction (34′) plus the sun's radius (16′). */
    private const val RISE_SET = 0.833

    /** The sun on one day at one place. Times are hours from 00:00 UTC of the date. */
    private class Solar(date: LocalDate, lat: Double, private val lon: Double) {
        private val jd0 = date.toEpochDay() + 2440587.5  // Julian day at 00:00 UTC
        private val phi = Math.toRadians(lat)

        /** Declination (radians) and equation of time (hours) at [hours] UTC. */
        private fun position(hours: Double): Pair<Double, Double> {
            val d = jd0 + (if (hours.isNaN()) 12.0 else hours) / 24.0 - 2451545.0
            val g = Math.toRadians(fix(357.529 + 0.98560028 * d, 360.0))
            val q = fix(280.459 + 0.98564736 * d, 360.0)
            val l = Math.toRadians(fix(q + 1.915 * sin(g) + 0.020 * sin(2 * g), 360.0))
            val e = Math.toRadians(23.439 - 0.00000036 * d)
            val ra = fix(Math.toDegrees(atan2(cos(e) * sin(l), cos(l))) / 15.0, 24.0)
            var eqt = q / 15.0 - ra
            eqt -= 24.0 * floor((eqt + 12.0) / 24.0)  // into -12..12
            return asin(sin(e) * sin(l)) to eqt
        }

        /** Solar noon (hours UTC) near [hours]. */
        fun noon(hours: Double): Double = 12.0 - position(hours).second - lon / 15.0

        /** Hours between noon and the sun at [angle] degrees below the horizon; NaN when never reached. */
        fun hourAngle(hours: Double, angle: Double): Double {
            val decl = position(hours).first
            val c = (-sin(Math.toRadians(angle)) - sin(phi) * sin(decl)) / (cos(phi) * cos(decl))
            return if (c < -1.0 || c > 1.0) Double.NaN else Math.toDegrees(acos(c)) / 15.0
        }

        /** Hours between noon and Asr for a shadow [factor] (1 standard, 2 Hanafi). */
        fun asrHourAngle(hours: Double, factor: Double): Double {
            val decl = position(hours).first
            val altitude = atan(1.0 / (factor + tan(abs(phi - decl))))
            val c = (sin(altitude) - sin(phi) * sin(decl)) / (cos(phi) * cos(decl))
            return if (c < -1.0 || c > 1.0) Double.NaN else Math.toDegrees(acos(c)) / 15.0
        }

        private fun fix(a: Double, b: Double): Double = a - b * floor(a / b)
    }
}
