package org.waaiya.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.RemoteInput
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import org.waaiya.app.adb.AdbKey
import org.waaiya.app.adb.AdbPairingClient
import org.waaiya.app.adb.AdbServices
import org.waaiya.app.adb.AdbShell
import org.waaiya.app.adb.PairingInput
import org.waaiya.app.adb.SetupFlow
import java.io.File
import java.net.NetworkInterface
import java.util.concurrent.Executors
import javax.net.ssl.SSLSocket

/**
 * One-time setup on the phone itself, with Android's own Wireless debugging (Android 11+): no Shizuku, no computer.
 * Waaiya pairs with the phone's adbd like `adb pair` does (the protocol code is in the `adb` package), then connects
 * like `adb connect` and runs the same two commands as the computer route:
 *   cmd package grant <pkg> android.permission.DUMP
 *   cmd appops set <pkg> PROJECT_MEDIA allow
 *   cmd package grant <pkg> android.permission.WRITE_SECURE_SETTINGS   (optional: the notification-text tile)
 * Everything stays on the phone: the connections go to 127.0.0.1, mDNS only tells us the ports.
 *
 * The pairing code is shown by Settings while Waaiya is in the background, so it is typed into a notification
 * (RemoteInput), like Shizuku does; the app's own field is the fallback (split screen) when notifications are off.
 * Pairing happens once: the key stays in the app's no-backup files, and later runs (after a reboot or a reinstall
 * of the grants) connect straight away while Wireless debugging is on.
 */
object WirelessSetup {
    private const val TAG = "IslamicMute"
    private const val PREFS = "wireless_setup"

    /** Pairing with a code needs Android 11 (adbd's TLS pairing server). */
    val supported: Boolean get() = Build.VERSION.SDK_INT >= 30

    /** What the setup card shows while the service runs, and after it ends. Main thread only. */
    data class Status(val phase: SetupFlow.Phase, val note: SetupFlow.Note, val detail: String? = null)

    @Volatile var status: Status? = null
        private set
    private val listeners = mutableSetOf<() -> Unit>()
    private val main = Handler(Looper.getMainLooper())

    fun addListener(l: () -> Unit) { listeners += l }
    fun removeListener(l: () -> Unit) { listeners -= l }
    internal fun publish(s: Status?) { status = s; main.post { listeners.toList().forEach { it() } } }
    val running: Boolean get() = status?.phase.let { it == SetupFlow.Phase.WAITING || it == SetupFlow.Phase.PAIRING || it == SetupFlow.Phase.CONNECTING }

    fun keyDir(ctx: Context) = File(ctx.noBackupFilesDir, "adb")

    fun pairedBefore(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean("paired", false)
    internal fun setPaired(ctx: Context, v: Boolean) =
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean("paired", v).apply()

    fun developerOptionsOn(ctx: Context) = android.provider.Settings.Global.getInt(ctx.contentResolver,
        android.provider.Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) == 1

    /** Wireless debugging switch: true/false, or null when this Android does not let apps read it. */
    fun wirelessDebuggingOn(ctx: Context): Boolean? = runCatching {
        android.provider.Settings.Global.getInt(ctx.contentResolver, "adb_wifi_enabled", -1)
    }.getOrNull()?.takeIf { it >= 0 }?.let { it == 1 }

    /** Addresses of this phone (Wi-Fi and others): mDNS answers from other phones nearby are ignored. */
    fun localAddresses(): Set<String> = runCatching {
        NetworkInterface.getNetworkInterfaces().toList().flatMap { i -> i.inetAddresses.toList() }
            .mapNotNull { it.hostAddress }.toSet()
    }.getOrDefault(emptySet())

    /**
     * Connected to Wi-Fi, judged from the network interfaces (no extra permission): a "wlan" interface that is up
     * and has an address other than link-local. Only a hint for the user: Wireless debugging itself decides.
     */
    fun onWifi(): Boolean = runCatching {
        NetworkInterface.getNetworkInterfaces().toList().any { i ->
            i.isUp && !i.isLoopback && i.name.startsWith("wlan") &&
                i.inetAddresses.toList().any { !it.isLinkLocalAddress && !it.isLoopbackAddress }
        }
    }.getOrDefault(true)

    /** Developer options, scrolled to "Wireless debugging"; About phone when Developer options are still off. */
    fun openWirelessDebugging(ctx: Context): Boolean {
        if (!developerOptionsOn(ctx)) {
            // some phones have no page for this action (seen on a Huawei): the top of Settings then, where
            // "About phone" is and where the search finds "Build number"
            val about = Intent(android.provider.Settings.ACTION_DEVICE_INFO_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (runCatching { ctx.startActivity(about) }.isFailure)
                runCatching { ctx.startActivity(Intent(android.provider.Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
            return false
        }
        val dev = Intent(android.provider.Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
            .putExtra(":settings:fragment_args_key", "toggle_adb_wireless")
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return runCatching { ctx.startActivity(dev) }.isSuccess
    }

    /** Start the helper during the setup: Android 12+ and a screen-blur option on (covers), or helper mode. */
    fun helperWanted(ctx: Context): Boolean {
        val s = Settings(ctx)
        return (Build.VERSION.SDK_INT >= 31 && s.blurOn) || HelperDumps.helperMode(ctx)
    }

    fun start(ctx: Context) {
        ctx.startForegroundService(Intent(ctx, WirelessSetupService::class.java).setAction(WirelessSetupService.ACTION_START))
    }

    /**
     * Helper mode ([HelperDumps]) and the helper is not running (the phone restarted): start it again over Wireless
     * debugging with the saved pairing, without a code and without any screen. Not when Wireless debugging is seen
     * off; otherwise the app shows how ([helperMissing]). Called when filtering starts and when Waaiya comes to the
     * front, from an activity (a foreground service may only be started from the foreground). True when a run started.
     * The run is short and silent ([WirelessSetupService.EXTRA_QUIET]): when it fails, the app's banner and its button
     * are what the user sees.
     */
    private var lastAutoRestart = 0L

    /** The run in progress is an automatic helper restart: the pages show it as "starting the helper", no steps. */
    @Volatile var quietRun = false
        internal set

    fun restartHelperIfNeeded(ctx: Context): Boolean {
        if (!supported || running || !ctx.helperMissing() || !pairedBefore(ctx)) return false
        if (wirelessDebuggingOn(ctx) == false) return false
        // at most one automatic try every 3 minutes: the banner has the button for another try
        val now = android.os.SystemClock.elapsedRealtime()
        if (lastAutoRestart != 0L && now - lastAutoRestart < 3 * 60_000L) return false
        lastAutoRestart = now
        return runCatching {
            ctx.startForegroundService(Intent(ctx, WirelessSetupService::class.java)
                .setAction(WirelessSetupService.ACTION_START).putExtra(WirelessSetupService.EXTRA_QUIET, true))
        }.onFailure { log("cannot restart the helper", it) }.isSuccess
    }

    /** A code typed in the app (fallback when the notification cannot be used). False when it has no 6 digits. */
    fun enterCode(ctx: Context, raw: String): Boolean {
        if (PairingInput.parse(raw) == null) return false
        ctx.startService(Intent(ctx, WirelessSetupService::class.java).setAction(WirelessSetupService.ACTION_CODE)
            .putExtra(WirelessSetupService.EXTRA_CODE, raw))
        return true
    }

    fun cancel(ctx: Context) {
        if (running) ctx.startService(Intent(ctx, WirelessSetupService::class.java).setAction(WirelessSetupService.ACTION_CANCEL))
    }

    /**
     * TLS keying material for the pairing password. Android 12+: the public SSLSockets API. Android 11: the socket
     * comes from the bundled Conscrypt (AdbTls), whose Conscrypt.exportKeyingMaterial is public API.
     */
    internal fun exportKeyingMaterial(socket: SSLSocket, label: String, length: Int): ByteArray =
        (if (Build.VERSION.SDK_INT >= 31) android.net.ssl.SSLSockets.exportKeyingMaterial(socket, label, null, length)
         else org.conscrypt.Conscrypt.exportKeyingMaterial(socket, label, null, length))
            ?: throw javax.net.ssl.SSLException("no keying material")

    /**
     * The shell line run as the shell user. Each result is echoed so that the log says which step failed.
     * Debug builds: `adb shell run-as <pkg> touch files/simulate_refused` makes it answer like a Xiaomi or OPPO phone
     * that refuses the grants (to test the helper route on an emulator).
     */
    internal fun grantCommand(ctx: Context): String {
        if (BuildConfig.DEBUG && File(ctx.filesDir, "simulate_refused").exists()) return SIMULATED_REFUSAL
        return grantCommand(ctx.packageName)
    }

    private const val SIMULATED_REFUSAL = "echo \"Exception occurred while executing 'grant': java.lang.SecurityException: " +
        "grantRuntimePermission: Neither user 2000 nor current process has android.permission.GRANT_RUNTIME_PERMISSIONS.\"; " +
        "echo dump=255; echo project_media=255; echo secure_settings=255"

    internal fun grantCommand(pkg: String) =
        "cmd package grant $pkg android.permission.DUMP 2>&1; echo \"dump=\$?\"; " +
            "cmd appops set $pkg PROJECT_MEDIA allow 2>&1; echo \"project_media=\$?\"; " +
            "cmd package grant $pkg android.permission.WRITE_SECURE_SETTINGS 2>&1; echo \"secure_settings=\$?\""

    internal fun log(msg: String, t: Throwable? = null) { if (t == null) Log.i(TAG, "wireless setup: $msg") else Log.w(TAG, "wireless setup: $msg", t) }
}

/**
 * Runs the setup in the background while the user is in Settings: finds adbd's pairing and connect ports by mDNS,
 * asks for the code in a notification, pairs, connects and grants. Foreground (dataSync: a local network exchange,
 * permission already declared) for at most [TIMEOUT_MS], then it gives up and says so.
 */
class WirelessSetupService : Service() {
    override fun attachBaseContext(base: Context) { super.attachBaseContext(Lang.wrap(base)) }

    private val main = Handler(Looper.getMainLooper())
    private val startedAt = android.os.SystemClock.elapsedRealtime()
    private val worker = Executors.newSingleThreadExecutor { Thread(it, "im-adb-setup") }
    private var flow: SetupFlow? = null
    private var nsd: NsdManager? = null
    private val discoveries = mutableListOf<NsdManager.DiscoveryListener>()
    private val resolveQueue = ArrayDeque<NsdServiceInfo>()
    private var resolving = false
    /** service name -> port, per type, for "lost" events (which carry no port) */
    private val ports = mutableMapOf<String, Int>()
    private val seenNames = mutableMapOf<String, MutableSet<String>>()
    private var detail: String? = null
    private var key: AdbKey? = null
    /** What the notification shows now: re-posting the same one would close a reply field the user is typing in. */
    private var shown: List<Any?>? = null
    /** Started by [WirelessSetup.restartHelperIfNeeded]: short, and no result notification when it worked. */
    private var quiet = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val q = intent.getBooleanExtra(EXTRA_QUIET, false)
                if (flow == null) quiet = q
                // the user tapped the button while an automatic restart was trying: it becomes a normal run
                else if (!q && quiet) { quiet = false; main.removeCallbacks(timeout); main.postDelayed(timeout, TIMEOUT_MS) }
                WirelessSetup.quietRun = quiet
                begin()
            }
            ACTION_CODE -> {
                val raw = RemoteInput.getResultsFromIntent(intent)?.getCharSequence(KEY_REMOTE_CODE)?.toString()
                    ?: intent.getStringExtra(EXTRA_CODE)
                if (flow == null) begin()
                onCode(raw)
            }
            ACTION_CANCEL -> { finish(null, cancelled = true); return START_NOT_STICKY }
            else -> if (flow == null) { stopSelf(); return START_NOT_STICKY }
        }
        return START_NOT_STICKY
    }

    private fun begin() {
        if (flow != null) { update(); return }
        val f = SetupFlow(WirelessSetup.pairedBefore(this) && AdbKey.load(WirelessSetup.keyDir(this)) != null)
        flow = f
        detail = null
        // Can be refused when started from the background (a reply to a notification of a run whose process died).
        val fg = runCatching {
            if (Build.VERSION.SDK_INT >= 34) startForeground(NOTIFICATION_ID, notification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
            else startForeground(NOTIFICATION_ID, notification())
        }
        if (fg.isFailure) { WirelessSetup.log("cannot run in the foreground", fg.exceptionOrNull()); flow = null; stopSelf(); return }
        publish()
        // The key: made now, while the user is still on the way to the pairing dialog (RSA takes a moment).
        worker.execute { runCatching { key = AdbKey.loadOrCreate(WirelessSetup.keyDir(this)) }
            .onFailure { WirelessSetup.log("key", it) } }
        startDiscovery()
        main.postDelayed(timeout, if (quiet) QUIET_TIMEOUT_MS else TIMEOUT_MS)
        main.postDelayed(refresher, REFRESH_MS)
    }

    private val timeout = Runnable { flow?.timedOut(); finish(null) }

    /** While waiting, the notification re-checks Wi-Fi and the Wireless debugging switch. */
    private val refresher = object : Runnable {
        override fun run() {
            if (flow?.phase == SetupFlow.Phase.WAITING) update()
            main.postDelayed(this, REFRESH_MS)
        }
    }

    private fun onCode(raw: String?) {
        val f = flow ?: return
        shown = null  // after a notification reply Android shows a spinner until the notification is posted again
        val parsed = raw?.let { PairingInput.parse(it) }
        if (parsed == null) {
            detail = getString(R.string.wsetup_code_unreadable)
            update(); return
        }
        detail = null
        run(f.codeEntered(parsed.code, parsed.port))
        update()
    }

    // --- mDNS -----------------------------------------------------------------------------------------------------

    private fun startDiscovery() {
        val m = getSystemService(NsdManager::class.java) ?: return
        nsd = m
        for (type in listOf(AdbServices.PAIRING_TYPE, AdbServices.CONNECT_TYPE)) {
            val l = object : NsdManager.DiscoveryListener {
                override fun onDiscoveryStarted(serviceType: String) {}
                override fun onDiscoveryStopped(serviceType: String) {}
                override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                    WirelessSetup.log("discovery of $type failed: $errorCode")
                }
                override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {}
                override fun onServiceFound(info: NsdServiceInfo) { main.post { seen(type, info.serviceName); enqueue(info) } }
                override fun onServiceLost(info: NsdServiceInfo) {
                    main.post {
                        val port = ports.remove(type + "/" + info.serviceName) ?: return@post
                        if (type == AdbServices.PAIRING_TYPE) flow?.pairingPortLost(port)
                        update()
                    }
                }
            }
            runCatching { m.discoverServices(type, NsdManager.PROTOCOL_DNS_SD, l); discoveries += l }
                .onFailure { WirelessSetup.log("discoverServices $type", it) }
        }
    }

    private fun seen(type: String, name: String) { seenNames.getOrPut(type) { mutableSetOf() } += name }

    private fun enqueue(info: NsdServiceInfo) { resolveQueue.addLast(info); resolveNext() }

    /** One resolve at a time: older Androids fail a second one with FAILURE_ALREADY_ACTIVE. */
    @Suppress("DEPRECATION")  // resolveService: the replacement (registerServiceInfoCallback) is Android 14+ only
    private fun resolveNext() {
        val m = nsd ?: return
        if (resolving) return
        val info = resolveQueue.removeFirstOrNull() ?: return
        resolving = true
        val listener = object : NsdManager.ResolveListener {
            override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                main.post { resolving = false; WirelessSetup.log("resolve ${serviceInfo.serviceName}: $errorCode"); resolveNext() }
            }
            override fun onServiceResolved(r: NsdServiceInfo) {
                main.post { resolving = false; resolved(r); resolveNext() }
            }
        }
        runCatching { m.resolveService(info, listener) }.onFailure { resolving = false; WirelessSetup.log("resolve", it) }
    }

    private fun resolved(r: NsdServiceInfo) {
        val f = flow ?: return
        val type = r.serviceType.trim('.').let { t -> listOf(AdbServices.PAIRING_TYPE, AdbServices.CONNECT_TYPE).firstOrNull { t.contains(it) } } ?: return
        @Suppress("DEPRECATION") val host = r.host?.hostAddress
        val found = AdbServices.Found(r.serviceName, host, r.port)
        val others = (seenNames[type]?.size ?: 1) - 1
        if (!AdbServices.isOurs(found, WirelessSetup.localAddresses(), others)) {
            WirelessSetup.log("ignoring ${r.serviceName} at $host (another device)"); return
        }
        ports[type + "/" + r.serviceName] = r.port
        WirelessSetup.log("found $type port ${r.port}")
        run(if (type == AdbServices.PAIRING_TYPE) f.pairingPortFound(r.port) else f.connectPortFound(r.port))
        update()
    }

    // --- actions (network on the worker thread, decisions on the main thread) --------------------------------------

    private fun run(action: SetupFlow.Action?) {
        when (action) {
            null -> return
            is SetupFlow.Action.Pair -> worker.execute { pair(action.port, action.code) }
            is SetupFlow.Action.Connect -> worker.execute { connect(action.port) }
        }
        update()
    }

    private fun ensureKey(): AdbKey = key ?: AdbKey.loadOrCreate(WirelessSetup.keyDir(this)).also { key = it }

    private fun pair(port: Int, code: String) {
        val result = runCatching {
            AdbPairingClient(ensureKey(), WirelessSetup::exportKeyingMaterial).pair(LOCALHOST, port, code)
        }
        main.post {
            val f = flow ?: return@post
            result.onSuccess {
                WirelessSetup.log("paired")
                WirelessSetup.setPaired(this, true)
                detail = null
                run(f.pairSucceeded())
            }.onFailure {
                WirelessSetup.log("pairing failed", it)
                val wrong = it is AdbPairingClient.WrongCodeException
                detail = if (wrong) null else describe(it)
                f.pairFailed(wrong)
            }
            update()
        }
    }

    private fun connect(port: Int) {
        val result = runCatching {
            val shell = AdbShell(ensureKey())
            val grants = shell.run(LOCALHOST, port, WirelessSetup.grantCommand(this), timeoutMs = 30_000)
            // Waaiya's helper (a shell-uid process, CoverHelper) on the same connection: for the screen-blur covers
            // (Android 12+), and on phones that refused the grants (Xiaomi, OPPO family without their hidden
            // Developer options switch), where it reads the sound sessions for the app (HelperDumps)
            val refused = !hasDumpPermission()
            // a second connection: its failure is "the helper did not start", not a failed setup when DUMP is granted
            val helper = if (refused || WirelessSetup.helperWanted(this))
                "\n" + runCatching { shell.run(LOCALHOST, port, CoverHelper.startCommand(this)) }
                    .getOrElse { "helper=missing ($it)" } else ""
            Triple(grants + helper, refused, helper.contains("helper=started"))
        }
        main.post {
            val f = flow ?: return@post
            result.onSuccess { (out, refused, helperStarted) ->
                WirelessSetup.log("grants:\n$out")
                SetupLog.record(this, "Wireless debugging", android.os.SystemClock.elapsedRealtime() - startedAt, out)
                if (!refused) {
                    // DUMP is what silences the originals. PROJECT_MEDIA only skips Android's question at each
                    // start, and some phones ignore that command without an error (vivo): not a failed setup.
                    HelperDumps.setHelperMode(this, false)
                    if (!hasProjectMediaAppOp()) WirelessSetup.log("PROJECT_MEDIA not allowed: Android asks at each start")
                    detail = null
                    f.grantsDone(true)
                    finish(null)
                } else if (helperStarted) {
                    // the helper hands its binder over within a few seconds (CoverHelper.main): wait for it
                    awaitHelper(out)
                } else {
                    detail = out.trim()
                    f.grantsDone(false)
                    finish(out.trim())
                }
            }.onFailure {
                WirelessSetup.log("connect failed", it)
                SetupLog.record(this, "Wireless debugging", android.os.SystemClock.elapsedRealtime() - startedAt,
                    "connect failed: $it")
                if (it is AdbShell.NotPairedException) { WirelessSetup.setPaired(this, false); detail = null; f.connectRefused() }
                else { detail = describe(it); f.connectFailed() }
                // an automatic restart does not wait for a code or for Wireless debugging to come back
                if (quiet) finish(null) else update()
            }
        }
    }

    /** The grants were refused and the helper started: done once it answers, failed after [HELPER_WAIT_MS]. */
    private fun awaitHelper(out: String) {
        val until = android.os.SystemClock.elapsedRealtime() + HELPER_WAIT_MS
        val check = object : Runnable {
            override fun run() {
                val f = flow ?: return
                if (HelperDumps.helperReady) {
                    HelperDumps.setHelperMode(this@WirelessSetupService, true)
                    WirelessSetup.log("grants refused: Waaiya's helper reads the sound sessions instead")
                    detail = null
                    f.grantsDone(true, viaHelper = true)
                    finish(null)
                } else if (android.os.SystemClock.elapsedRealtime() > until) {
                    detail = out.trim() + "\nhelper=no answer"
                    f.grantsDone(false)
                    finish(detail)
                } else main.postDelayed(this, 500)
            }
        }
        helperCheck = check
        main.post(check)
    }
    private var helperCheck: Runnable? = null

    private fun describe(t: Throwable): String = when (t) {
        is java.net.SocketTimeoutException -> getString(R.string.wsetup_err_timeout)
        is java.net.ConnectException -> getString(R.string.wsetup_err_refused)
        else -> t.message ?: t.javaClass.simpleName
    }

    // --- notification and state --------------------------------------------------------------------------------------

    private fun publish() {
        val f = flow ?: return
        WirelessSetup.publish(WirelessSetup.Status(f.phase, f.note, detail))
    }

    private fun update() {
        publish()
        val f = flow ?: return
        val now = listOf(texts(), f.phase, f.note, quiet)
        if (now == shown) return
        shown = now
        runCatching { getSystemService(NotificationManager::class.java).notify(NOTIFICATION_ID, notification()) }
    }

    /** The text for the current state; also used by the app's setup card. */
    private fun texts(): Pair<String, String> {
        val f = flow ?: return getString(R.string.wsetup_notif_title) to ""
        return WirelessSetupTexts.title(this, f.phase, f.note) to WirelessSetupTexts.body(this, f.phase, f.note, detail)
    }

    /** The code step the notification last popped up for (see [notification]); null outside the code steps. */
    private var alertedFor: SetupFlow.Note? = null

    private fun notification(): Notification {
        val nm = getSystemService(NotificationManager::class.java)
        // The helper's automatic restart: one quiet line, no code to type, nothing that pops up over the app.
        if (quiet) {
            nm.createNotificationChannel(NotificationChannel(CHANNEL_QUIET, getString(R.string.helper_channel),
                NotificationManager.IMPORTANCE_LOW))
            return Notification.Builder(this, CHANNEL_QUIET)
                .setSmallIcon(R.drawable.ic_notification).setColor(getColor(R.color.primary))
                .setContentTitle(getString(R.string.helper_starting)).setOngoing(true)
                .setCategory(Notification.CATEGORY_STATUS).build()
        }
        // High importance: the code is typed while Settings is in front, so the notification has to pop up there.
        nm.createNotificationChannel(NotificationChannel(CHANNEL, getString(R.string.wsetup_channel), NotificationManager.IMPORTANCE_HIGH)
            .apply { setSound(null, null); enableVibration(false) })
        val (title, body) = texts()
        val open = PendingIntent.getActivity(this, 0, UiActivity.main(this)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP), PendingIntent.FLAG_IMMUTABLE)
        val b = Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_notification).setColor(getColor(R.color.primary))
            .setContentTitle(title).setContentText(body).setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(open).setOngoing(true)
            .setCategory(Notification.CATEGORY_STATUS)
        val f = flow
        // Pop up again (like Shizuku) when the code is wanted: the moment "Pair device with pairing code" is opened in
        // Settings (pairing port found), and after a wrong code. A pop-up hides after a few seconds, and the first one
        // came when the setup started, before the user went to Settings. Other updates stay silent.
        val codeStep = f?.takeIf { it.phase == SetupFlow.Phase.WAITING }?.note
            ?.takeIf { it == SetupFlow.Note.ENTER_CODE || it == SetupFlow.Note.WRONG_CODE }
        b.setOnlyAlertOnce(codeStep == null || codeStep == alertedFor)
        alertedFor = codeStep
        if (f != null && f.phase == SetupFlow.Phase.WAITING && f.note != SetupFlow.Note.WAITING_FOR_CONNECT_PORT) {
            val reply = PendingIntent.getService(this, 1, Intent(this, WirelessSetupService::class.java).setAction(ACTION_CODE),
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0))
            val input = RemoteInput.Builder(KEY_REMOTE_CODE).setLabel(getString(R.string.wsetup_code_hint)).build()
            b.addAction(Notification.Action.Builder(null, getString(R.string.wsetup_enter_code), reply).addRemoteInput(input).build())
        }
        val cancel = PendingIntent.getService(this, 2, Intent(this, WirelessSetupService::class.java).setAction(ACTION_CANCEL),
            PendingIntent.FLAG_IMMUTABLE)
        b.addAction(Notification.Action.Builder(null, getString(R.string.wsetup_cancel), cancel).build())
        return b.build()
    }

    /** Ends the run: a last notification with the result (tap opens Waaiya), unless the user cancelled. */
    private fun finish(failureDetail: String?, cancelled: Boolean = false) {
        val f = flow
        main.removeCallbacks(timeout)
        main.removeCallbacks(refresher)
        helperCheck?.let { main.removeCallbacks(it) }
        helperCheck = null
        stopDiscovery()
        WirelessSetup.quietRun = false
        if (f != null && !cancelled && quiet) {
            // the helper is back: nothing to tell. It is not: the app's banner says so and has the button.
            if (f.phase != SetupFlow.Phase.DONE) WirelessSetup.log("automatic helper restart gave up (${f.phase}, ${f.note})")
            WirelessSetup.publish(null)
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else if (f != null && !cancelled) {
            detail = failureDetail ?: detail
            publish()
            val (title, body) = texts()
            val open = PendingIntent.getActivity(this, 0, UiActivity.main(this), PendingIntent.FLAG_IMMUTABLE)
            stopForeground(STOP_FOREGROUND_REMOVE)
            runCatching {
                getSystemService(NotificationManager::class.java).notify(RESULT_NOTIFICATION_ID, Notification.Builder(this, CHANNEL)
                    .setSmallIcon(R.drawable.ic_notification)
                    .setColor(getColor(if (f.phase == SetupFlow.Phase.DONE) R.color.primary else R.color.error))
                    .setContentTitle(title).setContentText(body).setStyle(Notification.BigTextStyle().bigText(body))
                    .setContentIntent(open).setAutoCancel(true).setOnlyAlertOnce(true).build())
            }
        } else {
            WirelessSetup.publish(null)
            stopForeground(STOP_FOREGROUND_REMOVE)
        }
        flow = null
        stopSelf()
    }

    private fun stopDiscovery() {
        val m = nsd ?: return
        discoveries.forEach { runCatching { m.stopServiceDiscovery(it) } }
        discoveries.clear()
        resolveQueue.clear()
        nsd = null
    }

    override fun onDestroy() {
        main.removeCallbacks(timeout)
        main.removeCallbacks(refresher)
        stopDiscovery()
        WirelessSetup.quietRun = false
        if (WirelessSetup.running) WirelessSetup.publish(null)  // killed while running: the card offers Start again
        worker.shutdownNow()
        super.onDestroy()
    }

    companion object {
        const val ACTION_START = "org.waaiya.app.wsetup.START"
        const val ACTION_CODE = "org.waaiya.app.wsetup.CODE"
        const val ACTION_CANCEL = "org.waaiya.app.wsetup.CANCEL"
        const val EXTRA_CODE = "code"
        const val EXTRA_QUIET = "quiet"
        private const val KEY_REMOTE_CODE = "pairing_code"
        private const val CHANNEL = "setup"
        private const val CHANNEL_QUIET = "helper"
        private const val NOTIFICATION_ID = 21
        private const val RESULT_NOTIFICATION_ID = 22
        private const val LOCALHOST = "127.0.0.1"
        private const val TIMEOUT_MS = 10 * 60_000L
        private const val REFRESH_MS = 5_000L
        /** The helper waits for the app's process to be seen twice, 2 s apart, before it hands its binder over. */
        private const val HELPER_WAIT_MS = 12_000L
        /** An automatic restart: adbd's port is announced within seconds when Wireless debugging is on. */
        private const val QUIET_TIMEOUT_MS = 25_000L
    }
}

/** Words for each state, shared by the notification and the app's setup card. */
object WirelessSetupTexts {
    @androidx.annotation.StringRes
    fun titleRes(phase: SetupFlow.Phase, note: SetupFlow.Note): Int = when (phase) {
        SetupFlow.Phase.DONE -> R.string.wsetup_done_title
        SetupFlow.Phase.FAILED -> R.string.wsetup_failed_title
        SetupFlow.Phase.PAIRING, SetupFlow.Phase.CONNECTING -> R.string.wsetup_busy_title
        SetupFlow.Phase.WAITING -> if (note == SetupFlow.Note.ENTER_CODE) R.string.wsetup_found_title else R.string.wsetup_notif_title
    }

    /** The main sentence (without the detail line). The Flutter screens get its resource name (UiBridge). */
    @androidx.annotation.StringRes
    fun bodyRes(ctx: Context, phase: SetupFlow.Phase, note: SetupFlow.Note, detail: String?): Int = when (phase) {
        // a running filter picks the permission (or the helper) up by itself
        SetupFlow.Phase.DONE -> if (note == SetupFlow.Note.VIA_HELPER) R.string.wsetup_done_helper_body else R.string.wsetup_done_body
        SetupFlow.Phase.PAIRING -> R.string.wsetup_pairing
        SetupFlow.Phase.CONNECTING -> R.string.wsetup_connecting
        else -> when (note) {
            SetupFlow.Note.NONE, SetupFlow.Note.OPEN_PAIRING_DIALOG -> when {
                !WirelessSetup.onWifi() -> R.string.wsetup_need_wifi
                WirelessSetup.wirelessDebuggingOn(ctx) == false -> R.string.wsetup_need_wireless_debugging
                else -> R.string.wsetup_open_dialog
            }
            SetupFlow.Note.ENTER_CODE -> R.string.wsetup_enter_code_body
            SetupFlow.Note.CODE_WAITING_FOR_DIALOG -> R.string.wsetup_code_waiting
            SetupFlow.Note.WRONG_CODE -> R.string.wsetup_wrong_code
            SetupFlow.Note.PAIRING_FAILED -> R.string.wsetup_pairing_failed
            SetupFlow.Note.WAITING_FOR_CONNECT_PORT -> R.string.wsetup_waiting_connect
            SetupFlow.Note.NOT_PAIRED -> R.string.wsetup_not_paired
            SetupFlow.Note.CONNECT_FAILED -> R.string.wsetup_connect_failed
            // the phone itself refused (Xiaomi, OPPO family: a Developer options switch), else the generic text
            SetupFlow.Note.GRANT_FAILED -> when {
                !SetupHelp.refused(detail.orEmpty()) -> R.string.wsetup_grant_failed
                SetupHelp.brand == SetupHelp.Brand.XIAOMI -> R.string.setup_refused_xiaomi
                SetupHelp.brand == SetupHelp.Brand.COLOROS -> R.string.setup_refused_coloros
                else -> R.string.wsetup_grant_failed
            }
            SetupFlow.Note.TIMEOUT -> R.string.wsetup_timeout
            SetupFlow.Note.VIA_HELPER -> R.string.wsetup_done_helper_body
        }
    }

    fun title(ctx: Context, phase: SetupFlow.Phase, note: SetupFlow.Note): String = ctx.getString(titleRes(phase, note))

    fun body(ctx: Context, phase: SetupFlow.Phase, note: SetupFlow.Note, detail: String?): String {
        val main = ctx.getString(bodyRes(ctx, phase, note, detail))
        // a refusal explained in words needs no raw log under it
        val showDetail = !detail.isNullOrBlank() && !(note == SetupFlow.Note.GRANT_FAILED && SetupHelp.refused(detail) &&
            SetupHelp.brand != SetupHelp.Brand.OTHER)
        return if (!showDetail) main else main + "\n" + ctx.getString(R.string.wsetup_detail, detail)
    }
}
