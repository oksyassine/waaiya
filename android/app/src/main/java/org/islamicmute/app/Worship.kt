package org.islamicmute.app

/** Prayer-time silence, media muted at the adhan, plain tones. Lane C. (docs/FEATURES_CONTRACT.md) */
object Worship : Feature {
    override val name = "worship"

    override fun snapshot(host: FeatureHost): Map<String, Any?> = emptyMap()

    override fun call(host: FeatureHost, method: String, args: Map<String, Any?>): Any? =
        throw FeatureException("unsupported", "worship.$method")
}
