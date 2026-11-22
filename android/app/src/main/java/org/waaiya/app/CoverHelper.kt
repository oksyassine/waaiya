package org.waaiya.app

import android.content.AttributionSource
import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Binder
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.os.Looper
import android.os.Process
import android.util.Log
import java.io.File
import kotlin.concurrent.thread
import kotlin.system.exitProcess

/**
 * Waaiya's own helper for the screen-blur covers (Android 12+), so touches pass through them without Shizuku.
 *
 * The covers must be drawn by a shell-uid process ([CoverService]: a trusted, skip-screenshot SurfaceFlinger layer).
 * Shizuku is one such process. This is another: the one-time setup already talks to the phone's own adbd over
 * Wireless debugging ([WirelessSetup]), and through that connection it starts this class with app_process, as Shizuku
 * starts its server:
 *
 *     CLASSPATH=<apk> setsid app_process /system/bin --nice-name=waaiya_covers org.waaiya.app.CoverHelper <uid> <version>
 *
 * The helper hands its binder to the app through [CoverHelperProvider] (a content-provider call, as Shizuku does), and
 * again whenever the app's process starts anew. It lives until the phone restarts, or until USB debugging / Developer
 * options are turned off (adbd stops); turning only Wireless debugging off keeps it, like Shizuku.
 *
 * Safety: it only draws plain colour layers ([CoverService], no command execution); it serves only the app's uid,
 * and the provider accepts a binder only from the shell or root. An app update leaves the old helper running the old
 * APK: its version is checked and a new one is started by the next setup run.
 */
object CoverHelper {
    private const val TAG = "IslamicMute"
    const val PROCESS_NAME = "waaiya_covers"
    const val AUTHORITY_SUFFIX = ".coverhelper"
    const val METHOD = "covers"
    const val KEY_BINDER = "binder"
    const val KEY_VERSION = "version"

    // --- app side -----------------------------------------------------------------------------------------------------

    @Volatile private var binder: IBinder? = null
    @Volatile var version = 0
        private set
    private val listeners = java.util.concurrent.CopyOnWriteArraySet<() -> Unit>()
    fun addListener(l: () -> Unit) { listeners += l }
    fun removeListener(l: () -> Unit) { listeners -= l }

    /** The helper's cover service, when one is running for this app version. */
    val service: ICoverService? get() = binder?.takeIf { it.isBinderAlive && version == BuildConfig.VERSION_CODE }
        ?.let { ICoverService.Stub.asInterface(it) }

    /** A helper can draw the covers now (Android 12+). */
    val available: Boolean get() = Build.VERSION.SDK_INT >= 31 && service != null

    /** A helper is running, but from an older Waaiya: the setup must start a new one. */
    val stale: Boolean get() = binder?.isBinderAlive == true && version != BuildConfig.VERSION_CODE

    internal fun received(b: IBinder, v: Int) {
        binder = b
        version = v
        runCatching { b.linkToDeath({ binder = null; notifyListeners() }, 0) }
        Log.i(TAG, "cover helper: connected (version $v)")
        notifyListeners()
    }

    private fun notifyListeners() {
        android.os.Handler(Looper.getMainLooper()).post { listeners.forEach { it() } }
    }

    /**
     * The shell line that (re)starts the helper: stops an older one, then starts this APK's in its own session so it
     * outlives the adb connection. Run by [WirelessSetupService] after the grants.
     *
     * The shell must not exit at once: adbd ends the session (and its process group) as soon as it does, and a
     * background child that has not reached setsid yet goes with it (seen on the emulator: one run in two). So it
     * waits, up to 5 s, until the helper runs under its own name, and says whether it does (`helper=started` or
     * `helper=missing`, kept in the setup log).
     */
    fun startCommand(ctx: Context): String {
        val pkg = ctx.packageName
        val uid = ctx.applicationInfo.uid
        return "for p in \$(pidof $PROCESS_NAME); do kill \$p; done; " +
            // the old one gone first, so that the check below sees the new one
            "for i in 1 2 3 4 5; do pidof $PROCESS_NAME >/dev/null || break; sleep 0.2; done; " +
            "P=\$(pm path $pkg | head -n 1 | cut -d: -f2); " +
            "CLASSPATH=\$P setsid app_process /system/bin --nice-name=$PROCESS_NAME ${CoverHelper::class.java.name} " +
            "$uid ${BuildConfig.VERSION_CODE} </dev/null >/dev/null 2>&1 & " +
            "for i in 1 2 3 4 5 6 7 8 9 10; do sleep 0.5; pidof $PROCESS_NAME >/dev/null && break; done; " +
            "pidof $PROCESS_NAME >/dev/null && echo helper=started || echo helper=missing"
    }

    // --- helper side (shell uid, app_process) -------------------------------------------------------------------------

    /** Android 11+ (Wireless debugging): the covers need 12+, the audio dumps ([HelperDumps]) work on 11 too. */
    @JvmStatic
    fun main(args: Array<String>) {
        val appUid = args.getOrNull(0)?.toIntOrNull() ?: exitProcess(2)
        val appVersion = args.getOrNull(1)?.toIntOrNull() ?: 0
        val pkg = BuildConfig.APPLICATION_ID
        Looper.prepareMainLooper()
        val service = CoverService(allowedUid = appUid)
        val apk = File(System.getenv("CLASSPATH") ?: "")
        Log.i(TAG, "cover helper: started for uid $appUid, version $appVersion")
        thread(name = "waaiya-helper-watch", isDaemon = true) {
            var deliveredTo = -1
            var seen = -1
            while (true) {
                if (!apk.exists()) { Log.i(TAG, "cover helper: app updated or removed, exiting"); exitProcess(0) }
                val pid = appPid(pkg)
                // only when the app runs (a provider call would otherwise start its process), and not while it is
                // starting: the same process seen 2 s ago, so the call never competes with its launch
                if (pid > 0 && pid != deliveredTo && pid == seen) {
                    if (deliver(pkg, service, appVersion)) deliveredTo = pid
                } else if (pid <= 0) deliveredTo = -1
                seen = pid
                Thread.sleep(2000)
            }
        }
        Looper.loop()
    }

    /** The main process of the app (not ":setup" or other suffixes), or -1. */
    private fun appPid(pkg: String): Int = runCatching {
        File("/proc").listFiles()?.firstNotNullOfOrNull { d ->
            val pid = d.name.toIntOrNull() ?: return@firstNotNullOfOrNull null
            val cmd = runCatching { File(d, "cmdline").readText().substringBefore('\u0000') }.getOrNull()
            pid.takeIf { cmd == pkg }
        } ?: -1
    }.getOrDefault(-1)

    /** Hands the binder to the app's [CoverHelperProvider]: IActivityManager/IContentProvider by reflection (the
     *  same signatures Shizuku uses; hidden-API checks do not apply to app_process). Android 12+ calls the provider
     *  with an AttributionSource, Android 11 with (callingPkg, featureId). */
    private fun deliver(pkg: String, service: IBinder, version: Int): Boolean = runCatching {
        val authority = pkg + AUTHORITY_SUFFIX
        val am = Class.forName("android.app.ActivityManager").getMethod("getService").invoke(null)!!
        val token = Binder()
        val holder = am.javaClass.getMethod("getContentProviderExternal", String::class.java, Int::class.javaPrimitiveType,
            IBinder::class.java, String::class.java).invoke(am, authority, 0, token, "waaiya-helper")
            ?: error("no provider $authority")
        try {
            val provider = holder.javaClass.getField("provider").get(holder)!!
            val extras = Bundle().apply { putBinder(KEY_BINDER, service); putInt(KEY_VERSION, version) }
            if (Build.VERSION.SDK_INT >= 31) {
                val source = AttributionSource.Builder(Process.myUid()).setPackageName("com.android.shell").build()
                provider.javaClass.getMethod("call", AttributionSource::class.java, String::class.java, String::class.java,
                    String::class.java, Bundle::class.java).invoke(provider, source, authority, METHOD, null, extras)
            } else {
                provider.javaClass.getMethod("call", String::class.java, String::class.java, String::class.java,
                    String::class.java, String::class.java, Bundle::class.java)
                    .invoke(provider, "com.android.shell", null, authority, METHOD, null, extras)
            }
        } finally {
            runCatching {
                am.javaClass.getMethod("removeContentProviderExternalAsUser", String::class.java, IBinder::class.java,
                    Int::class.javaPrimitiveType).invoke(am, authority, token, 0)
            }
        }
        Log.i(TAG, "cover helper: binder handed to the app")
        true
    }.onFailure { Log.w(TAG, "cover helper: could not reach the app", it) }.getOrDefault(false)
}

/**
 * Receives the helper's binder. Exported, but protected by INTERACT_ACROSS_USERS_FULL (the shell and root hold it,
 * apps do not), and the caller is checked again: only uid 2000 (shell) or 0 (root).
 */
class CoverHelperProvider : ContentProvider() {
    override fun onCreate() = true

    override fun call(method: String, arg: String?, extras: Bundle?): Bundle? {
        val caller = Binder.getCallingUid()
        if (caller != 2000 && caller != 0) throw SecurityException("not the shell: $caller")
        if (method != CoverHelper.METHOD || extras == null) return null
        val b = extras.getBinder(CoverHelper.KEY_BINDER) ?: return null
        CoverHelper.received(b, extras.getInt(CoverHelper.KEY_VERSION))
        context?.applicationContext?.let { app ->
            app.helperArrived()
            // a write the helper could not do while it was stopped (ScreenShareProtection keeps a mark)
            if (ScreenShareProtection.shownInCapture == null)
                kotlin.concurrent.thread(name = "im-ssp-restore") { ScreenShareProtection.restore(app) }
        }
        return Bundle()
    }

    override fun query(uri: Uri, p: Array<out String>?, s: String?, a: Array<out String>?, o: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, s: String?, a: Array<out String>?) = 0
    override fun update(uri: Uri, v: ContentValues?, s: String?, a: Array<out String>?) = 0
}
