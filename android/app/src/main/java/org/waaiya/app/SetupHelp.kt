package org.waaiya.app

import android.content.Context
import android.os.Build
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Phone makers whose systems block the one-time setup unless a Developer options switch is changed. Shizuku's own
 * guide lists the same ones (https://shizuku.rikka.app/guide/setup/):
 *  - Xiaomi, Redmi, POCO (MIUI, HyperOS): "USB debugging (Security settings)" must be on, or every
 *    `pm grant` / `appops set` from the shell user is refused. Turning it on asks for a Xiaomi account (and on some
 *    phones a SIM card). MIUI's own notification style can also hide the "Enter code" reply field.
 *  - OPPO, OnePlus, realme (ColorOS): "Permission monitoring" must be off.
 * The same switches are needed for all three routes (on the phone, Shizuku, a computer): it is the shell user that
 * is restricted, not the app.
 */
object SetupHelp {
    enum class Brand { XIAOMI, COLOROS, OTHER }

    private fun prop(name: String): String = runCatching {
        @Suppress("PrivateApi")
        Class.forName("android.os.SystemProperties").getMethod("get", String::class.java).invoke(null, name) as String
    }.getOrDefault("")

    val brand: Brand by lazy {
        val maker = (Build.MANUFACTURER + " " + Build.BRAND).lowercase(Locale.ROOT)
        when {
            prop("ro.miui.ui.version.name").isNotEmpty() || prop("ro.mi.os.version.name").isNotEmpty() ||
                listOf("xiaomi", "redmi", "poco").any { it in maker } -> Brand.XIAOMI
            listOf("oppo", "oneplus", "realme").any { it in maker } -> Brand.COLOROS
            else -> Brand.OTHER
        }
    }

    /** "MIUI V14 / HyperOS OS1.0" style line for the diagnostics report, empty elsewhere. */
    val systemName: String by lazy {
        listOfNotNull(prop("ro.miui.ui.version.name").takeIf { it.isNotEmpty() }?.let { "MIUI $it" },
            prop("ro.mi.os.version.name").takeIf { it.isNotEmpty() }?.let { "HyperOS $it" },
            prop("ro.build.version.oplusrom").takeIf { it.isNotEmpty() }?.let { "ColorOS $it" },
            prop("ro.build.version.oneui").takeIf { it.isNotEmpty() }?.let { "One UI $it" })
            .joinToString(", ")
    }

    /**
     * Where the "Build number" line is on this make of phone (the setup's first step): a key for the Flutter page
     * (`wiz_dev_body_<key>`), or null for the general sentence.
     */
    val aboutHint: String? by lazy {
        val maker = (Build.MANUFACTURER + " " + Build.BRAND).lowercase(Locale.ROOT)
        when {
            brand == Brand.XIAOMI -> "xiaomi"
            brand == Brand.COLOROS -> "coloros"
            "samsung" in maker || "asus" in maker -> "samsung"  // both: About phone › Software information
            "vivo" in maker || "iqoo" in maker -> "vivo"
            listOf("tecno", "infinix", "itel").any { it in maker } -> "transsion"
            "huawei" in maker || "honor" in maker -> "huawei"
            else -> null
        }
    }

    /** The note shown above the setup on these phones, or null. */
    fun noteRes(): Int? = when (brand) {
        Brand.XIAOMI -> R.string.setup_note_xiaomi
        Brand.COLOROS, Brand.OTHER -> null
    }

    /** The system refused the grant itself (not Waaiya, not Shizuku): the shell user lacks the right to grant. */
    fun refused(log: String): Boolean = listOf("GRANT_RUNTIME_PERMISSIONS", "SecurityException", "Neither user 2000",
        "not allowed", "Permission denial").any { log.contains(it, ignoreCase = true) }

    /**
     * What to say when the grant failed with [log]: the phone-specific fix when the system refused it on one of these
     * phones, else null (the caller shows the generic text with the log).
     */
    fun refusedMessage(ctx: Context, log: String): String? = if (!refused(log)) null else when (brand) {
        Brand.XIAOMI -> ctx.getString(R.string.setup_refused_xiaomi)
        Brand.COLOROS -> ctx.getString(R.string.setup_refused_coloros)
        Brand.OTHER -> null
    }
}

/**
 * The last setup attempt (route, when, how long, the command output), for the diagnostics report: a slow or
 * refused setup on someone else's phone can then be told apart from one that never started.
 */
object SetupLog {
    private const val PREFS = "setup_log"

    fun record(ctx: Context, route: String, ms: Long, text: String) {
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString("route", route).putLong("at", System.currentTimeMillis()).putLong("ms", ms)
            .putString("text", text.trim().take(2000)).apply()
    }

    fun report(ctx: Context): String {
        val p = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val route = p.getString("route", null) ?: return "No setup attempt recorded."
        val at = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.ROOT).format(Date(p.getLong("at", 0)))
        return "$route, $at, took %.1f s\n%s".format(Locale.ROOT, p.getLong("ms", 0) / 1000.0, p.getString("text", ""))
    }
}
