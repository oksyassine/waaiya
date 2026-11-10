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

    val blurOn: Boolean get() = blurWomen || blurNudity
}
