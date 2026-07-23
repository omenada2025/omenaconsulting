alter table public.status_reports
drop constraint if exists status_reports_action_status_check;

alter table public.status_reports
add constraint status_reports_action_status_check
check (action_status in ('Open', 'In Progress', 'Waiting on decision', 'Blocked', 'Closed'));
