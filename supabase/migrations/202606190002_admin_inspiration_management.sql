grant update, delete on public.inspiration_items to authenticated;

drop policy if exists "Admins manage inspiration items" on public.inspiration_items;
create policy "Admins manage inspiration items" on public.inspiration_items
for all to authenticated
using (private.is_admin('moderator'))
with check (private.is_admin('moderator'));
