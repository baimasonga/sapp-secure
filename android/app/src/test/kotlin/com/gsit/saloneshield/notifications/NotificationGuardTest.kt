package com.gsit.saloneshield.notifications

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * What the guard refuses to look at matters more than what it accepts, so most
 * of these tests are about the refusals.
 */
class NotificationGuardTest {

    private fun guard(
        packages: Set<String> = SupportedApps.all,
        filter: InterruptFilter = InterruptFilter.silent,
    ) = NotificationGuard(monitoredPackages = packages, interruptFilter = filter)

    private fun candidate(
        packageName: String = SupportedApps.WHATSAPP,
        text: String? = "hello",
        at: Long = 1_000,
        ongoing: Boolean = false,
        summary: Boolean = false,
        fromSelf: Boolean = false,
    ) = NotificationCandidate(packageName, text, at, ongoing, summary, fromSelf)

    private fun reasonFor(verdict: NotificationGuard.Verdict): String =
        (verdict as NotificationGuard.Verdict.Ignored).reason

    @Test
    fun `a monitored messaging notification is accepted`() {
        val verdict = guard().inspect(candidate(text = "  send me money  "))
        val accepted = verdict as NotificationGuard.Verdict.Accepted
        assertEquals("send me money", accepted.text)
        assertFalse(accepted.interrupt)
    }

    @Test
    fun `a notification from an app the user did not choose is never read`() {
        // This is the check that keeps one-time codes out: a bank, an e-mail
        // client or an authenticator can never be in the monitored set.
        val verdict = guard(packages = setOf(SupportedApps.WHATSAPP))
            .inspect(candidate(packageName = "com.example.bank", text = "Your code is 918273"))
        assertEquals("package not monitored", reasonFor(verdict))
    }

    @Test
    fun `an empty monitored set reads nothing at all`() {
        val verdict = guard(packages = emptySet()).inspect(candidate())
        assertEquals("package not monitored", reasonFor(verdict))
    }

    @Test
    fun `ongoing notifications and group summaries are skipped`() {
        assertEquals("ongoing", reasonFor(guard().inspect(candidate(ongoing = true))))
        assertEquals("group summary", reasonFor(guard().inspect(candidate(summary = true))))
    }

    @Test
    fun `a notification with no text is skipped`() {
        assertEquals("no text", reasonFor(guard().inspect(candidate(text = null))))
        assertEquals("no text", reasonFor(guard().inspect(candidate(text = "   "))))
    }

    @Test
    fun `the user's own outgoing message is skipped`() {
        assertEquals("own message", reasonFor(guard().inspect(candidate(fromSelf = true))))
    }

    @Test
    fun `the same text reposted is only accepted once`() {
        val subject = guard()
        assertTrue(subject.inspect(candidate(at = 1_000)) is NotificationGuard.Verdict.Accepted)
        val second = subject.inspect(candidate(at = 1_500))
        assertEquals("repeat", reasonFor(second))
    }

    @Test
    fun `the same text much later is treated as new`() {
        val subject = guard()
        subject.inspect(candidate(at = 1_000))
        val later = subject.inspect(
            candidate(at = 1_000 + NotificationGuard.DEFAULT_DIGEST_WINDOW_MILLIS + 1),
        )
        assertTrue(later is NotificationGuard.Verdict.Accepted)
    }

    @Test
    fun `long text is capped`() {
        val long = "a".repeat(NotificationGuard.MAX_TEXT_LENGTH + 500)
        val accepted = guard().inspect(candidate(text = long))
            as NotificationGuard.Verdict.Accepted
        assertEquals(NotificationGuard.MAX_TEXT_LENGTH, accepted.text.length)
    }

    @Test
    fun `an interrupt-worthy message is flagged for a warning`() {
        val filter = InterruptFilter(listOf(PatternMatcher("send me the code")))
        val accepted = guard(filter = filter)
            .inspect(candidate(text = "Please send me the code I just sent you"))
            as NotificationGuard.Verdict.Accepted
        assertTrue(accepted.interrupt)
    }
}
