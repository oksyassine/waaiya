package org.islamicmute.app

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.CheckBox
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.ScrollView
import android.widget.TextView
import rikka.shizuku.Shizuku

/** Onboarding (man / woman), options, start/stop, and setup help. Plain framework views, no extra libraries. */
class MainActivity : Activity() {
    private lateinit var settings: Settings
    private lateinit var status: TextView
    private lateinit var toggle: Button
    private lateinit var singing: CheckBox
    private lateinit var setup: LinearLayout
    private lateinit var shizukuInfo: TextView
    private lateinit var shizukuButton: Button
    private var shizukuBusy = false
    private var shizukuMessage: String? = null

    private val shizukuChanged = Shizuku.OnBinderReceivedListener { runOnUiThread { refresh() } }
    private val shizukuDead = Shizuku.OnBinderDeadListener { runOnUiThread { refresh() } }
    private val shizukuPermission = Shizuku.OnRequestPermissionResultListener { code, result ->
        if (code != ShizukuSetup.REQUEST_CODE) return@OnRequestPermissionResultListener
        runOnUiThread {
            if (result == PackageManager.PERMISSION_GRANTED) grantWithShizuku()
            else { shizukuMessage = "Shizuku permission was refused."; refresh() }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        settings = Settings(this)
        if (Build.VERSION.SDK_INT >= 33) requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS, android.Manifest.permission.RECORD_AUDIO), 1)
        else requestPermissions(arrayOf(android.Manifest.permission.RECORD_AUDIO), 1)

        val pad = (16 * resources.displayMetrics.density).toInt()
        val col = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(pad, pad, pad, pad) }
        fun text(s: String, size: Float = 16f) = TextView(this).apply { text = s; textSize = size; setPadding(0, pad / 2, 0, pad / 2) }

        col.addView(text("Islamic Mute", 24f))
        col.addView(text("Removes musical instruments from the sound of every app and keeps the voice: speech, recitation and singing."))

        col.addView(text("I am", 18f))
        val group = RadioGroup(this).apply { orientation = RadioGroup.HORIZONTAL }
        val man = RadioButton(this).apply { text = "a man"; id = View.generateViewId() }
        val woman = RadioButton(this).apply { text = "a woman"; id = View.generateViewId() }
        group.addView(man); group.addView(woman)
        when (settings.gender) { "man" -> man.isChecked = true; "woman" -> woman.isChecked = true }
        col.addView(group)

        singing = CheckBox(this).apply {
            text = "Also mute women's singing (keeps women's speech and recitation)"
            isChecked = settings.muteWomenSinging
            setOnCheckedChangeListener { _, v -> settings.muteWomenSinging = v }
        }
        col.addView(singing)
        group.setOnCheckedChangeListener { _, checked ->
            settings.gender = if (checked == man.id) "man" else "woman"
            refresh()
        }

        col.addView(CheckBox(this).apply {
            text = "Silence apps that block filtering (recommended: never hear unfiltered music)"
            isChecked = settings.silenceUnfilterable
            setOnCheckedChangeListener { _, v -> settings.silenceUnfilterable = v }
        })

        toggle = Button(this).apply { setOnClickListener { if (FilterService.running) stopFilter() else startFilter() } }
        col.addView(toggle)
        status = text("")
        col.addView(status)

        col.addView(text("Videos shared to Islamic Mute (\"Share\" or \"Open with\") play in perfect lip-sync.", 14f))

        // One-time setup: DUMP (mute the originals) + PROJECT_MEDIA (no screen-capture question). Shizuku or ADB.
        setup = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        setup.addView(text("One-time setup so the original sound is muted (otherwise you hear both)", 18f))
        shizukuInfo = text("", 14f)
        setup.addView(shizukuInfo)
        shizukuButton = Button(this).apply { setOnClickListener { onShizukuButton() } }
        setup.addView(shizukuButton)
        setup.addView(text("Or connect the phone to a computer with USB debugging and run:", 14f))
        setup.addView(text("adb shell pm grant $packageName android.permission.DUMP\n" +
            "adb shell appops set $packageName PROJECT_MEDIA allow", 14f).apply { setTextIsSelectable(true); gravity = Gravity.START })
        setup.addView(text("(The second line is optional: it stops Android asking for screen-capture permission at every start.)", 12f))
        col.addView(setup)

        col.addView(Button(this).apply {
            text = "Open-source licences"
            setOnClickListener { startActivity(Intent(this@MainActivity, LicencesActivity::class.java)) }
        })

        setContentView(ScrollView(this).apply { addView(col) })
        Shizuku.addBinderReceivedListenerSticky(shizukuChanged)
        Shizuku.addBinderDeadListener(shizukuDead)
        Shizuku.addRequestPermissionResultListener(shizukuPermission)
        refresh()
    }

    override fun onResume() { super.onResume(); refresh() }

    override fun onDestroy() {
        Shizuku.removeBinderReceivedListener(shizukuChanged)
        Shizuku.removeBinderDeadListener(shizukuDead)
        Shizuku.removeRequestPermissionResultListener(shizukuPermission)
        super.onDestroy()
    }

    private fun refresh() {
        singing.visibility = if (settings.gender == "man") View.VISIBLE else View.GONE
        toggle.text = if (FilterService.running) "Stop filtering" else "Start filtering"
        val dumpOk = hasDumpPermission()
        val projectOk = hasProjectMediaAppOp()
        val dump = if (dumpOk) "original sound muting: ready" else "original sound muting: NOT set up (see below)"
        val project = if (projectOk) "screen-capture question: skipped" else "screen-capture question: asked at every start"
        status.text = "Status: ${FilterService.status}\n$dump\n$project" +
            if (settings.muteWomenSinging && settings.gender == "man") {
                if (ModelStore.hasDetector(this)) "\nWomen's singing filter: on" + (if (FilterService.running) " (restart filtering to apply changes)" else "")
                else "\nWomen's singing filter: this build has no detector model, so all voice is muted while it is on (fail-closed)"
            } else ""
        setup.visibility = if (dumpOk && projectOk) View.GONE else View.VISIBLE
        refreshShizuku()
    }

    private fun refreshShizuku() {
        val state = ShizukuSetup.state(this)
        val (info, button) = when (state) {
            ShizukuSetup.State.NOT_INSTALLED ->
                "Without a computer: install the Shizuku app, start it (it explains how, with wireless debugging), then come back here." to null
            ShizukuSetup.State.NOT_RUNNING ->
                "Shizuku is installed but not running. Open it, start it, then come back here." to "Open Shizuku"
            ShizukuSetup.State.TOO_OLD ->
                "Your Shizuku version is too old. Please update it." to "Open Shizuku"
            ShizukuSetup.State.DENIED_PERMANENTLY ->
                "Shizuku was told to always deny Islamic Mute. In Shizuku, open the list of authorized apps and allow Islamic Mute." to "Open Shizuku"
            ShizukuSetup.State.NEEDS_PERMISSION, ShizukuSetup.State.READY ->
                "Shizuku is running: set everything up with one tap." to "Grant with Shizuku"
        }
        shizukuInfo.text = listOfNotNull(info, shizukuMessage).joinToString("\n")
        shizukuButton.text = if (shizukuBusy) "Setting up..." else button ?: ""
        shizukuButton.isEnabled = !shizukuBusy
        shizukuButton.visibility = if (button == null) View.GONE else View.VISIBLE
    }

    private fun onShizukuButton() {
        shizukuMessage = null
        when (ShizukuSetup.state(this)) {
            ShizukuSetup.State.READY -> grantWithShizuku()
            ShizukuSetup.State.NEEDS_PERMISSION -> runCatching { ShizukuSetup.requestPermission() }
                .onFailure { shizukuMessage = "Shizuku: ${it.message}"; refresh() }
            else -> {
                val launch = packageManager.getLaunchIntentForPackage(ShizukuSetup.SHIZUKU_PACKAGE)
                if (launch != null) startActivity(launch) else refresh()
            }
        }
    }

    private fun grantWithShizuku() {
        if (shizukuBusy) return
        shizukuBusy = true
        refresh()
        ShizukuSetup.grant(this) { log ->
            if (isDestroyed) return@grant
            shizukuBusy = false
            shizukuMessage = when {
                !hasDumpPermission() -> "Setup failed. Details:\n$log"
                FilterService.running -> "Done. Stop and start filtering once to mute the original sound."
                else -> null
            }
            refresh()
        }
    }

    private fun startFilter() {
        if (settings.gender.isEmpty()) { status.text = "Please choose man or woman first."; return }
        val mpm = getSystemService(MediaProjectionManager::class.java)
        startActivityForResult(mpm.createScreenCaptureIntent(), 7)
    }

    private fun stopFilter() {
        startService(Intent(this, FilterService::class.java).setAction(FilterService.ACTION_STOP))
        toggle.postDelayed({ refresh() }, 500)
    }

    @Deprecated("framework Activity API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 7 && resultCode == RESULT_OK && data != null) {
            startForegroundService(Intent(this, FilterService::class.java)
                .putExtra(FilterService.EXTRA_CODE, resultCode).putExtra(FilterService.EXTRA_DATA, data))
            toggle.postDelayed({ refresh() }, 800)
        }
    }
}
