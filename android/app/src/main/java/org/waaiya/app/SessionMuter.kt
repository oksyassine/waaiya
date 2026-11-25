package org.waaiya.app

import android.content.Context
import android.media.AudioManager
import android.media.AudioPlaybackConfiguration
import android.media.audiofx.DynamicsProcessing
import android.os.Build
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
 * `adb shell pm grant org.waaiya.app android.permission.DUMP`) the app reads the audio policy
 * dump to find every playing session ([AudioDump]), then attaches a top-priority DynamicsProcessing
 * effect with -200 dB input gain to each session. Capture taps the audio before that effect,
 * so the filter still receives it.
 *
 * Phones that refuse the grant (Xiaomi, OPPO family) get the two dumps from Waaiya's helper instead ([HelperDumps]):
 * the effects are attached by the app either way. Without both the originals cannot be muted and the user would hear
 * both; the UI says so ([status]). The helper can stop while filtering (Developer options turned off): the status
 * then goes back to NO_PERMISSION and silencing resumes when it is back.
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
        running = true
        if (context.canListSessions()) { begin(); return }
        lastError = if (HelperDumps.helperMode(context)) "Waaiya's helper is not running" else "DUMP permission not granted"
        status = Status.NO_PERMISSION
        // The setup can finish while filtering runs (Shizuku answering late, Wireless debugging, a computer, the
        // helper started again): start silencing the originals as soon as the list can be read, without a restart.
        thread(name = "im-muter-wait", isDaemon = true) {
            while (running && !context.canListSessions()) {
                wake.tryAcquire(2, TimeUnit.SECONDS)  // stop() releases it: no 2 s wait at the end
                wake.drainPermits()
            }
            val began = synchronized(this) { if (running) { lastError = null; begin(); true } else false }
            if (began) { Log.i("IslamicMute", "muter: permission granted while filtering, silencing now"); onChange?.invoke() }
        }
    }

    /** With the permission: listen for players and poll the session list until [stop]. */
    private fun begin() {
        status = Status.OK
        context.getSystemService(AudioManager::class.java).registerAudioPlaybackCallback(playbackCallback, null)
        thread(name = "im-muter", isDaemon = true) {
            Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
            while (running) {
                val before = status to blockedUids
                if (!context.canListSessions()) {
                    // the helper went away (helper mode): what is muted stays muted, new players are not. An app
                    // the user adds to "heard unfiltered" meanwhile is let go from the last list read, so it is not
                    // left silent (the capture now leaves it out)
                    val off = FilterService.captureExcluded ?: FixMistakes.filterOffUids(context, settings)
                    synchronized(effects) {
                        for (ss in sessions) if (ss.uid in off) { effects.remove(ss.id)?.release(); missed.remove(ss.id) }
                    }
                    status = Status.NO_PERMISSION
                    lastError = "Waaiya's helper stopped"
                    if (before != status to blockedUids) onChange?.invoke()
                    wake.tryAcquire(2, TimeUnit.SECONDS)
                    wake.drainPermits()
                    continue
                }
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

    /** Releases every effect: the other apps sound normal again. Any poll still running attaches nothing more. */
    fun stop() {
        synchronized(this) { running = false }
        runCatching { context.getSystemService(AudioManager::class.java).unregisterAudioPlaybackCallback(playbackCallback) }
        wake.release()
        synchronized(effects) { effects.values.forEach { runCatching { it.release() } }; effects.clear() }
    }

    fun info(): Info = Info(status, sessions, synchronized(effects) { effects.keys.toSet() }, attachFailures,
        pollFailures, polls, source, lastError)

    private fun poll() {
        polls++
        // The policy dump has session ids on every Android version and the real "refuses capture" flag.
        // `dumpsys audio` has session ids from Android 12: read there too, so a phone whose policy dump has a
        // layout this app does not know still gets the list that earlier versions used.
        var raw = ""
        val policy = runCatching { AudioDump.parsePolicy(dump("media.audio_policy").also { raw = it }) }
            .onFailure { lastError = "audio_policy: $it" }.getOrDefault(emptyList())
        val service = if (Build.VERSION.SDK_INT >= 31 || policy.isEmpty())
            AudioDump.parseService(dump("audio").also { if (raw.isBlank()) raw = it }) else emptyList()
        // No session at all while something plays (this app's own player is in these lists too): the dumps are not
        // readable here (a refusal printed instead of the list, or a layout this app does not know). Saying "OK"
        // would leave the music audible without a word.
        // The start of what came back goes into the error (and so into the diagnostics report): on a phone that
        // refuses the dump it is the refusal itself.
        if (policy.isEmpty() && service.isEmpty() && (raw.contains("Permission Denial", ignoreCase = true) ||
                context.getSystemService(AudioManager::class.java).isMusicActive))
            error("no sound session found in the system's lists, which begin: " +
                raw.trim().take(200).replace(Regex("\\s+"), " ").ifEmpty { "(nothing)" })
        var list = AudioDump.merge(policy, service)
        source = when {
            policy.isNotEmpty() && service.isNotEmpty() -> "audio_policy+audio (${policy.size}+${service.size})"
            policy.isNotEmpty() -> "audio_policy"
            service.isNotEmpty() -> "audio"
            else -> "none"
        } + if (context.hasDumpPermission()) "" else " via Waaiya's helper"
        val me = Process.myUid()
        // apps the user chose to hear unfiltered (FixMistakes, filter_off_apps): the capture leaves them out, so their
        // original must play. Left out like our own uid (not "blocked", not counted as unmuted); an effect already on
        // one of their sessions is released below at once.
        // what the running capture really leaves out: when a capture with a new list could not open, the old one goes
        // on and an app just added is still filtered, so its original stays muted (not heard twice)
        val off = FilterService.captureExcluded ?: FixMistakes.filterOffUids(context, settings)
        val offIds = list.filter { it.uid in off }.map { it.id }.toSet()
        list = list.filter { it.uid != me && it.id > 0 && it.uid !in off }
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
                // stop() may have run while this poll read the session list: it clears [effects] under this lock
                // after setting running = false, so an effect attached now would never be released and that app
                // would stay silent until Waaiya's process ends
                if (!running) return
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
                if (id in offIds) { effects.remove(id)?.release(); missed.remove(id); continue }
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
        if (!context.hasDumpPermission()) return HelperDumps.read(service)
        val sm = Class.forName("android.os.ServiceManager")
        val binder = sm.getMethod("getService", String::class.java).invoke(null, service) as IBinder
        val pipe = ParcelFileDescriptor.createPipe()
        binder.dumpAsync(pipe[1].fileDescriptor, arrayOf())
        pipe[1].close()
        return FileInputStream(pipe[0].fileDescriptor).use { it.readBytes().toString(Charsets.UTF_8) }.also { pipe[0].close() }
    }
}
