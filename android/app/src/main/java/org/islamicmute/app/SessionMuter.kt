package org.islamicmute.app

import android.content.Context
import android.media.AudioManager
import android.media.AudioPlaybackConfiguration
import android.media.audiofx.DynamicsProcessing
import android.os.IBinder
import android.os.ParcelFileDescriptor
import android.os.Process
import android.util.Log
import java.io.FileInputStream
import java.util.concurrent.Semaphore
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

/**
 * Silences the ORIGINAL audio of other apps so the user hears only the filtered copy.
 *
 * Technique (as in RootlessJamesDSP): with the DUMP permission (granted once, either with one tap
 * through Shizuku, see [ShizukuSetup], or over ADB:
 * `adb shell pm grant org.islamicmute.app android.permission.DUMP`) the app reads the audio policy
 * dump to find every playing session ([AudioDump]), then attaches a top-priority DynamicsProcessing
 * effect with -200 dB input gain to each session. Capture taps the audio before that effect,
 * so the filter still receives it.
 *
 * Without DUMP the originals cannot be muted and the user would hear both; the UI says so ([status]).
 */
class SessionMuter(private val context: Context, private val settings: Settings) {
    /** What the screen and the diagnostics report show. */
    enum class Status {
        /** The one-time setup is missing: originals play next to the filtered copy. */
        NO_PERMISSION,
        OK,
        /** The setup is done but the system's session list cannot be read or a session cannot be muted. */
        FAILING,
    }

    /** A snapshot for the diagnostics report. */
    data class Info(
        val status: Status,
        val sessions: List<AudioSession>,
        val muted: Set<Int>,
        val attachFailures: Int,
        val pollFailures: Int,
        val polls: Int,
        val source: String,
        val lastError: String?,
    )

    private val effects = HashMap<Int, DynamicsProcessing>()
    private val missed = HashMap<Int, Int>()
    @Volatile private var running = false
    // Woken as soon as any player starts or changes state, so a new video is muted in ~0.1 s (the dump) instead
    // of up to 0.6 s with polling alone. The 500 ms poll stays as a fallback.
    private val wake = Semaphore(0)
    private val playbackCallback = object : AudioManager.AudioPlaybackCallback() {
        override fun onPlaybackConfigChanged(configs: MutableList<AudioPlaybackConfiguration>?) { wake.release() }
    }
    /** Optional extra gain for the filtered output (used later by the singing/gender gate). */
    @Volatile var gate: Float? = null
    @Volatile var lastError: String? = null
        private set
    @Volatile var status = Status.NO_PERMISSION
        private set
    /** Apps playing media now that refuse capture: silenced (fail-closed setting) or playing unfiltered. */
    @Volatile var blockedUids: Set<Int> = emptySet()
        private set
    @Volatile private var sessions: List<AudioSession> = emptyList()
    @Volatile private var source = "-"
    @Volatile private var attachFailures = 0
    @Volatile private var pollFailures = 0
    @Volatile private var polls = 0
    private var failedInARow = 0
    /** Called (on the muter thread) when [status] or [blockedUids] changes. */
    var onChange: (() -> Unit)? = null

    fun start() {
        if (!context.hasDumpPermission()) { lastError = "DUMP permission not granted"; status = Status.NO_PERMISSION; return }
        running = true
        status = Status.OK
        context.getSystemService(AudioManager::class.java).registerAudioPlaybackCallback(playbackCallback, null)
        thread(name = "im-muter", isDaemon = true) {
            Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
            while (running) {
                val before = status to blockedUids
                runCatching { poll(); failedInARow = 0 }.onFailure {
                    lastError = it.toString(); pollFailures++
                    if (++failedInARow >= 4) status = Status.FAILING  // 2 s without a readable list
                    Log.w("IslamicMute", "muter: $it")
                }
                if (before != status to blockedUids) onChange?.invoke()
                wake.tryAcquire(500, TimeUnit.MILLISECONDS)
                wake.drainPermits()
            }
        }
    }

    fun stop() {
        running = false
        runCatching { context.getSystemService(AudioManager::class.java).unregisterAudioPlaybackCallback(playbackCallback) }
        wake.release()
        synchronized(effects) { effects.values.forEach { runCatching { it.release() } }; effects.clear() }
    }

    fun info(): Info = Info(status, sessions, synchronized(effects) { effects.keys.toSet() }, attachFailures,
        pollFailures, polls, source, lastError)

    private fun poll() {
        polls++
        // The policy dump works on every Android version; `dumpsys audio` only helps where the policy dump's
        // layout is one this app does not know yet.
        var list = AudioDump.parsePolicy(dump("media.audio_policy"))
        source = "audio_policy"
        if (list.isEmpty()) {
            val fromService = AudioDump.parseService(dump("audio"))
            if (fromService.isNotEmpty()) { list = fromService; source = "audio" }
        }
        val me = Process.myUid()
        list = list.filter { it.uid != me && it.id > 0 }
        sessions = list
        val seen = HashSet<Int>()
        var failedNow = 0
        for (s in list) {
            // Filterable sessions: mute the original (we play the filtered copy).
            // Unfilterable media (app opted out of capture): mute too if the user chose fail-closed.
            val mute = AudioDump.filterable(s) || (AudioDump.blocked(s) && settings.silenceUnfilterable)
            if (!mute) continue
            seen += s.id
            synchronized(effects) {
                if (s.id !in effects) {
                    runCatching {
                        DynamicsProcessing(Int.MAX_VALUE, s.id, null).apply {
                            setInputGainAllChannelsTo(-200f)
                            enabled = true
                        }
                    }.onSuccess {
                        effects[s.id] = it
                        Log.i("IslamicMute", "muter: original of session ${s.id} (uid ${s.uid}, ${s.usage}" +
                            "${if (s.capturable) "" else ", refuses capture"}) silenced")
                    }.onFailure {
                        attachFailures++; failedNow++
                        lastError = "cannot mute session ${s.id} (uid ${s.uid}): $it"
                        Log.w("IslamicMute", "cannot mute session ${s.id}: $it")
                    }
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
        blockedUids = list.filter { it.active && AudioDump.blocked(it) }.map { it.uid }.toSet()
        // a playing session that stays unmuted means the user hears the music
        val unmutedPlaying = list.any { it.active && AudioDump.filterable(it) && synchronized(effects) { it.id !in effects } }
        status = if (failedNow > 0 || unmutedPlaying) Status.FAILING else Status.OK
    }

    private fun dump(service: String): String {
        val sm = Class.forName("android.os.ServiceManager")
        val binder = sm.getMethod("getService", String::class.java).invoke(null, service) as IBinder
        val pipe = ParcelFileDescriptor.createPipe()
        binder.dumpAsync(pipe[1].fileDescriptor, arrayOf())
        pipe[1].close()
        return FileInputStream(pipe[0].fileDescriptor).use { it.readBytes().toString(Charsets.UTF_8) }.also { pipe[0].close() }
    }
}
