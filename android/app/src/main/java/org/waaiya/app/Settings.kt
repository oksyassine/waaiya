package org.waaiya.app

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
     * Android 15+: show the text of notifications while filtering. Android hides it during any whole-screen capture,
     * and filtering is one. Set from the Quick Settings tile ([ScreenShareTileService]); [ScreenShareProtection]
     * turns the protection off only while Waaiya filters. Off by default: it also unprotects other screen shares
     * that happen at the same time.
     */
    var showNotificationText: Boolean
        get() = p.getBoolean("show_notification_text", false)
        set(v) = p.edit().putBoolean("show_notification_text", v).apply()

    /** This phone's capture refused the sound of a one-app share once: ask for the entire screen ([CaptureChoice]). */
    var oneAppRefused: Boolean
        get() = p.getBoolean("one_app_refused", false)
        set(v) = p.edit().putBoolean("one_app_refused", v).apply()

    /** Simple mode (TEST): filter without the one-time setup by muting media while filtering ([SimpleMode]). */
    var simpleMode: Boolean
        get() = p.getBoolean("simple_mode", false)
        set(v) = p.edit().putBoolean("simple_mode", v).apply()

    /** Simple mode's output channel: "alarm" or "notification". */
    var simpleChannel: String
        get() = p.getString("simple_channel", "alarm")?.takeIf { it == "notification" } ?: "alarm"
        set(v) = p.edit().putString("simple_channel", v).apply()

    /** The user saw what the notification-text tile changes (shown once, at the first turn-on). */
    var notificationTextExplained: Boolean
        get() = p.getBoolean("notification_text_explained", false)
        set(v) = p.edit().putBoolean("notification_text_explained", v).apply()

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

    // --- 0.2.13 features (docs/FEATURES_CONTRACT.md). Weakening changes pass Protection.checkSetting first. ---

    /** Apps the live filter leaves alone (comma-separated package names): their sound is neither captured nor muted. */
    var filterOffApps: Set<String>
        get() = csv(p.getString("filter_off_apps", ""))
        set(v) = p.edit().putString("filter_off_apps", v.sorted().joinToString(",")).apply()

    /** Apps the screen blur leaves alone while they are in the foreground (comma-separated package names). */
    var blurOffApps: Set<String>
        get() = csv(p.getString("blur_off_apps", ""))
        set(v) = p.edit().putString("blur_off_apps", v.sorted().joinToString(",")).apply()

    /** Keep singing voices (the voice_v1 model) instead of removing them with the instruments. Test, off by default. */
    var keepSinging: Boolean
        get() = p.getBoolean("keep_singing", false)
        set(v) = p.edit().putBoolean("keep_singing", v).apply()

    /** Ringer silent (Do Not Disturb) for [prayerSilentMinutes] from each prayer time. Off by default. */
    var prayerSilent: Boolean
        get() = p.getBoolean("prayer_silent", false)
        set(v) = p.edit().putBoolean("prayer_silent", v).apply()

    var prayerSilentMinutes: Int
        get() = p.getInt("prayer_silent_minutes", 20).coerceIn(5, 90)
        set(v) = p.edit().putInt("prayer_silent_minutes", v.coerceIn(5, 90)).apply()

    /** Media muted for [prayerAdhanMinutes] at each adhan time. Off by default. */
    var prayerAdhanMute: Boolean
        get() = p.getBoolean("prayer_adhan_mute", false)
        set(v) = p.edit().putBoolean("prayer_adhan_mute", v).apply()

    var prayerAdhanMinutes: Int
        get() = p.getInt("prayer_adhan_minutes", 5).coerceIn(1, 30)
        set(v) = p.edit().putInt("prayer_adhan_minutes", v.coerceIn(1, 30)).apply()

    /** A city id from the bundled list, or "custom:LAT,LON,TZID"; "" = not chosen (prayer features stay off). */
    var prayerPlace: String
        get() = p.getString("prayer_place", "") ?: ""
        set(v) = p.edit().putString("prayer_place", v).apply()

    /** Calculation method (index into WorshipTimes.METHODS) and Asr rule (0 standard, 1 Hanafi): the user's choice. */
    var prayerMethod: Int
        get() = p.getInt("prayer_method", 0).coerceIn(0, 15)
        set(v) = p.edit().putInt("prayer_method", v.coerceIn(0, 15)).apply()

    var prayerAsr: Int
        get() = p.getInt("prayer_asr", 0).coerceIn(0, 1)
        set(v) = p.edit().putInt("prayer_asr", v.coerceIn(0, 1)).apply()

    /**
     * Reply by SMS to a call that rings unanswered for [prayerSmsDelaySeconds] inside a prayer window (the
     * [prayerSilentMinutes] from each prayer time). Off by default; not in Play builds (WorshipSms).
     */
    var prayerSmsReply: Boolean
        get() = p.getBoolean("prayer_sms_reply", false)
        set(v) = p.edit().putBoolean("prayer_sms_reply", v).apply()

    var prayerSmsDelaySeconds: Int
        get() = p.getInt("prayer_sms_delay_seconds", 5).coerceIn(3, 60)
        set(v) = p.edit().putInt("prayer_sms_delay_seconds", v.coerceIn(3, 60)).apply()

    /** The SMS text; "" = the default text in the app's language. */
    var prayerSmsText: String
        get() = p.getString("prayer_sms_text", "") ?: ""
        set(v) = p.edit().putString("prayer_sms_text", v).apply()

    /** Waiting period, in minutes, before switching off or weakening takes effect. 0 = none (the default). */
    var protectDelayMinutes: Int
        get() = p.getInt("protect_delay_minutes", 0).coerceIn(0, 1440)
        set(v) = p.edit().putInt("protect_delay_minutes", v.coerceIn(0, 1440)).apply()

    companion object {
        val MALE_CLEAR = floatArrayOf(0.999f, 0.99f, 0.98f)

        fun csv(s: String?): Set<String> = s.orEmpty().split(',').map { it.trim() }.filter { it.isNotEmpty() }.toSet()
    }
}
