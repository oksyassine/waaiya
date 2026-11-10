package org.islamicmute.app

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku

/**
 * Android backend of the Flutter screens: MethodChannel "waaiya/app" and EventChannel "waaiya/state"
 * (docs/UI_CONTRACT.md). A thin layer over the existing code: Settings, Lang, FilterService, ShizukuSetup,
 * ScreenBlur, LinkActivity, LicencesActivity's texts. It follows MainActivity's flows (permission order, capture
 * consent, Shizuku steps, blur grant) but returns facts and codes only; the words are chosen in Flutter.
 */
class UiBridge(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private class BadArgs(message: String) : Exception(message)

    private val settings = Settings(activity)
    private val methods = MethodChannel(messenger, "waaiya/app")
    private val events = EventChannel(messenger, "waaiya/state")
    private var sink: EventChannel.EventSink? = null
    private var disposed = false

    private var shizukuBusy = false
    private var shizukuMessage: Pair<String, String>? = null
    private var blurBusy = false
    private var blurMessage: Pair<String, String>? = null
    /** Shizuku's permission dialog was opened from the blur card: grant the blur (not the setup) when it returns. */
    private var blurAfterPermission = false
    /** startFilter is waiting for the permission or capture-consent dialogs. */
    private var pendingStart: MethodChannel.Result? = null
    /** Notifications are asked at most once per screen: a refusal must not block or loop Start. */
    private var askedNotifications = false
    /** The microphone permission was refused at the last Start. */
    private var micDenied = false

    private val changed: () -> Unit = { refresh() }
    private val shizukuChanged = Shizuku.OnBinderReceivedListener { activity.runOnUiThread { refresh() } }
    private val shizukuDead = Shizuku.OnBinderDeadListener { activity.runOnUiThread { refresh() } }
    private val shizukuPermission = Shizuku.OnRequestPermissionResultListener { code, result ->
        if (code != ShizukuSetup.REQUEST_CODE) return@OnRequestPermissionResultListener
        activity.runOnUiThread {
            if (result == PackageManager.PERMISSION_GRANTED) { if (blurAfterPermission) grantBlur() else grantWithShizuku() }
            else { shizukuMessage = "refused" to ""; refresh() }
            blurAfterPermission = false
        }
    }

    init {
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
        FilterService.addListener(changed)
        ScreenBlur.addListener(changed)
        Shizuku.addBinderReceivedListenerSticky(shizukuChanged)
        Shizuku.addBinderDeadListener(shizukuDead)
        Shizuku.addRequestPermissionResultListener(shizukuPermission)
    }

    fun dispose() {
        disposed = true
        FilterService.removeListener(changed)
        ScreenBlur.removeListener(changed)
        Shizuku.removeBinderReceivedListener(shizukuChanged)
        Shizuku.removeBinderDeadListener(shizukuDead)
        Shizuku.removeRequestPermissionResultListener(shizukuPermission)
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        pendingStart?.success("consent_denied")
        pendingStart = null
        sink = null
    }

    /** Sends a new snapshot to Flutter (main thread). */
    fun refresh() {
        if (!disposed && !activity.isDestroyed) sink?.success(snapshot())
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) { sink = events; refresh() }
    override fun onCancel(arguments: Any?) { sink = null }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getState" -> result.success(snapshot())
                "setSetting" -> { setSetting(call.argument<String>("key"), call.argument<Any>("value")); result.success(null) }
                "startFilter" -> startFilter(result)
                "stopFilter" -> {
                    activity.startService(Intent(activity, FilterService::class.java).setAction(FilterService.ACTION_STOP))
                    result.success(null)
                }
                "runSetupStep" -> { runSetupStep(call.argument<Int>("step") ?: throw BadArgs("step")); result.success(null) }
                "blurSetup" -> { blurSetup(); result.success(null) }
                "openShizuku" -> { openShizuku(); result.success(null) }
                "openDeveloperOptions" -> {
                    // Developer options, or About phone when they are not turned on yet (step 2 of the guide).
                    // Checked first: with them off, the Developer options page opens and closes at once (no exception).
                    val devOn = android.provider.Settings.Global.getInt(activity.contentResolver,
                        android.provider.Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) == 1
                    val about = Intent(android.provider.Settings.ACTION_DEVICE_INFO_SETTINGS)
                    if (devOn) runCatching { activity.startActivity(Intent(android.provider.Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)) }
                        .onFailure { activity.startActivity(about) }
                    else activity.startActivity(about)
                    result.success(null)
                }
                "openOverlaySettings" -> {
                    activity.startActivity(Intent(android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${activity.packageName}")))
                    result.success(null)
                }
                "setLanguage" -> {
                    val tag = call.argument<String>("tag")?.takeIf { it == Lang.AR || it == Lang.EN }
                        ?: throw BadArgs("language ${call.argument<Any>("tag")}")
                    Lang.store(activity, tag)
                    result.success(null)
                    refresh()
                }
                "openLinkScreen" -> { activity.startActivity(Intent(activity, LinkActivity::class.java)); result.success(null) }
                "getLicences" -> result.success(mapOf(
                    "notice" to licenceAsset("NOTICE.txt"),
                    "docs" to LicencesActivity.DOCS.map { (label, file) -> mapOf("label" to label, "file" to file) }))
                "getLicenceText" -> {
                    val file = call.argument<String>("file")
                    if (LicencesActivity.DOCS.none { it.second == file }) throw BadArgs("licence file $file")
                    result.success(licenceAsset(file!!))
                }
                else -> result.notImplemented()
            }
        } catch (e: BadArgs) {
            result.error("bad_args", e.message, null)
        } catch (e: Exception) {
            result.error("failed", e.message ?: e.javaClass.simpleName, null)
        }
    }

    /** The contract's snapshot (docs/UI_CONTRACT.md). */
    private fun snapshot(): Map<String, Any?> = mapOf(
        "platform" to "android",
        "version" to BuildConfig.VERSION_NAME,
        "language" to Lang.current(activity),
        "settings" to mapOf(
            "gender" to settings.gender,
            "mute_women_singing" to settings.muteWomenSinging,
            "silence_unfilterable" to settings.silenceUnfilterable,
            "blur_women" to settings.blurWomen,
            "blur_nudity" to settings.blurNudity,
            "blur_fail_cover" to settings.blurFailCover,
        ),
        "filter" to mapOf(
            "state" to FilterService.state.name,
            "delayMs" to FilterService.delayMs,
            "micDenied" to micDenied,
            "simulated" to false,
        ),
        "setup" to mapOf(
            "originalsMuted" to activity.hasDumpPermission(),
            "consentSkipped" to activity.hasProjectMediaAppOp(),
            "shizuku" to ShizukuSetup.state(activity).name,
            "busy" to shizukuBusy,
            "message" to shizukuMessage?.let { (code, detail) -> mapOf("code" to code, "detail" to detail) },
            "adbCommands" to "adb shell pm grant ${activity.packageName} android.permission.DUMP\n" +
                "adb shell appops set ${activity.packageName} PROJECT_MEDIA allow",
        ),
        "blur" to mapOf(
            "state" to ScreenBlur.state?.name,
            "overlayAllowed" to android.provider.Settings.canDrawOverlays(activity),
            "a11yBuild" to BuildConfig.BLUR_A11Y,
            "a11yEnabled" to activity.blurAccessibilityEnabled(),
            "touchPassThrough" to activity.blurTouchPassThrough(),
            // Shizuku running (Android 12+): the covers are a shell layer (ShizukuCovers), nothing else to allow
            "shizukuLayer" to (Build.VERSION.SDK_INT >= 31 && ShizukuSetup.state(activity) == ShizukuSetup.State.READY),
            "layerSupported" to (Build.VERSION.SDK_INT >= 31),  // Shizuku covers need Android 12+
            "busy" to blurBusy,
            "message" to blurMessage?.let { (code, detail) -> mapOf("code" to code, "detail" to detail) },
        ),
        "models" to mapOf("detector" to ModelStore.hasDetector(activity)),
        "capabilities" to mapOf(
            "shizukuSetup" to true, "adbSetup" to true, "captureConsent" to true,
            "screenBlur" to true, "links" to true, "womenSinging" to true,
        ),
    )

    private fun setSetting(key: String?, value: Any?) {
        if (key == null) throw BadArgs("key")
        fun bool() = value as? Boolean ?: throw BadArgs("$key takes a bool")
        when (key) {
            "gender" -> settings.gender = (value as? String)?.takeIf { it in listOf("", "man", "woman") }
                ?: throw BadArgs("gender is \"\", \"man\" or \"woman\"")
            "mute_women_singing" -> settings.muteWomenSinging = bool()
            "silence_unfilterable" -> settings.silenceUnfilterable = bool()
            "blur_women" -> settings.blurWomen = bool()
            "blur_nudity" -> settings.blurNudity = bool()
            "blur_fail_cover" -> settings.blurFailCover = bool()
            else -> throw BadArgs("unknown setting $key")
        }
        // No restart: the running filter and blur re-read Settings every 0.5 s.
        if (key.startsWith("blur_")) blurMessage = null  // as MainActivity.blurChanged
        refresh()
    }

    // --- Start: runtime permissions, then the capture consent, then the service (as MainActivity.startFilter) ---

    private fun startFilter(result: MethodChannel.Result) {
        if (FilterService.running) { result.success("already_running"); return }
        if (pendingStart != null) { result.error("busy", "a start is waiting for a dialog", null); return }
        pendingStart = result
        micDenied = false
        askOrConsent()
    }

    private fun askOrConsent() {
        // Only RECORD_AUDIO gates Start; the notification permission is optional and asked once.
        val wanted = buildList {
            if (activity.checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED)
                add(android.Manifest.permission.RECORD_AUDIO)
            if (Build.VERSION.SDK_INT >= 33 && !askedNotifications &&
                activity.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED)
                add(android.Manifest.permission.POST_NOTIFICATIONS)
        }
        if (Build.VERSION.SDK_INT >= 33 && android.Manifest.permission.POST_NOTIFICATIONS in wanted) askedNotifications = true
        if (wanted.isNotEmpty()) { activity.requestPermissions(wanted.toTypedArray(), REQ_PERMISSIONS); return }
        val mpm = activity.getSystemService(MediaProjectionManager::class.java)
        // Android 14+ offers "a single app" first; a system-wide filter needs the whole device, so ask for that only.
        val intent = if (Build.VERSION.SDK_INT >= 34)
            mpm.createScreenCaptureIntent(android.media.projection.MediaProjectionConfig.createConfigForDefaultDisplay())
        else mpm.createScreenCaptureIntent()
        @Suppress("DEPRECATION") activity.startActivityForResult(intent, REQ_CAPTURE)
    }

    fun onRequestPermissionsResult(requestCode: Int) {
        if (requestCode != REQ_PERMISSIONS || pendingStart == null) return
        if (activity.checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) askOrConsent()
        else { micDenied = true; finishStart("mic_denied") }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQ_CAPTURE || pendingStart == null) return
        if (resultCode == Activity.RESULT_OK && data != null) {
            activity.startForegroundService(Intent(activity, FilterService::class.java)
                .putExtra(FilterService.EXTRA_CODE, resultCode).putExtra(FilterService.EXTRA_DATA, data))
            finishStart("started")
        } else finishStart("consent_denied")
    }

    private fun finishStart(code: String) {
        pendingStart?.success(code)
        pendingStart = null
        refresh()
    }

    // --- One-time setup through Shizuku (as MainActivity.onStepAction / grantWithShizuku) ---

    private fun runSetupStep(step: Int) {
        shizukuMessage = null
        val s = ShizukuSetup.state(activity)
        when {
            step == 0 -> openStore()
            step == 1 && s == ShizukuSetup.State.TOO_OLD -> openStore()
            s == ShizukuSetup.State.READY -> grantWithShizuku()
            s == ShizukuSetup.State.NEEDS_PERMISSION -> runCatching { ShizukuSetup.requestPermission() }
                .onFailure { shizukuMessage = "error" to "Shizuku: ${it.message}" }
            else -> openShizuku()  // step 1 not running: Flutter shows the guide (MainActivity.showShizukuGuide)
        }
        refresh()
    }

    private fun grantWithShizuku() {
        if (shizukuBusy) return
        shizukuBusy = true
        refresh()
        ShizukuSetup.grant(activity) { log ->
            if (disposed) return@grant
            shizukuBusy = false
            shizukuMessage = when {
                !activity.hasDumpPermission() -> "failed" to log
                FilterService.running -> "done_restart" to ""
                else -> null
            }
            refresh()
        }
    }

    // --- Screen blur permission (as MainActivity.onBlurSetup / grantBlur) ---

    private fun blurSetup() {
        blurMessage = null
        when (ShizukuSetup.state(activity)) {
            ShizukuSetup.State.READY -> grantBlur()
            ShizukuSetup.State.NEEDS_PERMISSION -> {
                blurAfterPermission = true
                runCatching { ShizukuSetup.requestPermission() }.onFailure { blurAfterPermission = false }
            }
            ShizukuSetup.State.NOT_INSTALLED, ShizukuSetup.State.TOO_OLD -> openStore()
            else -> openShizuku()  // DENIED_PERMANENTLY; for NOT_RUNNING Flutter shows the guide instead of calling this
        }
        refresh()
    }

    private fun grantBlur() {
        blurAfterPermission = false
        if (blurBusy) return
        blurBusy = true
        refresh()
        ShizukuSetup.grantBlur(activity) { log ->
            if (disposed) return@grantBlur
            blurBusy = false
            blurMessage = if (activity.blurAccessibilityEnabled() || android.provider.Settings.canDrawOverlays(activity)) null
                          else "setup_failed" to log
            refresh()
        }
    }

    private fun openStore() {
        val pkg = ShizukuSetup.SHIZUKU_PACKAGE
        val market = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$pkg"))
        val web = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$pkg"))
        runCatching { activity.startActivity(market) }.onFailure { runCatching { activity.startActivity(web) } }
    }

    /** Shizuku itself, or its store page when it is not installed (as MainActivity.openShizuku). */
    private fun openShizuku() {
        activity.packageManager.getLaunchIntentForPackage(ShizukuSetup.SHIZUKU_PACKAGE)?.let { activity.startActivity(it) }
            ?: openStore()
    }

    private fun licenceAsset(name: String): String =
        runCatching { activity.assets.open("${LicencesActivity.DIR}/$name").bufferedReader().use { it.readText() } }
            .getOrElse { "($name missing)" }

    private companion object {
        const val REQ_PERMISSIONS = 1
        const val REQ_CAPTURE = 7
    }
}
