package org.islamicmute.app

/**
 * Which fix actions the filter's notification carries after its Stop (FixMistakes.notificationActions). Android shows
 * three actions on a notification and Stop is the first, so two at most. No Android classes (FixMistakesTest).
 */
object FixMistakesActions {
    const val COVER = "cover"
    const val REMOVE = "remove"
    const val MISSED = "missed"
    const val WRONG = "wrong"

    /**
     * While the blur runs: "Cover an area" (or "Remove hand covers" while there are some), then "Missed something".
     * Without the blur: the two notes. "Hidden by mistake" stays on the Screen and Filter pages.
     */
    fun kinds(blurRunning: Boolean, handCovers: Int): List<String> = when {
        !blurRunning -> listOf(MISSED, WRONG)
        handCovers > 0 -> listOf(REMOVE, MISSED)
        else -> listOf(COVER, MISSED)
    }
}
