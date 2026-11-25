package org.waaiya.app

import java.io.File

/**
 * Local "wrong detection" notes: what the user marked as missed (the blur or the filter let something through) or as
 * hidden by mistake (covered or removed wrongly). One line per note in an app-private file, at most [MAX] (the oldest
 * are dropped). No screenshot, no sound, nothing sent: the user reads them, shares them himself, or deletes them.
 * No Android classes: tested on the JVM (FixMistakesTest).
 */
object FixMistakesNotes {
    const val MAX = 500
    const val FILE = "fix_notes.txt"
    val KINDS = setOf("missed", "wrong")

    /** One note. [app]: the app on screen when known, else "". [where]: `notification`, `filter`, `screen`. */
    data class Note(
        val time: String, val kind: String, val where: String, val app: String,
        val filter: String, val blur: String, val models: String,
    ) {
        /** Tab-separated, one line: field contents never hold a tab or a line break. */
        fun line(): String = listOf(time, kind, where, app, filter, blur, models).joinToString("\t") { clean(it) }
    }

    private fun clean(s: String) = s.replace(Regex("[\\t\\r\\n]+"), " ").trim()

    /** The lines after adding [note]: the newest last, at most [max]. */
    fun append(lines: List<String>, note: Note, max: Int = MAX): List<String> {
        val all = lines.filter { it.isNotBlank() } + note.line()
        return if (all.size > max) all.subList(all.size - max, all.size) else all
    }

    fun parse(line: String): Note? {
        val f = line.split('\t')
        if (f.size < 7 || f[1] !in KINDS) return null
        return Note(f[0], f[1], f[2], f[3], f[4], f[5], f[6])
    }

    /** The notes as plain text, newest first, for "Show / share" (English field names, like the diagnostics report). */
    fun text(lines: List<String>, header: String): String = buildString {
        appendLine(header)
        val notes = lines.mapNotNull { parse(it) }
        appendLine("${notes.size} note(s), newest first.")
        for (n in notes.asReversed()) {
            appendLine()
            appendLine("${n.time}  ${if (n.kind == "missed") "missed something" else "hidden by mistake"} (from ${n.where})")
            if (n.app.isNotEmpty()) appendLine("  app: ${n.app}")
            appendLine("  filter: ${n.filter}")
            appendLine("  blur: ${n.blur}")
            if (n.models.isNotEmpty()) appendLine("  models: ${n.models}")
        }
    }.trimEnd()

    // --- the file (java.io only) ---

    private val lock = Any()

    fun read(dir: File): List<String> = synchronized(lock) {
        runCatching { File(dir, FILE).readLines() }.getOrDefault(emptyList()).filter { it.isNotBlank() }
    }

    /** Adds [note]; returns the number of notes kept. Written to a temporary file first: never half a file. */
    fun add(dir: File, note: Note, max: Int = MAX): Int = synchronized(lock) {
        val lines = append(read(dir), note, max)
        val tmp = File(dir, "$FILE.tmp")
        tmp.writeText(lines.joinToString("\n", postfix = "\n"))
        if (!tmp.renameTo(File(dir, FILE))) { File(dir, FILE).writeText(tmp.readText()); tmp.delete() }
        lines.size
    }

    fun count(dir: File): Int = read(dir).size

    fun clear(dir: File) = synchronized(lock) { File(dir, FILE).delete(); Unit }
}
