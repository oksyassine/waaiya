package org.waaiya.app

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import kotlin.math.pow

/**
 * Simple mode (TEST, 0.2.13): filtering without the one-time setup, for people who will not turn on Developer
 * options. Without the setup Waaiya cannot silence another app's own sound, so here it mutes the phone's media
 * sound while it filters and plays the filtered sound on another channel (alarm or notification, a setting).
 * Checked on the API 30 and API 35 emulators: the playback capture keeps the full level with media muted or at 0.
 *
 * The only phone state written is the media stream's mute. It is recorded before muting ([KEY_MUTED]) and undone
 * when filtering ends and, after a crash, at the next process start ([restore]). Waaiya's loudness is the track's
 * own gain ([gain]), taken from the media volume; a volume-key press (which changes the media volume and unmutes
 * it) becomes Waaiya's loudness and the media sound is muted again at once. Alarm and notification volumes are
 * never written.
 *
 * Open questions only real phones answer (the diagnostics report has what is needed): is the chosen channel heard
 * while media is muted; does it play only where media would (alarm also rings on the speaker with earphones in);
 * does it survive vibrate and Do Not Disturb (notification does not); Bluetooth earbuds with absolute volume.
 */
object SimpleMode {
    private const val TAG = "IslamicMute"
    private const val PREFS = "simple_mode"
    private const val KEY_MUTED = "media_muted"
    private const val OWN_EVENT_MS = 400L

    @Volatile var active = false; private set
    /** The filtered track's gain, 0..1, from the media volume (read by the filter loop). */
    @Volatile var gain = 1f; private set
    @Volatile var remutes = 0; private set
    /** Where Waaiya's own track plays (the filter loop sets it). */
    @Volatile var routed: AudioDeviceInfo? = null
    private var index = 0          // the media volume index Waaiya's loudness follows
    private var ownMuteAt = 0L     // our own mute call: its broadcasts are not volume-key presses
    private val events = ArrayDeque<String>()
    private var receiver: BroadcastReceiver? = null
    private var devices: AudioDeviceCallback? = null
    private val main = Handler(Looper.getMainLooper())

    fun on(ctx: Context) = Settings(ctx).simpleMode

    /** The usage of Waaiya's own output track in simple mode. */
    fun usage(ctx: Context): Int =
        if (Settings(ctx).simpleChannel == "notification") AudioAttributes.USAGE_NOTIFICATION else AudioAttributes.USAGE_ALARM

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Filtering starts in simple mode: mute media (recorded first) and follow volume and output changes. Main thread. */
    fun begin(ctx: Context) {
        if (active) return
        val app = ctx.applicationContext
        val am = app.getSystemService(AudioManager::class.java)
        index = am.getStreamVolume(AudioManager.STREAM_MUSIC)  // 0 while muted: read before muting
        // already muted (by the user, or left so): no level to follow, start in the middle
        if (index == 0 && am.isStreamMute(AudioManager.STREAM_MUSIC)) index = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC) / 2
        gain = gainFor(am, index)
        prefs(app).edit().putBoolean(KEY_MUTED, true).commit()
        active = true
        events.clear()
        log("begin: media volume $index/${am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)}, gain ${"%.2f".format(java.util.Locale.ROOT, gain)}")
        mute(am)
        receiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context, i: Intent) {
                if (i.getIntExtra("android.media.EXTRA_VOLUME_STREAM_TYPE", -1) != AudioManager.STREAM_MUSIC) return
                val v = i.getIntExtra("android.media.EXTRA_VOLUME_STREAM_VALUE", -1)
                val pv = i.getIntExtra("android.media.EXTRA_PREV_VOLUME_STREAM_VALUE", -1)
                val own = SystemClock.elapsedRealtime() - ownMuteAt < OWN_EVENT_MS
                if (i.action == "android.media.VOLUME_CHANGED_ACTION" && !own) {
                    val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                    index = when {
                        v > 0 -> v                                   // a raise unmutes: the real index
                        v == 0 && pv > 0 -> 0                        // lowered to nothing
                        else -> (index - 1).coerceAtLeast(0)         // "lower" on a muted stream
                    }.coerceAtMost(max)
                    gain = gainFor(am, index)
                    log("volume key: $pv -> $v, Waaiya's volume $index/$max (gain ${"%.2f".format(java.util.Locale.ROOT, gain)})")
                }
                main.postDelayed({ if (active) mute(am) }, 60)
            }
        }
        val filter = IntentFilter().apply {
            addAction("android.media.VOLUME_CHANGED_ACTION")
            addAction("android.media.STREAM_MUTE_CHANGED_ACTION")
        }
        if (android.os.Build.VERSION.SDK_INT >= 33) app.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
        else app.registerReceiver(receiver, filter)
        devices = object : AudioDeviceCallback() {
            override fun onAudioDevicesAdded(added: Array<out AudioDeviceInfo>) = changed("added", added)
            override fun onAudioDevicesRemoved(removed: Array<out AudioDeviceInfo>) = changed("removed", removed)
            private fun changed(what: String, d: Array<out AudioDeviceInfo>) {
                if (!active || d.none { it.isSink }) return
                log("output $what: ${d.filter { it.isSink }.joinToString { typeName(it.type) }}")
                main.postDelayed({ if (active) mute(am) }, 300)
            }
        }
        am.registerAudioDeviceCallback(devices, main)
    }

    /** Filtering ended (Stop, or the service ends): media sound back as it was. Main thread. */
    fun end(ctx: Context) {
        val app = ctx.applicationContext
        val am = app.getSystemService(AudioManager::class.java)
        receiver?.let { runCatching { app.unregisterReceiver(it) } }; receiver = null
        devices?.let { runCatching { am.unregisterAudioDeviceCallback(it) } }; devices = null
        if (active) log("end")
        active = false
        unmuteIfOurs(app)
    }

    /** A new process (after a crash or a kill while muted): give the media sound back. */
    fun restore(ctx: Context) {
        if (!active) unmuteIfOurs(ctx.applicationContext)
    }

    private fun unmuteIfOurs(app: Context) {
        if (!prefs(app).getBoolean(KEY_MUTED, false)) return
        runCatching {
            app.getSystemService(AudioManager::class.java)
                .adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_UNMUTE, 0)
        }.onFailure { Log.e(TAG, "simple mode: could not unmute media", it) }
        prefs(app).edit().remove(KEY_MUTED).commit()
    }

    private fun mute(am: AudioManager) {
        if (am.isStreamMute(AudioManager.STREAM_MUSIC)) return
        ownMuteAt = SystemClock.elapsedRealtime()
        runCatching { am.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_MUTE, 0) }
            .onFailure { log("could not mute media: $it") }
        remutes++
    }

    /** Media volume index -> amplitude, roughly Android's media curve (about -45 dB at the lowest step). */
    private fun gainFor(am: AudioManager, idx: Int): Float {
        val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
        if (idx <= 0) return 0f
        val db = -45.0 * (1.0 - idx.toDouble() / max)
        return 10.0.pow(db / 20.0).toFloat()
    }

    private fun log(s: String) {
        Log.i(TAG, "simple mode: $s")
        synchronized(events) {
            events.addLast("${java.text.SimpleDateFormat("HH:mm:ss", java.util.Locale.ROOT).format(java.util.Date())} $s")
            while (events.size > 12) events.removeFirst()
        }
    }

    private fun typeName(t: Int) = when (t) {
        AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "speaker"
        AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> "earpiece"
        AudioDeviceInfo.TYPE_WIRED_HEADPHONES, AudioDeviceInfo.TYPE_WIRED_HEADSET -> "wired"
        AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "Bluetooth (A2DP)"
        AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> "Bluetooth (call)"
        AudioDeviceInfo.TYPE_USB_HEADSET, AudioDeviceInfo.TYPE_USB_DEVICE -> "USB"
        26 /* TYPE_BLE_HEADSET */, 27 /* TYPE_BLE_SPEAKER */ -> "Bluetooth LE"
        AudioDeviceInfo.TYPE_HDMI -> "HDMI"
        AudioDeviceInfo.TYPE_TELEPHONY -> "telephony"
        AudioDeviceInfo.TYPE_REMOTE_SUBMIX -> "screen-share mix"
        else -> "type $t"
    }

    /** The diagnostics report's section: everything a test on a real phone needs to be read from the report. */
    fun report(ctx: Context): String = buildString {
        val s = Settings(ctx)
        val am = ctx.getSystemService(AudioManager::class.java)
        val nm = ctx.getSystemService(NotificationManager::class.java)
        appendLine("Simple mode (test): ${if (s.simpleMode) "on" else "off"}, channel ${s.simpleChannel}, " +
            "running ${if (active) "yes" else "no"}")
        if (!s.simpleMode && !active) return@buildString
        fun vol(stream: Int) = "${am.getStreamVolume(stream)}/${am.getStreamMaxVolume(stream)}" +
            if (am.isStreamMute(stream)) " muted" else ""
        appendLine("  media ${vol(AudioManager.STREAM_MUSIC)}, alarm ${vol(AudioManager.STREAM_ALARM)}, " +
            "notification ${vol(AudioManager.STREAM_NOTIFICATION)}, ring ${vol(AudioManager.STREAM_RING)}")
        appendLine("  Waaiya's volume $index (gain ${"%.2f".format(java.util.Locale.ROOT, gain)}), muted again $remutes time(s), " +
            "media muted by Waaiya: ${if (prefs(ctx).getBoolean(KEY_MUTED, false)) "yes" else "no"}")
        appendLine("  ringer ${when (am.ringerMode) { AudioManager.RINGER_MODE_SILENT -> "silent"
            AudioManager.RINGER_MODE_VIBRATE -> "vibrate"; else -> "normal" }}, Do Not Disturb " +
            when (nm.currentInterruptionFilter) { NotificationManager.INTERRUPTION_FILTER_ALL -> "off"
                NotificationManager.INTERRUPTION_FILTER_PRIORITY -> "priority only"
                NotificationManager.INTERRUPTION_FILTER_ALARMS -> "alarms only"
                NotificationManager.INTERRUPTION_FILTER_NONE -> "total silence"; else -> "unknown" })
        val outs = am.getDevices(AudioManager.GET_DEVICES_OUTPUTS).map { typeName(it.type) }.distinct()
        appendLine("  outputs: ${outs.joinToString()}; Waaiya's sound goes to: ${routed?.let { typeName(it.type) } ?: "unknown"}")
        synchronized(events) { events.forEach { appendLine("  $it") } }
    }
}
