package com.gsit.saloneshield.notifications

/**
 * Decides what happens to a notification the listener sees.
 *
 * This class holds no Android types on purpose: every rule about what Salone
 * Shield is allowed to look at lives here, in something that can be run and
 * argued with on a JVM. The service (see NotificationSecurityService) does the
 * plumbing and nothing else.
 *
 * The default posture is to ignore. A notification has to earn its way past
 * every check below before a single character of it is kept in memory.
 */
class NotificationGuard(
    private val monitoredPackages: Set<String>,
    private val interruptFilter: InterruptFilter,
    private val digestWindowMillis: Long = DEFAULT_DIGEST_WINDOW_MILLIS,
    private val maxTextLength: Int = MAX_TEXT_LENGTH,
) {

    /** What the guard saw, described without quoting it. */
    sealed interface Verdict {
        /** Dropped. [reason] exists for the developer log, never for a user. */
        data class Ignored(val reason: String) : Verdict

        /**
         * Worth handing to the analyser. [interrupt] is true when the text
         * tripped a high-signal pattern and the user should be told now rather
         * than the next time they open the app.
         */
        data class Accepted(val text: String, val interrupt: Boolean) : Verdict
    }

    /** Hashes, not text: enough to spot a repeat, useless to anyone reading it. */
    private val recentDigests = LinkedHashMap<Int, Long>()

    fun inspect(candidate: NotificationCandidate): Verdict {
        // An app the user did not put on the list is not looked at at all.
        // This is also what keeps one-time-code notifications from banks,
        // e-mail clients and authenticators out: they are never on the list.
        if (candidate.packageName !in monitoredPackages) {
            return Verdict.Ignored("package not monitored")
        }

        // Ongoing notifications are calls, backups and media controls.
        // Summaries are "5 new messages", which carry no message to analyse.
        if (candidate.isOngoing) return Verdict.Ignored("ongoing")
        if (candidate.isGroupSummary) return Verdict.Ignored("group summary")

        val text = candidate.text?.trim().orEmpty()
        if (text.isEmpty()) return Verdict.Ignored("no text")

        // A notification the user themselves triggered by sending a message.
        if (candidate.isFromSelf) return Verdict.Ignored("own message")

        val digest = text.hashCode()
        val now = candidate.postedAtMillis
        prune(now)
        if (recentDigests.containsKey(digest)) {
            return Verdict.Ignored("repeat")
        }
        recentDigests[digest] = now

        // WhatsApp re-posts a notification as a conversation grows, so the
        // text can be long. The analyser caps its own input; capping here as
        // well keeps the amount held in memory small and predictable.
        val trimmed = if (text.length > maxTextLength) text.take(maxTextLength) else text

        return Verdict.Accepted(
            text = trimmed,
            interrupt = interruptFilter.isWorthInterrupting(trimmed),
        )
    }

    /** Drops digests older than the window so the map cannot grow without end. */
    private fun prune(now: Long) {
        val iterator = recentDigests.entries.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (now - entry.value > digestWindowMillis) iterator.remove() else break
        }
        while (recentDigests.size > MAX_DIGESTS) {
            val oldest = recentDigests.keys.firstOrNull() ?: break
            recentDigests.remove(oldest)
        }
    }

    companion object {
        /** Two of the same message inside this window is a repost, not news. */
        const val DEFAULT_DIGEST_WINDOW_MILLIS = 60_000L

        const val MAX_DIGESTS = 40

        /** Matches the analyser's own input cap in spirit, smaller in size. */
        const val MAX_TEXT_LENGTH = 4_000
    }
}

/**
 * A notification, reduced to the few fields the guard is allowed to consider.
 *
 * Nothing here identifies a person: no sender name, no avatar, no thread id.
 */
data class NotificationCandidate(
    val packageName: String,
    val text: String?,
    val postedAtMillis: Long,
    val isOngoing: Boolean = false,
    val isGroupSummary: Boolean = false,
    val isFromSelf: Boolean = false,
)

/** The messaging apps Salone Shield knows how to read. */
object SupportedApps {
    const val WHATSAPP = "com.whatsapp"
    const val WHATSAPP_BUSINESS = "com.whatsapp.w4b"

    val all: Set<String> = setOf(WHATSAPP, WHATSAPP_BUSINESS)
}
