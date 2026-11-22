package org.waaiya.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.SmsManager
import android.telephony.TelephonyManager
import android.util.Log
import java.time.Instant

/**
 * "Reply to calls by SMS during prayer" (owner's request, 2026-11-20): a call left ringing for the chosen seconds
 * inside a prayer window gets one SMS, "It's prayer time, I can't answer now..." or the user's own text. The rules
 * are in [WorshipSmsRules].
 *
 * How the number is known (checked on developer.android.com, 2026-11-20): a call-screening app (CallScreeningService
 * with the call-screening role) is only called for numbers that are NOT in the contacts, which would leave out the
 * family and friends who call most. So Waaiya listens to the phone-state broadcast (READ_PHONE_STATE), whose copy
 * with the caller's number is only sent to apps that also hold READ_CALL_LOG. SEND_SMS sends the reply.
 * All three are asked only when the user turns the option on, one after another, each after one sentence saying why
 * (worship.dart). Google Play restricts SMS and call-log permissions, so a `-PimPlay` build leaves this whole option
 * out: the permissions and [WorshipCallReceiver] are in src/smsReply/AndroidManifest.xml, added only to other builds,
 * and [supported] is false there.
 */
object WorshipSms {
    private const val TAG = "WorshipSms"
    const val ACTION_CHECK = "org.waaiya.app.worship.SMS_CHECK"
    private const val NOTIF_SMS = 7303
    private const val MAX_LOG = 20

    private fun prefs(ctx: Context) = ctx.getSharedPreferences("worship", Context.MODE_PRIVATE)

    /** False in a build without the SMS reply (Play): the card hides the option. */
    fun supported(ctx: Context): Boolean = runCatching {
        ctx.packageManager.getPackageInfo(ctx.packageName, PackageManager.GET_PERMISSIONS)
            .requestedPermissions?.contains(android.Manifest.permission.SEND_SMS) == true
    }.getOrDefault(false)

    val PHONE_PERMISSIONS = arrayOf(android.Manifest.permission.READ_PHONE_STATE, android.Manifest.permission.READ_CALL_LOG)
    val SMS_PERMISSIONS = arrayOf(android.Manifest.permission.SEND_SMS)

    private fun granted(ctx: Context, perms: Array<String>) =
        perms.all { ctx.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED }

    fun phoneAllowed(ctx: Context) = granted(ctx, PHONE_PERMISSIONS)
    fun smsAllowed(ctx: Context) = granted(ctx, SMS_PERMISSIONS)

    fun roaming(ctx: Context): Boolean =
        runCatching { ctx.getSystemService(TelephonyManager::class.java).isNetworkRoaming }.getOrDefault(false)

    /** The prayer window now (its prayer time), or null. */
    private fun window(ctx: Context, st: Settings, now: Long): Long? {
        val place = WorshipCities.place(st.prayerPlace, Worship.cities(ctx)) ?: return null
        val prayers = WorshipAlarms.prayersAround(Instant.ofEpochMilli(now), place, st.prayerMethod, st.prayerAsr)
        return WorshipSmsRules.window(now, prayers, st.prayerSilentMinutes)
    }

    /** A phone-state broadcast: remember a ringing call, forget it once answered or ended, check after the delay. */
    fun onPhoneState(ctx: Context, state: String?, number: String?, pending: BroadcastReceiver.PendingResult?) {
        val p = prefs(ctx)
        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                val st = Settings(ctx)
                val now = System.currentTimeMillis()
                if (!st.prayerSmsReply || number == null || window(ctx, st, now) == null) { pending?.finish(); return }
                // the broadcast comes twice (without and with the number): keep the first ringing time
                val since = if (p.getString("ring_number", null) == number) p.getLong("ring_since", now) else now
                p.edit().putString("ring_number", number).putLong("ring_since", since).apply()
                val at = since + st.prayerSmsDelaySeconds * 1000L
                if (WorshipAlarms.exactAllowed(ctx)) {
                    runCatching {
                        ctx.getSystemService(AlarmManager::class.java)
                            .setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, checkIntent(ctx))
                    }
                    pending?.finish()
                } else {
                    // no exact alarms: wait in this broadcast (a receiver may take a few seconds), then check
                    Handler(Looper.getMainLooper()).postDelayed({
                        runCatching { check(ctx) }
                        pending?.finish()
                    }, (at - now).coerceIn(0, 9_000))
                }
            }
            else -> {  // answered (OFFHOOK) or ended (IDLE): nothing to send
                p.edit().remove("ring_number").remove("ring_since").apply()
                ctx.getSystemService(AlarmManager::class.java).cancel(checkIntent(ctx))
                pending?.finish()
            }
        }
    }

    private fun checkIntent(ctx: Context) = PendingIntent.getBroadcast(ctx, 5,
        Intent(ctx, WorshipReceiver::class.java).setAction(ACTION_CHECK),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

    /** The delay is over: send if the call still rings, inside a prayer window, to a number not answered yet. */
    @Synchronized
    fun check(ctx: Context) {
        val p = prefs(ctx)
        val st = Settings(ctx)
        val now = System.currentTimeMillis()
        val number = p.getString("ring_number", null)
        val ringing = number?.let { WorshipSmsRules.Ringing(it, p.getLong("ring_since", now)) }
        val window = window(ctx, st, now)
        val sent = if (window != null && p.getLong("sms_window", 0) == window)
            Settings.csv(p.getString("sms_sent", "")) else emptySet()
        val d = WorshipSmsRules.decide(st.prayerSmsReply && smsAllowed(ctx), now, ringing, st.prayerSmsDelaySeconds,
            window, sent, roaming(ctx))
        Log.i(TAG, "check: $d")
        if (d != WorshipSmsRules.Decision.SEND) return
        val to = WorshipSmsRules.normalize(number)!!
        val c = Lang.wrap(ctx)
        val text = st.prayerSmsText.ifBlank { c.getString(R.string.worship_sms_default) }
        val ok = runCatching {
            val sms = if (Build.VERSION.SDK_INT >= 31) ctx.getSystemService(SmsManager::class.java)
            else @Suppress("DEPRECATION") SmsManager.getDefault()
            sms.sendMultipartTextMessage(to, null, sms.divideMessage(text), null, null)
        }.onFailure { Log.w(TAG, "send", it) }.isSuccess
        if (!ok) return
        p.edit().putLong("sms_window", window!!).putString("sms_sent", (sent + to).sorted().joinToString(","))
            .putString("sms_log", (listOf("$now|$to") + log(ctx).map { "${it.first}|${it.second}" }).take(MAX_LOG)
                .joinToString("\n"))
            .remove("ring_number").remove("ring_since").apply()
        notify(c, to)
    }

    /** SMS sent, newest first: (epoch ms, number). Kept on the phone only. */
    fun log(ctx: Context): List<Pair<Long, String>> =
        prefs(ctx).getString("sms_log", "").orEmpty().lines().mapNotNull { l ->
            val i = l.indexOf('|')
            if (i <= 0) null else l.substring(0, i).toLongOrNull()?.let { it to l.substring(i + 1) }
        }

    private fun notify(c: Context, number: String) = runCatching {
        val nm = c.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(NotificationChannel(WorshipAlarms.CHANNEL, c.getString(R.string.notif_worship_channel),
            NotificationManager.IMPORTANCE_LOW))
        val open = UiActivity.open(c, "settings")?.let {
            PendingIntent.getActivity(c, 7300, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }
        val text = c.getString(R.string.notif_worship_sms_text).replace("{number}", number)
        nm.notify(NOTIF_SMS, Notification.Builder(c, WorshipAlarms.CHANNEL)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(c.getString(R.string.notif_worship_sms_title)).setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setContentIntent(open).setAutoCancel(true).build())
    }
}

/** The phone-state broadcast (a protected broadcast: only Android sends it). Declared in src/smsReply. */
class WorshipCallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return
        @Suppress("DEPRECATION")
        val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
        val pending = goAsync()
        runCatching { WorshipSms.onPhoneState(context, intent.getStringExtra(TelephonyManager.EXTRA_STATE), number, pending) }
            .onFailure { Log.w("WorshipSms", "phone state", it); pending.finish() }
    }
}
