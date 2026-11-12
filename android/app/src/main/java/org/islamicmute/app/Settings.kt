package org.islamicmute.app

import android.content.Context

/** User choices. The religious rules are the user's choice; the app only applies them. */
class Settings(context: Context) {
    private val p = context.getSharedPreferences("settings", Context.MODE_PRIVATE)

    /** "man", "woman" or "" (not answered yet). Asked at first launch. */
    var gender: String
        get() = p.getString("gender", "") ?: ""
        set(v) = p.edit().putString("gender", v).apply()

    /** For men: also mute women's singing (needs the singing/gender detector model). */
    var muteWomenSinging: Boolean
        get() = p.getBoolean("mute_women_singing", false)
        set(v) = p.edit().putBoolean("mute_women_singing", v).apply()

    /** Fail-closed: silence apps whose audio cannot be filtered instead of letting them play unfiltered. */
    var silenceUnfilterable: Boolean
        get() = p.getBoolean("silence_unfilterable", true)
        set(v) = p.edit().putBoolean("silence_unfilterable", v).apply()

    /** Screen blur: cover women (whole body; people the model cannot tell apart are covered too). */
    var blurWomen: Boolean
        get() = p.getBoolean("blur_women", false)
        set(v) = p.edit().putBoolean("blur_women", v).apply()

    /** Screen blur: cover nudity / immodest images of anyone. */
    var blurNudity: Boolean
        get() = p.getBoolean("blur_nudity", false)
        set(v) = p.edit().putBoolean("blur_nudity", v).apply()

    /** When the blur cannot keep up or its models fail: true = cover the whole screen, false = show it with a warning. */
    var blurFailCover: Boolean
        get() = p.getBoolean("blur_fail_cover", true)
        set(v) = p.edit().putBoolean("blur_fail_cover", v).apply()

    /**
     * Screen blur: how sure the model must be that a person is a man before leaving him uncovered.
     * 0 strict (99.9%, the default), 1 balanced (99%), 2 relaxed (98%). eval/results/blur_tiles.md.
     */
    var blurStrictness: Int
        get() = p.getInt("blur_strictness", 0).coerceIn(0, 2)
        set(v) = p.edit().putInt("blur_strictness", v.coerceIn(0, 2)).apply()

    /** The classifier threshold for [blurStrictness]. */
    val blurMaleClear: Float get() = MALE_CLEAR[blurStrictness]

    val blurOn: Boolean get() = blurWomen || blurNudity

    /**
     * Live filter in stereo (left and right kept apart). Off by default (owner's decision, 0.2.10): mono runs the model
     * once per hop instead of twice, so about half the battery, and keeps up on more phones; speech is almost always
     * centred. Even with stereo chosen, a phone too slow for it switches to mono by itself ([audioMono]).
     */
    var audioStereo: Boolean
        get() = p.getBoolean("audio_stereo", false)
        set(v) = p.edit().putBoolean("audio_stereo", v).apply()

    /**
     * When Android ends filtering (the capture is stopped or dies, not the user's Stop), keep the other apps' original
     * sound muted until the user starts again or taps Stop, instead of letting it play unfiltered. On by default
     * (owner's decision, 0.2.10). Needs the one-time setup (DUMP): without it nothing can be muted.
     */
    var holdSilence: Boolean
        get() = p.getBoolean("hold_silence", true)
        set(v) = p.edit().putBoolean("hold_silence", v).apply()

    /**
     * This phone needed mono to filter live sound in time (set by FilterService), so the next start begins in
     * mono instead of cutting again. Forgotten after a week or an app update: the phone may only have been hot
     * or busy that day, and an update may bring a faster model, so stereo gets another try.
     */
    var audioMono: Boolean
        get() = p.getInt("audio_mono_version", -1) == BuildConfig.VERSION_CODE &&
            System.currentTimeMillis() < p.getLong("audio_mono_until", 0)
        set(v) = p.edit().putInt("audio_mono_version", if (v) BuildConfig.VERSION_CODE else -1)
            .putLong("audio_mono_until", if (v) System.currentTimeMillis() + 7 * 24 * 3600 * 1000L else 0).apply()

    companion object {
        val MALE_CLEAR = floatArrayOf(0.999f, 0.99f, 0.98f)
    }
}
