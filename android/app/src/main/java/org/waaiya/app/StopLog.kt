package org.waaiya.app

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.os.PowerManager
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Why filtering ended by itself, kept on disk for the diagnostics report: the last few stops with the time and what
 * the phone was doing (screen on, locked, blur on, Android's question skipped, notification text shown). A tester
 * whose sound "blocks after a while" can then send one report that says which path it was: Android stopped the
 * capture (screen lock, another recording, the status-bar chip), the capture or the output died, or the process was
 * killed (ApplicationExitInfo, read in [report]).
 */
object StopLog {
    private const val PREFS = "stop_log"
    private const val KEEP = 16

    /** Filtering ended by itself because of [why]. Any thread. */
    fun record(ctx: Context, why: String) = add(ctx, "STOP $why (${phone(ctx)})")

    /** Something worth knowing that did not end filtering (the output made again). */
    fun event(ctx: Context, what: String) = add(ctx, what)

    /** As [event], with the phone's state (screen, lock, battery) at that moment. */
    fun eventWithState(ctx: Context, what: String) = add(ctx, "$what (${phone(ctx)})")

    @Synchronized private fun add(ctx: Context, line: String) {
        runCatching {
            val p = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val time = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.ROOT).format(Date())
            val lines = (p.getString("lines", "")!!.split('\n').filter { it.isNotBlank() } + "$time $line").takeLast(KEEP)
            p.edit().putString("lines", lines.joinToString("\n")).apply()
            android.util.Log.i("IslamicMute", "event: $line")
            Recent.of(ctx).event("$time $line")  // with the per-second log's other events, in order
        }
    }

    /** The phone's state now, for a log line: screen, lock, blur, battery settings. */
    fun phone(ctx: Context): String {
        val pm = ctx.getSystemService(PowerManager::class.java)
        val km = ctx.getSystemService(KeyguardManager::class.java)
        val yes = { b: Boolean -> if (b) "yes" else "no" }
        return "screen on ${yes(pm.isInteractive)}, locked ${yes(km.isKeyguardLocked)}, blur on ${yes(ScreenBlur.state != null)}, " +
            "question skipped ${yes(ctx.hasProjectMediaAppOp())}, power saver ${yes(pm.isPowerSaveMode)}, " +
            "battery unrestricted ${yes(pm.isIgnoringBatteryOptimizations(ctx.packageName))}" +
            (if (Build.VERSION.SDK_INT >= 28) ", background restricted " +
                yes(ctx.getSystemService(android.app.ActivityManager::class.java).isBackgroundRestricted) else "")
    }

    /** Filtering runs ([on]) or ended in an orderly way: a mark left set means the process died while filtering. */
    fun markFiltering(ctx: Context, on: Boolean) {
        val p = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
        if (on) p.putLong("filtering_since", System.currentTimeMillis()).remove("killed_at") else p.remove("filtering_since")
        p.apply()
    }

    /**
     * A new process (WaaiyaApp): if the last one died while filtering and it was not the user (force stop) or an
     * update, remember when, for the Filter page's "Keep Waaiya running" card (the music then played unfiltered).
     */
    fun checkKilled(ctx: Context) {
        val prefs = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val since = prefs.getLong("filtering_since", 0)
        if (since == 0L) return
        var at: Long = 0
        if (Build.VERSION.SDK_INT >= 30) runCatching {
            val e = ctx.getSystemService(ActivityManager::class.java)
                .getHistoricalProcessExitReasons(ctx.packageName, 0, 1).firstOrNull()
            if (e != null && e.timestamp >= since && e.reason !in setOf(10, 11, 15, 16))  // user stop, update
                at = e.timestamp
        }
        val p = prefs.edit().remove("filtering_since")
        if (at > 0) { p.putLong("killed_at", at); add(ctx, "Android ended Waaiya's process while it was filtering") }
        p.apply()
    }

    /** When Android last ended Waaiya while it was filtering, or 0 (cleared when filtering starts again). */
    fun killedAt(ctx: Context): Long = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getLong("killed_at", 0)

    /** The diagnostics report's lines: the last stops, and the last times Android ended Waaiya's process. */
    fun report(ctx: Context): String = buildString {
        val lines = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString("lines", "")!!
        appendLine(if (lines.isBlank()) "No stop by itself recorded." else lines)
        if (Build.VERSION.SDK_INT >= 30) runCatching {
            val am = ctx.getSystemService(ActivityManager::class.java)
            val fmt = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.ROOT)
            am.getHistoricalProcessExitReasons(ctx.packageName, 0, 4).forEach { e ->
                appendLine("Process ended ${fmt.format(Date(e.timestamp))}: reason ${e.reason}, importance ${e.importance}" +
                    (e.description?.let { ", $it" } ?: ""))
            }
        }
    }.trimEnd()
}
