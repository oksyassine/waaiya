package org.waaiya.app

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log

/**
 * Android 15+ hides the text of notifications (only the app name shows) while any app captures the whole screen.
 * Filtering needs such a capture (Android hands over other apps' sound only through a screen-capture token), so
 * with Waaiya on, every notification looks empty.
 *
 * The Developer options switch "Disable screen share protections" is the global setting [KEY]. Waaiya writes it
 * (WRITE_SECURE_SETTINGS, granted by the one-time setup) only when the user asked for it with the Quick Settings
 * tile, and only while filtering: it is turned off just before the capture starts and restored when filtering
 * ends, so screen shares made while Waaiya is off stay protected. A value the user set by hand is never changed.
 */
object ScreenShareProtection {
    private const val TAG = "IslamicMute"
    const val KEY = "disable_screen_share_protections_for_apps_and_notifications"
    private const val PREFS = "screen_share"
    /** Waaiya changed [KEY] to 1 and must put it back. Kept on disk: a crash must not leave it changed for good. */
    private const val CHANGED = "changed_by_waaiya"

    val supported: Boolean get() = Build.VERSION.SDK_INT >= 35

    /** The permission, or Waaiya's helper on a phone that refused it ([HelperDumps]). */
    fun canWrite(ctx: Context) =
        ctx.checkSelfPermission(android.Manifest.permission.WRITE_SECURE_SETTINGS) == PackageManager.PERMISSION_GRANTED ||
            HelperDumps.helperReady

    /** The tile can work on this phone: the permission, or the helper mode (the helper may need starting again). */
    fun setUp(ctx: Context) =
        ctx.checkSelfPermission(android.Manifest.permission.WRITE_SECURE_SETTINGS) == PackageManager.PERMISSION_GRANTED ||
            HelperDumps.helperMode(ctx)

    /** The helper tried to write the switch and this phone refused: the tile says so instead of pretending. */
    @Volatile var refusedByPhone = false
        private set

    /** True when Android's protection is off now (by Waaiya or by hand): notification text shows during captures. */
    fun protectionOff(ctx: Context) =
        android.provider.Settings.Global.getInt(ctx.contentResolver, KEY, 0) != 0

    /**
     * Android asks before each capture on this phone (no PROJECT_MEDIA: Xiaomi and the OPPO family refuse it to the
     * setup). Android 15 QPR1+ then stops the capture at every screen lock (STOP_REASON_KEYGUARD, checked on the
     * Android 16 emulator, blur on or off), and Waaiya holds the other apps silent until the user resumes. With this
     * protection off the lock does not stop it. So on such a phone Waaiya lifts the protection while filtering
     * whatever the notification-text choice, when it can.
     */
    fun neededForLock(ctx: Context) = supported && !ctx.hasProjectMediaAppOp()

    /** Lift the protection at the next capture start: the user's notification-text choice, or [neededForLock]. */
    fun wanted(ctx: Context) = Settings(ctx).showNotificationText || neededForLock(ctx)

    /** The user turned the tile on but the permission is missing: the main screen shows the setup card again. */
    fun needsSetup(ctx: Context) = supported && Settings(ctx).showNotificationText && !setUp(ctx)

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /**
     * Whether notification text shows during the running capture: Android (SystemUI) reads the switch only when a
     * capture starts, so a change made while filtering applies at the next start. Null when not capturing.
     */
    @Volatile var shownInCapture: Boolean? = null
        private set

    /** Called by FilterService just before the capture starts. commit(): the mark must be on disk before a crash. */
    @android.annotation.SuppressLint("ApplySharedPref")
    fun apply(ctx: Context) {
        if (supported && wanted(ctx) && canWrite(ctx) && !protectionOff(ctx) && put(ctx, 1))
            prefs(ctx).edit().putBoolean(CHANGED, true).commit()
        shownInCapture = if (supported) protectionOff(ctx) else null
    }

    /** Called when the capture ends (FilterService). */
    fun captureEnded(ctx: Context) {
        shownInCapture = null
        restore(ctx)
    }

    /** Called when the capture ends, when the tile is turned off, and at app start (after a crash). */
    @android.annotation.SuppressLint("ApplySharedPref")
    fun restore(ctx: Context) {
        if (!prefs(ctx).getBoolean(CHANGED, false)) return
        // Forget the mark only when Android's switch really is back (written now, or already 0). When it cannot be
        // written now (helper stopped), the mark stays: CoverHelperProvider calls this again when a helper answers.
        if (put(ctx, 0) || !protectionOff(ctx)) prefs(ctx).edit().putBoolean(CHANGED, false).commit()
    }

    /**
     * Through the helper (no permission): the helper runs `settings put`, which takes a moment and which some phones
     * refuse to the shell too (OPPO family). So: off the calling thread with a deadline (this is called on the main
     * thread just before a capture starts), and believed only when the value reads back.
     */
    private fun put(ctx: Context, v: Int): Boolean = runCatching {
        if (ctx.checkSelfPermission(android.Manifest.permission.WRITE_SECURE_SETTINGS) == PackageManager.PERMISSION_GRANTED)
            return@runCatching android.provider.Settings.Global.putInt(ctx.contentResolver, KEY, v)
        val helper = CoverHelper.service ?: return@runCatching false
        val task = java.util.concurrent.FutureTask { helper.putScreenShareProtection(v) }
        kotlin.concurrent.thread(name = "im-ssp-put", isDaemon = true) { task.run() }
        val said = runCatching { task.get(2500, java.util.concurrent.TimeUnit.MILLISECONDS) }.getOrDefault(false)
        val took = protectionOff(ctx) == (v != 0)
        refusedByPhone = !took
        if (!took) Log.w(TAG, "screen share protection: the helper's write did not take (helper said $said)")
        took
    }.onFailure { Log.w(TAG, "screen share protection: cannot write $KEY", it) }.getOrDefault(false)
}
