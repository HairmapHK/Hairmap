create table if not exists public.salon_brands (
  id text primary key,
  name text not null,
  owner_id uuid references public.profiles(id) on delete set null,
  primary_salon_id text,
  description text not null default '',
  image_url text not null default '',
  instagram_url text not null default '',
  phone text not null default '',
  is_active boolean not null default true,
  display_order integer not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.salons
  add column if not exists brand_id text,
  add column if not exists branch_name text not null default '',
  add column if not exists booking_enabled boolean not null default true,
  add column if not exists chat_enabled boolean not null default true;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'salons_brand_id_fkey'
      and conrelid = 'public.salons'::regclass
  ) then
    alter table public.salons
      add constraint salons_brand_id_fkey
      foreign key (brand_id) references public.salon_brands(id)
      on delete set null;
  end if;
end $$;

create table if not exists public.salon_services (
  id text primary key,
  salon_id text not null references public.salons(id) on delete cascade,
  name text not null,
  category text not null default '',
  duration integer not null default 60,
  description text not null default '',
  price integer not null default 0,
  is_active boolean not null default true,
  display_order integer not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.salon_applications
  add column if not exists brand_name text not null default '',
  add column if not exists branch_name text not null default '',
  add column if not exists services_payload jsonb not null default '[]'::jsonb;

alter table public.bookings
  alter column stylist_id drop not null,
  add column if not exists salon_brand_id text references public.salon_brands(id) on delete set null,
  add column if not exists branch_name text not null default '',
  add column if not exists assignment_mode text not null default 'stylist_selected',
  add column if not exists assigned_stylist_id text references public.stylists(id) on delete set null,
  add column if not exists booking_note text not null default '';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'bookings_assignment_mode_check'
      and conrelid = 'public.bookings'::regclass
  ) then
    alter table public.bookings
      add constraint bookings_assignment_mode_check
      check (assignment_mode in ('stylist_selected', 'salon_assigns'));
  end if;
end $$;

create table if not exists public.salon_chat_threads (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  salon_id text not null references public.salons(id) on delete cascade,
  salon_brand_id text references public.salon_brands(id) on delete set null,
  subject text not null default '',
  status text not null default 'open' check (status in ('open', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (customer_id, salon_id)
);

create table if not exists public.salon_chat_messages (
  id text primary key,
  thread_id uuid not null references public.salon_chat_threads(id) on delete cascade,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  salon_id text not null references public.salons(id) on delete cascade,
  salon_brand_id text references public.salon_brands(id) on delete set null,
  sender_role text not null check (sender_role in ('customer', 'salon', 'admin')),
  sender_name text not null,
  text text not null,
  sent_at text not null,
  created_at timestamptz not null default now()
);

drop trigger if exists touch_salon_brands_updated_at on public.salon_brands;
create trigger touch_salon_brands_updated_at
before update on public.salon_brands
for each row execute function public.touch_updated_at();

drop trigger if exists touch_salon_services_updated_at on public.salon_services;
create trigger touch_salon_services_updated_at
before update on public.salon_services
for each row execute function public.touch_updated_at();

drop trigger if exists touch_salon_chat_threads_updated_at on public.salon_chat_threads;
create trigger touch_salon_chat_threads_updated_at
before update on public.salon_chat_threads
for each row execute function public.touch_updated_at();

create index if not exists idx_salons_brand_id on public.salons(brand_id, display_order);
create index if not exists idx_salon_services_salon_id on public.salon_services(salon_id, is_active, display_order);
create index if not exists idx_bookings_salon_brand_id on public.bookings(salon_brand_id);
create index if not exists idx_bookings_assigned_stylist_id on public.bookings(assigned_stylist_id);
create index if not exists idx_salon_chat_threads_customer on public.salon_chat_threads(customer_id, updated_at desc);
create index if not exists idx_salon_chat_threads_salon on public.salon_chat_threads(salon_id, updated_at desc);
create index if not exists idx_salon_chat_messages_thread on public.salon_chat_messages(thread_id, created_at);
create index if not exists idx_salon_chat_messages_customer on public.salon_chat_messages(customer_id, created_at desc);

alter table public.salon_brands enable row level security;
alter table public.salon_services enable row level security;
alter table public.salon_chat_threads enable row level security;
alter table public.salon_chat_messages enable row level security;

grant select on public.salon_brands, public.salon_services to anon, authenticated;
grant select, insert, update, delete on public.salon_brands, public.salon_services to authenticated;
grant select, insert, update on public.salon_chat_threads, public.salon_chat_messages to authenticated;

drop policy if exists "Salon brands readable" on public.salon_brands;
create policy "Salon brands readable" on public.salon_brands
for select to anon, authenticated
using (is_active);

drop policy if exists "Salon brand owners manage brand" on public.salon_brands;
create policy "Salon brand owners manage brand" on public.salon_brands
for update to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

drop policy if exists "Admins manage salon brands" on public.salon_brands;
create policy "Admins manage salon brands" on public.salon_brands
for all to authenticated
using (private.is_admin('admin'))
with check (private.is_admin('admin'));

drop policy if exists "Salon services readable" on public.salon_services;
create policy "Salon services readable" on public.salon_services
for select to anon, authenticated
using (is_active);

drop policy if exists "Salon owners manage salon services" on public.salon_services;
create policy "Salon owners manage salon services" on public.salon_services
for all to authenticated
using (exists (
  select 1
  from public.salons salon
  join public.salon_brands brand on brand.id = salon.brand_id
  where salon.id = salon_services.salon_id
    and brand.owner_id = (select auth.uid())
))
with check (exists (
  select 1
  from public.salons salon
  join public.salon_brands brand on brand.id = salon.brand_id
  where salon.id = salon_services.salon_id
    and brand.owner_id = (select auth.uid())
));

drop policy if exists "Admins manage salon services" on public.salon_services;
create policy "Admins manage salon services" on public.salon_services
for all to authenticated
using (private.is_admin('admin'))
with check (private.is_admin('admin'));

drop policy if exists "Users read own or assigned bookings" on public.bookings;
create policy "Users read own or assigned bookings" on public.bookings
for select to authenticated
using (
  customer_id = (select auth.uid())
  or exists (
    select 1
    from public.stylists s
    where s.id = coalesce(bookings.assigned_stylist_id, bookings.stylist_id)
      and s.owner_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.salon_brands brand
    where brand.id = bookings.salon_brand_id
      and brand.owner_id = (select auth.uid())
  )
  or private.is_admin('admin')
);

drop policy if exists "Customers or stylists update bookings" on public.bookings;
create policy "Customers or stylists update bookings" on public.bookings
for update to authenticated
using (
  customer_id = (select auth.uid())
  or exists (
    select 1
    from public.stylists s
    where s.id = coalesce(bookings.assigned_stylist_id, bookings.stylist_id)
      and s.owner_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.salon_brands brand
    where brand.id = bookings.salon_brand_id
      and brand.owner_id = (select auth.uid())
  )
  or private.is_admin('admin')
)
with check (
  customer_id = (select auth.uid())
  or exists (
    select 1
    from public.stylists s
    where s.id = coalesce(bookings.assigned_stylist_id, bookings.stylist_id)
      and s.owner_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.salon_brands brand
    where brand.id = bookings.salon_brand_id
      and brand.owner_id = (select auth.uid())
  )
  or private.is_admin('admin')
);

drop policy if exists "Customers read own salon chat threads" on public.salon_chat_threads;
create policy "Customers read own salon chat threads" on public.salon_chat_threads
for select to authenticated
using (
  customer_id = (select auth.uid())
  or exists (
    select 1
    from public.salon_brands brand
    where brand.id = salon_chat_threads.salon_brand_id
      and brand.owner_id = (select auth.uid())
  )
  or private.is_admin('admin')
);

drop policy if exists "Customers create own salon chat threads" on public.salon_chat_threads;
create policy "Customers create own salon chat threads" on public.salon_chat_threads
for insert to authenticated
with check (customer_id = (select auth.uid()));

drop policy if exists "Salon participants update chat threads" on public.salon_chat_threads;
create policy "Salon participants update chat threads" on public.salon_chat_threads
for update to authenticated
using (
  customer_id = (select auth.uid())
  or exists (
    select 1
    from public.salon_brands brand
    where brand.id = salon_chat_threads.salon_brand_id
      and brand.owner_id = (select auth.uid())
  )
  or private.is_admin('admin')
)
with check (
  customer_id = (select auth.uid())
  or exists (
    select 1
    from public.salon_brands brand
    where brand.id = salon_chat_threads.salon_brand_id
      and brand.owner_id = (select auth.uid())
  )
  or private.is_admin('admin')
);

drop policy if exists "Salon participants read chat messages" on public.salon_chat_messages;
create policy "Salon participants read chat messages" on public.salon_chat_messages
for select to authenticated
using (exists (
  select 1
  from public.salon_chat_threads thread
  left join public.salon_brands brand on brand.id = thread.salon_brand_id
  where thread.id = salon_chat_messages.thread_id
    and (
      thread.customer_id = (select auth.uid())
      or brand.owner_id = (select auth.uid())
      or private.is_admin('admin')
    )
));

drop policy if exists "Salon participants send chat messages" on public.salon_chat_messages;
create policy "Salon participants send chat messages" on public.salon_chat_messages
for insert to authenticated
with check (exists (
  select 1
  from public.salon_chat_threads thread
  left join public.salon_brands brand on brand.id = thread.salon_brand_id
  where thread.id = salon_chat_messages.thread_id
    and (
      (sender_role = 'customer' and thread.customer_id = (select auth.uid()) and customer_id = (select auth.uid()))
      or (sender_role in ('salon', 'admin') and brand.owner_id = (select auth.uid()))
      or private.is_admin('admin')
    )
));

insert into public.salon_brands (
  id,
  name,
  primary_salon_id,
  description,
  image_url,
  instagram_url,
  phone,
  is_active,
  display_order
)
select
  'hair-kiss',
  'Hair kiss',
  'salon-hair-kiss-2ba81bac',
  'Hair Kiss 日韓髮型連鎖店，提供尖沙咀、銅鑼灣及旺角分店。',
  coalesce(nullif(max(image_url) filter (where id = 'salon-hair-kiss-2ba81bac'), ''), max(image_url), ''),
  coalesce(nullif(max(instagram_url) filter (where instagram_url <> ''), ''), ''),
  coalesce(nullif(max(phone) filter (where id = 'salon-hair-kiss-2ba81bac'), ''), max(phone), ''),
  true,
  min(display_order)
from public.salons
where id in ('salon-hair-kiss-2ba81bac', 'salon-hair-kiss-5bd688bf', 'salon-hair-kiss-50ed9708')
having count(*) > 0
on conflict (id) do update
set
  name = excluded.name,
  primary_salon_id = excluded.primary_salon_id,
  description = excluded.description,
  image_url = excluded.image_url,
  instagram_url = excluded.instagram_url,
  phone = excluded.phone,
  is_active = excluded.is_active,
  display_order = excluded.display_order;

update public.salons
set
  brand_id = 'hair-kiss',
  branch_name = case id
    when 'salon-hair-kiss-2ba81bac' then '尖沙咀分店'
    when 'salon-hair-kiss-5bd688bf' then '銅鑼灣分店'
    when 'salon-hair-kiss-50ed9708' then '旺角分店'
    else branch_name
  end,
  booking_enabled = true,
  chat_enabled = true
where id in ('salon-hair-kiss-2ba81bac', 'salon-hair-kiss-5bd688bf', 'salon-hair-kiss-50ed9708');

update public.salon_applications
set
  brand_name = 'Hair kiss',
  branch_name = case salon_id
    when 'salon-hair-kiss-2ba81bac' then '尖沙咀分店'
    when 'salon-hair-kiss-5bd688bf' then '銅鑼灣分店'
    when 'salon-hair-kiss-50ed9708' then '旺角分店'
    else branch_name
  end
where salon_id in ('salon-hair-kiss-2ba81bac', 'salon-hair-kiss-5bd688bf', 'salon-hair-kiss-50ed9708');

insert into public.salon_services (id, salon_id, name, category, duration, description, price, is_active, display_order)
values
  ('salon-hair-kiss-2ba81bac-service-cut-men', 'salon-hair-kiss-2ba81bac', '男士時尚剪髮造型 Men''s Premium Cut & Style', '剪髮', 60, 'Hair Kiss 尖沙咀分店男士剪髮造型', 278, true, 10),
  ('salon-hair-kiss-2ba81bac-service-cut-women', 'salon-hair-kiss-2ba81bac', '女士專業剪髮造型 Women''s Signature Cut & Style', '剪髮', 60, 'Hair Kiss 尖沙咀分店女士剪髮造型', 328, true, 20),
  ('salon-hair-kiss-2ba81bac-service-lv-straight', 'salon-hair-kiss-2ba81bac', '日本 LV pro 微創矯形直髮護理', '直髮', 180, '申請資料標示 HK$1680-2380，App 以起價顯示', 1680, true, 30),
  ('salon-hair-kiss-2ba81bac-service-luxe-care', 'salon-hair-kiss-2ba81bac', '黑耀光感奢華護理 Luxe Black Radiance Treatment', '護理', 120, '高階髮質護理服務', 1680, true, 40),
  ('salon-hair-kiss-2ba81bac-service-women-color', 'salon-hair-kiss-2ba81bac', '女士魅力染髮全效呵護套裝', '染髮', 180, 'Women''s Glamour Color Complete Care Package', 1980, true, 50),
  ('salon-hair-kiss-2ba81bac-service-men-color', 'salon-hair-kiss-2ba81bac', '男士完美染髮變身套裝', '染髮', 150, 'Men''s Complete Color Transformation Package', 1580, true, 60),
  ('salon-hair-kiss-2ba81bac-service-edgar-perm', 'salon-hair-kiss-2ba81bac', 'Edgar 潮流燙髮 + 漸變層次剪藝術造型', '燙髮', 150, 'Edgar Trending Perm + Precision Fade Artistry', 1830, true, 70),
  ('salon-hair-kiss-2ba81bac-service-men-perm', 'salon-hair-kiss-2ba81bac', '男士型格燙髮全效套裝', '燙髮', 150, 'Men''s Stylish Perm Complete Package', 1830, true, 80),
  ('salon-hair-kiss-5bd688bf-service-cut-men', 'salon-hair-kiss-5bd688bf', '男士時尚剪髮造型 Men''s Premium Cut & Style', '剪髮', 60, 'Hair Kiss 銅鑼灣分店男士剪髮造型', 278, true, 10),
  ('salon-hair-kiss-5bd688bf-service-cut-women', 'salon-hair-kiss-5bd688bf', '女士專業剪髮造型 Women''s Signature Cut & Style', '剪髮', 60, 'Hair Kiss 銅鑼灣分店女士剪髮造型', 328, true, 20),
  ('salon-hair-kiss-5bd688bf-service-lv-straight', 'salon-hair-kiss-5bd688bf', '日本 LV pro 微創矯形直髮護理', '直髮', 180, '申請資料標示 HK$1680-2380，App 以起價顯示', 1680, true, 30),
  ('salon-hair-kiss-5bd688bf-service-luxe-care', 'salon-hair-kiss-5bd688bf', '黑耀光感奢華護理 Luxe Black Radiance Treatment', '護理', 120, '高階髮質護理服務', 1680, true, 40),
  ('salon-hair-kiss-5bd688bf-service-women-color', 'salon-hair-kiss-5bd688bf', '女士魅力染髮全效呵護套裝', '染髮', 180, 'Women''s Glamour Color Complete Care Package', 1980, true, 50),
  ('salon-hair-kiss-5bd688bf-service-men-color', 'salon-hair-kiss-5bd688bf', '男士完美染髮變身套裝', '染髮', 150, 'Men''s Complete Color Transformation Package', 1580, true, 60),
  ('salon-hair-kiss-5bd688bf-service-edgar-perm', 'salon-hair-kiss-5bd688bf', 'Edgar 潮流燙髮 + 漸變層次剪藝術造型', '燙髮', 150, 'Edgar Trending Perm + Precision Fade Artistry', 1830, true, 70),
  ('salon-hair-kiss-5bd688bf-service-men-perm', 'salon-hair-kiss-5bd688bf', '男士型格燙髮全效套裝', '燙髮', 150, 'Men''s Stylish Perm Complete Package', 1830, true, 80),
  ('salon-hair-kiss-50ed9708-service-cut-men', 'salon-hair-kiss-50ed9708', '男士時尚剪髮造型', '剪髮', 60, 'Hair Kiss 旺角分店男士剪髮造型', 278, true, 10),
  ('salon-hair-kiss-50ed9708-service-cut-women', 'salon-hair-kiss-50ed9708', '女士修飾面形剪髮造型', '剪髮', 60, 'Hair Kiss 旺角分店女士剪髮造型', 328, true, 20),
  ('salon-hair-kiss-50ed9708-service-lv-straight', 'salon-hair-kiss-50ed9708', '日本 LV pro 微創矯形直髮護理', '直髮', 180, '申請資料標示 HK$1680-2380，App 以起價顯示', 1680, true, 30),
  ('salon-hair-kiss-50ed9708-service-milbon-color', 'salon-hair-kiss-50ed9708', 'Milbon 有機染髮', '染髮', 120, 'Hair Kiss 旺角分店 Milbon 有機染髮', 888, true, 40),
  ('salon-hair-kiss-50ed9708-service-men-perm', 'salon-hair-kiss-50ed9708', '男生韓式電髮', '燙髮', 120, 'Hair Kiss 旺角分店男生韓式電髮', 988, true, 50),
  ('salon-hair-kiss-50ed9708-service-women-perm', 'salon-hair-kiss-50ed9708', '女生慵懶曲髮', '燙髮', 150, 'Hair Kiss 旺角分店女生慵懶曲髮', 1288, true, 60)
on conflict (id) do update
set
  salon_id = excluded.salon_id,
  name = excluded.name,
  category = excluded.category,
  duration = excluded.duration,
  description = excluded.description,
  price = excluded.price,
  is_active = excluded.is_active,
  display_order = excluded.display_order;

do $$
declare
  live_table text;
  live_tables text[] := array[
    'salon_brands',
    'salon_services',
    'salon_chat_threads',
    'salon_chat_messages'
  ];
begin
  foreach live_table in array live_tables loop
    if exists (
      select 1
      from information_schema.tables
      where table_schema = 'public'
        and table_name = live_table
    ) and not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = live_table
    ) then
      execute format('alter publication supabase_realtime add table public.%I', live_table);
    end if;
  end loop;
end $$;
