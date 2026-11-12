package org.islamicmute.app.adb

import org.conscrypt.Conscrypt
import org.junit.Assume.assumeTrue
import org.junit.Test
import java.io.File
import java.security.Security

/**
 * Talks to a real adbd: skipped unless WAAIYA_ADB_PAIR ("host:port:code") and/or WAAIYA_ADB_CONNECT ("host:port")
 * are set. Used with an emulator: open Settings > Developer options > Wireless debugging > Pair device with pairing
 * code, `adb forward tcp:P tcp:P` for the pairing and connect ports, then run this class. The key is kept in
 * WAAIYA_ADB_KEYDIR (default build/adb-interop-key) so that a later connect-only run uses the paired key.
 */
class AdbInteropTest {
    private val keyDir = File(System.getenv("WAAIYA_ADB_KEYDIR") ?: "build/adb-interop-key")

    private fun conscrypt() {
        if (Security.getProvider("Conscrypt") == null) Security.insertProviderAt(Conscrypt.newProvider(), 1)
    }

    @Test fun pairThenConnect() {
        val pair = System.getenv("WAAIYA_ADB_PAIR")
        val connect = System.getenv("WAAIYA_ADB_CONNECT")
        assumeTrue(pair != null || connect != null)
        conscrypt()
        val key = AdbKey.loadOrCreate(keyDir)
        if (pair != null) {
            val (host, port, code) = pair.split(':')
            AdbPairingClient(key) { s, label, n -> Conscrypt.exportKeyingMaterial(s, label, null, n) }
                .pair(host, port.toInt(), code)
            println("paired with $host:$port")
        }
        if (connect != null) {
            val (host, port) = connect.split(':')
            val out = AdbShell(key).run(host, port.toInt(), "id; echo exit=\$?")
            println("shell output: $out")
            check(out.contains("uid=2000")) { "not the shell user: $out" }
        }
    }
}
