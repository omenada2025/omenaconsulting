create extension if not exists pgcrypto;

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

alter table public.weekly_review_sends enable row level security;

drop policy if exists "weekly_review_sends_read_all" on public.weekly_review_sends;
create policy "weekly_review_sends_read_all"
on public.weekly_review_sends for select
using (true);

drop policy if exists "weekly_review_sends_insert_all" on public.weekly_review_sends;
create policy "weekly_review_sends_insert_all"
on public.weekly_review_sends for insert
with check (true);

notify pgrst, 'reload schema';
