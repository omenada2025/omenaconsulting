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

create table if not exists public.weekly_review_sends (
  id uuid primary key default gen_random_uuid(),
  batch_id text,
  owner text not null,
  email text not null,
  filter_product text not null default 'all',
  filter_week text not null default 'all',
  filter_role text not null default 'all',
  period_label text,
  report_count integer not null default 0 check (report_count >= 0),
  action_count integer not null default 0 check (action_count >= 0),
  feedback_tone text not null default 'green' check (feedback_tone in ('green', 'amber', 'red')),
  subject text,
  message_preview text,
  status text not null default 'sent' check (status in ('sent', 'failed')),
  error_message text,
  sent_by_username text,
  sent_by_name text,
  sent_by_role text,
  created_at timestamptz not null default now()
);

create index if not exists weekly_review_sends_created_at_idx on public.weekly_review_sends (created_at desc);
create index if not exists weekly_review_sends_owner_idx on public.weekly_review_sends (owner);
create index if not exists weekly_review_sends_filter_week_idx on public.weekly_review_sends (filter_week);
create index if not exists weekly_review_sends_status_idx on public.weekly_review_sends (status);
create index if not exists weekly_review_sends_batch_idx on public.weekly_review_sends (batch_id);

create or replace view public.weekly_review_send_kpis as
select
  date_trunc('week', created_at)::date as send_week,
  filter_week,
  period_label,
  count(*) as total_attempts,
  count(*) filter (where status = 'sent') as emails_sent,
  count(*) filter (where status = 'failed') as emails_failed,
  count(distinct owner) filter (where status = 'sent') as owners_reached,
  coalesce(sum(report_count) filter (where status = 'sent'), 0) as reports_covered,
  coalesce(sum(action_count) filter (where status = 'sent'), 0) as actions_generated
from public.weekly_review_sends
group by 1, 2, 3;

alter table public.status_reports enable row level security;
alter table public.user_action_logs enable row level security;
alter table public.weekly_review_sends enable row level security;

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

drop policy if exists "weekly_review_sends_read_all" on public.weekly_review_sends;
create policy "weekly_review_sends_read_all"
on public.weekly_review_sends for select
using (true);

drop policy if exists "weekly_review_sends_insert_all" on public.weekly_review_sends;
create policy "weekly_review_sends_insert_all"
on public.weekly_review_sends for insert
with check (true);

notify pgrst, 'reload schema';
