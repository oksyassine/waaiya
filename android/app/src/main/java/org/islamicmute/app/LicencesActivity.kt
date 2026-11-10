package org.islamicmute.app

import android.app.Activity
import android.os.Bundle
import android.webkit.WebView
import android.os.Build
import android.view.Gravity
import android.view.View
import android.view.WindowInsets
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageButton
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
    override fun attachBaseContext(base: android.content.Context) { super.attachBaseContext(Lang.wrap(base)) }

    private var doc: WebView? = null

    private lateinit var titleView: TextView
    private lateinit var body: FrameLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Same edge-to-edge handling as the main screen: our own header, padded below the status bar.
        if (Build.VERSION.SDK_INT >= 30) window.setDecorFitsSystemWindows(false)
        val dp = resources.displayMetrics.density
        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setBackgroundColor(getColor(R.color.bg)) }
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL
            setPaddingRelative((4 * dp).toInt(), (4 * dp).toInt(), (16 * dp).toInt(), (4 * dp).toInt())
        }
        header.addView(ImageButton(this).apply {
            setImageResource(R.drawable.ic_arrow_back)
            setBackgroundResource(R.drawable.bg_button_text)
            contentDescription = getString(R.string.back)
            setOnClickListener { goBack() }
        }, LinearLayout.LayoutParams((48 * dp).toInt(), (48 * dp).toInt()))
        titleView = TextView(this, null, 0, R.style.Text_Headline).apply {
            setPaddingRelative((8 * dp).toInt(), 0, 0, 0); isSingleLine = true
            ellipsize = android.text.TextUtils.TruncateAt.END; isAccessibilityHeading = true
        }
        header.addView(titleView, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        root.addView(header)
        body = FrameLayout(this)
        root.addView(body, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f))
        root.setOnApplyWindowInsetsListener { v, insets ->
            val bars = if (Build.VERSION.SDK_INT >= 30)
                insets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
            else @Suppress("DEPRECATION") android.graphics.Insets.of(insets.systemWindowInsetLeft,
                insets.systemWindowInsetTop, insets.systemWindowInsetRight, insets.systemWindowInsetBottom)
            v.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            insets
        }
        setContentView(root)
        showIndex()
    }

    private fun showIndex() {
        doc?.destroy(); doc = null
        titleView.setText(R.string.licences)
        val dp = resources.displayMetrics.density
        val pad = (20 * dp).toInt()
        val col = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(pad, 0, pad, pad) }
        fun text(s: String, style: Int = R.style.Text_Secondary) = TextView(this, null, 0, style).apply {
            text = s; setPadding(0, pad / 2, 0, pad / 2); setTextIsSelectable(true)
        }
        col.addView(text(getString(R.string.licences_intro), R.style.Text_Body))
        // NOTICE is English legal text: keep it left-to-right in an Arabic UI.
        col.addView(text(asset("NOTICE.txt")).apply {
            textDirection = View.TEXT_DIRECTION_LTR; textAlignment = View.TEXT_ALIGNMENT_TEXT_START
        })
        col.addView(text(getString(R.string.licences_cc)))
        col.addView(text(getString(R.string.licences_full), R.style.Text_Section))
        for ((label, file) in DOCS) col.addView(Button(this, null, 0, R.style.Button_Tonal).apply {
            text = label
            setOnClickListener { showDoc(label, file) }
        }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
            topMargin = (8 * dp).toInt()
        })
        body.removeAllViews()
        body.addView(ScrollView(this).apply { addView(col) })
    }

    private fun showDoc(label: String, file: String) {
        titleView.text = label
        doc = WebView(this).apply {
            settings.javaScriptEnabled = false
            settings.defaultTextEncodingName = "utf-8"
            loadUrl("file:///android_asset/$DIR/$file")
        }
        body.removeAllViews()
        body.addView(doc)
    }

    private fun goBack() { if (doc != null) showIndex() else finish() }

    @Deprecated("framework Activity API")
    override fun onBackPressed() {
        if (doc != null) showIndex()
        else @Suppress("DEPRECATION") super.onBackPressed()
    }

    override fun onDestroy() { doc?.destroy(); super.onDestroy() }

    private fun asset(name: String): String =
        runCatching { assets.open("$DIR/$name").bufferedReader().use { it.readText() } }.getOrElse { "($name missing)" }

    companion object {
        private const val DIR = "licences"
        private val DOCS = listOf(
            "Apache License 2.0 (Waaiya, AndroidX, Media3, Kotlin, Guava)" to "LICENSE-Apache-2.0.txt",
            "Third-party components, models and training data" to "THIRD_PARTY_LICENSES.txt",
            "ONNX Runtime (MIT)" to "onnxruntime-LICENSE.txt",
            "ONNX Runtime third-party notices" to "onnxruntime-ThirdPartyNotices.txt",
            "Shizuku-API (MIT)" to "Shizuku-API-LICENSE.txt",
            "DeepFilterNet (MIT; also available under Apache-2.0)" to "DeepFilterNet-LICENSE-MIT.txt",
            "EfficientAT detector backbone (MIT)" to "EfficientAT-LICENSE.txt",
            "Chaquopy, Python in the app (MIT)" to "Chaquopy-LICENSE.txt",
            "Python (PSF License)" to "Python-LICENSE.txt",
            "yt-dlp, link reader (Unlicense)" to "yt-dlp-LICENSE.txt",
            "yt-dlp-ejs (Unlicense; includes astring MIT, meriyah ISC)" to "yt-dlp-ejs-LICENSE.txt",
            "QuickJS-NG, JavaScript engine (MIT)" to "quickjs-ng-LICENSE.txt",
        )
    }
}
