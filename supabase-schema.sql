create table if not exists public.status_reports (
  id uuid primary key default gen_random_uuid(),
  product text not null,
  owner text,
  role text not null default 'Product Manager' check (role in ('Product Manager', 'UI/UX')),
  week date not null,
  due_date date,
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

create index if not exists status_reports_week_idx on public.status_reports (week desc);
create index if not exists status_reports_health_idx on public.status_reports (health);

alter table public.status_reports enable row level security;

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
