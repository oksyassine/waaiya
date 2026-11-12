package org.islamicmute.app.adb

import java.io.DataInputStream
import java.io.InputStream
import java.io.OutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Wire formats of the adb wireless pairing (pairing_connection/pairing_connection.cpp) and of the adb transport
 * (adb.h, protocol.txt), both from AOSP packages/modules/adb (Apache-2.0).
 */
object PairingWire {
    const val VERSION: Byte = 1
    const val TYPE_SPAKE2_MSG: Byte = 0
    const val TYPE_PEER_INFO: Byte = 1
    const val HEADER_SIZE = 6
    /** sizeof(PeerInfo): 1 type byte + 8191 data bytes, always sent whole. */
    const val PEER_INFO_SIZE = 8192
    const val PEER_INFO_RSA_PUB_KEY: Byte = 0
    const val PEER_INFO_DEVICE_GUID: Byte = 1
    private const val MAX_PAYLOAD = PEER_INFO_SIZE * 2

    /** The TLS exporter label, with the NUL adb passes (sizeof("adb-label")), and the key size. */
    const val EXPORT_LABEL = "adb-label\u0000"
    const val EXPORT_SIZE = 64

    /** Header: version, type, payload length (32-bit big-endian), then the payload. */
    fun packet(type: Byte, payload: ByteArray): ByteArray =
        ByteBuffer.allocate(HEADER_SIZE + payload.size).order(ByteOrder.BIG_ENDIAN)
            .put(VERSION).put(type).putInt(payload.size).put(payload).array()

    /** Reads one packet; [java.io.EOFException] when the peer closed (adbd closes on a wrong pairing code). */
    fun read(input: InputStream): Pair<Byte, ByteArray> {
        val din = DataInputStream(input)
        val version = din.readByte()
        val type = din.readByte()
        val size = din.readInt()
        if (version != VERSION) throw ProtocolException("pairing header version $version")
        if (type != TYPE_SPAKE2_MSG && type != TYPE_PEER_INFO) throw ProtocolException("pairing packet type $type")
        if (size <= 0 || size > MAX_PAYLOAD) throw ProtocolException("pairing payload size $size")
        val payload = ByteArray(size)
        din.readFully(payload)
        return type to payload
    }

    /** Our PeerInfo: type ADB_RSA_PUB_KEY, then the public key line ("<base64> name"), zero-filled to 8192. */
    fun peerInfo(publicKeyLine: String): ByteArray {
        val key = publicKeyLine.toByteArray(Charsets.UTF_8)
        require(key.size <= PEER_INFO_SIZE - 2) { "public key too long" }  // keep a NUL after it
        return ByteArray(PEER_INFO_SIZE).also { it[0] = PEER_INFO_RSA_PUB_KEY; System.arraycopy(key, 0, it, 1, key.size) }
    }
}

class ProtocolException(message: String) : java.io.IOException(message)

/** One adb transport message: a 24-byte little-endian header and its payload. */
class AdbMessage(val command: Int, val arg0: Int, val arg1: Int, val payload: ByteArray = ByteArray(0)) {
    fun toBytes(): ByteArray {
        val b = ByteBuffer.allocate(HEADER_SIZE + payload.size).order(ByteOrder.LITTLE_ENDIAN)
        b.putInt(command).putInt(arg0).putInt(arg1).putInt(payload.size).putInt(checksum(payload))
            .putInt(command xor -1).put(payload)
        return b.array()
    }

    fun write(out: OutputStream) { out.write(toBytes()); out.flush() }

    override fun toString(): String = "${name(command)}($arg0, $arg1, ${payload.size} bytes)"

    companion object {
        const val HEADER_SIZE = 24
        const val A_CNXN = 0x4e584e43
        const val A_OPEN = 0x4e45504f
        const val A_OKAY = 0x59414b4f
        const val A_CLSE = 0x45534c43
        const val A_WRTE = 0x45545257
        const val A_AUTH = 0x48545541
        const val A_STLS = 0x534c5453
        const val A_VERSION = 0x01000001
        const val A_STLS_VERSION = 0x01000000
        const val MAX_PAYLOAD = 1024 * 1024

        /** Sum of the payload bytes: adbd ignores it from version 0x01000001, older ones check it. */
        fun checksum(p: ByteArray): Int = p.fold(0) { acc, b -> acc + (b.toInt() and 0xff) }

        fun name(c: Int): String = String(ByteArray(4) { (c ushr (8 * it)).toByte() }, Charsets.US_ASCII)

        /**
         * Reads exactly one message, byte by byte from [input] as given: before the TLS upgrade the caller must not
         * read ahead of the STLS message, so wrap a buffered stream only around a socket that stays plain.
         */
        fun read(input: InputStream, maxPayload: Int = MAX_PAYLOAD): AdbMessage {
            val din = DataInputStream(input)
            val h = ByteArray(HEADER_SIZE)
            din.readFully(h)
            val b = ByteBuffer.wrap(h).order(ByteOrder.LITTLE_ENDIAN)
            val command = b.int; val arg0 = b.int; val arg1 = b.int; val len = b.int; b.int; val magic = b.int
            if (magic != command xor -1) throw ProtocolException("bad adb message magic")
            if (len < 0 || len > maxPayload) throw ProtocolException("adb payload size $len")
            val payload = ByteArray(len)
            din.readFully(payload)
            return AdbMessage(command, arg0, arg1, payload)
        }
    }
}
