package org.islamicmute.app

import android.app.Activity
import android.app.AlertDialog
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.ColorStateList
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.widget.Button
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.Switch
import android.widget.TextView
import rikka.shizuku.Shizuku

/**
 * Main screen: first-run question (man / woman), one large on/off control with its state in words, the one-time
 * setup as a numbered checklist (Shizuku, or a computer), and settings. Framework views and resources only.
 */
class MainActivity : Activity() {
    override fun attachBaseContext(base: android.content.Context) { super.attachBaseContext(Lang.wrap(base)) }

    private lateinit var settings: Settings
    private lateinit var power: ImageButton
    private lateinit var stateTitle: TextView
    private lateinit var stateDetail: TextView
    private lateinit var captureHint: TextView
    private lateinit var setupBanner: View
    private lateinit var setupCard: View
    private lateinit var setupMessage: TextView
    private lateinit var computerBox: View
    private lateinit var singingRow: View
    private lateinit var singingBody: TextView
    private lateinit var singing: Switch
    private lateinit var restartNote: TextView
    private lateinit var genderValue: TextView
    private lateinit var steps: List<View>
    private lateinit var blurStatus: TextView
    private lateinit var blurSetup: Button
    private lateinit var blurSetupManual: Button
    private lateinit var blurFail: Switch
    private lateinit var blurFailNote: TextView
    private var blurBusy = false
    private var blurMessage: String? = null
    /** Shizuku's permission dialog was opened from the blur card: grant the blur (not the setup) when it returns. */
    private var blurAfterPermission = false
    private var shizukuBusy = false
    private var shizukuMessage: String? = null
    /** Start was tapped but the microphone/notification permission request is still open. */
    private var startAfterPermission = false
    /** Notifications are asked at most once per screen: a refusal must not block or loop Start. */
    private var askedNotifications = false
    /** The microphone permission was refused at the last Start: keep saying why until the next tap. */
    private var micDenied = false

    private val serviceChanged: () -> Unit = { refresh() }
    private val shizukuChanged = Shizuku.OnBinderReceivedListener { runOnUiThread { refresh() } }
    private val shizukuDead = Shizuku.OnBinderDeadListener { runOnUiThread { refresh() } }
    private val shizukuPermission = Shizuku.OnRequestPermissionResultListener { code, result ->
        if (code != ShizukuSetup.REQUEST_CODE) return@OnRequestPermissionResultListener
        runOnUiThread {
            if (result == PackageManager.PERMISSION_GRANTED) { if (blurAfterPermission) grantBlur() else grantWithShizuku() }
            else { shizukuMessage = getString(R.string.shizuku_refused); refresh() }
            blurAfterPermission = false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        settings = Settings(this)
        setContentView(R.layout.activity_main)
        edgeToEdge()

        power = findViewById(R.id.power)
        stateTitle = findViewById(R.id.state_title)
        stateDetail = findViewById(R.id.state_detail)
        captureHint = findViewById(R.id.capture_hint)
        setupBanner = findViewById(R.id.setup_banner)
        setupCard = findViewById(R.id.setup_card)
        setupMessage = findViewById(R.id.setup_message)
        computerBox = findViewById(R.id.computer_box)
        singingRow = findViewById(R.id.singing_row)
        singingBody = findViewById(R.id.singing_body)
        singing = findViewById(R.id.switch_singing)
        restartNote = findViewById(R.id.restart_note)
        genderValue = findViewById(R.id.gender_value)
        steps = listOf(findViewById(R.id.step1), findViewById(R.id.step2), findViewById(R.id.step3))

        findViewById<Button>(R.id.choose_man).setOnClickListener { setGender("man") }
        findViewById<Button>(R.id.choose_woman).setOnClickListener { setGender("woman") }
        findViewById<Button>(R.id.change_gender).setOnClickListener { askGender() }
        findViewById<Button>(R.id.change_language).setOnClickListener { askLanguage() }
        findViewById<Button>(R.id.onboard_language).apply {
            val other = if (Lang.current(this@MainActivity) == Lang.AR) Lang.EN else Lang.AR
            text = getString(if (other == Lang.AR) R.string.language_ar else R.string.language_en)
            setOnClickListener { Lang.set(this@MainActivity, other) }
        }

        power.setOnClickListener { if (FilterService.running) stopFilter() else startFilter() }

        findViewById<Switch>(R.id.switch_silence).apply {
            isChecked = settings.silenceUnfilterable
            // Read by the running muter on every poll: applies at once, no restart needed.
            setOnCheckedChangeListener { _, v -> settings.silenceUnfilterable = v }
        }
        singing.isChecked = settings.muteWomenSinging
        singing.setOnCheckedChangeListener { _, v -> settings.muteWomenSinging = v; settingChanged() }

        val adb = "adb shell pm grant $packageName android.permission.DUMP\n" +
            "adb shell appops set $packageName PROJECT_MEDIA allow"
        findViewById<TextView>(R.id.adb_commands).text = adb
        val copy = findViewById<Button>(R.id.copy_adb)
        copy.setOnClickListener {
            getSystemService(ClipboardManager::class.java).setPrimaryClip(ClipData.newPlainText("adb", adb))
            copy.setText(R.string.copied)
            copy.postDelayed({ copy.setText(R.string.copy) }, 2000)
        }
        val computerToggle = findViewById<Button>(R.id.computer_toggle)
        computerToggle.setOnClickListener {
            val open = computerBox.visibility != View.VISIBLE
            computerBox.visibility = if (open) View.VISIBLE else View.GONE
            if (open) computerBox.post {
                val r = android.graphics.Rect(); computerBox.getDrawingRect(r); computerBox.requestRectangleOnScreen(r)
            }
        }
        blurStatus = findViewById(R.id.blur_status)
        blurSetup = findViewById(R.id.blur_setup)
        blurSetupManual = findViewById(R.id.blur_setup_manual)
        findViewById<Switch>(R.id.switch_blur_women).apply {
            isChecked = settings.blurWomen
            setOnCheckedChangeListener { _, v -> settings.blurWomen = v; blurChanged() }
        }
        findViewById<Switch>(R.id.switch_blur_nudity).apply {
            isChecked = settings.blurNudity
            setOnCheckedChangeListener { _, v -> settings.blurNudity = v; blurChanged() }
        }
        blurFail = findViewById(R.id.switch_blur_fail)
        blurFailNote = findViewById(R.id.blur_fail_note)
        // read by the running blur on every frame: applies at once. Greyed out in refreshBlur() when touches cannot
        // pass through the covers (a full-screen cover would then lock the phone).
        blurFail.setOnCheckedChangeListener { v, checked -> if (v.isEnabled) settings.blurFailCover = checked }
        blurSetup.setOnClickListener { onBlurSetup() }
        blurSetupManual.setOnClickListener {
            runCatching { startActivity(Intent(android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName"))) }
        }
        findViewById<Button>(R.id.open_link).setOnClickListener { startActivity(Intent(this, LinkActivity::class.java)) }
        findViewById<Button>(R.id.licences).setOnClickListener {
            startActivity(Intent(this, LicencesActivity::class.java))
        }

        FilterService.addListener(serviceChanged)
        ScreenBlur.addListener(serviceChanged)
        Shizuku.addBinderReceivedListenerSticky(shizukuChanged)
        Shizuku.addBinderDeadListener(shizukuDead)
        Shizuku.addRequestPermissionResultListener(shizukuPermission)
        refresh()
    }

    override fun onResume() { super.onResume(); refresh() }

    override fun onDestroy() {
        FilterService.removeListener(serviceChanged)
        ScreenBlur.removeListener(serviceChanged)
        Shizuku.removeBinderReceivedListener(shizukuChanged)
        Shizuku.removeBinderDeadListener(shizukuDead)
        Shizuku.removeRequestPermissionResultListener(shizukuPermission)
        super.onDestroy()
    }

    /** Draw behind the system bars (enforced from Android 15) and keep content clear of them. */
    private fun edgeToEdge() {
        if (Build.VERSION.SDK_INT >= 30) window.setDecorFitsSystemWindows(false)
        else @Suppress("DEPRECATION") {
            window.decorView.systemUiVisibility = window.decorView.systemUiVisibility or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        }
        // The scroll view stops below the status bar (scrolled text must not run under the clock); the content
        // itself scrolls under the transparent navigation bar and ends with padding above it.
        val scroll = findViewById<View>(R.id.scroll)
        val content = findViewById<View>(R.id.content)
        val dp = resources.displayMetrics.density
        val start = content.paddingStart
        val end = content.paddingEnd
        scroll.setOnApplyWindowInsetsListener { v, insets ->
            val bars = if (Build.VERSION.SDK_INT >= 30)
                insets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
            else @Suppress("DEPRECATION") android.graphics.Insets.of(
                insets.systemWindowInsetLeft, insets.systemWindowInsetTop, insets.systemWindowInsetRight, insets.systemWindowInsetBottom)
            val rtl = v.layoutDirection == View.LAYOUT_DIRECTION_RTL
            v.setPadding(0, bars.top, 0, 0)
            content.setPaddingRelative(start + if (rtl) bars.right else bars.left, (24 * dp).toInt(),
                end + if (rtl) bars.left else bars.right, bars.bottom + (32 * dp).toInt())
            insets
        }
    }

    private fun refresh() {
        if (isDestroyed) return
        val hasGender = settings.gender.isNotEmpty()
        findViewById<View>(R.id.onboarding).visibility = if (hasGender) View.GONE else View.VISIBLE
        findViewById<View>(R.id.main).visibility = if (hasGender) View.VISIBLE else View.GONE
        if (!hasGender) return

        // State: shown by the control's fill AND in words.
        val st = FilterService.state
        val on = FilterService.running
        power.isActivated = on
        power.imageTintList = ColorStateList.valueOf(getColor(if (on) R.color.on_primary else R.color.text_primary))
        power.contentDescription = getString(if (on) R.string.power_stop_cd else R.string.power_start_cd)
        stateTitle.setText(when (st) {
            FilterService.State.STARTING -> R.string.state_starting
            FilterService.State.FILTERING, FilterService.State.MODEL_FAILED -> R.string.state_on_title
            else -> R.string.state_off_title
        })
        stateDetail.text = when (st) {
            FilterService.State.FILTERING -> getString(R.string.state_on_detail, FilterService.delayMs)
            FilterService.State.MODEL_FAILED -> getString(R.string.state_model_failed)
            FilterService.State.NO_CAPTURE_PERMISSION -> getString(R.string.state_capture_denied)
            FilterService.State.STOPPED_BY_SYSTEM -> getString(R.string.state_stopped_by_system)
            FilterService.State.STARTING -> ""
            FilterService.State.STOPPED -> getString(R.string.state_off_detail)
        }
        stateDetail.setTextColor(getColor(
            if (st == FilterService.State.MODEL_FAILED || st == FilterService.State.NO_CAPTURE_PERMISSION) R.color.error
            else R.color.text_secondary))
        if (micDenied && !on) {
            stateDetail.setText(R.string.need_record_audio)
            stateDetail.setTextColor(getColor(R.color.error))
        }

        val dumpOk = hasDumpPermission()
        val projectOk = hasProjectMediaAppOp()
        captureHint.visibility = if (!on && !projectOk) View.VISIBLE else View.GONE
        setupBanner.visibility = if (dumpOk) View.GONE else View.VISIBLE
        setupCard.visibility = if (dumpOk && projectOk) View.GONE else View.VISIBLE
        refreshSteps(dumpOk)

        // Settings
        val man = settings.gender == "man"
        singingRow.visibility = if (man) View.VISIBLE else View.GONE
        singingBody.setText(if (settings.muteWomenSinging && !ModelStore.hasDetector(this))
            R.string.setting_singing_no_model else R.string.setting_singing_body)
        singingBody.setTextColor(getColor(if (settings.muteWomenSinging && !ModelStore.hasDetector(this))
            R.color.error else R.color.text_secondary))
        if (!on) restartNote.visibility = View.GONE
        refreshBlur(on)
        findViewById<TextView>(R.id.language_value).text = getString(R.string.setting_language_title, getString(
            if (Lang.current(this) == Lang.AR) R.string.language_ar else R.string.language_en))
        genderValue.text = getString(R.string.setting_gender_title) + ": " +
            getString(if (man) R.string.gender_man else R.string.gender_woman)
    }

    /** Screen-blur card: what it needs, and its state while filtering runs. */
    private fun refreshBlur(on: Boolean) {
        val a11y = blurAccessibilityEnabled()
        val overlay = android.provider.Settings.canDrawOverlays(this)
        // builds without the accessibility service (the default: Play Protect blocks it) need the overlay permission
        // Shizuku running (Android 12+): the covers are a shell layer, nothing else to allow
        val shizukuLayer = Build.VERSION.SDK_INT >= 31 && ShizukuSetup.state(this) == ShizukuSetup.State.READY
        val needsSetup = settings.blurOn && !shizukuLayer && (if (BuildConfig.BLUR_A11Y) !a11y else !overlay)
        blurSetup.visibility = if (needsSetup) View.VISIBLE else View.GONE
        blurSetup.isEnabled = !blurBusy
        blurSetupManual.visibility = if (needsSetup && !overlay) View.VISIBLE else View.GONE
        val passThrough = blurTouchPassThrough()
        blurFail.isEnabled = passThrough  // before isChecked: the listener ignores changes while disabled
        blurFail.isChecked = passThrough && settings.blurFailCover
        blurFailNote.visibility = if (passThrough) View.GONE else View.VISIBLE
        blurFailNote.setText(if (BuildConfig.BLUR_A11Y) R.string.blur_fail_needs_a11y else R.string.blur_fail_unavailable)
        val bs = ScreenBlur.state
        val setupText = if (BuildConfig.BLUR_A11Y) R.string.blur_status_needs_setup else R.string.blur_status_needs_overlay
        val msg: Pair<String, Boolean>? = when {
            blurMessage != null -> blurMessage!! to true
            !settings.blurOn -> null
            needsSetup && !overlay -> getString(setupText) to true
            !on -> if (needsSetup) getString(setupText) to false else null
            bs == null -> getString(R.string.blur_status_starting) to false // applied within half a second
            bs == ScreenBlur.State.STARTING -> getString(R.string.blur_status_starting) to false
            bs == ScreenBlur.State.ON -> getString(R.string.blur_status_on) to false
            bs == ScreenBlur.State.ON_COVERS_VISIBLE -> getString(R.string.blur_status_on_visible) to false
            bs == ScreenBlur.State.MODELS_MISSING -> getString(R.string.blur_status_models) to true
            bs == ScreenBlur.State.FAILING -> getString(R.string.blur_status_failing) to true
            else -> getString(R.string.blur_status_no_overlay) to true
        }
        blurStatus.visibility = if (msg == null) View.GONE else View.VISIBLE
        msg?.let { (text, bad) ->
            blurStatus.text = text
            blurStatus.setTextColor(getColor(if (bad) R.color.error else R.color.text_secondary))
        }
    }

    private fun blurChanged() {
        blurMessage = null
        refresh()
    }

    private fun onBlurSetup() {
        blurMessage = null
        when (ShizukuSetup.state(this)) {
            ShizukuSetup.State.READY -> grantBlur()
            ShizukuSetup.State.NEEDS_PERMISSION -> {
                blurAfterPermission = true
                runCatching { ShizukuSetup.requestPermission() }.onFailure { blurAfterPermission = false }
            }
            ShizukuSetup.State.NOT_INSTALLED, ShizukuSetup.State.TOO_OLD -> openStore()
            else -> packageManager.getLaunchIntentForPackage(ShizukuSetup.SHIZUKU_PACKAGE)?.let { startActivity(it) }
        }
    }

    private fun grantBlur() {
        blurAfterPermission = false
        if (blurBusy) return
        blurBusy = true
        refresh()
        ShizukuSetup.grantBlur(this) { log ->
            if (isDestroyed) return@grantBlur
            blurBusy = false
            blurMessage = if (blurAccessibilityEnabled() || android.provider.Settings.canDrawOverlays(this)) null
                          else getString(R.string.blur_setup_failed, log)
            refresh()
        }
    }

    /** The three Shizuku steps: done ones get a check, the current one gets its action button. */
    private fun refreshSteps(dumpOk: Boolean) {
        val s = ShizukuSetup.state(this)
        val installed = s != ShizukuSetup.State.NOT_INSTALLED
        val running = installed && s != ShizukuSetup.State.NOT_RUNNING && s != ShizukuSetup.State.TOO_OLD
        val done = listOf(installed, running, dumpOk)
        val current = done.indexOfFirst { !it }
        val tooOld = s == ShizukuSetup.State.TOO_OLD
        val denied = s == ShizukuSetup.State.DENIED_PERMANENTLY
        val content = listOf(
            Triple(R.string.step1_title, R.string.step1_body, R.string.step1_action),
            Triple(R.string.step2_title, if (tooOld) R.string.step2_too_old else R.string.step2_body,
                if (tooOld) R.string.step2_update else R.string.step2_action),
            Triple(R.string.step3_title, if (denied) R.string.step2_denied else R.string.step3_body,
                when { denied -> R.string.step2_action; shizukuBusy -> R.string.step3_busy; else -> R.string.step3_action }))
        for ((i, row) in steps.withIndex()) {
            val (title, body, action) = content[i]
            row.findViewById<TextView>(R.id.step_title).setText(title)
            row.findViewById<TextView>(R.id.step_body).setText(body)
            row.findViewById<View>(R.id.step_badge).isActivated = done[i]
            row.findViewById<ImageView>(R.id.step_check).visibility = if (done[i]) View.VISIBLE else View.GONE
            row.findViewById<TextView>(R.id.step_number).apply {
                text = (i + 1).toString()
                visibility = if (done[i]) View.GONE else View.VISIBLE
            }
            row.contentDescription = null
            row.findViewById<TextView>(R.id.step_title).contentDescription =
                (if (done[i]) getString(R.string.step_done_cd) else getString(R.string.step_todo_cd, i + 1)) +
                    ". " + getString(title)
            val btn = row.findViewById<Button>(R.id.step_action)
            btn.visibility = if (i == current) View.VISIBLE else View.GONE
            btn.setText(action)
            btn.isEnabled = !(i == 2 && shizukuBusy)
            btn.setOnClickListener { onStepAction(i) }
        }
        setupMessage.text = shizukuMessage ?: ""
        setupMessage.visibility = if (shizukuMessage == null) View.GONE else View.VISIBLE
    }

    private fun onStepAction(step: Int) {
        shizukuMessage = null
        val s = ShizukuSetup.state(this)
        when {
            step == 0 -> openStore()
            step == 1 && s == ShizukuSetup.State.TOO_OLD -> openStore()
            s == ShizukuSetup.State.READY -> grantWithShizuku()
            s == ShizukuSetup.State.NEEDS_PERMISSION -> runCatching { ShizukuSetup.requestPermission() }
                .onFailure { shizukuMessage = "Shizuku: ${it.message}"; refresh() }
            else -> packageManager.getLaunchIntentForPackage(ShizukuSetup.SHIZUKU_PACKAGE)?.let { startActivity(it) }
                ?: refresh()
        }
    }

    private fun openStore() {
        val pkg = ShizukuSetup.SHIZUKU_PACKAGE
        val market = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$pkg"))
        val web = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$pkg"))
        runCatching { startActivity(market) }.onFailure { runCatching { startActivity(web) } }
    }

    private fun grantWithShizuku() {
        if (shizukuBusy) return
        shizukuBusy = true
        refresh()
        ShizukuSetup.grant(this) { log ->
            if (isDestroyed) return@grant
            shizukuBusy = false
            shizukuMessage = when {
                !hasDumpPermission() -> getString(R.string.setup_failed, log)
                FilterService.running -> getString(R.string.setup_done_restart)
                else -> null
            }
            refresh()
        }
    }

    private fun setGender(g: String) {
        settings.gender = g
        refresh()
        findViewById<View>(R.id.scroll).scrollTo(0, 0)
    }

    private fun askLanguage() {
        val tags = arrayOf(Lang.AR, Lang.EN)
        val names = arrayOf(getString(R.string.language_ar), getString(R.string.language_en))
        AlertDialog.Builder(this)
            .setTitle(R.string.language_title)
            .setSingleChoiceItems(names, tags.indexOf(Lang.current(this))) { d, which ->
                d.dismiss()
                if (tags[which] != Lang.current(this)) Lang.set(this, tags[which])
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private fun askGender() {
        val choices = arrayOf(getString(R.string.gender_man), getString(R.string.gender_woman))
        val checked = if (settings.gender == "man") 0 else 1
        AlertDialog.Builder(this)
            .setTitle(R.string.setting_gender_title)
            .setSingleChoiceItems(choices, checked) { d, which ->
                settings.gender = if (which == 0) "man" else "woman"
                d.dismiss(); settingChanged()
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    /** The running filter and blur follow the settings within half a second: no restart needed. */
    private fun settingChanged() = refresh()

    private fun startFilter() {
        micDenied = false
        // Ask for the runtime permissions only now, when their purpose is clear (capture needs RECORD_AUDIO).
        // Only RECORD_AUDIO gates Start; the notification permission is optional and asked once.
        val wanted = buildList {
            if (checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED)
                add(android.Manifest.permission.RECORD_AUDIO)
            if (Build.VERSION.SDK_INT >= 33 && !askedNotifications &&
                checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED)
                add(android.Manifest.permission.POST_NOTIFICATIONS)
        }
        if (Build.VERSION.SDK_INT >= 33 && android.Manifest.permission.POST_NOTIFICATIONS in wanted) askedNotifications = true
        if (wanted.isNotEmpty()) {
            // Android's dialog says "record audio": say first why, and that nothing is recorded.
            if (android.Manifest.permission.RECORD_AUDIO in wanted) stateDetail.setText(R.string.need_record_audio)
            startAfterPermission = true
            requestPermissions(wanted.toTypedArray(), REQ_PERMISSIONS)
            return
        }
        val mpm = getSystemService(MediaProjectionManager::class.java)
        // Android 14+ offers "a single app" first; a system-wide filter needs the whole device, so ask for that only.
        val intent = if (Build.VERSION.SDK_INT >= 34)
            mpm.createScreenCaptureIntent(android.media.projection.MediaProjectionConfig.createConfigForDefaultDisplay())
        else mpm.createScreenCaptureIntent()
        startActivityForResult(intent, REQ_CAPTURE)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQ_PERMISSIONS || !startAfterPermission) return
        startAfterPermission = false
        if (checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) startFilter()
        else { micDenied = true; refresh() }
    }

    private fun stopFilter() {
        startService(Intent(this, FilterService::class.java).setAction(FilterService.ACTION_STOP))
    }

    @Deprecated("framework Activity API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_CAPTURE && resultCode == RESULT_OK && data != null) {
            startForegroundService(Intent(this, FilterService::class.java)
                .putExtra(FilterService.EXTRA_CODE, resultCode).putExtra(FilterService.EXTRA_DATA, data))
        }
    }

    private companion object {
        const val REQ_PERMISSIONS = 1
        const val REQ_CAPTURE = 7
    }
}
