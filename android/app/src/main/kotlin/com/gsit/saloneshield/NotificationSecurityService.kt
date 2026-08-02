package com.gsit.saloneshield

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.gsit.saloneshield.notifications.InterruptFilter
import com.gsit.saloneshield.notifications.MonitoringSettings
import com.gsit.saloneshield.notifications.NotificationCandidate
import com.gsit.saloneshield.notifications.NotificationGuard
import com.gsit.saloneshield.notifications.NotificationInbox
import io.flutter.FlutterInjector
import java.io.InputStreamReader

/**
 * Watches messaging notifications so a scam can be caught as it arrives
 * (specification section 14).
 *
 * What this service does **not** do is as much of its design as what it does:
 *
 * - It reads notifications from the messaging apps the user ticked, and no
 *   others. A one-time code from a bank, an e-mail, an authenticator app —
 *   none of those packages can be on the list, so none are ever read.
 * - It keeps text in memory only, in a small queue that empties itself after
 *   fifteen minutes. Nothing is written to disk and nothing is uploaded.
 * - It never puts message text in a notification of its own. The warning it
 *   posts says only that something arrived worth checking.
 * - It does not use an Accessibility Service, and it cannot read anything
 *   inside WhatsApp: a notification is all it sees, which is also all the user
 *   sees on their lock screen.
 *
 * The scoring, the explanation and the advice all happen in Dart, on the same
 * engine the paste-and-check flow uses. This service only decides whether the
 * user should be told now or the next time they open the app.
 */
class NotificationSecurityService : NotificationListenerService() {

    private val settings by lazy { MonitoringSettings(applicationContext) }
    private val interruptFilter by lazy { loadInterruptFilter() }
    private var guard: NotificationGuard? = null
    private var guardPackages: Set<String> = emptySet()

    override fun onListenerDisconnected() {
        // Android has taken the connection away, usually because access was
        // revoked. Anything held becomes unreachable rather than stale.
        NotificationInbox.clear()
        super.onListenerDisconnected()
    }

    override fun onNotificationPosted(notification: StatusBarNotification?) {
        val posted = notification ?: return
        if (!settings.isEnabled) return

        val monitored = settings.monitoredPackages
        if (monitored.isEmpty()) return
        if (posted.packageName !in monitored) return

        val candidate = describe(posted) ?: return
        val verdict = guardFor(monitored).inspect(candidate)
        if (verdict !is NotificationGuard.Verdict.Accepted) return

        val entry = NotificationInbox.create(
            packageName = candidate.packageName,
            text = verdict.text,
            nowMillis = candidate.postedAtMillis,
            interrupt = verdict.interrupt,
        )

        // With the app in front of the user it says so on screen rather than
        // adding to their notification shade. An entry taken this way is
        // deliberately not queued: the next drain would otherwise hand the app
        // a second copy of a message it has already shown.
        if (NotificationInbox.deliverToDart(entry)) return

        NotificationInbox.enqueue(entry)
        if (verdict.interrupt) postCheckPrompt()
    }

    /** The guard is rebuilt only when the user's app selection changes. */
    private fun guardFor(monitored: Set<String>): NotificationGuard {
        val existing = guard
        if (existing != null && guardPackages == monitored) return existing
        val created = NotificationGuard(
            monitoredPackages = monitored,
            interruptFilter = interruptFilter,
        )
        guard = created
        guardPackages = monitored
        return created
    }

    /**
     * Pulls out the message text and nothing else.
     *
     * Sender names, avatars, conversation ids and reply actions are all
     * available on the notification and all deliberately left behind.
     */
    private fun describe(posted: StatusBarNotification): NotificationCandidate? {
        val notification = posted.notification ?: return null
        val extras = notification.extras ?: return null
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()

        return NotificationCandidate(
            packageName = posted.packageName,
            text = text,
            postedAtMillis = posted.postTime.takeIf { it > 0 } ?: System.currentTimeMillis(),
            isOngoing = posted.isOngoing,
            isGroupSummary = (notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0,
            isFromSelf = extras.getBoolean(EXTRA_IS_FROM_SELF, false),
        )
    }

    /**
     * A prompt with no content in it.
     *
     * Putting the suspicious text in this notification would be the one place
     * the app leaks a message back onto a lock screen, so the warning says
     * only that there is something to check.
     */
    private fun postCheckPrompt() {
        val manager = NotificationManagerCompat.from(this)
        if (!manager.areNotificationsEnabled()) return

        ensureChannel()

        val open = PendingIntent.getActivity(
            this,
            REQUEST_OPEN_APP,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val warning = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(getString(R.string.notification_check_title))
            .setContentText(getString(R.string.notification_check_body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(open)
            .build()

        try {
            manager.notify(NOTIFICATION_ID, warning)
        } catch (error: SecurityException) {
            // POST_NOTIFICATIONS was refused. The message still waits in the
            // inbox for the next time the app is opened.
        }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = getString(R.string.notification_channel_description)
                setShowBadge(false)
            },
        )
    }

    /**
     * Reads the interrupt patterns out of the same rules asset Dart analyses
     * with, so the two can never disagree about what counts as decisive.
     */
    private fun loadInterruptFilter(): InterruptFilter {
        // The service can be running with no Flutter engine in the process, so
        // the loader may not be initialised. The conventional asset path is
        // tried as well rather than giving up on the first failure. Throwable,
        // not Exception: an uninitialised loader asserts rather than throws.
        for (key in assetKeys()) {
            try {
                return assets.open(key).use { stream ->
                    InterruptFilter.fromRulesJson(InputStreamReader(stream).readText())
                }
            } catch (error: Throwable) {
                continue
            }
        }
        // Without patterns the service still queues messages for the app; it
        // simply stops interrupting, which is the harmless direction to fail.
        return InterruptFilter.silent
    }

    private fun assetKeys(): List<String> {
        val fromLoader = try {
            FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(RULES_ASSET)
        } catch (error: Throwable) {
            null
        }
        return listOfNotNull(fromLoader, "flutter_assets/$RULES_ASSET").distinct()
    }

    private companion object {
        const val CHANNEL_ID = "salone_shield_checks"
        const val NOTIFICATION_ID = 4201
        const val REQUEST_OPEN_APP = 4202
        const val RULES_ASSET = "assets/scam_rules/initial_rules.json"

        /** Set by messaging apps on the user's own outgoing messages. */
        const val EXTRA_IS_FROM_SELF = "android.isFromSelf"
    }
}
