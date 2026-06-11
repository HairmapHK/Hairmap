create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  email text not null,
  role text not null check (role in ('customer', 'stylist')),
  stylist_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.salons (
  id text primary key,
  name text not null,
  location text not null,
  distance numeric not null default 0,
  rating numeric not null default 0,
  tags text[] not null default '{}',
  open_hours text not null,
  phone text not null,
  start_price integer not null default 0,
  image_url text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.stylists (
  id text primary key,
  owner_id uuid references public.profiles(id) on delete set null,
  salon_id text not null references public.salons(id) on delete cascade,
  name text not null,
  title text not null,
  rating numeric not null default 0,
  reviews_count integer not null default 0,
  languages text not null,
  experience text not null,
  specialties text[] not null default '{}',
  avatar_url text not null,
  bio text not null default '',
  base_price integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add constraint profiles_stylist_fk foreign key (stylist_id)
  references public.stylists(id) deferrable initially deferred;

create table if not exists public.services (
  id text primary key,
  stylist_id text not null references public.stylists(id) on delete cascade,
  name text not null,
  category text not null,
  duration integer not null,
  description text not null,
  price integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.portfolio_works (
  id text primary key,
  stylist_id text not null references public.stylists(id) on delete cascade,
  title text not null,
  image_url text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.reviews (
  id text primary key,
  stylist_id text not null references public.stylists(id) on delete cascade,
  reviewer_name text not null,
  reviewer_avatar text not null,
  text text not null,
  stars integer not null check (stars between 1 and 5),
  time_ago text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.inspiration_items (
  id text primary key,
  stylist_id text not null references public.stylists(id) on delete cascade,
  title text not null,
  salon_name text not null,
  location text not null,
  tags text[] not null default '{}',
  image_url text not null,
  category text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.profiles(id) on delete set null,
  stylist_id text not null references public.stylists(id) on delete cascade,
  salon_id text not null references public.salons(id) on delete cascade,
  service_id text references public.services(id) on delete set null,
  salon_name text not null,
  stylist_name text not null,
  client_name text not null,
  client_phone text not null,
  booking_date date not null,
  start_time time not null,
  end_time time not null,
  service_name text not null,
  price integer not null,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.messages (
  id text primary key,
  customer_id uuid references public.profiles(id) on delete set null,
  stylist_id text not null references public.stylists(id) on delete cascade,
  sender_role text not null check (sender_role in ('customer', 'stylist')),
  sender_name text not null,
  text text not null,
  sent_at text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.blocked_slots (
  id uuid primary key default gen_random_uuid(),
  stylist_id text not null references public.stylists(id) on delete cascade,
  work_date date not null,
  start_time time not null,
  created_at timestamptz not null default now(),
  unique (stylist_id, work_date, start_time)
);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists touch_profiles_updated_at on public.profiles;
create trigger touch_profiles_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();

drop trigger if exists touch_salons_updated_at on public.salons;
create trigger touch_salons_updated_at
before update on public.salons
for each row execute function public.touch_updated_at();

drop trigger if exists touch_stylists_updated_at on public.stylists;
create trigger touch_stylists_updated_at
before update on public.stylists
for each row execute function public.touch_updated_at();

drop trigger if exists touch_services_updated_at on public.services;
create trigger touch_services_updated_at
before update on public.services
for each row execute function public.touch_updated_at();

drop trigger if exists touch_bookings_updated_at on public.bookings;
create trigger touch_bookings_updated_at
before update on public.bookings
for each row execute function public.touch_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  role_value text := coalesce(new.raw_user_meta_data ->> 'role', 'customer');
  stylist_value text := nullif(new.raw_user_meta_data ->> 'stylist_id', '');
begin
  insert into public.profiles (id, display_name, email, role, stylist_id)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)),
    coalesce(new.email, ''),
    case when role_value in ('customer', 'stylist') then role_value else 'customer' end,
    stylist_value
  )
  on conflict (id) do update set
    display_name = excluded.display_name,
    email = excluded.email,
    role = excluded.role,
    stylist_id = excluded.stylist_id,
    updated_at = now();

  if role_value = 'stylist' and stylist_value is not null then
    update public.stylists
    set owner_id = new.id, updated_at = now()
    where id = stylist_value and owner_id is null;
  end if;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create index if not exists idx_stylists_owner_id on public.stylists(owner_id);
create index if not exists idx_stylists_salon_id on public.stylists(salon_id);
create index if not exists idx_services_stylist_id on public.services(stylist_id);
create index if not exists idx_works_stylist_id on public.portfolio_works(stylist_id);
create index if not exists idx_bookings_customer_id on public.bookings(customer_id);
create index if not exists idx_bookings_stylist_id on public.bookings(stylist_id);
create index if not exists idx_messages_customer_id on public.messages(customer_id);
create index if not exists idx_messages_stylist_id on public.messages(stylist_id);
create index if not exists idx_blocked_slots_stylist_date on public.blocked_slots(stylist_id, work_date);

alter table public.profiles enable row level security;
alter table public.salons enable row level security;
alter table public.stylists enable row level security;
alter table public.services enable row level security;
alter table public.portfolio_works enable row level security;
alter table public.reviews enable row level security;
alter table public.inspiration_items enable row level security;
alter table public.bookings enable row level security;
alter table public.messages enable row level security;
alter table public.blocked_slots enable row level security;

grant select on public.salons, public.stylists, public.services, public.portfolio_works, public.reviews, public.inspiration_items, public.blocked_slots to anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage on schema public to anon, authenticated;

create policy "Profiles are readable by owner" on public.profiles
for select to authenticated
using ((select auth.uid()) = id);

create policy "Users can upsert own profile" on public.profiles
for insert to authenticated
with check ((select auth.uid()) = id);

create policy "Users can update own profile" on public.profiles
for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy "Catalog salons readable" on public.salons
for select to anon, authenticated
using (true);

create policy "Catalog stylists readable" on public.stylists
for select to anon, authenticated
using (true);

create policy "Stylist owners can update stylist" on public.stylists
for update to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

create policy "Stylist owners can insert stylist" on public.stylists
for insert to authenticated
with check (owner_id = (select auth.uid()));

create policy "Services readable" on public.services
for select to anon, authenticated
using (true);

create policy "Stylist owners manage services" on public.services
for all to authenticated
using (exists (
  select 1 from public.stylists s
  where s.id = services.stylist_id and s.owner_id = (select auth.uid())
))
with check (exists (
  select 1 from public.stylists s
  where s.id = services.stylist_id and s.owner_id = (select auth.uid())
));

create policy "Works readable" on public.portfolio_works
for select to anon, authenticated
using (true);

create policy "Stylist owners manage works" on public.portfolio_works
for all to authenticated
using (exists (
  select 1 from public.stylists s
  where s.id = portfolio_works.stylist_id and s.owner_id = (select auth.uid())
))
with check (exists (
  select 1 from public.stylists s
  where s.id = portfolio_works.stylist_id and s.owner_id = (select auth.uid())
));

create policy "Reviews readable" on public.reviews
for select to anon, authenticated
using (true);

create policy "Inspiration readable" on public.inspiration_items
for select to anon, authenticated
using (true);

create policy "Users read own or assigned bookings" on public.bookings
for select to authenticated
using (
  customer_id = (select auth.uid())
  or exists (
    select 1 from public.stylists s
    where s.id = bookings.stylist_id and s.owner_id = (select auth.uid())
  )
);

create policy "Customers create own bookings" on public.bookings
for insert to authenticated
with check (customer_id = (select auth.uid()));

create policy "Customers or stylists update bookings" on public.bookings
for update to authenticated
using (
  customer_id = (select auth.uid())
  or exists (
    select 1 from public.stylists s
    where s.id = bookings.stylist_id and s.owner_id = (select auth.uid())
  )
)
with check (
  customer_id = (select auth.uid())
  or exists (
    select 1 from public.stylists s
    where s.id = bookings.stylist_id and s.owner_id = (select auth.uid())
  )
);

create policy "Participants read messages" on public.messages
for select to authenticated
using (
  customer_id = (select auth.uid())
  or exists (
    select 1 from public.stylists s
    where s.id = messages.stylist_id and s.owner_id = (select auth.uid())
  )
);

create policy "Participants send messages" on public.messages
for insert to authenticated
with check (
  customer_id = (select auth.uid())
  or exists (
    select 1 from public.stylists s
    where s.id = messages.stylist_id and s.owner_id = (select auth.uid())
  )
);

create policy "Blocked slots are readable" on public.blocked_slots
for select to anon, authenticated
using (true);

create policy "Stylist owners manage blocked slots" on public.blocked_slots
for all to authenticated
using (exists (
  select 1 from public.stylists s
  where s.id = blocked_slots.stylist_id and s.owner_id = (select auth.uid())
))
with check (exists (
  select 1 from public.stylists s
  where s.id = blocked_slots.stylist_id and s.owner_id = (select auth.uid())
));

insert into public.salons (id, name, location, distance, rating, tags, open_hours, phone, start_price, image_url)
values
  ('s1', 'Maison de Beaute', '尖沙咀海港城', 0.5, 4.9, array['歐美染髮', '手刷染'], '10:00 - 20:00', '+852 2345 6789', 1200, 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=1200&q=80'),
  ('s2', 'Noir Studio', '中環國際金融中心', 1.2, 4.8, array['男士理髮', '英式油頭', '漸層推剪'], '11:00 - 21:00', '+852 9876 5432', 800, 'https://images.unsplash.com/photo-1522338242992-e1a54906a8da?auto=format&fit=crop&w=1200&q=80'),
  ('s3', 'Zenith Premium Salon', '銅鑼灣時代廣場', 1.8, 4.9, array['韓式燙髮', '縮毛矯正', '女神大波浪'], '10:00 - 21:00', '+852 2882 1122', 1500, 'https://images.unsplash.com/photo-1633681926022-84c23e8cb2d6?auto=format&fit=crop&w=1200&q=80'),
  ('s4', 'Elysian Hair Art', '旺角朗豪坊', 2.3, 4.7, array['裙擺染', '線條感挑染', '深層護理'], '11:00 - 22:00', '+852 2772 3344', 500, 'https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=1200&q=80')
on conflict (id) do nothing;

insert into public.stylists (id, salon_id, name, title, rating, reviews_count, languages, experience, specialties, avatar_url, bio, base_price)
values
  ('master-leo', 's1', 'Master Leo', '首席設計師', 4.9, 124, '中 / 英 / 粵', '10年以上', array['挑染專家', '經典剪髮'], 'https://images.unsplash.com/photo-1615109398623-88346a601842?auto=format&fit=crop&w=900&q=80', '10年以上明星美髮經驗。擅長巴黎 Balayage 手刷漸層挑染、高精密層次剪裁與修飾臉型氣墊燙。', 680),
  ('alex-chen', 's2', 'Alex Chen', '歐美挑染專家', 4.9, 96, '中 / 粵 / 英', '8年資歷', array['歐美挑染', '漸層推剪'], 'https://images.unsplash.com/photo-1556157382-97eda2d62296?auto=format&fit=crop&w=900&q=80', '專精歐美手刷染與男士輪廓剪裁，重視比例、髮流與日常整理便利度。', 520),
  ('sarah-lin', 's3', 'Sarah Lin', '韓式燙髮專家', 4.8, 112, '中 / 韓', '6年資歷', array['韓式燙髮', '縮毛矯正', '女神大波浪'], 'https://images.unsplash.com/photo-1580618672591-eb180b1a973f?auto=format&fit=crop&w=900&q=80', '擅長韓系柔霧髮色與高層次氣墊燙，喜歡把客人的日常穿搭和臉型一起納入設計。', 980),
  ('jessica-ho', 's4', 'Jessica Ho', '縮毛矯正專家', 5.0, 78, '中 / 粵', '5年資歷', array['縮毛矯正', '深層護理', '直髮柔順'], 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=900&q=80', '專注受損髮修復、直髮柔順與自然捲管理，讓護理後的質感保持可維護。', 920)
on conflict (id) do nothing;

insert into public.services (id, stylist_id, name, category, duration, description, price)
values
  ('s_cut', 'master-leo', '招牌剪髮', '剪髮', 60, '含洗髮與造型', 680),
  ('s_color', 'master-leo', '全頭染髮與光澤護理', '染髮', 120, '頂級有機染劑', 1280),
  ('s_spa', 'master-leo', '巴西生命果護髮', '護髮', 150, '抗毛躁深層護理', 1880),
  ('s_alex_cut', 'alex-chen', '男士俐落剪髮', '剪髮', 45, '頭骨修飾剪裁含精緻洗髮', 520),
  ('s_alex_dye', 'alex-chen', '巴黎手刷漸層染', '染髮', 180, '進口無氨漂色及調色護理', 1680),
  ('s_sarah_perm', 'sarah-lin', '韓系高層次氣墊燙', '燙髮', 150, '客製澎潤修飾燙含洗剪保養', 1480),
  ('s_sarah_dye', 'sarah-lin', '女神霧感拿鐵色染髮', '染髮', 120, '韓系低調顯白色調含水療', 980),
  ('s_jess_stra', 'jessica-ho', '膠原蛋白縮毛矯正', '直髮', 180, '恢復鏡面絲滑質感', 1880),
  ('s_jess_treat', 'jessica-ho', '黑曜光五劑式深層修復', '護髮', 90, '重建髮絲內部鏈鍵', 920)
on conflict (id) do nothing;

insert into public.portfolio_works (id, stylist_id, title, image_url)
values
  ('w1', 'master-leo', '金色巴黎畫染', 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=900&q=80'),
  ('w2', 'master-leo', '精準漸層剪裁', 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=900&q=80'),
  ('w3', 'alex-chen', '冷灰色歐美畫染', 'https://images.unsplash.com/photo-1595959183075-c1d0a174db24?auto=format&fit=crop&w=900&q=80'),
  ('w4', 'alex-chen', '復古清爽油頭', 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=900&q=80'),
  ('w5', 'sarah-lin', '女神木馬卷', 'https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=900&q=80'),
  ('w6', 'sarah-lin', '法式外翻氣墊燙', 'https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=900&q=80'),
  ('w7', 'jessica-ho', '極致直順縮毛矯正', 'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?auto=format&fit=crop&w=900&q=80')
on conflict (id) do nothing;

insert into public.reviews (id, stylist_id, reviewer_name, reviewer_avatar, text, stars, time_ago)
values
  ('rev1', 'master-leo', 'Sarah Jenkins', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80', 'Leo 的挑染非常自然，層次像雜誌封面一樣精緻。', 5, '2 天前'),
  ('rev2', 'master-leo', 'Michael R.', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80', '服務專業，環境安靜，剪完後線條乾淨很多。', 5, '1 週前'),
  ('rev3', 'alex-chen', 'Jimmy Law', 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80', '兩側漸層推剪非常細，油頭比例剛好。', 5, '3 天前')
on conflict (id) do nothing;

insert into public.inspiration_items (id, stylist_id, title, salon_name, location, tags, image_url, category)
values
  ('feed1', 'master-leo', '銀灰精靈短髮', 'Maison de Beaute', '尖沙咀', array['銀灰髮', '短髮造型'], 'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=900&q=80', '熱門趨勢'),
  ('feed2', 'alex-chen', '琥珀銅漸層染', 'Noir Studio', '中環', array['琥珀銅色', '歐美手刷染'], 'https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?auto=format&fit=crop&w=900&q=80', '熱門趨勢'),
  ('feed3', 'alex-chen', '質感漸層油頭', 'Noir Studio', '中環', array['漸層推剪', '男士理髮'], 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=900&q=80', '最新髮型'),
  ('feed4', 'sarah-lin', '摩登法式鮑伯', 'Zenith Premium Salon', '銅鑼灣', array['經典鮑伯', '精緻剪裁'], 'https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=900&q=80', '關注中')
on conflict (id) do nothing;
