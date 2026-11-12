package org.islamicmute.app.adb

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.EOFException
import java.security.KeyFactory
import java.security.interfaces.RSAPublicKey
import java.security.spec.X509EncodedKeySpec
import java.util.Base64
import javax.security.auth.x500.X500Principal

class PairingWireTest {
    @Test fun headerIsVersionTypeBigEndianLength() {
        val p = PairingWire.packet(PairingWire.TYPE_PEER_INFO, ByteArray(0x1234 + 0x10))
        assertArrayEquals(byteArrayOf(1, 1, 0, 0, 0x12, 0x44), p.copyOf(6))
        val (type, payload) = PairingWire.read(ByteArrayInputStream(p))
        assertEquals(PairingWire.TYPE_PEER_INFO, type)
        assertEquals(0x1244, payload.size)
    }

    @Test fun closedConnectionIsEof() {
        try { PairingWire.read(ByteArrayInputStream(ByteArray(0))); fail() } catch (e: EOFException) {}
    }

    @Test fun rejectsBadHeaders() {
        for (bad in listOf(byteArrayOf(2, 0, 0, 0, 0, 1), byteArrayOf(1, 5, 0, 0, 0, 1), byteArrayOf(1, 0, 0, 1, 0, 1))) {
            try { PairingWire.read(ByteArrayInputStream(bad + ByteArray(32))); fail() } catch (e: ProtocolException) {}
        }
    }

    @Test fun peerInfoIsAlways8192Bytes() {
        val info = PairingWire.peerInfo("QUFB name")
        assertEquals(8192, info.size)
        assertEquals(0, info[0].toInt())
        assertEquals("QUFB name", String(info, 1, 9))
        assertEquals(0, info[10].toInt())
    }

    @Test fun exportLabelHasItsNul() {
        assertEquals(10, PairingWire.EXPORT_LABEL.toByteArray().size)
    }
}

class AdbMessageTest {
    @Test fun cnxnBytes() {
        val m = AdbMessage(AdbMessage.A_CNXN, AdbMessage.A_VERSION, AdbMessage.MAX_PAYLOAD, "host::\u0000".toByteArray())
        val b = m.toBytes()
        assertEquals(24 + 7, b.size)
        assertEquals("CNXN", String(b, 0, 4))
        // arg0 0x01000001 little-endian, magic = ~command
        assertArrayEquals(byteArrayOf(1, 0, 0, 1), b.copyOfRange(4, 8))
        assertArrayEquals(byteArrayOf(0, 0, 0x10, 0), b.copyOfRange(8, 12))
        assertArrayEquals(byteArrayOf(7, 0, 0, 0), b.copyOfRange(12, 16))
        val sum = "host::".sumOf { it.code }
        assertEquals(sum, java.nio.ByteBuffer.wrap(b, 16, 4).order(java.nio.ByteOrder.LITTLE_ENDIAN).int)
        assertEquals(AdbMessage.A_CNXN xor -1, java.nio.ByteBuffer.wrap(b, 20, 4).order(java.nio.ByteOrder.LITTLE_ENDIAN).int)
    }

    @Test fun roundTripAndStreamPosition() {
        val out = ByteArrayOutputStream()
        AdbMessage(AdbMessage.A_STLS, AdbMessage.A_STLS_VERSION, 0).write(out)
        out.write(0x16)  // the first byte of a TLS record must stay unread
        val input = ByteArrayInputStream(out.toByteArray())
        val m = AdbMessage.read(input)
        assertEquals("STLS", AdbMessage.name(m.command))
        assertEquals(AdbMessage.A_STLS_VERSION, m.arg0)
        assertEquals(0x16, input.read())
    }

    @Test fun badMagicIsRejected() {
        val b = AdbMessage(AdbMessage.A_OKAY, 1, 2).toBytes()
        b[20] = 0
        try { AdbMessage.read(ByteArrayInputStream(b)); fail() } catch (e: ProtocolException) {}
    }
}

class AdbKeyTest {
    private fun resource(name: String) = javaClass.classLoader!!.getResource("adbkey/$name")!!.readText()

    /** The same public key as `adb keygen` wrote it (fixture: a throwaway key's public half and its adbkey.pub). */
    @Test fun androidPublicKeyMatchesAdbKeygen() {
        val pem = resource("public.pem").lines().filter { !it.startsWith("-----") }.joinToString("")
        val pub = KeyFactory.getInstance("RSA").generatePublic(X509EncodedKeySpec(Base64.getDecoder().decode(pem))) as RSAPublicKey
        assertEquals(resource("adbkey.pub.b64").trim(), Base64.getEncoder().encodeToString(AdbKey.androidPublicKey(pub)))
    }

    @Test fun certificateIsValidAndSelfSigned() {
        val key = AdbKey.generate()
        val cert = key.certificate
        cert.verify(cert.publicKey)
        cert.checkValidity()
        assertEquals(X500Principal("CN=Waaiya"), cert.subjectX500Principal)
        assertEquals("SHA256withRSA", cert.sigAlgName)
        val line = key.publicKeyLine()
        assertTrue(line.endsWith(" " + AdbKey.NAME))
        assertEquals(524, Base64.getDecoder().decode(line.substringBefore(' ')).size)
    }

    @Test fun savedKeyLoadsBack() {
        val dir = kotlin.io.path.createTempDirectory("adbkey").toFile()
        try {
            val a = AdbKey.loadOrCreate(dir)
            val b = AdbKey.loadOrCreate(dir)
            assertArrayEquals(a.certificate.encoded, b.certificate.encoded)
            assertArrayEquals(a.privateKey.encoded, b.privateKey.encoded)
            assertNull(AdbKey.load(kotlin.io.path.createTempDirectory("empty").toFile()))
        } finally { dir.deleteRecursively() }
    }

    @Test fun derOid() {
        assertArrayEquals(byteArrayOf(6, 9, 0x2a, 0x86.toByte(), 0x48, 0x86.toByte(), 0xf7.toByte(), 0x0d, 1, 1, 11),
            Der.oid("1.2.840.113549.1.1.11"))
    }
}
