package org.islamicmute.app

import android.app.Activity

/**
 * The native side of a 0.2.13 feature (docs/FEATURES_CONTRACT.md). Each feature owns one object and one snapshot
 * section; UiBridge only routes to it, so features do not edit each other's code.
 */
interface Feature {
    /** Snapshot section and method prefix: `fix`, `worship`, `protect`, `singing`. */
    val name: String

    /** `features.<name>` in the snapshot. Values must suit Flutter's StandardMethodCodec. */
    fun snapshot(host: FeatureHost): Map<String, Any?>

    /** Method `<name>.<method>` from Flutter. Returns a codec value; throws [FeatureException] or BadArgs-like errors. */
    fun call(host: FeatureHost, method: String, args: Map<String, Any?>): Any?
}

/** What a feature may use from the screen that hosts Flutter. */
interface FeatureHost {
    val activity: Activity

    /** Sends a new snapshot to Flutter. */
    fun refresh()
}

/** A refusal with a contract error code: `bad_args`, `unsupported`, `busy`, `failed`, `protected`. */
class FeatureException(val code: String, message: String) : Exception(message)

object Features {
    val ALL: List<Feature> = listOf(FixMistakes, Worship, Protection, Singing)

    fun byMethod(method: String): Pair<Feature, String>? {
        val dot = method.indexOf('.')
        if (dot <= 0) return null
        val f = ALL.firstOrNull { it.name == method.substring(0, dot) } ?: return null
        return f to method.substring(dot + 1)
    }
}
