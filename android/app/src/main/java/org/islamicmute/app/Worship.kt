package org.islamicmute.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * Prayer-time silence, media muted at the adhan, plain tones. Lane C (docs/FEATURES_CONTRACT.md, docs/ROADMAP.md
 * items 8 and 9). Off by default; everything is computed on the phone and nothing goes online.
 *
 * Pieces: [WorshipTimes] (astronomy and methods), [WorshipCities] (bundled list, place setting), [WorshipSchedule]
 * (when to act), [WorshipAlarms] (alarms, Do Not Disturb, media volume, notifications), [WorshipTones].
 *
 * Snapshot `features.worship` (facts and codes only; Flutter chooses the words):
 * - `supported` true (desktop has no such section, so the card is hidden there);
 * - `placeSet`, `placeValid`, `placeLabel` (in the app's language), `placeCustom`, `zone`, `deviceZone`,
 *   `suggestedMethod` (the city's country's usual method, or null), `methods` (method keys by index);
 * - `date` (today at the place), `times`: [{name: fajr|sunrise|dhuhr|asr|maghrib|isha, hm: "HH:mm", at: epoch ms}]
 *   or null (no place, or no sunrise/sunset today);
 * - `next`: {prayer, hm, at} the next prayer that will act, or null; `silentUntil`/`muteUntil` (epoch ms, 0 = none)
 *   with `silentUntilHm`/`muteUntilHm`;
 * - `dndAccess`, `exactAlarms`, `notifications`, `writeSettings` (permission states);
 * - `tones`: [{id, kind: ring|notification, number}], `ringtone` and `notificationTone`: the id of Waaiya's tone
 *   that is the phone's default now, or "".
 *
 * Methods `worship.<name>`: cities {query, limit}, times {date?, place?, method?, asr?}, customPlace {lat, lon, tz},
 * zones {query}, openDndAccess, openExactAlarms, openNotificationSettings, openWriteSettings, openSoundSettings,
 * previewTone {id}, stopTone, setTone {id}, unmuteNow, endSilentNow.
 */
object Worship : Feature {
    override val name = "worship"

    @Volatile private var cityCache: List<WorshipCities.City>? = null

    /** The bundled list (assets/cities.tsv), read once. */
    fun cities(ctx: Context): List<WorshipCities.City> = cityCache
        ?: ctx.assets.open("cities.tsv").bufferedReader().use { WorshipCities.parse(it.readText()) }.also { cityCache = it }

    override fun snapshot(host: FeatureHost): Map<String, Any?> =
        runCatching { snapshot(host.activity) }.getOrElse { mapOf("supported" to true, "error" to (it.message ?: "")) }

    private fun timesList(day: WorshipTimes.Day?): List<Map<String, Any?>>? = day?.let { d ->
        WorshipTimes.Prayer.entries.map { p ->
            mapOf("name" to p.key, "hm" to WorshipAlarms.hm(d[p].toEpochMilli(), d.zone), "at" to d[p].toEpochMilli())
        }
    }

    fun snapshot(ctx: Context): Map<String, Any?> {
        WorshipAlarms.syncIfChanged(ctx)
        val st = Settings(ctx)
        val lang = Lang.current(ctx)
        val place = WorshipCities.place(st.prayerPlace, cities(ctx))
        val now = System.currentTimeMillis()
        val zone = place?.zone
        val today = zone?.let { Instant.ofEpochMilli(now).atZone(it).toLocalDate() }
        val day = place?.let { WorshipTimes.compute(today!!, it.lat, it.lon, it.zone, st.prayerMethod, st.prayerAsr) }
        val state = WorshipAlarms.state(ctx)
        val next = place?.let {
            val opts = WorshipSchedule.Options(st.prayerSilent, st.prayerSilentMinutes, st.prayerAdhanMute, st.prayerAdhanMinutes)
            WorshipSchedule.plan(now, WorshipAlarms.prayersAround(Instant.ofEpochMilli(now), it, st.prayerMethod, st.prayerAsr),
                opts, state).next
        }
        val shownZone = zone ?: ZoneId.systemDefault()
        fun until(t: Long) = if (t > now) t else 0L
        return mapOf(
            "supported" to true,
            "placeSet" to st.prayerPlace.isNotEmpty(),
            "placeValid" to (place != null),
            "placeLabel" to place?.label(lang),
            "placeCustom" to (place != null && place.city == null),
            "zone" to zone?.id,
            "deviceZone" to ZoneId.systemDefault().id,
            "suggestedMethod" to place?.city?.let { WorshipCities.suggestedMethod(it.cc) },
            "methods" to WorshipTimes.METHODS.map { it.key },
            "date" to today?.toString(),
            "times" to timesList(day),
            "next" to next?.let { mapOf("prayer" to it.prayer, "hm" to WorshipAlarms.hm(it.at, shownZone), "at" to it.at) },
            "silentUntil" to until(state.silentEnd),
            "silentUntilHm" to until(state.silentEnd).takeIf { it > 0 }?.let { WorshipAlarms.hm(it, shownZone) },
            "muteUntil" to until(state.muteEnd),
            "muteUntilHm" to until(state.muteEnd).takeIf { it > 0 }?.let { WorshipAlarms.hm(it, shownZone) },
            "dndAccess" to WorshipAlarms.dndAccess(ctx),
            "exactAlarms" to WorshipAlarms.exactAllowed(ctx),
            "notifications" to WorshipAlarms.notificationsAllowed(ctx),
            "writeSettings" to WorshipTones.canWriteSettings(ctx),
            "tones" to WorshipTones.ALL.map { mapOf("id" to it.id, "kind" to it.kind, "number" to it.number) },
            "ringtone" to WorshipTones.current(ctx, "ring"),
            "notificationTone" to WorshipTones.current(ctx, "notification"),
        )
    }

    override fun call(host: FeatureHost, method: String, args: Map<String, Any?>): Any? {
        val ctx = host.activity
        fun str(k: String) = args[k] as? String
        fun open(intent: Intent) { ctx.startActivity(intent); }
        return when (method) {
            "cities" -> {
                val lang = Lang.current(ctx)
                val limit = (args["limit"] as? Int)?.coerceIn(1, 500) ?: 50
                WorshipCities.search(cities(ctx), str("query") ?: "", lang, limit, ZoneId.systemDefault().id).map {
                    mapOf("id" to it.id, "name" to it.name(lang), "en" to it.name("en"), "ar" to it.name("ar"),
                        "cc" to it.cc, "tz" to it.tz, "method" to WorshipCities.suggestedMethod(it.cc))
                }
            }
            "times" -> {
                val st = Settings(ctx)
                val place = WorshipCities.place(str("place") ?: st.prayerPlace, cities(ctx))
                    ?: throw FeatureException("bad_args", "no valid place")
                val date = str("date")?.let { runCatching { LocalDate.parse(it) }.getOrNull() ?: throw FeatureException("bad_args", "date $it") }
                    ?: Instant.now().atZone(place.zone).toLocalDate()
                val m = (args["method"] as? Int)?.takeIf { it in WorshipTimes.METHODS.indices } ?: st.prayerMethod
                val asr = (args["asr"] as? Int)?.takeIf { it in 0..1 } ?: st.prayerAsr
                mapOf("date" to date.toString(), "zone" to place.zone.id, "label" to place.label(Lang.current(ctx)),
                    "times" to timesList(WorshipTimes.compute(date, place.lat, place.lon, place.zone, m, asr)))
            }
            "customPlace" -> {
                val lat = (args["lat"] as? Number)?.toDouble()?.takeIf { it in -90.0..90.0 }
                    ?: throw FeatureException("bad_args", "lat")
                val lon = (args["lon"] as? Number)?.toDouble()?.takeIf { it in -180.0..180.0 }
                    ?: throw FeatureException("bad_args", "lon")
                val tz = str("tz")?.trim()?.takeIf { z -> runCatching { ZoneId.of(z) }.isSuccess && !z.contains(',') }
                    ?: throw FeatureException("bad_args", "tz")
                WorshipCities.customSetting(lat, lon, tz)
            }
            "zones" -> {
                val q = WorshipCities.normalize(str("query") ?: "")
                ZoneId.getAvailableZoneIds().filter { it.contains('/') && WorshipCities.normalize(it).contains(q) }
                    .sorted().take(50)
            }
            "openDndAccess" -> open(Intent(android.provider.Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
            "openExactAlarms" -> {
                if (Build.VERSION.SDK_INT < 31) throw FeatureException("unsupported", "exact alarms need no permission here")
                open(Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:${ctx.packageName}")))
            }
            "openNotificationSettings" -> open(Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, ctx.packageName))
            "openWriteSettings" -> open(Intent(android.provider.Settings.ACTION_MANAGE_WRITE_SETTINGS,
                Uri.parse("package:${ctx.packageName}")))
            "openSoundSettings" -> open(Intent(android.provider.Settings.ACTION_SOUND_SETTINGS))
            "previewTone" -> WorshipTones.preview(ctx, str("id"))
            "stopTone" -> WorshipTones.stop()
            "setTone" -> WorshipTones.set(ctx, str("id")).also { host.refresh() }
            "unmuteNow" -> { WorshipAlarms.unmuteNow(ctx); host.refresh() }
            "endSilentNow" -> { WorshipAlarms.endSilentNow(ctx); host.refresh() }
            else -> throw FeatureException("unsupported", "worship.$method")
        }.let { if (it == Unit) null else it }
    }
}
