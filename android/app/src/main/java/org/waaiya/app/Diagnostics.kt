package org.waaiya.app

import android.app.ActivityManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.media.AudioManager
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.os.SystemClock

/**
 * A plain-text report of everything that decides whether the filter works on this phone: the setup, the phone's
 * speed, dropouts, what is being silenced. The user copies or shares it; nothing is sent by the app.
 *
 * Always in English with fixed labels, whatever the app language: it is read by whoever helps the user.
 * No account, serial number or other identifier is included; app names appear only for apps playing sound now.
 */
object Diagnostics {
    /** Battery and CPU at the start of the running filter (FilterService); null before the first start. */
    @Volatile var power: PowerUse? = null
        private set

    /** Called by the filter when it starts: the battery and CPU figures the report compares with. */
    fun filterStarted(ctx: Context) {
        val b = battery(ctx)
        power = PowerUse(SystemClock.elapsedRealtime(), Process.getElapsedCpuTime(), b?.percent, b?.charging ?: false)
    }

    /** The sticky battery broadcast: level, charging, temperature. Null when Android does not give it. */
    private fun battery(ctx: Context): PowerUse.Battery? = runCatching {
        val i = ctx.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED)) ?: return null
        val status = i.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        PowerUse.Battery(
            percent = PowerUse.batteryPercent(i.getIntExtra(BatteryManager.EXTRA_LEVEL, -1), i.getIntExtra(BatteryManager.EXTRA_SCALE, -1)),
            charging = i.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) != 0 ||
                status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL,
            tenthsC = i.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, Int.MIN_VALUE),
        )
    }.getOrNull()

    fun report(ctx: Context): String = buildString {
        val s = Settings(ctx)
        val yes = { b: Boolean -> if (b) "yes" else "no" }
        fun granted(p: String) = ctx.checkSelfPermission(p) == PackageManager.PERMISSION_GRANTED

        appendLine("Waaiya ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE}) ${BuildConfig.BUILD_TYPE}")
        appendLine("Phone: ${Build.MANUFACTURER} ${Build.MODEL}, Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})" +
            SetupHelp.systemName.let { if (it.isEmpty()) "" else ", $it" })
        val mem = ActivityManager.MemoryInfo().also { ctx.getSystemService(ActivityManager::class.java).getMemoryInfo(it) }
        appendLine("Chip: ${chip()}, ${Runtime.getRuntime().availableProcessors()} cores, " +
            "ABI ${Build.SUPPORTED_ABIS.joinToString("/")}, RAM ${mem.totalMem / (1 shl 20)} MB (free ${mem.availMem / (1 shl 20)} MB)")
        appendLine("Language: ${Lang.current(ctx)}, user: ${s.gender.ifEmpty { "not chosen" }}")
        appendLine()

        appendLine("[Setup]")
        appendLine("Silence originals (DUMP): ${yes(ctx.hasDumpPermission())}")
        if (HelperDumps.helperMode(ctx)) appendLine("Grants refused by this phone: Waaiya's helper reads the sessions " +
            "(helper running: ${yes(HelperDumps.helperReady)})")
        appendLine("Skip screen-share question (PROJECT_MEDIA): ${yes(ctx.hasProjectMediaAppOp())}")
        appendLine("Shizuku: ${ShizukuSetup.state(ctx)}")
        appendLine("Notification text tile (Android 15+): permission ${yes(ScreenShareProtection.canWrite(ctx))}, " +
            "on ${yes(Settings(ctx).showNotificationText)}")
        appendLine("Last setup: " + SetupLog.report(ctx))
        appendLine("Microphone permission: ${yes(granted(android.Manifest.permission.RECORD_AUDIO))}")
        appendLine("Notifications: ${yes(ctx.getSystemService(NotificationManager::class.java).areNotificationsEnabled())}")
        val pm = ctx.getSystemService(PowerManager::class.java)
        appendLine("Battery: unrestricted ${yes(pm.isIgnoringBatteryOptimizations(ctx.packageName))}, power saver ${yes(pm.isPowerSaveMode)}")
        appendLine()

        appendLine("[Filter]")
        appendLine("State: ${FilterService.state}")
        val h = FilterService.health
        if (h == null) appendLine("Not running: start filtering, play something for 20 seconds, then open this report again.")
        else {
            appendLine("Model: ${h.model}, delay ${FilterService.delayMs} ms, mono ${yes(h.mono)}" +
                (if (h.monoForSpeed) " (stereo chosen, phone too slow for it)" else "") + ", too slow ${yes(h.tooSlow)}")
            appendLine("Speed (a hop must take under 10 ms): last 2 s avg %.1f ms, max %.1f ms, late %.0f%%"
                .format(java.util.Locale.ROOT, h.avgHopMs, h.maxHopMs, h.lateShare * 100))
            appendLine("Speed since start: avg %.1f ms, peak %.1f ms, late %d of %d hops with sound (%d hops in all)"
                .format(java.util.Locale.ROOT, h.overallAvgMs, h.peakHopMs, h.lateHops, h.busyHops, h.hops))
            appendLine("Output: dropouts ${h.underruns}, waiting ${h.bufferedMs} ms, buffer ${h.bufferFrames} of " +
                "${h.bufferCapacityFrames} frames (minimum ${h.minBufferFrames}), grown ${h.extraBufferHops}, " +
                "given back ${h.trimmedHops} hops, keeping ${h.keepHops * 10} ms")
            appendLine("Capture: level ${h.captureDb} dB, read errors ${h.readErrors}, model errors ${h.engineErrors}")
            appendLine("Women's singing filter: " + if (h.gateShare < 0) "off" else "on, muting %.0f%% of the time".format(java.util.Locale.ROOT, h.gateShare * 100))
            appendLine("Keep singing model: running ${yes(h.keepSinging)}")
            power?.let { p ->
                val b = battery(ctx)
                val thermal = if (Build.VERSION.SDK_INT >= 29) PowerUse.thermalName(pm.currentThermalStatus) else "not told (Android 10+)"
                appendLine(p.report(SystemClock.elapsedRealtime(), Process.getElapsedCpuTime(), b, thermal))
            }
        }
        appendLine("Keep singing chosen: ${yes(s.keepSinging)}, model bundled: ${yes(ModelStore.hasSinging(ctx))}")
        appendLine("Stereo chosen: ${yes(s.audioStereo)}, starts in mono (learned on this phone): ${yes(s.audioMono)}")
        appendLine("Keep apps silent if filtering stops by itself: ${yes(s.holdSilence)}")
        appendLine("Detector model bundled: ${yes(ModelStore.hasDetector(ctx))}")
        val am = ctx.getSystemService(AudioManager::class.java)
        appendLine("Media playing now (Waaiya's own output counts): ${yes(am.isMusicActive)}, media volume ${am.getStreamVolume(AudioManager.STREAM_MUSIC)}/" +
            "${am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)}, output rate ${am.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE)} Hz, " +
            "burst ${am.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER)} frames")
        appendLine()

        appendLine("[Original sound]")
        val m = h?.muter
        append(SimpleMode.report(ctx))
        if (m == null) appendLine("Muter: ${FilterService.muterStatus} (details appear while filtering runs)")
        else {
            appendLine("Muter: ${m.status}, list from ${m.source}, polls ${m.polls}, failed polls ${m.pollFailures}, " +
                "sessions that could not be muted ${m.attachFailures}")
            m.lastError?.takeIf { m.status != SessionMuter.Status.NO_PERMISSION || HelperDumps.helperMode(ctx) }
                ?.let { appendLine("Last error: $it") }
            if (m.status == SessionMuter.Status.NO_PERMISSION) appendLine(
                if (HelperDumps.helperMode(ctx)) "Other apps' sound sessions cannot be listed while Waaiya's helper is stopped."
                else "Other apps' sound sessions cannot be listed without the setup.")
            else if (m.sessions.isEmpty()) appendLine("No other app has a sound session.")
            for (x in m.sessions) {
                val name = ctx.packageManager.getPackagesForUid(x.uid)?.firstOrNull() ?: "uid ${x.uid}"
                appendLine("  session ${x.id}: $name, ${x.usage.removePrefix("USAGE_")}, " +
                    (if (x.active) "playing" else "idle") + ", " +
                    (if (x.capturable) "can be filtered" else "refuses capture") + ", " +
                    (if (x.id in m.muted) "original muted" else "original NOT muted"))
            }
        }
        appendLine("Silence apps that block filtering: ${yes(s.silenceUnfilterable)}")
        appendLine()

        appendLine("[Screen blur]")
        appendLine("Women ${yes(s.blurWomen)}, immodest images ${yes(s.blurNudity)}, strictness ${s.blurStrictness}, " +
            "cover when failing ${yes(s.blurFailCover)}")
        appendLine("State: ${ScreenBlur.state ?: "off"}, draw over apps ${yes(android.provider.Settings.canDrawOverlays(ctx))}, " +
            "accessibility build ${yes(BuildConfig.BLUR_A11Y)}")
        ScreenBlur.coverInfo?.let { appendLine(it) }
        ScreenBlur.stats?.let { appendLine(it) }
    }

    /** The chip name where Android tells it (API 31+), else the board name. */
    private fun chip(): String =
        if (Build.VERSION.SDK_INT >= 31) "${Build.SOC_MANUFACTURER} ${Build.SOC_MODEL}" else Build.HARDWARE
}

/**
 * Battery and heat while filtering (roadmap item 2): battery used per hour, the app's CPU time and which model and
 * mono / stereo ran since the filter started. The arithmetic has no Android classes: tested on the JVM
 * (DiagnosticsPowerTest). [startPercent] null: the level was not known; [startCharging]: plugged in at the start.
 */
class PowerUse(
    private val startMs: Long, private val startCpuMs: Long,
    private val startPercent: Double?, private val startCharging: Boolean,
) {
    /** One reading of the sticky ACTION_BATTERY_CHANGED. [tenthsC]: temperature in tenths of a degree C. */
    data class Battery(val percent: Double?, val charging: Boolean, val tenthsC: Int)

    private val runs = LinkedHashSet<String>()

    /** The model and mode the filter runs with now (called with every health report); each one is listed once. */
    @Synchronized fun noteRun(model: String, mono: Boolean) { runs += "$model ${if (mono) "mono" else "stereo"}" }
    @Synchronized fun runs(): List<String> = runs.toList()

    /** The report lines (two, no trailing newline). [nowMs] / [cpuMs]: elapsedRealtime and the process CPU time now. */
    fun report(nowMs: Long, cpuMs: Long, now: Battery?, thermal: String): String {
        val wall = nowMs - startMs
        val min = wall / 60_000.0
        val rate = batteryPerHour(startPercent, now?.percent, wall, startCharging || now?.charging != false)
        val cpu = cpuShare(cpuMs - startCpuMs, wall)
        val l = java.util.Locale.ROOT
        val battery = when {
            startCharging || now?.charging == true -> "charging"
            rate == null && min < MIN_MINUTES -> "measuring (needs ${MIN_MINUTES.toInt()} minutes without charging)"
            rate == null -> "not known"
            else -> "%.1f%% per hour (%.0f%% to %.0f%%)".format(l, rate, startPercent, now?.percent)
        }
        val temp = now?.tenthsC?.takeIf { it != Int.MIN_VALUE }?.let { "%.1f C".format(l, it / 10.0) } ?: "not known"
        // the texts are joined, never used as a format: "12.0% per hour" holds a '%'
        return "Power since start (" + "%.0f".format(l, min) + " min): battery $battery, temperature $temp, thermal $thermal\n" +
            "CPU of all of Waaiya (blur and screen included): " +
            (cpu?.let { "%.0f%% of one core (%.1f s per minute)".format(l, it, it * 0.6) } ?: "not known") +
            ", ran: ${runs().joinToString(", ").ifEmpty { "?" }}"
    }

    companion object {
        /** Battery use is shown after this many minutes: the level only moves in whole percents. */
        const val MIN_MINUTES = 10.0

        /** Level as a percentage, or null when the broadcast has no valid level. */
        fun batteryPercent(level: Int, scale: Int): Double? =
            if (level < 0 || scale <= 0 || level > scale) null else level * 100.0 / scale

        /**
         * Battery percent used per hour, or null when it cannot be told: charging at either reading, a level not known,
         * less than [MIN_MINUTES], or a level that went up (charged in between).
         */
        fun batteryPerHour(startPercent: Double?, nowPercent: Double?, wallMs: Long, charging: Boolean): Double? {
            if (charging || startPercent == null || nowPercent == null || wallMs < MIN_MINUTES * 60_000) return null
            val used = startPercent - nowPercent
            return if (used < 0) null else used * 3_600_000.0 / wallMs
        }

        /** CPU time as a percentage of one core over [wallMs] (100 = one core busy all the time). */
        fun cpuShare(cpuMs: Long, wallMs: Long): Double? =
            if (wallMs <= 0 || cpuMs < 0) null else cpuMs * 100.0 / wallMs

        /** PowerManager.THERMAL_STATUS_* (API 29+). */
        fun thermalName(status: Int): String = when (status) {
            0 -> "none"; 1 -> "light"; 2 -> "moderate"; 3 -> "severe"; 4 -> "critical"; 5 -> "emergency"; 6 -> "shutdown"
            else -> "unknown ($status)"
        }
    }
}
