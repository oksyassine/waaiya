package org.islamicmute.app

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
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        bridge?.dispose()
        bridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /** Permissions can change in another app (Shizuku, Android settings) without a callback. */
    override fun onResume() {
        super.onResume()
        bridge?.refresh()
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
