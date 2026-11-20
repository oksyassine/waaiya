package org.islamicmute.app

import android.content.Context
import android.os.ParcelFileDescriptor
import java.io.FileInputStream

/**
 * What the app normally does with the permissions of the one-time setup, done through Waaiya's helper (a shell-uid
 * process, [CoverHelper]) when the phone refused to grant them.
 *
 * Xiaomi (MIUI/HyperOS) and the OPPO family (ColorOS) refuse `pm grant` / `appops set` from the shell unless a hidden
 * Developer options switch is changed, which most people cannot find. The shell user itself holds DUMP and
 * WRITE_SECURE_SETTINGS, so the helper reads the two audio dumps and writes the one setting for the app instead. The
 * price: the helper ends when the phone restarts, so it is started again (one tap, or by itself when filtering
 * starts) over Wireless debugging. [helperMode] remembers that this phone needs it.
 */
object HelperDumps {
    /** The only dumps the helper hands out: the sound sessions SessionMuter silences. */
    val SERVICES = setOf("media.audio_policy", "audio")

    private const val PREFS = "helper_mode"

    /** This phone refused the grants and the helper took over (set by the setup, cleared when DUMP is granted). */
    fun helperMode(ctx: Context): Boolean =
        !ctx.hasDumpPermission() && ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean("on", false)

    fun setHelperMode(ctx: Context, on: Boolean) =
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean("on", on).apply()

    /** The helper for this app version is running and answers. */
    val helperReady: Boolean get() = CoverHelper.service != null

    /**
     * Just after the app's process starts, a running helper has not handed its binder over yet: it waits until it has
     * seen the process twice, 2 s apart (CoverHelper.main). Until [SETTLE_MS] the helper is "not known yet", not
     * missing: nothing warns, and nothing starts a new helper over a healthy one.
     */
    val settling: Boolean get() =
        android.os.SystemClock.elapsedRealtime() - android.os.Process.getStartElapsedRealtime() < SETTLE_MS
    const val SETTLE_MS = 6_000L

    /** One reader: a helper that never answers holds one thread, not one more with every poll. */
    private val reader = java.util.concurrent.Executors.newSingleThreadExecutor { Thread(it, "im-helper-dump").apply { isDaemon = true } }
    @Volatile private var pending: java.util.concurrent.Future<String>? = null

    /**
     * The dump of [service] through the helper; throws when the helper is gone, refuses, or does not answer within
     * [READ_MS] (a helper frozen by the phone's battery manager must not block the muter for good).
     */
    fun read(service: String): String {
        val helper = CoverHelper.service ?: error("helper not running")
        if (pending?.isDone == false) throw java.io.IOException("helper still busy with the last read")
        val pipe = ParcelFileDescriptor.createPipe()
        val task = reader.submit<String> {
            try {
                if (!helper.dumpAudio(service, pipe[1])) error("helper refused $service")
            } finally {
                runCatching { pipe[1].close() }  // ours: the helper and the service hold their own copies
            }
            FileInputStream(pipe[0].fileDescriptor).readBytes().toString(Charsets.UTF_8)
        }
        pending = task
        try {
            return task.get(READ_MS, java.util.concurrent.TimeUnit.MILLISECONDS)
        } catch (e: java.util.concurrent.TimeoutException) {
            task.cancel(true)
            throw java.io.IOException("helper did not answer in $READ_MS ms ($service)")
        } catch (e: java.util.concurrent.ExecutionException) {
            throw e.cause ?: e
        } finally {
            runCatching { pipe[1].close() }
            runCatching { pipe[0].close() }  // also unblocks a read that is still waiting
        }
    }
    private const val READ_MS = 2_500L

    /** Its own reader, so the window list read every 250 ms never makes the muter's sound dump wait. */
    private val windowReader = java.util.concurrent.Executors.newSingleThreadExecutor { Thread(it, "im-helper-windows").apply { isDaemon = true } }

    /** `dumpsys window visible-apps` through the helper (FixMistakes, helper mode); throws as [read] does. */
    fun readVisibleApps(): String {
        val helper = CoverHelper.service ?: error("helper not running")
        val pipe = ParcelFileDescriptor.createPipe()
        val task = windowReader.submit<String> {
            try {
                if (!helper.dumpVisibleApps(pipe[1])) error("helper refused the window list")
            } finally {
                runCatching { pipe[1].close() }
            }
            FileInputStream(pipe[0].fileDescriptor).readBytes().toString(Charsets.UTF_8)
        }
        try {
            return task.get(1_000L, java.util.concurrent.TimeUnit.MILLISECONDS)
        } catch (e: java.util.concurrent.TimeoutException) {
            task.cancel(true)
            throw java.io.IOException("helper did not answer in 1000 ms (window list)")
        } catch (e: java.util.concurrent.ExecutionException) {
            throw e.cause ?: e
        } finally {
            runCatching { pipe[1].close() }
            runCatching { pipe[0].close() }
        }
    }

    /** Helper side: `settings put global` (shell has WRITE_SECURE_SETTINGS); [value] is checked by the caller. */
    internal fun putGlobal(key: String, value: String): Boolean {
        val p = ProcessBuilder("/system/bin/settings", "put", "global", key, value).redirectErrorStream(true).start()
        p.inputStream.readBytes()
        return p.waitFor() == 0
    }
}

/** Other apps' sound sessions can be listed now: the DUMP permission, or Waaiya's helper. */
fun Context.canListSessions(): Boolean = hasDumpPermission() || HelperDumps.helperReady

/**
 * A helper answered and the app has no DUMP: this phone is in helper mode from now on (the setup starts the helper
 * only after the grant was refused; this also covers a helper that answered after the setup stopped waiting).
 */
internal fun Context.helperArrived() {
    if (!hasDumpPermission() && HelperDumps.helperReady) HelperDumps.setHelperMode(this, true)
}

/**
 * The one-time setup is done: DUMP granted, or this phone uses the helper (which may need starting again after a
 * restart: [helperMissing]).
 */
fun Context.setupDone(): Boolean = hasDumpPermission() || HelperDumps.helperMode(this)

/**
 * Helper mode, but the helper is not running (the phone restarted, Waaiya was updated, or Developer options were
 * turned off). Not before the app's process is [HelperDumps.settling]: a running helper needs a few seconds to
 * answer a new process.
 */
fun Context.helperMissing(): Boolean = HelperDumps.helperMode(this) && !HelperDumps.helperReady && !HelperDumps.settling

