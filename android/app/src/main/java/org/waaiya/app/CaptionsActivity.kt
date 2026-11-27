package org.waaiya.app

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.CheckBox
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/**
 * Live captions (docs/CAPTIONS.md): the microphone's Arabic speech as large right-to-left text that scrolls as it
 * grows, the line being spoken shown dimmer until it is finished. Listens only while this screen is open and in front;
 * the screen stays on meanwhile. Font size, colours and "Remove background sounds first" are kept between visits.
 */
class CaptionsActivity : Activity() {
    override fun attachBaseContext(base: Context) { super.attachBaseContext(Lang.wrap(base)) }

    private companion object {
        const val REQ_MIC = 41
        const val PREFS = "captions"
    }

    private val main = Handler(Looper.getMainLooper())
    private lateinit var scroll: ScrollView
    private lateinit var text: TextView
    private lateinit var status: TextView
    private lateinit var pause: Button
    private lateinit var root: LinearLayout
    private lateinit var note: TextView
    private lateinit var clean: CheckBox
    private var listener: Captions.Listener? = null
    private var lines: List<String> = emptyList()
    private var partial = ""
    private var sp = CaptionsText.DEFAULT_SP
    private var scheme = 0
    private var paused = false
    private var slow = false
    private var problem: Int? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val prefs = getSharedPreferences(PREFS, MODE_PRIVATE)
        sp = prefs.getInt("sp", CaptionsText.DEFAULT_SP).coerceIn(CaptionsText.MIN_SP, CaptionsText.MAX_SP)
        scheme = prefs.getInt("scheme", 0).coerceIn(0, CaptionsText.SCHEMES.size - 1)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)  // read from across the room for a whole khutba
        val d = resources.displayMetrics.density
        fun px(v: Int) = (v * d).toInt()

        root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        // edge to edge on every version (Android 15+ forces it): the content kept clear of the bars, as MusicCheckActivity
        if (Build.VERSION.SDK_INT >= 30) window.setDecorFitsSystemWindows(false)
        root.setOnApplyWindowInsetsListener { v, insets ->
            val b = if (Build.VERSION.SDK_INT >= 30)
                insets.getInsets(android.view.WindowInsets.Type.systemBars() or android.view.WindowInsets.Type.displayCutout())
            else @Suppress("DEPRECATION") android.graphics.Insets.of(insets.systemWindowInsetLeft,
                insets.systemWindowInsetTop, insets.systemWindowInsetRight, insets.systemWindowInsetBottom)
            v.setPadding(b.left, b.top, b.right, b.bottom)
            insets
        }
        status = TextView(this).apply {
            textSize = 15f
            setPadding(px(16), px(10), px(16), px(4))
            textDirection = View.TEXT_DIRECTION_LOCALE
        }
        root.addView(status, LinearLayout.LayoutParams(-1, -2))
        text = TextView(this).apply {
            // the captions are Arabic whatever the app's language: right to left, right aligned
            textDirection = View.TEXT_DIRECTION_RTL
            textAlignment = View.TEXT_ALIGNMENT_VIEW_START
            layoutDirection = View.LAYOUT_DIRECTION_RTL
            setTypeface(typeface, Typeface.BOLD)
            setLineSpacing(0f, 1.25f)
            setPadding(px(16), px(8), px(16), px(24))
            setTextIsSelectable(false)
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES
        }
        scroll = ScrollView(this).apply { isFillViewport = true; addView(text, -1, -2) }
        root.addView(scroll, LinearLayout.LayoutParams(-1, 0, 1f))

        val themed = android.view.ContextThemeWrapper(this, android.R.style.Theme_DeviceDefault)
        fun bar() = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(px(8), px(2), px(8), px(2))
        }
        fun button(parent: LinearLayout, label: Int, onClick: () -> Unit) = Button(themed).apply {
            setText(label)
            isAllCaps = false
            setOnClickListener { onClick() }
            parent.addView(this, LinearLayout.LayoutParams(0, -2, 1f).apply { marginStart = px(3); marginEnd = px(3) })
        }
        val row1 = bar()
        pause = button(row1, R.string.captions_pause) { setPaused(!paused) }
        button(row1, R.string.captions_clear) { lines = emptyList(); partial = ""; listener?.clear(); render() }
        val row2 = bar()
        button(row2, R.string.captions_smaller) { setSize(CaptionsText.smaller(sp)) }
        button(row2, R.string.captions_bigger) { setSize(CaptionsText.bigger(sp)) }
        button(row2, R.string.captions_colours) {
            scheme = CaptionsText.nextScheme(scheme)
            prefs.edit().putInt("scheme", scheme).apply()
            colours()
        }
        clean = CheckBox(themed).apply {
            setText(R.string.captions_clean)
            isChecked = prefs.getBoolean("clean", true)
            setPadding(px(4), px(4), px(4), px(4))
            setOnCheckedChangeListener { _, on ->
                prefs.edit().putBoolean("clean", on).apply()
                listener?.clean = on
            }
        }
        note = TextView(this).apply {
            text = getString(R.string.captions_note)
            textSize = 13f
            setPadding(px(16), px(2), px(16), px(8))
        }
        root.addView(row1, LinearLayout.LayoutParams(-1, -2))
        root.addView(row2, LinearLayout.LayoutParams(-1, -2))
        root.addView(clean, LinearLayout.LayoutParams(-2, -2).apply { marginStart = px(12) })
        root.addView(note, LinearLayout.LayoutParams(-1, -2))
        setContentView(root)
        setSize(sp)
        colours()
        render()
        if (checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED)
            requestPermissions(arrayOf(android.Manifest.permission.RECORD_AUDIO), REQ_MIC)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQ_MIC) return
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) startListening()
        else { problem = R.string.captions_no_mic; render() }
    }

    // listens only while the screen is in front: nothing is heard once the user leaves it
    override fun onStart() {
        super.onStart()
        if (checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) startListening()
    }

    override fun onStop() {
        stopListening()
        super.onStop()
    }

    private fun startListening() {
        if (listener != null) return
        problem = null
        val app = applicationContext
        val clean = getSharedPreferences(PREFS, MODE_PRIVATE).getBoolean("clean", true)
        // the model is copied out of the APK on the listening thread: it is large, the screen must not wait on it
        listener = Captions.Listener(app, { ModelStore.captionsPath(app) }, clean, { u -> main.post { onUpdate(u) } },
            { p -> main.post { onProblem(p) } }).also { it.paused = paused; it.start() }
        render()
    }

    private fun stopListening() {
        val l = listener ?: return
        listener = null
        // the last line may still be recognised: closing waits for it off the main thread
        Thread({ l.close() }, "im-captions-stop").start()
    }

    private fun onUpdate(u: Captions.Listener.Update) {
        if (isFinishing || isDestroyed) return
        val atEnd = !scroll.canScrollVertically(1)
        lines = CaptionsText.append(lines, u.finals)
        partial = u.partial
        slow = u.slow
        render()
        // follow the speaker, unless the user scrolled back to read an earlier line
        if (atEnd) scroll.post { scroll.fullScroll(View.FOCUS_DOWN) }
    }

    private fun onProblem(p: Captions.Listener.Problem) {
        if (isFinishing || isDestroyed) return
        problem = when (p) {
            Captions.Listener.Problem.NO_MODEL -> R.string.captions_card_missing
            Captions.Listener.Problem.NO_MIC -> R.string.captions_no_mic
            Captions.Listener.Problem.FAILED -> R.string.captions_failed
        }
        stopListening()
        render()
    }

    private fun setPaused(on: Boolean) {
        paused = on
        listener?.paused = on
        if (on) partial = ""
        render()
    }

    private fun setSize(v: Int) {
        sp = v
        getSharedPreferences(PREFS, MODE_PRIVATE).edit().putInt("sp", sp).apply()
        text.setTextSize(TypedValue.COMPLEX_UNIT_SP, sp.toFloat())
    }

    private fun colours() {
        val (fg, bg) = CaptionsText.SCHEMES[scheme]
        root.setBackgroundColor(bg)
        scroll.setBackgroundColor(bg)
        text.setTextColor(fg)
        status.setTextColor(fg)
        note.setTextColor(fg)
        clean.setTextColor(fg)
        clean.buttonTintList = android.content.res.ColorStateList.valueOf(fg)
        render()
    }

    private fun render() {
        if (!::text.isInitialized) return
        val (fg, _) = CaptionsText.SCHEMES[scheme]
        val sb = SpannableStringBuilder()
        if (lines.isEmpty() && partial.isEmpty()) {
            sb.append(getString(R.string.captions_hint))
            sb.setSpan(ForegroundColorSpan(dim(fg)), 0, sb.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        } else {
            for (l in lines) { if (sb.isNotEmpty()) sb.append("\n"); sb.append(l) }
            if (partial.isNotEmpty()) {
                if (sb.isNotEmpty()) sb.append("\n")
                val at = sb.length
                sb.append(partial)
                sb.setSpan(ForegroundColorSpan(dim(fg)), at, sb.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
        }
        text.text = sb
        status.text = when {
            problem != null -> getString(problem!!)
            paused -> getString(R.string.captions_paused)
            slow -> getString(R.string.captions_slow)
            else -> getString(R.string.captions_listening)
        }
        pause.setText(if (paused) R.string.captions_resume else R.string.captions_pause)
    }

    /** The colour at 60%: the line still being spoken. */
    private fun dim(c: Int): Int = (c and 0x00FFFFFF) or (0x99 shl 24)
}
