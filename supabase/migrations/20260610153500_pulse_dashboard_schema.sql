create extension if not exists pgcrypto;

create table if not exists public.status_reports (
  id uuid primary key default gen_random_uuid(),
  product text not null,
  feature_workstream text,
  owner text,
  participants text,
  product_type text not null default 'Legacy',
  role text not null default 'Product Manager',
  week date not null,
  start_date date,
  due_date date,
  health text not null default 'amber',
  progress integer not null default 0,
  stage text not null default 'Discovery',
  summary text not null default '',
  win text,
  blocker text,
  next text,
  impact integer not null default 1,
  time integer not null default 1,
  priority text not null default 'Normal',
  history jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.status_reports
  add column if not exists feature_workstream text,
  add column if not exists participants text,
  add column if not exists product_type text not null default 'Legacy',
  add column if not exists role text not null default 'Product Manager',
  add column if not exists start_date date,
  add column if not exists due_date date,
  add column if not exists history jsonb not null default '[]'::jsonb;

create table if not exists public.user_action_logs (
  id uuid primary key default gen_random_uuid(),
  session_id text,
  action text not null,
  view text,
  target_type text,
  target_id text,
  report_id text,
  product text,
  owner text,
  details jsonb not null default '{}'::jsonb,
  page_url text,
  user_agent text,
  created_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_status_reports_updated_at on public.status_reports;
create trigger set_status_reports_updated_at
before update on public.status_reports
for each row execute function public.set_updated_at();

create unique index if not exists status_reports_identity_idx
on public.status_reports (
  product,
  coalesce(feature_workstream, ''),
  coalesce(owner, ''),
  week,
  md5(coalesce(summary, ''))
);

create index if not exists status_reports_week_idx on public.status_reports (week desc);
create index if not exists status_reports_owner_idx on public.status_reports (owner);
create index if not exists status_reports_product_type_idx on public.status_reports (product_type);
create index if not exists status_reports_role_idx on public.status_reports (role);
create index if not exists status_reports_health_idx on public.status_reports (health);
create index if not exists user_action_logs_created_at_idx on public.user_action_logs (created_at desc);
create index if not exists user_action_logs_action_idx on public.user_action_logs (action);

alter table public.status_reports enable row level security;
alter table public.user_action_logs enable row level security;

drop policy if exists "status_reports_select_all" on public.status_reports;
create policy "status_reports_select_all"
on public.status_reports for select
using (true);

drop policy if exists "status_reports_insert_all" on public.status_reports;
create policy "status_reports_insert_all"
on public.status_reports for insert
with check (true);

drop policy if exists "status_reports_update_all" on public.status_reports;
create policy "status_reports_update_all"
on public.status_reports for update
using (true)
with check (true);

drop policy if exists "status_reports_delete_all" on public.status_reports;
create policy "status_reports_delete_all"
on public.status_reports for delete
using (true);

drop policy if exists "user_action_logs_insert_all" on public.user_action_logs;
create policy "user_action_logs_insert_all"
on public.user_action_logs for insert
with check (true);

drop policy if exists "user_action_logs_select_all" on public.user_action_logs;
create policy "user_action_logs_select_all"
on public.user_action_logs for select
using (true);
