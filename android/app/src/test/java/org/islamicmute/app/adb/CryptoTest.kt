package org.islamicmute.app.adb

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import java.math.BigInteger
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.AEADBadTagException

private fun hex(s: String) = Spake2.hex(s)
private fun ByteArray.toHex() = joinToString("") { "%02x".format(it) }

class Ed25519Test {
    /** RFC 8032 7.1 TEST 1 and TEST 3: public key = clamp(SHA-512(secret)[0:32]) * B. */
    @Test fun rfc8032PublicKeys() {
        val vectors = mapOf(
            "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60" to
                "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
            "c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7" to
                "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
        )
        for ((secret, public) in vectors) {
            val h = MessageDigest.getInstance("SHA-512").digest(hex(secret)).copyOf(32)
            h[0] = (h[0].toInt() and 248).toByte()
            h[31] = ((h[31].toInt() and 127) or 64).toByte()
            val a = Ed25519.fromLittleEndian(h)
            assertEquals(public, Ed25519.BASE.times(a).encode().toHex())
        }
    }

    @Test fun groupLaws() {
        val b = Ed25519.BASE
        assertEquals(Ed25519.IDENTITY, b.times(Ed25519.L))
        assertEquals(b + b + b, b.times(BigInteger.valueOf(3)))
        assertEquals(Ed25519.IDENTITY, b - b)
        val p = b.times(BigInteger.valueOf(123456789))
        assertEquals(p, Ed25519.decode(p.encode()))
    }

    @Test fun rejectsBytesOffTheCurve() {
        // y = 2 has no x on edwards25519
        val bad = ByteArray(32).also { it[0] = 2 }
        try { Ed25519.decode(bad); fail() } catch (e: IllegalArgumentException) {}
    }
}

class Spake2Test {
    /** The M and N encodings decode to the decimal coordinates in BoringSSL's spake25519.cc comment. */
    @Test fun boringSslPoints() {
        val m = Spake2.M; val n = Spake2.N
        assertEquals(Ed25519.affine(
            BigInteger("31406539342727633121250288103050113562375374900226415211311216773867585644232"),
            BigInteger("21177308356423958466833845032658859666296341766942662650232962324899758529114")), m)
        assertEquals(Ed25519.affine(
            BigInteger("49918732221787544735331783592030787422991506689877079631459872391322455579424"),
            BigInteger("54629554431565467720832445949441049581317094546788069926228343916274969994000")), n)
    }

    @Test fun passwordScalarIsAMultipleOfEightAndEqualModL() {
        repeat(50) { i ->
            val h = Spake2.sha512(byteArrayOf(i.toByte()))
            val w = Spake2.passwordScalar(h)
            assertEquals(0, w.mod(BigInteger.valueOf(8)).toInt())
            assertEquals(Ed25519.fromLittleEndian(h).mod(Ed25519.L), w.mod(Ed25519.L))
            assertTrue(w.bitLength() <= 256)
        }
    }

    @Test fun privateScalarIsReducedThenTimesEight() {
        val r = ByteArray(64) { 0xff.toByte() }
        val s = Spake2.privateScalarFrom(r)
        assertEquals(Ed25519.fromLittleEndian(r).mod(Ed25519.L).shiftLeft(3), s)
        assertTrue(s.bitLength() <= 256)
    }

    @Test fun clientAndServerAgreeOnlyWithTheSamePassword() {
        val rnd = SecureRandom()
        val pw = "482913".toByteArray() + ByteArray(64) { it.toByte() }
        val c = Spake2.adbClient(pw, rnd)
        val s = Spake2.adbServer(pw, rnd)
        val k1 = c.processMessage(s.message)
        val k2 = s.processMessage(c.message)
        assertArrayEquals(k1, k2)
        assertEquals(64, k1.size)

        val wrong = Spake2.adbServer("482914".toByteArray() + ByteArray(64) { it.toByte() }, rnd)
        val c2 = Spake2.adbClient(pw, rnd)
        assertFalse(c2.processMessage(wrong.message).contentEquals(wrong.processMessage(c2.message)))
    }

    /**
     * Regression vector from this implementation with fixed scalars (no external SPAKE2 vector exists for BoringSSL's
     * variant; interoperability with adbd was checked on an Android 11 emulator, see docs/SETUP.md).
     */
    @Test fun fixedScalarsGiveFixedBytes() {
        val pw = "123456".toByteArray()
        val a = Spake2(true, Spake2.ADB_CLIENT_NAME, Spake2.ADB_SERVER_NAME, pw, Spake2.privateScalarFrom(ByteArray(64) { 1 }))
        val b = Spake2(false, Spake2.ADB_SERVER_NAME, Spake2.ADB_CLIENT_NAME, pw, Spake2.privateScalarFrom(ByteArray(64) { 2 }))
        val key = a.processMessage(b.message)
        assertArrayEquals(key, b.processMessage(a.message))
        assertEquals(REG_A_MSG, a.message.toHex())
        assertEquals(REG_B_MSG, b.message.toHex())
        assertEquals(REG_KEY, key.toHex())
    }

    private companion object {
        const val REG_A_MSG = "6ae9f08f3c163d197c9f64196370f7196d004e6ede36fa7b29212444a1cb47bd"
        const val REG_B_MSG = "45c576d23b71b1bd5a856431dc57d0888ac7b7da976182993e233a24d06024cd"
        const val REG_KEY =
            "eaa8d136254bd592ff278c04955806ce8c5b4008826306497a8acd31994129b6df7281084b827321243b4d450311af0d573155703c3e7e5695d0132b4c3d33be"
    }
}

class PairingCipherTest {
    /** RFC 5869 A.1 and A.3 (no salt, no info). */
    @Test fun hkdfRfc5869() {
        val ikm = ByteArray(22) { 0x0b }
        assertEquals("3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865",
            PairingCipher.hkdfSha256(ikm, hex("000102030405060708090a0b0c"), hex("f0f1f2f3f4f5f6f7f8f9"), 42).toHex())
        assertEquals("8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8",
            PairingCipher.hkdfSha256(ikm, ByteArray(0), ByteArray(0), 42).toHex())
    }

    @Test fun sealsWithACounterPerDirection() {
        val k = ByteArray(64) { 7 }
        val a = PairingCipher(k); val b = PairingCipher(k)
        val m1 = a.encrypt("one".toByteArray()); val m2 = a.encrypt("two".toByteArray())
        assertEquals(3 + PairingCipher.TAG_SIZE, m1.size)
        assertEquals("one", String(b.decrypt(m1)))
        assertEquals("two", String(b.decrypt(m2)))
        // same plaintext, next counter: different bytes
        assertNotEquals(a.encrypt("one".toByteArray()).toHex(), m1.toHex())
    }

    @Test fun nonceIsTheLittleEndianCounter() {
        // first message uses an all-zero nonce: AES-GCM of key HKDF(k) with nonce 0 must open it
        val k = ByteArray(64) { 3 }
        val sealed = PairingCipher(k).encrypt(ByteArray(5))
        val c = javax.crypto.Cipher.getInstance("AES/GCM/NoPadding")
        c.init(javax.crypto.Cipher.DECRYPT_MODE,
            javax.crypto.spec.SecretKeySpec(PairingCipher.hkdfSha256(k, ByteArray(0), PairingCipher.INFO, 16), "AES"),
            javax.crypto.spec.GCMParameterSpec(128, ByteArray(12)))
        assertArrayEquals(ByteArray(5), c.doFinal(sealed))
    }

    @Test fun wrongKeyFailsTheTag() {
        val sealed = PairingCipher(ByteArray(64) { 1 }).encrypt(ByteArray(8192))
        try { PairingCipher(ByteArray(64) { 2 }).decrypt(sealed); fail() } catch (e: AEADBadTagException) {}
    }
}
