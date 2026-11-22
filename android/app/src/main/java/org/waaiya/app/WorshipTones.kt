package org.waaiya.app

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import android.util.Log

/**
 * Plain tones (docs/ROADMAP.md item 9): the ringtone and the notification sound are played by Android itself and
 * cannot be filtered, only replaced. Waaiya ships a few plain tones (res/raw/worship_*.ogg, made by
 * scripts/make_tones.py, CC0) and sets one as the default: copied into the phone's Ringtones or Notifications folder
 * (MediaStore, no storage permission needed for the app's own files from Android 10), then set with
 * RingtoneManager, which needs "Modify system settings" (WRITE_SETTINGS, a page in Android's settings). If the
 * phone refuses, the card opens the Sound settings instead.
 */
object WorshipTones {
    private const val TAG = "WorshipTones"

    /** [kind] is `ring` or `notification`; [number] is what the screen calls it ("Plain ringtone 1"). */
    class Tone(val id: String, val kind: String, val number: Int, val res: Int) {
        val fileName get() = "Waaiya plain ${if (kind == "ring") "ringtone" else "notification"} $number.ogg"
    }

    val ALL = listOf(
        Tone("ring_1", "ring", 1, R.raw.worship_ring_1),
        Tone("ring_2", "ring", 2, R.raw.worship_ring_2),
        Tone("ring_3", "ring", 3, R.raw.worship_ring_3),
        Tone("notification_1", "notification", 1, R.raw.worship_notification_1),
        Tone("notification_2", "notification", 2, R.raw.worship_notification_2),
        Tone("notification_3", "notification", 3, R.raw.worship_notification_3),
    )

    fun find(id: String?): Tone = ALL.firstOrNull { it.id == id } ?: throw FeatureException("bad_args", "tone $id")

    private var player: MediaPlayer? = null

    /** Plays [id] once, at the ring or notification volume (as Android's own sound picker does). */
    @Synchronized
    fun preview(ctx: Context, id: String?) {
        val t = find(id)
        stop()
        val p = MediaPlayer()
        try {
            p.setAudioAttributes(AudioAttributes.Builder()
                .setUsage(if (t.kind == "ring") AudioAttributes.USAGE_NOTIFICATION_RINGTONE else AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
            ctx.resources.openRawResourceFd(t.res).use { p.setDataSource(it.fileDescriptor, it.startOffset, it.length) }
            p.setOnCompletionListener { synchronized(this) { it.release(); if (player === it) player = null } }
            p.prepare()
            p.start()
            player = p
        } catch (e: Exception) {
            p.release()
            throw FeatureException("failed", "preview: ${e.message}")
        }
    }

    @Synchronized
    fun stop() {
        player?.let { runCatching { it.stop() }; it.release() }
        player = null
    }

    fun canWriteSettings(ctx: Context): Boolean = android.provider.Settings.System.canWrite(ctx)

    /**
     * Sets [id] as the default ringtone or notification sound. `set`; `needs_permission` (the "Modify system
     * settings" page was opened: tap again after allowing); `failed` (the phone refused: the card offers the Sound
     * settings).
     */
    fun set(ctx: Context, id: String?): String {
        val t = find(id)
        if (!canWriteSettings(ctx)) {
            ctx.startActivity(Intent(android.provider.Settings.ACTION_MANAGE_WRITE_SETTINGS,
                Uri.parse("package:${ctx.packageName}")).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            return "needs_permission"
        }
        return runCatching {
            val uri = mediaUri(ctx, t)
            RingtoneManager.setActualDefaultRingtoneUri(ctx, type(t), uri)
            ctx.getSharedPreferences("worship", Context.MODE_PRIVATE).edit()
                .putString("tone_${t.kind}", t.id).putString("tone_${t.kind}_uri", uri.toString()).apply()
            "set"
        }.getOrElse { Log.w(TAG, "set ${t.id}", it); "failed" }
    }

    private fun type(t: Tone) = if (t.kind == "ring") RingtoneManager.TYPE_RINGTONE else RingtoneManager.TYPE_NOTIFICATION

    /** The tone of [kind] that is the phone's default now, if it is one of Waaiya's; "" otherwise. */
    fun current(ctx: Context, kind: String): String = runCatching {
        val p = ctx.getSharedPreferences("worship", Context.MODE_PRIVATE)
        val id = p.getString("tone_$kind", null) ?: return ""
        val ours = p.getString("tone_${kind}_uri", null) ?: return ""
        val now = RingtoneManager.getActualDefaultRingtoneUri(ctx,
            if (kind == "ring") RingtoneManager.TYPE_RINGTONE else RingtoneManager.TYPE_NOTIFICATION)
        if (now?.toString() == ours) id else ""
    }.getOrDefault("")

    /** The tone's entry in the phone's Ringtones or Notifications folder, added the first time. */
    private fun mediaUri(ctx: Context, t: Tone): Uri {
        val cr = ctx.contentResolver
        val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val dir = (if (t.kind == "ring") Environment.DIRECTORY_RINGTONES else Environment.DIRECTORY_NOTIFICATIONS) + "/"
        cr.query(collection, arrayOf(MediaStore.Audio.Media._ID),
            "${MediaStore.Audio.Media.DISPLAY_NAME}=? AND ${MediaStore.Audio.Media.RELATIVE_PATH}=?",
            arrayOf(t.fileName, dir), null)?.use { c ->
            if (c.moveToFirst()) return android.content.ContentUris.withAppendedId(collection, c.getLong(0))
        }
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, t.fileName)
            put(MediaStore.Audio.Media.TITLE, t.fileName.removeSuffix(".ogg"))
            put(MediaStore.Audio.Media.MIME_TYPE, "audio/ogg")
            put(MediaStore.Audio.Media.RELATIVE_PATH, dir)
            put(MediaStore.Audio.Media.IS_RINGTONE, t.kind == "ring")
            put(MediaStore.Audio.Media.IS_NOTIFICATION, t.kind == "notification")
            put(MediaStore.Audio.Media.IS_ALARM, false)
            put(MediaStore.Audio.Media.IS_MUSIC, false)
            put(MediaStore.Audio.Media.IS_PENDING, 1)
        }
        val uri = cr.insert(collection, values) ?: throw IllegalStateException("MediaStore refused the tone")
        try {
            cr.openOutputStream(uri)!!.use { out -> ctx.resources.openRawResource(t.res).use { it.copyTo(out) } }
            cr.update(uri, ContentValues().apply { put(MediaStore.Audio.Media.IS_PENDING, 0) }, null, null)
        } catch (e: Exception) {
            runCatching { cr.delete(uri, null, null) }
            throw e
        }
        return uri
    }
}
