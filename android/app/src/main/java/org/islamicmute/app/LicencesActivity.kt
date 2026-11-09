package org.islamicmute.app

import android.app.Activity
import android.os.Bundle
import android.webkit.WebView
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/**
 * Open-source licences. The texts are assets copied at build time from the repository (copyLicences in
 * app/build.gradle.kts), so this screen cannot drift from NOTICE and THIRD_PARTY_LICENSES.md.
 * The index shows NOTICE; each button opens one full text in a WebView (plain text, no JavaScript), which copes
 * with ONNX Runtime's 340 KB ThirdPartyNotices.txt better than a TextView.
 */
class LicencesActivity : Activity() {
    private var doc: WebView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = "Open-source licences"
        showIndex()
    }

    private fun showIndex() {
        doc?.destroy(); doc = null
        val pad = (16 * resources.displayMetrics.density).toInt()
        val col = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(pad, pad, pad, pad) }
        fun text(s: String, size: Float = 14f) = TextView(this).apply {
            text = s; textSize = size; setPadding(0, pad / 2, 0, pad / 2); setTextIsSelectable(true)
        }
        col.addView(text("Islamic Mute is free software under the GNU Affero General Public License v3 or later.", 16f))
        col.addView(text(asset("NOTICE.txt")))
        col.addView(text("Creative Commons Attribution 4.0 (training data): https://creativecommons.org/licenses/by/4.0/"))
        col.addView(text("Full texts", 18f))
        for ((label, file) in DOCS) col.addView(Button(this).apply {
            text = label
            isAllCaps = false
            setOnClickListener { showDoc(label, file) }
        })
        setContentView(ScrollView(this).apply { addView(col) })
    }

    private fun showDoc(label: String, file: String) {
        title = label
        doc = WebView(this).apply {
            settings.javaScriptEnabled = false
            settings.defaultTextEncodingName = "utf-8"
            loadUrl("file:///android_asset/$DIR/$file")
        }
        setContentView(doc)
    }

    @Deprecated("framework Activity API")
    override fun onBackPressed() {
        if (doc != null) { title = "Open-source licences"; showIndex() }
        else @Suppress("DEPRECATION") super.onBackPressed()
    }

    override fun onDestroy() { doc?.destroy(); super.onDestroy() }

    private fun asset(name: String): String =
        runCatching { assets.open("$DIR/$name").bufferedReader().use { it.readText() } }.getOrElse { "($name missing)" }

    companion object {
        private const val DIR = "licences"
        private val DOCS = listOf(
            "GNU Affero General Public License v3 or later (Islamic Mute)" to "LICENSE-Apache-2.0.txt",
            "Third-party components, models and training data" to "THIRD_PARTY_LICENSES.txt",
            "ONNX Runtime (MIT)" to "onnxruntime-LICENSE.txt",
            "ONNX Runtime third-party notices" to "onnxruntime-ThirdPartyNotices.txt",
            "Shizuku-API (MIT)" to "Shizuku-API-LICENSE.txt",
            "DeepFilterNet (MIT; also available under Apache-2.0)" to "DeepFilterNet-LICENSE-MIT.txt",
            "EfficientAT detector backbone (MIT)" to "EfficientAT-LICENSE.txt",
        )
    }
}
