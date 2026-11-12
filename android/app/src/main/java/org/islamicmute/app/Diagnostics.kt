package org.islamicmute.app

import android.app.ActivityManager
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioManager
import android.os.Build
import android.os.PowerManager

/**
 * A plain-text report of everything that decides whether the filter works on this phone: the setup, the phone's
 * speed, dropouts, what is being silenced. The user copies or shares it; nothing is sent by the app.
 *
 * Always in English with fixed labels, whatever the app language: it is read by whoever helps the user.
 * No account, serial number or other identifier is included; app names appear only for apps playing sound now.
 */
object Diagnostics {
    fun report(ctx: Context): String = buildString {
        val s = Settings(ctx)
        val yes = { b: Boolean -> if (b) "yes" else "no" }
        fun granted(p: String) = ctx.checkSelfPermission(p) == PackageManager.PERMISSION_GRANTED

        appendLine("Waaiya ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE}) ${BuildConfig.BUILD_TYPE}")
        appendLine("Phone: ${Build.MANUFACTURER} ${Build.MODEL}, Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})")
        val mem = ActivityManager.MemoryInfo().also { ctx.getSystemService(ActivityManager::class.java).getMemoryInfo(it) }
        appendLine("Chip: ${chip()}, ${Runtime.getRuntime().availableProcessors()} cores, " +
            "ABI ${Build.SUPPORTED_ABIS.joinToString("/")}, RAM ${mem.totalMem / (1 shl 20)} MB (free ${mem.availMem / (1 shl 20)} MB)")
        appendLine("Language: ${Lang.current(ctx)}, user: ${s.gender.ifEmpty { "not chosen" }}")
        appendLine()

        appendLine("[Setup]")
        appendLine("Silence originals (DUMP): ${yes(ctx.hasDumpPermission())}")
        appendLine("Skip screen-share question (PROJECT_MEDIA): ${yes(ctx.hasProjectMediaAppOp())}")
        appendLine("Shizuku: ${ShizukuSetup.state(ctx)}")
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
            appendLine("Model: ${h.model}, delay ${FilterService.delayMs} ms, mono ${yes(h.mono)}, too slow ${yes(h.tooSlow)}")
            appendLine("Speed (a hop must take under 10 ms): last 2 s avg %.1f ms, max %.1f ms, late %.0f%%"
                .format(java.util.Locale.ROOT, h.avgHopMs, h.maxHopMs, h.lateShare * 100))
            appendLine("Speed since start: avg %.1f ms, peak %.1f ms, late %d of %d hops with sound (%d hops in all)"
                .format(java.util.Locale.ROOT, h.overallAvgMs, h.peakHopMs, h.lateHops, h.busyHops, h.hops))
            appendLine("Output: dropouts ${h.underruns}, waiting ${h.bufferedMs} ms, buffer ${h.bufferFrames} of " +
                "${h.bufferCapacityFrames} frames (minimum ${h.minBufferFrames}), grown ${h.extraBufferHops}, " +
                "given back ${h.trimmedHops} hops, keeping ${h.keepHops * 10} ms")
            appendLine("Capture: level ${h.captureDb} dB, read errors ${h.readErrors}, model errors ${h.engineErrors}")
            appendLine("Women's singing filter: " + if (h.gateShare < 0) "off" else "on, muting %.0f%% of the time".format(java.util.Locale.ROOT, h.gateShare * 100))
        }
        appendLine("Starts in mono (learned on this phone): ${yes(s.audioMono)}")
        appendLine("Detector model bundled: ${yes(ModelStore.hasDetector(ctx))}")
        val am = ctx.getSystemService(AudioManager::class.java)
        appendLine("Media playing now (Waaiya's own output counts): ${yes(am.isMusicActive)}, media volume ${am.getStreamVolume(AudioManager.STREAM_MUSIC)}/" +
            "${am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)}, output rate ${am.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE)} Hz, " +
            "burst ${am.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER)} frames")
        appendLine()

        appendLine("[Original sound]")
        val m = h?.muter
        if (m == null) appendLine("Muter: ${FilterService.muterStatus} (details appear while filtering runs)")
        else {
            appendLine("Muter: ${m.status}, list from ${m.source}, polls ${m.polls}, failed polls ${m.pollFailures}, " +
                "sessions that could not be muted ${m.attachFailures}")
            m.lastError?.takeIf { m.status != SessionMuter.Status.NO_PERMISSION }?.let { appendLine("Last error: $it") }
            if (m.status == SessionMuter.Status.NO_PERMISSION) appendLine("Other apps' sound sessions cannot be listed without the setup.")
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
        ScreenBlur.stats?.let { appendLine(it) }
    }

    /** The chip name where Android tells it (API 31+), else the board name. */
    private fun chip(): String =
        if (Build.VERSION.SDK_INT >= 31) "${Build.SOC_MANUFACTURER} ${Build.SOC_MODEL}" else Build.HARDWARE
}
