alter table public.status_reports
  add column if not exists baseline_due_date date,
  add column if not exists dependency text,
  add column if not exists milestone text;

create index if not exists status_reports_baseline_due_date_idx on public.status_reports (baseline_due_date);
create index if not exists status_reports_milestone_idx on public.status_reports (milestone);
