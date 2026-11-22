package org.waaiya.app

import java.time.Instant
import java.time.ZoneId
import kotlin.math.max

/**
 * When "silent at prayer times" and "mute media at the adhan" act, without Android classes (WorshipScheduleTest).
 * [WorshipAlarms] applies the plan: it changes Do Not Disturb and the media volume, announces each change, keeps
 * [State] in its own preferences file (so a restart in the middle of a window still restores), and sets one alarm
 * for [Plan.wake].
 *
 * Rules:
 * - A window starts at a prayer time and lasts the chosen minutes, counted from the prayer time (an alarm that
 *   comes late shortens the window, it never moves it). A prayer whose window is already over is skipped.
 * - A window that is still open at the next prayer (a long silence between Maghrib and Isha) is extended: Waaiya
 *   keeps the state it found before the first one and restores it once, at the end of the last one.
 * - Switching an option off ends its window at once. With both off and nothing open, nothing is scheduled.
 * - Turning an option on (or changing the place or the method) never acts on a prayer that has already passed:
 *   [onSettingsChanged] marks everything up to now as handled.
 * - At the end, the phone goes back to what the user had only if it is still what Waaiya set ([restoreDnd],
 *   [restoreMedia]); if the user changed it in the meantime, it is left alone.
 */
object WorshipSchedule {
    /** An alarm may come a little early or late, and a prayer exactly at "now" counts as come. */
    const val SLACK_MS = 5_000L

    class PrayerTime(val prayer: String, val at: Long) {
        override fun toString() = "$prayer@$at"
    }

    data class Options(val silent: Boolean, val silentMinutes: Int, val mute: Boolean, val muteMinutes: Int) {
        val any get() = silent || mute
    }

    /**
     * What Waaiya has set and must undo. Times in epoch milliseconds; 0 = nothing open.
     * @param silentEnd end of the open silence window (Waaiya turned Do Not Disturb on).
     * @param muteEnd end of the open media-mute window (Waaiya muted the media volume).
     * @param lastPrayer the latest prayer time already acted on (or skipped): never acted on twice.
     */
    data class State(val silentEnd: Long = 0, val muteEnd: Long = 0, val lastPrayer: Long = 0)

    /**
     * @param startSilent / [startMute]: open a new window now (Do Not Disturb on / media muted), until the end in
     *   [state]. The caller first checks the phone is not already in that state ([shouldSilence], [shouldMute]);
     *   if it is, it touches nothing and clears that end from [state].
     * @param endSilent / [endMute]: the window is over (or the option was switched off): restore if unchanged.
     * @param extendedSilent / [extendedMute]: that window was already open and now ends later (a new prayer came
     *   before its end): nothing changes on the phone, only the end.
     * @param prayer the prayer that started or extended a window now.
     * @param wake the next alarm (epoch ms), 0 = cancel every alarm.
     * @param next the next prayer that will start something, for the screen.
     */
    data class Plan(
        val startSilent: Boolean,
        val startMute: Boolean,
        val endSilent: Boolean,
        val endMute: Boolean,
        val extendedSilent: Boolean,
        val extendedMute: Boolean,
        val prayer: PrayerTime?,
        val state: State,
        val wake: Long,
        val next: PrayerTime?,
    )

    /** [prayers] in time order, covering at least yesterday to tomorrow at the place (only the five prayers). */
    fun plan(now: Long, prayers: List<PrayerTime>, o: Options, s: State): Plan {
        val due = prayers.lastOrNull { it.at <= now + SLACK_MS }?.takeIf { it.at > s.lastPrayer }
        var silentEnd = s.silentEnd
        var muteEnd = s.muteEnd
        var startSilent = false; var startMute = false; var extendedSilent = false; var extendedMute = false
        var acted: PrayerTime? = null
        fun until(minutes: Int) = due!!.at + minutes * 60_000L

        if (due != null && o.silent && until(o.silentMinutes) > now + SLACK_MS) {
            acted = due
            if (silentEnd != 0L) { silentEnd = max(silentEnd, until(o.silentMinutes)); extendedSilent = true }
            else { silentEnd = until(o.silentMinutes); startSilent = true }
        }
        if (due != null && o.mute && until(o.muteMinutes) > now + SLACK_MS) {
            acted = due
            if (muteEnd != 0L) { muteEnd = max(muteEnd, until(o.muteMinutes)); extendedMute = true }
            else { muteEnd = until(o.muteMinutes); startMute = true }
        }
        val endSilent = silentEnd != 0L && (!o.silent || silentEnd <= now + SLACK_MS)
        val endMute = muteEnd != 0L && (!o.mute || muteEnd <= now + SLACK_MS)
        if (endSilent) { silentEnd = 0; startSilent = false; extendedSilent = false }
        if (endMute) { muteEnd = 0; startMute = false; extendedMute = false }

        val lastPrayer = max(s.lastPrayer, due?.at ?: 0L)
        val next = if (o.any) prayers.firstOrNull { it.at > now + SLACK_MS && it.at > lastPrayer } else null
        val wake = listOf(silentEnd, muteEnd, next?.at ?: 0L).filter { it > 0L }.minOrNull() ?: 0L
        return Plan(startSilent, startMute, endSilent, endMute, extendedSilent, extendedMute, acted,
            State(silentEnd, muteEnd, lastPrayer), wake, next)
    }

    /**
     * The five prayers from yesterday to tomorrow at the place (its own dates, so a window that crosses midnight
     * and the next Fajr are both there), in time order. Days with no times (polar day or night) are left out.
     */
    fun prayersAround(now: Instant, lat: Double, lon: Double, zone: ZoneId, method: Int, asr: Int): List<PrayerTime> {
        val today = now.atZone(zone).toLocalDate()
        return (-1L..1L).flatMap { d ->
            val day = WorshipTimes.compute(today.plusDays(d), lat, lon, zone, method, asr) ?: return@flatMap emptyList()
            WorshipTimes.FIVE.map { PrayerTime(it.key, day[it].toEpochMilli()) }
        }.sortedBy { it.at }
    }

    /** The options, place or method changed: only prayers from now on count. Open windows stay as they are. */
    fun onSettingsChanged(now: Long, s: State): State = s.copy(lastPrayer = max(s.lastPrayer, now))

    /** NotificationManager.INTERRUPTION_FILTER_ALL and _PRIORITY (the values are fixed Android API constants). */
    const val FILTER_ALL = 1
    const val FILTER_PRIORITY = 2

    /** Turn Do Not Disturb on only when it is off: if the user already has it on, it is theirs, not ours. */
    fun shouldSilence(currentFilter: Int): Boolean = currentFilter == FILTER_ALL

    /**
     * End of a silence window: turn Do Not Disturb off only if it is still what Waaiya set. From Android 15
     * (API 35, for apps targeting it), turning it "off" only ends Waaiya's own Do Not Disturb rule and never a
     * Do Not Disturb the user turned on, so it is always safe there.
     */
    fun restoreDnd(sdk: Int, currentFilter: Int, setByUs: Int): Boolean = sdk >= 35 || currentFilter == setByUs

    /** Mute the media only when it is not muted already (or at volume 0): then it is the user's own silence. */
    fun shouldMute(mutedNow: Boolean, volume: Int): Boolean = !mutedNow && volume > 0

    /** End of a media-mute window: unmute only if still muted (raising the volume unmutes; then leave it). */
    fun restoreMedia(mutedNow: Boolean): Boolean = mutedNow
}
