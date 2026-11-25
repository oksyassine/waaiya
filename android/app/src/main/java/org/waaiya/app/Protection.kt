package org.waaiya.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.SystemClock
import android.util.Log
import org.json.JSONObject
import java.lang.ref.WeakReference

/**
 * Protection that survives a weak moment: a waiting period chosen in advance, and a local PIN (docs/FEATURES_CONTRACT.md,
 * lane B). Every path that switches protection off or weakens it asks here first and must not act when refused.
 * The rules, the clock and the PIN are in ProtectionCore.kt (JVM-tested); this is the Android side.
 *
 * Kept in the private preferences file "protect" (not "settings"): the PIN as PBKDF2 only, its wrong tries, and the
 * one pending request. A waiting period counts on elapsedRealtime with the boot count (Settings.Global.BOOT_COUNT):
 * a wall clock moved forward does not count, and after a reboot only the time since boot counts from the last
 * checkpoint (saved every minute while pending, and at shutdown while Waaiya's process is alive).
 *
 * What it cannot stop, and says so on the screen: force stop, uninstalling, clearing the app's data and Android's own
 * settings. That would need device-admin or accessibility powers Waaiya does not use.
 */
object Protection : Feature {
    override val name = "protect"

    private const val TAG = "Protection"
    private const val CHANNEL = "protect"
    private const val NOTIFICATION_ID = 7401
    const val ACTION_TICK = "org.waaiya.app.PROTECT_TICK"
    const val ACTION_DUE = "org.waaiya.app.PROTECT_DUE"
    const val ACTION_CANCEL = "org.waaiya.app.PROTECT_CANCEL"

    @Volatile private var core: ProtectionCore? = null
    @Volatile private var host: WeakReference<FeatureHost>? = null
    private var shutdownReceiver: BroadcastReceiver? = null

    /** A stop refused outside the app (notification, tile, shortcut): Flutter asks for it on the Settings page. */
    private var prompt: Map<String, Any?>? = null
    private var prompts = 0

    private class AndroidClock(private val ctx: Context) : ProtectionClock {
        override fun wallMs() = System.currentTimeMillis()
        override fun elapsedMs() = SystemClock.elapsedRealtime()
        override fun bootCount() = runCatching {
            android.provider.Settings.Global.getInt(ctx.contentResolver, android.provider.Settings.Global.BOOT_COUNT, -1)
        }.getOrDefault(-1)
    }

    private class PrefsStore(ctx: Context) : ProtectionStore {
        private val p = ctx.getSharedPreferences("protect", Context.MODE_PRIVATE)
        override fun get(key: String): String? = p.getString(key, null)
        // commit, not apply: a change of protection must be on disk before the call returns
        override fun put(key: String, value: String?) {
            if (value == null) p.edit().remove(key).commit() else p.edit().putString(key, value).commit()
        }
    }

    private fun core(context: Context): ProtectionCore = core ?: synchronized(this) {
        core ?: run {
            val ctx = context.applicationContext
            val settings = Settings(ctx)
            ProtectionCore(PrefsStore(ctx), AndroidClock(ctx), { settings.protectDelayMinutes }, { key -> current(settings, key) })
                .also { core = it }
        }
    }

    private fun current(s: Settings, key: String): Any? = when (key) {
        "blur_on" -> s.blurEnabled
        "blur_women" -> s.blurWomen
        "blur_nudity" -> s.blurNudity
        "blur_fail_cover" -> s.blurFailCover
        "silence_unfilterable" -> s.silenceUnfilterable
        "hold_silence" -> s.holdSilence
        "mute_women_singing" -> s.muteWomenSinging
        "keep_singing" -> s.keepSinging
        "blur_strictness" -> s.blurStrictness
        "filter_off_apps" -> s.filterOffApps.sorted().joinToString(",")
        "blur_off_apps" -> s.blurOffApps.sorted().joinToString(",")
        "gender" -> s.gender
        "protect_delay_minutes" -> s.protectDelayMinutes
        else -> null
    }

    /** Writes a change the guard allowed (only the keys ProtectionRules.KEYS holds), or stops the filter. */
    private fun apply(context: Context, a: ProtectionCore.Apply) {
        val ctx = context.applicationContext
        val s = Settings(ctx)
        val v = a.value
        when (a.what) {
            ProtectionCore.STOP -> if (FilterService.running || FilterService.state == FilterService.State.SILENCED)
                ctx.startService(Intent(ctx, FilterService::class.java).setAction(FilterService.ACTION_STOP))
            "blur_on" -> s.blurEnabled = v as Boolean
            "blur_women" -> s.blurWomen = v as Boolean
            "blur_nudity" -> s.blurNudity = v as Boolean
            "blur_fail_cover" -> s.blurFailCover = v as Boolean
            "silence_unfilterable" -> s.silenceUnfilterable = v as Boolean
            "hold_silence" -> s.holdSilence = v as Boolean
            "mute_women_singing" -> s.muteWomenSinging = v as Boolean
            "keep_singing" -> s.keepSinging = v as Boolean
            "blur_strictness" -> s.blurStrictness = v as Int
            "filter_off_apps" -> s.filterOffApps = ProtectionRules.csv(v as String)
            "blur_off_apps" -> s.blurOffApps = ProtectionRules.csv(v as String)
            "gender" -> s.gender = v as String
            "protect_delay_minutes" -> s.protectDelayMinutes = v as Int
        }
    }

    /** Diagnostics: a change waiting for the period or the PIN, in words; null when none. */
    fun pendingForReport(context: Context): String? = runCatching {
        val c = core(context)
        val p = c.pending() ?: return@runCatching null
        val left = p.left(AndroidClock(context))
        "${p.what} = ${p.value ?: ""}, " + if (left > 0) "applies in ${left / 60000} min" else "ready to confirm"
    }.getOrNull()

    /** The machine detail of a refusal, for Flutter's onProtected (protection.dart). */
    private fun detail(c: ProtectionCore, what: String, value: Any?, g: ProtectionRules.Gate, delay: Int): String {
        val o = JSONObject()
        val p = c.pending()
        val same = p != null && p.what == what && p.value == (if (what == ProtectionCore.STOP) null else ProtectionRules.normalize(what, value))
        o.put("need", when {
            same -> "waiting"
            g.pin && g.wait -> "pin_wait"
            g.pin -> "pin"
            else -> "wait"
        })
        o.put("what", what)
        o.put("value", value ?: JSONObject.NULL)
        o.put("delayMinutes", delay)
        if (same) o.put("dueAt", c.due(p!!))
        return o.toString()
    }

    /**
     * A setting change from any screen. Throws FeatureException("protected", detail) when the change weakens protection
     * and the waiting period or the PIN holds it back.
     */
    fun checkSetting(context: Context, key: String, value: Any?) {
        val c = core(context)
        val had = c.pending() != null
        val g = c.check(key, value)
        if (had && c.pending() == null) sync(context)
        if (g != null) throw FeatureException("protected", detail(c, key, value, g, Settings(context).protectDelayMinutes))
    }

    /** UiBridge's stopFilter: throws FeatureException("protected", detail) when stopping is held back. */
    fun checkStop(context: Context) {
        val c = core(context)
        val g = c.checkStop()
        sync(context)
        if (g != null) throw FeatureException("protected", detail(c, ProtectionCore.STOP, null, g, Settings(context).protectDelayMinutes))
    }

    /** Stopping the filter (screen button, notification Stop, Quick Settings tile). No side effect. */
    fun mayStopFilter(context: Context): Boolean = core(context).mayStop()

    /**
     * Stop from outside the app (notification, tile, app shortcut): stops when allowed (a ready stop request is
     * confirmed by it). Otherwise returns an intent that opens Waaiya's Settings page, where Flutter asks for the PIN
     * or offers the waiting period. Main thread.
     */
    fun stopOrAsk(context: Context): Intent? {
        val c = core(context)
        val g = c.checkStop()
        if (g == null) {
            sync(context)
            context.startService(Intent(context, FilterService::class.java).setAction(FilterService.ACTION_STOP))
            return null
        }
        val d = JSONObject(detail(c, ProtectionCore.STOP, null, g, Settings(context).protectDelayMinutes))
        prompt = mapOf("id" to ++prompts, "need" to d.getString("need"), "what" to ProtectionCore.STOP,
            "delayMinutes" to d.getInt("delayMinutes"), "dueAt" to d.optLong("dueAt").takeIf { it > 0 })
        refreshUi()
        return UiActivity.open(context, "settings") ?: UiActivity.main(context)
    }

    override fun snapshot(host: FeatureHost): Map<String, Any?> {
        this.host = WeakReference(host)
        return core(host.activity).snapshot() + ("prompt" to prompt)
    }

    override fun call(host: FeatureHost, method: String, args: Map<String, Any?>): Any? {
        val ctx = host.activity
        val c = core(ctx)
        fun str(name: String) = args[name] as? String
        val out = try {
            when (method) {
                "request" -> c.request(str("what") ?: throw FeatureException("bad_args", "what"), args["value"], str("pin"))
                "setPin" -> c.setPin(str("pin"), str("oldPin"))
                "clearPin" -> c.clearPin(str("pin"))
                "cancel" -> { c.cancel(); ProtectionCore.Outcome(ProtectionCore.DONE) }
                "confirm" -> c.confirm()
                "promptShown" -> { prompt = null; ProtectionCore.Outcome(ProtectionCore.DONE) }
                else -> throw FeatureException("unsupported", "protect.$method")
            }
        } catch (e: IllegalArgumentException) {
            throw FeatureException("bad_args", e.message ?: "bad arguments")
        }
        out.apply?.let { apply(ctx, it) }
        sync(ctx)
        host.refresh()
        return out.toMap()
    }

    private fun refreshUi() { host?.get()?.refresh() }

    // --- alarms and the notification ---

    /** Saves the time left and brings the alarms and the notification in line with the pending request. */
    fun sync(context: Context) {
        val ctx = context.applicationContext
        val c = core(ctx)
        c.checkpoint()
        val p = c.pending()
        val am = ctx.getSystemService(AlarmManager::class.java)
        val nm = ctx.getSystemService(NotificationManager::class.java)
        if (p == null) {
            runCatching { am.cancel(broadcast(ctx, ACTION_TICK)); am.cancel(broadcast(ctx, ACTION_DUE)) }
            runCatching { nm.cancel(NOTIFICATION_ID) }
            shutdownReceiver?.let { runCatching { ctx.unregisterReceiver(it) } }
            shutdownReceiver = null
            return
        }
        val left = p.left(AndroidClock(ctx))
        val now = SystemClock.elapsedRealtime()
        runCatching {
            // a checkpoint every minute (inexact, not waking the phone: time lost to a missed tick only lengthens the wait)
            am.set(AlarmManager.ELAPSED_REALTIME, now + 60_000, broadcast(ctx, ACTION_TICK))
            // the end of the wait, then the end of the time to confirm: the notification changes
            val next = if (left > 0) left else left + ProtectionRules.CONFIRM_MS
            am.setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, now + next.coerceAtLeast(1000), broadcast(ctx, ACTION_DUE))
        }.onFailure { Log.w(TAG, "alarms: $it") }
        if (shutdownReceiver == null) {
            // Android sends the shutdown only to receivers registered at run time
            val r = object : BroadcastReceiver() {
                override fun onReceive(c: Context, i: Intent) { runCatching { core(c).checkpoint() } }
            }
            runCatching { ctx.registerReceiver(r, IntentFilter(Intent.ACTION_SHUTDOWN)); shutdownReceiver = r }
        }
        notify(ctx, p, left)
    }

    private fun broadcast(ctx: Context, action: String): PendingIntent =
        PendingIntent.getBroadcast(ctx, 7401 + listOf(ACTION_TICK, ACTION_DUE, ACTION_CANCEL).indexOf(action),
            Intent(action).setClass(ctx, ProtectionReceiver::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

    private fun notify(context: Context, p: ProtectionCore.Pending, left: Long) {
        val ctx = Lang.wrap(context)
        runCatching {
            val nm = ctx.getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(NotificationChannel(CHANNEL, ctx.getString(R.string.notif_protect_channel),
                NotificationManager.IMPORTANCE_DEFAULT).apply { setSound(null, null); setShowBadge(false) })
            val wall = System.currentTimeMillis()
            fun hm(at: Long) = android.text.format.DateFormat.getTimeFormat(ctx).format(java.util.Date(at))
            val what = ctx.getString(when (p.what) {
                ProtectionCore.STOP -> R.string.notif_protect_what_stop
                ProtectionCore.PIN_CHANGE, ProtectionCore.PIN_CLEAR -> R.string.notif_protect_what_pin
                else -> R.string.notif_protect_what_setting
            })
            val text = if (left > 0) ctx.getString(R.string.notif_protect_waiting_text, hm(wall + left))
            else ctx.getString(R.string.notif_protect_ready_text, hm(wall + left + ProtectionRules.CONFIRM_MS))
            val open = PendingIntent.getActivity(ctx, 7405, UiActivity.open(ctx, "settings") ?: UiActivity.main(ctx),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
            nm.notify(NOTIFICATION_ID, Notification.Builder(ctx, CHANNEL)
                .setContentTitle(what)
                .setContentText(text)
                .setStyle(Notification.BigTextStyle().bigText(text))
                .setSmallIcon(R.drawable.ic_notification)
                .setColor(ctx.getColor(R.color.primary))
                .setContentIntent(open)
                .setOnlyAlertOnce(left > 0)  // the "still want it?" moment alerts once
                .setOngoing(true)
                .addAction(Notification.Action.Builder(null, ctx.getString(R.string.notif_protect_cancel),
                    broadcast(ctx, ACTION_CANCEL)).build())
                .build())
        }.onFailure { Log.w(TAG, "notification: $it") }
    }

    /** From [ProtectionReceiver]: a tick, the end of a wait, Cancel, a boot or an update. */
    fun onAlarm(context: Context, action: String?) {
        if (action == ACTION_CANCEL) core(context).cancel()
        sync(context)
        refreshUi()
    }
}

/** Waaiya's own alarms and the notification's Cancel (not exported). */
class ProtectionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        runCatching { Protection.onAlarm(context, intent.action) }
    }
}

/** After a boot or an update the alarms are set again and the notification comes back (protected broadcasts). */
class ProtectionSystemReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED ->
                runCatching { Protection.onAlarm(context, null) }
        }
    }
}
