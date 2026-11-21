package org.islamicmute.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings as AndroidSettings
import android.util.Log
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.lang.ref.WeakReference
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.Executors
import java.util.zip.ZipFile

/**
 * New versions of Waaiya (feature `update`): once a day (unless turned off) and on "Check now", the release file
 * https://waaiya.mssid.org/downloads/update.json is read; the comparison is made here, nothing is sent but the request
 * itself (a fixed client name, no device or version). When a newer version exists, a notification says so.
 *
 * "Update now" downloads the smallest way to the new APK: a zstd patch against the APK installed on this phone (a few
 * MB instead of ~100), rebuilt here by [AppUpdatePatch]; if there is no patch for this APK, or anything about it fails,
 * the full APK of the same variant. The result must match the release's SHA-256, its package, its version and this
 * app's signing certificate before Android's installer (which asks the user to confirm) is given it
 * ([AppUpdateInstall]). Installing stops the filter, so it goes through the same gate as Stop (PIN, waiting period).
 * Not in builds that must not download code (-PimPlay: BuildConfig.SELF_UPDATE false).
 */
object AppUpdate : Feature {
    override val name = "update"
    private const val TAG = "WaaiyaUpdate"
    const val MANIFEST_URL = "https://waaiya.mssid.org/downloads/update.json"
    const val PAGE_URL = "https://waaiya.mssid.org/#download"
    private const val HOST = "waaiya.mssid.org"
    private const val USER_AGENT = "Waaiya-Update/1"  // fixed: no phone model, no version
    private const val SCHEMA = 1
    private const val MAX_APK = 1L shl 30
    const val CHANNEL = "updates"
    private const val NOTIFICATION_ID = 4710
    private const val PREFS = "app_update"

    data class Asset(val url: String, val sha256: String, val size: Long)
    data class Patch(val from: String, val variant: String, val asset: Asset)
    data class Release(
        val versionCode: Long, val versionName: String, val notes: Map<String, String>,
        val apks: Map<String, Asset>, val patches: List<Patch>, val known: Map<String, String>,
    )

    /** The way to the new APK chosen for this phone. */
    data class Plan(val variant: String, val target: Asset, val patch: Patch?) {
        val download: Long get() = patch?.asset?.size ?: target.size
    }

    @Volatile private var state = "idle"  // idle checking none available downloading preparing ready installing error permission
    @Volatile private var progress = 0.0
    @Volatile private var error: String? = null
    @Volatile private var release: Release? = null
    @Volatile private var plan: Plan? = null
    @Volatile private var host: WeakReference<FeatureHost>? = null
    @Volatile private var lastAttempt = 0L  // a failed check is retried by itself at most once an hour
    private val worker = Executors.newSingleThreadExecutor { r -> Thread(r, "im-update") }
    private val main by lazy { Handler(Looper.getMainLooper()) }

    private fun prefs(c: Context) = c.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    fun auto(c: Context) = prefs(c).getBoolean("auto", true)
    private fun dir(c: Context) = File(c.applicationContext.cacheDir, "update").apply { mkdirs() }

    // ---------- Feature (Flutter) ----------

    override fun snapshot(host: FeatureHost): Map<String, Any?> {
        this.host = WeakReference(host)
        val c = host.activity
        if (!BuildConfig.SELF_UPDATE) return mapOf("supported" to false)
        // the screen is open: a check older than a day happens now (no notification: the screen shows it)
        val now = System.currentTimeMillis()
        if (auto(c) && state == "idle" && now - prefs(c).getLong("lastCheck", 0) > DAY && now - lastAttempt > HOUR) check(c, notify = false)
        val r = release
        val p = plan
        return mapOf(
            "supported" to true, "auto" to auto(c), "state" to state, "current" to BuildConfig.VERSION_NAME,
            "latest" to r?.versionName, "notes" to r?.notes, "download" to p?.download, "full" to p?.target?.size,
            "patch" to (p?.patch != null), "progress" to progress, "error" to error,
            "lastCheck" to prefs(c).getLong("lastCheck", 0), "page" to PAGE_URL,
        )
    }

    override fun call(host: FeatureHost, method: String, args: Map<String, Any?>): Any? {
        this.host = WeakReference(host)
        val c = host.activity
        if (!BuildConfig.SELF_UPDATE) throw FeatureException("unsupported", "updates are not in this build")
        when (method) {
            "check" -> check(c, notify = false)
            "setAuto" -> {
                prefs(c).edit().putBoolean("auto", args["on"] as? Boolean ?: throw FeatureException("bad_args", "on")).apply()
                schedule(c)
            }
            "start" -> {
                if (state !in setOf("available", "error", "permission", "ready")) throw FeatureException("busy", state)
                // installing stops the filter: the same gate as Stop (PIN, waiting period) before anything starts
                if (FilterService.running) Protection.checkStop(c)
                start(c)
            }
            "openPage" -> c.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(PAGE_URL)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            else -> throw FeatureException("unsupported", "update.$method")
        }
        host.refresh()
        return null
    }

    private fun set(newState: String, p: Double = progress, err: String? = null) {
        state = newState; progress = p; error = err
        main.post { host?.get()?.refresh() }
    }

    // ---------- checking ----------

    /** Reads the release file; [notify]: post a notification for a version not announced before (daily check). */
    fun check(context: Context, notify: Boolean, done: (() -> Unit)? = null) {
        val c = context.applicationContext
        if (!BuildConfig.SELF_UPDATE) { done?.invoke(); return }
        if (state in setOf("checking", "downloading", "preparing", "installing")) { done?.invoke(); return }
        lastAttempt = System.currentTimeMillis()
        set("checking")
        worker.execute {
            try {
                val r = parse(fetchText(manifestUrl(c)))
                prefs(c).edit().putLong("lastCheck", System.currentTimeMillis()).apply()
                release = r
                if (r.versionCode <= BuildConfig.VERSION_CODE) { plan = null; set("none") }
                else {
                    plan = choose(c, r)
                    set(if (plan == null) "error" else "available", 0.0, if (plan == null) "no_file" else null)
                    if (notify && plan != null && prefs(c).getLong("notified", 0) < r.versionCode) {
                        announce(c, r, plan!!)
                        prefs(c).edit().putLong("notified", r.versionCode).apply()
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "check: $e")
                set(if (release != null && release!!.versionCode > BuildConfig.VERSION_CODE) "available" else "idle", 0.0, "network")
            } finally { done?.invoke() }
        }
    }

    /** Debug builds may point at a test release file: `run-as <pkg>` writes files/update-url.txt (e2e tests). */
    private fun manifestUrl(c: Context): String {
        if (BuildConfig.DEBUG) File(c.filesDir, "update-url.txt").takeIf { it.isFile }?.readText()?.trim()
            ?.takeIf { it.startsWith("https://") }?.let { return it }
        return MANIFEST_URL
    }

    private fun allowedUrl(u: String) = runCatching { URL(u) }.getOrNull()?.let { it.protocol == "https" && it.host == HOST } == true

    private fun asset(o: JSONObject?): Asset? {
        o ?: return null
        val url = o.optString("url"); val sha = o.optString("sha256").lowercase(); val size = o.optLong("size")
        if (!allowedUrl(url) || !Regex("[0-9a-f]{64}").matches(sha) || size <= 0 || size > MAX_APK) return null
        return Asset(url, sha, size)
    }

    /** The release file (schema 1); unknown fields are ignored, a newer schema is read as far as it is understood. */
    internal fun parse(text: String): Release {
        val j = JSONObject(text)
        require(j.optInt("schema", 0) >= SCHEMA) { "schema" }
        val a = j.getJSONObject("android")
        val apks = HashMap<String, Asset>()
        a.optJSONObject("apks")?.let { o -> o.keys().forEach { k -> asset(o.optJSONObject(k))?.let { apks[k] = it } } }
        val patches = ArrayList<Patch>()
        a.optJSONArray("patches")?.let { arr ->
            for (i in 0 until arr.length()) {
                val o = arr.optJSONObject(i) ?: continue
                val from = o.optString("from").lowercase()
                val v = o.optString("variant")
                val asset = asset(o)
                if (asset != null && Regex("[0-9a-f]{64}").matches(from) && v in apks) patches += Patch(from, v, asset)
            }
        }
        val known = HashMap<String, String>()
        a.optJSONObject("known")?.let { o -> o.keys().forEach { k -> known[k.lowercase()] = o.optString(k) } }
        val notes = HashMap<String, String>()
        j.optJSONObject("notes")?.let { o -> o.keys().forEach { k -> notes[k] = o.optString(k).take(2000) } }
        require(apks.isNotEmpty()) { "no apks" }
        return Release(a.getLong("versionCode"), a.optString("versionName").take(40), notes, apks, patches, known)
    }

    /** The patch for the APK installed here if there is one, else the full APK of the same variant. */
    internal fun choose(c: Context, r: Release): Plan? {
        val base = File(c.applicationInfo.sourceDir)
        val split = !c.applicationInfo.splitSourceDirs.isNullOrEmpty()
        val own = if (split) null else ownSha(c, base)
        val variant = own?.let { r.known[it] }?.takeIf { it in r.apks } ?: guessVariant(base).takeIf { it in r.apks } ?: "universal"
        val target = r.apks[variant] ?: return null
        val patch = own?.let { o -> r.patches.firstOrNull { it.from == o && it.variant == variant } }
        return Plan(variant, target, patch)
    }

    /** The installed APK's SHA-256, cached for as long as that file is the same. */
    private fun ownSha(c: Context, base: File): String? {
        val key = "${base.path}|${base.length()}|${base.lastModified()}"
        val p = prefs(c)
        if (p.getString("ownKey", null) == key) p.getString("ownSha", null)?.let { return it }
        val sha = runCatching { sha256(base) }.getOrNull() ?: return null
        p.edit().putString("ownKey", key).putString("ownSha", sha).apply()
        return sha
    }

    /** universal when the APK carries more than one processor's code, else that processor's name. */
    private fun guessVariant(base: File): String = runCatching {
        ZipFile(base).use { z ->
            val abis = z.entries().asSequence().map { it.name }.filter { it.startsWith("lib/") }
                .map { it.split('/').getOrNull(1) }.filterNotNull().toSet()
            if (abis.size == 1) abis.first() else "universal"
        }
    }.getOrDefault("universal")

    // ---------- updating ----------

    private fun start(c0: Context) {
        val c = c0.applicationContext
        val r = release ?: throw FeatureException("failed", "check first")
        val p = plan ?: throw FeatureException("failed", "no file for this phone")
        set("downloading", 0.0)
        worker.execute {
            try {
                val apk = File(dir(c), "waaiya-${r.versionCode}-${p.variant}.apk")
                if (!(apk.length() == p.target.size && sha256(apk) == p.target.sha256)) {
                    clean(c, keep = null)
                    val need = p.target.size + (p.patch?.asset?.size ?: 0) + (32L shl 20)
                    if (dir(c).usableSpace < need) { set("error", 0.0, "space"); return@execute }
                    val viaPatch = p.patch?.let { patch -> runCatching { byPatch(c, patch, p.target, apk) }.getOrElse { Log.w(TAG, "patch: $it"); false } } == true
                    if (!viaPatch) {
                        if (p.patch != null) Log.i(TAG, "patch failed: downloading the full APK")
                        if (!download(p.target, apk, 0.0, 1.0)) { set("error", 0.0, "network"); return@execute }
                    }
                }
                set("ready", 1.0)
                main.post { install(c, apk, r) }
            } catch (e: Exception) {
                Log.w(TAG, "update: $e")
                set("error", 0.0, "failed")
            }
        }
    }

    private fun byPatch(c: Context, patch: Patch, target: Asset, out: File): Boolean {
        val pf = File(dir(c), "patch-${patch.asset.sha256.take(16)}.zst")
        if (!download(patch.asset, pf, 0.0, 0.9)) return false
        set("preparing", 0.9)
        val err = AppUpdatePatch.apply(File(c.applicationInfo.sourceDir), pf, out, target.size)
        pf.delete()
        if (err != null) { Log.w(TAG, "rebuild: $err"); out.delete(); return false }
        if (out.length() != target.size || sha256(out) != target.sha256) { Log.w(TAG, "rebuilt APK differs from the release"); out.delete(); return false }
        return true
    }

    /** Downloads (resuming a partial file) and checks size and SHA-256; progress goes from [from] to [to]. */
    private fun download(a: Asset, dest: File, from: Double, to: Double): Boolean {
        repeat(3) { attempt ->
            try {
                var have = if (dest.isFile) dest.length() else 0L
                if (have > a.size) { dest.delete(); have = 0 }
                if (have < a.size) {
                    val conn = (URL(a.url).openConnection() as HttpURLConnection).apply {
                        connectTimeout = 15000; readTimeout = 30000; instanceFollowRedirects = false
                        setRequestProperty("User-Agent", USER_AGENT)
                        if (have > 0) setRequestProperty("Range", "bytes=$have-")
                    }
                    try {
                        val code = conn.responseCode
                        if (code == 200) have = 0 else if (code != 206) throw java.io.IOException("HTTP $code")
                        conn.inputStream.use { input ->
                            FileOutputStream(dest, have > 0).use { out ->
                                val buf = ByteArray(1 shl 16)
                                var got = have
                                var shown = -1
                                while (true) {
                                    val n = input.read(buf)
                                    if (n < 0) break
                                    got += n
                                    if (got > a.size) throw java.io.IOException("larger than announced")
                                    out.write(buf, 0, n)
                                    val pct = (100 * got / a.size).toInt()
                                    if (pct != shown) { shown = pct; set(state, from + (to - from) * got / a.size) }
                                }
                            }
                        }
                    } finally { conn.disconnect() }
                }
                if (dest.length() == a.size && sha256(dest) == a.sha256) return true
                Log.w(TAG, "download: wrong file, starting again"); dest.delete()
            } catch (e: Exception) {
                Log.w(TAG, "download (attempt ${attempt + 1}): $e")
                Thread.sleep(2000L * (attempt + 1))
            }
        }
        return false
    }

    /** Main thread. Checks the APK, then hands it to Android's installer (or asks for the permission first). */
    fun install(context: Context, apk: File, r: Release) {
        val c = context.applicationContext
        val why = AppUpdateInstall.verify(c, apk, r.versionCode)
        if (why != null) { Log.w(TAG, "install: $why"); apk.delete(); set("error", 0.0, "bad_file"); return }
        if (!c.packageManager.canRequestPackageInstalls()) {
            set("permission", 1.0)
            val i = Intent(AndroidSettings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${c.packageName}"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            runCatching { c.startActivity(i) }
            return
        }
        if (FilterService.running) {
            // filtering was started while the update downloaded: the same gate as Stop, or wait for the next tap
            try { Protection.checkStop(c) } catch (e: FeatureException) { set("ready", 1.0); return }
            c.startService(Intent(c, FilterService::class.java).setAction(FilterService.ACTION_STOP))
        }
        set("installing", 1.0)
        AppUpdateInstall.commit(c, apk)?.let { set("error", 1.0, "install") }
    }

    /** From the installer's answer ([AppUpdateInstall]): the user cancelled, or it failed. */
    fun installEnded(failed: Boolean) = set(if (failed) "error" else "ready", 1.0, if (failed) "install" else null)

    /** Removes downloads that are not for [keep]. After an update (the new version runs), everything goes. */
    private fun clean(c: Context, keep: File?) {
        dir(c).listFiles()?.forEach { if (it != keep && !it.name.startsWith("patch-")) it.delete() }
    }

    // ---------- the daily check, the notification ----------

    /** Called when the app starts: plans (or cancels) the daily check; a finished update's files are removed. */
    fun schedule(context: Context) {
        val c = context.applicationContext
        if (!BuildConfig.SELF_UPDATE) return
        if (prefs(c).getLong("cleanedFor", 0) != BuildConfig.VERSION_CODE.toLong()) {
            worker.execute { runCatching { dir(c).deleteRecursively() } }
            prefs(c).edit().putLong("cleanedFor", BuildConfig.VERSION_CODE.toLong()).apply()
        }
        AppUpdateJob.schedule(c, auto(c))
    }

    private fun announce(c: Context, r: Release, p: Plan) {
        val nm = c.getSystemService(NotificationManager::class.java)
        if (!nm.areNotificationsEnabled()) return
        nm.createNotificationChannel(NotificationChannel(CHANNEL, c.getString(R.string.notif_update_channel), NotificationManager.IMPORTANCE_DEFAULT))
        val open = UiActivity.open(c, "settings") ?: UiActivity.main(c)
        val pi = PendingIntent.getActivity(c, NOTIFICATION_ID, open.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val n = Notification.Builder(c, CHANNEL)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(c.getString(R.string.notif_update_title, r.versionName))
            .setContentText(c.getString(R.string.notif_update_text, sizeText(p.download)))
            .setContentIntent(pi).setAutoCancel(true).build()
        nm.notify(NOTIFICATION_ID, n)
    }

    private fun sizeText(bytes: Long): String =
        if (bytes >= 10L shl 20) "${bytes shr 20} MB" else String.format(java.util.Locale.ROOT, "%.1f MB", bytes / 1048576.0)

    // ---------- small helpers ----------

    private fun fetchText(url: String): String {
        val conn = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 15000; readTimeout = 15000; instanceFollowRedirects = false
            setRequestProperty("User-Agent", USER_AGENT); setRequestProperty("Cache-Control", "no-cache")
            useCaches = false
        }
        try {
            if (conn.responseCode != 200) throw java.io.IOException("HTTP ${conn.responseCode}")
            val bytes = conn.inputStream.use { it.readNBytesCompat(256 * 1024) }
            return String(bytes, Charsets.UTF_8)
        } finally { conn.disconnect() }
    }

    private fun java.io.InputStream.readNBytesCompat(max: Int): ByteArray {
        val out = java.io.ByteArrayOutputStream()
        val buf = ByteArray(8192)
        while (true) {
            val n = read(buf); if (n < 0) break
            out.write(buf, 0, n)
            if (out.size() > max) throw java.io.IOException("release file too large")
        }
        return out.toByteArray()
    }

    fun sha256(f: File): String {
        val md = MessageDigest.getInstance("SHA-256")
        RandomAccessFile(f, "r").use { raf ->
            val buf = ByteArray(1 shl 16)
            while (true) { val n = raf.read(buf); if (n < 0) break; md.update(buf, 0, n) }
        }
        return md.digest().joinToString("") { "%02x".format(it) }
    }

    private const val DAY = 24 * 3600 * 1000L
    private const val HOUR = 3600 * 1000L
}
