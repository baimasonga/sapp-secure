# Moderation policy

This policy exists because community reporting can hurt people. A number
wrongly marked as a scammer belongs to somebody, and in a country where mobile
money is how families move money, being flagged has real consequences.

**Reporting must not be enabled in production until there are named moderators
who have agreed to this policy.** A queue nobody works is worse than no queue:
it collects accusations, acts on none of them, and tells users they were heard
when they were not.

## Principles

1. **A report is a claim, not a finding.** Nothing a user submits is treated
   as fact until a moderator has looked at it.
2. **Counts are not evidence.** Ten reports from one person, or ten people
   repeating one rumour, prove nothing. Only independent reporters count, and
   only after review.
3. **Doubt favours the accused.** If the evidence does not support the claim,
   the report is not upheld. "Probably" is not enough to label someone.
4. **Say what you did.** Every decision is written to an append-only log with
   the moderator's identity. No one may edit or delete it, including admins.
5. **A mistake must be reversible.** Retracting a verification retires the
   indicator immediately and automatically.

## Statuses

| Status | Meaning |
|---|---|
| `pending` | Received, not yet looked at |
| `under_review` | A moderator is working on it |
| `needs_more_evidence` | Plausible but unsupported; reporter may add detail |
| `verified` | Evidence supports the claim |
| `rejected` | Evidence does not support the claim |
| `duplicate` | The same indicator from the same reporter |
| `archived` | Closed without a verdict, e.g. withdrawn |

## What "verified" requires

All of:

- The message or evidence shows the behaviour claimed, not merely a number.
- The indicator is specific — a number or a link, not a name or a description.
- Nothing suggests the reporter is settling a personal score.
- A second moderator agrees, for anything that would reach `critical`.

Absent any of these, use `needs_more_evidence` or `rejected`.

## What moderators must never do

- Mark verified to clear a backlog.
- Act on a report about someone they know personally — hand it to another
  moderator.
- Copy a reported number anywhere outside the system.
- Share evidence outside moderation, including with police, without the
  documented legal process.
- Contact a reporter or a reported person directly.

## Appeals

Anyone can contest an indicator. On an appeal:

1. Set the indicator to `disputed`, which removes it from user-visible results
   while it is examined.
2. A moderator who did not make the original decision reviews it.
3. Record the outcome in the audit log either way.

The burden is on the evidence, not on the person appealing.

## Abuse by reporters

Reporter reputation is tracked (`reports_submitted`, `reports_verified`,
`reports_rejected`). A pattern of rejected reports is grounds for suspension by
an administrator. Suspension stops submissions only — every protective feature
keeps working, because the app's job is to protect people, including ones who
have behaved badly.

## Data handling

- Evidence lives in a private bucket, readable by its owner and moderators.
- Do not download evidence to a personal device.
- Reports are archived, never deleted, so a decision cannot be quietly erased.
- A deleted account leaves its reports in place with the reporter detached and
  free text cleared.

## Review

This policy is reviewed whenever the reporting or moderation features change,
and at least once a year. Changes are agreed with the moderators who work the
queue, not imposed on them.
