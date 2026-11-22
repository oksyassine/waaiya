package org.waaiya.app

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import java.util.function.Consumer

/**
 * "Use my location" for the prayer times: the phone's approximate position, read once when the user taps it
 * (ACCESS_COARSE_LOCATION, about 2 km: the times change by well under a minute over that). Only Android's own
 * LocationManager, so it works without Google's services; nothing is sent anywhere and nothing is read again
 * later. The position only becomes the place setting ([WorshipCities.fromLocation]).
 *
 * Order: a fix from the last 10 minutes if the phone has one, else a new one from the fused, network or GPS
 * provider (GPS with the approximate permission needs Android 12), else, after [TIMEOUT_MS], the newest fix of the
 * last [STALE_MS] (the user has not travelled far since, most likely).
 */
object WorshipLocation {
    const val TIMEOUT_MS = 30_000L
    private const val FRESH_MS = 10 * 60_000L
    private const val STALE_MS = 24 * 3600_000L

    /** Why there is no position: `off` (location turned off in the phone's settings), `denied`, `none`. */
    class Failure(val code: String)

    fun allowed(c: Context): Boolean =
        c.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            c.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED

    fun enabled(c: Context): Boolean = c.getSystemService(LocationManager::class.java)?.isLocationEnabled == true

    private fun ageMs(l: Location) = (SystemClock.elapsedRealtimeNanos() - l.elapsedRealtimeNanos) / 1_000_000

    @SuppressLint("MissingPermission")  // checked by allowed() first
    private fun lastKnown(lm: LocationManager): Location? =
        lm.getProviders(false).mapNotNull { runCatching { lm.getLastKnownLocation(it) }.getOrNull() }
            .minByOrNull { ageMs(it) }

    /** Providers to ask now, in order of preference, among those enabled and usable with the permission held. */
    private fun providers(lm: LocationManager): List<String> {
        val enabled = lm.getProviders(true)
        val order = buildList {
            if (Build.VERSION.SDK_INT >= 31) add(LocationManager.FUSED_PROVIDER)
            add(LocationManager.NETWORK_PROVIDER)
            if (Build.VERSION.SDK_INT >= 31) add(LocationManager.GPS_PROVIDER)  // approximate GPS: Android 12+
        }
        return order.filter { it in enabled }
    }

    /**
     * Reads one position and calls [done] once on the main thread with a [Location] or a [Failure]. Never asks for
     * the permission itself (Worship.askPermission does, when the user taps).
     */
    @SuppressLint("MissingPermission")
    fun locate(c: Context, done: (Any) -> Unit) {
        val main = Handler(Looper.getMainLooper())
        if (!allowed(c)) { main.post { done(Failure("denied")) }; return }
        if (!enabled(c)) { main.post { done(Failure("off")) }; return }
        val lm = c.getSystemService(LocationManager::class.java)
            ?: run { main.post { done(Failure("none")) }; return }
        lastKnown(lm)?.takeIf { ageMs(it) <= FRESH_MS }?.let { l -> main.post { done(l) }; return }

        var finished = false
        val listeners = mutableListOf<LocationListener>()
        fun finish(result: Any) {
            if (finished) return
            finished = true
            listeners.forEach { runCatching { lm.removeUpdates(it) } }
            done(result)
        }
        val asked = providers(lm)
        for (p in asked) {
            runCatching {
                if (Build.VERSION.SDK_INT >= 30) {
                    lm.getCurrentLocation(p, null, c.mainExecutor, Consumer { l -> if (l != null) finish(l) })
                } else {
                    val listener = object : LocationListener {
                        override fun onLocationChanged(l: Location) = finish(l)
                        @Deprecated("framework API") override fun onStatusChanged(p: String?, s: Int, b: android.os.Bundle?) {}
                        override fun onProviderEnabled(p: String) {}
                        override fun onProviderDisabled(p: String) {}
                    }
                    listeners.add(listener)
                    @Suppress("DEPRECATION") lm.requestSingleUpdate(p, listener, Looper.getMainLooper())
                }
            }
        }
        main.postDelayed({
            finish(lastKnown(lm)?.takeIf { ageMs(it) <= STALE_MS } ?: Failure("none"))
        }, if (asked.isEmpty()) 0 else TIMEOUT_MS)
    }
}
