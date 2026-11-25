package org.waaiya.app

import android.app.AlertDialog
import android.content.Context
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.view.ContextThemeWrapper

/**
 * Quick Settings tile "Notification text" (Android 15+; the manifest enables it only there): while Waaiya filters,
 * show the text of notifications instead of only the app name. See [ScreenShareProtection] for what it changes.
 *
 * Needs WRITE_SECURE_SETTINGS from the one-time setup. Phones set up before this tile existed do not have it: with
 * Shizuku running the tile asks Shizuku itself, otherwise it says to run the setup again in Waaiya.
 */
class ScreenShareTileService : TileService() {
    override fun attachBaseContext(base: Context) { super.attachBaseContext(Lang.wrap(base)) }

    private var granting = false
    private val changed: () -> Unit = { update() }

    override fun onStartListening() {
        super.onStartListening()
        FilterService.addListener(changed)  // "from the next start" ends when filtering stops or starts again
        update()
    }

    override fun onStopListening() {
        FilterService.removeListener(changed)
        super.onStopListening()
    }

    override fun onClick() {
        // Android's protection must not be switched from the lock screen: unlock first.
        if (isLocked) unlockAndRun { click() } else click()
    }

    /** One dialog at most per tap: a second dialog opened from the first one's button would not show. */
    private fun click() {
        val settings = Settings(this)
        val can = ScreenShareProtection.setUp(this)
        when {
            granting -> return
            settings.showNotificationText && can -> set(false)
            !settings.notificationTextExplained -> explain(can)
            else -> turnOn(withDialog = true)  // also "on but the permission is missing": asks for the setup again
        }
    }

    /**
     * Android reads its switch only when a capture starts: turning on takes effect at the next start (FilterService
     * applies it then). Turning off puts Android's switch back at once, for screen shares started from now on.
     */
    private fun set(on: Boolean) {
        Settings(this).showNotificationText = on
        if (!on) ScreenShareProtection.restore(this)
        update()
    }

    /**
     * On without the permission keeps the wish: the main screen shows the setup card again
     * ([ScreenShareProtection.needsSetup]), and the tile works as soon as the setup is done.
     */
    private fun turnOn(withDialog: Boolean) {
        set(true)
        if (ScreenShareProtection.setUp(this)) return
        when {
            ShizukuSetup.state(this) == ShizukuSetup.State.READY -> grantWithShizuku()
            withDialog -> showDialog(dialog()
                .setTitle(R.string.tile_text_setup_title)
                .setMessage(R.string.tile_text_setup_body)
                .setPositiveButton(R.string.tile_open_app) { _, _ -> openApp() }
                .setNegativeButton(android.R.string.cancel) { _, _ -> set(false) }
                .create())
            else -> openApp()
        }
    }

    /**
     * The first turn-on says what changes: other screen shares at the same time are not protected either. When the
     * permission is missing (and Shizuku cannot give it now), the same dialog also says how to get it.
     */
    private fun explain(can: Boolean) {
        val viaApp = !can && ShizukuSetup.state(this) != ShizukuSetup.State.READY
        val body = getString(R.string.tile_text_explain_body) +
            if (viaApp) "\n\n" + getString(R.string.tile_text_setup_body) else ""
        showDialog(dialog()
            .setTitle(R.string.tile_text_explain_title)
            .setMessage(body)
            .setPositiveButton(if (viaApp) R.string.tile_open_app else R.string.tile_text_turn_on) { _, _ ->
                Settings(this).notificationTextExplained = true
                turnOn(withDialog = false)
            }
            .setNegativeButton(android.R.string.cancel, null)
            .create())
    }

    private fun grantWithShizuku() {
        granting = true
        update()
        ShizukuSetup.grant(this) {
            granting = false
            update()
        }
    }

    private fun openApp() {
        UiActivity.open(this, "setup")?.let { FilterTileService.openActivity(this, it) }
    }

    private fun dialog() = AlertDialog.Builder(ContextThemeWrapper(this, android.R.style.Theme_DeviceDefault_DayNight))

    private fun update() {
        val tile = qsTile ?: return
        val can = ScreenShareProtection.setUp(this)
        val on = can && Settings(this).showNotificationText
        tile.label = getString(R.string.tile_text_label)
        tile.state = if (on) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        val running = ScreenShareProtection.shownInCapture
        tile.subtitle = getString(when {
            granting -> R.string.tile_text_granting
            !can -> R.string.tile_text_needs_setup
            ScreenShareProtection.refusedByPhone && on -> R.string.tile_text_refused
            running != null && running != on -> R.string.tile_text_next_start
            on -> R.string.tile_text_shown
            else -> R.string.tile_text_hidden
        })
        tile.updateTile()
    }
}
