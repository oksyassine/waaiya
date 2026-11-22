package org.waaiya.app

import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.os.Process
import android.util.Log
import rikka.shizuku.Shizuku
import kotlin.concurrent.thread
import kotlin.system.exitProcess

/**
 * One-tap setup through Shizuku (https://shizuku.rikka.app), for users without a computer.
 *
 * Shizuku runs a privileged server as the shell user (or root). Through it we do once what the ADB
 * instructions do:
 *   pm grant <pkg> android.permission.DUMP     -> SessionMuter can list sessions and mute the originals
 *   appops set <pkg> PROJECT_MEDIA allow       -> SystemUI skips the screen-capture consent dialog
 *                                                 (MediaProjectionPermissionActivity returns at once when
 *                                                 hasProjectionPermission(); present on API 29-35)
 *   pm grant <pkg> android.permission.WRITE_SECURE_SETTINGS -> optional, for the notification-text tile
 *                                                 (ScreenShareProtection)
 *
 * Mechanism: a Shizuku UserService ([SetupService]) that runs the stable `cmd package` / `cmd appops`
 * shell commands. Why this one:
 *  - Shizuku.newProcess() is private since API 13, so calling it would need reflection.
 *  - Binder calls through ShizukuBinderWrapper to IPackageManager/IPermissionManager/IAppOpsService need
 *    hidden-API stubs, and grantRuntimePermission moved between interfaces and changed its signature
 *    across API 29-35 (userId, then deviceId, then persistentDeviceId).
 *  - UserService is the officially supported path, and the shell commands are the exact, documented
 *    interface the ADB instructions already use, identical on every Android version we support.
 */
object ShizukuSetup {
    const val SHIZUKU_PACKAGE = "moe.shizuku.privileged.api"
    const val REQUEST_CODE = 4242
    private const val TAG = "IslamicMute"
    private const val MIN_SERVER_VERSION = 10  // UserService needs Shizuku server API 10+

    enum class State { NOT_INSTALLED, NOT_RUNNING, TOO_OLD, NEEDS_PERMISSION, DENIED_PERMANENTLY, READY }

    fun isInstalled(ctx: Context): Boolean = runCatching {
        ctx.packageManager.getPackageInfo(SHIZUKU_PACKAGE, 0); true
    }.getOrDefault(false)

    fun state(ctx: Context): State {
        val running = runCatching { Shizuku.pingBinder() }.getOrDefault(false)
        if (!running) return if (isInstalled(ctx)) State.NOT_RUNNING else State.NOT_INSTALLED
        return runCatching {
            when {
                Shizuku.isPreV11() || Shizuku.getVersion() < MIN_SERVER_VERSION -> State.TOO_OLD
                Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED -> State.READY
                Shizuku.shouldShowRequestPermissionRationale() -> State.DENIED_PERMANENTLY  // "deny and don't ask again"
                else -> State.NEEDS_PERMISSION
            }
        }.getOrDefault(State.NOT_RUNNING)  // binder died between calls
    }

    /** Shows Shizuku's own "allow Islamic Mute?" dialog; the result arrives on OnRequestPermissionResultListener. */
    fun requestPermission() = Shizuku.requestPermission(REQUEST_CODE)

    /** [done]'s text when Shizuku never answered within [GIVE_UP_MS] (the UI words it). */
    const val TIMEOUT = "timeout"
    /** After this long the screen says "still working": the helper process is slow to start on some phones. */
    const val SLOW_MS = 20_000L
    /** Only then does the screen say it failed. A later answer still counts ([addListener]). */
    const val GIVE_UP_MS = 120_000L

    private val main = Handler(Looper.getMainLooper())
    private val listeners = java.util.concurrent.CopyOnWriteArraySet<() -> Unit>()

    /**
     * Called on the main thread whenever a Shizuku grant ends, also after its caller stopped waiting: on some Xiaomi
     * phones the answer came after the old 20 s limit, the grants had worked, and only a restart showed it.
     */
    fun addListener(l: () -> Unit) { listeners += l }
    fun removeListener(l: () -> Unit) { listeners -= l }

    /**
     * Starts [SetupService] through Shizuku, runs the grants, removes the service.
     * [slow] runs on the main thread after [SLOW_MS] without an answer; [done] runs once, on the main thread, with
     * the command log, an error message or [TIMEOUT]. The caller re-checks the real state (checkSelfPermission /
     * app-op) afterwards: that is the source of truth, not this text.
     */
    fun grant(ctx: Context, slow: () -> Unit = {}, done: (String) -> Unit) =
        run(ctx.applicationContext, "Shizuku setup", slow, done) { it.grantSetup() }

    /** Screen blur: overlay permission + the covers' accessibility service, through the same UserService. */
    fun grantBlur(ctx: Context, slow: () -> Unit = {}, done: (String) -> Unit) =
        run(ctx.applicationContext, "Shizuku blur setup", slow, done) { it.grantBlur() }

    private fun run(ctx: Context, route: String, slow: () -> Unit, done: (String) -> Unit, call: (ISetupService) -> String) {
        val started = SystemClock.elapsedRealtime()
        var finished = false  // only touched on the main thread
        fun finish(msg: String) = main.post { if (!finished) { finished = true; done(msg) } }
        fun ended(msg: String) {
            SetupLog.record(ctx, route, SystemClock.elapsedRealtime() - started, msg)
            finish(msg)
            main.post { listeners.forEach { it() } }  // also when [done] was already called with TIMEOUT
        }

        val args = Shizuku.UserServiceArgs(ComponentName(ctx.packageName, SetupService::class.java.name))
            .daemon(false)
            .processNameSuffix("setup")
            .debuggable(BuildConfig.DEBUG)
            .version(BuildConfig.VERSION_CODE)
        val conn = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
                if (binder == null || !binder.pingBinder()) { ended("Shizuku service did not start"); return }
                val conn = this
                thread(name = "im-shizuku") {
                    val result = runCatching { call(ISetupService.Stub.asInterface(binder)) }
                    result.onSuccess { Log.i(TAG, "shizuku setup:\n$it") }.onFailure { Log.w(TAG, "shizuku setup failed", it) }
                    runCatching { Shizuku.unbindUserService(args, conn, true) }
                    ended(result.getOrElse { "Shizuku: ${it.message ?: it.javaClass.simpleName}" })
                }
            }
            override fun onServiceDisconnected(name: ComponentName?) {}
        }
        try {
            Shizuku.bindUserService(args, conn)
        } catch (t: Throwable) {
            ended("Shizuku: ${t.message ?: t.javaClass.simpleName}"); return
        }
        main.postDelayed({ if (!finished) slow() }, SLOW_MS)
        main.postDelayed({
            if (finished) return@postDelayed
            SetupLog.record(ctx, route, GIVE_UP_MS, "no answer from Shizuku after ${GIVE_UP_MS / 1000} s (a late answer is still applied)")
            finish(TIMEOUT)
        }, GIVE_UP_MS)
    }
}

/** True when SystemUI will hand out screen-capture tokens without asking (app-op PROJECT_MEDIA = allow). */
fun Context.hasProjectMediaAppOp(): Boolean = runCatching {
    getSystemService(AppOpsManager::class.java)
        .unsafeCheckOpNoThrow("android:project_media", Process.myUid(), packageName) == AppOpsManager.MODE_ALLOWED
}.getOrDefault(false)

/**
 * Shizuku UserService: instantiated by Shizuku in a separate process (`:setup`) running as shell (or root),
 * from this APK's code. Never started by Android itself, so it is not declared in the manifest.
 */
class SetupService : ISetupService.Stub() {
    override fun destroy() { exitProcess(0) }

    override fun grantSetup(): String {
        debugDelay()
        val pkg = BuildConfig.APPLICATION_ID
        // `cmd <service> ...` is what the `pm` and `appops` wrapper scripts call; no shell, no PATH needed.
        val log = StringBuilder()
        log.appendLine(run("/system/bin/cmd", "package", "grant", pkg, "android.permission.DUMP"))
        log.appendLine(run("/system/bin/cmd", "appops", "set", pkg, "PROJECT_MEDIA", "allow"))
        // Optional: lets the notification-text tile turn Android 15's screen-share protection off while filtering.
        log.appendLine(run("/system/bin/cmd", "package", "grant", pkg, "android.permission.WRITE_SECURE_SETTINGS"))
        return log.toString()
    }

    override fun grantBlur(): String {
        val pkg = BuildConfig.APPLICATION_ID
        val service = "$pkg/${BlurAccessibilityService::class.java.name}"
        val log = StringBuilder()
        log.appendLine(run("/system/bin/cmd", "appops", "set", pkg, "SYSTEM_ALERT_WINDOW", "allow"))
        if (!BuildConfig.BLUR_A11Y) return log.toString() // this build has no accessibility service
        // Android 13+: sideloaded apps cannot have accessibility turned on until this app-op allows it.
        log.appendLine(run("/system/bin/cmd", "appops", "set", pkg, "ACCESS_RESTRICTED_SETTINGS", "allow"))
        val current = output("/system/bin/settings", "get", "secure", "enabled_accessibility_services")
            .takeUnless { it == "null" }.orEmpty()
        val list = current.split(':').filter { it.isNotBlank() }
        if (list.none { it.equals(service, ignoreCase = true) }) {
            log.appendLine(run("/system/bin/settings", "put", "secure", "enabled_accessibility_services",
                (list + service).joinToString(":")))
        }
        log.appendLine(run("/system/bin/settings", "put", "secure", "accessibility_enabled", "1"))
        return log.toString()
    }

    /**
     * Debug builds only: `adb shell setprop debug.waaiya.setup_delay <seconds>` makes the helper answer that late, to
     * test a slow Shizuku (seen on a Xiaomi) on an emulator. Release builds never read it.
     */
    private fun debugDelay() {
        if (!BuildConfig.DEBUG) return
        val s = output("/system/bin/getprop", "debug.waaiya.setup_delay").toLongOrNull() ?: return
        Thread.sleep(s * 1000)
    }

    private fun output(vararg cmd: String): String = runCatching {
        val p = ProcessBuilder(*cmd).redirectErrorStream(true).start()
        p.inputStream.bufferedReader().readText().trim().also { p.waitFor() }
    }.getOrDefault("")

    private fun run(vararg cmd: String): String = runCatching {
        val p = ProcessBuilder(*cmd).redirectErrorStream(true).start()
        val out = p.inputStream.bufferedReader().readText().trim()
        "${cmd.drop(1).joinToString(" ")} -> exit ${p.waitFor()} $out"
    }.getOrElse { "${cmd.joinToString(" ")} -> $it" }
}
