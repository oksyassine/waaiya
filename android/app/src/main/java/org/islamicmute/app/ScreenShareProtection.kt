package org.islamicmute.app

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

    fun canWrite(ctx: Context) =
        ctx.checkSelfPermission(android.Manifest.permission.WRITE_SECURE_SETTINGS) == PackageManager.PERMISSION_GRANTED

    /** True when Android's protection is off now (by Waaiya or by hand): notification text shows during captures. */
    fun protectionOff(ctx: Context) =
        android.provider.Settings.Global.getInt(ctx.contentResolver, KEY, 0) != 0

    /** The user turned the tile on but the permission is missing: the main screen shows the setup card again. */
    fun needsSetup(ctx: Context) = supported && Settings(ctx).showNotificationText && !canWrite(ctx)

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
        if (supported && Settings(ctx).showNotificationText && canWrite(ctx) && !protectionOff(ctx) && put(ctx, 1))
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
        if (!canWrite(ctx) || put(ctx, 0)) prefs(ctx).edit().putBoolean(CHANGED, false).commit()
    }

    private fun put(ctx: Context, v: Int): Boolean = runCatching {
        android.provider.Settings.Global.putInt(ctx.contentResolver, KEY, v)
    }.onFailure { Log.w(TAG, "screen share protection: cannot write $KEY", it) }.getOrDefault(false)
}
