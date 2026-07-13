create extension if not exists pgcrypto;

create table if not exists public.status_reports (
  id uuid primary key default gen_random_uuid(),
  product text not null,
  feature_workstream text,
  owner text,
  participants text,
  product_type text not null default 'Legacy' check (product_type in ('Legacy', 'New product')),
  role text not null default 'Product Manager' check (role in ('Product Manager', 'UI/UX')),
  week date not null,
  start_date date,
  due_date date,
  baseline_due_date date,
  dependency text,
  milestone text,
  delay_reason text,
  date_change_reason text,
  action_owner text,
  action_due_date date,
  decision_needed text,
  action_status text not null default 'Open' check (action_status in ('Open', 'In Progress', 'Waiting on decision', 'Blocked', 'Closed')),
  health text not null check (health in ('green', 'amber', 'red', 'gray')),
  progress integer not null default 0 check (progress >= 0 and progress <= 100),
  stage text not null,
  priority text not null default 'Normal' check (priority in ('Normal', 'High', 'Critical')),
  impact integer not null default 1 check (impact >= 1 and impact <= 3),
  time integer not null default 1 check (time >= 1 and time <= 3),
  summary text not null,
  win text,
  blocker text,
  next text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.status_reports
add column if not exists role text not null default 'Product Manager'
check (role in ('Product Manager', 'UI/UX'));

alter table public.status_reports
add column if not exists due_date date;

alter table public.status_reports
add column if not exists baseline_due_date date;

alter table public.status_reports
add column if not exists dependency text;

alter table public.status_reports
add column if not exists milestone text;

alter table public.status_reports
add column if not exists delay_reason text;

alter table public.status_reports
add column if not exists date_change_reason text;

alter table public.status_reports
add column if not exists action_owner text;

alter table public.status_reports
add column if not exists action_due_date date;

alter table public.status_reports
add column if not exists decision_needed text;

alter table public.status_reports
add column if not exists action_status text not null default 'Open'
check (action_status in ('Open', 'In Progress', 'Waiting on decision', 'Blocked', 'Closed'));

alter table public.status_reports
add column if not exists product_type text not null default 'Legacy'
check (product_type in ('Legacy', 'New product'));

alter table public.status_reports
add column if not exists start_date date;

alter table public.status_reports
add column if not exists feature_workstream text;

alter table public.status_reports
add column if not exists participants text;

create index if not exists status_reports_week_idx on public.status_reports (week desc);
create index if not exists status_reports_health_idx on public.status_reports (health);
create index if not exists status_reports_product_type_idx on public.status_reports (product_type);
create index if not exists status_reports_product_idx on public.status_reports (product);

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

alter table public.status_reports enable row level security;
alter table public.user_action_logs enable row level security;

drop policy if exists "status_reports_read_all" on public.status_reports;
create policy "status_reports_read_all"
on public.status_reports for select
using (true);

drop policy if exists "status_reports_insert_all" on public.status_reports;
create policy "status_reports_insert_all"
on public.status_reports for insert
with check (true);

drop policy if exists "status_reports_delete_all" on public.status_reports;
create policy "status_reports_delete_all"
on public.status_reports for delete
using (true);

drop policy if exists "status_reports_update_all" on public.status_reports;
create policy "status_reports_update_all"
on public.status_reports for update
using (true)
with check (true);

drop policy if exists "user_action_logs_insert_all" on public.user_action_logs;
create policy "user_action_logs_insert_all"
on public.user_action_logs for insert
with check (true);

drop policy if exists "user_action_logs_read_all" on public.user_action_logs;
create policy "user_action_logs_read_all"
on public.user_action_logs for select
using (true);

notify pgrst, 'reload schema';
