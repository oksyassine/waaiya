package org.islamicmute.app.adb

import java.math.BigInteger

/**
 * The edwards25519 group (RFC 8032 section 5.1), just enough for [Spake2]: point decoding and encoding, addition,
 * negation and variable-time scalar multiplication. BigInteger arithmetic in extended coordinates: slow next to
 * BoringSSL's, but SPAKE2 needs four multiplications once per pairing (well under a second on a phone), and it is
 * pure JVM code that the unit tests can check against the RFC's vectors.
 *
 * Not constant time. The secrets here are one-time: a random scalar that lives for one pairing attempt and a
 * pairing code that Android shows on screen and discards when the dialog closes.
 */
internal object Ed25519 {
    val P: BigInteger = BigInteger.ONE.shiftLeft(255) - BigInteger.valueOf(19)
    /** Order of the prime-order subgroup: 2^252 + 27742317777372353535851937790883648493. */
    val L: BigInteger = BigInteger.ONE.shiftLeft(252) + BigInteger("27742317777372353535851937790883648493")
    private val D: BigInteger = BigInteger.valueOf(-121665) * BigInteger.valueOf(121666).modInverse(P) % P
    private val D2: BigInteger = D.shiftLeft(1) % P
    private val SQRT_M1: BigInteger = BigInteger.valueOf(2).modPow((P - BigInteger.ONE).shiftRight(2), P)

    /** A point in extended coordinates: x = X/Z, y = Y/Z, x*y = T/Z. */
    class Point internal constructor(val x: BigInteger, val y: BigInteger, val z: BigInteger, val t: BigInteger) {
        operator fun plus(o: Point): Point {
            val a = (y - x) * (o.y - o.x) % P
            val b = (y + x) * (o.y + o.x) % P
            val c = t * D2 % P * o.t % P
            val d = z.shiftLeft(1) * o.z % P
            val e = b - a; val f = d - c; val g = d + c; val h = b + a
            return Point(e * f % P, g * h % P, f * g % P, e * h % P)
        }

        operator fun unaryMinus(): Point = Point(P - x.mod(P), y, z, P - t.mod(P))
        operator fun minus(o: Point): Point = this + (-o)

        /** k * this for any k >= 0 (not reduced: [Spake2] relies on multiples of the cofactor). */
        fun times(k: BigInteger): Point {
            require(k.signum() >= 0)
            var acc = IDENTITY
            for (i in k.bitLength() - 1 downTo 0) {
                acc += acc
                if (k.testBit(i)) acc += this
            }
            return acc
        }

        /** 32 bytes: y little-endian, the sign of x in the top bit. */
        fun encode(): ByteArray {
            val zi = z.mod(P).modInverse(P)
            val ax = x * zi % P
            val ay = (y * zi).mod(P)
            val out = toLittleEndian(ay, 32)
            if (ax.mod(P).testBit(0)) out[31] = (out[31].toInt() or 0x80).toByte()
            return out
        }

        override fun equals(other: Any?): Boolean = other is Point &&
            (x * other.z - other.x * z).mod(P).signum() == 0 && (y * other.z - other.y * z).mod(P).signum() == 0
        override fun hashCode(): Int = encode().contentHashCode()
    }

    val IDENTITY = Point(BigInteger.ZERO, BigInteger.ONE, BigInteger.ONE, BigInteger.ZERO)

    /** The base point: y = 4/5, x even. */
    val BASE: Point = decode(toLittleEndian(BigInteger.valueOf(4) * BigInteger.valueOf(5).modInverse(P) % P, 32))

    fun affine(x: BigInteger, y: BigInteger): Point = Point(x.mod(P), y.mod(P), BigInteger.ONE, (x * y).mod(P))

    /** RFC 8032 5.1.3. Throws [IllegalArgumentException] for bytes that are not a point on the curve. */
    fun decode(bytes: ByteArray): Point {
        require(bytes.size == 32) { "point must be 32 bytes" }
        val b = bytes.copyOf()
        val sign = (b[31].toInt() shr 7) and 1
        b[31] = (b[31].toInt() and 0x7f).toByte()
        val y = fromLittleEndian(b)
        require(y < P) { "point not canonical" }
        val y2 = y * y % P
        val u = (y2 - BigInteger.ONE).mod(P)
        val v = (D * y2 + BigInteger.ONE) % P
        val x2 = u * v.modInverse(P) % P
        if (x2.signum() == 0) {
            require(sign == 0) { "point not on the curve" }
            return affine(BigInteger.ZERO, y)
        }
        var x = x2.modPow((P + BigInteger.valueOf(3)).shiftRight(3), P)
        if ((x * x - x2).mod(P).signum() != 0) x = x * SQRT_M1 % P
        require((x * x - x2).mod(P).signum() == 0) { "point not on the curve" }
        if (x.testBit(0) != (sign == 1)) x = P - x
        return affine(x, y)
    }

    fun fromLittleEndian(b: ByteArray): BigInteger = BigInteger(1, b.reversedArray())

    /** [v] (non-negative, < 2^(8*size)) as [size] little-endian bytes. */
    fun toLittleEndian(v: BigInteger, size: Int): ByteArray {
        val be = v.toByteArray()  // big-endian, maybe with a leading sign byte
        val out = ByteArray(size)
        for (i in be.indices) {
            val j = be.size - 1 - i
            if (j < size) out[j] = be[i] else require(be[i].toInt() == 0) { "value does not fit" }
        }
        return out
    }
}
