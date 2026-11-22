package org.waaiya.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Main screen: the shared Flutter screens (../ui through ../ui_module). Launched through the ".MainActivity" alias
 * (AndroidManifest.xml). Everything system-level stays native and is reached through [UiBridge].
 */
class UiActivity : FlutterActivity() {
    private var bridge: UiBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = UiBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        takePage(intent)
    }

    /** Shows the page an intent asks for, once: the extra is removed so a recreated screen does not jump again. */
    private fun takePage(i: Intent?) {
        val page = i?.getStringExtra(EXTRA_PAGE) ?: return
        i.removeExtra(EXTRA_PAGE)
        bridge?.requestPage(page)
    }

    /** Opened again with a page to show (a Quick Settings tile's "Open Waaiya"). */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        takePage(intent)
    }

    companion object {
        /** The launcher entry (the ".MainActivity" alias of this activity), for notifications. */
        fun main(ctx: android.content.Context): Intent = Intent().setClassName(ctx, "${ctx.packageName}.MainActivity")

        /** Page to show: `setup`, `filter`, `screen` (docs/UI_CONTRACT.md `navigate`). */
        const val EXTRA_PAGE = "org.waaiya.app.PAGE"

        /** The launcher entry with a page to open. */
        fun open(ctx: android.content.Context, page: String): Intent? =
            ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)?.putExtra(EXTRA_PAGE, page)
                // an open Waaiya gets it in onNewIntent instead of a second screen
                ?.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        bridge?.dispose()
        bridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /** Permissions can change in another app (Shizuku, Android settings) without a callback. */
    override fun onResume() {
        super.onResume()
        bridge?.onResume()
    }

    override fun onPause() {
        bridge?.onPause()
        super.onPause()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        bridge?.onRequestPermissionsResult(requestCode)
    }

    @Deprecated("framework Activity API")
    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        bridge?.onActivityResult(requestCode, resultCode, data)
    }
}
