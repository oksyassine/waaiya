package org.islamicmute.app

/**
 * When "Reply to calls by SMS during prayer" sends an SMS, without Android classes (WorshipSmsRulesTest).
 * [WorshipSms] feeds it the phone's call state and sends.
 *
 * - Only inside a prayer window: from each prayer time for Settings.prayerSilentMinutes (the silence window,
 *   whether or not the silence itself is on).
 * - Only to a call that is still ringing after the chosen seconds: a call answered, rejected or ended before that
 *   gets nothing.
 * - Never to a hidden or unknown number, a short code (fewer than 7 digits) or a name instead of a number.
 * - At most one SMS per number per prayer window.
 * - Never while roaming (an SMS abroad can cost money).
 */
object WorshipSmsRules {
    /** The prayer window around [now]: the prayer time it started at (its key), or null outside every window. */
    fun window(now: Long, prayers: List<WorshipSchedule.PrayerTime>, minutes: Int): Long? =
        prayers.lastOrNull { it.at <= now && now < it.at + minutes * 60_000L }?.at

    /** The number in a comparable form (`+` and digits), or null when no SMS may go to it. */
    fun normalize(number: String?): String? {
        if (number.isNullOrBlank()) return null
        val t = number.trim()
        if (t.any { it.isLetter() }) return null                 // a name, "Private", "Unknown"
        val plus = t.startsWith("+") || t.startsWith("00")
        val digits = t.filter { it.isDigit() }.let { if (t.startsWith("00")) it.drop(2) else it }
        if (digits.length < 7) return null                       // short codes, "-1"/"-2" (hidden), service numbers
        if (t.any { !it.isDigit() && it !in "+ -(). /" }) return null
        return (if (plus) "+" else "") + digits
    }

    /** A ringing call that was seen: [number] as Android gave it, [since] when it started ringing (epoch ms). */
    data class Ringing(val number: String?, val since: Long)

    enum class Decision { SEND, TOO_EARLY, NOT_RINGING, OUTSIDE_PRAYER, NO_NUMBER, ALREADY_SENT, ROAMING, OFF }

    /**
     * @param ringing the call still ringing now (null: answered, rejected or ended).
     * @param sentInWindow numbers ([normalize]d) already sent an SMS in [window].
     */
    fun decide(
        enabled: Boolean,
        now: Long,
        ringing: Ringing?,
        delaySeconds: Int,
        window: Long?,
        sentInWindow: Set<String>,
        roaming: Boolean,
    ): Decision {
        if (!enabled) return Decision.OFF
        if (ringing == null) return Decision.NOT_RINGING
        if (now - ringing.since < delaySeconds * 1000L - 500) return Decision.TOO_EARLY
        if (window == null) return Decision.OUTSIDE_PRAYER
        val n = normalize(ringing.number) ?: return Decision.NO_NUMBER
        if (n in sentInWindow) return Decision.ALREADY_SENT
        if (roaming) return Decision.ROAMING
        return Decision.SEND
    }
}
