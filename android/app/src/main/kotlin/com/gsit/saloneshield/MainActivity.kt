package com.gsit.saloneshield

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The whole of the native surface: text shared into the app, and the system
 * contact picker.
 *
 * The activity reads only [Intent.EXTRA_TEXT] from a share the user performed
 * deliberately, and only the single contact row the system picker hands back.
 * It never reads another application's data, notifications or accessibility
 * events, declares no contacts permission, and stores nothing: values are
 * passed to Dart and forgotten.
 */
class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null

    /** Text from a share that arrived before Dart was ready to receive it. */
    private var pendingSharedText: String? = null

    private val contactPicker by lazy { ContactPickerDelegate(this) }

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
                    METHOD_PICK_CONTACT -> contactPicker.pick(result)
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

    @Deprecated("Required while the app targets the classic activity result API.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (contactPicker.onActivityResult(requestCode, resultCode, data)) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        contactPicker.dispose()
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
        const val METHOD_PICK_CONTACT = "pickContact"
        const val MIME_PLAIN_TEXT = "text/plain"
    }
}
