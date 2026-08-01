package com.gsit.saloneshield

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Receives text shared into Salone Shield from WhatsApp or any other app.
 *
 * This is the whole of the native surface. The activity reads only
 * [Intent.EXTRA_TEXT] from a share the user performed deliberately. It never
 * reads another application's data, notifications or accessibility events, and
 * it stores nothing: the text is handed to Dart and forgotten.
 */
class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null

    /** Text from a share that arrived before Dart was ready to receive it. */
    private var pendingSharedText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        pendingSharedText = extractSharedText(intent)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    METHOD_GET_SHARED_TEXT -> {
                        // Consumed once, so coming back to the app later does
                        // not resurrect a message already dealt with.
                        result.success(pendingSharedText)
                        pendingSharedText = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val sharedText = extractSharedText(intent) ?: return
        val activeChannel = channel
        if (activeChannel == null) {
            pendingSharedText = sharedText
        } else {
            activeChannel.invokeMethod(METHOD_ON_SHARED_TEXT, sharedText)
        }
    }

    override fun onDestroy() {
        channel?.setMethodCallHandler(null)
        channel = null
        pendingSharedText = null
        super.onDestroy()
    }

    private fun extractSharedText(intent: Intent?): String? {
        if (intent == null) return null
        if (intent.action != Intent.ACTION_SEND) return null
        if (intent.type != MIME_PLAIN_TEXT) return null
        return intent.getStringExtra(Intent.EXTRA_TEXT)?.takeIf { it.isNotBlank() }
    }

    private companion object {
        const val CHANNEL = "com.gsit.saloneshield/shared_text"
        const val METHOD_GET_SHARED_TEXT = "getSharedText"
        const val METHOD_ON_SHARED_TEXT = "onSharedText"
        const val MIME_PLAIN_TEXT = "text/plain"
    }
}
