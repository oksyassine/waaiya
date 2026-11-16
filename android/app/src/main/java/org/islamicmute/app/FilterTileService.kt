package org.islamicmute.app

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
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
            startService(Intent(this, FilterService::class.java).setAction(FilterService.ACTION_STOP))
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
            if (FilterService.running || FilterService.state == FilterService.State.SILENCED)
                startService(Intent(this, FilterService::class.java).setAction(FilterService.ACTION_STOP))
            finish()
            return
        }
        if (FilterService.running) { finish(); return }
        if (checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED ||
            !hasDumpPermission()) {
            // the setup is missing: the Setup page explains; the microphone question belongs to the Filter page
            UiActivity.open(this, if (hasDumpPermission()) "filter" else "setup")?.let { runCatching { startActivity(it) } }
            finish()
            return
        }
        val mpm = getSystemService(MediaProjectionManager::class.java)
        // As the main screen: the whole device, never "a single app" (Android 14+ offers that first otherwise).
        val ask = if (Build.VERSION.SDK_INT >= 34)
            mpm.createScreenCaptureIntent(android.media.projection.MediaProjectionConfig.createConfigForDefaultDisplay())
        else mpm.createScreenCaptureIntent()
        @Suppress("DEPRECATION") startActivityForResult(ask, REQ_CAPTURE)
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
        const val ACTION_STOP_FILTER = "org.islamicmute.app.STOP_FILTER"
    }
}
