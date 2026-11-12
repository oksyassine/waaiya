package org.islamicmute.app.adb

import java.io.ByteArrayOutputStream
import java.io.File
import java.math.BigInteger
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.PrivateKey
import java.security.Signature
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.security.interfaces.RSAPublicKey
import java.security.spec.PKCS8EncodedKeySpec
import java.security.spec.RSAKeyGenParameterSpec
import java.util.Base64

/**
 * This app's adb identity: an RSA-2048 key pair and a self-signed certificate for it. Pairing sends the public key
 * to adbd (Settings then lists "Waaiya" under Paired devices); every later TLS connection presents the certificate,
 * and adbd lets in the key it remembers. Stored in the app's private no-backup directory, never sent anywhere else.
 */
class AdbKey(val privateKey: PrivateKey, val certificate: X509Certificate) {
    val publicKey: RSAPublicKey get() = certificate.publicKey as RSAPublicKey

    /** The line adb sends in PeerInfo and writes to adbkey.pub: base64 of the Android key struct, a space, a name. */
    fun publicKeyLine(name: String = NAME): String = Base64.getEncoder().encodeToString(androidPublicKey(publicKey)) + " " + name

    companion object {
        const val NAME = "waaiya@phone"
        private const val KEY_FILE = "adb_key.pk8"
        private const val CERT_FILE = "adb_key.crt"

        /** Loads the key from [dir], or makes and saves a new one (a second or two on a slow phone). */
        fun loadOrCreate(dir: File): AdbKey {
            load(dir)?.let { return it }
            val key = generate()
            dir.mkdirs()
            writeAtomically(File(dir, KEY_FILE), key.privateKey.encoded)
            writeAtomically(File(dir, CERT_FILE), key.certificate.encoded)
            return key
        }

        fun load(dir: File): AdbKey? = runCatching {
            val pk = KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(File(dir, KEY_FILE).readBytes()))
            val cert = CertificateFactory.getInstance("X.509")
                .generateCertificate(File(dir, CERT_FILE).inputStream()) as X509Certificate
            AdbKey(pk, cert)
        }.getOrNull()

        fun generate(): AdbKey {
            val gen = KeyPairGenerator.getInstance("RSA")
            gen.initialize(RSAKeyGenParameterSpec(2048, RSAKeyGenParameterSpec.F4))
            val pair = gen.generateKeyPair()
            return AdbKey(pair.private, selfSignedCertificate(pair.public as RSAPublicKey, pair.private))
        }

        private fun writeAtomically(f: File, data: ByteArray) {
            val tmp = File(f.parentFile, f.name + ".tmp")
            tmp.writeBytes(data)
            if (!tmp.renameTo(f)) { f.delete(); check(tmp.renameTo(f)) { "cannot save ${f.name}" } }
        }

        /**
         * libcrypto_utils' android_pubkey_encode (AOSP system/core, Apache-2.0): modulus size in 32-bit words,
         * n0inv = -1/n mod 2^32, the modulus and R^2 mod n (R = 2^2048) little-endian, then the exponent.
         * All fields little-endian; 524 bytes for RSA-2048.
         */
        fun androidPublicKey(key: RSAPublicKey): ByteArray {
            val n = key.modulus
            require(n.bitLength() in 2041..2048) { "adb keys are RSA-2048" }
            val r32 = BigInteger.ONE.shiftLeft(32)
            val n0inv = r32 - n.mod(r32).modInverse(r32)
            val rr = BigInteger.ONE.shiftLeft(2048).modPow(BigInteger.valueOf(2), n)
            val out = ByteArray(4 + 4 + 256 + 256 + 4)
            putLe32(out, 0, 64)
            putLe32(out, 4, n0inv.toLong().toInt())
            Ed25519.toLittleEndian(n, 256).copyInto(out, 8)
            Ed25519.toLittleEndian(rr, 256).copyInto(out, 264)
            putLe32(out, 520, key.publicExponent.toInt())
            return out
        }

        private fun putLe32(b: ByteArray, at: Int, v: Int) { for (i in 0 until 4) b[at + i] = (v ushr (8 * i)).toByte() }

        /**
         * A minimal X.509 v1 certificate (CN=Waaiya, valid 2020-2049, SHA256withRSA) written as DER by hand, so no
         * certificate library is needed. adbd accepts any certificate while pairing and afterwards only compares its
         * public key with the paired keys.
         */
        fun selfSignedCertificate(pub: RSAPublicKey, priv: PrivateKey, serial: Long = 1): X509Certificate {
            val sha256WithRsa = Der.seq(Der.oid("1.2.840.113549.1.1.11"), Der.NULL)
            val name = Der.seq(Der.set(Der.seq(Der.oid("2.5.4.3"), Der.utf8("Waaiya"))))
            val validity = Der.seq(Der.utcTime("200101000000Z"), Der.utcTime("491231235959Z"))
            val tbs = Der.seq(Der.integer(BigInteger.valueOf(serial)), sha256WithRsa, name, validity, name, pub.encoded)
            val sig = Signature.getInstance("SHA256withRSA").run { initSign(priv); update(tbs); sign() }
            val der = Der.seq(tbs, sha256WithRsa, Der.bitString(sig))
            return CertificateFactory.getInstance("X.509").generateCertificate(der.inputStream()) as X509Certificate
        }
    }
}

/** The handful of DER encoders the certificate needs. */
internal object Der {
    val NULL = byteArrayOf(0x05, 0x00)

    fun tlv(tag: Int, body: ByteArray): ByteArray {
        val out = ByteArrayOutputStream()
        out.write(tag)
        val n = body.size
        when {
            n < 0x80 -> out.write(n)
            n < 0x100 -> { out.write(0x81); out.write(n) }
            n < 0x10000 -> { out.write(0x82); out.write(n shr 8); out.write(n and 0xff) }
            else -> { out.write(0x83); out.write(n shr 16); out.write((n shr 8) and 0xff); out.write(n and 0xff) }
        }
        out.write(body)
        return out.toByteArray()
    }

    fun seq(vararg parts: ByteArray) = tlv(0x30, parts.fold(ByteArray(0)) { a, b -> a + b })
    fun set(vararg parts: ByteArray) = tlv(0x31, parts.fold(ByteArray(0)) { a, b -> a + b })
    fun integer(v: BigInteger) = tlv(0x02, v.toByteArray())
    fun utf8(s: String) = tlv(0x0c, s.toByteArray(Charsets.UTF_8))
    fun utcTime(s: String) = tlv(0x17, s.toByteArray(Charsets.US_ASCII))
    fun bitString(b: ByteArray) = tlv(0x03, byteArrayOf(0) + b)

    fun oid(dotted: String): ByteArray {
        val parts = dotted.split('.').map { it.toLong() }
        val out = ByteArrayOutputStream()
        out.write((parts[0] * 40 + parts[1]).toInt())
        for (p in parts.drop(2)) {
            val groups = ArrayList<Int>()
            var v = p
            do { groups.add((v and 0x7f).toInt()); v = v ushr 7 } while (v > 0)
            for (i in groups.indices.reversed()) out.write(groups[i] or (if (i > 0) 0x80 else 0))
        }
        return tlv(0x06, out.toByteArray())
    }
}
