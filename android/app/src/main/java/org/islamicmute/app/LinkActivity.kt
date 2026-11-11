package org.islamicmute.app

import android.app.Activity
import android.content.ClipboardManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.EditText
import android.widget.ProgressBar
import android.widget.TextView
import kotlin.concurrent.thread

/**
 * Paste (or share from another app) a link, then watch it filtered in the player or save a filtered copy.
 * Opening a link uses the network and JavaScript, so it runs off the main thread; saving runs in
 * [LinkExportService] so it continues when the user leaves this screen.
 */
class LinkActivity : Activity() {
    override fun attachBaseContext(base: android.content.Context) { super.attachBaseContext(Lang.wrap(base)) }

    private lateinit var input: EditText
    private lateinit var error: TextView
    private lateinit var resolving: View
    private lateinit var result: View
    private lateinit var export: View
    private var resolved: Links.Resolved? = null
    private var resolvingUrl: String? = null

    private val exportChanged: () -> Unit = { showExport() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_link)
        edgeToEdge()
        input = findViewById(R.id.link_input)
        error = findViewById(R.id.link_error)
        resolving = findViewById(R.id.resolving)
        result = findViewById(R.id.result)
        export = findViewById(R.id.export)

        findViewById<View>(R.id.back).setOnClickListener { finish() }
        findViewById<Button>(R.id.paste).setOnClickListener {
            val clip = getSystemService(ClipboardManager::class.java).primaryClip
            val text = if (clip != null && clip.itemCount > 0) clip.getItemAt(0).coerceToText(this) else null
            Links.findLink(text)?.let { input.setText(it); open() } ?: showError(getString(R.string.link_invalid))
        }
        findViewById<Button>(R.id.open).setOnClickListener { open() }
        input.setOnEditorActionListener { _, id, _ -> if (id == EditorInfo.IME_ACTION_GO) { open(); true } else false }
        findViewById<Button>(R.id.watch).setOnClickListener { watch() }
        findViewById<Button>(R.id.save).setOnClickListener { save() }
        findViewById<Button>(R.id.export_cancel).setOnClickListener { stopService(Intent(this, LinkExportService::class.java)) }
        findViewById<Button>(R.id.play_saved).setOnClickListener { playSaved() }
        findViewById<Button>(R.id.share_saved).setOnClickListener { shareSaved() }

        LinkExportService.addListener(exportChanged)
        handle(intent)
        showExport()
        // Keep yt-dlp current (at most once a day; a no-op when nothing newer is on PyPI). Never delays a link:
        // a link waits only for the moment the new copy is switched in.
        thread(name = "im-ytdlp-update") { runCatching { Links.update(applicationContext) } }
    }

    override fun onNewIntent(intent: Intent) { super.onNewIntent(intent); setIntent(intent); handle(intent) }

    override fun onDestroy() { LinkExportService.removeListener(exportChanged); super.onDestroy() }

    /** A link shared from another app (YouTube "Share" sends text containing the link) opens at once. */
    private fun handle(intent: Intent?) {
        val link = Links.findLink(intent?.getStringExtra(Intent.EXTRA_TEXT) ?: intent?.dataString) ?: return
        input.setText(link)
        open()
    }

    private fun edgeToEdge() {
        if (Build.VERSION.SDK_INT >= 30) window.setDecorFitsSystemWindows(false)
        val root = findViewById<View>(R.id.root)
        root.setOnApplyWindowInsetsListener { v, insets ->
            val bars = if (Build.VERSION.SDK_INT >= 30)
                insets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout() or WindowInsets.Type.ime())
            else @Suppress("DEPRECATION") android.graphics.Insets.of(insets.systemWindowInsetLeft,
                insets.systemWindowInsetTop, insets.systemWindowInsetRight, insets.systemWindowInsetBottom)
            v.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            insets
        }
    }

    private fun showError(msg: String?) {
        error.text = msg ?: ""
        error.visibility = if (msg == null) View.GONE else View.VISIBLE
    }

    private fun open() {
        val url = Links.findLink(input.text) ?: run { showError(getString(R.string.link_invalid)); return }
        if (url == resolvingUrl) return
        getSystemService(InputMethodManager::class.java).hideSoftInputFromWindow(input.windowToken, 0)
        showError(null)
        LinkExportService.clearFinished()
        result.visibility = View.GONE
        resolving.visibility = View.VISIBLE
        resolvingUrl = url
        thread(name = "im-resolve") {
            val r = runCatching { Links.resolve(this, url) }
            runOnUiThread {
                if (isDestroyed || resolvingUrl != url) return@runOnUiThread
                resolvingUrl = null
                resolving.visibility = View.GONE
                r.onSuccess { show(it) }.onFailure { showError(it.message ?: getString(R.string.link_failed)) }
            }
        }
    }

    private fun show(r: Links.Resolved) {
        resolved = r
        findViewById<TextView>(R.id.result_title).text = r.title.ifEmpty { r.site }
        val d = r.durationSec?.toInt()
        val duration = when {
            d == null -> ""
            d >= 3600 -> "%d:%02d:%02d".format(d / 3600, d / 60 % 60, d % 60)
            else -> "%d:%02d".format(d / 60, d % 60)
        }
        val meta = if (duration.isEmpty()) r.site else getString(R.string.link_meta, r.site, duration)
        findViewById<TextView>(R.id.result_meta).text =
            if (r.videoUnavailable) meta + "\n" + getString(R.string.link_audio_only) else meta
        findViewById<Button>(R.id.watch).setText(if (r.hasVideo) R.string.link_watch else R.string.link_listen)
        result.visibility = View.VISIBLE
    }

    private fun watch() {
        val r = resolved ?: return
        startActivity(Intent(this, PlayerActivity::class.java)
            .putExtra(PlayerActivity.EXTRA_STREAMS, Links.streamsJson(r.streams()))
            .putExtra(PlayerActivity.EXTRA_TITLE, r.title))
    }

    private fun save() {
        val r = resolved ?: return
        when {
            r.isLive -> showError(getString(R.string.link_live))
            LinkExportService.busy -> showError(getString(R.string.link_busy))
            else -> { showError(null); LinkExportService.start(this, r.title, r.streams()) }
        }
    }

    private fun showExport() {
        val s = LinkExportService.status
        export.visibility = if (s.phase == LinkExportService.Phase.IDLE) View.GONE else View.VISIBLE
        if (s.phase == LinkExportService.Phase.IDLE) return
        findViewById<TextView>(R.id.export_title).text = s.title
        val running = LinkExportService.busy
        findViewById<TextView>(R.id.export_state).apply {
            text = when (s.phase) {
                LinkExportService.Phase.DOWNLOADING -> getString(R.string.link_downloading)
                LinkExportService.Phase.FILTERING -> getString(R.string.link_filtering)
                LinkExportService.Phase.DONE -> getString(R.string.link_saved) + "\n" +
                    getString(if (s.isVideo) R.string.link_saved_video else R.string.link_saved_audio)
                LinkExportService.Phase.FAILED -> s.error ?: getString(R.string.link_export_failed)
                else -> ""
            }
            setTextColor(getColor(if (s.phase == LinkExportService.Phase.FAILED) R.color.error else R.color.text_secondary))
        }
        findViewById<ProgressBar>(R.id.export_progress).apply {
            visibility = if (running) View.VISIBLE else View.GONE
            isIndeterminate = s.progress < 0
            progress = (s.progress * 100).toInt()
        }
        findViewById<View>(R.id.export_cancel).visibility = if (running) View.VISIBLE else View.GONE
        val done = s.phase == LinkExportService.Phase.DONE && s.result != null
        findViewById<View>(R.id.export_done).visibility = if (done) View.VISIBLE else View.GONE
        findViewById<View>(R.id.share_note).visibility = if (done) View.VISIBLE else View.GONE
    }

    private fun playSaved() {
        val s = LinkExportService.status
        val uri = s.result ?: return
        // Our own player: the saved file is already filtered, so this only plays it (and filtering again is harmless).
        startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, if (s.isVideo) "video/mp4" else "audio/mp4")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
    }

    private fun shareSaved() {
        val s = LinkExportService.status
        val uri = s.result ?: return
        val send = Intent(Intent.ACTION_SEND).setType(if (s.isVideo) "video/mp4" else "audio/mp4")
            .putExtra(Intent.EXTRA_STREAM, uri).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        startActivity(Intent.createChooser(send, getString(R.string.link_share)))
    }
}
