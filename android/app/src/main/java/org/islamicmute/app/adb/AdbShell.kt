package org.islamicmute.app.adb

import java.io.BufferedInputStream
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.net.InetSocketAddress
import java.net.Socket
import javax.net.ssl.SSLException
import javax.net.ssl.SSLSocket

/**
 * A minimal adb client for adbd's TLS port (Wireless debugging): CNXN, the STLS upgrade, CNXN again inside TLS,
 * then one `shell:` stream whose output is collected until adbd closes it. Enough to run a few `cmd` lines as the
 * shell user, which is what the one-time setup needs.
 */
class AdbShell(private val key: AdbKey) {
    /** adbd did not accept our key: this phone has not paired with us (or forgot us, e.g. after "Revoke"). */
    class NotPairedException(cause: Throwable?) : IOException("not paired", cause)

    fun run(host: String, port: Int, command: String, timeoutMs: Int = 15_000): String {
        val plain = Socket()
        plain.connect(InetSocketAddress(host, port), timeoutMs)
        plain.soTimeout = timeoutMs
        plain.tcpNoDelay = true
        var ssl: SSLSocket? = null
        try {
            val rawIn = plain.getInputStream()  // unbuffered until TLS: nothing may be read past STLS
            AdbMessage(AdbMessage.A_CNXN, AdbMessage.A_VERSION, AdbMessage.MAX_PAYLOAD, "host::\u0000".toByteArray())
                .write(plain.getOutputStream())
            val first = AdbMessage.read(rawIn)
            if (first.command != AdbMessage.A_STLS) throw ProtocolException("expected STLS, got $first")
            AdbMessage(AdbMessage.A_STLS, AdbMessage.A_STLS_VERSION, 0).write(plain.getOutputStream())
            ssl = try { AdbTls(key).upgrade(plain, host, port) } catch (e: SSLException) { throw NotPairedException(e) }
            val input = BufferedInputStream(ssl.inputStream)
            val out = ssl.outputStream
            // TLS 1.3: adbd checks our certificate after our side of the handshake is done, so a refusal arrives
            // as the first read failing.
            val cnxn = try { AdbMessage.read(input) } catch (e: IOException) {
                if (e is java.net.SocketTimeoutException) throw e else throw NotPairedException(e)
            }
            if (cnxn.command != AdbMessage.A_CNXN) throw ProtocolException("expected CNXN, got $cnxn")
            return shell(input, out, command)
        } finally {
            runCatching { ssl?.close() }
            runCatching { plain.close() }
        }
    }

    private fun shell(input: java.io.InputStream, out: java.io.OutputStream, command: String): String {
        val localId = 1
        AdbMessage(AdbMessage.A_OPEN, localId, 0, "shell:$command\u0000".toByteArray(Charsets.UTF_8)).write(out)
        val result = ByteArrayOutputStream()
        var remoteId = 0
        while (true) {
            val m = AdbMessage.read(input)
            when (m.command) {
                AdbMessage.A_OKAY -> remoteId = m.arg0
                AdbMessage.A_WRTE -> {
                    result.write(m.payload)
                    remoteId = m.arg0
                    AdbMessage(AdbMessage.A_OKAY, localId, remoteId).write(out)
                }
                AdbMessage.A_CLSE -> {
                    if (m.arg0 != 0) AdbMessage(AdbMessage.A_CLSE, localId, m.arg0).write(out)
                    return result.toString(Charsets.UTF_8.name())
                }
                else -> {}  // e.g. a second CNXN: ignore
            }
        }
    }
}
