package org.waaiya.app

import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

/*
 * Protection that survives a weak moment, without Android: the rules (what weakens), the waiting period that a reboot
 * or a clock change cannot shorten, and the PIN. Protection.kt holds the Android side (preferences, alarms,
 * notifications). The same rules are in ui/lib/src/protection_core.dart for the desktop.
 */

/** Wall clock (display only), a monotonic clock that keeps counting in deep sleep, and the boot number (-1: unknown). */
interface ProtectionClock {
    fun wallMs(): Long
    fun elapsedMs(): Long
    fun bootCount(): Int
}

/** A small private key-value file. */
interface ProtectionStore {
    fun get(key: String): String?
    fun put(key: String, value: String?)
}

object ProtectionRules {
    /** The waiting periods offered, in minutes (0: none). */
    val DELAYS = listOf(0, 1, 5, 15, 30, 60, 240, 1440)

    /** After the waiting period, the change must be confirmed within this time, else it lapses. */
    const val CONFIRM_MS = 15 * 60_000L

    const val TRIES = 5
    const val LOCK_MS = 30_000L
    const val ITERATIONS = 120_000

    private val ON_TO_OFF = setOf("blur_on", "blur_women", "blur_nudity", "blur_fail_cover", "silence_unfilterable", "hold_silence",
        "mute_women_singing")
    private val APPS = setOf("filter_off_apps", "blur_off_apps")

    /** The settings a pending request may hold (every one that can weaken protection). */
    val KEYS = ON_TO_OFF + APPS + setOf("keep_singing", "blur_strictness", "gender", "protect_delay_minutes")

    fun csv(s: String?): Set<String> = s.orEmpty().split(',').map { it.trim() }.filter { it.isNotEmpty() }.toSet()

    /**
     * Does changing [key] from [old] to [new] weaken protection? Unknown keys and values of the wrong type do not
     * (the setting is then refused for its type anyway). Prayer settings, language, stereo, removing apps from the
     * off lists, notes and hand covers never weaken.
     */
    fun isWeakening(key: String, old: Any?, new: Any?): Boolean = normalize(key, new) != null && when (key) {
        in ON_TO_OFF -> old == true && new == false
        "keep_singing" -> old != true && new == true
        "blur_strictness" -> new is Int && old is Int && new > old
        in APPS -> new is String && (csv(new) - csv(old as? String)).isNotEmpty()
        // the first answer (onboarding) is not a change
        "gender" -> new is String && old is String && old.isNotEmpty() && new != old
        "protect_delay_minutes" -> new is Int && old is Int && new < old
        else -> false
    }

    /** What a change needs: the PIN, the waiting period, both or none. */
    data class Gate(val pin: Boolean, val wait: Boolean) {
        val free get() = !pin && !wait
    }

    fun gate(key: String, old: Any?, new: Any?, pinSet: Boolean, delayMinutes: Int): Gate {
        val weak = isWeakening(key, old, new)
        // any change of the waiting period needs the PIN (raising it too: it is the parent's choice)
        val pin = pinSet && (weak || (key == "protect_delay_minutes" && old != new))
        return Gate(pin, weak && delayMinutes > 0)
    }

    fun stopGate(pinSet: Boolean, delayMinutes: Int) = Gate(pinSet, delayMinutes > 0)

    /** The value with its type checked, or null when [key] cannot be held or the value is wrong. */
    fun normalize(key: String, value: Any?): Any? = when (key) {
        in ON_TO_OFF, "keep_singing" -> value as? Boolean
        "blur_strictness" -> (value as? Number)?.toInt()?.takeIf { it in 0..2 && value !is Double }
        in APPS -> (value as? String)?.let { csv(it).sorted().joinToString(",") }
        "gender" -> (value as? String)?.takeIf { it in listOf("", "man", "woman") }
        "protect_delay_minutes" -> (value as? Number)?.toInt()?.takeIf { it in 0..1440 && value !is Double }
        else -> null
    }

    fun pinValid(pin: String?): Boolean = pin != null && pin.length in 4..8 && pin.all { it in '0'..'9' }

    /** Lockout after [n] wrong tries in a row: 30 s after 5, doubled after each further 5; 0 between. */
    fun lockMs(n: Int): Long = if (n <= 0 || n % TRIES != 0) 0 else LOCK_MS shl (n / TRIES - 1).coerceAtMost(12)
}

/**
 * Time left on a monotonic clock that survives reboots and ignores the wall clock. [remainingMs] was left at the
 * checkpoint [anchorElapsed] of boot [boot]. In the same boot, the time since the anchor counts. After a reboot only
 * the time since this boot counts: the time between the last checkpoint and the shutdown, and the time powered off,
 * never shorten it. A clock that went back (elapsed below the anchor) is a reboot too.
 */
data class Countdown(val remainingMs: Long, val anchorElapsed: Long, val boot: Int) {
    fun remaining(c: ProtectionClock): Long {
        val now = c.elapsedMs()
        val sameBoot = c.bootCount() == boot && now >= anchorElapsed
        return remainingMs - if (sameBoot) now - anchorElapsed else now.coerceAtLeast(0)
    }

    fun checkpoint(c: ProtectionClock) = Countdown(remaining(c), c.elapsedMs(), c.bootCount())

    fun encode() = "$remainingMs,$anchorElapsed,$boot"

    companion object {
        fun start(ms: Long, c: ProtectionClock) = Countdown(ms, c.elapsedMs(), c.bootCount())

        fun decode(s: String?): Countdown? {
            val p = s?.split(',') ?: return null
            if (p.size != 3) return null
            return Countdown(p[0].toLongOrNull() ?: return null, p[1].toLongOrNull() ?: return null,
                p[2].toIntOrNull() ?: return null)
        }
    }
}

/** PBKDF2-HMAC-SHA256 with a random 16-byte salt, stored as "iterations:salt:hash" (hex). Never the digits. */
object ProtectionPin {
    fun hash(pin: String, salt: ByteArray, iterations: Int): ByteArray {
        val spec = PBEKeySpec(pin.toCharArray(), salt, iterations, 256)
        try {
            return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).encoded
        } finally {
            spec.clearPassword()
        }
    }

    fun record(pin: String, iterations: Int): String {
        val salt = ByteArray(16).also { SecureRandom().nextBytes(it) }
        return "$iterations:${hex(salt)}:${hex(hash(pin, salt, iterations))}"
    }

    fun matches(pin: String, record: String?): Boolean {
        val p = record?.split(':') ?: return false
        if (p.size != 3) return false
        val iterations = p[0].toIntOrNull() ?: return false
        return MessageDigest.isEqual(hash(pin, unhex(p[1]), iterations), unhex(p[2]))
    }

    fun hex(b: ByteArray) = b.joinToString("") { "%02x".format(it) }
    fun unhex(s: String) = ByteArray(s.length / 2) { s.substring(2 * it, 2 * it + 2).toInt(16).toByte() }
}

/**
 * The waiting period and the PIN. [delayMinutes] and [current] read the app's settings; the caller applies a change
 * when an [Outcome] carries [Outcome.apply]. One request waits at a time: a different one replaces it and waits the
 * full period again; the same one again does not restart it.
 */
class ProtectionCore(
    private val store: ProtectionStore,
    private val clock: ProtectionClock,
    private val delayMinutes: () -> Int,
    private val current: (String) -> Any?,
    private val iterations: Int = ProtectionRules.ITERATIONS,
) {
    /** The change to make now: a setting key or "stop" (PIN changes are made here). */
    data class Apply(val what: String, val value: Any?)

    data class Outcome(
        val status: String,
        val dueAt: Long? = null,
        val triesLeft: Int? = null,
        val lockedUntil: Long? = null,
        val apply: Apply? = null,
    ) {
        fun toMap(): Map<String, Any?> = buildMap {
            put("status", status)
            dueAt?.let { put("dueAt", it) }
            triesLeft?.let { put("triesLeft", it) }
            lockedUntil?.let { put("lockedUntil", it) }
        }
    }

    class Pending(val what: String, val value: Any?, val countdown: Countdown, val pinRecord: String?) {
        /** Waiting for the period to end (> 0), ready to confirm (in (-CONFIRM_MS, 0]), lapsed (below). */
        fun left(c: ProtectionClock) = countdown.remaining(c)
    }

    val pinSet: Boolean @Synchronized get() = store.get(K_PIN) != null

    // --- the guard ---

    /**
     * A setting change from a screen: null when allowed, else what it needs. An allowed change of a setting that has a
     * pending request drops that request (it was made about a value that is gone); the same change made again once
     * it is ready to confirm is the confirmation.
     */
    @Synchronized fun check(key: String, value: Any?): ProtectionRules.Gate? {
        val g = ProtectionRules.gate(key, current(key), value, pinSet, delayMinutes())
        val p = pending()
        if (g.free) {
            if (p != null && p.what == key) clearPending()
            return null
        }
        if (g.wait && p != null && p.what == key && p.value == ProtectionRules.normalize(key, value) && p.left(clock) <= 0) {
            clearPending()
            return null
        }
        return g
    }

    /** Stopping the filter from anywhere: null when allowed (also when a ready stop request is confirmed by it). */
    @Synchronized fun checkStop(): ProtectionRules.Gate? {
        val g = ProtectionRules.stopGate(pinSet, delayMinutes())
        if (g.free) return null
        val p = pending()
        if (g.wait && p != null && p.what == STOP && p.left(clock) <= 0) {
            clearPending()
            return null
        }
        return g
    }

    @Synchronized fun guarded(): Boolean = pinSet || delayMinutes() > 0

    /** [checkStop] without its side effect. */
    @Synchronized fun mayStop(): Boolean {
        val g = ProtectionRules.stopGate(pinSet, delayMinutes())
        if (g.free) return true
        val p = pending()
        return g.wait && p != null && p.what == STOP && p.left(clock) <= 0
    }

    // --- requests (protect.request / setPin / clearPin / cancel / confirm) ---

    /** [what]: a setting key or "stop". Throws IllegalArgumentException for a key or value that cannot be held. */
    @Synchronized fun request(what: String, rawValue: Any?, pin: String?): Outcome {
        val value = if (what == STOP) null else ProtectionRules.normalize(what, rawValue)
            ?: throw IllegalArgumentException("$what cannot take $rawValue")
        val g = if (what == STOP) ProtectionRules.stopGate(pinSet, delayMinutes())
        else ProtectionRules.gate(what, current(what), value, pinSet, delayMinutes())
        if (g.free) return Outcome(DONE, apply = Apply(what, value))
        val p = pending()
        if (p != null && p.what == what && p.value == value) {
            // the same request: never restarted; repeating it once ready confirms it
            return if (p.left(clock) > 0) Outcome(WAITING, dueAt = due(p)) else confirm()
        }
        if (g.pin) verify(pin)?.let { return it }
        if (!g.wait) return Outcome(DONE, apply = Apply(what, value))
        return startWait(what, value, null)
    }

    /** Sets the PIN (none yet: at once), or changes it (the old PIN, then the waiting period). */
    @Synchronized fun setPin(newPin: String?, oldPin: String?): Outcome {
        require(ProtectionRules.pinValid(newPin)) { "the PIN is 4 to 8 digits" }
        val record = ProtectionPin.record(newPin!!, iterations)
        if (!pinSet) {
            store.put(K_PIN, record)
            return Outcome(DONE)
        }
        verify(oldPin)?.let { return it }
        if (delayMinutes() > 0) return startWait(PIN_CHANGE, null, record)
        store.put(K_PIN, record)
        return Outcome(DONE)
    }

    @Synchronized fun clearPin(pin: String?): Outcome {
        if (!pinSet) return Outcome(DONE)
        verify(pin)?.let { return it }
        if (delayMinutes() > 0) return startWait(PIN_CLEAR, null, null)
        store.put(K_PIN, null)
        return Outcome(DONE)
    }

    /** Cancelling only keeps protection: never asks anything. */
    @Synchronized fun cancel() = clearPending()

    @Synchronized fun confirm(): Outcome {
        val p = pending() ?: return Outcome(NONE)
        if (p.left(clock) > 0) return Outcome(WAITING, dueAt = due(p))
        clearPending()
        return when (p.what) {
            PIN_CHANGE -> { store.put(K_PIN, p.pinRecord); Outcome(DONE) }
            PIN_CLEAR -> { store.put(K_PIN, null); Outcome(DONE) }
            else -> Outcome(DONE, apply = Apply(p.what, p.value))
        }
    }

    // --- the PIN and its lockout ---

    /** null when [pin] is right; else the outcome to report. Wrong tries count even with a mistyped format. */
    private fun verify(pin: String?): Outcome? {
        lockedUntil()?.let { return Outcome(LOCKED, lockedUntil = it) }
        if (pin.isNullOrEmpty()) return Outcome(PIN_NEEDED)
        if (ProtectionPin.matches(pin, store.get(K_PIN))) {
            store.put(K_FAILS, null)
            store.put(K_LOCK, null)
            return null
        }
        val fails = (store.get(K_FAILS)?.toIntOrNull() ?: 0) + 1
        store.put(K_FAILS, fails.toString())
        val lock = ProtectionRules.lockMs(fails)
        if (lock > 0) {
            store.put(K_LOCK, Countdown.start(lock, clock).encode())
            return Outcome(LOCKED, lockedUntil = clock.wallMs() + lock)
        }
        return Outcome(PIN_WRONG, triesLeft = ProtectionRules.TRIES - fails % ProtectionRules.TRIES)
    }

    /** Wall time the lockout ends, for display; null when not locked. */
    @Synchronized fun lockedUntil(): Long? {
        val left = Countdown.decode(store.get(K_LOCK))?.remaining(clock) ?: return null
        if (left <= 0) { store.put(K_LOCK, null); return null }
        return clock.wallMs() + left
    }

    // --- the pending request ---

    private fun startWait(what: String, value: Any?, pinRecord: String?): Outcome {
        val ms = delayMinutes() * 60_000L
        store.put(K_WHAT, what)
        store.put(K_VALUE, encodeValue(value))
        store.put(K_PIN_NEW, pinRecord)
        store.put(K_DUE, Countdown.start(ms, clock).encode())
        return Outcome(PENDING, dueAt = clock.wallMs() + ms)
    }

    /** The pending request; a lapsed one is dropped here. */
    @Synchronized fun pending(): Pending? {
        val what = store.get(K_WHAT) ?: return null
        val cd = Countdown.decode(store.get(K_DUE))
        val p = cd?.let { Pending(what, decodeValue(store.get(K_VALUE)), it, store.get(K_PIN_NEW)) }
        if (p == null || p.left(clock) <= -ProtectionRules.CONFIRM_MS) { clearPending(); return null }
        return p
    }

    private fun clearPending() { for (k in listOf(K_WHAT, K_VALUE, K_PIN_NEW, K_DUE)) store.put(k, null) }

    /** Wall time the wait of [p] ends, for display. */
    fun due(p: Pending) = clock.wallMs() + p.left(clock)

    /** Saves the time left now (at least every minute while pending, and at shutdown when Android says so). */
    @Synchronized fun checkpoint() {
        pending()?.let { store.put(K_DUE, it.countdown.checkpoint(clock).encode()) }
        Countdown.decode(store.get(K_LOCK))?.let { store.put(K_LOCK, it.checkpoint(clock).encode()) }
    }

    /** `features.protect` (docs/FEATURES_CONTRACT.md); times are wall-clock ms for display. */
    @Synchronized fun snapshot(): Map<String, Any?> {
        val p = pending()
        return mapOf(
            "pinSet" to pinSet,
            "delayMinutes" to delayMinutes(),
            "pending" to p?.let {
                val left = it.left(clock)
                mapOf(
                    "what" to it.what,
                    "value" to it.value,  // null for the PIN: the new PIN's hash stays here
                    "dueAt" to clock.wallMs() + left,
                    "confirmUntil" to clock.wallMs() + left + ProtectionRules.CONFIRM_MS,
                    "ready" to (left <= 0),
                )
            },
            "lockedUntil" to lockedUntil(),
        )
    }

    companion object {
        const val STOP = "stop"
        const val PIN_CHANGE = "pin_change"
        const val PIN_CLEAR = "pin_clear"

        const val DONE = "done"
        const val PENDING = "pending"
        const val WAITING = "waiting"
        const val NONE = "none"
        const val PIN_NEEDED = "pin_needed"
        const val PIN_WRONG = "pin_wrong"
        const val LOCKED = "locked"

        private const val K_PIN = "pin"
        private const val K_FAILS = "pin_fails"
        private const val K_LOCK = "pin_lock"
        private const val K_WHAT = "pending_what"
        private const val K_VALUE = "pending_value"
        private const val K_PIN_NEW = "pending_pin"
        private const val K_DUE = "pending_due"

        /** b:true, i:3, s:text, n: (null). */
        fun encodeValue(v: Any?): String = when (v) {
            null -> "n:"
            is Boolean -> "b:$v"
            is Int -> "i:$v"
            else -> "s:$v"
        }

        fun decodeValue(s: String?): Any? = when {
            s == null || s.startsWith("n:") -> null
            s.startsWith("b:") -> s.substring(2) == "true"
            s.startsWith("i:") -> s.substring(2).toIntOrNull()
            else -> s.removePrefix("s:")
        }
    }
}
