package com.gsit.saloneshield.notifications

import org.json.JSONArray
import org.json.JSONObject

/**
 * Decides whether a message is worth interrupting the user for.
 *
 * This is deliberately *not* a second scam engine. Scoring, escalation floors,
 * explanations and advice all stay in one place, in Dart, and the user is only
 * ever shown a verdict that engine produced. All this does is answer a much
 * smaller question — "is this worth a tap on the shoulder right now?" — for the
 * case where the app is not open and Dart is not running.
 *
 * It reads its patterns from the same `initial_rules.json` the analyser uses,
 * so the two cannot drift apart: a pattern deleted from the rules file stops
 * interrupting people in the same commit. Only rules at or above
 * [INTERRUPT_WEIGHT] qualify, which is the difference between "worth telling
 * you about when you next open the app" and "worth a notification".
 */
class InterruptFilter(private val matchers: List<PatternMatcher>) {

    fun isWorthInterrupting(text: String): Boolean {
        if (matchers.isEmpty()) return false
        val normalised = TextNormaliser.normalise(text)
        return matchers.any { it.matches(normalised) }
    }

    companion object {
        /**
         * The bar for an interruption. Rules at this weight are the ones the
         * specification treats as decisive on their own — a verification-code
         * request, a demand for a mobile-money PIN — rather than the ones that
         * only mean something in combination.
         */
        const val INTERRUPT_WEIGHT = 30

        /** An empty filter interrupts nobody, which is the safe failure. */
        val silent = InterruptFilter(emptyList())

        /**
         * Builds a filter from the rules asset. A malformed or missing file
         * yields [silent]: failing to warn is bad, but a crash in a service
         * that runs on every notification is worse.
         */
        fun fromRulesJson(json: String): InterruptFilter = try {
            val rules = JSONObject(json).optJSONArray("rules") ?: JSONArray()
            val matchers = mutableListOf<PatternMatcher>()
            for (index in 0 until rules.length()) {
                val rule = rules.optJSONObject(index) ?: continue
                if (!rule.optBoolean("enabled", true)) continue
                if (rule.optBoolean("derived", false)) continue
                val decisive = rule.optInt("weight") >= INTERRUPT_WEIGHT ||
                    rule.optInt("escalation_floor") >= INTERRUPT_WEIGHT
                if (!decisive) continue
                val patterns = rule.optJSONArray("patterns") ?: continue
                for (patternIndex in 0 until patterns.length()) {
                    val pattern = patterns.optString(patternIndex)
                    if (pattern.isNotBlank()) matchers.add(PatternMatcher(pattern))
                }
            }
            InterruptFilter(matchers)
        } catch (error: Exception) {
            silent
        }
    }
}

/**
 * The Kotlin twin of the Dart `PatternMatcher`, with the same word-boundary
 * behaviour, so "code" does not match inside "codeine" here either.
 */
class PatternMatcher(pattern: String) {

    private val regex: Regex = run {
        val escaped = Regex.escape(pattern)
        val prefix = if (pattern.firstOrNull()?.isWordChar() == true) "(?<![\\w])" else ""
        val suffix = if (pattern.lastOrNull()?.isWordChar() == true) "(?![\\w])" else ""
        Regex("$prefix$escaped$suffix", RegexOption.IGNORE_CASE)
    }

    fun matches(normalisedText: String): Boolean = regex.containsMatchIn(normalisedText)

    private companion object {
        fun Char.isWordChar(): Boolean = isLetterOrDigit() || this == '_'
    }
}

/**
 * The Kotlin twin of the Dart `TextNormaliser`. Both exist so a scammer cannot
 * slip a pattern past one of them with a zero-width space.
 */
object TextNormaliser {
    private val invisible = Regex("[\\u200b-\\u200f\\u202a-\\u202e\\u2060\\ufeff]")
    private val apostrophes = Regex("[\\u2018\\u2019\\u02bc\\u00b4`]")
    private val dashes = Regex("[\\u2010-\\u2015]")
    private val whitespace = Regex("\\s+")

    fun normalise(input: String): String = input
        .lowercase()
        .replace(invisible, "")
        .replace(apostrophes, "'")
        .replace(dashes, "-")
        .replace(whitespace, " ")
        .trim()
}
