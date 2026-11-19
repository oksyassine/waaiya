package org.islamicmute.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.WindowInsets
import android.widget.Button
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/**
 * The on-phone setup (Wireless debugging, [WirelessSetup]) step by step, each step with a screenshot, like
 * Shizuku's own guide (https://shizuku.rikka.app/guide/setup/). The pictures were taken on an Android 15 emulator,
 * in each language of the app (drawable-nodpi = English, drawable-<language>-nodpi; android/tools/guide_shots.py); menus look a little different on each phone, so the
 * last section says what to look for, with the notes for Xiaomi and OPPO-family phones ([SetupHelp]).
 */
class SetupGuideActivity : Activity() {
    override fun attachBaseContext(base: android.content.Context) { super.attachBaseContext(Lang.wrap(base)) }

    private val steps = listOf(
        R.string.guide_w_1 to R.drawable.guide_1_about,
        R.string.guide_w_2 to R.drawable.guide_5_start,
        R.string.guide_w_3 to R.drawable.guide_2_dev,
        R.string.guide_w_4 to R.drawable.guide_3_allow,
        R.string.guide_w_5 to R.drawable.guide_4_pair,
        R.string.guide_w_6 to R.drawable.guide_6_code,
        R.string.guide_w_7 to R.drawable.guide_7_notif,
        R.string.guide_w_8 to R.drawable.guide_8_reply,
        R.string.guide_w_9 to R.drawable.guide_9_done,
    )

    companion object {
        const val SHIZUKU_GUIDE = "https://shizuku.rikka.app/guide/setup/"

        /** The pictures by name, for the Flutter setup steps (UiBridge "guidePicture"). */
        val PICTURES = mapOf(
            "guide_1_about" to R.drawable.guide_1_about, "guide_2_dev" to R.drawable.guide_2_dev,
            "guide_3_allow" to R.drawable.guide_3_allow, "guide_4_pair" to R.drawable.guide_4_pair,
            "guide_5_start" to R.drawable.guide_5_start, "guide_6_code" to R.drawable.guide_6_code,
            "guide_7_notif" to R.drawable.guide_7_notif, "guide_8_reply" to R.drawable.guide_8_reply,
            "guide_9_done" to R.drawable.guide_9_done,
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 30) window.setDecorFitsSystemWindows(false)  // as LicencesActivity
        val dp = resources.displayMetrics.density
        fun px(v: Int) = (v * dp).toInt()

        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setBackgroundColor(getColor(R.color.bg)) }
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL
            setPaddingRelative(px(4), px(4), px(16), px(4))
        }
        header.addView(ImageButton(this).apply {
            setImageResource(R.drawable.ic_arrow_back)
            setBackgroundResource(R.drawable.bg_button_text)
            contentDescription = getString(R.string.back)
            setOnClickListener { finish() }
        }, LinearLayout.LayoutParams(px(48), px(48)))
        header.addView(TextView(this, null, 0, R.style.Text_Headline).apply {
            setText(R.string.guide_w_title); setPaddingRelative(px(8), 0, 0, 0); isAccessibilityHeading = true
        }, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        root.addView(header)

        val list = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(px(20), px(8), px(20), px(32)) }
        fun text(res: Int, style: Int = R.style.Text_Body, top: Int = 0) = TextView(this, null, 0, style).apply {
            setText(res); textAlignment = TextView.TEXT_ALIGNMENT_VIEW_START
        }.also { list.addView(it, LinearLayout.LayoutParams(-1, -2).apply { topMargin = px(top) }) }

        text(R.string.guide_w_intro, R.style.Text_Secondary)
        SetupHelp.noteRes()?.let { note ->  // this phone's own switch first (Xiaomi, OPPO family)
            text(note).apply {
                setBackgroundResource(R.drawable.bg_warning); setPadding(px(12), px(12), px(12), px(12))
                setTextColor(getColor(R.color.on_warning_container))
            }.also { (it.layoutParams as LinearLayout.LayoutParams).topMargin = px(16) }
        }
        for ((i, step) in steps.withIndex()) {
            val (words, picture) = step
            text(words, top = 24).text = getString(R.string.guide_w_step, i + 1, getString(words))
            list.addView(ImageView(this).apply {
                setImageResource(picture)
                adjustViewBounds = true
                scaleType = ImageView.ScaleType.FIT_START
                setBackgroundResource(R.drawable.bg_card)
                setPadding(px(1), px(1), px(1), px(1))
                clipToOutline = true
                importantForAccessibility = ImageView.IMPORTANT_FOR_ACCESSIBILITY_NO  // the text says it all
            }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = px(10) })
        }

        if (Build.VERSION.SDK_INT >= 31) text(R.string.guide_w_helper_note, R.style.Text_Secondary, top = 16)

        text(R.string.guide_w_trouble_title, R.style.Text_Section, top = 32).isAccessibilityHeading = true
        text(R.string.guide_w_trouble, R.style.Text_Secondary, top = 8)
        text(R.string.setup_note_xiaomi, R.style.Text_Secondary, top = 12)

        text(R.string.guide_w_shizuku_title, R.style.Text_Section, top = 32).isAccessibilityHeading = true
        text(R.string.guide_w_shizuku, R.style.Text_Secondary, top = 8)
        list.addView(Button(this, null, 0, R.style.Button_Tonal).apply {
            setText(R.string.guide_w_shizuku_open)
            gravity = Gravity.CENTER
            setPadding(px(20), px(10), px(20), px(10))
            setOnClickListener {
                runCatching { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(SHIZUKU_GUIDE))) }
            }
        }, LinearLayout.LayoutParams(-2, -2).apply { topMargin = px(12) })

        root.addView(ScrollView(this).apply { addView(list) }, LinearLayout.LayoutParams(-1, 0, 1f))
        root.setOnApplyWindowInsetsListener { v, insets ->
            val bars = if (Build.VERSION.SDK_INT >= 30)
                insets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
            else @Suppress("DEPRECATION") android.graphics.Insets.of(insets.systemWindowInsetLeft,
                insets.systemWindowInsetTop, insets.systemWindowInsetRight, insets.systemWindowInsetBottom)
            v.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            insets
        }
        setContentView(root)
    }

}
