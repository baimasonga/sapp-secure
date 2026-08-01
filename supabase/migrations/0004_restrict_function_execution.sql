-- Everything in `public` is reachable over PostgREST as an RPC. That includes
-- functions written to be triggers, which were never meant to be part of the
-- API surface at all. Supabase's own linter flagged all of them.
--
-- The one that actually mattered: 0002 granted EXECUTE on
-- `refresh_indicator_confidence` to `authenticated`, so any signed-in user
-- could recompute an indicator's standing on demand. It only ever writes
-- figures derived from real reports, so it cannot be used to invent a verdict
-- — but no client calls it, and a function nobody needs should not be exposed
-- to everybody. The moderation path reaches it through a trigger, which runs
-- as the definer and does not need the grant.
--
-- Calling a trigger function directly would fail anyway; revoking is about not
-- leaving a rake on the floor.

revoke all on function public.refresh_indicator_confidence(text) from anon, authenticated;

revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.protect_profile_privileges() from public, anon, authenticated;
revoke all on function public.protect_report_verdict() from public, anon, authenticated;
revoke all on function public.on_report_reviewed() from public, anon, authenticated;
revoke all on function public.anonymise_reports_on_profile_delete() from public, anon, authenticated;

-- current_role_is, is_moderator and is_admin are deliberately NOT revoked, and
-- this is load-bearing. A row-level security policy expression is evaluated
-- with the privileges of the user running the query, so revoking EXECUTE from
-- `authenticated` does not hide these functions — it makes every policy that
-- calls them fail with "permission denied for function is_moderator", which
-- locks moderators out of the queue entirely. `anon` needs it for the same
-- reason: a policy that mentions is_moderator() is evaluated for anonymous
-- callers too, and without EXECUTE the query errors instead of correctly
-- returning nothing.
--
-- Leaving them callable costs little. Each reports only on the caller's own
-- account: is_admin() tells you whether *you* are an admin, which you may
-- reasonably know.
--
-- This was found the hard way — revoking them was tried, and the moderator
-- lost access to every table in the same breath.
