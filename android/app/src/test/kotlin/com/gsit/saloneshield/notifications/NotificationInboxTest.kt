package com.gsit.saloneshield.notifications

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * The inbox is the only place a monitored message is held, so the properties
 * that matter here are about forgetting rather than remembering: nothing
 * outlives the window, nothing grows without bound, and nothing is handed to
 * the app twice.
 */
class NotificationInboxTest {

    private val now = 1_700_000_000_000L

    @Before
    @After
    fun reset() {
        NotificationInbox.setListener(null)
        NotificationInbox.clear()
    }

    private fun add(text: String, at: Long = now, interrupt: Boolean = false) {
        NotificationInbox.enqueue(
            NotificationInbox.create(SupportedApps.WHATSAPP, text, at, interrupt),
        )
    }

    @Test
    fun `a delivered entry is not also queued`() {
        // The defect this guards against: an entry handed to a listening app
        // that stays in the queue as well, so the next drain shows the user
        // the same message a second time.
        val seen = mutableListOf<String>()
        NotificationInbox.setListener { entry ->
            seen.add(entry.text)
            true
        }

        val entry = NotificationInbox.create(SupportedApps.WHATSAPP, "send the code", now, true)
        val taken = NotificationInbox.deliverToDart(entry)
        if (!taken) NotificationInbox.enqueue(entry)

        assertTrue(taken)
        assertEquals(listOf("send the code"), seen)
        assertEquals(0, NotificationInbox.size(now))
    }

    @Test
    fun `a declining listener leaves the entry to be queued`() {
        // What a backgrounded app looks like: registered, but not in front of
        // the user, so the message must wait and the service must interrupt.
        NotificationInbox.setListener { false }

        val entry = NotificationInbox.create(SupportedApps.WHATSAPP, "send the code", now, true)
        val taken = NotificationInbox.deliverToDart(entry)
        if (!taken) NotificationInbox.enqueue(entry)

        assertFalse(taken)
        assertEquals(1, NotificationInbox.size(now))
    }

    @Test
    fun `no listener means the entry waits`() {
        val entry = NotificationInbox.create(SupportedApps.WHATSAPP, "hello", now, false)
        assertFalse(NotificationInbox.deliverToDart(entry))
    }

    @Test
    fun `entries carry distinct ids`() {
        // The app dismisses by id, so a collision would make one message
        // remove another.
        val first = NotificationInbox.create(SupportedApps.WHATSAPP, "one", now, false)
        val second = NotificationInbox.create(SupportedApps.WHATSAPP, "two", now, false)
        assertTrue(first.id != second.id)
    }

    @Test
    fun `draining empties the queue`() {
        add("one")
        add("two")

        assertEquals(2, NotificationInbox.drain(now).size)
        assertEquals(0, NotificationInbox.size(now))
    }

    @Test
    fun `text older than the retention window is forgotten`() {
        add("old", at = now)
        val later = now + NotificationInbox.RETENTION_MILLIS + 1

        assertEquals(0, NotificationInbox.size(later))
        assertTrue(NotificationInbox.drain(later).isEmpty())
    }

    @Test
    fun `the queue is capped and drops the oldest`() {
        for (index in 1..NotificationInbox.MAX_ENTRIES + 5) {
            add("message $index")
        }

        val pending = NotificationInbox.drain(now)
        assertEquals(NotificationInbox.MAX_ENTRIES, pending.size)
        assertEquals("message 6", pending.first().text)
    }

    @Test
    fun `clearing forgets everything`() {
        add("something")
        NotificationInbox.clear()
        assertEquals(0, NotificationInbox.size(now))
    }
}
