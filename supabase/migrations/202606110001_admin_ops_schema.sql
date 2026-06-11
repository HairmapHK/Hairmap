create schema if not exists private;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('super_admin', 'admin', 'moderator')),
  display_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function private.is_admin(required_role text default 'moderator')
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.admin_users admin
    where admin.user_id = (select auth.uid())
      and case required_role
        when 'super_admin' then admin.role = 'super_admin'
        when 'admin' then admin.role in ('super_admin', 'admin')
        else admin.role in ('super_admin', 'admin', 'moderator')
      end
  );
$$;

revoke all on function private.is_admin(text) from public;
grant usage on schema private to authenticated;
grant execute on function private.is_admin(text) to authenticated;

alter table public.salons
  add column if not exists is_active boolean not null default true,
  add column if not exists is_featured boolean not null default false,
  add column if not exists display_order integer not null default 100,
  add column if not exists admin_note text not null default '';

alter table public.stylists
  add column if not exists is_active boolean not null default true,
  add column if not exists is_featured boolean not null default false,
  add column if not exists display_order integer not null default 100,
  add column if not exists admin_note text not null default '';

alter table public.services
  add column if not exists is_active boolean not null default true,
  add column if not exists display_order integer not null default 100;

alter table public.portfolio_works
  add column if not exists is_active boolean not null default true,
  add column if not exists display_order integer not null default 100;

alter table public.reviews
  add column if not exists is_hidden boolean not null default false,
  add column if not exists moderation_status text not null default 'approved'
    check (moderation_status in ('pending', 'approved', 'hidden', 'rejected')),
  add column if not exists review_photo_url text;

alter table public.inspiration_items
  add column if not exists is_active boolean not null default true,
  add column if not exists is_featured boolean not null default false,
  add column if not exists display_order integer not null default 100,
  add column if not exists like_count integer not null default 0,
  add column if not exists comment_count integer not null default 0,
  add column if not exists share_count integer not null default 0;

create table if not exists public.salon_portfolio_works (
  id text primary key,
  salon_id text not null references public.salons(id) on delete cascade,
  title text not null,
  image_url text not null,
  is_active boolean not null default true,
  display_order integer not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.homepage_sections (
  id text primary key,
  section_key text not null unique,
  title text not null,
  layout text not null default 'grid',
  sort_order integer not null default 100,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.homepage_items (
  id uuid primary key default gen_random_uuid(),
  section_id text not null references public.homepage_sections(id) on delete cascade,
  item_type text not null check (item_type in ('stylist', 'salon', 'inspiration')),
  item_id text not null,
  title_override text,
  image_url_override text,
  sort_order integer not null default 100,
  is_featured boolean not null default false,
  is_active boolean not null default true,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (section_id, item_type, item_id)
);

create table if not exists public.ranking_overrides (
  id uuid primary key default gen_random_uuid(),
  ranking_key text not null,
  item_type text not null check (item_type in ('stylist', 'salon')),
  item_id text not null,
  manual_rank integer,
  score_override numeric,
  is_pinned boolean not null default false,
  is_active boolean not null default true,
  note text not null default '',
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (ranking_key, item_type, item_id)
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references public.profiles(id) on delete set null,
  entity_type text not null check (entity_type in ('stylist', 'salon', 'review', 'inspiration', 'message', 'profile')),
  entity_id text not null,
  reason text not null,
  details text not null default '',
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  resolved_by uuid references auth.users(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  is_public boolean not null default false,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists touch_admin_users_updated_at on public.admin_users;
create trigger touch_admin_users_updated_at
before update on public.admin_users
for each row execute function public.touch_updated_at();

drop trigger if exists touch_salon_portfolio_works_updated_at on public.salon_portfolio_works;
create trigger touch_salon_portfolio_works_updated_at
before update on public.salon_portfolio_works
for each row execute function public.touch_updated_at();

drop trigger if exists touch_homepage_sections_updated_at on public.homepage_sections;
create trigger touch_homepage_sections_updated_at
before update on public.homepage_sections
for each row execute function public.touch_updated_at();

drop trigger if exists touch_homepage_items_updated_at on public.homepage_items;
create trigger touch_homepage_items_updated_at
before update on public.homepage_items
for each row execute function public.touch_updated_at();

drop trigger if exists touch_ranking_overrides_updated_at on public.ranking_overrides;
create trigger touch_ranking_overrides_updated_at
before update on public.ranking_overrides
for each row execute function public.touch_updated_at();

drop trigger if exists touch_reports_updated_at on public.reports;
create trigger touch_reports_updated_at
before update on public.reports
for each row execute function public.touch_updated_at();

drop trigger if exists touch_app_settings_updated_at on public.app_settings;
create trigger touch_app_settings_updated_at
before update on public.app_settings
for each row execute function public.touch_updated_at();

create index if not exists idx_salons_ops_order on public.salons(is_active, display_order, rating desc);
create index if not exists idx_stylists_ops_order on public.stylists(is_active, display_order, rating desc);
create index if not exists idx_services_ops_order on public.services(stylist_id, is_active, display_order, price);
create index if not exists idx_works_ops_order on public.portfolio_works(stylist_id, is_active, display_order);
create index if not exists idx_salon_works_ops_order on public.salon_portfolio_works(salon_id, is_active, display_order);
create index if not exists idx_inspiration_ops_order on public.inspiration_items(is_active, display_order, created_at desc);
create index if not exists idx_homepage_sections_order on public.homepage_sections(is_active, sort_order);
create index if not exists idx_homepage_items_order on public.homepage_items(section_id, is_active, sort_order);
create index if not exists idx_ranking_overrides_order on public.ranking_overrides(ranking_key, is_active, manual_rank);
create index if not exists idx_reports_status on public.reports(status, created_at desc);
create index if not exists idx_audit_logs_entity on public.audit_logs(entity_type, entity_id, created_at desc);

alter table public.admin_users enable row level security;
alter table public.salon_portfolio_works enable row level security;
alter table public.homepage_sections enable row level security;
alter table public.homepage_items enable row level security;
alter table public.ranking_overrides enable row level security;
alter table public.reports enable row level security;
alter table public.audit_logs enable row level security;
alter table public.app_settings enable row level security;

grant select on public.homepage_sections, public.homepage_items, public.ranking_overrides, public.salon_portfolio_works, public.app_settings to anon;
grant select on public.homepage_sections, public.homepage_items, public.ranking_overrides, public.salon_portfolio_works, public.app_settings to authenticated;
grant select, insert, update, delete on public.admin_users, public.homepage_sections, public.homepage_items, public.ranking_overrides, public.reports, public.audit_logs, public.app_settings, public.salon_portfolio_works to authenticated;

drop policy if exists "Admins read admin users" on public.admin_users;
create policy "Admins read admin users" on public.admin_users
for select to authenticated
using (user_id = (select auth.uid()) or private.is_admin('admin'));

drop policy if exists "Super admins manage admin users" on public.admin_users;
create policy "Super admins manage admin users" on public.admin_users
for all to authenticated
using (private.is_admin('super_admin'))
with check (private.is_admin('super_admin'));

drop policy if exists "Public reads active homepage sections" on public.homepage_sections;
create policy "Public reads active homepage sections" on public.homepage_sections
for select to anon
using (is_active);

drop policy if exists "Authenticated reads homepage sections" on public.homepage_sections;
create policy "Authenticated reads homepage sections" on public.homepage_sections
for select to authenticated
using (is_active or private.is_admin('moderator'));

drop policy if exists "Admins manage homepage sections" on public.homepage_sections;
create policy "Admins manage homepage sections" on public.homepage_sections
for all to authenticated
using (private.is_admin('admin'))
with check (private.is_admin('admin'));

drop policy if exists "Public reads active homepage items" on public.homepage_items;
create policy "Public reads active homepage items" on public.homepage_items
for select to anon
using (
  is_active
  and (starts_at is null or starts_at <= now())
  and (ends_at is null or ends_at >= now())
);

drop policy if exists "Authenticated reads homepage items" on public.homepage_items;
create policy "Authenticated reads homepage items" on public.homepage_items
for select to authenticated
using (
  (
    is_active
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at >= now())
  )
  or private.is_admin('moderator')
);

drop policy if exists "Admins manage homepage items" on public.homepage_items;
create policy "Admins manage homepage items" on public.homepage_items
for all to authenticated
using (private.is_admin('admin'))
with check (private.is_admin('admin'));

drop policy if exists "Public reads active ranking overrides" on public.ranking_overrides;
create policy "Public reads active ranking overrides" on public.ranking_overrides
for select to anon
using (
  is_active
  and (starts_at is null or starts_at <= now())
  and (ends_at is null or ends_at >= now())
);

drop policy if exists "Authenticated reads ranking overrides" on public.ranking_overrides;
create policy "Authenticated reads ranking overrides" on public.ranking_overrides
for select to authenticated
using (
  (
    is_active
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at >= now())
  )
  or private.is_admin('moderator')
);

drop policy if exists "Admins manage ranking overrides" on public.ranking_overrides;
create policy "Admins manage ranking overrides" on public.ranking_overrides
for all to authenticated
using (private.is_admin('admin'))
with check (private.is_admin('admin'));

drop policy if exists "Public reads active salon works" on public.salon_portfolio_works;
create policy "Public reads active salon works" on public.salon_portfolio_works
for select to anon, authenticated
using (is_active);

drop policy if exists "Admins manage salon works" on public.salon_portfolio_works;
create policy "Admins manage salon works" on public.salon_portfolio_works
for all to authenticated
using (private.is_admin('admin'))
with check (private.is_admin('admin'));

drop policy if exists "Users create reports" on public.reports;
create policy "Users create reports" on public.reports
for insert to authenticated
with check (reporter_id = (select auth.uid()));

drop policy if exists "Admins read reports" on public.reports;
create policy "Admins read reports" on public.reports
for select to authenticated
using (private.is_admin('moderator'));

drop policy if exists "Admins update reports" on public.reports;
create policy "Admins update reports" on public.reports
for update to authenticated
using (private.is_admin('moderator'))
with check (private.is_admin('moderator'));

drop policy if exists "Admins read audit logs" on public.audit_logs;
create policy "Admins read audit logs" on public.audit_logs
for select to authenticated
using (private.is_admin('admin'));

drop policy if exists "Admins write audit logs" on public.audit_logs;
create policy "Admins write audit logs" on public.audit_logs
for insert to authenticated
with check (private.is_admin('admin'));

drop policy if exists "Public reads public settings" on public.app_settings;
create policy "Public reads public settings" on public.app_settings
for select to anon
using (is_public);

drop policy if exists "Authenticated reads settings" on public.app_settings;
create policy "Authenticated reads settings" on public.app_settings
for select to authenticated
using (is_public or private.is_admin('moderator'));

drop policy if exists "Admins manage settings" on public.app_settings;
create policy "Admins manage settings" on public.app_settings
for all to authenticated
using (private.is_admin('admin'))
with check (private.is_admin('admin'));

insert into public.homepage_sections (id, section_key, title, layout, sort_order, is_active)
values
  ('featured_stylists', 'featured_stylists', '精選推薦髮型設計師', 'stylist_grid', 10, true),
  ('featured_salons', 'featured_salons', '為您推薦沙龍', 'salon_grid', 20, true),
  ('hot_rankings', 'hot_rankings', '香港熱門排行榜', 'ranking_list', 30, true)
on conflict (id) do update set
  title = excluded.title,
  layout = excluded.layout,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active,
  updated_at = now();

insert into public.homepage_items (section_id, item_type, item_id, sort_order, is_featured, is_active)
values
  ('featured_stylists', 'stylist', 'master-leo', 10, true, true),
  ('featured_stylists', 'stylist', 'alex-chen', 20, true, true),
  ('featured_stylists', 'stylist', 'sarah-lin', 30, true, true),
  ('featured_salons', 'salon', 's1', 10, true, true),
  ('featured_salons', 'salon', 's2', 20, true, true),
  ('featured_salons', 'salon', 's3', 30, true, true)
on conflict (section_id, item_type, item_id) do update set
  sort_order = excluded.sort_order,
  is_featured = excluded.is_featured,
  is_active = excluded.is_active,
  updated_at = now();

insert into public.ranking_overrides (ranking_key, item_type, item_id, manual_rank, is_pinned, is_active, note)
values
  ('stylist_hot', 'stylist', 'jessica-ho', 1, true, true, '可由後台置頂'),
  ('stylist_hot', 'stylist', 'master-leo', 2, true, true, '可由後台置頂'),
  ('stylist_hot', 'stylist', 'alex-chen', 3, true, true, '可由後台置頂'),
  ('salon_hot', 'salon', 's1', 1, true, true, '可由後台置頂'),
  ('salon_hot', 'salon', 's3', 2, true, true, '可由後台置頂')
on conflict (ranking_key, item_type, item_id) do update set
  manual_rank = excluded.manual_rank,
  is_pinned = excluded.is_pinned,
  is_active = excluded.is_active,
  note = excluded.note,
  updated_at = now();

update public.stylists set display_order = 10, is_featured = true where id = 'master-leo';
update public.stylists set display_order = 20, is_featured = true where id = 'alex-chen';
update public.stylists set display_order = 30, is_featured = true where id = 'sarah-lin';
update public.stylists set display_order = 40, is_featured = false where id = 'jessica-ho';

update public.salons set display_order = 10, is_featured = true where id = 's1';
update public.salons set display_order = 20, is_featured = true where id = 's2';
update public.salons set display_order = 30, is_featured = true where id = 's3';
update public.salons set display_order = 40, is_featured = false where id = 's4';
