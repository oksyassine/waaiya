package org.islamicmute.app

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.os.Process
import android.os.SystemClock
import android.util.Log
import android.widget.Toast
import java.io.ByteArrayOutputStream
import java.io.FileInputStream
import java.lang.ref.WeakReference

/**
 * Fix mistakes on the spot (docs/FEATURES_CONTRACT.md, lane A; roadmap item 5):
 *
 * - **Filter off for chosen apps** ([Settings.filterOffApps]): their sound is neither captured by the live filter
 *   (FilterService builds its capture with [filterOffUids] excluded and rebuilds it when the list changes) nor muted by
 *   [SessionMuter], so they play their original sound. A package that cannot be resolved stays filtered.
 * - **Blur off for chosen apps** ([Settings.blurOffApps]): no covers while such an app is the only one on screen. The
 *   app on screen is read from the window manager's dump ([FixMistakesForeground]), which needs the DUMP permission of
 *   the one-time setup; elsewhere (helper mode, accessibility build or no setup without DUMP) the option is shown
 *   disabled and the covers stay. A reading that failed or is older than [FixMistakesForeground.STALE_MS] keeps the
 *   covers ([blurPaused]).
 * - **Cover an area by hand**: [FixMistakesActivity] (from the filter's notification or the Screen page) adds an opaque cover
 *   drawn by the blur's own cover host ([BlurOverlay]) until "Remove hand covers" or until the blur stops. Not kept.
 * - **Wrong-detection notes**: [FixMistakesNotes], an app-private file, never sent anywhere.
 *
 * Changes to the two app lists go through UiBridge.setSetting, so the protection guard sees them.
 */
object FixMistakes : Feature {
    override val name = "fix"
    private const val TAG = "IslamicMute"
    private const val OLD_CHANNEL = "fix"
    private const val OLD_NOTIFICATION_ID = 7
    private const val ACTION = "org.islamicmute.app.FIX"
    private const val EXTRA_WHAT = "what"
    private const val EXTRA_TOKEN = "token"
    /** At most this many hand covers (each is one layer or window region). */
    const val MAX_HAND_COVERS = 12

    private val main = Handler(Looper.getMainLooper())
    /** Notification actions carry it: the runtime receiver ignores broadcasts from anyone who does not know it. */
    private val token = java.util.UUID.randomUUID().toString()

    // ------------------------------------------------------------------ filter off for apps

    private var uidKey: String? = null
    private var uidSet: Set<Int> = emptySet()
    private var uidAt = 0L

    /**
     * The uids of [Settings.filterOffApps] (FilterService's capture and SessionMuter leave them alone). Packages that
     * cannot be resolved, Waaiya itself and system uids (shared by many system apps) are left out: they stay filtered.
     * Cached; resolved again when the list changes and every 30 s (an app installed or updated).
     */
    @Synchronized
    fun filterOffUids(ctx: Context, settings: Settings): Set<Int> {
        val apps = settings.filterOffApps
        val key = apps.sorted().joinToString(",")
        val now = SystemClock.uptimeMillis()
        if (key == uidKey && now - uidAt < 30_000) return uidSet
        val me = Process.myUid()
        uidSet = apps.mapNotNull { pkg ->
            runCatching { ctx.packageManager.getApplicationInfo(pkg, 0).uid }.getOrNull()
                ?.takeIf { it != me && it >= Process.FIRST_APPLICATION_UID }
        }.toSet()
        uidKey = key
        uidAt = now
        return uidSet
    }

    // ------------------------------------------------------------------ blur off for apps

    @Volatile private var screen: FixMistakesForeground.Screen? = null
    @Volatile private var screenAt = 0L
    @Volatile private var offApps: Set<String> = emptySet()
    @Volatile private var lastPaused = false
    @Volatile private var poller: Thread? = null
    @Volatile private var session = false
    /** Set by ScreenBlur: shows the covers again (main thread) when [blurPaused] changes. */
    @Volatile var onCoversChanged: (() -> Unit)? = null

    /** Where the app on screen cannot be read, the reason (`helper_mode`, `needs_setup`); null when it can. */
    fun blurAppsReason(ctx: Context): String? =
        FixMistakesForeground.unavailableReason(ctx.hasDumpPermission(), HelperDumps.helperMode(ctx), HelperDumps.helperReady)

    /** The covers are left off now: a fresh reading shows only an app the user chose. Any thread. */
    fun blurPaused(): Boolean =
        FixMistakesForeground.coversOff(screen, SystemClock.uptimeMillis() - screenAt, offApps)

    /** Reads the window list every [FixMistakesForeground.POLL_MS] while the blur runs and the list is not empty. */
    private fun startPoller(ctx: Context) {
        if (poller != null) return
        poller = Thread({
            val settings = Settings(ctx)
            while (session) {
                val off = settings.blurOffApps
                val viaHelper = !ctx.hasDumpPermission() && HelperDumps.helperMode(ctx) && HelperDumps.helperReady
                val use = off.isNotEmpty() && settings.blurOn && ScreenBlur.state != null &&
                    (ctx.hasDumpPermission() || viaHelper)
                if (!use) {
                    screen = null; offApps = off
                    changed()
                    sleep(500)
                    continue
                }
                val s = runCatching { FixMistakesForeground.parse(if (viaHelper) HelperDumps.readVisibleApps() else dumpWindows()) }
                    .onFailure { Log.w(TAG, "fix: window list not readable: $it") }.getOrNull()
                screen = s; screenAt = SystemClock.uptimeMillis(); offApps = off
                changed()
                sleep(FixMistakesForeground.POLL_MS)
            }
            screen = null
            changed()
            poller = null
        }, "im-fix-foreground").apply { isDaemon = true; start() }
    }

    private fun changed() {
        val p = blurPaused()
        if (p != lastPaused) {
            lastPaused = p
            Log.i(TAG, "fix: covers ${if (p) "off: ${screen?.app} is chosen" else "back"}")
            onCoversChanged?.invoke()
        }
    }

    private fun sleep(ms: Long) = runCatching { Thread.sleep(ms) }

    /** `dumpsys window visible-apps` through the window service (DUMP permission). Not on the main thread. */
    private fun dumpWindows(): String {
        val sm = Class.forName("android.os.ServiceManager")
        val binder = sm.getMethod("getService", String::class.java).invoke(null, "window") as IBinder
        val pipe = ParcelFileDescriptor.createPipe()
        try {
            binder.dumpAsync(pipe[1].fileDescriptor, arrayOf("visible-apps"))
            pipe[1].close()
            return FileInputStream(pipe[0].fileDescriptor).use { it.readBytes().toString(Charsets.UTF_8) }
        } finally {
            runCatching { pipe[1].close() }
            runCatching { pipe[0].close() }
        }
    }

    // ------------------------------------------------------------------ hand covers

    private val hand = ArrayList<FloatArray>()

    /** Hand covers as x0,y0,x1,y1 (0..1 of the screen) per cover. Any thread. */
    fun handCovers(): FloatArray = synchronized(hand) {
        val out = FloatArray(hand.size * 4)
        for ((i, r) in hand.withIndex()) System.arraycopy(r, 0, out, i * 4, 4)
        out
    }

    val handCoverCount: Int get() = synchronized(hand) { hand.size }

    /** A new hand cover (0..1 of the screen); ignored when the blur does not run. Returns whether it was added. */
    fun addHandCover(ctx: Context, x0: Float, y0: Float, x1: Float, y1: Float): Boolean {
        if (ScreenBlur.state == null) return false
        val r = floatArrayOf(minOf(x0, x1).coerceIn(0f, 1f), minOf(y0, y1).coerceIn(0f, 1f),
            maxOf(x0, x1).coerceIn(0f, 1f), maxOf(y0, y1).coerceIn(0f, 1f))
        if (r[2] - r[0] < 0.01f || r[3] - r[1] < 0.01f) return false
        synchronized(hand) {
            if (hand.size >= MAX_HAND_COVERS) hand.removeAt(0)
            hand += r
        }
        coversEdited()
        return true
    }

    /** "Remove hand covers", or the blur stopped (they are not kept across blur restarts). */
    fun clearHandCovers(ctx: Context?) {
        val had = synchronized(hand) { val n = hand.size; hand.clear(); n }
        if (had > 0) coversEdited()
    }

    private fun coversEdited() {
        onCoversChanged?.invoke()
        actionsChanged()
        refreshUi()
    }

    // ------------------------------------------------------------------ notes

    @Volatile private var noteCount = -1

    fun notesCount(ctx: Context): Int {
        if (noteCount < 0) noteCount = FixMistakesNotes.count(ctx.filesDir)
        return noteCount
    }

    /** Writes one note ([kind] `missed` or `wrong`, [where] `notification`, `filter`, `screen`). Returns the count. */
    fun addNote(ctx: Context, kind: String, where: String): Int {
        val settings = Settings(ctx)
        // the app on screen: the fresh reading of the blur's check, else one reading now (DUMP only). From the
        // notification the shade is open over that app; from Waaiya's own screens it is Waaiya (left out).
        val s = screen.takeIf { SystemClock.uptimeMillis() - screenAt <= FixMistakesForeground.STALE_MS }
            ?: if (ctx.hasDumpPermission()) runCatching { FixMistakesForeground.parse(dumpWindows()) }.getOrNull() else null
        val pkg = s?.focusedApps?.singleOrNull()?.takeIf { it != ctx.packageName }
        val app = pkg?.let { "${label(ctx, it)} ($it)" } ?: ""
        val h = FilterService.health
        val filter = "${FilterService.state.name}" +
            (if (FilterService.running) ", ${if (h?.mono != false) "mono" else "stereo"}" else "") +
            (if (settings.muteWomenSinging) ", women's singing muted" else "") +
            (if (pkg != null && pkg in settings.filterOffApps) ", this app is left unfiltered" else "")
        val blur = (ScreenBlur.state?.name ?: "off") +
            (if (settings.blurWomen) ", women" else "") + (if (settings.blurNudity) ", nudity" else "") +
            ", strictness ${settings.blurStrictness}" +
            (if (pkg != null && pkg in settings.blurOffApps) ", this app is left uncovered" else "") +
            (if (handCoverCount > 0) ", $handCoverCount hand cover(s)" else "")
        val models = listOfNotNull(
            h?.model?.let { "filter $it" },
            if (settings.muteWomenSinging && ModelStore.hasDetector(ctx)) "detector.onnx" else null,
            if (settings.blurOn) "blur ${listOf(ModelStore.BLUR_PERSON, ModelStore.BLUR_GENDER, ModelStore.BLUR_NSFW,
                ModelStore.BLUR_SEG).filter { ModelStore.hasAsset(ctx, it) }.joinToString(" ")}" else null,
        ).joinToString("; ")
        val time = java.time.LocalDateTime.now().withNano(0).toString().replace('T', ' ')
        val n = FixMistakesNotes.add(ctx.filesDir,
            FixMistakesNotes.Note(time, kind, where, app, filter, blur, "Waaiya ${BuildConfig.VERSION_NAME}; $models"))
        noteCount = n
        return n
    }

    // ------------------------------------------------------------------ app names and the picker list

    private val labels = HashMap<String, String>()
    private val icons = HashMap<String, ByteArray>()

    private fun label(ctx: Context, pkg: String): String = synchronized(labels) {
        labels.getOrPut(pkg) {
            runCatching { ctx.packageManager.getApplicationLabel(ctx.packageManager.getApplicationInfo(pkg, 0)).toString() }
                .getOrDefault(pkg)
        }
    }

    /**
     * Apps with a launcher icon (the manifest's <queries> makes them visible), not Waaiya. Apps sharing a system uid
     * (Settings, some phones' gallery) only for the blur list ([systemToo]): the blur matches windows by package, but
     * the capture and the muter work by uid, and leaving a system uid unfiltered would leave every app on it.
     */
    private fun launchableApps(ctx: Context, systemToo: Boolean): List<Map<String, Any?>> {
        val pm = ctx.packageManager
        val acts = pm.queryIntentActivities(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER), 0)
        return acts.map { it.activityInfo.applicationInfo }.distinctBy { it.packageName }
            .filter { it.packageName != ctx.packageName && (systemToo || it.uid >= Process.FIRST_APPLICATION_UID) }
            .map { ai ->
                val l = runCatching { pm.getApplicationLabel(ai).toString() }.getOrDefault(ai.packageName)
                synchronized(labels) { labels[ai.packageName] = l }
                mapOf("package" to ai.packageName, "label" to l, "icon" to icon(ctx, ai))
            }
            .sortedBy { (it["label"] as String).lowercase() }
    }

    /** A small PNG of the app's icon (cached), or null. */
    private fun icon(ctx: Context, ai: android.content.pm.ApplicationInfo): ByteArray? = synchronized(icons) {
        icons[ai.packageName] ?: runCatching {
            val d = ctx.packageManager.getApplicationIcon(ai)
            val px = (40 * ctx.resources.displayMetrics.density).toInt().coerceIn(32, 128)
            val bm = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
            d.setBounds(0, 0, px, px)
            d.draw(Canvas(bm))
            ByteArrayOutputStream().also { bm.compress(Bitmap.CompressFormat.PNG, 100, it); bm.recycle() }.toByteArray()
        }.getOrNull()?.also { icons[ai.packageName] = it }
    }

    // ------------------------------------------------------------------ Feature (Flutter)

    private var hostRef: WeakReference<FeatureHost>? = null

    private fun refreshUi() = main.post { hostRef?.get()?.refresh() }

    override fun snapshot(host: FeatureHost): Map<String, Any?> {
        hostRef = WeakReference(host)
        val ctx = host.activity
        val s = Settings(ctx)
        val reason = blurAppsReason(ctx)
        return mapOf(
            "filterApps" to true,
            "blurApps" to (reason == null),
            "blurAppsReason" to reason,
            "handCover" to true,
            "handCovers" to handCoverCount,
            "blurRunning" to (ScreenBlur.state != null),
            "notes" to notesCount(ctx),
            // display names of the apps in either list (package -> label)
            "labels" to (s.filterOffApps + s.blurOffApps).associateWith { label(ctx, it) },
        )
    }

    override fun call(host: FeatureHost, method: String, args: Map<String, Any?>): Any? {
        hostRef = WeakReference(host)
        val ctx = host.activity
        return when (method) {
            // {list: blur_off_apps | filter_off_apps}: which list the picker adds to (filter_off_apps when absent)
            "apps" -> launchableApps(ctx, systemToo = args["list"] == "blur_off_apps")
            "coverArea" -> {
                if (ScreenBlur.state == null) return "blur_off"
                ctx.startActivity(FixMistakesActivity.intent(ctx))
                "opened"
            }
            "removeCovers" -> { clearHandCovers(ctx); host.refresh(); null }
            "note" -> {
                val kind = args["kind"] as? String
                if (kind !in FixMistakesNotes.KINDS) throw FeatureException("bad_args", "kind is missed or wrong")
                val where = (args["where"] as? String)?.takeIf { it in setOf("filter", "screen") } ?: "app"
                addNote(ctx, kind!!, where).also { host.refresh() }
            }
            "notes" -> FixMistakesNotes.text(FixMistakesNotes.read(ctx.filesDir),
                "Waaiya ${BuildConfig.VERSION_NAME}: wrong-detection notes (kept on this phone only)")
            "clearNotes" -> { FixMistakesNotes.clear(ctx.filesDir); noteCount = 0; host.refresh(); null }
            else -> throw FeatureException("unsupported", "fix.$method")
        }
    }

    // ------------------------------------------------------------------ session and notification

    private var receiver: BroadcastReceiver? = null
    private val blurListener: () -> Unit = { actionsChanged() }

    /** Filtering started (ScreenBlur runs, parked or not, for the whole filtering session). Main thread. */
    fun sessionStarted(context: Context) {
        val ctx = context.applicationContext
        session = true
        shownKinds = null
        startPoller(ctx)
        if (receiver == null) {
            val r = object : BroadcastReceiver() {
                override fun onReceive(c: Context, i: Intent) {
                    if (i.getStringExtra(EXTRA_TOKEN) != token) return
                    when (val what = i.getStringExtra(EXTRA_WHAT)) {
                        "remove" -> clearHandCovers(ctx)
                        "missed", "wrong" -> {
                            // a dump may take a moment: not on the main thread
                            Thread {
                                runCatching { addNote(ctx, what, "notification") }
                                    .onSuccess { n -> main.post {
                                        Toast.makeText(Lang.wrap(ctx), Lang.wrap(ctx).getString(R.string.notif_fix_noted, n),
                                            Toast.LENGTH_SHORT).show()
                                        refreshUi()
                                    } }
                                    .onFailure { Log.w(TAG, "fix: note not written: $it") }
                            }.start()
                        }
                    }
                }
            }
            val f = IntentFilter(ACTION)
            if (Build.VERSION.SDK_INT >= 33) ctx.registerReceiver(r, f, Context.RECEIVER_NOT_EXPORTED)
            else @Suppress("UnspecifiedRegisterReceiverFlag") ctx.registerReceiver(r, f)
            receiver = r
        }
        ScreenBlur.addListener(blurListener)
        // the separate "Fix a mistake" notification of the first 0.2.13 builds: gone, with its channel
        runCatching {
            val nm = ctx.getSystemService(NotificationManager::class.java)
            nm.cancel(OLD_NOTIFICATION_ID)
            nm.deleteNotificationChannel(OLD_CHANNEL)
        }
        actionsChanged()
    }

    /** Filtering ended: no hand covers, no poller, no notification. Main thread. */
    fun sessionEnded(context: Context) {
        val ctx = context.applicationContext
        session = false
        shownKinds = null
        ScreenBlur.removeListener(blurListener)
        clearHandCovers(null)
        receiver?.let { runCatching { ctx.unregisterReceiver(it) } }
        receiver = null
        FilterService.refreshNotification()
        refreshUi()
    }

    private fun broadcast(ctx: Context, what: String, code: Int): PendingIntent =
        PendingIntent.getBroadcast(ctx, code, Intent(ACTION).setPackage(ctx.packageName)
            .putExtra(EXTRA_WHAT, what).putExtra(EXTRA_TOKEN, token),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

    /**
     * The fix actions, carried by the filter's own notification after its Stop (FilterService.notification), never by
     * a notification of their own: Android 15+ hides every notification but the foreground service's while the screen
     * is captured, and two notifications of one app are grouped under one hidden summary, which took the filter's
     * Stop with it. Android shows three actions, so at most two here ([FixMistakesActions.kinds]). Empty outside a
     * filtering session.
     */
    fun notificationActions(context: Context): List<Notification.Action> {
        if (!session) return emptyList()
        val ctx = Lang.wrap(context)
        return FixMistakesActions.kinds(ScreenBlur.state != null, handCoverCount).map { kind ->
            when (kind) {
                FixMistakesActions.COVER -> Notification.Action.Builder(null, ctx.getString(R.string.notif_fix_cover_area),
                    PendingIntent.getActivity(ctx, 71, FixMistakesActivity.intent(ctx),
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)).build()
                FixMistakesActions.REMOVE -> Notification.Action.Builder(null,
                    ctx.getString(R.string.notif_fix_remove_covers), broadcast(ctx, "remove", 72)).build()
                FixMistakesActions.MISSED -> Notification.Action.Builder(null,
                    ctx.getString(R.string.notif_fix_note_missed), broadcast(ctx, "missed", 73)).build()
                else -> Notification.Action.Builder(null,
                    ctx.getString(R.string.notif_fix_note_wrong), broadcast(ctx, "wrong", 74)).build()
            }
        }
    }

    /** The actions shown on the filter's notification; null: not shown yet in this session. */
    @Volatile private var shownKinds: List<String>? = null

    /**
     * Blur on or off, hand covers added or removed: the filter's notification is built again, only when its actions
     * change (the blur's state also changes as covers come and go).
     */
    private fun actionsChanged() {
        if (!session) return
        val kinds = FixMistakesActions.kinds(ScreenBlur.state != null, handCoverCount)
        if (kinds == shownKinds) return
        shownKinds = kinds
        FilterService.refreshNotification()
    }
}
