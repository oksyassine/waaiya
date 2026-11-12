package org.islamicmute.app

/**
 * Watches how long the engine takes per hop, how often the output track runs dry and how much sound waits in it,
 * and decides what the live filter does on this phone: carry on, mix to mono (half the work), let the output
 * buffer grow, give back delay that is no longer needed, or report that the phone cannot keep up.
 *
 * Why: the model has to finish each 10 ms hop in under 10 ms. A phone that needs longer drops sound on both sides
 * (the capture buffer overflows, the output runs dry), which the user hears as cuts.
 *
 * A hop that is merely late leaves one gap, after which the sound it delayed sits in the output buffer as a
 * cushion against the next late hop: the delay grows by itself to the worst lateness seen, up to the buffer
 * size. The same happens at the start, when the first slow hops leave a backlog. So the buffer is allowed to grow
 * while gaps keep coming, and after a calm stretch the part of the cushion that this phone's slowest recent hop
 * does not need is given back (silent hops are skipped), which keeps sound and picture together.
 *
 * No Android classes: tested on the JVM (LoadMonitorTest).
 */
class LoadMonitor(
    private val hopMs: Double = 10.0,
    mono: Boolean = false,
    private val hopFrames: Int = 480,
    private val maxExtraHops: Int = MAX_EXTRA_HOPS,
) {
    enum class Action { NONE, GO_MONO, GROW_BUFFER }

    /** The channels are mixed and the model runs once per hop. */
    var mono = mono
        private set
    /** Even in mono the model does not finish its hops in time: the sound cuts and nothing here can fix it. */
    var tooSlow = false
        private set
    /** Hops added to the output buffer's size because gaps kept coming on a phone that is fast enough. */
    var extraHops = 0
        private set
    /** Silent hops skipped to give back delay. */
    var trimmedHops = 0
        private set
    /** Least sound waiting in the output buffer during the last window, in frames (-1: not measured). */
    var minFillFrames = -1
        private set

    // The last finished window (about 2 s), for the screen and the report.
    var avgMs = 0.0
        private set
    var maxMs = 0.0
        private set
    /** Share of the hops with sound that took longer than a hop (0..1). */
    var lateShare = 0.0
        private set
    var windowUnderruns = 0
        private set

    // Since the start.
    var hops = 0L
        private set
    var busyHops = 0L
        private set
    var lateHops = 0L
        private set
    var peakMs = 0.0
        private set
    /** Dropouts counted by the output track after the warm-up. */
    var underruns = 0
        private set
    private var sumAllMs = 0.0
    val overallAvgMs: Double get() = if (busyHops == 0L) 0.0 else sumAllMs / busyHops

    private var n = 0
    private var busy = 0
    private var late = 0
    private var sumMs = 0.0
    private var winMax = 0.0
    private var lastUnderrunCount = -1
    private var slowWindows = 0
    private var goodWindows = 0
    private var warmMs = 0.0
    private var lateRun = 0
    private var winMinFill = Int.MAX_VALUE
    private val calmFills = ArrayDeque<Int>()   // window minimums since the last gap
    private val recentMax = ArrayDeque<Double>() // slowest hop of each of the last windows
    private var trimPending = 0
    /** Hops of sound kept waiting: enough for the slowest hop of the last minute, plus one. */
    var keepHops = KEEP_HOPS
        private set

    /**
     * Call once per hop from the audio thread. [workNs]: the time the engine took for this hop.
     * [underrunCount]: the output track's running total. [fillFrames]: sound waiting in the output buffer right
     * after this hop was written (-1 if unknown). Returns what to do now.
     */
    fun hop(workNs: Long, underrunCount: Int, fillFrames: Int = -1): Action {
        hops++
        val ms = workNs / 1e6
        if (warmMs < WARMUP_MS) {  // model warm-up and the track's first fill are not this phone's steady speed
            warmMs += maxOf(hopMs, ms)  // about one second of real time, however slow the hops are
            lastUnderrunCount = underrunCount
            return Action.NONE
        }
        if (lastUnderrunCount < 0) lastUnderrunCount = underrunCount
        if (ms >= BUSY_MS) {  // a silent hop skips the model: it says nothing about speed
            busy++; busyHops++
            sumMs += ms; sumAllMs += ms
            if (ms > hopMs) { late++; lateHops++; lateRun++ } else lateRun = 0
        } else lateRun = 0
        if (ms > winMax) winMax = ms
        if (ms > peakMs) peakMs = ms
        if (fillFrames in 0 until winMinFill) winMinFill = fillFrames
        // a window ends after 2 s of hops, or at once when EARLY_LATE_HOPS hops in a row were late: a phone
        // that needs 50 ms per hop would otherwise cut for half a minute before anything is done about it
        if (++n < WINDOW_HOPS && lateRun < EARLY_LATE_HOPS) return Action.NONE
        lateRun = 0

        val newUnderruns = (underrunCount - lastUnderrunCount).coerceAtLeast(0)
        lastUnderrunCount = underrunCount
        underruns += newUnderruns
        windowUnderruns = newUnderruns
        val enough = busy >= MIN_BUSY_HOPS
        avgMs = if (busy > 0) sumMs / busy else 0.0
        maxMs = winMax
        lateShare = if (busy > 0) late.toDouble() / busy else 0.0
        val overloaded = enough && (avgMs > OVERLOAD_SHARE * hopMs || lateShare > LATE_SHARE)
        minFillFrames = if (winMinFill == Int.MAX_VALUE) -1 else winMinFill
        n = 0; busy = 0; late = 0; sumMs = 0.0; winMax = 0.0; winMinFill = Int.MAX_VALUE

        // Give back delay: after CALM_WINDOWS windows without a gap, whatever stayed in the buffer the whole
        // time beyond what the slowest recent hop needs was never used. A gap, or an overloaded phone, starts
        // the count again.
        recentMax.addLast(maxMs)
        if (recentMax.size > JITTER_WINDOWS) recentMax.removeFirst()
        keepHops = maxOf(KEEP_HOPS, Math.ceil(recentMax.max() / hopMs).toInt() + 1)
        if (newUnderruns > 0 || overloaded || minFillFrames < 0) { calmFills.clear(); trimPending = 0 }
        else {
            calmFills.addLast(minFillFrames)
            if (calmFills.size > CALM_WINDOWS) calmFills.removeFirst()
            if (calmFills.size == CALM_WINDOWS) {
                val spare = calmFills.min() / hopFrames - keepHops
                if (spare > 0) { trimPending = spare; calmFills.clear() }
            }
        }

        if (overloaded) {
            goodWindows = 0
            if (!mono) { mono = true; slowWindows = 0; return Action.GO_MONO }
            if (++slowWindows >= SLOW_WINDOWS) tooSlow = true
            return Action.NONE
        }
        if (enough) {
            slowWindows = 0
            if (tooSlow && avgMs < RECOVER_SHARE * hopMs && ++goodWindows >= GOOD_WINDOWS) { tooSlow = false; goodWindows = 0 }
            // fast enough, yet the output ran dry again: the buffer may be too small to hold the cushion
            if (newUnderruns > 0 && extraHops < maxExtraHops) { extraHops++; return Action.GROW_BUFFER }
        }
        return Action.NONE
    }

    /**
     * Call for every hop before writing it; [silent] = the hop holds no sound. True: skip this hop (do not write
     * it), which shortens the delay by one hop without cutting into sound.
     */
    fun takeTrim(silent: Boolean): Boolean {
        if (trimPending == 0 || !silent) return false
        trimPending--
        trimmedHops++
        return true
    }

    companion object {
        const val MAX_EXTRA_HOPS = 4
        const val CALM_WINDOWS = 5       // 10 s without a gap
        const val JITTER_WINDOWS = 30    // the slowest hop is remembered for a minute
        const val KEEP_HOPS = 2          // sound always left waiting: at least 20 ms
        const val WARMUP_MS = 1000.0
        const val WARMUP_HOPS = 100      // the warm-up in hops on a phone that keeps up
        const val WINDOW_HOPS = 200      // 2 s
        const val EARLY_LATE_HOPS = 50   // this many late hops in a row end the window early
        const val MIN_BUSY_HOPS = 50     // a window with less sound than this is not judged
        const val BUSY_MS = 0.5
        const val OVERLOAD_SHARE = 0.75  // average above 75% of a hop: no room left for the uneven hops
        const val LATE_SHARE = 0.15
        const val RECOVER_SHARE = 0.6
        const val SLOW_WINDOWS = 2
        const val GOOD_WINDOWS = 3
    }
}
