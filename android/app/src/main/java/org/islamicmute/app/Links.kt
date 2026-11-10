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
    ) {
        fun streams() = Streams(video, audio, progressive)
        val hasVideo get() = video != null || progressive != null
    }

    /** The part of [Resolved] the player and the exporter need. */
    data class Streams(val video: Stream?, val audio: Stream?, val progressive: Stream?)

    fun streamsJson(st: Streams): String = JSONObject().apply {
        fun put(k: String, s: Stream?) { if (s != null) put(k, JSONObject().put("url", s.url).put("headers", JSONObject(s.headers))
            .put("height", s.height ?: JSONObject.NULL).put("ext", s.ext ?: JSONObject.NULL).put("size", s.size ?: JSONObject.NULL)) }
        put("video", st.video); put("audio", st.audio); put("progressive", st.progressive)
    }.toString()

    fun streamsFromJson(json: String): Streams = JSONObject(json).let { Streams(stream(it, "video"), stream(it, "audio"), stream(it, "progressive")) }

    private fun stream(o: JSONObject, k: String): Stream? = o.optJSONObject(k)?.let { s ->
        val h = s.optJSONObject("headers")
        Stream(s.getString("url"), h?.keys()?.asSequence()?.associateWith { h.getString(it) } ?: emptyMap(),
            s.optInt("height").takeIf { s.has("height") && !s.isNull("height") }, s.optString("ext").takeIf { s.has("ext") && !s.isNull("ext") },
            s.optLong("size").takeIf { s.has("size") && !s.isNull("size") })
    }

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
            // Python's LinkError("code", detail): message reads "LinkError: ('code', 'detail')" or "LinkError: code"
            val m = e.message ?: ""
            val code = Regex("""^LinkError: \(?'?(\w+)""").find(m)?.groupValues?.get(1)
            val res = when (code) {
                "invalid_url" -> R.string.link_invalid
                "login" -> R.string.link_login
                "unsupported_site" -> R.string.link_unsupported
                "playlist" -> R.string.link_playlist
                "no_format" -> R.string.link_no_format
                else -> R.string.link_failed
            }
            android.util.Log.w("IslamicMute", "link: $m")
            throw LinkException(ctx.getString(res))
        }
        val o = JSONObject(json)
        return Resolved(o.optString("title"), o.optDouble("duration").takeIf { !it.isNaN() }, o.optBoolean("is_live"),
            o.optString("site"), o.optString("thumbnail").ifEmpty { null }, stream(o, "video"), stream(o, "audio"), stream(o, "progressive"))
    }

    fun ytDlpVersion(ctx: Context): String = python(ctx).getModule("im_links").callAttr("version").toString()
}
