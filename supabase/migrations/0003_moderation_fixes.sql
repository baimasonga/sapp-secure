-- Two defects found by running 0001 and 0002 against a live project for the
-- first time. Both were invisible to review: the SQL is individually correct
-- and only fails when the triggers meet each other.
--
-- 1. A moderator could not verify or reject anything.
--
--    `on_report_reviewed` (AFTER UPDATE on threat_reports) recomputes the
--    reporter's reputation counters by updating public.profiles. That update
--    fires `protect_profile_privileges` (BEFORE UPDATE on profiles), which
--    raises "Reputation counters are maintained by the server" because the
--    moderator is not an administrator. Every moderation action failed at the
--    first step, which means the entire moderation workflow was dead on
--    arrival.
--
--    The fix is not to trust the caller. Counter changes are allowed only when
--    the new values are exactly what a fresh count of threat_reports produces.
--    A forged value is still rejected no matter who sends it, so this is
--    strictly safer than a "the server said so" flag would have been.
--
-- 2. There was no way to create the first moderator or administrator.
--
--    Changing a role requires is_admin(), and nobody was an admin, so the
--    condition could never be met. Even the postgres role was refused: the
--    trigger checks auth.uid(), which is null outside a user session. The only
--    way in was to disable the trigger, which is precisely the habit a
--    protection like this exists to prevent.
--
--    The fix names the operator path explicitly. It grants nothing new:
--    service_role already bypasses RLS and could always have disabled the
--    trigger. Making it legitimate means nobody has to learn the bad habit.

-- ---------------------------------------------------------------------------
-- profiles: privilege protection
-- ---------------------------------------------------------------------------

create or replace function public.protect_profile_privileges()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_verified integer;
  v_rejected integer;
  v_submitted integer;
  v_counters_changed boolean;
begin
  if public.is_admin() then
    new.updated_at := now();
    return new;
  end if;

  -- The operator path: a privileged database role acting outside any user
  -- session. This is how the first administrator is created. It is not a new
  -- capability — service_role bypasses row-level security already — but it is
  -- a named one, so bootstrapping does not require disabling this trigger.
  if auth.uid() is null
     and current_user in ('postgres', 'supabase_admin', 'service_role') then
    new.updated_at := now();
    return new;
  end if;

  if new.role is distinct from old.role then
    raise exception 'Only an administrator may change a role.';
  end if;
  if new.is_suspended is distinct from old.is_suspended then
    raise exception 'Only an administrator may change suspension.';
  end if;

  v_counters_changed :=
    new.reports_submitted is distinct from old.reports_submitted
    or new.reports_verified is distinct from old.reports_verified
    or new.reports_rejected is distinct from old.reports_rejected;

  if v_counters_changed then
    -- A counter may move only to its true value. Each is judged on its own:
    -- the server-side recount touches one or two of them and leaves the rest
    -- alone, and an untouched counter that happens to be stale must not make
    -- a legitimate update fail.
    select count(*),
           count(*) filter (where status = 'verified'),
           count(*) filter (where status = 'rejected')
      into v_submitted, v_verified, v_rejected
    from public.threat_reports
    where reporter_id = new.id;

    if (new.reports_verified is distinct from old.reports_verified
        and new.reports_verified is distinct from v_verified)
       or (new.reports_rejected is distinct from old.reports_rejected
           and new.reports_rejected is distinct from v_rejected)
       or (new.reports_submitted is distinct from old.reports_submitted
           and new.reports_submitted is distinct from v_submitted) then
      raise exception 'Reputation counters are maintained by the server.';
    end if;
  end if;

  new.updated_at := now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- threat_reports: the same operator gap
-- ---------------------------------------------------------------------------

-- `protect_report_verdict` demanded is_moderator() for every update, which
-- also locked out the server itself: back-office corrections, archival, and
-- any future maintenance had no way in short of disabling the trigger. The
-- client-facing rule is unchanged — an ordinary user still cannot touch a
-- verdict, and provenance is still immutable for everyone.
create or replace function public.protect_report_verdict()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_is_operator boolean;
begin
  v_is_operator := auth.uid() is null
    and current_user in ('postgres', 'supabase_admin', 'service_role');

  if tg_op = 'INSERT' then
    if new.status is distinct from 'pending' or new.confidence_score <> 0 then
      raise exception 'A new report starts as pending with no confidence.';
    end if;
    if new.reviewed_at is not null or new.reviewed_by is not null then
      raise exception 'A new report has not been reviewed.';
    end if;
    return new;
  end if;

  if not public.is_moderator() and not v_is_operator then
    raise exception 'Only a moderator may change a report.';
  end if;

  if new.created_at is distinct from old.created_at then
    raise exception 'Report provenance is immutable.';
  end if;

  -- Provenance may be erased but never rewritten. Detaching a report from its
  -- reporter is what account deletion does — reporter_id is ON DELETE SET
  -- NULL — and the original blanket check made deleting an account impossible,
  -- which took away a control the user is entitled to. Reassigning a report to
  -- a different person remains forbidden, because that would let someone put
  -- their accusation in another user's name.
  if new.reporter_id is distinct from old.reporter_id
     and new.reporter_id is not null then
    raise exception 'A report cannot be reassigned to another reporter.';
  end if;

  -- An operator acting outside a session has no identity to record, so the
  -- review stamp is left alone rather than being filled with a null.
  if not v_is_operator then
    new.reviewed_at := now();
    new.reviewed_by := auth.uid();
  end if;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Bootstrapping the first administrator
-- ---------------------------------------------------------------------------

-- Callable only by an operator with no end-user session: the SQL editor, a
-- migration, or the service role. Revoked from anon and authenticated, so no
-- client can reach it even if they learn the name.
create or replace function public.bootstrap_grant_role(
  p_user uuid,
  p_role text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is not null then
    raise exception 'bootstrap_grant_role is not callable from a user session.';
  end if;
  if current_user not in ('postgres', 'supabase_admin', 'service_role') then
    raise exception 'bootstrap_grant_role requires an operator role.';
  end if;
  if p_role not in ('user', 'moderator', 'admin') then
    raise exception 'Unknown role: %', p_role;
  end if;

  update public.profiles set role = p_role where id = p_user;
  if not found then
    raise exception 'No profile for %', p_user;
  end if;
end;
$$;

revoke all on function public.bootstrap_grant_role(uuid, text) from public, anon, authenticated;

comment on function public.bootstrap_grant_role(uuid, text) is
  'Operator-only. Creates the first moderator or administrator, which is '
  'otherwise impossible because changing a role requires an existing admin.';
