package org.waaiya.app

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import java.io.File
import java.io.FileNotFoundException

/**
 * Shares the copies without music made by "Check for music" (MusicCheckActivity): read only, only files of
 * cache/clean/, and only to the app that a share grants the one URI to (not exported, grantUriPermissions).
 */
class CleanCopyProvider : ContentProvider() {
    companion object {
        fun authority(ctx: android.content.Context) = ctx.packageName + ".clean"
        fun dir(ctx: android.content.Context) = File(ctx.cacheDir, "clean")
        fun uri(ctx: android.content.Context, f: File): Uri = Uri.Builder().scheme("content").authority(authority(ctx))
            .appendPath(f.name).build()

        /** Copies are kept a day at most. */
        fun prune(ctx: android.content.Context) {
            val old = System.currentTimeMillis() - 24 * 3600 * 1000L
            dir(ctx).listFiles()?.forEach { if (it.lastModified() < old) it.delete() }
        }
    }

    private fun file(uri: Uri): File {
        val name = uri.lastPathSegment ?: throw FileNotFoundException()
        val d = dir(context!!)
        val f = File(d, name)
        if (f.parentFile?.canonicalPath != d.canonicalPath || !f.isFile) throw FileNotFoundException()
        return f
    }

    override fun onCreate() = true

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (mode != "r") throw SecurityException("read only")
        return ParcelFileDescriptor.open(file(uri), ParcelFileDescriptor.MODE_READ_ONLY)
    }

    override fun getType(uri: Uri): String = if (file(uri).extension == "m4a") "audio/mp4" else "video/mp4"

    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, args: Array<out String>?, sort: String?): Cursor {
        val f = file(uri)
        val cols = projection ?: arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE)
        return MatrixCursor(cols, 1).apply {
            addRow(cols.map { when (it) { OpenableColumns.DISPLAY_NAME -> f.name; OpenableColumns.SIZE -> f.length(); else -> null } })
        }
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, args: Array<out String>?) = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, args: Array<out String>?) = 0
}
