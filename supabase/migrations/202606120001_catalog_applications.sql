create table if not exists public.stylist_applications (
  id text primary key,
  submitted_by uuid references public.profiles(id) on delete set null,
  stylist_id text not null,
  owner_id uuid references public.profiles(id) on delete set null,
  salon_id text not null,
  name text not null,
  title text not null,
  rating numeric not null default 5,
  reviews_count integer not null default 0,
  languages text not null,
  experience text not null,
  specialties text[] not null default '{}',
  avatar_url text not null,
  bio text not null default '',
  base_price integer not null default 0,
  services_payload jsonb not null default '[]'::jsonb,
  works_payload jsonb not null default '[]'::jsonb,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  admin_note text not null default '',
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.salon_applications (
  id text primary key,
  submitted_by uuid references public.profiles(id) on delete set null,
  salon_id text not null,
  name text not null,
  location text not null,
  distance numeric not null default 0,
  rating numeric not null default 5,
  tags text[] not null default '{}',
  open_hours text not null,
  phone text not null,
  start_price integer not null default 0,
  image_url text not null,
  works_payload jsonb not null default '[]'::jsonb,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  admin_note text not null default '',
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists touch_stylist_applications_updated_at on public.stylist_applications;
create trigger touch_stylist_applications_updated_at
before update on public.stylist_applications
for each row execute function public.touch_updated_at();

drop trigger if exists touch_salon_applications_updated_at on public.salon_applications;
create trigger touch_salon_applications_updated_at
before update on public.salon_applications
for each row execute function public.touch_updated_at();

create index if not exists idx_stylist_applications_status_created
  on public.stylist_applications(status, created_at desc);

create index if not exists idx_stylist_applications_submitted_by
  on public.stylist_applications(submitted_by, status);

create index if not exists idx_salon_applications_status_created
  on public.salon_applications(status, created_at desc);

create index if not exists idx_salon_applications_submitted_by
  on public.salon_applications(submitted_by, status);

alter table public.stylist_applications enable row level security;
alter table public.salon_applications enable row level security;

grant select, insert, update on public.stylist_applications, public.salon_applications to authenticated;

drop policy if exists "Users create own stylist applications" on public.stylist_applications;
create policy "Users create own stylist applications" on public.stylist_applications
for insert
to authenticated
with check (
  submitted_by = (select auth.uid())
  and owner_id = (select auth.uid())
  and status = 'pending'
);

drop policy if exists "Users read own stylist applications" on public.stylist_applications;
create policy "Users read own stylist applications" on public.stylist_applications
for select
to authenticated
using (submitted_by = (select auth.uid()));

drop policy if exists "Admins manage stylist applications" on public.stylist_applications;
create policy "Admins manage stylist applications" on public.stylist_applications
for all
to authenticated
using (private.is_admin('admin'))
with check (private.is_admin('admin'));

drop policy if exists "Users create own salon applications" on public.salon_applications;
create policy "Users create own salon applications" on public.salon_applications
for insert
to authenticated
with check (
  submitted_by = (select auth.uid())
  and status = 'pending'
);

drop policy if exists "Users read own salon applications" on public.salon_applications;
create policy "Users read own salon applications" on public.salon_applications
for select
to authenticated
using (submitted_by = (select auth.uid()));

drop policy if exists "Admins manage salon applications" on public.salon_applications;
create policy "Admins manage salon applications" on public.salon_applications
for all
to authenticated
using (private.is_admin('admin'))
with check (private.is_admin('admin'));
