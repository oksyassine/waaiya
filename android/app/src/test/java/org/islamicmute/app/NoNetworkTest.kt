package org.islamicmute.app

import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * Privacy claim, "nothing is sent": only the code that has to talk to a network may use network APIs. That is the
 * link screen (Links, LinkExport, the bundled yt-dlp) and the one-time setup, which talks to the phone's own
 * Wireless debugging (WirelessSetup, adb/), and the update check and download (AppUpdate: the release file and the
 * update itself, from waaiya.mssid.org only). The filter, the muter, the screen blur and the rest never do; a new
 * use there fails this test and has to be added here on purpose. (The Linux side: linux/test_no_network.sh.)
 */
class NoNetworkTest {
    private val allowed = setOf("LinkExport.kt", "Links.kt", "LinkActivity.kt", "WirelessSetup.kt", "AppUpdate.kt")
    private val network = listOf(
        "java.net.", "javax.net.", "HttpURLConnection", "HttpsURLConnection", "okhttp", "android.net.http",
        "Socket(", "DatagramSocket", "URL(", "WebView", "ConnectivityManager",
    )

    @Test
    fun filterAndBlurCodeUseNoNetwork() {
        val dir = File("src/main/java/org/islamicmute/app")
        assertTrue("sources not found from ${File(".").absolutePath}", dir.isDirectory)
        // the licence texts: a WebView on local files, with network loads blocked
        val licences = File(dir, "LicencesActivity.kt").readText()
        assertTrue("LicencesActivity's WebView must block network loads", licences.contains("blockNetworkLoads = true"))
        val sources = dir.listFiles { f -> f.isFile && f.name.endsWith(".kt") }!!
            .filter { it.name !in allowed && it.name != "LicencesActivity.kt" }
        assertTrue("too few sources (${sources.size}): wrong folder?", sources.size > 20)
        val hits = sources.flatMap { f ->
            f.readLines().mapIndexedNotNull { i, line ->
                val code = line.substringBefore("//")
                network.firstOrNull { code.contains(it) }?.let { "${f.name}:${i + 1}: $it" }
            }
        }
        assertTrue("network API outside the link screen and the setup:\n" + hits.joinToString("\n"), hits.isEmpty())
        for (f in listOf("FilterService.kt", "SessionMuter.kt", "ScreenBlur.kt", "Engine.kt", "Vision.kt")) {
            assertTrue("$f should exist (and be checked)", File(dir, f).isFile)
        }
    }
}
