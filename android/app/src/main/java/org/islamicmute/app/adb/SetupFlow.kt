package org.islamicmute.app.adb

/**
 * The decisions of the one-time setup over Wireless debugging, kept free of Android classes so they can be
 * unit-tested. The service feeds in what it sees (ports found by mDNS, the code typed by the user, the outcome
 * of each network step) and runs the [Action] it gets back, one at a time.
 *
 * Order: an app that paired before tries the connect port straight away (after a reboot nothing else is needed);
 * otherwise it waits for the code and the pairing port, pairs, then connects and runs the grants.
 */
class SetupFlow(pairedBefore: Boolean, private val clock: () -> Long = System::currentTimeMillis) {
    enum class Phase { WAITING, PAIRING, CONNECTING, DONE, FAILED }

    /** What the user should be told while waiting or after a failure. */
    enum class Note {
        NONE,
        /** Nothing found yet: turn on Wireless debugging and open "Pair device with pairing code". */
        OPEN_PAIRING_DIALOG,
        /** The pairing dialog is open (port known): type the code. */
        ENTER_CODE,
        /** A code came in but the pairing dialog is not visible to us yet: keep it open, we keep looking. */
        CODE_WAITING_FOR_DIALOG,
        WRONG_CODE,
        PAIRING_FAILED,
        /** Paired, waiting for adbd's connect port (Wireless debugging must stay on). */
        WAITING_FOR_CONNECT_PORT,
        /** Our key was refused: pair again. */
        NOT_PAIRED,
        CONNECT_FAILED,
        GRANT_FAILED,
        TIMEOUT,
    }

    sealed class Action {
        data class Pair(val port: Int, val code: String) : Action()
        data class Connect(val port: Int) : Action()
    }

    var phase = Phase.WAITING; private set
    var note = Note.OPEN_PAIRING_DIALOG; private set
    var paired = pairedBefore; private set
    var pairPort: Int? = null; private set
    var connectPort: Int? = null; private set
    private var pendingCode: String? = null
    private var pendingAt = 0L
    private var triedConnectPort: Int? = null

    private val busy get() = phase == Phase.PAIRING || phase == Phase.CONNECTING
    private val finished get() = phase == Phase.DONE || phase == Phase.FAILED

    fun pairingPortFound(port: Int): Action? {
        if (finished) return null
        pairPort = port
        if (busy) return null
        // A code typed before the pairing service was seen: use it only if the service showed up soon after (mDNS
        // can be a few seconds late). Settings makes a new code each time the pairing screen opens, so an older one
        // would only fail.
        pendingCode?.let { code ->
            pendingCode = null
            if (clock() - pendingAt <= PENDING_CODE_MS) return startPair(port, code)
        }
        note = Note.ENTER_CODE
        return null
    }

    fun pairingPortLost(port: Int) { if (pairPort == port) pairPort = null }

    fun connectPortFound(port: Int): Action? {
        if (finished) return null
        connectPort = port
        if (busy || !paired || triedConnectPort == port) return null
        return startConnect(port)
    }

    /** The user typed a code (and maybe the port shown under "IP address & Port"). */
    fun codeEntered(code: String, port: Int?): Action? {
        if (finished || busy) return null
        val p = port ?: pairPort
        if (p == null) { pendingCode = code; pendingAt = clock(); note = Note.CODE_WAITING_FOR_DIALOG; return null }
        return startPair(p, code)
    }

    fun pairSucceeded(): Action? {
        paired = true
        val c = connectPort
        if (c != null) return startConnect(c)
        phase = Phase.WAITING; note = Note.WAITING_FOR_CONNECT_PORT
        return null
    }

    fun pairFailed(wrongCode: Boolean) {
        phase = Phase.WAITING
        note = if (wrongCode) Note.WRONG_CODE else Note.PAIRING_FAILED
    }

    /** The grants ran and the caller checked them on the app's side. */
    fun grantsDone(verified: Boolean) {
        phase = if (verified) Phase.DONE else Phase.FAILED
        note = if (verified) Note.NONE else Note.GRANT_FAILED
    }

    /** adbd refused our key: forget "paired" and ask for a pairing code. */
    fun connectRefused() {
        paired = false
        phase = Phase.WAITING; note = Note.NOT_PAIRED
    }

    /** Network trouble on the connect port. Another port announcement (Wireless debugging restarted) retries. */
    fun connectFailed() {
        phase = Phase.WAITING; note = Note.CONNECT_FAILED
    }

    fun timedOut() {
        if (finished) return
        phase = Phase.FAILED; note = Note.TIMEOUT
    }

    companion object { const val PENDING_CODE_MS = 30_000L }

    private fun startPair(port: Int, code: String): Action {
        phase = Phase.PAIRING; note = Note.NONE
        return Action.Pair(port, code)
    }

    private fun startConnect(port: Int): Action {
        triedConnectPort = port
        phase = Phase.CONNECTING; note = Note.NONE
        return Action.Connect(port)
    }
}

/** What the user typed in the notification or the app: the 6-digit code, maybe followed by the port. */
object PairingInput {
    data class Parsed(val code: String, val port: Int?)

    /** Arabic-Indic (U+0660..) and Eastern Arabic-Indic (U+06F0..) digits become ASCII; everything else separates. */
    fun normaliseDigits(s: String): String = buildString {
        for (c in s) append(when (c) {
            in '٠'..'٩' -> '0' + (c - '٠')
            in '۰'..'۹' -> '0' + (c - '۰')
            else -> c
        })
    }

    /**
     * "482913", "482 913", "٤٨٢٩١٣" -> code. "482913 37123" or "482913 192.168.1.5:37123" -> code and port.
     * Null when no 6-digit code can be read.
     */
    fun parse(raw: String): Parsed? {
        val runs = Regex("[0-9]+").findAll(normaliseDigits(raw)).map { it.value }.toList()
        val codeIdx = runs.indexOfFirst { it.length == 6 }
        if (codeIdx < 0) {
            val joined = runs.joinToString("")
            return if (joined.length == 6) Parsed(joined, null) else null
        }
        val port = runs.drop(codeIdx + 1).lastOrNull()?.takeIf { it.length in 4..5 }?.toInt()?.takeIf { it in 1024..65535 }
        return Parsed(runs[codeIdx], port)
    }
}

/** mDNS results: adbd announces `adb-<serial>-<random>` under each service type, also from other phones nearby. */
object AdbServices {
    const val PAIRING_TYPE = "_adb-tls-pairing._tcp"
    const val CONNECT_TYPE = "_adb-tls-connect._tcp"

    data class Found(val name: String, val hostAddress: String?, val port: Int)

    /**
     * The announcement from this phone: its address is one of ours (or loopback). When the resolver gave no
     * address, it is accepted only if it is the only one: trying it on 127.0.0.1 fails harmlessly otherwise.
     */
    fun isOurs(found: Found, localAddresses: Set<String>, othersSeen: Int): Boolean {
        val host = found.hostAddress?.substringBefore('%')?.lowercase() ?: return othersSeen == 0
        if (host == "127.0.0.1" || host == "::1") return true
        return localAddresses.any { it.substringBefore('%').lowercase() == host }
    }
}
