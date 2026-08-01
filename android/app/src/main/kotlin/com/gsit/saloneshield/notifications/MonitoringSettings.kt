package com.gsit.saloneshield.notifications

import android.content.Context

/**
 * Reads the user's monitoring choices from the same store the Flutter settings
 * screen writes to.
 *
 * The service asks this on every notification rather than caching, so turning
 * monitoring off in the app takes effect on the very next message instead of
 * whenever the service happens to restart. Reading a boolean from an already
 * open shared-preferences map costs nothing worth optimising away.
 *
 * Keys carry the `flutter.` prefix because that is how the shared_preferences
 * plugin namespaces them; the names after the prefix match
 * `PreferencesService` in Dart.
 */
class MonitoringSettings(private val context: Context) {

    private val preferences
        get() = context.getSharedPreferences(FLUTTER_PREFERENCES, Context.MODE_PRIVATE)

    /**
     * The master switch. Defaults to off: notification access can be granted
     * in Android's settings without the user ever having agreed to it inside
     * the app, and that grant on its own must not start monitoring.
     */
    val isEnabled: Boolean
        get() = preferences.getBoolean(KEY_ENABLED, false)

    /**
     * The apps the user chose. An empty set means none — again the safe
     * reading, because it is what a user who has enabled nothing looks like.
     */
    val monitoredPackages: Set<String>
        get() = SupportedApps.all.filterTo(mutableSetOf()) { packageName ->
            preferences.getBoolean(perAppKey(packageName), false)
        }

    private companion object {
        const val FLUTTER_PREFERENCES = "FlutterSharedPreferences"
        const val KEY_ENABLED = "flutter.notifications.monitoring_enabled"

        fun perAppKey(packageName: String) = "flutter.notifications.app.$packageName"
    }
}
