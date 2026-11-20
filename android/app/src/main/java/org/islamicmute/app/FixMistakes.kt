package org.islamicmute.app

/** Fix mistakes on the spot: per-app filter/blur off, covering an area by hand, local wrong-detection notes. Lane A. (docs/FEATURES_CONTRACT.md) */
object FixMistakes : Feature {
    override val name = "fix"

    override fun snapshot(host: FeatureHost): Map<String, Any?> = emptyMap()

    override fun call(host: FeatureHost, method: String, args: Map<String, Any?>): Any? =
        throw FeatureException("unsupported", "fix.$method")
}
