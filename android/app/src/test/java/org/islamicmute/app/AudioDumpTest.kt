package org.islamicmute.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The session list is read from text that Android prints for developers, in a layout that changed between
 * versions. These tests run the parser on dumps saved from emulators (src/test/resources/dumps), taken while
 * Waaiya (uid 10222) was filtering and another app was playing.
 */
class AudioDumpTest {
    private fun dump(name: String): String =
        checkNotNull(javaClass.getResourceAsStream("/dumps/$name")) { "missing fixture $name" }.reader().readText()

    private fun List<AudioSession>.byUid(uid: Int) = filter { it.uid == uid }

    @Test fun api35Policy() {
        val all = AudioDump.parsePolicy(dump("api35_audio_policy.txt"))
        val player = all.byUid(10157).single()            // YouTube Music's player
        assertEquals(185, player.id)
        assertEquals("USAGE_MEDIA", player.usage)
        assertTrue(player.capturable)
        assertTrue(AudioDump.filterable(player))
        val ours = all.byUid(10222)
        assertEquals("only the output track, not the capture session", listOf(177), ours.map { it.id })
        assertFalse("Waaiya's own output refuses capture", ours.single().capturable)
        assertTrue(ours.single().active)
        assertNull("recording sessions are not players", all.find { it.id == 169 })
        assertEquals("each session once", all.size, all.map { it.id }.toSet().size)
    }

    @Test fun api35Service() {
        val all = AudioDump.parseService(dump("api35_audio.txt"))
        val player = all.byUid(10157).single()
        assertEquals(185, player.id)
        assertEquals("USAGE_MEDIA", player.usage)
        assertNotNull(all.find { it.id == 177 })
    }

    @Test fun api30Policy() {
        val all = AudioDump.parsePolicy(dump("api30_audio_policy.txt"))
        val media = all.filter { it.usage == "USAGE_MEDIA" && it.uid >= 10000 }
        assertTrue("another app's media session is found on Android 11", media.isNotEmpty())
        assertTrue(media.all { it.id > 0 })
        assertTrue("it is playing in this dump", media.any { it.active })
        assertEquals(all.size, all.map { it.id }.toSet().size)
    }

    @Test fun api30ServiceHasNoSessionIds() {
        // the reason the policy dump is read first: Android 10 and 11 do not print session ids here
        assertTrue(AudioDump.parseService(dump("api30_audio.txt")).isEmpty())
    }

    @Test fun olderLayout() {
        // Android 10-13 layout (ClientDescriptor::dump): one field per line
        val text = """
            |  - AudioTrack clients:
            |      Client 1:
            |      - Port Id: 62 Session Id: 185 UID: 10157
            |      - Format: 00000001 Sampling rate: 44100 Channels: 00000003
            |      - Attributes: { Content type: AUDIO_CONTENT_TYPE_MUSIC Usage: AUDIO_USAGE_MEDIA Source: -1 Flags: 0x800 Tags:  }
            |      - Preferred Device Id: 00000000
            |      - State: Active
            |      - Stream: 3 flags: 00000000
            |      Client 2:
            |      - Port Id: 70 Session Id: 201 UID: 10199
            |      - Format: 00000001 Sampling rate: 48000 Channels: 00000003
            |      - Attributes: { Content type: AUDIO_CONTENT_TYPE_MOVIE Usage: AUDIO_USAGE_MEDIA Source: -1 Flags: 0xc00 Tags:  }
            |      - Preferred Device Id: 00000000
            |      - State: Inactive
            |      - Stream: 3 flags: 00000000
            |  - AudioRecord clients:
            |      Client 1:
            |      - Port Id: 71 Session Id: 209 UID: 10222
            |      - Attributes: { Content type: AUDIO_CONTENT_TYPE_UNKNOWN Usage: AUDIO_USAGE_UNKNOWN Source: AUDIO_SOURCE_REMOTE_SUBMIX Flags: 0x0 Tags:  }
            |      - State: Active
        """.trimMargin()
        val all = AudioDump.parsePolicy(text)
        assertEquals(listOf(185, 201), all.map { it.id })
        assertTrue(all[0].active); assertTrue(all[0].capturable)
        assertFalse(all[1].active)
        assertFalse("flag 0x400: the app refuses capture", all[1].capturable)
        assertTrue(AudioDump.blocked(all[1])); assertFalse(AudioDump.filterable(all[1]))
    }

    @Test fun whatIsMuted() {
        fun s(usage: String, capturable: Boolean) = AudioSession(1, 10001, usage, capturable, true)
        assertTrue(AudioDump.filterable(s("USAGE_MEDIA", true)))
        assertTrue(AudioDump.filterable(s("USAGE_GAME", true)))
        assertTrue(AudioDump.filterable(s("USAGE_UNKNOWN", true)))
        // never touched: calls, alarms, ringtones, navigation, the screen reader
        for (u in listOf("USAGE_VOICE_COMMUNICATION", "USAGE_ALARM", "USAGE_NOTIFICATION_RINGTONE",
            "USAGE_ASSISTANCE_NAVIGATION_GUIDANCE", "USAGE_ASSISTANCE_ACCESSIBILITY", "USAGE_NOTIFICATION")) {
            assertFalse(u, AudioDump.filterable(s(u, true)))
            assertFalse(u, AudioDump.blocked(s(u, false)))
        }
        assertTrue(AudioDump.blocked(s("USAGE_MEDIA", false)))
        assertFalse("unknown sound that cannot be captured is left alone", AudioDump.blocked(s("USAGE_UNKNOWN", false)))
    }

    @Test fun garbage() {
        assertTrue(AudioDump.parsePolicy("").isEmpty())
        assertTrue(AudioDump.parsePolicy("Permission Denial: can't dump AudioPolicyService").isEmpty())
        assertTrue(AudioDump.parseService("no players here").isEmpty())
    }
}
