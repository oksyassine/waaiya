package org.islamicmute.app

import android.content.Context
import com.chaquo.python.PyException
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import org.json.JSONObject
import java.io.File

/** Page link (YouTube, TikTok, ...) to media streams, through yt-dlp in the bundled Python (src/main/python/im_links.py). */
object Links {
    data class Stream(val url: String, val headers: Map<String, String>, val height: Int?, val ext: String?, val size: Long?)
    data class Resolved(
        val title: String, val durationSec: Double?, val isLive: Boolean, val site: String, val thumbnail: String?,
        /** Either [video] + [audio] (separate streams), or [progressive] (one file with both), or [audio] only. */
        val video: Stream?, val audio: Stream?, val progressive: Stream?,
    )

    /** Message is meant for the user. */
    class LinkException(message: String) : Exception(message)

    /** Text that a share from another app carries: the first http(s) link in it, or null. */
    fun findLink(text: CharSequence?): String? =
        text?.let { Regex("""https?://\S+""").find(it)?.value?.trimEnd('.', ',', ')', '"', '\'') }

    private fun python(ctx: Context): Python {
        if (!Python.isStarted()) Python.start(AndroidPlatform(ctx.applicationContext))
        return Python.getInstance()
    }

    /** Blocking (network + JavaScript): call off the main thread. */
    fun resolve(ctx: Context, url: String): Resolved {
        val qjs = File(ctx.applicationInfo.nativeLibraryDir, "libqjs.so").path
        val cache = File(ctx.cacheDir, "links").apply { mkdirs() }.path
        val json = try {
            python(ctx).getModule("im_links").callAttr("resolve", url, qjs, cache).toString()
        } catch (e: PyException) {
            val m = e.message ?: ""
            throw LinkException(if (m.startsWith("LinkError: ")) m.removePrefix("LinkError: ") else "Could not open this link.\n$m")
        }
        val o = JSONObject(json)
        fun stream(k: String): Stream? = o.optJSONObject(k)?.let { s ->
            val h = s.optJSONObject("headers")
            Stream(s.getString("url"), h?.keys()?.asSequence()?.associateWith { h.getString(it) } ?: emptyMap(),
                s.optInt("height").takeIf { s.has("height") && !s.isNull("height") }, s.optString("ext").ifEmpty { null },
                s.optLong("size").takeIf { s.has("size") && !s.isNull("size") })
        }
        return Resolved(o.optString("title"), o.optDouble("duration").takeIf { !it.isNaN() }, o.optBoolean("is_live"),
            o.optString("site"), o.optString("thumbnail").ifEmpty { null }, stream("video"), stream("audio"), stream("progressive"))
    }

    fun ytDlpVersion(ctx: Context): String = python(ctx).getModule("im_links").callAttr("version").toString()
}
