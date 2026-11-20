package org.islamicmute.app

import android.content.Context

/**
 * Protection that survives a weak moment: a waiting period chosen in advance, and a local PIN (docs/FEATURES_CONTRACT.md,
 * lane B). Every path that switches protection off or weakens it asks here first and must not act when refused.
 */
object Protection : Feature {
    override val name = "protect"

    /**
     * A setting change from any screen. Throws FeatureException("protected") when the change weakens protection and the
     * waiting period or the PIN holds it back. Stub: allows everything.
     */
    fun checkSetting(context: Context, key: String, value: Any?) {}

    /** Stopping the filter (screen button, notification Stop, Quick Settings tile). Stub: allows. */
    fun mayStopFilter(context: Context): Boolean = true

    override fun snapshot(host: FeatureHost): Map<String, Any?> = emptyMap()

    override fun call(host: FeatureHost, method: String, args: Map<String, Any?>): Any? =
        throw FeatureException("unsupported", "protect.$method")
}
