drop policy if exists "Hairmap users upload own media" on storage.objects;
create policy "Hairmap users upload own media" on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'hairmap-media'
  and (storage.foldername(name))[1] = 'uploads'
  and lower((storage.foldername(name))[2]) = lower((select auth.uid())::text)
);

drop policy if exists "Hairmap users update own media" on storage.objects;
create policy "Hairmap users update own media" on storage.objects
for update
to authenticated
using (
  bucket_id = 'hairmap-media'
  and owner = (select auth.uid())
)
with check (
  bucket_id = 'hairmap-media'
  and (storage.foldername(name))[1] = 'uploads'
  and lower((storage.foldername(name))[2]) = lower((select auth.uid())::text)
);
