package org.islamicmute.app.adb

import java.net.InetSocketAddress
import java.net.Socket
import java.security.Principal
import java.security.PrivateKey
import java.security.cert.X509Certificate
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLEngine
import javax.net.ssl.SSLSocket
import javax.net.ssl.X509ExtendedKeyManager
import javax.net.ssl.X509ExtendedTrustManager

/**
 * TLS 1.3 the way adb uses it: both sides present a self-signed certificate and neither checks the other's chain
 * (pairing proves the peer through SPAKE2; adbd then trusts only paired keys). The key manager always offers our
 * certificate: adbd sends a list of "CA names" made from its paired keys, which a default key manager would use to
 * filter our certificate out.
 */
class AdbTls(private val key: AdbKey) {
    private val context: SSLContext by lazy {
        SSLContext.getInstance("TLSv1.3").apply { init(arrayOf(KeyManager(key)), arrayOf(TrustAll), null) }
    }

    /** Opens [host]:[port] and runs the TLS handshake (plain socket first, for the adb transport's STLS step). */
    fun connect(host: String, port: Int, timeoutMs: Int): SSLSocket {
        val plain = Socket()
        try {
            plain.connect(InetSocketAddress(host, port), timeoutMs)
            plain.soTimeout = timeoutMs
            plain.tcpNoDelay = true
        } catch (t: Throwable) { runCatching { plain.close() }; throw t }
        return upgrade(plain, host, port)
    }

    /** Wraps an already connected socket in TLS (client side) and finishes the handshake. */
    fun upgrade(plain: Socket, host: String, port: Int): SSLSocket {
        val ssl = context.socketFactory.createSocket(plain, host, port, true) as SSLSocket
        try {
            ssl.enabledProtocols = arrayOf("TLSv1.3")
            ssl.useClientMode = true
            ssl.startHandshake()
        } catch (t: Throwable) { runCatching { ssl.close() }; throw t }
        return ssl
    }

    private class KeyManager(private val key: AdbKey) : X509ExtendedKeyManager() {
        override fun chooseClientAlias(keyType: Array<out String>?, issuers: Array<out Principal>?, socket: Socket?) = ALIAS
        override fun chooseEngineClientAlias(keyType: Array<out String>?, issuers: Array<out Principal>?, engine: SSLEngine?) = ALIAS
        override fun getClientAliases(keyType: String?, issuers: Array<out Principal>?) = arrayOf(ALIAS)
        override fun getCertificateChain(alias: String?): Array<X509Certificate> = arrayOf(key.certificate)
        override fun getPrivateKey(alias: String?): PrivateKey = key.privateKey
        override fun getServerAliases(keyType: String?, issuers: Array<out Principal>?): Array<String>? = null
        override fun chooseServerAlias(keyType: String?, issuers: Array<out Principal>?, socket: Socket?): String? = null
    }

    @Suppress("CustomX509TrustManager", "TrustAllX509TrustManager")
    private object TrustAll : X509ExtendedTrustManager() {
        override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) {}
        override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) {}
        override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?, socket: Socket?) {}
        override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?, socket: Socket?) {}
        override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?, engine: SSLEngine?) {}
        override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?, engine: SSLEngine?) {}
        override fun getAcceptedIssuers(): Array<X509Certificate> = emptyArray()
    }

    private companion object { const val ALIAS = "waaiya-adb" }
}
