package org.waaiya.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

/** The release file (update.json) as AppUpdate reads it: only waaiya.mssid.org over https, well-formed hashes. */
class AppUpdateTest {
    private val a = "a".repeat(64)
    private val b = "b".repeat(64)
    private val p = "c".repeat(64)
    private fun asset(url: String, sha: String = b, size: Long = 1000) = """{"url":"$url","sha256":"$sha","size":$size}"""
    private val site = "https://waaiya.mssid.org/downloads/"

    private fun manifest(apks: String, patches: String = "[]", schema: Int = 1) =
        """{"schema":$schema,"android":{"versionCode":17,"versionName":"0.2.14","apks":{$apks},"patches":$patches,
           "known":{"${a.uppercase()}":"universal"}},"notes":{"en":"${"x".repeat(3000)}","ar":"ملاحظة"}}"""

    @Test
    fun readsAWellFormedRelease() {
        val r = AppUpdate.parse(manifest(""""universal":${asset(site + "u.apk")}""",
            """[{"from":"$a","variant":"universal","url":"${site}patches/p.zst","sha256":"$p","size":10}]"""))
        assertEquals(17L, r.versionCode)
        assertEquals("0.2.14", r.versionName)
        assertEquals(setOf("universal"), r.apks.keys)
        assertEquals(1, r.patches.size)
        assertEquals("universal", r.known[a])  // hashes are compared in lower case
        assertEquals(2000, r.notes["en"]!!.length)  // long notes are cut
        assertEquals("ملاحظة", r.notes["ar"])
    }

    @Test
    fun dropsFilesFromAnywhereElse() {
        val r = AppUpdate.parse(manifest(
            """"universal":${asset(site + "u.apk")},"arm64-v8a":${asset("http://waaiya.mssid.org/a.apk")},
               "armeabi-v7a":${asset("https://evil.example/a.apk")},"x":${asset("https://waaiya.mssid.org.evil.example/a.apk")},
               "y":${asset(site + "y.apk", sha = "nothex")},"z":${asset(site + "z.apk", size = 0)}""",
            """[{"from":"$a","variant":"universal","url":"https://evil.example/p.zst","sha256":"$p","size":10},
                {"from":"$a","variant":"arm64-v8a","url":"${site}p.zst","sha256":"$p","size":10},
                {"from":"short","variant":"universal","url":"${site}p.zst","sha256":"$p","size":10}]"""))
        assertEquals(setOf("universal"), r.apks.keys)
        assertTrue("no patch survives: foreign host, unknown variant, bad from", r.patches.isEmpty())
    }

    @Test
    fun refusesOldSchemaOrNoApk() {
        for (text in listOf(manifest(""""universal":${asset(site + "u.apk")}""", schema = 0),
                            manifest(""""universal":${asset("https://evil.example/u.apk")}"""), "not json")) {
            try { AppUpdate.parse(text); fail("accepted: ${text.take(40)}") } catch (_: Exception) {}
        }
    }
}
