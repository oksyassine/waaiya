package org.waaiya.app

import java.io.File

/**
 * Rebuilds an update's APK from the installed APK and a zstd "--patch-from" patch (native: cpp/zpatch, decoder-only
 * zstd). The caller checks the result's SHA-256 against the release file before Android ever sees it.
 */
object AppUpdatePatch {
    private val loaded: Boolean = runCatching { System.loadLibrary("waaiyapatch") }.isSuccess

    /** null on success; else why it failed (no output file is left behind). */
    fun apply(old: File, patch: File, out: File, outSize: Long): String? {
        if (!loaded) return "patcher not available"
        return runCatching { nativeApply(old.path, patch.path, out.path, outSize) }.getOrElse { it.toString() }
    }

    @JvmStatic private external fun nativeApply(oldPath: String, patchPath: String, outPath: String, outSize: Long): String?
}
