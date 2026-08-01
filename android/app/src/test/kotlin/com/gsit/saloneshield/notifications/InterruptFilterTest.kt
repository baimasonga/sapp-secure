package com.gsit.saloneshield.notifications

import java.io.File
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The filter is loaded from the same rules file the Dart analyser uses, so
 * these tests read the real asset rather than a fixture. If a pattern is
 * removed from the rules, the corresponding test here fails — which is the
 * point: the two must not drift.
 */
class InterruptFilterTest {

    private val rulesJson: String =
        File("../../assets/scam_rules/initial_rules.json").readText()

    private val filter = InterruptFilter.fromRulesJson(rulesJson)

    @Test
    fun `a verification-code request is worth interrupting`() {
        assertTrue(filter.isWorthInterrupting("Please send me the code I just sent you"))
    }

    @Test
    fun `a QR-code request is worth interrupting`() {
        assertTrue(filter.isWorthInterrupting("Scan this QR code to confirm your account"))
    }

    @Test
    fun `an ordinary message is not worth interrupting`() {
        assertFalse(filter.isWorthInterrupting("Good morning, see you at church"))
    }

    @Test
    fun `a merely suspicious message is left for the app to explain`() {
        // "Send money" is a signal, not a decision: it scores, but on its own
        // it does not earn a notification.
        assertFalse(filter.isWorthInterrupting("Please send money for transport"))
    }

    @Test
    fun `invisible characters do not hide a pattern`() {
        assertTrue(filter.isWorthInterrupting("send me the c​ode now"))
    }

    @Test
    fun `a pattern only matches on word boundaries`() {
        // The same rule the Dart matcher follows: "send the code" must not
        // fire on "send the coded file", or the warning becomes noise.
        assertFalse(filter.isWorthInterrupting("Please send the coded file when you can"))
        assertTrue(filter.isWorthInterrupting("Please send the code when you can"))
    }

    @Test
    fun `a broken rules file interrupts nobody`() {
        assertFalse(InterruptFilter.fromRulesJson("{not json").isWorthInterrupting("send the code"))
        assertFalse(InterruptFilter.fromRulesJson("{}").isWorthInterrupting("send the code"))
    }
}
