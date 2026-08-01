package com.gsit.saloneshield.notifications

/**
 * The only place a monitored message is ever held, and it is held in memory.
 *
 * Nothing here is written to disk, a database, a log or a notification. The
 * queue is small and short-lived: if the user does not open the app within the
 * retention window, the text is gone and the app has forgotten it existed.
 * Killing the process has the same effect, which is the intended design rather
 * than a limitation.
 */
object NotificationInbox {

    /** A message waiting for the analyser. */
    data class Entry(
        val id: Long,
        val packageName: String,
        val text: String,
        val receivedAtMillis: Long,
        val interrupt: Boolean,
    ) {
        fun toMap(): Map<String, Any> = mapOf(
            "id" to id,
            "package" to packageName,
            "text" to text,
            "received_at" to receivedAtMillis,
            "interrupt" to interrupt,
        )
    }

    /** Beyond this the oldest is dropped: a backlog is not worth keeping. */
    const val MAX_ENTRIES = 20

    /** Unread text is discarded after this long, whatever happens. */
    const val RETENTION_MILLIS = 15 * 60 * 1000L

    private val entries = ArrayDeque<Entry>()
    private var nextId = 1L

    /** Set while Dart is listening; null when the app is not running. */
    @Volatile
    private var listener: ((Entry) -> Unit)? = null

    val isDartListening: Boolean get() = listener != null

    @Synchronized
    fun add(packageName: String, text: String, nowMillis: Long, interrupt: Boolean): Entry {
        prune(nowMillis)
        val entry = Entry(nextId++, packageName, text, nowMillis, interrupt)
        entries.addLast(entry)
        while (entries.size > MAX_ENTRIES) entries.removeFirst()
        return entry
    }

    /** Hands over everything waiting and empties the queue in one step. */
    @Synchronized
    fun drain(nowMillis: Long): List<Entry> {
        prune(nowMillis)
        val pending = entries.toList()
        entries.clear()
        return pending
    }

    @Synchronized
    fun clear() {
        entries.clear()
    }

    @Synchronized
    fun size(nowMillis: Long): Int {
        prune(nowMillis)
        return entries.size
    }

    fun setListener(listener: ((Entry) -> Unit)?) {
        this.listener = listener
    }

    /** True when Dart took the entry, so it does not also need queueing. */
    fun deliverToDart(entry: Entry): Boolean {
        val target = listener ?: return false
        target(entry)
        return true
    }

    private fun prune(nowMillis: Long) {
        while (entries.isNotEmpty() &&
            nowMillis - entries.first().receivedAtMillis > RETENTION_MILLIS
        ) {
            entries.removeFirst()
        }
    }
}
