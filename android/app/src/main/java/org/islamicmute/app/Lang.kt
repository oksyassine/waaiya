package org.islamicmute.app

import android.app.Activity
import android.app.Application
import android.app.LocaleManager
import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.os.LocaleList
import java.util.Locale

/**
 * App language: Arabic first (whatever the phone's language), English on request.
 *
 * Android 13+: the choice is the system's per-app language (LocaleManager; also shown in Android's app settings
 * through res/xml/locales_config.xml), so the system applies it to every activity and service.
 * Android 10-12: kept in our preferences and applied by wrapping each activity's and service's base context.
 */
object Lang {
    const val AR = "ar"
    const val EN = "en"
    private const val PREF = "lang"

    private fun prefs(ctx: Context) = ctx.getSharedPreferences("settings", Context.MODE_PRIVATE)

    /** The language in use: "ar" or "en". */
    fun current(ctx: Context): String {
        if (Build.VERSION.SDK_INT >= 33) {
            val l = ctx.getSystemService(LocaleManager::class.java).applicationLocales
            if (!l.isEmpty) return if (l[0].language == EN) EN else AR
        }
        return prefs(ctx).getString(PREF, AR) ?: AR
    }

    /** At app start: on Android 13+, apply Arabic as the per-app language when none was ever chosen. */
    fun init(app: Application) {
        if (Build.VERSION.SDK_INT >= 33) {
            val lm = app.getSystemService(LocaleManager::class.java)
            if (lm.applicationLocales.isEmpty) lm.applicationLocales = LocaleList.forLanguageTags(current(app))
        }
    }

    /** Switches the app language; the open screen is rebuilt in the new language. */
    fun set(activity: Activity, tag: String) {
        store(activity, tag)
        if (Build.VERSION.SDK_INT < 33) activity.recreate()
    }

    /**
     * Saves the language for the native screens, services and notifications without restarting the open screen
     * (the Flutter screens switch language themselves; UiActivity declares locale config changes).
     */
    fun store(ctx: Context, tag: String) {
        prefs(ctx).edit().putString(PREF, tag).apply()
        if (Build.VERSION.SDK_INT >= 33)
            ctx.getSystemService(LocaleManager::class.java).applicationLocales = LocaleList.forLanguageTags(tag)
    }

    /**
     * A context with the chosen language (attachBaseContext of activities and services). Needed on Android 10-12,
     * and on 13+ for the very first launch: the per-app language set in [init] only reaches screens opened after
     * it, so the first screen would otherwise show the phone's language.
     */
    fun wrap(base: Context): Context {
        val locale = Locale(current(base))
        if (base.resources.configuration.locales[0].language == locale.language) return base
        val cfg = Configuration(base.resources.configuration)
        cfg.setLocales(LocaleList(locale))
        cfg.setLayoutDirection(locale)
        return base.createConfigurationContext(cfg)
    }
}

class WaaiyaApp : Application() {
    override fun onCreate() {
        super.onCreate()
        Lang.init(this)
        // "Save without music" keeps the downloaded original in the cache while it works. If the app was killed
        // in the middle, remove what is left: unfiltered sound must not stay on the phone.
        kotlin.concurrent.thread(name = "im-clean") { runCatching { java.io.File(cacheDir, "export").deleteRecursively() } }
    }
}
