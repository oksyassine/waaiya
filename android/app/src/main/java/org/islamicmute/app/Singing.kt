package org.islamicmute.app

/** Keep singing (voice_v1 model, a test). Lane D. (docs/FEATURES_CONTRACT.md) */
object Singing : Feature {
    override val name = "singing"

    override fun snapshot(host: FeatureHost): Map<String, Any?> = emptyMap()

    override fun call(host: FeatureHost, method: String, args: Map<String, Any?>): Any? =
        throw FeatureException("unsupported", "singing.$method")
}
