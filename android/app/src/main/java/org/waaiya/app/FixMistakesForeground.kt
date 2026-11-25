package org.waaiya.app

/**
 * Which app is on screen, read from `dumpsys window visible-apps` (the window manager's dump, which needs the DUMP
 * permission of the one-time setup), and whether the blur may leave its covers off for the apps the user chose
 * ([Settings.blurOffApps]). No Android classes: tested on the JVM against dumps saved from the API 30 and API 35
 * emulators (FixMistakesTest).
 *
 * The dump has, per display, the focused window and the focused app, then every visible app window:
 *
 *     mCurrentFocus=Window{a72e4f7 u0 NotificationShade}
 *     mFocusedApp=ActivityRecord{3f95ee1 u0 com.android.settings/.Settings t129}
 *     ...
 *       Window #0 Window{5f7c618 u0 com.android.settings/com.android.settings.Settings}:
 *       Window #0 Window{e8bab78 u0 Splash Screen com.android.settings}:
 *
 * Fail-closed: the covers stay unless the screen is known to show only chosen apps. Anything else (no reading, a
 * reading older than [STALE_MS], an unknown layout, the notification shade or another app's window focused, two
 * apps side by side, a window whose owner cannot be read) keeps the covers.
 */
object FixMistakesForeground {
    /** A reading older than this is not trusted: the covers come back. */
    const val STALE_MS = 1000L

    /** How often the window list is read while the option is in use (switching away restores covers within ~0.3 s). */
    const val POLL_MS = 250L

    /** What the window manager says is on screen. */
    data class Screen(
        /** Packages of the focused apps (one per display that has one). */
        val focusedApps: Set<String>,
        /** A focused window that belongs to no app or to a package other than a focused app (shade, dialogs). */
        val focusOther: Set<String>,
        /** Packages owning visible app windows. */
        val visibleApps: Set<String>,
        /** Visible app windows whose owner could not be read: their content is unknown. */
        val unknownWindows: Int,
    ) {
        /** The one app on screen, or null when it is not exactly one (none, several, or something unclear). */
        val app: String?
            get() = if (focusedApps.size == 1 && focusOther.isEmpty() && unknownWindows == 0 &&
                visibleApps.isNotEmpty() && visibleApps.all { it in focusedApps }) focusedApps.first() else null
    }

    private val packageRe = Regex("""^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$""")
    private val focusedAppRe = Regex("""mFocusedApp=(?:null|\S*\{[0-9a-f]+ u\d+ ([^\s/}]+)/)""")
    private val currentFocusRe = Regex("""mCurrentFocus=(null|Window\{[0-9a-f]+ u\d+ ([^}]*)\})""")
    private val windowRe = Regex("""^\s*Window #\d+ Window\{[0-9a-f]+ u\d+ ([^}]*)\}:""")

    /** The package a window title names ("pkg/Activity", "Splash Screen pkg"), or null. */
    fun windowPackage(title: String): String? {
        val t = title.trim().removePrefix("Splash Screen ").substringBefore('/').trim()
        return t.takeIf { packageRe.matches(it) }
    }

    /** Reads the dump; null when it holds no focused-app line at all (not the layout this code knows). */
    fun parse(text: String): Screen? {
        var sawFocusedApp = false
        val focused = LinkedHashSet<String>()
        val focusTitles = ArrayList<String>()
        val visible = LinkedHashSet<String>()
        var unknown = 0
        for (line in text.lineSequence()) {
            focusedAppRe.find(line)?.let { m ->
                sawFocusedApp = true
                m.groupValues[1].takeIf { it.isNotEmpty() }?.let { focused += it }
            }
            currentFocusRe.find(line)?.let { m -> if (m.groupValues[1] != "null") focusTitles += m.groupValues[2] }
            windowRe.find(line)?.let { m ->
                val pkg = windowPackage(m.groupValues[1])
                if (pkg == null) unknown++ else visible += pkg
            }
        }
        if (!sawFocusedApp) return null
        val other = LinkedHashSet<String>()
        for (t in focusTitles) {
            val pkg = windowPackage(t)
            if (pkg == null || pkg !in focused) other += pkg ?: t.trim()
        }
        return Screen(focused, other, visible, unknown)
    }

    /**
     * True only when the covers may be left off: a fresh reading ([ageMs] at most [STALE_MS]) shows exactly one app,
     * and the user chose it.
     */
    fun coversOff(screen: Screen?, ageMs: Long, offApps: Set<String>): Boolean {
        if (screen == null || offApps.isEmpty() || ageMs < 0 || ageMs > STALE_MS) return false
        val app = screen.app ?: return false
        return app in offApps
    }

    /** Where the foreground app can be read in this setup; null when it can. Codes for `features.fix.blurAppsReason`. */
    fun unavailableReason(dumpGranted: Boolean, helperMode: Boolean, helperRunning: Boolean = false): String? = when {
        dumpGranted -> null
        // helper mode: Waaiya's helper hands out the window list (ICoverService.dumpVisibleApps) while it runs;
        // when it is not running, the covers stay (the Filter page already says the helper is missing)
        helperMode -> if (helperRunning) null else "helper_mode"
        else -> "needs_setup"
    }
}
