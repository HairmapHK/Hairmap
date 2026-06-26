drop policy if exists "Stylist owners can update stylist" on public.stylists;
drop policy if exists "Stylist owners can insert stylist" on public.stylists;
drop policy if exists "Stylist owners manage services" on public.services;
drop policy if exists "Stylist owners manage works" on public.portfolio_works;

drop policy if exists "Admins read profiles" on public.profiles;
create policy "Admins read profiles" on public.profiles
for select
to authenticated
using (private.is_admin('admin'));

drop policy if exists "Admins update profiles" on public.profiles;
create policy "Admins update profiles" on public.profiles
for update
to authenticated
using (private.is_admin('admin'))
with check (private.is_admin('admin'));
