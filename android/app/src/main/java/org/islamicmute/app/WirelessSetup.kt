package org.islamicmute.app

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
import org.islamicmute.app.adb.AdbKey
import org.islamicmute.app.adb.AdbPairingClient
import org.islamicmute.app.adb.AdbServices
import org.islamicmute.app.adb.AdbShell
import org.islamicmute.app.adb.PairingInput
import org.islamicmute.app.adb.SetupFlow
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
            runCatching { ctx.startActivity(Intent(android.provider.Settings.ACTION_DEVICE_INFO_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
            return false
        }
        val dev = Intent(android.provider.Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
            .putExtra(":settings:fragment_args_key", "toggle_adb_wireless")
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return runCatching { ctx.startActivity(dev) }.isSuccess
    }

    fun start(ctx: Context) {
        ctx.startForegroundService(Intent(ctx, WirelessSetupService::class.java).setAction(WirelessSetupService.ACTION_START))
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
     * TLS keying material for the pairing password. Android 12+: the public SSLSockets API. Android 11 has the same
     * function in the platform's Conscrypt (com.android.org.conscrypt.Conscrypt.exportKeyingMaterial, what SSLSockets
     * calls on 12+) but not in the SDK yet, so it is called through reflection (with the hidden-API exemption the
     * screen blur already uses). Fallback: the socket's own package-private method.
     */
    internal fun exportKeyingMaterial(socket: SSLSocket, label: String, length: Int): ByteArray {
        if (Build.VERSION.SDK_INT >= 31) return android.net.ssl.SSLSockets.exportKeyingMaterial(socket, label, null, length)
            ?: throw javax.net.ssl.SSLException("no keying material")
        org.lsposed.hiddenapibypass.HiddenApiBypass.addHiddenApiExemptions("Lcom/android/org/conscrypt/")
        val viaConscrypt = runCatching {
            Class.forName("com.android.org.conscrypt.Conscrypt").getMethod("exportKeyingMaterial",
                SSLSocket::class.java, String::class.java, ByteArray::class.java, Int::class.javaPrimitiveType)
                .invoke(null, socket, label, null, length) as ByteArray
        }
        viaConscrypt.getOrNull()?.let { return it }
        var c: Class<*>? = socket.javaClass
        while (c != null) {
            val m = runCatching { c.getDeclaredMethod("exportKeyingMaterial", String::class.java, ByteArray::class.java,
                Int::class.javaPrimitiveType) }.getOrNull()
            if (m != null) { m.isAccessible = true; return m.invoke(socket, label, null, length) as ByteArray }
            c = c.superclass
        }
        throw javax.net.ssl.SSLException("TLS exporter not available", viaConscrypt.exceptionOrNull())
    }

    /** The shell line run as the shell user. Each result is echoed so that the log says which step failed. */
    internal fun grantCommand(pkg: String) =
        "cmd package grant $pkg android.permission.DUMP 2>&1; echo \"dump=\$?\"; " +
            "cmd appops set $pkg PROJECT_MEDIA allow 2>&1; echo \"project_media=\$?\""

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

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> begin()
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
        main.postDelayed(timeout, TIMEOUT_MS)
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
        val result = runCatching { AdbShell(ensureKey()).run(LOCALHOST, port, WirelessSetup.grantCommand(packageName)) }
        main.post {
            val f = flow ?: return@post
            result.onSuccess { out ->
                WirelessSetup.log("grants:\n$out")
                val ok = hasDumpPermission() && hasProjectMediaAppOp()
                detail = if (ok) null else out.trim()
                f.grantsDone(ok)
                finish(if (ok) null else out.trim())
            }.onFailure {
                WirelessSetup.log("connect failed", it)
                if (it is AdbShell.NotPairedException) { WirelessSetup.setPaired(this, false); detail = null; f.connectRefused() }
                else { detail = describe(it); f.connectFailed() }
                update()
            }
        }
    }

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
        val now = listOf(texts(), f.phase, f.note)
        if (now == shown) return
        shown = now
        runCatching { getSystemService(NotificationManager::class.java).notify(NOTIFICATION_ID, notification()) }
    }

    /** The text for the current state; also used by the app's setup card. */
    private fun texts(): Pair<String, String> {
        val f = flow ?: return getString(R.string.wsetup_notif_title) to ""
        return WirelessSetupTexts.title(this, f.phase, f.note) to WirelessSetupTexts.body(this, f.phase, f.note, detail)
    }

    private fun notification(): Notification {
        val nm = getSystemService(NotificationManager::class.java)
        // High importance: the code is typed while Settings is in front, so the notification has to pop up there.
        nm.createNotificationChannel(NotificationChannel(CHANNEL, getString(R.string.wsetup_channel), NotificationManager.IMPORTANCE_HIGH)
            .apply { setSound(null, null); enableVibration(false) })
        val (title, body) = texts()
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP), PendingIntent.FLAG_IMMUTABLE)
        val b = Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_notification).setColor(getColor(R.color.primary))
            .setContentTitle(title).setContentText(body).setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(open).setOnlyAlertOnce(true).setOngoing(true)
            .setCategory(Notification.CATEGORY_STATUS)
        val f = flow
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
        stopDiscovery()
        if (f != null && !cancelled) {
            detail = failureDetail ?: detail
            publish()
            val (title, body) = texts()
            val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
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
        if (WirelessSetup.running) WirelessSetup.publish(null)  // killed while running: the card offers Start again
        worker.shutdownNow()
        super.onDestroy()
    }

    companion object {
        const val ACTION_START = "org.islamicmute.app.wsetup.START"
        const val ACTION_CODE = "org.islamicmute.app.wsetup.CODE"
        const val ACTION_CANCEL = "org.islamicmute.app.wsetup.CANCEL"
        const val EXTRA_CODE = "code"
        private const val KEY_REMOTE_CODE = "pairing_code"
        private const val CHANNEL = "setup"
        private const val NOTIFICATION_ID = 21
        private const val RESULT_NOTIFICATION_ID = 22
        private const val LOCALHOST = "127.0.0.1"
        private const val TIMEOUT_MS = 10 * 60_000L
        private const val REFRESH_MS = 5_000L
    }
}

/** Words for each state, shared by the notification and the app's setup card. */
object WirelessSetupTexts {
    fun title(ctx: Context, phase: SetupFlow.Phase, note: SetupFlow.Note): String = ctx.getString(when (phase) {
        SetupFlow.Phase.DONE -> R.string.wsetup_done_title
        SetupFlow.Phase.FAILED -> R.string.wsetup_failed_title
        SetupFlow.Phase.PAIRING, SetupFlow.Phase.CONNECTING -> R.string.wsetup_busy_title
        SetupFlow.Phase.WAITING -> if (note == SetupFlow.Note.ENTER_CODE) R.string.wsetup_found_title else R.string.wsetup_notif_title
    })

    fun body(ctx: Context, phase: SetupFlow.Phase, note: SetupFlow.Note, detail: String?): String {
        val main = when (phase) {
            SetupFlow.Phase.DONE -> ctx.getString(if (FilterService.running) R.string.setup_done_restart else R.string.wsetup_done_body)
            SetupFlow.Phase.PAIRING -> ctx.getString(R.string.wsetup_pairing)
            SetupFlow.Phase.CONNECTING -> ctx.getString(R.string.wsetup_connecting)
            else -> ctx.getString(when (note) {
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
                SetupFlow.Note.GRANT_FAILED -> R.string.wsetup_grant_failed
                SetupFlow.Note.TIMEOUT -> R.string.wsetup_timeout
            })
        }
        return if (detail.isNullOrBlank()) main else main + "\n" + ctx.getString(R.string.wsetup_detail, detail)
    }
}
