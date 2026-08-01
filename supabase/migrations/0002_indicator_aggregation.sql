-- Indicator aggregation and confidence (specification section 17.3).
--
-- Confidence is deliberately not "how many reports arrived". A number can be
-- reported ten times by one angry person, or by ten people repeating the same
-- rumour. What counts is independent reporters plus a moderator actually
-- looking. Nothing here can publish an indicator on its own — reading one
-- still requires verified_report_count > 0, which only a moderator can set.

-- Records that a report named an indicator. Called by the Edge Function with
-- the service role; there is no client path to it.
create or replace function public.record_indicator_report(
  p_indicator_type text,
  p_indicator_hash text,
  p_masked text,
  p_reporter uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_distinct integer;
begin
  insert into public.threat_indicators (
    indicator_type, indicator_hash, display_value_masked, report_count,
    distinct_reporter_count
  )
  values (p_indicator_type, p_indicator_hash, p_masked, 1, 1)
  on conflict (indicator_type, indicator_hash) do update
    set report_count = public.threat_indicators.report_count + 1,
        last_seen_at = now(),
        -- Keep the first mask seen; they should all be identical anyway.
        display_value_masked = coalesce(
          public.threat_indicators.display_value_masked, excluded.display_value_masked
        );

  -- Recount distinct reporters rather than incrementing, so a repeat reporter
  -- never inflates the figure that matters.
  select count(distinct reporter_id) into v_distinct
  from public.threat_reports
  where reported_number_hash = p_indicator_hash
     or payment_number_hash = p_indicator_hash;

  update public.threat_indicators
  set distinct_reporter_count = greatest(v_distinct, 1)
  where indicator_type = p_indicator_type
    and indicator_hash = p_indicator_hash;
end;
$$;

revoke all on function public.record_indicator_report(text, text, text, uuid) from public, anon, authenticated;

-- Recomputes an indicator's standing after a moderator decision.
--
-- The rules, in plain terms:
--   * Nothing is visible to users until a moderator has verified a report.
--   * One verified report earns "caution", never more.
--   * "critical" needs a moderator verdict AND several independent reporters.
--   * A rejected report can take an indicator back out of sight.
create or replace function public.refresh_indicator_confidence(p_indicator_hash text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_verified integer;
  v_distinct integer;
  v_level text;
begin
  select count(*) filter (where status = 'verified'),
         count(distinct reporter_id) filter (where status = 'verified')
    into v_verified, v_distinct
  from public.threat_reports
  where reported_number_hash = p_indicator_hash
     or payment_number_hash = p_indicator_hash;

  v_level := case
    when v_verified = 0 then 'caution'
    when v_distinct >= 5 and v_verified >= 5 then 'critical'
    when v_distinct >= 2 then 'high'
    else 'caution'
  end;

  update public.threat_indicators
  set verified_report_count = v_verified,
      risk_level = v_level,
      status = case when v_verified = 0 then 'retired' else 'active' end,
      last_seen_at = now()
  where indicator_hash = p_indicator_hash;
end;
$$;

revoke all on function public.refresh_indicator_confidence(text) from public, anon;
grant execute on function public.refresh_indicator_confidence(text) to authenticated;

-- Keeps indicators in step with moderation, so a moderator cannot forget to
-- retract an indicator after rejecting the report behind it.
create or replace function public.on_report_reviewed()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.status is distinct from old.status then
    if new.reported_number_hash is not null then
      perform public.refresh_indicator_confidence(new.reported_number_hash);
    end if;
    if new.payment_number_hash is not null then
      perform public.refresh_indicator_confidence(new.payment_number_hash);
    end if;

    update public.profiles
    set reports_verified = (
          select count(*) from public.threat_reports
          where reporter_id = new.reporter_id and status = 'verified'
        ),
        reports_rejected = (
          select count(*) from public.threat_reports
          where reporter_id = new.reporter_id and status = 'rejected'
        )
    where id = new.reporter_id;
  end if;
  return new;
end;
$$;

create trigger on_report_reviewed
  after update on public.threat_reports
  for each row execute function public.on_report_reviewed();

-- Deleting an account must not leave its reports attached to a live person.
-- reporter_id is already ON DELETE SET NULL; this strips the free text too,
-- because an excerpt can identify the person who submitted it.
create or replace function public.anonymise_reports_on_profile_delete()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.threat_reports
  set message_excerpt = null,
      district = null
  where reporter_id = old.id;
  return old;
end;
$$;

create trigger anonymise_reports_on_profile_delete
  before delete on public.profiles
  for each row execute function public.anonymise_reports_on_profile_delete();
