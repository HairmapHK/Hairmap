drop policy if exists "Admins manage salons" on public.salons;
create policy "Admins manage salons" on public.salons
for all
to authenticated
using (private.is_admin('admin'))
with check (private.is_admin('admin'));

drop policy if exists "Admins manage stylists" on public.stylists;
create policy "Admins manage stylists" on public.stylists
for all
to authenticated
using (private.is_admin('admin'))
with check (private.is_admin('admin'));

drop policy if exists "Admins manage services" on public.services;
create policy "Admins manage services" on public.services
for all
to authenticated
using (private.is_admin('admin'))
with check (private.is_admin('admin'));

drop policy if exists "Admins manage portfolio works" on public.portfolio_works;
create policy "Admins manage portfolio works" on public.portfolio_works
for all
to authenticated
using (private.is_admin('admin'))
with check (private.is_admin('admin'));
