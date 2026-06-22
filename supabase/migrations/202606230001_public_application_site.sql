insert into public.salons (
  id,
  name,
  location,
  distance,
  rating,
  tags,
  open_hours,
  phone,
  start_price,
  image_url,
  is_active,
  is_featured,
  display_order,
  admin_note
)
values (
  'independent-stylist-studio',
  'Hairmap 獨立髮型師',
  '香港',
  0,
  0,
  array['獨立髮型師'],
  '按髮型師安排',
  '',
  0,
  '',
  false,
  false,
  999,
  '系統隱藏項目：公開申請網站用於未有沙龍檔案的髮型師申請。'
)
on conflict (id) do update
set
  is_active = false,
  is_featured = false,
  display_order = 999,
  admin_note = excluded.admin_note,
  updated_at = now();

grant insert on public.stylist_applications, public.salon_applications to anon;
grant insert on storage.objects to anon;

drop policy if exists "Public creates pending stylist applications" on public.stylist_applications;
create policy "Public creates pending stylist applications" on public.stylist_applications
for insert
to anon
with check (
  submitted_by is null
  and owner_id is null
  and status = 'pending'
  and coalesce(name, '') <> ''
  and coalesce(title, '') <> ''
  and coalesce(avatar_url, '') <> ''
);

drop policy if exists "Public creates pending salon applications" on public.salon_applications;
create policy "Public creates pending salon applications" on public.salon_applications
for insert
to anon
with check (
  submitted_by is null
  and status = 'pending'
  and coalesce(name, '') <> ''
  and coalesce(location, '') <> ''
  and coalesce(phone, '') <> ''
  and coalesce(image_url, '') <> ''
);

drop policy if exists "Public uploads application media" on storage.objects;
create policy "Public uploads application media" on storage.objects
for insert
to anon
with check (
  bucket_id = 'hairmap-media'
  and (storage.foldername(name))[1] = 'public-applications'
);
