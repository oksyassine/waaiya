package org.waaiya.app

/**
 * Decides, once a second, whether the live filter's sound is stuck, and what to try. A tester's phone (HyperOS 3,
 * MediaTek) went silent while filtering said "on", until the user turned filtering off and on; nothing in the app saw
 * it. The cause is not known yet, so this only acts where a state cannot be normal, and the per-second log
 * ([RecentLog]) records the inputs either way, so the next report names the cause.
 *
 * - Capture silent while an app Waaiya mutes is playing (5 s): the capture is rebuilt on the same screen share, with
 *   no gap. This can be normal (a feed video autoplaying muted gives silence), so it is the only step taken, at most
 *   once a minute, and filtering never ends for it.
 * - The loop waits for the capture (3 s) while a muted app plays: the capture is rebuilt, once per episode.
 * - The output does not play (its position stands still for 2 s) while the loop writes to it or waits to: the
 *   output is made again. Writing may wait, or return at once having taken nothing (a paused track on Android 16):
 *   either way nothing is heard. That cannot be normal; after two rebuilds that did not help, filtering ends with the
 *   other apps kept silent and the notification's Resume (State.SILENCED), the one thing left: a new screen share
 *   needs a tap.
 * - The model call or anything else in the loop takes over 2 s: logged only.
 *
 * No Android classes: tested on the JVM (StuckDetectorTest).
 */
class StuckDetector {
    enum class Phase { READ, ENGINE, WRITE, OTHER }
    enum class Action { NONE, REBUILD_CAPTURE, REBUILD_OUTPUT, END }

    /** One second of the loop as the watchdog saw it. */
    data class Second(
        /** Hops the loop finished during this second. */
        val hops: Int,
        /** Loudest captured sample this second, dBFS (-120: nothing). */
        val inDb: Int,
        /** Apps playing now whose original Waaiya mutes (media sessions): their sound should reach the capture. */
        val playing: Int,
        /** Where the loop is now, and since how long (ms). */
        val phase: Phase, val phaseMs: Long,
        /** The output played some sound waiting in it during this second (its position moved; false for the
         *  second in which the output was made again). */
        val headMoved: Boolean,
    )

    /** What happened this second, for the log (null: nothing new). */
    var event: String? = null
        private set
    /** This second began an episode of stuck sound (the watchdog keeps the minute around it). */
    var episodeStarted = false
        private set

    private var tick = 0L
    private var silentSecs = 0
    private var silentEpisode = false
    private var lastCaptureRebuild = -BACKOFF_S
    private var readEpisode = false
    private var writeEpisode = false
    private var outputRebuilds = 0
    private var stillSecs = 0
    private var slowNoted = false

    fun second(s: Second): Action {
        tick++
        event = null
        episodeStarted = false
        var action = Action.NONE
        val flowing = s.hops >= MIN_HOPS

        // the capture gives silence while a muted app plays
        if (s.playing > 0 && flowing && s.inDb <= SILENT_DB) {
            silentSecs++
            if (silentSecs == SILENT_S) {
                silentEpisode = true; episodeStarted = true
                if (tick - lastCaptureRebuild >= BACKOFF_S) {
                    lastCaptureRebuild = tick
                    action = Action.REBUILD_CAPTURE
                    event = "no sound from the capture for $SILENT_S s while ${s.playing} muted app(s) played: capture rebuilt"
                } else event = "no sound from the capture for $SILENT_S s while ${s.playing} muted app(s) played " +
                    "(capture rebuilt ${tick - lastCaptureRebuild} s ago: only logged)"
            }
        } else {
            if (silentEpisode && s.inDb > SILENT_DB) event = "sound from the capture again after ${silentSecs} s"
            if (s.inDb > SILENT_DB || s.playing == 0) { silentSecs = 0; silentEpisode = false }
        }

        // the output does not play while the loop gives it sound (or waits to)
        stillSecs = if (!s.headMoved && (flowing || s.phase == Phase.WRITE)) stillSecs + 1 else 0
        // the loop does not come back from one place
        when {
            stillSecs >= STILL_S -> {
                stillSecs = 0
                if (!writeEpisode) { writeEpisode = true; episodeStarted = true }
                if (outputRebuilds < MAX_OUTPUT_REBUILDS) {
                    outputRebuilds++
                    action = Action.REBUILD_OUTPUT
                    event = "the output does not play (position still for $STILL_S s, loop at ${s.phase.name.lowercase()} " +
                        "${s.phaseMs} ms): output made again ($outputRebuilds)"
                } else {
                    action = Action.END
                    event = "the output does not play after $MAX_OUTPUT_REBUILDS rebuilds: filtering ends, other apps stay silent"
                }
            }
            s.phase == Phase.READ && s.phaseMs >= READ_STALL_MS && s.playing > 0 -> if (!readEpisode) {
                readEpisode = true; episodeStarted = true
                if (action == Action.NONE) action = Action.REBUILD_CAPTURE
                lastCaptureRebuild = tick
                event = "no sound came from the capture for ${s.phaseMs} ms while ${s.playing} muted app(s) played: capture rebuilt"
            }
            (s.phase == Phase.ENGINE || s.phase == Phase.OTHER) && s.phaseMs >= SLOW_STEP_MS -> if (!slowNoted) {
                slowNoted = true
                event = "the filter loop is held ${s.phaseMs} ms in ${s.phase.name.lowercase()}"
            }
        }
        if (flowing) { readEpisode = false; slowNoted = false }  // the loop runs again
        if (flowing && s.headMoved) {
            if (writeEpisode) event = event ?: "the output plays again"
            writeEpisode = false; outputRebuilds = 0
        }
        return action
    }

    companion object {
        const val SILENT_DB = -100
        const val SILENT_S = 5
        const val BACKOFF_S = 60L
        const val MIN_HOPS = 50
        const val STILL_S = 2
        const val READ_STALL_MS = 3000L
        const val SLOW_STEP_MS = 2000L
        const val MAX_OUTPUT_REBUILDS = 2
    }
}
