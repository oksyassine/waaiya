package org.waaiya.app

import java.io.File

/**
 * What the live filter did second by second, for the diagnostics report: the status lines say how things are now,
 * but a tester whose sound got stuck turns filtering off and on before sending the report, and the moment that
 * mattered is gone. So this keeps:
 * - one line per second for the last [SECONDS] seconds (written by the filter's watchdog, even when the filter loop
 *   itself is stuck);
 * - the last [EVENTS] events (stuck sound found, what was tried, sound back, starts and stops);
 * - copies of the last minute taken at the moments that matter ([snapshot]): when the user stops filtering, when
 *   filtering stops by itself, around stuck sound, and the minute the previous run of Waaiya left behind.
 *
 * Saved to two files: the live lines every few seconds ([flush], about 12 KB), the events and snapshots when they
 * change. A process that Android ends keeps its last minute.
 * No Android classes: tested on the JVM (RecentLogTest).
 */
class RecentLog(private val file: File?) {
    data class Snapshot(val kind: String, val title: String, val lines: List<String>)

    private val lines = ArrayDeque<String>()
    private val events = ArrayDeque<String>()
    private val snaps = LinkedHashMap<String, Snapshot>()
    private var dirty = false

    init { load() }

    @Synchronized fun second(line: String) {
        lines.addLast(line)
        while (lines.size > SECONDS) lines.removeFirst()
        dirty = true
    }

    @Synchronized fun event(line: String) {
        events.addLast(line)
        while (events.size > EVENTS) events.removeFirst()
        saveKept()
    }

    /** Keeps the last [n] seconds under [kind] (one copy per kind, the newest). */
    @Synchronized fun snapshot(kind: String, title: String, n: Int = SNAP) {
        if (lines.isEmpty()) return
        snaps.remove(kind)
        snaps[kind] = Snapshot(kind, title, lines.toList().takeLast(n))
        saveKept()
    }

    /** The live lines are about to restart (a new filtering session): nothing to keep from them beyond the snapshots. */
    @Synchronized fun clearLive() { lines.clear(); saveLive() }

    /** Saves when lines came since the last save (called every few seconds by the watchdog). */
    @Synchronized fun flush() { if (dirty) saveLive() }

    @Synchronized fun report(live: Boolean): String = buildString {
        appendLine("Events (newest last):")
        if (events.isEmpty()) appendLine("  none") else events.forEach { appendLine("  $it") }
        if (live) {
            appendLine("Last minute, one line per second:")
            if (lines.isEmpty()) appendLine("  none yet") else lines.toList().takeLast(SNAP).forEach { appendLine("  $it") }
        }
        for (s in snaps.values.reversed()) {
            appendLine("${s.title}:")
            s.lines.forEach { appendLine("  $it") }
        }
        append(LEGEND)
    }.trimEnd()

    @Synchronized fun snapshots(): List<Snapshot> = snaps.values.toList()
    @Synchronized fun eventLines(): List<String> = events.toList()
    @Synchronized fun liveLines(): List<String> = lines.toList()

    private val liveFile get() = file?.let { File(it.path + ".live") }

    private fun saveLive() {
        dirty = false
        write(liveFile, buildString { lines.forEach { append("L ").append(it).append('\n') } })
    }

    private fun saveKept() = write(file, buildString {
        events.forEach { append("E ").append(it).append('\n') }
        for (s in snaps.values) {
            append("S ").append(s.kind).append('\t').append(s.title).append('\n')
            s.lines.forEach { append("s ").append(it).append('\n') }
        }
    })

    private fun write(f: File?, text: String) {
        f ?: return
        runCatching {
            val tmp = File(f.path + ".tmp")
            tmp.writeText(text)
            tmp.renameTo(f)
        }
    }

    /**
     * Reads the file of the previous run. Its live lines become the snapshot "previous run": a process that ended (or
     * was ended) while filtering left its last minute there.
     */
    private fun load() {
        val f = file ?: return
        val text = listOfNotNull(f, liveFile).joinToString("\n") { runCatching { it.readText() }.getOrDefault("") }
        val old = ArrayList<String>()
        var cur: Pair<String, String>? = null
        var curLines = ArrayList<String>()
        fun close() { cur?.let { (k, t) -> snaps[k] = Snapshot(k, t, curLines) }; cur = null; curLines = ArrayList() }
        for (l in text.split('\n')) {
            if (l.length < 2) continue
            val body = l.substring(2)
            when (l[0]) {
                'L' -> old += body
                'E' -> events.addLast(body)
                'S' -> { close(); val tab = body.indexOf('\t'); if (tab > 0) cur = body.substring(0, tab) to body.substring(tab + 1) }
                's' -> curLines += body
            }
        }
        close()
        while (events.size > EVENTS) events.removeFirst()
        if (old.isNotEmpty()) {
            snaps.remove(PREVIOUS_RUN)
            snaps[PREVIOUS_RUN] = Snapshot(PREVIOUS_RUN, "The last minute saved by the previous run of Waaiya (its process ended)",
                old.takeLast(SNAP))
            saveKept(); saveLive()  // kept once: the next process does not see these lines again
        }
    }

    companion object {
        const val SECONDS = 120
        const val EVENTS = 40
        const val SNAP = 60
        const val PREVIOUS_RUN = "previous_run"
        const val LEGEND = "Line: time, h hops done that second (100 = all), in / out loudest sound captured / played (dB), " +
            "w model ms (slowest hop), r wait for the capture ms, wr wait to write the output ms, drop output dropouts, " +
            "cap sound waiting in the capture ms, buf in the output ms, play muted apps playing, at where the loop is / " +
            "for how long ms, scr screen; late: this line came that many ms late (rt real time, up awake time: up much " +
            "smaller than rt = the phone slept; both = Waaiya was not run)."
    }
}

/** The app's one [RecentLog], in the app's files. */
object Recent {
    @Volatile private var log: RecentLog? = null

    fun of(ctx: android.content.Context): RecentLog = log ?: synchronized(this) {
        log ?: RecentLog(File(ctx.applicationContext.filesDir, "recent_log.txt")).also { log = it }
    }

    /** An event with the date and time, and whether the screen was on and locked. Any thread. */
    fun event(ctx: android.content.Context, what: String) {
        val time = java.text.SimpleDateFormat("MM-dd HH:mm:ss", java.util.Locale.ROOT).format(java.util.Date())
        android.util.Log.i("IslamicMute", "event: $what")
        val screen = runCatching {
            val on = ctx.getSystemService(android.os.PowerManager::class.java).isInteractive
            val locked = ctx.getSystemService(android.app.KeyguardManager::class.java).isKeyguardLocked
            " (screen ${if (on) "on" else "off"}${if (locked) ", locked" else ""})"
        }.getOrDefault("")
        of(ctx).event("$time $what$screen")
    }
}
