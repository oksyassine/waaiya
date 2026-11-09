package org.islamicmute.app

import android.content.Context
import android.media.audiofx.DynamicsProcessing
import android.os.IBinder
import android.os.ParcelFileDescriptor
import android.os.Process
import android.util.Log
import java.io.FileInputStream
import kotlin.concurrent.thread

/**
 * Silences the ORIGINAL audio of other apps so the user hears only the filtered copy.
 *
 * Technique (as in RootlessJamesDSP): with the DUMP permission (granted once, either with one tap
 * through Shizuku, see [ShizukuSetup], or over ADB:
 * `adb shell pm grant org.islamicmute.app android.permission.DUMP`) the app reads the audio
 * service dump to find every playing session, then attaches a top-priority DynamicsProcessing
 * effect with -200 dB input gain to each session. Capture taps the audio before that effect,
 * so the filter still receives it.
 *
 * Without DUMP the originals cannot be muted and the user would hear both; the UI says so.
 */
class SessionMuter(private val context: Context, private val settings: Settings) {
    private data class Session(val id: Int, val uid: Int, val usage: String, val capturable: Boolean)

    private val effects = HashMap<Int, DynamicsProcessing>()
    private val missed = HashMap<Int, Int>()
    @Volatile private var running = false
    /** Optional extra gain for the filtered output (used later by the singing/gender gate). */
    @Volatile var gate: Float? = null
    @Volatile var lastError: String? = null
        private set

    fun start() {
        if (!context.hasDumpPermission()) { lastError = "DUMP permission not granted"; return }
        running = true
        thread(name = "im-muter", isDaemon = true) {
            while (running) {
                runCatching { poll() }.onFailure { lastError = it.message; Log.w("IslamicMute", "muter: $it") }
                Thread.sleep(500)
            }
        }
    }

    fun stop() {
        running = false
        synchronized(effects) { effects.values.forEach { runCatching { it.release() } }; effects.clear() }
    }

    private fun poll() {
        val sessions = parse(dump("audio"))
        val me = Process.myUid()
        val seen = HashSet<Int>()
        for (s in sessions) {
            if (s.uid == me || s.id <= 0) continue
            val filterable = s.capturable && s.usage in setOf("USAGE_MEDIA", "USAGE_GAME", "USAGE_UNKNOWN")
            // Filterable sessions: mute the original (we play the filtered copy).
            // Unfilterable media (app opted out of capture): mute too if the user chose fail-closed.
            val mute = filterable || (s.usage in setOf("USAGE_MEDIA", "USAGE_GAME") && settings.silenceUnfilterable)
            if (!mute) continue
            seen += s.id
            synchronized(effects) {
                if (s.id !in effects) {
                    runCatching {
                        DynamicsProcessing(Int.MAX_VALUE, s.id, null).apply {
                            setInputGainAllChannelsTo(-200f)
                            enabled = true
                        }
                    }.onSuccess { effects[s.id] = it }.onFailure { Log.w("IslamicMute", "cannot mute session ${s.id}: $it") }
                }
            }
        }
        synchronized(effects) {
            for (id in effects.keys.toList()) {
                if (id in seen) { missed.remove(id); continue }
                val m = (missed[id] ?: 0) + 1
                if (m >= 6) { effects.remove(id)?.release(); missed.remove(id) } else missed[id] = m
            }
        }
    }

    private fun dump(service: String): String {
        val sm = Class.forName("android.os.ServiceManager")
        val binder = sm.getMethod("getService", String::class.java).invoke(null, service) as IBinder
        val pipe = ParcelFileDescriptor.createPipe()
        binder.dumpAsync(pipe[1].fileDescriptor, arrayOf())
        pipe[1].close()
        return FileInputStream(pipe[0].fileDescriptor).use { it.readBytes().toString(Charsets.UTF_8) }.also { pipe[0].close() }
    }

    /** Parses AudioPlaybackConfiguration lines of `dumpsys audio`. Field names vary across Android versions. */
    private fun parse(text: String): List<Session> {
        val out = ArrayList<Session>()
        val uidRe = Regex("""u/pid:(\d+)/""")
        val sessionRe = Regex("""session(?:Id)?[:=]\s*(\d+)""")
        val usageRe = Regex("""usage=(USAGE_\w+)""")
        val flagsRe = Regex("""flags=0x([0-9A-Fa-f]+)""")
        for (line in text.lineSequence()) {
            if (!line.contains("AudioPlaybackConfiguration") && !line.contains("piid:")) continue
            if (line.contains("state:released")) continue
            val uid = uidRe.find(line)?.groupValues?.get(1)?.toIntOrNull() ?: continue
            val id = sessionRe.find(line)?.groupValues?.get(1)?.toIntOrNull() ?: continue
            val usage = usageRe.find(line)?.groupValues?.get(1) ?: "USAGE_UNKNOWN"
            val flags = flagsRe.find(line)?.groupValues?.get(1)?.toIntOrNull(16) ?: 0
            val noProjection = flags and 0x400 != 0  // AudioAttributes.FLAG_NO_MEDIA_PROJECTION
            out += Session(id, uid, usage, !noProjection)
        }
        return out
    }
}
