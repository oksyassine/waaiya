package org.islamicmute.app.adb

import javax.crypto.Cipher
import javax.crypto.Mac
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * adb's pairing cipher (pairing_auth/aes_128_gcm.cpp): AES-128-GCM with the key derived by HKDF-SHA256 from the
 * SPAKE2 key (no salt, info "adb pairing_auth aes-128-gcm key" without a NUL). The 12-byte nonce is a 64-bit
 * message counter, little-endian, then zeros; sending and receiving count separately. 16-byte tag appended.
 */
class PairingCipher(spakeKey: ByteArray) {
    private val key = SecretKeySpec(hkdfSha256(spakeKey, ByteArray(0), INFO, 16), "AES")
    private var encSeq = 0L
    private var decSeq = 0L

    fun encrypt(plain: ByteArray): ByteArray = run(Cipher.ENCRYPT_MODE, encSeq++, plain)

    /** Throws [javax.crypto.AEADBadTagException] when the peer used another key (a wrong pairing code). */
    fun decrypt(sealed: ByteArray): ByteArray = run(Cipher.DECRYPT_MODE, decSeq++, sealed)

    private fun run(mode: Int, seq: Long, data: ByteArray): ByteArray {
        val nonce = ByteArray(12)
        for (i in 0 until 8) nonce[i] = (seq ushr (8 * i)).toByte()
        val c = Cipher.getInstance("AES/GCM/NoPadding")
        c.init(mode, key, GCMParameterSpec(128, nonce))
        return c.doFinal(data)
    }

    companion object {
        val INFO = "adb pairing_auth aes-128-gcm key".toByteArray(Charsets.US_ASCII)
        const val TAG_SIZE = 16

        /** RFC 5869 HKDF (extract then expand). An empty salt means HashLen zero bytes, as the RFC says. */
        fun hkdfSha256(ikm: ByteArray, salt: ByteArray, info: ByteArray, length: Int): ByteArray {
            val mac = Mac.getInstance("HmacSHA256")
            mac.init(SecretKeySpec(if (salt.isEmpty()) ByteArray(32) else salt, "HmacSHA256"))
            val prk = mac.doFinal(ikm)
            mac.init(SecretKeySpec(prk, "HmacSHA256"))
            val out = ByteArray(length)
            var t = ByteArray(0)
            var pos = 0
            var counter = 1
            while (pos < length) {
                mac.update(t); mac.update(info); mac.update(counter.toByte())
                t = mac.doFinal()
                val n = minOf(t.size, length - pos)
                System.arraycopy(t, 0, out, pos, n)
                pos += n; counter++
            }
            return out
        }
    }
}
