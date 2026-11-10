package org.islamicmute.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaMuxer
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
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
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.nio.ByteBuffer
import java.util.concurrent.CopyOnWriteArraySet

/**
 * "Save without music": downloads the streams of a resolved link, joins video and audio into one MP4 (no
 * re-encoding), runs the audio through the voice filter (same engine and exact delay compensation as the
 * player; the video is copied as is), and publishes the result to Movies/ or Music/ "Islamic Mute".
 *
 * Fail-closed: files holding the original audio stay in the app cache and are deleted; the gallery only ever
 * receives a fully filtered file. Any error (unsupported audio, model failure, network) means no file.
 */
@OptIn(UnstableApi::class)
class LinkExportService : Service() {
    enum class Phase { IDLE, DOWNLOADING, FILTERING, DONE, FAILED }

    /** Snapshot shown by the link screen. [progress] is 0..1 within the phase, -1 if unknown. */
    data class Status(val phase: Phase, val title: String = "", val progress: Float = -1f,
                      val result: Uri? = null, val isVideo: Boolean = true, val error: String? = null)

    companion object {
        const val EXTRA_STREAMS = "streams"
        const val EXTRA_TITLE = "title"
        private const val CHANNEL = "export"
        private const val TAG = "IslamicMute"
        private const val CHUNK = 10L shl 20  // YouTube throttles single long requests; ranged chunks are not

        @Volatile var status = Status(Phase.IDLE)
            private set
        private val listeners = CopyOnWriteArraySet<() -> Unit>()
        private val main = Handler(Looper.getMainLooper())
        fun addListener(l: () -> Unit) { listeners += l }
        fun removeListener(l: () -> Unit) { listeners -= l }
        val busy get() = status.phase == Phase.DOWNLOADING || status.phase == Phase.FILTERING

        /** Forget a finished (done or failed) save, e.g. when the user opens another link. */
        fun clearFinished() {
            if (busy || status.phase == Phase.IDLE) return
            status = Status(Phase.IDLE)
            main.post { listeners.forEach { it() } }
        }

        fun start(ctx: Context, title: String, streams: Links.Streams) {
            ctx.startForegroundService(Intent(ctx, LinkExportService::class.java)
                .putExtra(EXTRA_TITLE, title).putExtra(EXTRA_STREAMS, Links.streamsJson(streams)))
        }
    }

    private var worker: Thread? = null
    @Volatile private var cancelled = false
    private var lastNotify = 0L

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: ""
        val json = intent?.getStringExtra(EXTRA_STREAMS)
        startForeground(2, notification(title, -1f, getString(R.string.link_downloading)), fgsType())
        if (json == null || busy) { if (!busy) stopSelf(); return START_NOT_STICKY }
        val streams = Links.streamsFromJson(json)
        publish(Status(Phase.DOWNLOADING, title, 0f, isVideo = streams.video != null || streams.progressive != null))
        worker = Thread({ run(title, streams) }, "im-export").also { it.start() }
        return START_NOT_STICKY
    }

    private fun fgsType(): Int =
        if (Build.VERSION.SDK_INT >= 35) ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC or ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROCESSING
        else ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC

    override fun onDestroy() {
        cancelled = true
        super.onDestroy()
    }

    private fun publish(s: Status) {
        status = s
        main.post { listeners.forEach { it() } }
        val now = System.currentTimeMillis()
        if (s.phase == Phase.DOWNLOADING || s.phase == Phase.FILTERING) {
            if (now - lastNotify < 500) return
            lastNotify = now
            val text = getString(if (s.phase == Phase.DOWNLOADING) R.string.link_downloading else R.string.link_filtering)
            getSystemService(NotificationManager::class.java).notify(2, notification(s.title, s.progress, text))
        }
    }

    /** Runs on the worker thread. */
    private fun run(title: String, st: Links.Streams) {
        val dir = File(cacheDir, "export").apply { deleteRecursively(); mkdirs() }
        try {
            // 1. Download (progress over all parts by bytes)
            val parts = listOfNotNull(st.progressive, st.video, st.audio)
            val sizes = parts.map { it.size ?: 0L }
            val total = sizes.sum().coerceAtLeast(1)
            var doneBytes = 0L
            val files = parts.mapIndexed { i, s ->
                val f = File(dir, "part$i.${s.ext ?: "mp4"}")
                download(s, f) { n -> publish(status.copy(progress = if (sizes.all { it > 0 }) (doneBytes + n).toFloat() / total else -1f)) }
                doneBytes += f.length()
                f
            }
            // 2. One input file: video + audio joined without re-encoding
            val input = if (st.video != null && st.audio != null) File(dir, "joined.mp4").also { mux(files[0], files[1], it) } else files[0]
            // 3. Filter the audio (video copied), strict: fails instead of writing unfiltered or silent audio
            publish(status.copy(phase = Phase.FILTERING, progress = 0f))
            val out = File(dir, "filtered.mp4")
            filter(input, out)
            // 4. Publish
            val isVideo = st.video != null || st.progressive != null
            val uri = publishToGallery(out, title, isVideo)
            publish(Status(Phase.DONE, title, 1f, uri, isVideo))
            getSystemService(NotificationManager::class.java).notify(2, doneNotification(title, uri, isVideo))
        } catch (e: Throwable) {
            Log.w(TAG, "export failed", e)
            val msg = if (cancelled) getString(R.string.link_cancelled) else (e as? Links.LinkException)?.message ?: getString(R.string.link_export_failed)
            publish(Status(Phase.FAILED, title, error = msg))
            getSystemService(NotificationManager::class.java).cancel(2)
        } finally {
            dir.deleteRecursively()  // the original-audio intermediates never leave the cache
            main.post { stopForeground(STOP_FOREGROUND_DETACH); stopSelf() }
        }
    }

    private fun download(s: Links.Stream, f: File, progress: (Long) -> Unit) {
        f.outputStream().use { out ->
            var pos = 0L
            var length = s.size ?: -1L
            while (!cancelled && (length < 0 || pos < length)) {
                val c = URL(s.url).openConnection() as HttpURLConnection
                c.connectTimeout = 20_000; c.readTimeout = 30_000; c.instanceFollowRedirects = true
                s.headers.forEach { (k, v) -> c.setRequestProperty(k, v) }
                c.setRequestProperty("Range", "bytes=$pos-${pos + CHUNK - 1}")
                val code = c.responseCode
                if (code !in 200..299) { c.disconnect(); throw IOException("HTTP $code") }
                if (code == 206) c.getHeaderField("Content-Range")?.substringAfter('/')?.toLongOrNull()?.let { length = it }
                else if (code == 200) length = c.contentLengthLong  // server ignored Range: whole file in one go
                val before = pos
                c.inputStream.use { inp ->
                    val buf = ByteArray(64 shl 10)
                    while (!cancelled) { val n = inp.read(buf); if (n < 0) break; out.write(buf, 0, n); pos += n; progress(pos) }
                }
                c.disconnect()
                if (code == 200 || pos == before) break
            }
            if (cancelled) throw IOException("cancelled")
        }
    }

    /** Copies the video track of [video] and the audio track of [audio] into one MP4 (no re-encoding). */
    private fun mux(video: File, audio: File, out: File) {
        val muxer = MediaMuxer(out.path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        val sources = listOf(video to "video/", audio to "audio/").map { (file, prefix) ->
            val ex = MediaExtractor().apply { setDataSource(file.path) }
            val track = (0 until ex.trackCount).firstOrNull { ex.getTrackFormat(it).getString("mime")?.startsWith(prefix) == true }
                ?: throw Links.LinkException(getString(R.string.link_export_failed))
            ex.selectTrack(track)
            Triple(ex, muxer.addTrack(ex.getTrackFormat(track)), track)
        }
        muxer.start()
        val buf = ByteBuffer.allocate(4 shl 20)
        val info = MediaCodec.BufferInfo()
        for ((ex, dst, _) in sources) {
            while (!cancelled) {
                val n = ex.readSampleData(buf, 0)
                if (n < 0) break
                info.set(0, n, ex.sampleTime, if (ex.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC != 0) MediaCodec.BUFFER_FLAG_KEY_FRAME else 0)
                muxer.writeSampleData(dst, buf, info)
                ex.advance()
            }
            ex.release()
        }
        muxer.stop(); muxer.release()
        if (cancelled) throw IOException("cancelled")
    }

    /** Media3 Transformer (on its own Looper thread): audio through the voice filter, video copied. Blocks until done. */
    private fun filter(input: File, out: File) {
        val encoderDelay = AacDelay.get(this)
        val done = java.util.concurrent.CountDownLatch(1)
        var error: Throwable? = null
        val thread = HandlerThread("im-transformer").also { it.start() }
        val h = Handler(thread.looper)
        h.post {
            val to48k = SonicAudioProcessor().apply { setOutputSampleRateHz(Engine.SAMPLE_RATE) }
            val item = EditedMediaItem.Builder(MediaItem.fromUri(Uri.fromFile(input)))
                .setEffects(Effects(listOf(to48k, VoiceFilterProcessor(this, strict = true, extraDropFrames = encoderDelay)), emptyList()))
                .build()
            val transformer = Transformer.Builder(this)
                .setLooper(thread.looper)
                .setAudioMimeType(MimeTypes.AUDIO_AAC)
                .addListener(object : Transformer.Listener {
                    override fun onCompleted(composition: Composition, exportResult: ExportResult) { done.countDown() }
                    override fun onError(composition: Composition, exportResult: ExportResult, exportException: ExportException) {
                        error = exportException; done.countDown()
                    }
                })
                .build()
            transformer.start(item, out.path)
            val holder = ProgressHolder()
            h.post(object : Runnable {
                override fun run() {
                    if (done.count == 0L) return
                    if (cancelled) { transformer.cancel(); error = IOException("cancelled"); done.countDown(); return }
                    if (transformer.getProgress(holder) == Transformer.PROGRESS_STATE_AVAILABLE) publish(status.copy(progress = holder.progress / 100f))
                    h.postDelayed(this, 300)
                }
            })
        }
        done.await()
        thread.quitSafely()
        error?.let { throw it }
        if (!out.isFile || out.length() == 0L) throw IOException("no output")
    }

    private fun publishToGallery(file: File, title: String, isVideo: Boolean): Uri {
        val base = title.replace(Regex("""[\\/:*?"<>|\n\r]"""), " ").trim().take(80).ifEmpty { "Islamic Mute" }
        val ext = if (isVideo) ".mp4" else ".m4a"
        val folder = (if (isVideo) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_MUSIC) + "/Islamic Mute/"
        val collection = if (isVideo) MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                         else MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        // Saving the same video twice: "Title (2).mp4" instead of clashing with the existing entry.
        fun taken(n: String) = contentResolver.query(collection, arrayOf(MediaStore.MediaColumns._ID),
            "${MediaStore.MediaColumns.DISPLAY_NAME}=? AND ${MediaStore.MediaColumns.RELATIVE_PATH}=?", arrayOf(n, folder), null)
            ?.use { it.count > 0 } ?: false
        val name = (1..99).asSequence().map { if (it == 1) base + ext else "$base ($it)$ext" }.firstOrNull { !taken(it) }
            ?: "$base ${System.currentTimeMillis()}$ext"
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, if (isVideo) "video/mp4" else "audio/mp4")
            put(MediaStore.MediaColumns.RELATIVE_PATH, folder)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(collection, values) ?: throw IOException("cannot create the gallery entry")
        try {
            contentResolver.openOutputStream(uri)!!.use { o -> file.inputStream().use { it.copyTo(o) } }
            contentResolver.update(uri, ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }, null, null)
        } catch (e: Throwable) { contentResolver.delete(uri, null, null); throw e }
        return uri
    }

    private fun channel() {
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(NotificationChannel(CHANNEL, getString(R.string.link_channel), NotificationManager.IMPORTANCE_LOW))
    }

    private fun openLinkScreen() = PendingIntent.getActivity(this, 3, Intent(this, LinkActivity::class.java),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

    private fun notification(title: String, progress: Float, text: String): Notification {
        channel()
        return Notification.Builder(this, CHANNEL)
            .setContentTitle(text).setContentText(title).setSmallIcon(R.drawable.ic_notification)
            .setColor(getColor(R.color.primary)).setOngoing(true).setOnlyAlertOnce(true)
            .setProgress(100, (progress * 100).toInt().coerceIn(0, 100), progress < 0)
            .setContentIntent(openLinkScreen())
            .build()
    }

    private fun doneNotification(title: String, uri: Uri, isVideo: Boolean): Notification {
        channel()
        val view = PendingIntent.getActivity(this, 4, Intent(Intent.ACTION_VIEW).setDataAndType(uri, if (isVideo) "video/mp4" else "audio/mp4")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION), PendingIntent.FLAG_IMMUTABLE)
        return Notification.Builder(this, CHANNEL)
            .setContentTitle(getString(R.string.link_saved)).setContentText(title).setSmallIcon(R.drawable.ic_notification)
            .setColor(getColor(R.color.primary)).setAutoCancel(true).setContentIntent(view).build()
    }
}
