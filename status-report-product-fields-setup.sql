alter table public.status_reports
add column if not exists feature_workstream text;

alter table public.status_reports
add column if not exists participants text;

alter table public.status_reports
add column if not exists product_type text not null default 'Legacy'
check (product_type in ('Legacy', 'New product'));

alter table public.status_reports
add column if not exists role text not null default 'Product Manager'
check (role in ('Product Manager', 'UI/UX'));

alter table public.status_reports
add column if not exists start_date date;

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

create index if not exists status_reports_product_idx on public.status_reports (product);
create index if not exists status_reports_product_type_idx on public.status_reports (product_type);

notify pgrst, 'reload schema';
