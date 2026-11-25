package org.waaiya.app

/**
 * "Check for music" decision (docs/MUSIC_CHECK.md, approach C): from the AudioSet tags of 1 s windows every 0.5 s
 * (engine/src/im_music.c) to the parts with music and a verdict. The same rule as eval/music_check_eval.py
 * (evidence / parts_from / verdict), with the thresholds chosen there on the tune split of the test set, scored on
 * the tags the phone computes (models/music/eval_scan.py). Pure Kotlin: JVM tests check it against vectors exported
 * from the evaluation (MusicRuleTest).
 */
object MusicRule {
    const val CLASSES = 527
    const val STEP_S = 0.5
    const val WINDOW_S = 1.0

    // AudioSet class groups (models/detector/efficientat/class_labels_indices.csv)
    private const val MUSIC = 137
    /** strings, keys, mallets, brass, bowed, wind, harmonica..theremin; no bells, chimes, singing bowl */
    private val TONAL_INSTR = ((138..160) + (178..199) + (208..213)).toIntArray()
    /** Percussion .. Gong: drums, cymbals, tabla, tambourine, rattles */
    private val PERC = (161..177).toList().toIntArray()
    /** the drums without the gong: a far adhan's echo tail can pass for a gong */
    private val PERC_NO_GONG = (161..176).toList().toIntArray()
    /** music genres and moods; no beatboxing, opera, vocal music, a cappella, lullaby (voice-only possible) */
    private val GENRE = (216..282).filter { it !in setOf(218, 238, 254, 255, 271) }.toIntArray()
    /** singing, choir, chant, mantra... vocal music, a cappella */
    private val VOCAL = ((27..36) + listOf(254, 255)).toIntArray()
    private val SPECIFIC = TONAL_INSTR + PERC_NO_GONG + GENRE

    data class Thresholds(
        val music: Float = 0.75f,
        /** how much of the strongest voice class is taken off the generic "Music" class */
        val vocal: Float = 0.0f,
        val perc: Float = 0.1f,
        val tonalMax: Float = 0.3f,
        /** share of a part's windows that look like drums alone for "percussion only" */
        val pshare: Float = 0.3f,
        /** windows quieter than this (dBFS) are not judged */
        val minLevelDb: Float = -45f,
        /** adhan guard: a music window needs a specific instrument, drum or genre class above [guardSpec] within
         *  [guardRadius] windows; null = no guard */
        val guardSpec: Float? = null,
        val guardRadius: Int = 0,
        val minPartS: Double = 3.0,
        val gapS: Double = 2.0,
    )

    val DEFAULT = Thresholds()

    enum class Verdict { NONE, MUSIC, PERCUSSION }

    data class Part(val start: Double, val end: Double)

    data class Result(val verdict: Verdict, val parts: List<Part>)

    private fun max(p: FloatArray, idx: IntArray): Float {
        var m = 0f
        for (i in idx) if (p[i] > m) m = p[i]
        return m
    }

    /** Per window: music flag and percussion-like flag. probs[k] = the 527 tags of window k. */
    fun evidence(probs: List<FloatArray>, levelsDb: FloatArray, th: Thresholds = DEFAULT): Pair<BooleanArray, BooleanArray> {
        val n = probs.size
        val mus = BooleanArray(n)
        val perc = BooleanArray(n)
        val guard = th.guardSpec != null
        val drumsIdx = if (guard) PERC_NO_GONG else PERC
        for (k in 0 until n) {
            val p = probs[k]
            if (levelsDb[k] <= th.minLevelDb) continue
            val ton = max(p, TONAL_INSTR)
            val drums = max(p, drumsIdx)
            // "Music" also answers to singing and chant: a voice-only window loses part of it
            val score = maxOf(p[MUSIC] - th.vocal * max(p, VOCAL), ton, max(p, GENRE))
            val pc = drums > th.perc && ton < th.tonalMax
            mus[k] = score > th.music || pc
            perc[k] = pc
        }
        if (guard) {
            val spec = FloatArray(n) { max(probs[it], SPECIFIC) }
            for (k in 0 until n) {
                if (!mus[k] || perc[k]) continue
                var near = 0f
                for (j in maxOf(0, k - th.guardRadius)..minOf(n - 1, k + th.guardRadius)) near = maxOf(near, spec[j])
                if (near <= th.guardSpec!!) mus[k] = false
            }
        }
        return mus to perc
    }

    /** Flagged windows -> parts: gaps under gapS bridged, parts under minPartS dropped. */
    fun parts(flags: BooleanArray, th: Thresholds = DEFAULT): List<Part> {
        val segs = ArrayList<DoubleArray>()
        for (k in flags.indices) {
            if (!flags[k]) continue
            val s = k * STEP_S
            val last = segs.lastOrNull()
            if (last != null && s <= last[1] + th.gapS) last[1] = s + WINDOW_S else segs.add(doubleArrayOf(s, s + WINDOW_S))
        }
        return segs.filter { it[1] - it[0] >= th.minPartS }.map { Part(it[0], it[1]) }
    }

    fun decide(probs: List<FloatArray>, levelsDb: FloatArray, durationS: Double, th: Thresholds = DEFAULT): Result {
        val (mus, perc) = evidence(probs, levelsDb, th)
        val parts = parts(mus, th).map { Part(it.start, minOf(it.end, durationS)) }
        if (parts.isEmpty()) return Result(Verdict.NONE, emptyList())
        // percussion only: in every part, a large share of the windows look like drums without a melodic instrument
        val percOnly = parts.all { pt ->
            val ks = mus.indices.filter { val t = it * STEP_S; t >= pt.start && t < pt.end }
            ks.isNotEmpty() && ks.count { perc[it] }.toDouble() / ks.size >= th.pshare
        }
        return Result(if (percOnly) Verdict.PERCUSSION else Verdict.MUSIC, parts)
    }
}
