package org.islamicmute.app.adb

import java.io.EOFException
import java.io.IOException
import java.net.SocketTimeoutException
import javax.crypto.AEADBadTagException
import javax.net.ssl.SSLSocket

/**
 * "Pair device with pairing code" from the device side (adb pair, pairing_connection.cpp):
 * TLS 1.3 to the pairing port, password = code + 64 bytes exported from the TLS session, SPAKE2 messages, then
 * each side sends its PeerInfo encrypted with the SPAKE2 key. Ours carries [AdbKey.publicKeyLine]; adbd stores it
 * as a paired key. A wrong code shows up as a PeerInfo that does not decrypt, or as adbd closing the connection.
 *
 * [exporter] reads the TLS keying material (android.net.ssl.SSLSockets on Android 12+, Conscrypt's own method on
 * Android 11); passed in so that this class stays plain JVM code.
 */
class AdbPairingClient(
    private val key: AdbKey,
    private val exporter: (SSLSocket, String, Int) -> ByteArray,
) {
    class WrongCodeException : IOException("the pairing code was not accepted")

    /** Pairs with the adbd pairing server on [host]:[port]. Throws [WrongCodeException] or another IOException. */
    fun pair(host: String, port: Int, code: String, timeoutMs: Int = 15_000) {
        AdbTls(key).connect(host, port, timeoutMs).use { ssl ->
            val material = exporter(ssl, PairingWire.EXPORT_LABEL, PairingWire.EXPORT_SIZE)
            check(material.size == PairingWire.EXPORT_SIZE) { "TLS exporter gave ${material.size} bytes" }
            val spake = Spake2.adbClient(code.toByteArray(Charsets.US_ASCII) + material)
            val out = ssl.outputStream
            val input = ssl.inputStream
            out.write(PairingWire.packet(PairingWire.TYPE_SPAKE2_MSG, spake.message)); out.flush()
            val (t1, theirMsg) = PairingWire.read(input)
            if (t1 != PairingWire.TYPE_SPAKE2_MSG) throw ProtocolException("expected the SPAKE2 message, got type $t1")
            val cipher = try { PairingCipher(spake.processMessage(theirMsg)) }
                         catch (e: IllegalArgumentException) { throw WrongCodeException() }  // not a point
            out.write(PairingWire.packet(PairingWire.TYPE_PEER_INFO, cipher.encrypt(PairingWire.peerInfo(key.publicKeyLine()))))
            out.flush()
            val theirInfo = try {
                val (t2, sealed) = PairingWire.read(input)
                if (t2 != PairingWire.TYPE_PEER_INFO) throw ProtocolException("expected PeerInfo, got type $t2")
                cipher.decrypt(sealed)
            } catch (e: AEADBadTagException) { throw WrongCodeException() }
              catch (e: EOFException) { throw WrongCodeException() }
              catch (e: SocketTimeoutException) { throw e }
              catch (e: javax.net.ssl.SSLException) { throw WrongCodeException() }  // reset by adbd after a bad PeerInfo
            if (theirInfo.size != PairingWire.PEER_INFO_SIZE) throw ProtocolException("PeerInfo size ${theirInfo.size}")
        }
    }
}
