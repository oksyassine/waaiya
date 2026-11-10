package org.islamicmute.app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.ScrollView
import android.widget.TextView
import kotlin.concurrent.thread

/** Paste or share a link (spike: resolves it and shows what was found). */
class LinkActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val out = TextView(this).apply { setPadding(48, 160, 48, 48); setTextIsSelectable(true) }
        setContentView(ScrollView(this).apply { addView(out) })
        val link = Links.findLink(intent?.getStringExtra(Intent.EXTRA_TEXT) ?: intent?.dataString)
        if (link == null) { out.text = "no link"; return }
        out.text = "resolving $link"
        thread {
            val t = System.nanoTime()
            val r = runCatching { Links.resolve(this, link) }
            val ms = (System.nanoTime() - t) / 1_000_000
            android.util.Log.i("IslamicMute", "link resolve ${ms} ms: $r")
            runOnUiThread { out.text = "yt-dlp ${runCatching { Links.ytDlpVersion(this) }.getOrNull()}\n$ms ms\n$r" }
        }
    }
}
