-- The reporter's side of a moderation decision.
--
-- `SubmittedReport` in the app already reads `moderator_note` and shows it on
-- the report-history screen. No such column existed, so the field was always
-- null and a verdict of "needs more evidence" reached the reporter as those
-- three words and nothing else — no indication of *what* evidence.
--
-- The moderator's full reasoning stays in `moderation_actions`, which is
-- moderator-only and append-only. This column is the part deliberately shown
-- to the person who filed the report: short, and written knowing they will
-- read it.
--
-- It is a moderator-written field on a row the reporter can already read, so
-- it needs no new policy. What it does need is the same protection as every
-- other verdict field, which `protect_report_verdict` already provides: only
-- a moderator or the server may update a report at all.

alter table public.threat_reports
  add column if not exists moderator_note text
    check (moderator_note is null or length(moderator_note) <= 500);

comment on column public.threat_reports.moderator_note is
  'Shown to the reporter. The moderator''s working notes belong in '
  'moderation_actions, which the reporter cannot read.';
