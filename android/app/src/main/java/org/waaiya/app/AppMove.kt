package org.waaiya.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Binder
import android.os.Bundle
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * Waaiya moved from org.islamicmute.app to org.waaiya.app in 0.2.15 (docs/MOVE.md). Android treats the two as
 * different apps, so the move takes three steps, each offered on screen (feature `move`):
 *
 * 1. The old app's last version (built with -PimMoveBuild: [BuildConfig.MOVE_BUILD]) offers to install the new app.
 *    It uses the in-app update's download and checks (AppUpdate: the new app's release file, its package, the release
 *    certificate) and Android's installer.
 * 2. The new app, on its first start, takes the old app's settings (settings, protection, worship) from the old app's
 *    [MoveProvider], which only an app signed with the same certificate may call (permission
 *    org.waaiya.permission.MOVE, protection level signature). The one-time setup must be done again: Android's
 *    permissions belong to a package.
 * 3. Both offer to remove the old app, so that the two never filter at the same time.
 */
object AppMove : Feature {
    override val name = "move"
    private const val TAG = "WaaiyaMove"
    private const val PREFS = "app_move"
    /** The preference files that move: what the user chose. Not moved: setup, pairing, update and simple-mode state,
     *  which belong to this installation. */
    val MOVED_PREFS = listOf("settings", "protect", "worship")
    private const val CHANNEL = "updates"
    private const val NOTIFICATION_ID = 4711

    private fun prefs(c: Context) = c.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun installed(c: Context, pkg: String): Boolean =
        runCatching { c.packageManager.getPackageInfo(pkg, 0); true }.getOrDefault(false)

    /** The other side of the move on this phone: the new app (in the old one) or the old app (in the new one). */
    private fun other(): String = if (BuildConfig.MOVE_BUILD) BuildConfig.NEW_ID else BuildConfig.OLD_ID

    override fun snapshot(host: FeatureHost): Map<String, Any?> {
        val c = host.activity
        if (BuildConfig.MOVE_BUILD) {
            return mapOf("supported" to true, "kind" to "old", "newInstalled" to installed(c, BuildConfig.NEW_ID))
        }
        if (!installed(c, BuildConfig.OLD_ID)) return mapOf("supported" to false)
        return mapOf("supported" to true, "kind" to "new", "imported" to prefs(c).getBoolean("imported", false))
    }

    override fun call(host: FeatureHost, method: String, args: Map<String, Any?>): Any? {
        val c = host.activity
        when (method) {
            "openNew" -> {
                val i = c.packageManager.getLaunchIntentForPackage(BuildConfig.NEW_ID)
                    ?: throw FeatureException("failed", "the new Waaiya is not installed")
                c.startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            }
            // Android asks the user; the old app may be removed from either side (in the old app: itself)
            "removeOld" -> {
                if (!installed(c, BuildConfig.OLD_ID)) throw FeatureException("failed", "the old Waaiya is not installed")
                // removing the old app stops its filter: the same gate as Stop there
                if (BuildConfig.MOVE_BUILD && FilterService.running) Protection.checkStop(c)
                @Suppress("DEPRECATION")
                c.startActivity(Intent(Intent.ACTION_DELETE, Uri.parse("package:${BuildConfig.OLD_ID}"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            }
            else -> throw FeatureException("unsupported", "move.$method")
        }
        host.refresh()
        return null
    }

    /**
     * At every start of the process. The new app: take the old app's settings once, if it has none of its own yet.
     * The old app's last version: say once, in a notification, that Waaiya has moved.
     */
    fun onStart(c: Context) {
        if (BuildConfig.MOVE_BUILD) { notifyOnce(c); return }
        val p = prefs(c)
        if (p.getBoolean("tried", false) || !installed(c, BuildConfig.OLD_ID)) return
        val out = runCatching { importFromOld(c) }
        out.onFailure { Log.w(TAG, "import: $it") }  // an old app before 0.2.15 has no provider: nothing to take
        p.edit().putBoolean("tried", true).putBoolean("imported", out.getOrDefault(false)).apply()
    }

    private fun importFromOld(c: Context): Boolean {
        // never over settings the user already made in the new app
        if (c.getSharedPreferences("settings", Context.MODE_PRIVATE).all.isNotEmpty()) return false
        val b = c.contentResolver.call(Uri.parse("content://${BuildConfig.OLD_ID}.move"), "export", null, null)
            ?: return false
        val json = JSONObject(b.getString("prefs") ?: return false)
        apply(c, json)
        Log.i(TAG, "settings taken from ${BuildConfig.OLD_ID}: ${json.keys().asSequence().toList()}")
        return true
    }

    /** Preference files as JSON: {file: {key: [type, value]}}; sets become arrays. */
    fun export(c: Context): JSONObject {
        val all = JSONObject()
        for (f in MOVED_PREFS) {
            val o = JSONObject()
            for ((k, v) in c.getSharedPreferences(f, Context.MODE_PRIVATE).all) {
                val e = when (v) {
                    is Boolean -> JSONArray().put("b").put(v)
                    is Int -> JSONArray().put("i").put(v)
                    is Long -> JSONArray().put("l").put(v)
                    is Float -> JSONArray().put("f").put(v.toDouble())
                    is String -> JSONArray().put("s").put(v)
                    is Set<*> -> JSONArray().put("ss").put(JSONArray(v.map { it.toString() }))
                    else -> null
                } ?: continue
                o.put(k, e)
            }
            all.put(f, o)
        }
        return all
    }

    fun apply(c: Context, all: JSONObject) {
        for (f in MOVED_PREFS) {
            val o = all.optJSONObject(f) ?: continue
            val ed = c.getSharedPreferences(f, Context.MODE_PRIVATE).edit()
            for (k in o.keys()) {
                val e = o.optJSONArray(k) ?: continue
                when (e.optString(0)) {
                    "b" -> ed.putBoolean(k, e.optBoolean(1))
                    "i" -> ed.putInt(k, e.optInt(1))
                    "l" -> ed.putLong(k, e.optLong(1))
                    "f" -> ed.putFloat(k, e.optDouble(1).toFloat())
                    "s" -> ed.putString(k, e.optString(1))
                    "ss" -> ed.putStringSet(k, e.optJSONArray(1)?.let { a -> (0 until a.length()).map { a.optString(it) }.toSet() } ?: emptySet())
                }
            }
            ed.commit()
        }
    }

    /** The old app's last version: "Waaiya has moved", once (at the first start after the update, or the daily check). */
    fun notifyOnce(c: Context) {
        val p = prefs(c)
        if (p.getBoolean("notified", false) || installed(c, BuildConfig.NEW_ID)) return
        val nm = c.getSystemService(NotificationManager::class.java)
        if (!nm.areNotificationsEnabled()) return
        nm.createNotificationChannel(NotificationChannel(CHANNEL, c.getString(R.string.notif_update_channel), NotificationManager.IMPORTANCE_DEFAULT))
        val pi = PendingIntent.getActivity(c, NOTIFICATION_ID, UiActivity.main(c).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        nm.notify(NOTIFICATION_ID, Notification.Builder(c, CHANNEL)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(c.getString(R.string.notif_move_title))
            .setContentText(c.getString(R.string.notif_move_text))
            .setStyle(Notification.BigTextStyle().bigText(c.getString(R.string.notif_move_text)))
            .setContentIntent(pi).setAutoCancel(true).build())
        p.edit().putBoolean("notified", true).apply()
    }
}

/**
 * In the old app's last version only (declared by src/move/AndroidManifest.xml): hands the user's settings to the new
 * app. Android lets only apps holding org.waaiya.permission.MOVE call it, a signature permission: the new Waaiya,
 * signed with the same certificate. The caller is checked again here.
 */
class MoveProvider : ContentProvider() {
    override fun onCreate() = true

    override fun call(method: String, arg: String?, extras: Bundle?): Bundle? {
        val c = context ?: return null
        val caller = c.packageManager.getPackagesForUid(Binder.getCallingUid())?.toList().orEmpty()
        if (BuildConfig.NEW_ID !in caller ||
            c.packageManager.checkSignatures(c.packageName, BuildConfig.NEW_ID) != PackageManager.SIGNATURE_MATCH) {
            throw SecurityException("not the new Waaiya")
        }
        if (method != "export") return null
        return Bundle().apply { putString("prefs", AppMove.export(c).toString()) }
    }

    override fun query(uri: Uri, p: Array<out String>?, s: String?, a: Array<out String>?, o: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, s: String?, a: Array<out String>?) = 0
    override fun update(uri: Uri, v: ContentValues?, s: String?, a: Array<out String>?) = 0
}
