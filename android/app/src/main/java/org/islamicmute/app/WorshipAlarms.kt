package org.islamicmute.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.util.Log
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/**
 * Silent at prayer times and media muted at the adhan: applies [WorshipSchedule]'s plan on the phone.
 *
 * Alarms (checked against developer.android.com, "Schedule alarms", 2026-11-20):
 * - Android 10 and 11: exact alarms need no permission.
 * - Android 12 and 13: SCHEDULE_EXACT_ALARM ("Alarms & reminders") is granted by default; the user can take it
 *   back in Settings. Android 14+: it is NOT granted to new installs of apps targeting Android 13+; the card offers
 *   a button to that page (ACTION_REQUEST_SCHEDULE_EXACT_ALARM).
 * - USE_EXACT_ALARM (granted at install) is restricted by Google Play to alarm-clock and calendar apps, so Waaiya
 *   does not declare it.
 * - Without the permission: setWindow with a 10-minute window (Android 12+ never allows less), which Doze may delay
 *   further; the card says so. Revoking the permission cancels exact alarms and stops the app; a second, inexact
 *   setAndAllowWhileIdle alarm for the same moment survives that and reschedules.
 * Alarms are set again after boot, a clock or time-zone change, an app update and the permission being granted
 * ([WorshipSystemReceiver]), and whenever the screen shows a changed setting ([Worship.snapshot]).
 *
 * Do Not Disturb (NotificationManager.setInterruptionFilter, needs "Do Not Disturb access"): from Android 15 an app
 * targeting it gets its own Do Not Disturb rule (Settings > Modes), and turning it off never ends a Do Not Disturb
 * the user turned on.
 */
object WorshipAlarms {
    private const val TAG = "WorshipAlarms"
    const val ACTION_TICK = "org.islamicmute.app.worship.TICK"
    const val ACTION_UNMUTE = "org.islamicmute.app.worship.UNMUTE"
    const val ACTION_END_SILENT = "org.islamicmute.app.worship.END_SILENT"
    const val CHANNEL = "worship"
    private const val NOTIF_SILENT = 7301
    private const val NOTIF_MUTE = 7302
    /** Inexact alarms on Android 12+ come within this window. */
    const val INEXACT_WINDOW_MS = 10 * 60_000L

    // --- state kept across restarts (own file: "settings" holds only the user's choices) ---

    private fun prefs(ctx: Context) = ctx.getSharedPreferences("worship", Context.MODE_PRIVATE)

    private fun load(ctx: Context) = prefs(ctx).let {
        WorshipSchedule.State(it.getLong("silent_end", 0), it.getLong("mute_end", 0), it.getLong("last_prayer", 0))
    }

    private fun save(ctx: Context, s: WorshipSchedule.State) = prefs(ctx).edit()
        .putLong("silent_end", s.silentEnd).putLong("mute_end", s.muteEnd).putLong("last_prayer", s.lastPrayer).apply()

    fun state(ctx: Context): WorshipSchedule.State = load(ctx)

    private fun options(st: Settings) =
        WorshipSchedule.Options(st.prayerSilent, st.prayerSilentMinutes, st.prayerAdhanMute, st.prayerAdhanMinutes)

    /** Everything a schedule depends on: when it changes, prayers already passed are not acted on. */
    private fun fingerprint(st: Settings) = listOf(st.prayerSilent, st.prayerSilentMinutes, st.prayerAdhanMute,
        st.prayerAdhanMinutes, st.prayerPlace, st.prayerMethod, st.prayerAsr).joinToString("|")

    fun prayersAround(now: Instant, place: WorshipCities.Place, method: Int, asr: Int) =
        WorshipSchedule.prayersAround(now, place.lat, place.lon, place.zone, method, asr)

    /**
     * Called whenever the screen refreshes (cheap): when the prayer settings changed since the last time, marks the
     * prayers up to now as handled and plans again. Never throws: the screen's snapshot must not fail.
     */
    fun syncIfChanged(ctx: Context) {
        runCatching {
            val st = Settings(ctx)
            val fp = fingerprint(st)
            val p = prefs(ctx)
            if (p.getString("fingerprint", null) == fp) return
            p.edit().putString("fingerprint", fp).apply()
            save(ctx, WorshipSchedule.onSettingsChanged(System.currentTimeMillis(), load(ctx)))
            tick(ctx)
        }.onFailure { Log.w(TAG, "sync", it) }
    }

    /** After boot, a clock change or an app update: plan again (open windows are restored if they are over). */
    fun reschedule(ctx: Context) {
        runCatching {
            prefs(ctx).edit().putString("fingerprint", fingerprint(Settings(ctx))).apply()
            tick(ctx)
        }.onFailure { Log.w(TAG, "reschedule", it) }
    }

    /** The plan for now, applied: ends, starts, announcements, the next alarm. */
    @Synchronized
    fun tick(ctx: Context) {
        val st = Settings(ctx)
        val now = System.currentTimeMillis()
        val place = WorshipCities.place(st.prayerPlace, Worship.cities(ctx))
        val prayers = place?.let { prayersAround(Instant.ofEpochMilli(now), it, st.prayerMethod, st.prayerAsr) }
            ?: emptyList()
        val opts = if (place == null) WorshipSchedule.Options(false, 0, false, 0) else options(st)
        val plan = WorshipSchedule.plan(now, prayers, opts, load(ctx))
        var state = plan.state
        val c = Lang.wrap(ctx)
        val zone = place?.zone ?: ZoneId.systemDefault()

        if (plan.endSilent) endSilent(c)
        if (plan.endMute) endMute(c)
        if (plan.startSilent && !startSilent(c, plan.prayer!!, state.silentEnd, zone)) state = state.copy(silentEnd = 0)
        else if (plan.extendedSilent && plan.prayer != null)
            announceSilent(c, plan.prayer, state.silentEnd, zone)
        if (plan.startMute && !startMute(c, plan.prayer!!, state.muteEnd, zone)) state = state.copy(muteEnd = 0)
        else if (plan.extendedMute && plan.prayer != null)
            announceMute(c, plan.prayer, state.muteEnd, zone)
        save(ctx, state)
        val wake = listOf(state.silentEnd, state.muteEnd, plan.next?.at ?: 0L).filter { it > 0 }.minOrNull() ?: 0L
        schedule(ctx, wake)
    }

    // --- Do Not Disturb ---

    fun dndAccess(ctx: Context): Boolean =
        ctx.getSystemService(NotificationManager::class.java).isNotificationPolicyAccessGranted

    private fun startSilent(c: Context, prayer: WorshipSchedule.PrayerTime, until: Long, zone: ZoneId): Boolean {
        val nm = c.getSystemService(NotificationManager::class.java)
        if (!nm.isNotificationPolicyAccessGranted) {
            notify(c, NOTIF_SILENT, prayerName(c, prayer.prayer), c.getString(R.string.notif_worship_no_access), null)
            return false
        }
        if (!WorshipSchedule.shouldSilence(nm.currentInterruptionFilter)) return false  // the user's own DND: leave it
        return runCatching {
            nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
            prefs(c).edit().putInt("silent_set", NotificationManager.INTERRUPTION_FILTER_PRIORITY).apply()
            announceSilent(c, prayer, until, zone)
            true
        }.getOrElse { Log.w(TAG, "silence", it); false }
    }

    private fun announceSilent(c: Context, prayer: WorshipSchedule.PrayerTime, until: Long, zone: ZoneId) {
        val end = PendingIntent.getBroadcast(c, 3, Intent(c, WorshipReceiver::class.java).setAction(ACTION_END_SILENT),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        notify(c, NOTIF_SILENT, c.getString(R.string.notif_worship_silent_title).replace("{prayer}", prayerName(c, prayer.prayer)),
            c.getString(R.string.notif_worship_silent_text).replace("{time}", hm(until, zone)),
            Notification.Action.Builder(null, c.getString(R.string.worship_end_silent), end).build())
    }

    private fun endSilent(c: Context) {
        val nm = c.getSystemService(NotificationManager::class.java)
        val set = prefs(c).getInt("silent_set", NotificationManager.INTERRUPTION_FILTER_PRIORITY)
        val restored = runCatching {
            if (WorshipSchedule.restoreDnd(Build.VERSION.SDK_INT, nm.currentInterruptionFilter, set)) {
                nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL); true
            } else false
        }.getOrElse { Log.w(TAG, "restore DND", it); false }
        notify(c, NOTIF_SILENT, c.getString(R.string.notif_worship_silent_end_title),
            c.getString(if (restored) R.string.notif_worship_silent_end_text else R.string.notif_worship_silent_left), null,
            timeoutMs = 30 * 60_000L)
    }

    /** "End silence now" (the card or the notification). */
    fun endSilentNow(ctx: Context) {
        val s = load(ctx)
        if (s.silentEnd == 0L) return
        endSilent(Lang.wrap(ctx))
        save(ctx, s.copy(silentEnd = 0))
        tick(ctx)
    }

    // --- media volume ---

    private fun startMute(c: Context, prayer: WorshipSchedule.PrayerTime, until: Long, zone: ZoneId): Boolean {
        val am = c.getSystemService(AudioManager::class.java)
        if (!WorshipSchedule.shouldMute(am.isStreamMute(AudioManager.STREAM_MUSIC), am.getStreamVolume(AudioManager.STREAM_MUSIC)))
            return false
        return runCatching {
            am.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_MUTE, 0)
            announceMute(c, prayer, until, zone)
            true
        }.getOrElse { Log.w(TAG, "mute", it); false }
    }

    private fun announceMute(c: Context, prayer: WorshipSchedule.PrayerTime, until: Long, zone: ZoneId) {
        val unmute = PendingIntent.getBroadcast(c, 2, Intent(c, WorshipReceiver::class.java).setAction(ACTION_UNMUTE),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        notify(c, NOTIF_MUTE, c.getString(R.string.notif_worship_mute_title).replace("{prayer}", prayerName(c, prayer.prayer)),
            c.getString(R.string.notif_worship_mute_text).replace("{time}", hm(until, zone)),
            Notification.Action.Builder(null, c.getString(R.string.worship_unmute), unmute).build())
    }

    private fun endMute(c: Context, now: Boolean = false) {
        val am = c.getSystemService(AudioManager::class.java)
        val restored = runCatching {
            if (WorshipSchedule.restoreMedia(am.isStreamMute(AudioManager.STREAM_MUSIC))) {
                am.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_UNMUTE, 0); true
            } else false
        }.getOrElse { Log.w(TAG, "unmute", it); false }
        if (now) c.getSystemService(NotificationManager::class.java).cancel(NOTIF_MUTE)
        else notify(c, NOTIF_MUTE, c.getString(R.string.notif_worship_mute_end_title),
            c.getString(if (restored) R.string.notif_worship_mute_end_text else R.string.notif_worship_mute_left), null,
            timeoutMs = 30 * 60_000L)
    }

    /** "Unmute now" (the notification's action, or the card). */
    fun unmuteNow(ctx: Context) {
        val s = load(ctx)
        if (s.muteEnd == 0L) return
        endMute(Lang.wrap(ctx), now = true)
        save(ctx, s.copy(muteEnd = 0))
        tick(ctx)
    }

    // --- alarms ---

    fun exactAllowed(ctx: Context): Boolean =
        Build.VERSION.SDK_INT < 31 || ctx.getSystemService(AlarmManager::class.java).canScheduleExactAlarms()

    private fun alarmIntent(ctx: Context, code: Int) = PendingIntent.getBroadcast(ctx, code,
        Intent(ctx, WorshipReceiver::class.java).setAction(ACTION_TICK),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

    /** One alarm at [at] (epoch ms) and its inexact backup; 0 cancels both. */
    private fun schedule(ctx: Context, at: Long) {
        val am = ctx.getSystemService(AlarmManager::class.java)
        val main = alarmIntent(ctx, 0)
        val backup = alarmIntent(ctx, 1)
        prefs(ctx).edit().putLong("wake", at).apply()
        if (at == 0L) { am.cancel(main); am.cancel(backup); return }
        runCatching {
            if (exactAllowed(ctx)) am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, main)
            else am.setWindow(AlarmManager.RTC_WAKEUP, at, INEXACT_WINDOW_MS, main)
        }.onFailure { am.setWindow(AlarmManager.RTC_WAKEUP, at, INEXACT_WINDOW_MS, main) }  // revoked meanwhile
        am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, backup)
    }

    /** The alarm time set last (epoch ms), 0 = none: for the screen and the tests. */
    fun wake(ctx: Context): Long = prefs(ctx).getLong("wake", 0)

    // --- notifications ---

    fun notificationsAllowed(ctx: Context): Boolean =
        ctx.getSystemService(NotificationManager::class.java).areNotificationsEnabled()

    private fun notify(c: Context, id: Int, title: String, text: String, action: Notification.Action?, timeoutMs: Long = 0) {
        runCatching {
            val nm = c.getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(NotificationChannel(CHANNEL, c.getString(R.string.notif_worship_channel),
                NotificationManager.IMPORTANCE_LOW))
            val open = UiActivity.open(c, "settings")?.let {
                PendingIntent.getActivity(c, 7300, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            }
            val b = Notification.Builder(c, CHANNEL)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(title).setContentText(text)
                .setStyle(Notification.BigTextStyle().bigText(text))
                .setContentIntent(open).setAutoCancel(true)
                .setCategory(Notification.CATEGORY_REMINDER)
            if (action != null) b.addAction(action)
            if (timeoutMs > 0) b.setTimeoutAfter(timeoutMs)
            nm.notify(id, b.build())
        }.onFailure { Log.w(TAG, "notify", it) }
    }

    fun prayerName(c: Context, key: String): String = c.getString(when (key) {
        "fajr" -> R.string.worship_prayer_fajr
        "sunrise" -> R.string.worship_prayer_sunrise
        "dhuhr" -> R.string.worship_prayer_dhuhr
        "asr" -> R.string.worship_prayer_asr
        "maghrib" -> R.string.worship_prayer_maghrib
        else -> R.string.worship_prayer_isha
    })

    private val HM = DateTimeFormatter.ofPattern("HH:mm")
    fun hm(at: Long, zone: ZoneId): String = Instant.ofEpochMilli(at).atZone(zone).format(HM)
    fun date(at: Long, zone: ZoneId): LocalDate = Instant.ofEpochMilli(at).atZone(zone).toLocalDate()
}

/** Waaiya's own alarms and notification buttons (not exported: only Waaiya's PendingIntents reach it). */
class WorshipReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            WorshipAlarms.ACTION_TICK -> runCatching { WorshipAlarms.tick(context) }
            WorshipAlarms.ACTION_UNMUTE -> runCatching { WorshipAlarms.unmuteNow(context) }
            WorshipAlarms.ACTION_END_SILENT -> runCatching { WorshipAlarms.endSilentNow(context) }
            WorshipSms.ACTION_CHECK -> runCatching { WorshipSms.check(context) }
        }
    }
}

/**
 * Android's broadcasts after which alarms must be set again: boot, clock or time-zone change, app update, exact
 * alarms allowed. All are protected broadcasts that only the system can send.
 */
class WorshipSystemReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_MY_PACKAGE_REPLACED, AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED ->
                WorshipAlarms.reschedule(context)
        }
    }
}
