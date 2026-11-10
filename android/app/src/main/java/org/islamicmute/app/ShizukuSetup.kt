package org.islamicmute.app

import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
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

    /**
     * Starts [SetupService] through Shizuku, runs the grants, removes the service.
     * [done] runs on the main thread with the command log or an error message. The caller re-checks the
     * real state (checkSelfPermission / app-op) afterwards: that is the source of truth, not this text.
     */
    fun grant(ctx: Context, done: (String) -> Unit) = run(ctx, done) { it.grantSetup() }

    /** Screen blur: overlay permission + the covers' accessibility service, through the same UserService. */
    fun grantBlur(ctx: Context, done: (String) -> Unit) = run(ctx, done) { it.grantBlur() }

    private fun run(ctx: Context, done: (String) -> Unit, call: (ISetupService) -> String) {
        val main = Handler(Looper.getMainLooper())
        var finished = false  // only touched on the main thread
        fun finish(msg: String) = main.post { if (!finished) { finished = true; done(msg) } }

        val args = Shizuku.UserServiceArgs(ComponentName(ctx.packageName, SetupService::class.java.name))
            .daemon(false)
            .processNameSuffix("setup")
            .debuggable(BuildConfig.DEBUG)
            .version(BuildConfig.VERSION_CODE)
        val conn = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
                if (binder == null || !binder.pingBinder()) { finish("Shizuku service did not start"); return }
                val conn = this
                thread(name = "im-shizuku") {
                    val result = runCatching { call(ISetupService.Stub.asInterface(binder)) }
                    result.onSuccess { Log.i(TAG, "shizuku setup:\n$it") }.onFailure { Log.w(TAG, "shizuku setup failed", it) }
                    runCatching { Shizuku.unbindUserService(args, conn, true) }
                    finish(result.getOrElse { "Shizuku: ${it.message ?: it.javaClass.simpleName}" })
                }
            }
            override fun onServiceDisconnected(name: ComponentName?) {}
        }
        try {
            Shizuku.bindUserService(args, conn)
        } catch (t: Throwable) {
            finish("Shizuku: ${t.message ?: t.javaClass.simpleName}"); return
        }
        main.postDelayed({ finish("Shizuku did not answer in time. Is it still running?") }, 20_000)
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
        val pkg = BuildConfig.APPLICATION_ID
        // `cmd <service> ...` is what the `pm` and `appops` wrapper scripts call; no shell, no PATH needed.
        val log = StringBuilder()
        log.appendLine(run("/system/bin/cmd", "package", "grant", pkg, "android.permission.DUMP"))
        log.appendLine(run("/system/bin/cmd", "appops", "set", pkg, "PROJECT_MEDIA", "allow"))
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
