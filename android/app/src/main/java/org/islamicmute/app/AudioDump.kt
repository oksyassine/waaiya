package org.islamicmute.app

/** One player of another app, as listed by the system's audio dumps. */
data class AudioSession(
    val id: Int,
    val uid: Int,
    /** Java-style name: USAGE_MEDIA, USAGE_GAME, ... */
    val usage: String,
    /** False when the app does not allow its sound to be captured (so it cannot be filtered). */
    val capturable: Boolean,
    /** Playing right now. */
    val active: Boolean,
)

/**
 * Finds the audio sessions of all apps in the text of `dumpsys media.audio_policy` (preferred) or `dumpsys audio`.
 *
 * Why two: `dumpsys audio` prints the session id only from Android 12, and its flags miss apps that refuse capture
 * in their manifest. The audio policy dump has the session id, the uid, the usage and the real flags on every
 * version this app supports (Android 10+), in two layouts:
 *
 *     Android 10-13:  - Port Id: 62 Session Id: 185 UID: 10157     (attributes and state on the next lines)
 *     Android 14+:    3. Port ID: 31; Session ID: 185; uid 10157; State: Inactive
 *
 * No Android classes: tested on the JVM against dumps saved from emulators (AudioDumpTest).
 */
object AudioDump {
    /** AudioAttributes.FLAG_NO_MEDIA_PROJECTION, the same bit in the native flags. */
    private const val FLAG_NO_MEDIA_PROJECTION = 0x400

    private val clientRe = Regex("""Port I[dD]:\s*(\d+)\W+Session I[dD]:\s*(\d+)\W+uid:?\s*(\d+)""", RegexOption.IGNORE_CASE)
    private val usageRe = Regex("""Usage:\s*(?:AUDIO_)?(USAGE_\w+)""")
    private val flagsRe = Regex("""Flags:\s*0x([0-9A-Fa-f]+)""")
    private val stateRe = Regex("""State:\s*(Active|Inactive)""")
    private val sourceRe = Regex("""Source:\s*(\S+)""")
    /** Attribute "Source" values of a playback client; anything else is a recording client. */
    private val playbackSources = setOf("AUDIO_SOURCE_INVALID", "AUDIO_SOURCE_DEFAULT", "-1", "0")

    /** `dumpsys media.audio_policy`: every playback client of every output. */
    fun parsePolicy(text: String): List<AudioSession> {
        val lines = text.lines()
        val out = LinkedHashMap<Int, AudioSession>()
        var recording = false
        var i = 0
        while (i < lines.size) {
            val line = lines[i]
            // section titles: "AudioTrack clients", "AudioRecord Clients"; a client line never holds them
            if (!line.contains("Port I", ignoreCase = false)) {
                if (line.contains("AudioRecord", ignoreCase = true)) recording = true
                else if (line.contains("AudioTrack", ignoreCase = true)) recording = false
            }
            val m = clientRe.find(line)
            if (m == null) { i++; continue }
            // this client's details: up to the next client or the next section, at most a few lines
            var end = i + 1
            while (end < lines.size && end < i + 8 && clientRe.find(lines[end]) == null &&
                !lines[end].contains("clients", ignoreCase = true)) end++
            val block = lines.subList(i, end).joinToString("\n")
            i = end
            val source = sourceRe.find(block)?.groupValues?.get(1)?.trimEnd(',', ';')
            if (recording || (source != null && source !in playbackSources)) continue
            val id = m.groupValues[2].toIntOrNull() ?: continue
            val uid = m.groupValues[3].toIntOrNull() ?: continue
            val usage = usageRe.find(block)?.groupValues?.get(1) ?: "USAGE_UNKNOWN"
            val flags = flagsRe.find(block)?.groupValues?.get(1)?.toIntOrNull(16) ?: 0
            val active = stateRe.find(block)?.groupValues?.get(1) == "Active"
            val s = AudioSession(id, uid, usage, flags and FLAG_NO_MEDIA_PROJECTION == 0, active)
            // the same client is listed again under "active clients": keep one, active if either says so
            val old = out[id]
            out[id] = if (old == null) s else old.copy(active = old.active || active)
        }
        return out.values.toList()
    }

    private val uidRe = Regex("""u/pid:(\d+)/""")
    private val sessionRe = Regex("""session(?:Id)?[:=]\s*(\d+)""")
    private val javaUsageRe = Regex("""usage=(USAGE_\w+)""")
    private val javaFlagsRe = Regex("""flags=0x([0-9A-Fa-f]+)""")

    /** `dumpsys audio` (AudioPlaybackConfiguration lines): has session ids on Android 12+ only. */
    fun parseService(text: String): List<AudioSession> {
        val out = LinkedHashMap<Int, AudioSession>()
        for (line in text.lineSequence()) {
            if (!line.contains("AudioPlaybackConfiguration") && !line.contains("piid:")) continue
            if (line.contains("state:released")) continue
            if (!line.contains("state:")) continue  // the event log below the list repeats old players
            val uid = uidRe.find(line)?.groupValues?.get(1)?.toIntOrNull() ?: continue
            val id = sessionRe.find(line)?.groupValues?.get(1)?.toIntOrNull() ?: continue
            val usage = javaUsageRe.find(line)?.groupValues?.get(1) ?: "USAGE_UNKNOWN"
            val flags = javaFlagsRe.find(line)?.groupValues?.get(1)?.toIntOrNull(16) ?: 0
            out[id] = AudioSession(id, uid, usage, flags and FLAG_NO_MEDIA_PROJECTION == 0, line.contains("state:started"))
        }
        return out.values.toList()
    }

    private val filterableUsages = setOf("USAGE_MEDIA", "USAGE_GAME", "USAGE_UNKNOWN")

    /** The app's sound reaches the filter (we play the filtered copy, so the original is muted). */
    fun filterable(s: AudioSession): Boolean = s.capturable && s.usage in filterableUsages

    /**
     * Sound of an app that refuses capture: it cannot be filtered, only silenced or left as it is. The same
     * usages as [filterable] (sound with no declared usage may be music): what would be filtered is never
     * let through unfiltered just because the app refuses.
     */
    fun blocked(s: AudioSession): Boolean = !s.capturable && s.usage in filterableUsages

    /**
     * Both lists as one. The policy dump knows the real "refuses capture" flag; `dumpsys audio` is the list
     * this app used before, kept so that a phone whose policy dump has a layout unknown here loses nothing.
     */
    fun merge(policy: List<AudioSession>, service: List<AudioSession>): List<AudioSession> {
        val out = LinkedHashMap<Int, AudioSession>()
        for (s in policy) out[s.id] = s
        for (s in service) {
            val p = out[s.id]
            out[s.id] = if (p == null) s else p.copy(active = p.active || s.active, capturable = p.capturable && s.capturable)
        }
        return out.values.toList()
    }
}
