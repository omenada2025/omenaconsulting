create extension if not exists pgcrypto;

create table if not exists public.user_action_logs (
  id uuid primary key default gen_random_uuid(),
  session_id text not null,
  action text not null,
  view text,
  target_type text,
  target_id text,
  report_id uuid,
  product text,
  owner text,
  details jsonb not null default '{}'::jsonb,
  page_url text,
  user_agent text,
  created_at timestamptz not null default now()
);

create index if not exists user_action_logs_created_at_idx on public.user_action_logs (created_at desc);
create index if not exists user_action_logs_action_idx on public.user_action_logs (action);
create index if not exists user_action_logs_session_idx on public.user_action_logs (session_id);
create index if not exists user_action_logs_report_idx on public.user_action_logs (report_id);

create or replace view public.user_action_log_export as
select
  id,
  created_at,
  session_id,
  action,
  view,
  target_type,
  target_id,
  report_id,
  product,
  owner,
  details,
  details->>'area' as filter_area,
  details->>'filter' as filter_name,
  details->>'value' as filter_value,
  details->>'format' as export_format,
  nullif(details->>'row_count', '')::integer as export_row_count,
  page_url,
  user_agent
from public.user_action_logs;

alter table public.user_action_logs enable row level security;

drop policy if exists "user_action_logs_insert_all" on public.user_action_logs;
create policy "user_action_logs_insert_all"
on public.user_action_logs for insert
with check (true);

drop policy if exists "user_action_logs_read_all" on public.user_action_logs;
create policy "user_action_logs_read_all"
on public.user_action_logs for select
using (true);

notify pgrst, 'reload schema';

-- Example extraction:
-- select * from public.user_action_log_export order by created_at desc;
-- select action, count(*) from public.user_action_logs group by action order by count(*) desc;
