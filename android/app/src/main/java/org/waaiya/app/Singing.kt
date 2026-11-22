package org.waaiya.app

/**
 * Keep singing (voice_v1 model, a test). Lane D. (docs/FEATURES_CONTRACT.md)
 *
 * The setting is `keep_singing` (Settings.keepSinging, changed through UiBridge.setSetting like any other); the live
 * filter picks the model from it and swaps engines while running (FilterService). Snapshot `features.singing`:
 * `available` = this build bundles the model, `active` = the running filter uses it and it loaded.
 */
object Singing : Feature {
    override val name = "singing"

    override fun snapshot(host: FeatureHost): Map<String, Any?> = mapOf(
        "available" to ModelStore.hasSinging(host.activity),
        "active" to active(FilterService.health?.keepSinging, FilterService.state),
    )

    /** The running filter uses the keep-singing model and that model loaded (a failed one is silent: not active). */
    fun active(engineSinging: Boolean?, state: FilterService.State): Boolean =
        engineSinging == true && state == FilterService.State.FILTERING

    override fun call(host: FeatureHost, method: String, args: Map<String, Any?>): Any? =
        throw FeatureException("unsupported", "singing.$method")
}
