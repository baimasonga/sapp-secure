# Incident response

Specification milestone 8.

This app is used by people who are already being targeted. An incident here is
not an outage — it is a scam that got through, a warning that did not arrive,
or an accusation attached to an innocent person. The plans below are written
for those, not for uptime.

## Before anything else

**Who to contact.** This section must be filled in before release and is
deliberately left blank rather than invented:

| Role | Name | Contact | Hours |
|---|---|---|---|
| Incident lead | | | |
| Database / backend | | | |
| Moderation lead | | | |
| Someone who can speak to affected users in Krio | | | |

A plan with no names is a document, not a response.

## Severity

| Level | Meaning | Example |
|---|---|---|
| **S1** | Users are being harmed right now, or personal data is exposed | The report database is readable by strangers; the app tells people a scam is safe |
| **S2** | A protection is silently not working | The engine loads no rules and scores everything zero; notification monitoring stops delivering |
| **S3** | A protection is degraded but visibly so | Reporting is down and the screen says so |
| **S4** | Cosmetic or contained | A label is wrong on one screen |

The distinguishing question for S1 versus S2 is not how loud the failure is.
It is whether a user could act on wrong information. **Silence that reads as
safety is an S1**, even though nothing appears broken.

## The first hour

1. **Write down the time and what was observed.** Not the diagnosis — the
   observation.
2. **Decide whether users are currently being misled.** If they are, stop the
   misleading output before investigating. Every remote feature is behind a
   flag for this reason: `ENABLE_REPORTING`,
   `ENABLE_NOTIFICATION_MONITORING`, `ENABLE_EXTERNAL_URL_REPUTATION`.
3. **Do not delete evidence.** The moderation log is append-only by design;
   keep database logs too.
4. **Say something.** A holding message that names the problem beats silence,
   and this app's whole argument is that it tells the truth about what it
   knows.

## Playbooks

### The database is exposed

The realistic version: an RLS policy is wrong and the anon key — which is
public, inside every APK — can read reports.

1. **Contain.** Disable the anon key's access at the Supabase level, or take
   the affected policy to `using (false)`. Reporting failing closed is far
   better than reports leaking.
2. **Measure.** What was reachable, and for how long? Reports hold peppered
   hashes, not numbers, which limits the harm — but excerpts are free text and
   may name people.
3. **Notify.** Anyone whose excerpt was exposed, and the relevant data
   protection authority if one applies.
4. **Fix, then re-run the whole plan** in `docs/SUPABASE_SETUP.md` — not just
   the check that failed. A policy that was wrong once means the reasoning was
   wrong, and the reasoning touched all of them.

### The pepper leaks

`INDICATOR_PEPPER` is what stops stored hashes being brute-forced. There are
roughly ten million Sierra Leonean mobile numbers; a laptop exhausts that
against an unpeppered hash in minutes.

1. Treat every stored indicator hash as compromised.
2. Rotate the pepper. **This invalidates every existing hash** — there is no
   migration, by design, and the indicator table has to be rebuilt from
   reports.
3. Work out how it leaked. It should exist only in the Edge Function
   environment; if it reached CI, a log, or a client build, that path is the
   real defect.

### The engine stops detecting

The dangerous failure, because the app looks fine: every message scores zero
and every verdict reads "low risk".

1. Confirm with the shipped fixtures — `risk_engine_test.dart` covers the
   known-scam corpus.
2. If rules fail to load, the app must show an error, never a clean result.
   `RuleRepository.loadEngine` throws `AnalysisFailure` rather than returning
   an empty engine, and a regression here is an S1.
3. Ship a fix before anything else. There is no useful workaround for a user.

### A wrongly verified indicator

An innocent person's number has been marked as a scam number and users are
being warned about them.

1. A moderator sets the report to `rejected`. The
   `refresh_indicator_confidence` trigger retires the indicator automatically —
   this is why moderation drives visibility rather than raw report counts.
2. Check the audit log for who verified it and on what evidence. The entry
   cannot be edited or deleted, which is the point of it.
3. If the indicator was public for any length of time, treat it as harm done
   to a real person, not a data error. `MODERATION_POLICY.md` governs the
   apology and the correction.
4. Ask whether the corroboration rule held: verification requires independent
   reporters, and a pile-on from one person should never have reached this
   point.

### A fake "Salone Shield" is circulating

Threat T15. A look-alike APK that harvests codes and PINs.

1. Report the listing or distribution channel.
2. Say publicly, in the same words the app uses: **Salone Shield will never
   ask for a verification code, a two-step PIN, or a mobile-money PIN.** That
   sentence is the app's own recognisability test and it is repeated
   throughout the interface for exactly this moment.
3. Publish the signing fingerprint of the genuine build.

### Notification monitoring reads something it should not

Threat T16.

1. The user's own master switch stops it immediately, but do not rely on
   users: ship a build with `ENABLE_NOTIFICATION_MONITORING=false`.
2. Nothing monitored is persisted or uploaded — the queue is in memory, capped
   at twenty entries and fifteen minutes — so the exposure is bounded by what
   was on screen. Confirm that is still true before saying it.

## Afterwards

Within a week of any S1 or S2, write down:

- what happened, in plain words;
- **what made it possible**, which is rarely the same as what caused it;
- what test now exists so it fails next time.

The last line is the one that matters. Four defects in the database schema
were found only by running it against a live project, and each of them is now
a check in `docs/SUPABASE_SETUP.md`. An incident that does not end in a new
test has not been finished.

## What is not covered

- No on-call rotation exists. Until one does, response times are best-effort
  and should not be promised to users.
- No automated alerting. Nothing currently pages anyone when the queue stops
  moving or the Edge Function starts failing; the first signal would be a user
  saying so.
- No user-facing status page.

These are gaps, listed rather than glossed over, and they should be closed
before the app is promoted to an audience that depends on it.
