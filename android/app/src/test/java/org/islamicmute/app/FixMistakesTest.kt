package org.islamicmute.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.nio.file.Files

/**
 * Fix mistakes on the spot: the app lists, the "is a chosen app alone on screen" decision (fail-closed: anything
 * unclear keeps the covers), and the notes file. The window dumps were saved from the API 30 and API 35 emulators
 * (`dumpsys window visible-apps`, src/test/resources/dumps).
 */
class FixMistakesTest {
    private fun dump(name: String): String =
        checkNotNull(javaClass.getResourceAsStream("/dumps/$name")) { "missing fixture $name" }.reader().readText()

    private val launcher = "com.google.android.apps.nexuslauncher"
    private val settingsApp = "com.android.settings"

    // --- app lists ---

    @Test fun appListParsing() {
        assertEquals(emptySet<String>(), Settings.csv(""))
        assertEquals(emptySet<String>(), Settings.csv(null))
        assertEquals(setOf("com.a", "org.b"), Settings.csv(" com.a,,org.b , com.a "))
    }

    // --- the app on screen ---

    @Test fun api35LauncherAlone() {
        val s = checkNotNull(FixMistakesForeground.parse(dump("api35_window_visible_apps_home.txt")))
        assertEquals(launcher, s.app)
        assertTrue(FixMistakesForeground.coversOff(s, 100, setOf(launcher)))
        assertFalse("another app chosen", FixMistakesForeground.coversOff(s, 100, setOf(settingsApp)))
    }

    @Test fun api30SettingsAlone() {
        val s = checkNotNull(FixMistakesForeground.parse(dump("api30_window_visible_apps_settings.txt")))
        assertEquals(settingsApp, s.app)
        assertTrue(FixMistakesForeground.coversOff(s, 0, setOf(settingsApp, "com.other")))
        val home = checkNotNull(FixMistakesForeground.parse(dump("api30_window_visible_apps_home.txt")))
        assertEquals(launcher, home.app)
    }

    @Test fun notificationShadeOverTheAppKeepsCovers() {
        // Settings is the focused app, but the shade has the focus and is what the user sees
        val s = checkNotNull(FixMistakesForeground.parse(dump("api35_window_visible_apps_shade.txt")))
        assertEquals(setOf(settingsApp), s.focusedApps)
        assertTrue(s.focusOther.isNotEmpty())
        assertNull(s.app)
        assertFalse(FixMistakesForeground.coversOff(s, 0, setOf(settingsApp)))
    }

    @Test fun twoAppsOnScreenKeepCovers() {
        // an app starting: its splash window and the launcher are both visible
        val s = checkNotNull(FixMistakesForeground.parse(dump("api35_window_visible_apps_splash.txt")))
        assertEquals(setOf(settingsApp, launcher), s.visibleApps)
        assertNull(s.app)
        assertFalse(FixMistakesForeground.coversOff(s, 0, setOf(settingsApp)))
        assertFalse("even with both chosen", FixMistakesForeground.coversOff(s, 0, setOf(settingsApp, launcher)))
    }

    @Test fun splitScreenAndUnknownWindowsKeepCovers() {
        val split = """
            mCurrentFocus=Window{1 u0 com.a/com.a.Main}
            mFocusedApp=ActivityRecord{2 u0 com.a/.Main t5}
              Window #0 Window{3 u0 com.a/com.a.Main}:
              Window #1 Window{4 u0 com.b/com.b.Main}:
        """.trimIndent()
        assertFalse(FixMistakesForeground.coversOff(FixMistakesForeground.parse(split), 0, setOf("com.a")))
        assertFalse("two apps side by side keep the covers, even when both are chosen",
            FixMistakesForeground.coversOff(FixMistakesForeground.parse(split), 0, setOf("com.a", "com.b")))
        val popup = """
            mCurrentFocus=Window{1 u0 com.a/com.a.Main}
            mFocusedApp=ActivityRecord{2 u0 com.a/.Main t5}
              Window #0 Window{3 u0 com.a/com.a.Main}:
              Window #1 Window{5 u0 PopupWindow:1a2b}:
        """.trimIndent()
        val p = checkNotNull(FixMistakesForeground.parse(popup))
        assertEquals(1, p.unknownWindows)
        assertFalse("a window whose owner is unknown", FixMistakesForeground.coversOff(p, 0, setOf("com.a")))
        val twoDisplays = """
            mFocusedApp=ActivityRecord{2 u0 com.a/.Main t5}
            mFocusedApp=ActivityRecord{6 u0 com.b/.Main t6}
              Window #0 Window{3 u0 com.a/com.a.Main}:
        """.trimIndent()
        assertFalse(FixMistakesForeground.coversOff(FixMistakesForeground.parse(twoDisplays), 0, setOf("com.a")))
    }

    @Test fun staleUnknownOrEmptyKeepsCovers() {
        val s = FixMistakesForeground.parse(dump("api35_window_visible_apps_home.txt"))
        val off = setOf(launcher)
        assertTrue(FixMistakesForeground.coversOff(s, FixMistakesForeground.STALE_MS, off))
        assertFalse("stale reading", FixMistakesForeground.coversOff(s, FixMistakesForeground.STALE_MS + 1, off))
        assertFalse("never read", FixMistakesForeground.coversOff(null, 0, off))
        assertFalse("clock went back", FixMistakesForeground.coversOff(s, -5, off))
        assertFalse("no app chosen", FixMistakesForeground.coversOff(s, 0, emptySet()))
        assertNull("not the layout this code knows", FixMistakesForeground.parse("Permission Denial: can't dump"))
        assertNull(FixMistakesForeground.parse(""))
        val nothing = checkNotNull(FixMistakesForeground.parse("mCurrentFocus=null\nmFocusedApp=null\n"))
        assertNull("no app at all", nothing.app)
        assertFalse(FixMistakesForeground.coversOff(nothing, 0, off))
    }

    @Test fun windowTitles() {
        assertEquals("com.a.b", FixMistakesForeground.windowPackage("com.a.b/com.a.b.Main"))
        assertEquals("com.android.settings", FixMistakesForeground.windowPackage("Splash Screen com.android.settings"))
        assertNull(FixMistakesForeground.windowPackage("NotificationShade"))
        assertNull(FixMistakesForeground.windowPackage("PopupWindow:1a2b"))
        assertNull(FixMistakesForeground.windowPackage("StatusBar"))
    }

    @Test fun whereTheAppOnScreenCanBeRead() {
        assertNull(FixMistakesForeground.unavailableReason(dumpGranted = true, helperMode = false))
        assertEquals("helper_mode", FixMistakesForeground.unavailableReason(dumpGranted = false, helperMode = true))
        // helper mode with the helper running: it hands out the window list (ICoverService.dumpVisibleApps)
        assertNull(FixMistakesForeground.unavailableReason(dumpGranted = false, helperMode = true, helperRunning = true))
        assertEquals("needs_setup", FixMistakesForeground.unavailableReason(dumpGranted = false, helperMode = false))
    }

    // --- notes ---

    private fun note(i: Int, kind: String = "missed") =
        FixMistakesNotes.Note("2026-11-20 10:00:$i", kind, "screen", "App\twith tab\n($i)", "FILTERING", "ON", "m")

    @Test fun notesKeepTheNewest500() {
        var lines = emptyList<String>()
        for (i in 0 until 503) lines = FixMistakesNotes.append(lines, note(i))
        assertEquals(500, lines.size)
        assertTrue("oldest dropped", lines.first().startsWith("2026-11-20 10:00:3\t"))
        assertTrue(lines.last().startsWith("2026-11-20 10:00:502\t"))
        assertTrue("one line per note", lines.none { it.contains('\n') })
        assertEquals("tabs and line breaks become spaces", "App with tab (502)", FixMistakesNotes.parse(lines.last())!!.app)
    }

    @Test fun notesFile() {
        val dir = Files.createTempDirectory("fixnotes").toFile()
        try {
            assertEquals(0, FixMistakesNotes.count(dir))
            for (i in 0 until 5) FixMistakesNotes.add(dir, note(i, if (i % 2 == 0) "missed" else "wrong"), max = 3)
            assertEquals(3, FixMistakesNotes.count(dir))
            val text = FixMistakesNotes.text(FixMistakesNotes.read(dir), "header")
            assertTrue(text.startsWith("header"))
            assertTrue("newest first", text.indexOf("10:00:4") < text.indexOf("10:00:2"))
            assertFalse("dropped", text.contains("10:00:1 "))
            assertTrue(text.contains("hidden by mistake") && text.contains("missed something"))
            FixMistakesNotes.clear(dir)
            assertEquals(0, FixMistakesNotes.count(dir))
            assertNull("an unknown kind is not a note", FixMistakesNotes.parse("t\tother\tx\t\tf\tb\tm"))
        } finally {
            dir.deleteRecursively()
        }
    }

    // --- the actions on the filter's notification (Stop + at most two) ---

    @Test fun notificationActions() {
        assertEquals(listOf("missed", "wrong"), FixMistakesActions.kinds(blurRunning = false, handCovers = 0))
        assertEquals("no hand covers without the blur", listOf("missed", "wrong"), FixMistakesActions.kinds(false, 3))
        assertEquals(listOf("cover", "missed"), FixMistakesActions.kinds(blurRunning = true, handCovers = 0))
        assertEquals(listOf("remove", "missed"), FixMistakesActions.kinds(blurRunning = true, handCovers = 2))
        for (b in listOf(false, true)) for (n in 0..2) assertTrue(FixMistakesActions.kinds(b, n).size <= 2)
    }
}
