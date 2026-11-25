package org.waaiya.app

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
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

    private val featureHost = object : FeatureHost {
        override val activity get() = this@UiBridge.activity
        override fun refresh() = this@UiBridge.refresh()
    }

    private var shizukuBusy = false
    private var shizukuMessage: Pair<String, String>? = null
    /** startFilter is waiting for the permission or capture-consent dialogs. */
    private var pendingStart: MethodChannel.Result? = null
    /** Notifications are asked at most once per screen: a refusal must not block or loop Start. */
    private var askedNotifications = false
    /** The microphone permission was refused at the last Start. */
    private var micDenied = false
    /** Android's screen-sharing question was cancelled at the last Start (MainActivity.captureCancelled). */
    private var captureCancelled = false

    private val changed: () -> Unit = { refresh() }
    private val shizukuChanged = Shizuku.OnBinderReceivedListener { activity.runOnUiThread { refresh() } }
    private val shizukuDead = Shizuku.OnBinderDeadListener { activity.runOnUiThread { refresh() } }
    private val shizukuPermission = Shizuku.OnRequestPermissionResultListener { code, result ->
        if (code != ShizukuSetup.REQUEST_CODE) return@OnRequestPermissionResultListener
        activity.runOnUiThread {
            if (result == PackageManager.PERMISSION_GRANTED) grantWithShizuku()
            else { shizukuMessage = "refused" to ""; refresh() }
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

    private val main = android.os.Handler(android.os.Looper.getMainLooper())
    /** While the setup is not finished, look again every 2 s (as MainActivity.setupTick). */
    private val setupTick = object : Runnable {
        override fun run() {
            main.removeCallbacks(this)
            if (disposed || (activity.hasDumpPermission() && activity.hasProjectMediaAppOp())) return
            // helper mode: nothing more to wait for while the helper runs (Android asks before each capture there)
            if (HelperDumps.helperMode(activity) && HelperDumps.helperReady) return
            refresh()
            main.postDelayed(this, 2000)
        }
    }
    /** A Shizuku grant ended, perhaps after the screen stopped waiting: show the real state. */
    private val shizukuGrantEnded: () -> Unit = {
        if (activity.hasDumpPermission() && !shizukuBusy) shizukuMessage = null
        refresh()
    }

    init {  // after the properties above are initialised
        ShizukuSetup.addListener(shizukuGrantEnded)
        WirelessSetup.addListener(changed)
        CoverHelper.addListener(changed)
    }

    /** A page asked for by an intent (UiActivity), until Flutter says it showed it. */
    private var pageRequest: Pair<String, Int>? = null
    private var pageRequests = 0
    fun requestPage(page: String) { pageRequest = page to ++pageRequests; refresh() }

    /** Notifications were refused or never asked: the code must then be typed in the app (split screen). */
    private var wirelessHint: String? = null

    /**
     * Start of the on-phone setup: notifications first (the code is typed in one), then Developer options. Returns
     * `started`, `dev_off` (Flutter offers About phone), or `asking` (Android's notification question is open; the
     * setup continues by itself after it).
     */
    private fun wirelessStart(askedNotifications: Boolean): String {
        wirelessHint = null
        if (Build.VERSION.SDK_INT >= 33 && !askedNotifications &&
            activity.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            activity.requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), REQ_WSETUP_NOTIFICATIONS)
            return "asking"
        }
        if (!WirelessSetup.developerOptionsOn(activity)) return "dev_off"
        if (!activity.getSystemService(android.app.NotificationManager::class.java).areNotificationsEnabled())
            wirelessHint = "wsetup_notif_off"
        // Android 15+ makes notifications unusable while a screen share runs, and filtering is one: the code could
        // not be typed in Waaiya's notification
        else if (Build.VERSION.SDK_INT >= 35 && FilterService.running && !ScreenShareProtection.protectionOff(activity))
            wirelessHint = "wsetup_filter_on"
        WirelessSetup.start(activity)
        WirelessSetup.openWirelessDebugging(activity)
        refresh()
        return "started"
    }

    /** setup.wireless (docs/UI_CONTRACT.md): codes and resource names, the words are chosen in Flutter. */
    private fun wirelessInfo(): Map<String, Any?> {
        val st = WirelessSetup.status
        val res = activity.resources
        return mapOf(
            "supported" to WirelessSetup.supported,
            "running" to WirelessSetup.running,
            "phase" to st?.phase?.name,
            "title" to st?.let { res.getResourceEntryName(WirelessSetupTexts.titleRes(it.phase, it.note)) },
            "body" to st?.let { res.getResourceEntryName(WirelessSetupTexts.bodyRes(activity, it.phase, it.note, it.detail)) },
            // the raw output only when no sentence explains it (a refusal on Xiaomi/OPPO is explained)
            "detail" to st?.detail?.takeUnless { d ->
                st.note == org.waaiya.app.adb.SetupFlow.Note.GRANT_FAILED && SetupHelp.refused(d) &&
                    SetupHelp.brand != SetupHelp.Brand.OTHER },
            "isError" to (st?.phase == org.waaiya.app.adb.SetupFlow.Phase.FAILED ||
                st?.note == org.waaiya.app.adb.SetupFlow.Note.WRONG_CODE),
            "hint" to wirelessHint,
            // the guided steps (setup page): what Waaiya can see of each step. Hints only: the Wi-Fi guess can be
            // wrong and some phones do not let apps read the Wireless debugging switch (null).
            "devOptions" to WirelessSetup.developerOptionsOn(activity),
            "wifi" to WirelessSetup.onWifi(),
            "wirelessDebugging" to WirelessSetup.wirelessDebuggingOn(activity),
            "paired" to (WirelessSetup.pairedBefore(activity) &&
                WirelessSetup.keyDir(activity).list()?.isNotEmpty() == true),
            // where "Build number" is on this make of phone (SetupHelp), null: the general sentence
            "aboutHint" to SetupHelp.aboutHint,
        )
    }

    /** Helper mode: once a new process had time to hear from a running helper, start one if none answered. */
    private val helperCheck = Runnable {
        if (!disposed) { WirelessSetup.restartHelperIfNeeded(activity); refresh() }
    }

    fun onResume() {
        main.removeCallbacks(helperCheck)
        if (HelperDumps.helperMode(activity) && !HelperDumps.helperReady) {
            if (HelperDumps.settling) main.postDelayed(helperCheck, HelperDumps.SETTLE_MS) else helperCheck.run()
        }
        refresh(); setupTick.run()
    }
    fun onPause() { main.removeCallbacks(setupTick); main.removeCallbacks(helperCheck) }

    fun dispose() {
        disposed = true
        main.removeCallbacks(setupTick)
        main.removeCallbacks(helperCheck)
        ShizukuSetup.removeListener(shizukuGrantEnded)
        WirelessSetup.removeListener(changed)
        CoverHelper.removeListener(changed)
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
                    Protection.checkStop(activity)  // throws "protected" when the waiting period or PIN holds it
                    activity.startService(Intent(activity, FilterService::class.java).setAction(FilterService.ACTION_STOP))
                    result.success(null)
                }
                "runSetupStep" -> { runSetupStep(call.argument<Int>("step") ?: throw BadArgs("step")); result.success(null) }
                "openShizuku" -> { openShizuku(); result.success(null) }
                // --- setup on the phone itself (Wireless debugging), as MainActivity.startWireless / askPairingCode
                "wirelessStart" -> result.success(wirelessStart(askedNotifications = false))
                "wirelessEnterCode" -> result.success(WirelessSetup.enterCode(activity, call.argument<String>("code") ?: ""))
                "wirelessCancel" -> { WirelessSetup.cancel(activity); result.success(null) }
                "openAboutPhone" -> { WirelessSetup.openWirelessDebugging(activity); result.success(null) }
                "guidePicture" -> {
                    // the illustrated guide's picture in the app's language (res/drawable-<language>-nodpi); through
                    // Lang.wrap because below Android 13 this activity keeps the language it started with
                    val id = SetupGuideActivity.PICTURES[call.argument<String>("name")]
                        ?: throw BadArgs("guide picture ${call.argument<Any>("name")}")
                    result.success(Lang.wrap(activity).resources.openRawResource(id).use { it.readBytes() })
                }
                "openWifiSettings" -> {
                    runCatching { activity.startActivity(Intent(android.provider.Settings.ACTION_WIFI_SETTINGS)) }
                    result.success(null)
                }
                "openSetupGuide" -> { activity.startActivity(Intent(activity, SetupGuideActivity::class.java)); result.success(null) }
                "pageShown" -> { pageRequest = null; result.success(null) }
                "shareText" -> {
                    activity.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain")
                        .putExtra(Intent.EXTRA_TEXT, call.argument<String>("text") ?: throw BadArgs("text")), null))
                    result.success(null)
                }
                "openDeveloperOptions" -> {
                    // Developer options, or About phone when they are not turned on yet (step 2 of the guide).
                    // Checked first: with them off, the Developer options page opens and closes at once (no exception).
                    val devOn = android.provider.Settings.Global.getInt(activity.contentResolver,
                        android.provider.Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) == 1
                    val about = Intent(android.provider.Settings.ACTION_DEVICE_INFO_SETTINGS)
                    // highlight: the key of one switch on that page, scrolled to and flashed (AOSP Settings' search
                    // extra; phones that ignore it just open the page)
                    val dev = Intent(android.provider.Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
                    when (call.argument<String>("highlight")) {
                        "screen_share" -> dev.putExtra(":settings:fragment_args_key", ScreenShareProtection.KEY)
                    }
                    if (devOn) runCatching { activity.startActivity(dev) }
                        .onFailure { activity.startActivity(about) }
                    else activity.startActivity(about)
                    result.success(null)
                }
                "openAppSettings" -> {
                    activity.startActivity(Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:${activity.packageName}")))
                    result.success(null)
                }
                "openOverlaySettings" -> {
                    activity.startActivity(Intent(android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${activity.packageName}")))
                    result.success(null)
                }
                "setLanguage" -> {
                    val tag = call.argument<String>("tag")?.takeIf { it in Lang.ALL }
                        ?: throw BadArgs("language ${call.argument<Any>("tag")}")
                    Lang.store(activity, tag)
                    result.success(null)
                    refresh()
                }
                "openLinkScreen" -> { activity.startActivity(Intent(activity, LinkActivity::class.java)); result.success(null) }
                "getLicences" -> result.success(mapOf(
                    "notice" to licenceAsset("NOTICE.txt"),
                    "docs" to LicencesActivity.DOCS.map { (label, file) -> mapOf("label" to label, "file" to file) }))
                "diagnosticsReport" -> result.success(Diagnostics.report(activity))
                "getLicenceText" -> {
                    val file = call.argument<String>("file")
                    if (LicencesActivity.DOCS.none { it.second == file }) throw BadArgs("licence file $file")
                    result.success(licenceAsset(file!!))
                }
                else -> {
                    val (feature, method) = Features.byMethod(call.method) ?: run { result.notImplemented(); return }
                    @Suppress("UNCHECKED_CAST")
                    val args = (call.arguments as? Map<String, Any?>) ?: emptyMap()
                    result.success(feature.call(featureHost, method, args))
                }
            }
        } catch (e: FeatureException) {
            result.error(e.code, e.message, null)
        } catch (e: BadArgs) {
            result.error("bad_args", e.message, null)
        } catch (e: Exception) {
            result.error("failed", e.message ?: e.javaClass.simpleName, null)
        }
    }

    /** The contract's snapshot (docs/UI_CONTRACT.md). */
    private fun snapshot(): Map<String, Any?> = mapOf(
        "platform" to "android",
        // a page to show once (the tiles' "Open Waaiya", a notification): {page, id}; Flutter calls pageShown
        "navigate" to pageRequest?.let { (page, id) -> mapOf("page" to page, "id" to id) },
        "version" to BuildConfig.VERSION_NAME,
        "language" to Lang.current(activity),
        "settings" to mapOf(
            "gender" to settings.gender,
            "mute_women_singing" to settings.muteWomenSinging,
            "silence_unfilterable" to settings.silenceUnfilterable,
            "blur_on" to settings.blurEnabled,
            "blur_women" to settings.blurWomen,
            "blur_nudity" to settings.blurNudity,
            "blur_fail_cover" to settings.blurFailCover,
            "blur_strictness" to settings.blurStrictness,
            "audio_stereo" to settings.audioStereo,
            "hold_silence" to settings.holdSilence,
            "simple_mode" to settings.simpleMode,
            "simple_channel" to settings.simpleChannel,
            "filter_off_apps" to settings.filterOffApps.sorted().joinToString(","),
            "blur_off_apps" to settings.blurOffApps.sorted().joinToString(","),
            "keep_singing" to settings.keepSinging,
            "prayer_silent" to settings.prayerSilent,
            "prayer_silent_minutes" to settings.prayerSilentMinutes,
            "prayer_adhan_mute" to settings.prayerAdhanMute,
            "prayer_adhan_minutes" to settings.prayerAdhanMinutes,
            "prayer_place" to settings.prayerPlace,
            "prayer_method" to settings.prayerMethod,
            "prayer_asr" to settings.prayerAsr,
            "prayer_sms_reply" to settings.prayerSmsReply,
            "prayer_sms_delay_seconds" to settings.prayerSmsDelaySeconds,
            "prayer_sms_text" to settings.prayerSmsText,
            "protect_delay_minutes" to settings.protectDelayMinutes,
        ),
        "filter" to mapOf(
            "state" to FilterService.state.name,
            "delayMs" to FilterService.delayMs,
            "micDenied" to micDenied,
            "simulated" to false,
            // what the user actually hears while filtering (MainActivity.refresh): a problem first
            "problem" to if (FilterService.state != FilterService.State.FILTERING) null else when {
                FilterService.health?.tooSlow == true -> "too_slow"
                FilterService.muterStatus == SessionMuter.Status.NO_PERMISSION ->
                    if (activity.helperMissing()) "helper_missing" else "not_muted"
                FilterService.muterStatus == SessionMuter.Status.FAILING -> "mute_failing"
                else -> null
            },
            // mono because the phone could not keep up with the stereo chosen, not mono by choice (MainActivity)
            "mono" to (FilterService.health?.monoForSpeed == true),
            "blockedApps" to FilterService.blockedApps,
            "captureCancelled" to captureCancelled,
            // this filtering started with "Share one app" offered and the blur was turned on since: it needs a restart
            "blurNeedsRestart" to (FilterService.running && FilterService.oneAppSession && settings.blurOn),
        ),
        "setup" to mapOf(
            // DUMP granted, or this phone refused it and Waaiya's helper reads the sessions (HelperDumps)
            // simple mode (test) silences the originals with the media mute instead of the setup
            "originalsMuted" to (activity.setupDone() || settings.simpleMode),
            "helperMode" to HelperDumps.helperMode(activity),
            // helper mode but the helper is not running (after a restart): the Setup and Filter pages say how
            "helperMissing" to activity.helperMissing(),
            // an automatic restart of the helper is trying (short and silent); a run the user started shows its steps
            "helperRestarting" to (WirelessSetup.running && WirelessSetup.quietRun),
            "helperTip" to when (SetupHelp.brand) {
                SetupHelp.Brand.XIAOMI -> "xiaomi"; SetupHelp.Brand.COLOROS -> "coloros"; SetupHelp.Brand.OTHER -> null
            },
            "consentSkipped" to activity.hasProjectMediaAppOp(),
            // the notification-text tile is on but WRITE_SECURE_SETTINGS is missing: the setup grants it
            "notificationTextNeedsSetup" to ScreenShareProtection.needsSetup(activity),
            // Android 15+ hides notification text during any whole-screen capture, filtering included: the Filter
            // options switch (setup done: Waaiya lifts it only while filtering) or Developer options by hand
            "notificationText" to mapOf(
                "supported" to ScreenShareProtection.supported,
                "canWrite" to ScreenShareProtection.setUp(activity),
                "wanted" to settings.showNotificationText,
                // no PROJECT_MEDIA: Waaiya lifts it anyway while filtering, or Android stops filtering at each lock
                "forcedForLock" to ScreenShareProtection.neededForLock(activity),
                // Android 16+: the start question also offers "Share one app" (pick Waaiya: text shown, no lock stop)
                "oneAppOffered" to CaptureChoice.offerOneApp(activity),
                // the one-app notice advises the one-time pairing until it is done (simple mode included)
                "pairAdvised" to !activity.setupDone(),
                "protectionOff" to ScreenShareProtection.protectionOff(activity),
                "shownNow" to ScreenShareProtection.shownInCapture,
                "refused" to ScreenShareProtection.refusedByPhone,
            ),
            // Xiaomi: its notification style can hide the field for the pairing code (SetupHelp)
            // or Huawei: Wireless debugging may be missing there, the computer is then the way
            "deviceNote" to when {
                SetupHelp.brand == SetupHelp.Brand.XIAOMI -> "xiaomi"
                SetupHelp.aboutHint == "huawei" && Build.MANUFACTURER.contains("huawei", ignoreCase = true) -> "huawei"
                else -> null
            },
            "shizuku" to ShizukuSetup.state(activity).name,
            "wireless" to wirelessInfo(),
            "busy" to shizukuBusy,
            "message" to shizukuMessage?.let { (code, detail) -> mapOf("code" to code, "detail" to detail) },
            "adbCommands" to "adb shell pm grant ${activity.packageName} android.permission.DUMP\n" +
                "adb shell appops set ${activity.packageName} PROJECT_MEDIA allow\n" +
                "adb shell pm grant ${activity.packageName} android.permission.WRITE_SECURE_SETTINGS",
        ),
        "blur" to mapOf(
            "state" to ScreenBlur.state?.name,
            "overlayAllowed" to android.provider.Settings.canDrawOverlays(activity),
            "a11yBuild" to BuildConfig.BLUR_A11Y,
            "a11yEnabled" to activity.blurAccessibilityEnabled(),
            "touchPassThrough" to activity.blurTouchPassThrough(),
            // Waaiya's helper runs (Android 12+): the covers are a shell layer (ShellCovers), touches pass through
            "shellLayer" to activity.blurShellLayerAvailable(),
            // Waaiya's own cover helper (CoverHelper): running, or startable through the on-phone setup (12+)
            "helperRunning" to CoverHelper.available,
            "helperStartable" to (Build.VERSION.SDK_INT >= 31 && WirelessSetup.supported),
            "layerSupported" to (Build.VERSION.SDK_INT >= 31),  // Shizuku covers need Android 12+
        ),
        "models" to mapOf("detector" to ModelStore.hasDetector(activity)),
        "features" to Features.ALL.associate { it.name to it.snapshot(featureHost) },
        "capabilities" to mapOf(
            "shizukuSetup" to true, "adbSetup" to true, "captureConsent" to true,
            "screenBlur" to true, "links" to BuildConfig.LINKS, "womenSinging" to true,
        ),
    )

    private fun setSetting(key: String?, value: Any?) {
        if (key == null) throw BadArgs("key")
        fun bool() = value as? Boolean ?: throw BadArgs("$key takes a bool")
        fun int(lo: Int, hi: Int) = (value as? Int)?.takeIf { it in lo..hi } ?: throw BadArgs("$key takes $lo to $hi")
        fun apps() = Settings.csv(value as? String ?: throw BadArgs("$key takes comma-separated package names"))
        Protection.checkSetting(activity, key, value)  // throws "protected" when the waiting period or PIN holds it
        when (key) {
            "gender" -> settings.gender = (value as? String)?.takeIf { it in listOf("", "man", "woman") }
                ?: throw BadArgs("gender is \"\", \"man\" or \"woman\"")
            "mute_women_singing" -> settings.muteWomenSinging = bool()
            "silence_unfilterable" -> settings.silenceUnfilterable = bool()
            "blur_on" -> settings.blurEnabled = bool()
            "blur_women" -> settings.blurWomen = bool()
            "blur_nudity" -> settings.blurNudity = bool()
            "blur_fail_cover" -> settings.blurFailCover = bool()
            "blur_strictness" -> settings.blurStrictness = (value as? Int)?.takeIf { it in 0..2 }
                ?: throw BadArgs("blur_strictness takes 0, 1 or 2")
            // read by the running filter (stereo) and when Android ends filtering (hold): apply at once
            "audio_stereo" -> settings.audioStereo = bool()
            "hold_silence" -> settings.holdSilence = bool()
            // read when filtering starts (a running filter keeps its way until the next start)
            "simple_mode" -> settings.simpleMode = bool()
            "simple_channel" -> settings.simpleChannel = (value as? String)?.takeIf { it == "alarm" || it == "notification" }
                ?: throw BadArgs("simple_channel is \"alarm\" or \"notification\"")
            "filter_off_apps" -> settings.filterOffApps = apps()
            "blur_off_apps" -> settings.blurOffApps = apps()
            "keep_singing" -> settings.keepSinging = bool()
            // as the Quick Settings tile: off puts Android's switch back at once; while filtering, a new capture
            // starts at once so the choice applies now (FilterService.restartForNotificationText)
            "show_notification_text" -> {
                val on = bool()
                settings.showNotificationText = on
                settings.notificationTextExplained = true
                if (!on) ScreenShareProtection.restore(activity)
                FilterService.restartForNotificationText(activity)?.let { runCatching { activity.startActivity(it) } }
            }
            "prayer_silent" -> settings.prayerSilent = bool()
            "prayer_silent_minutes" -> settings.prayerSilentMinutes = int(5, 90)
            "prayer_adhan_mute" -> settings.prayerAdhanMute = bool()
            "prayer_adhan_minutes" -> settings.prayerAdhanMinutes = int(1, 30)
            "prayer_place" -> settings.prayerPlace = value as? String ?: throw BadArgs("$key takes a string")
            "prayer_method" -> settings.prayerMethod = int(0, 15)
            "prayer_asr" -> settings.prayerAsr = int(0, 1)
            "prayer_sms_reply" -> settings.prayerSmsReply = bool()
            "prayer_sms_delay_seconds" -> settings.prayerSmsDelaySeconds = int(3, 60)
            "prayer_sms_text" -> settings.prayerSmsText = (value as? String)?.takeIf { it.length <= 300 }
                ?: throw BadArgs("$key takes a string of at most 300 characters")
            "protect_delay_minutes" -> settings.protectDelayMinutes = int(0, 1440)
            else -> throw BadArgs("unknown setting $key")
        }
        // No restart: the running filter and blur re-read Settings every 0.5 s.
        refresh()
    }

    // --- Start: runtime permissions, then the capture consent, then the service (as MainActivity.startFilter) ---

    private fun startFilter(result: MethodChannel.Result) {
        if (FilterService.running) { result.success("already_running"); return }
        if (pendingStart != null) { result.error("busy", "a start is waiting for a dialog", null); return }
        WirelessSetup.restartHelperIfNeeded(activity)  // helper mode after a restart (the muter waits for it)
        pendingStart = result
        micDenied = false
        captureCancelled = false
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
        // the entire screen, or on Android 16+ also "Share one app" (CaptureChoice)
        @Suppress("DEPRECATION") activity.startActivityForResult(CaptureChoice.intent(activity), REQ_CAPTURE)
    }

    fun onRequestPermissionsResult(requestCode: Int) {
        if (requestCode == REQ_WSETUP_NOTIFICATIONS) {  // answered (either way): go on with the on-phone setup
            if (wirelessStart(askedNotifications = true) == "dev_off") { wirelessHint = "wsetup_dev_off"; refresh() }
            return
        }
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
        } else {
            captureCancelled = true  // "Cancel" or back at Android's question: nothing started, say why it is asked
            finishStart("consent_denied")
        }
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
        ShizukuSetup.grant(activity, slow = {
            if (!disposed && shizukuBusy) { shizukuMessage = "slow" to ""; refresh() }
        }) { log ->
            if (disposed) return@grant
            shizukuBusy = false
            // A running filter starts silencing the originals by itself (SessionMuter waits for the permission).
            shizukuMessage = failure(log, activity.hasDumpPermission(), "failed")
            refresh()
        }
    }

    /**
     * The message after a Shizuku grant: none when it worked, `timeout`, `refused_xiaomi` / `refused_coloros` (the
     * phone itself refused: a Developer options switch, SetupHelp), else [generic] with the log as detail.
     */
    private fun failure(log: String, ok: Boolean, generic: String): Pair<String, String>? = when {
        ok -> null
        log == ShizukuSetup.TIMEOUT -> "timeout" to ""
        SetupHelp.refused(log) && SetupHelp.brand == SetupHelp.Brand.XIAOMI -> "refused_xiaomi" to log
        SetupHelp.refused(log) && SetupHelp.brand == SetupHelp.Brand.COLOROS -> "refused_coloros" to log
        else -> generic to log
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
        const val REQ_WSETUP_NOTIFICATIONS = 8
    }
}
