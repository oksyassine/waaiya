package org.waaiya.app

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import java.io.File

/**
 * Hands a checked update APK to Android's installer (PackageInstaller session). Android shows its own confirmation;
 * nothing is installed without the user's tap, and Android itself refuses an APK signed by anyone else.
 */
object AppUpdateInstall {
    private const val TAG = "WaaiyaUpdate"

    /** null if [apk] is [pkg] (this app, or the new app in the old app's last version), version [versionCode] (newer
     *  than this one when it is this app), signed with this app's certificate. */
    fun verify(c: Context, apk: File, versionCode: Long, pkg: String = c.packageName): String? {
        val pm = c.packageManager
        val flags = PackageManager.GET_SIGNING_CERTIFICATES
        val info = pm.getPackageArchiveInfo(apk.path, flags) ?: return "not an APK"
        if (info.packageName != pkg) return "another app: ${info.packageName}"
        if (info.longVersionCode != versionCode || (pkg == c.packageName && versionCode <= BuildConfig.VERSION_CODE))
            return "version ${info.longVersionCode}"
        val mine = pm.getPackageInfo(c.packageName, flags).signingInfo ?: return "no own certificate"
        val theirs = info.signingInfo ?: return "unsigned"
        val a = (if (mine.hasMultipleSigners()) mine.apkContentsSigners else mine.signingCertificateHistory).map { it.toByteArray().toList() }.toSet()
        val b = (if (theirs.hasMultipleSigners()) theirs.apkContentsSigners else theirs.signingCertificateHistory).map { it.toByteArray().toList() }.toSet()
        if (a.intersect(b).isEmpty()) return "signed by another certificate"
        return null
    }

    /** Opens an install session and commits [apk]; the answer comes to [AppUpdateInstallReceiver]. null = committed. */
    fun commit(c: Context, apk: File, pkg: String = c.packageName): String? = runCatching {
        val installer = c.packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL).apply {
            setAppPackageName(pkg)
            setSize(apk.length())
            if (Build.VERSION.SDK_INT >= 31) setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_REQUIRED)
        }
        val id = installer.createSession(params)
        installer.openSession(id).use { s ->
            s.openWrite("waaiya.apk", 0, apk.length()).use { out -> apk.inputStream().use { it.copyTo(out, 1 shl 16) }; s.fsync(out) }
            val intent = Intent(c, AppUpdateInstallReceiver::class.java).setPackage(c.packageName)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0)
            s.commit(PendingIntent.getBroadcast(c, id, intent, flags).intentSender)
        }
        null
    }.getOrElse { Log.w(TAG, "commit: $it"); it.toString() }
}

/** The installer's answer: show its confirmation screen, or report a cancel or a failure. */
class AppUpdateInstallReceiver : BroadcastReceiver() {
    override fun onReceive(c: Context, intent: Intent) {
        when (val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                @Suppress("DEPRECATION")
                val confirm = (if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                               else intent.getParcelableExtra(Intent.EXTRA_INTENT)) ?: return AppUpdate.installEnded(true)
                runCatching { c.startActivity(confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
                    .onFailure { Log.w("WaaiyaUpdate", "confirm: $it"); AppUpdate.installEnded(true) }
            }
            PackageInstaller.STATUS_SUCCESS -> Log.i("WaaiyaUpdate", "installed")  // Android restarts the app
            PackageInstaller.STATUS_FAILURE_ABORTED -> AppUpdate.installEnded(false)  // the user said no: try again later
            else -> {
                Log.w("WaaiyaUpdate", "install failed: $status ${intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)}")
                AppUpdate.installEnded(true)
            }
        }
    }
}
