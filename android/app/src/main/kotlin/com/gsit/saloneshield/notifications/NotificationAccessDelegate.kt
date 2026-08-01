package com.gsit.saloneshield.notifications

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * The Dart-facing half of notification monitoring.
 *
 * Three things cross this boundary and nothing else: whether Android has
 * granted notification access, a way to open the settings page where the user
 * grants it, and the messages the listener has queued. The app cannot grant
 * itself access — the most it can do is take the user to the screen where they
 * decide.
 */
class NotificationAccessDelegate(private val activity: Activity) {

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    fun attach(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, METHOD_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    METHOD_IS_GRANTED -> result.success(isAccessGranted())
                    METHOD_OPEN_SETTINGS -> result.success(openSettings())
                    METHOD_DRAIN -> result.success(
                        NotificationInbox.drain(System.currentTimeMillis())
                            .map { it.toMap() },
                    )
                    METHOD_CLEAR -> {
                        NotificationInbox.clear()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        eventChannel = EventChannel(messenger, EVENT_CHANNEL).apply {
            setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        if (events == null) return
                        NotificationInbox.setListener { entry ->
                            // The sink is not thread-safe and the listener
                            // fires on the service's thread.
                            activity.runOnUiThread { events.success(entry.toMap()) }
                        }
                    }

                    override fun onCancel(arguments: Any?) {
                        NotificationInbox.setListener(null)
                    }
                },
            )
        }
    }

    fun detach() {
        NotificationInbox.setListener(null)
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
    }

    /**
     * Asks Android, not the app's own settings: this is the grant the user
     * made in the system, which they can withdraw there at any time without
     * telling Salone Shield.
     */
    fun isAccessGranted(): Boolean {
        val enabled = Settings.Secure.getString(
            activity.contentResolver,
            SETTING_ENABLED_LISTENERS,
        ) ?: return false
        val expected = ComponentName(activity, SERVICE_CLASS)
        return enabled.split(':').any { entry ->
            val component = ComponentName.unflattenFromString(entry)
            component == expected
        }
    }

    private fun openSettings(): Boolean {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        return try {
            activity.startActivity(intent)
            true
        } catch (error: Exception) {
            // Some builds ship without the settings screen. Saying so lets the
            // app explain the situation rather than appearing to do nothing.
            false
        }
    }

    private companion object {
        const val METHOD_CHANNEL = "com.gsit.saloneshield/notification_access"
        const val EVENT_CHANNEL = "com.gsit.saloneshield/notification_events"
        const val METHOD_IS_GRANTED = "isAccessGranted"
        const val METHOD_OPEN_SETTINGS = "openAccessSettings"
        const val METHOD_DRAIN = "drainPending"
        const val METHOD_CLEAR = "clearPending"
        const val SETTING_ENABLED_LISTENERS = "enabled_notification_listeners"
        const val SERVICE_CLASS = "com.gsit.saloneshield.NotificationSecurityService"
    }
}
