package org.waaiya.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.provider.OpenableColumns
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.audio.SonicAudioProcessor
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.Transformer
import java.io.File

/**
 * "Waaiya: check for music" in the share sheet (docs/MUSIC_CHECK.md): listens to the shared video or audio file on
 * the phone, then says whether it heard musical instruments and where, and offers to share a copy without music, to
 * share the file as it is, or to listen to it filtered. The wording stays modest: what Waaiya heard, not a ruling.
 * Everything happens here while the screen is open (the share's read access belongs to this screen).
 */
@OptIn(UnstableApi::class)
class MusicCheckActivity : Activity() {
    override fun attachBaseContext(base: android.content.Context) { super.attachBaseContext(Lang.wrap(base)) }

    private lateinit var uri: Uri
    private var mime: String = "video/*"
    private var name: String = ""
    @Volatile private var cancelled = false
    private var worker: Thread? = null
    private var transformer: Transformer? = null
    private var copyThread: HandlerThread? = null
    private var firstPartMs = 0L
    private var copy: File? = null
    private val main = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val u: Uri? = if (intent?.action == Intent.ACTION_SEND) {
            if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            else @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_STREAM)
        } else null
        // a shared file only: another app's explicit intent could otherwise hand it a web address to fetch
        if (u == null || (u.scheme != "content" && u.scheme != "file")) { finish(); return }
        uri = u
        mime = intent.type?.takeIf { it.startsWith("video/") || it.startsWith("audio/") }
            ?: runCatching { contentResolver.getType(u) }.getOrNull() ?: "video/*"
        name = runCatching {
            contentResolver.query(u, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                if (c.moveToFirst()) c.getString(0) else null
            }
        }.getOrNull() ?: getString(R.string.mc_unnamed)
        setContentView(R.layout.activity_music_check)
        // edge to edge on every version (Android 15+ forces it): the content kept clear of the bars, as LinkActivity
        if (Build.VERSION.SDK_INT >= 30) window.setDecorFitsSystemWindows(false)
        findViewById<View>(R.id.root).setOnApplyWindowInsetsListener { v, insets ->
            val b = if (Build.VERSION.SDK_INT >= 30)
                insets.getInsets(android.view.WindowInsets.Type.systemBars() or android.view.WindowInsets.Type.displayCutout())
            else @Suppress("DEPRECATION") android.graphics.Insets.of(insets.systemWindowInsetLeft,
                insets.systemWindowInsetTop, insets.systemWindowInsetRight, insets.systemWindowInsetBottom)
            v.setPadding(b.left, b.top, b.right, b.bottom)
            insets
        }
        findViewById<View>(R.id.back).setOnClickListener { finish() }
        findViewById<TextView>(R.id.file_name).text = name
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)  // the check runs only while this is open
        CleanCopyProvider.prune(this)
        listening(0f)
        worker = Thread({
            val out = MusicScan.analyze(this, uri, { f -> main.post { if (!isFinishing) listening(f) } }, { cancelled })
            main.post { if (!isFinishing && !isDestroyed) show(out) }
        }, "im-music-check").also { it.start() }
    }

    override fun onDestroy() {
        cancelled = true
        transformer?.let { t -> copyThread?.let { Handler(it.looper).post { runCatching { t.cancel() } } } }
        copyThread?.quitSafely()
        super.onDestroy()
    }

    private fun listening(f: Float) {
        val pct = (f * 100).toInt()
        findViewById<TextView>(R.id.listening_text).text = getString(R.string.mc_listening, pct)
        findViewById<ProgressBar>(R.id.listening_progress).progress = pct
    }

    private fun time(s: Double): String {
        val t = s.toLong()
        return if (t >= 3600) "%d:%02d:%02d".format(t / 3600, t / 60 % 60, t % 60) else "%d:%02d".format(t / 60, t % 60)
    }

    /** "0:00–0:35, 1:10–1:40", each range kept left to right in right-to-left text. */
    private fun ranges(parts: List<MusicRule.Part>): String =
        parts.joinToString(getString(R.string.mc_list_sep)) { "\u2066${time(it.start)}–${time(it.end)}\u2069" }

    private fun show(out: MusicScan.Companion.Outcome) {
        findViewById<View>(R.id.listening).visibility = View.GONE
        findViewById<View>(R.id.result).visibility = View.VISIBLE
        val title = findViewById<TextView>(R.id.result_title)
        val detail = findViewById<TextView>(R.id.result_detail)
        val note = findViewById<TextView>(R.id.result_note)
        val actions = findViewById<View>(R.id.actions)
        actions.visibility = View.VISIBLE
        note.visibility = View.GONE
        when (out) {
            is MusicScan.Companion.Outcome.Done -> {
                val r = out.result
                val meta = findViewById<TextView>(R.id.file_meta)
                meta.text = time(out.durationS)
                meta.visibility = View.VISIBLE
                if (r.verdict != MusicRule.Verdict.NONE) {
                    val tl = findViewById<MusicTimelineView>(R.id.timeline)
                    tl.set(out.durationS, r.parts, r.verdict == MusicRule.Verdict.PERCUSSION)
                    tl.visibility = View.VISIBLE
                    findViewById<View>(R.id.timeline_ends).visibility = View.VISIBLE
                    findViewById<TextView>(R.id.timeline_end).text = time(out.durationS)
                    firstPartMs = (r.parts.first().start * 1000).toLong()
                }
                val heard = r.parts.sumOf { it.end - it.start }
                val pct = if (out.durationS > 0) (heard / out.durationS * 100).toInt().coerceIn(1, 100) else 0
                when (r.verdict) {
                    MusicRule.Verdict.MUSIC -> {
                        title.text = getString(R.string.mc_music)
                        detail.text = getString(R.string.mc_music_detail, ranges(r.parts), "\u2066$pct\u2069")
                        note.text = getString(R.string.mc_note_quiet)
                        note.visibility = View.VISIBLE
                        findViewById<MusicTimelineView>(R.id.timeline).contentDescription = detail.text
                    }
                    MusicRule.Verdict.PERCUSSION -> {
                        title.text = getString(R.string.mc_percussion)
                        detail.text = getString(R.string.mc_percussion_detail, ranges(r.parts))
                        findViewById<MusicTimelineView>(R.id.timeline).contentDescription = detail.text
                    }
                    MusicRule.Verdict.NONE -> {
                        title.text = getString(R.string.mc_none)
                        detail.text = getString(R.string.mc_none_detail)
                        note.text = getString(R.string.mc_note_quiet)
                        note.visibility = View.VISIBLE
                    }
                }
                setUpActions(listenToo = r.verdict != MusicRule.Verdict.NONE)
            }
            else -> {
                title.text = getString(R.string.mc_failed)
                detail.text = getString(when (out) {
                    MusicScan.Companion.Outcome.NoModel -> R.string.mc_failed_no_model
                    MusicScan.Companion.Outcome.NoSound -> R.string.mc_failed_no_sound
                    MusicScan.Companion.Outcome.TooLong -> R.string.mc_failed_too_long
                    else -> R.string.mc_failed_unreadable
                })
                // a copy without music needs the file to be readable, and listening needs the sound
                setUpActions(listenToo = false, cleanToo = out == MusicScan.Companion.Outcome.TooLong)
            }
        }
    }

    private fun setUpActions(listenToo: Boolean, cleanToo: Boolean = true) {
        val clean = findViewById<Button>(R.id.share_clean)
        clean.visibility = if (cleanToo) View.VISIBLE else View.GONE
        clean.setOnClickListener { copy?.let { shareCopy(it) } ?: makeCopy() }
        findViewById<Button>(R.id.listen).apply {
            visibility = if (listenToo) View.VISIBLE else View.GONE
            setOnClickListener {
                val i = Intent(this@MusicCheckActivity, PlayerActivity::class.java).setAction(Intent.ACTION_VIEW)
                    .setDataAndType(uri, mime).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    .putExtra(PlayerActivity.EXTRA_START_MS, firstPartMs)
                runCatching { startActivity(i) }
            }
        }
        findViewById<Button>(R.id.share_anyway).setOnClickListener {
            val i = Intent(Intent.ACTION_SEND).setType(mime).putExtra(Intent.EXTRA_STREAM, uri)
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            runCatching { startActivity(Intent.createChooser(i, null)) }
        }
    }

    /** The same filter as the player (the user's filter), audio only; the picture is copied as it is. */
    private fun makeCopy() {
        val clean = findViewById<Button>(R.id.share_clean)
        clean.isEnabled = false
        val copying = findViewById<LinearLayout>(R.id.copying)
        val text = findViewById<TextView>(R.id.copying_text)
        val bar = findViewById<ProgressBar>(R.id.copying_progress)
        copying.visibility = View.VISIBLE
        text.text = getString(R.string.mc_copying, 0)
        bar.progress = 0
        val audioOnly = mime.startsWith("audio/")
        val base = name.substringBeforeLast('.').ifBlank { "waaiya" }.replace(Regex("[\\\\/:*?\"<>|]"), "_").take(80)
        val dir = CleanCopyProvider.dir(this).apply { mkdirs() }
        val out = File(dir, getString(R.string.mc_copy_name, base) + if (audioOnly) ".m4a" else ".mp4")
        out.delete()
        val thread = HandlerThread("im-clean-copy").also { it.start() }
        copyThread = thread
        val h = Handler(thread.looper)
        fun failed() = main.post {
            if (isDestroyed) return@post
            copying.visibility = View.VISIBLE
            text.text = getString(R.string.mc_copy_failed)
            clean.isEnabled = true
        }
        h.post {
            try {
                val to48k = SonicAudioProcessor().apply { setOutputSampleRateHz(Engine.SAMPLE_RATE) }
                val item = EditedMediaItem.Builder(MediaItem.fromUri(uri))
                    .setEffects(Effects(listOf(to48k, VoiceFilterProcessor(this, strict = true, extraDropFrames = AacDelay.get(this))), emptyList()))
                    .build()
                val t = Transformer.Builder(this).setLooper(thread.looper).setAudioMimeType(MimeTypes.AUDIO_AAC)
                    .addListener(object : Transformer.Listener {
                        override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                            main.post {
                                if (isDestroyed) return@post
                                copying.visibility = View.GONE
                                clean.isEnabled = true
                                copy = out
                                shareCopy(out)
                            }
                        }
                        override fun onError(composition: Composition, exportResult: ExportResult, e: ExportException) {
                            android.util.Log.w("IslamicMute", "copy without music failed", e)
                            out.delete()
                            failed()
                        }
                    }).build()
                transformer = t
                t.start(item, out.path)
                val holder = ProgressHolder()
                h.post(object : Runnable {
                    override fun run() {
                        if (cancelled) return
                        if (t.getProgress(holder) == Transformer.PROGRESS_STATE_AVAILABLE) {
                            val p = holder.progress
                            main.post { if (!isDestroyed) { text.text = getString(R.string.mc_copying, p); bar.progress = p } }
                        }
                        if (t.getProgress(holder) != Transformer.PROGRESS_STATE_NOT_STARTED) h.postDelayed(this, 300)
                    }
                })
            } catch (e: Exception) {
                android.util.Log.w("IslamicMute", "copy without music failed", e)
                failed()
            }
        }
    }

    private fun shareCopy(f: File) {
        val u = CleanCopyProvider.uri(this, f)
        val i = Intent(Intent.ACTION_SEND).setType(if (f.extension == "m4a") "audio/mp4" else "video/mp4")
            .putExtra(Intent.EXTRA_STREAM, u).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        runCatching { startActivity(Intent.createChooser(i, null)) }
    }
}
