package org.waaiya.app

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Quick Settings tile "Waaiya": starts and stops filtering without opening the app.
 *
 * Stopping is a plain service call. Starting needs Android's screen-capture token, which only an activity can ask
 * for, so the tile opens [TileStartActivity], an invisible activity that asks and closes. After the one-time setup
 * (PROJECT_MEDIA app-op) Android answers without showing its question, so nothing appears on screen.
 */
class FilterTileService : TileService() {
    override fun attachBaseContext(base: Context) { super.attachBaseContext(Lang.wrap(base)) }

    private val changed: () -> Unit = { update() }

    override fun onStartListening() {
        super.onStartListening()
        FilterService.addListener(changed)
        update()
    }

    override fun onStopListening() {
        FilterService.removeListener(changed)
        super.onStopListening()
    }

    override fun onClick() {
        if (FilterService.running) {
            // the waiting period and the PIN (Protection): when they hold it back, Waaiya opens where it asks
            Protection.stopOrAsk(this)?.let { openActivity(this, it) }
            return
        }
        // From SILENCED too: starting again resumes filtering (the muter keeps the originals silent meanwhile).
        val go = { openActivity(this, Intent(this, TileStartActivity::class.java)) }
        if (isLocked) unlockAndRun(go) else go()
    }

    private fun update() {
        val tile = qsTile ?: return
        val state = FilterService.state
        tile.label = getString(R.string.app_name)
        tile.state = if (FilterService.running) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.subtitle = getString(when {
            state == FilterService.State.STARTING -> R.string.tile_starting
            state == FilterService.State.SILENCED -> R.string.tile_silenced
            !FilterService.running -> R.string.tile_off
            FilterService.muterStatus == SessionMuter.Status.NO_PERMISSION -> R.string.tile_on_not_muted
            else -> R.string.tile_on
        })
        tile.updateTile()
    }

    companion object {
        /** Opens an activity from a tile and closes the Quick Settings panel (the PendingIntent form on 14+). */
        fun openActivity(tile: TileService, intent: Intent) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (Build.VERSION.SDK_INT >= 34) {
                tile.startActivityAndCollapse(PendingIntent.getActivity(tile, 0, intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT))
            } else {
                @Suppress("DEPRECATION", "StartActivityAndCollapseDeprecated") tile.startActivityAndCollapse(intent)
            }
        }
    }
}

/**
 * Invisible, for the Quick Settings tile and the app shortcuts (Start / Stop filtering on the icon): asks Android
 * for the screen-capture token (answered at once after the setup), starts [FilterService]
 * and closes. When something needs the user (the microphone permission, or the one-time setup is missing so the
 * original music would still be heard), it opens the main screen instead, which explains and asks.
 */
class TileStartActivity : Activity() {
    override fun attachBaseContext(base: Context) { super.attachBaseContext(Lang.wrap(base)) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState != null) return  // recreated while Android's question is open: its answer still comes
        // the "Stop filtering" app shortcut (res/xml/shortcuts.xml); SILENCED too: the other apps sound again
        if (intent?.action == ACTION_STOP_FILTER) {
            // also the filter notification's Stop. Through the waiting period and the PIN (Protection): when they
            // hold it back, Waaiya opens at its Settings page, where it asks
            if (FilterService.running || FilterService.state == FilterService.State.SILENCED)
                Protection.stopOrAsk(this)?.let { runCatching { startActivity(it) } }
            finish()
            return
        }
        if (FilterService.running) { finish(); return }
        val ready = setupDone() || Settings(this).simpleMode  // simple mode (test) needs no setup
        if (checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED || !ready) {
            // the setup is missing: the Setup page explains; the microphone question belongs to the Filter page
            UiActivity.open(this, if (ready) "filter" else "setup")?.let { runCatching { startActivity(it) } }
            finish()
            return
        }
        // Helper mode in a process that just started (the tile, a shortcut): a running helper answers within a few
        // seconds; wait for it rather than guess (HelperDumps.settling).
        if (HelperDumps.helperMode(this) && !HelperDumps.helperReady && HelperDumps.settling) {
            val go = object : Runnable {
                var done = false
                override fun run() { if (!done && !isFinishing && !isDestroyed) { done = true; CoverHelper.removeListener(arrived); askOrExplain() } }
                val arrived: () -> Unit = { if (HelperDumps.helperReady) run() }
            }
            CoverHelper.addListener(go.arrived)
            window.decorView.postDelayed(go, HelperDumps.SETTLE_MS)
            return
        }
        askOrExplain()
    }

    private fun askOrExplain() {
        // helper mode after a restart: the helper comes back while the capture starts (the muter waits for it). When
        // it cannot (Wireless debugging off), filtering would play the music too: the Filter page says how instead
        if (helperMissing() && !WirelessSetup.restartHelperIfNeeded(this) && !WirelessSetup.running) {
            UiActivity.open(this, "filter")?.let { runCatching { startActivity(it) } }
            finish()
            return
        }
        // as the main screen: the entire screen, or on Android 16+ also "Share one app" (CaptureChoice)
        @Suppress("DEPRECATION") startActivityForResult(CaptureChoice.intent(this), REQ_CAPTURE)
    }

    @Deprecated("framework Activity API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION") super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_CAPTURE && resultCode == RESULT_OK && data != null) {
            startForegroundService(Intent(this, FilterService::class.java)
                .putExtra(FilterService.EXTRA_CODE, resultCode).putExtra(FilterService.EXTRA_DATA, data))
        }
        finish()
    }

    companion object {
        private const val REQ_CAPTURE = 7
        /** App shortcuts (res/xml/shortcuts.xml). START_FILTER is this activity's normal job. */
        const val ACTION_STOP_FILTER = "org.waaiya.app.STOP_FILTER"
    }
}
