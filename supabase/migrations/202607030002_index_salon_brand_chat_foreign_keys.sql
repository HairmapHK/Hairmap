create index if not exists idx_salon_brands_owner_id
  on public.salon_brands(owner_id)
  where owner_id is not null;

create index if not exists idx_salon_chat_threads_salon_brand_id
  on public.salon_chat_threads(salon_brand_id)
  where salon_brand_id is not null;

create index if not exists idx_salon_chat_messages_salon_id
  on public.salon_chat_messages(salon_id);

create index if not exists idx_salon_chat_messages_salon_brand_id
  on public.salon_chat_messages(salon_brand_id)
  where salon_brand_id is not null;

drop policy if exists "Salon brand owners manage brand" on public.salon_brands;
drop policy if exists "Admins manage salon brands" on public.salon_brands;

create policy "Admins create salon brands" on public.salon_brands
for insert to authenticated
with check (private.is_admin('admin'));

create policy "Salon brand owners or admins update brand" on public.salon_brands
for update to authenticated
using (
  owner_id = (select auth.uid())
  or private.is_admin('admin')
)
with check (
  owner_id = (select auth.uid())
  or private.is_admin('admin')
);

create policy "Admins delete salon brands" on public.salon_brands
for delete to authenticated
using (private.is_admin('admin'));

drop policy if exists "Salon owners manage salon services" on public.salon_services;
drop policy if exists "Admins manage salon services" on public.salon_services;

create policy "Salon owners or admins create salon services" on public.salon_services
for insert to authenticated
with check (
  private.is_admin('admin')
  or exists (
    select 1
    from public.salons salon
    join public.salon_brands brand on brand.id = salon.brand_id
    where salon.id = salon_services.salon_id
      and brand.owner_id = (select auth.uid())
  )
);

create policy "Salon owners or admins update salon services" on public.salon_services
for update to authenticated
using (
  private.is_admin('admin')
  or exists (
    select 1
    from public.salons salon
    join public.salon_brands brand on brand.id = salon.brand_id
    where salon.id = salon_services.salon_id
      and brand.owner_id = (select auth.uid())
  )
)
with check (
  private.is_admin('admin')
  or exists (
    select 1
    from public.salons salon
    join public.salon_brands brand on brand.id = salon.brand_id
    where salon.id = salon_services.salon_id
      and brand.owner_id = (select auth.uid())
  )
);

create policy "Salon owners or admins delete salon services" on public.salon_services
for delete to authenticated
using (
  private.is_admin('admin')
  or exists (
    select 1
    from public.salons salon
    join public.salon_brands brand on brand.id = salon.brand_id
    where salon.id = salon_services.salon_id
      and brand.owner_id = (select auth.uid())
  )
);
