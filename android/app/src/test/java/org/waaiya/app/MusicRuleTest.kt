package org.waaiya.app

import org.json.JSONArray
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * MusicRule against the evaluation (eval/music_check_eval.py, approach Cg, thresholds of the shipped rule): the tags
 * of 17 test-split clips as the phone computes them (models/music/eval_scan.py), with the evaluation's verdict and
 * parts (resources/music_rule_vectors.json).
 */
class MusicRuleTest {
    private fun vectors(): JSONArray =
        JSONArray(javaClass.classLoader!!.getResourceAsStream("music_rule_vectors.json")!!.bufferedReader().readText())

    @Test fun sameVerdictsAndPartsAsTheEvaluation() {
        val v = vectors()
        assert(v.length() >= 15)
        for (i in 0 until v.length()) {
            val o = v.getJSONObject(i)
            val probs = (0 until o.getJSONArray("probs").length()).map { k ->
                val d = o.getJSONArray("probs").getJSONObject(k)
                FloatArray(MusicRule.CLASSES).also { p -> d.keys().forEach { p[it.toInt()] = d.getDouble(it).toFloat() } }
            }
            val lv = o.getJSONArray("levels").let { a -> FloatArray(a.length()) { a.getDouble(it).toFloat() } }
            val dur = o.getDouble("duration")
            val r = MusicRule.decide(probs, lv, dur)
            val id = o.getString("id")
            assertEquals(id, o.getString("verdict"), r.verdict.name.lowercase())
            val want = o.getJSONArray("parts").let { a -> (0 until a.length()).map { a.getJSONArray(it).let { p -> p.getDouble(0) to minOf(p.getDouble(1), dur) } } }
            assertEquals(id, want, r.parts.map { it.start to it.end })
        }
    }

    @Test fun quietWindowsAreNotJudged() {
        val loud = FloatArray(MusicRule.CLASSES).also { it[137] = 0.99f; it[140] = 0.5f }
        val probs = List(20) { loud }
        assertEquals(MusicRule.Verdict.MUSIC, MusicRule.decide(probs, FloatArray(20) { -20f }, 10.5).verdict)
        assertEquals(MusicRule.Verdict.NONE, MusicRule.decide(probs, FloatArray(20) { -60f }, 10.5).verdict)
    }

    @Test fun shortBurstsAreDroppedAndGapsBridged() {
        val m = FloatArray(MusicRule.CLASSES).also { it[137] = 0.99f; it[140] = 0.5f }
        val z = FloatArray(MusicRule.CLASSES)
        // 2 s of music: under the 3 s minimum
        assertEquals(MusicRule.Verdict.NONE, MusicRule.decide(List(20) { if (it in 4..6) m else z }, FloatArray(20) { -20f }, 10.5).verdict)
        // two 1.5 s bursts 1.5 s apart: bridged into one part
        val r = MusicRule.decide(List(20) { if (it in 2..3 || it in 7..8) m else z }, FloatArray(20) { -20f }, 10.5)
        assertEquals(listOf(MusicRule.Part(1.0, 5.0)), r.parts)
    }

    @Test fun chantAloneIsNotMusic() {
        // the generic "Music" class high, no instrument, drum or genre class: a far adhan's pattern
        val chant = FloatArray(MusicRule.CLASSES).also { it[137] = 0.95f; it[156] = 0.4f; it[177] = 0.3f }
        assertEquals(MusicRule.Verdict.NONE, MusicRule.decide(List(20) { chant }, FloatArray(20) { -20f }, 10.5).verdict)
        assertEquals(MusicRule.Verdict.MUSIC,
            MusicRule.decide(List(20) { chant }, FloatArray(20) { -20f }, 10.5, MusicRule.DEFAULT.copy(guardSpec = null)).verdict)
    }
}
