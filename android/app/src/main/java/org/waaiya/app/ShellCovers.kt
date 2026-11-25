package org.waaiya.app

import android.content.Context
import android.graphics.Rect
import android.os.Binder
import android.os.Handler
import android.os.IBinder
import android.os.ParcelFileDescriptor
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.SurfaceControl
import android.annotation.TargetApi
import kotlin.concurrent.thread

/**
 * Screen-blur covers drawn by the shell instead of an app window (Android 12+, Waaiya's helper [CoverHelper] running).
 *
 * Why: an app overlay that hides content also swallows the touches under it (Android 12+), and an accessibility
 * overlay (which does not) makes Google Play Protect block the sideloaded app. A shell-uid process may instead
 * create a top-level SurfaceFlinger layer (it holds ACCESS_SURFACE_FLINGER) and mark it as a trusted overlay
 * (touches pass through it) and skip-screenshot (left out of the screen capture, so the detector keeps seeing
 * what is under the covers). Checked against AOSP 14/15 sources; recipe follows ColorFade.java.
 *
 * Safety: the covers are plain colour layers with no input of their own. They are removed when the app dies
 * (linkToDeath), hidden when no update came for 2.5 s, and removed when the service stops.
 *
 * This file holds both sides: [ShellCovers] (in the app) and [CoverService] (in the helper's process).
 */
@TargetApi(31)
class ShellCovers(private val ctx: Context) {
    private val main = Handler(Looper.getMainLooper())
    private val token = Binder()
    @Volatile private var svc: ICoverService? = null

    val alive: Boolean get() = svc?.asBinder()?.isBinderAlive == true

    /** Set (from the health thread) when the shell process reported a draw error or the health call threw: the
     *  covers may not be on screen, so the caller falls back to a window. */
    @Volatile var failed = false
        private set
    @Volatile private var checking = false

    /** Who hosts the layer (diagnostics). */
    val via = "Waaiya helper"

    /** Starts the layer in Waaiya's helper. [done] runs on the main thread: true = covers can be drawn; false at once
     *  when the helper is not running (the caller then draws in windows). */
    fun connect(done: (Boolean) -> Unit) {
        val s = CoverHelper.service ?: run { main.post { done(false) }; return }
        thread(name = "im-covers-start") {
            val ok = runCatching { s.start(token) }.onFailure { Log.w(TAG, "covers: helper start failed", it) }
                .getOrDefault(false)
            if (ok) svc = s
            main.post { done(ok) }
        }
    }

    /** rects: count records of 8 floats (x0, y0, x1, y1 in display pixels, kind, r, g, b). One-way: never blocks. */
    fun update(rects: FloatArray, count: Int) {
        runCatching { svc?.update(rects, count) }.onFailure { svc = null }
    }

    /**
     * Asks the shell process whether the last updates were drawn ([failed] turns true if not). Called twice a
     * second; the two-way call runs on its own thread so the main thread never waits on the shell.
     */
    fun checkHealth() {
        val s = svc ?: return
        if (checking || failed) return
        checking = true
        thread(name = "im-covers-health") {
            val h = runCatching { s.health() }.onFailure { Log.w(TAG, "covers: health call failed", it) }.getOrDefault(-1)
            if (h != 0) { Log.w(TAG, "covers: shell layer reports $h"); failed = true }
            checking = false
        }
    }

    fun stop() {
        val s = svc
        svc = null
        thread(name = "im-covers-stop") {
            runCatching { s?.stop() }  // the helper stays for the next blur
        }
    }

    companion object {
        private const val TAG = "IslamicMute"
        const val RECORD = 8
        // kinds beyond Vision's (1..4)
        const val KIND_FAIL_COVER = 90   // the blur cannot keep up and the user chose "cover the screen": opaque
        const val KIND_BADGE = 91        // warning bar
        const val KIND_TEST = 99         // self-test square
    }
}

/**
 * The layer's side in Waaiya's helper ([CoverHelper]: shell uid, own app_process, not in the manifest). Hidden
 * SurfaceControl methods are called by reflection; hidden-API checks do not apply to app_process processes.
 * Only [allowedUid] (the app) may call it, and destroy() does not end the helper.
 */
class CoverService(private val allowedUid: Int) : ICoverService.Stub() {
    private companion object {
        /** Colour layers at most: the app's rects (Vision.MAX_RECTS, outlines as strips) plus badge and test square. */
        const val MAX_LAYERS = Vision.MAX_RECTS + 2
    }

    private val lock = Any()
    private var root: SurfaceControl? = null
    private val covers = ArrayList<SurfaceControl>()
    private var app: IBinder? = null
    @Volatile private var last = 0L
    @Volatile private var shown = false
    /** An update failed since the last health() call. */
    @Volatile private var updateFailed = false
    private val death = IBinder.DeathRecipient { clear() }

    init {
        thread(isDaemon = true, name = "covers-watchdog") {
            while (true) {
                Thread.sleep(500)
                if (shown && SystemClock.uptimeMillis() - last > 2500) hideAll() // the app stopped talking: uncover
            }
        }
    }

    private fun checkCaller() {
        if (Binder.getCallingUid() != allowedUid) throw SecurityException("not Waaiya")
    }

    override fun destroy() { checkCaller(); clear() }

    override fun start(app: IBinder): Boolean = synchronized(lock) {
        checkCaller()
        clear()
        try {
            val b = SurfaceControl.Builder().setName("waaiya-covers")
            call(b, "setContainerLayer")
            val r = b.build()
            val t = SurfaceControl.Transaction()
            call(t, "setLayerStack", r, 0)             // the default display
            t.setLayer(r, 1_000_000)                   // above WindowManager's whole tree (its root layer is at 0)
            setTrusted(t, r)                           // touches pass through (InputDispatcher skips trusted overlays)
            call(t, "setSkipScreenshot", r, true)      // not in screen capture / screenshots
            t.setVisibility(r, true)
            t.apply()
            root = r
            // Probe: one cover through every call update() makes, left hidden. update() is one-way, so an error
            // there never reaches the app; here it does, and the app then draws with a window instead.
            val probe = newCover(r)
            covers += probe
            val pt = SurfaceControl.Transaction()
            configure(pt, probe, 0, 0, 1, 1, Vision.KIND_WOMAN, floatArrayOf(0f, 0f, 0f))
            pt.setVisibility(probe, false)
            pt.apply()
            this.app = app
            app.linkToDeath(death, 0)
            last = SystemClock.uptimeMillis()
            updateFailed = false
            true
        } catch (e: Throwable) {
            Log.e("IslamicMute", "covers: cannot create the layer", e)
            clear()
            false
        }
    }

    override fun update(rects: FloatArray, count: Int): Unit = synchronized(lock) {
        if (allowedUid >= 0 && Binder.getCallingUid() != allowedUid) return@synchronized  // one-way: drop, no throw
        val r = root ?: return@synchronized
        last = SystemClock.uptimeMillis()
        val n = count.coerceIn(0, rects.size / ShellCovers.RECORD).coerceAtMost(MAX_LAYERS)
        val t = SurfaceControl.Transaction()
        try {
            while (covers.size < n) covers += newCover(r)
            for ((i, c) in covers.withIndex()) {
                if (i >= n) { t.setVisibility(c, false); continue }
                val o = i * ShellCovers.RECORD
                val x0 = rects[o].toInt(); val y0 = rects[o + 1].toInt()
                val w = (rects[o + 2] - rects[o]).toInt().coerceAtLeast(1)
                val h = (rects[o + 3] - rects[o + 1]).toInt().coerceAtLeast(1)
                val kind = rects[o + 4].toInt()
                val rgb = when (kind) {
                    ShellCovers.KIND_TEST -> floatArrayOf(1f, 0f, 1f)
                    ShellCovers.KIND_BADGE -> floatArrayOf(0.8f, 0.15f, 0.15f)
                    else -> floatArrayOf(rects[o + 5], rects[o + 6], rects[o + 7])
                }
                configure(t, c, x0, y0, w, h, kind, rgb)
                t.setVisibility(c, true)
            }
            t.apply()
            shown = n > 0
        } catch (e: Throwable) {
            // one-way call: the app learns of this through health()
            updateFailed = true
            Log.e("IslamicMute", "covers: update failed", e)
        }
    }

    override fun health(): Int = synchronized(lock) {
        checkCaller()
        val r = when { root == null -> 1; updateFailed -> 2; else -> 0 }
        updateFailed = false
        r
    }

    private fun newCover(parent: SurfaceControl): SurfaceControl {
        val b = SurfaceControl.Builder().setName("waaiya-cover").setParent(parent)
        call(b, "setEffectLayer")
        return b.build()
    }

    /** Position, size, colour and corners of one cover (the same calls for the start() probe and update()). */
    private fun configure(t: SurfaceControl.Transaction, c: SurfaceControl, x0: Int, y0: Int, w: Int, h: Int, kind: Int,
                          rgb: FloatArray) {
        call(t, "setPosition", c, x0.toFloat(), y0.toFloat()) // public from API 33, hidden on 31-32
        call(t, "setCrop", c, Rect(0, 0, w, h))
        call(t, "setColor", c, rgb)
        t.setAlpha(c, 1f)                         // opaque: nothing of what is under shows through
        // square corners for the whole screen and for strips of an outline (they stack into one shape)
        val square = kind == Vision.KIND_FULL || kind == ShellCovers.KIND_FAIL_COVER ||
            (kind < ShellCovers.KIND_FAIL_COVER && (kind and Vision.KIND_PART) != 0)
        runCatching { call(t, "setCornerRadius", c, if (square) 0f else 24f) }
        t.setLayer(c, if (kind == ShellCovers.KIND_BADGE || kind == ShellCovers.KIND_TEST) 10 else 1)
    }

    override fun stop() { checkCaller(); clear() }

    override fun dumpAudio(service: String, sink: ParcelFileDescriptor): Boolean {
        try {
            checkCaller()
            if (service !in HelperDumps.SERVICES) return false
            // as SessionMuter.dump() does with its own DUMP permission: the service writes into the app's pipe in
            // the background (one-way), so a full pipe never blocks this call; the app reads until the end
            val b = Class.forName("android.os.ServiceManager").getMethod("getService", String::class.java)
                .invoke(null, service) as? IBinder ?: return false
            b.dumpAsync(sink.fileDescriptor, arrayOf())
            return true
        } finally {
            runCatching { sink.close() }  // the service holds its own copy
        }
    }

    override fun dumpVisibleApps(sink: ParcelFileDescriptor): Boolean {
        try {
            checkCaller()
            val b = Class.forName("android.os.ServiceManager").getMethod("getService", String::class.java)
                .invoke(null, "window") as? IBinder ?: return false
            b.dumpAsync(sink.fileDescriptor, arrayOf("visible-apps"))
            return true
        } finally {
            runCatching { sink.close() }
        }
    }

    override fun putScreenShareProtection(value: Int): Boolean {
        checkCaller()
        if (value != 0 && value != 1) return false
        return runCatching { HelperDumps.putGlobal(ScreenShareProtection.KEY, value.toString()) }
            .onFailure { Log.w("IslamicMute", "helper: cannot write ${ScreenShareProtection.KEY}", it) }.getOrDefault(false)
    }

    private fun hideAll(): Unit = synchronized(lock) {
        val t = SurfaceControl.Transaction()
        covers.forEach { t.setVisibility(it, false) }
        runCatching { t.apply() }
        shown = false
    }

    private fun clear(): Unit = synchronized(lock) {
        val t = SurfaceControl.Transaction()
        covers.forEach { t.reparent(it, null) }
        root?.let { t.reparent(it, null) }
        runCatching { t.apply() }
        covers.forEach { it.release() }
        covers.clear()
        root?.release()
        root = null
        shown = false
        runCatching { app?.unlinkToDeath(death, 0) }
        app = null
    }

    /** setTrustedOverlay(SurfaceControl, boolean); newer releases may only have an int overload (1 = enabled). */
    private fun setTrusted(t: SurfaceControl.Transaction, sc: SurfaceControl) {
        val ms = t.javaClass.methods.filter { it.name == "setTrustedOverlay" && it.parameterTypes.size == 2 }
        val m = ms.firstOrNull { it.parameterTypes[1] == java.lang.Boolean.TYPE } ?: ms.first()
        m.isAccessible = true
        if (m.parameterTypes[1] == java.lang.Boolean.TYPE) m.invoke(t, sc, true) else m.invoke(t, sc, 1)
    }

    private fun call(target: Any, name: String, vararg args: Any): Any? {
        var cls: Class<*>? = target.javaClass
        while (cls != null) {
            val m = cls.declaredMethods.firstOrNull { it.name == name && it.parameterTypes.size == args.size }
            if (m != null) { m.isAccessible = true; return m.invoke(target, *args) }
            cls = cls.superclass
        }
        throw NoSuchMethodException("${target.javaClass.name}.$name/${args.size}")
    }
}
