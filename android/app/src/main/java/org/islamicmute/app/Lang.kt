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
        prefs(activity).edit().putString(PREF, tag).apply()
        if (Build.VERSION.SDK_INT >= 33)
            activity.getSystemService(LocaleManager::class.java).applicationLocales = LocaleList.forLanguageTags(tag)
        else activity.recreate()
    }

    /** Android 10-12: a context with the chosen language (attachBaseContext of activities and services). */
    fun wrap(base: Context): Context {
        if (Build.VERSION.SDK_INT >= 33) return base
        val locale = Locale(prefs(base).getString(PREF, AR) ?: AR)
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
    }
}
