create table if not exists public.app_users (
  username text primary key,
  display_name text not null,
  role text not null default 'admin',
  password text not null,
  active boolean not null default true,
  deleted boolean not null default false,
  last_credential_email_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_app_users_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_app_users_updated_at on public.app_users;
create trigger set_app_users_updated_at
before update on public.app_users
for each row execute function public.set_app_users_updated_at();

alter table public.app_users enable row level security;

drop policy if exists app_users_select_all on public.app_users;
create policy app_users_select_all
on public.app_users for select
using (true);

drop policy if exists app_users_insert_all on public.app_users;
create policy app_users_insert_all
on public.app_users for insert
with check (true);

drop policy if exists app_users_update_all on public.app_users;
create policy app_users_update_all
on public.app_users for update
using (true)
with check (true);

drop policy if exists app_users_delete_all on public.app_users;
create policy app_users_delete_all
on public.app_users for delete
using (true);
