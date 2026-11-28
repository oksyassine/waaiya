package org.waaiya.app

import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionConfig
import android.media.projection.MediaProjectionManager
import android.os.Build

/**
 * What Android's start question offers: the entire screen, or (Android 16+) also "Share one app".
 *
 * Android 16 still hands over every app's sound when only one app is shared (Waaiya itself), and then neither hides
 * notification text nor stops the capture when the screen locks (all three checked on the Android 16 emulator,
 * 2026-11-25). Android 15 refuses the sound of a one-app share (UnsupportedOperationException when the capture opens).
 * So on Android 16+, when Android asks anyway (no PROJECT_MEDIA: no setup, or a phone that refused it) and the screen
 * blur is off (it needs the entire screen), the question offers both and the Filter page says to pick Waaiya. A phone
 * whose capture refuses it once ([Settings.oneAppRefused]) is asked for the entire screen from then on.
 */
object CaptureChoice {
    fun offerOneApp(ctx: Context): Boolean {
        val s = Settings(ctx)
        return Build.VERSION.SDK_INT >= 36 && !ctx.hasProjectMediaAppOp() && !s.blurOn && !s.oneAppRefused
    }

    /** Android's question, as [offerOneApp] says. */
    fun intent(ctx: Context): Intent {
        val mpm = ctx.getSystemService(MediaProjectionManager::class.java)
        return when {
            Build.VERSION.SDK_INT < 34 -> mpm.createScreenCaptureIntent()
            offerOneApp(ctx) -> mpm.createScreenCaptureIntent(MediaProjectionConfig.createConfigForUserChoice())
            // Android 14+ offers "a single app" first otherwise; before 16 it would carry no other app's sound
            else -> mpm.createScreenCaptureIntent(MediaProjectionConfig.createConfigForDefaultDisplay())
        }
    }
}
