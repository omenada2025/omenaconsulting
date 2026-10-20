-- Factory cycle fields for Live PM / Support PM Sprint A
-- Safe to re-run.

alter table public.status_reports
  add column if not exists ownership_stage text;

alter table public.status_reports
  add column if not exists v0_received_date date;

alter table public.status_reports
  add column if not exists version_label text;

alter table public.status_reports
  add column if not exists factory_week text;

alter table public.status_reports
  add column if not exists handover_accepted_at timestamptz;

alter table public.status_reports
  add column if not exists handover_accepted_by text;

alter table public.status_reports
  drop constraint if exists status_reports_ownership_stage_check;

alter table public.status_reports
  add constraint status_reports_ownership_stage_check check (
    ownership_stage is null or ownership_stage in (
      'In delivery (pre-handover)',
      'Handover in progress',
      'Live ops (Support PM)'
    )
  );

alter table public.status_reports
  drop constraint if exists status_reports_factory_week_check;

alter table public.status_reports
  add constraint status_reports_factory_week_check check (
    factory_week is null or factory_week in ('1', '2', '3', '4', '5', '6')
  );

notify pgrst, 'reload schema';
