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
}
