-- Optional validation signals for Sprint C polish (P2-02)
-- Safe to re-run.

alter table public.status_reports
  add column if not exists validation_status text;

alter table public.status_reports
  add column if not exists test_environment text;

alter table public.status_reports
  drop constraint if exists status_reports_validation_status_check;

alter table public.status_reports
  add constraint status_reports_validation_status_check check (
    validation_status is null or validation_status in (
      'Not started',
      'In progress',
      'Passed',
      'Blocked'
    )
  );

notify pgrst, 'reload schema';
