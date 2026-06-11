insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'hairmap-media',
  'hairmap-media',
  true,
  52428800,
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
    'video/mp4',
    'video/quicktime'
  ]
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

grant select on storage.objects to anon;
grant select, insert, update, delete on storage.objects to authenticated;

drop policy if exists "Hairmap media public read" on storage.objects;
drop policy if exists "Hairmap users read own media metadata" on storage.objects;
create policy "Hairmap users read own media metadata" on storage.objects
for select
to authenticated
using (
  bucket_id = 'hairmap-media'
  and owner = (select auth.uid())
);

drop policy if exists "Hairmap users upload own media" on storage.objects;
create policy "Hairmap users upload own media" on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'hairmap-media'
  and (storage.foldername(name))[1] = 'uploads'
  and (storage.foldername(name))[2] = (select auth.uid())::text
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
  and (storage.foldername(name))[2] = (select auth.uid())::text
);

drop policy if exists "Hairmap users delete own media" on storage.objects;
create policy "Hairmap users delete own media" on storage.objects
for delete
to authenticated
using (
  bucket_id = 'hairmap-media'
  and owner = (select auth.uid())
);

alter table public.reviews
  add column if not exists reviewer_id uuid references public.profiles(id) on delete set null;

alter table public.inspiration_items
  add column if not exists author_id uuid references public.profiles(id) on delete set null,
  add column if not exists author_name text not null default '',
  add column if not exists studio text not null default '',
  add column if not exists media_urls text[] not null default '{}',
  add column if not exists media_kinds text[] not null default '{}',
  add column if not exists face_shape text not null default '',
  add column if not exists hair_type text not null default '',
  add column if not exists specs text not null default '',
  add column if not exists details text not null default '',
  add column if not exists is_user_post boolean not null default false;

create index if not exists idx_reviews_reviewer_id on public.reviews(reviewer_id);
create index if not exists idx_reviews_stylist_id on public.reviews(stylist_id);
create index if not exists idx_inspiration_stylist_id on public.inspiration_items(stylist_id);
create index if not exists idx_inspiration_author_id on public.inspiration_items(author_id);
create index if not exists idx_profiles_stylist_id on public.profiles(stylist_id);
create index if not exists idx_bookings_salon_id on public.bookings(salon_id);
create index if not exists idx_bookings_service_id on public.bookings(service_id);
create index if not exists idx_reports_reporter_id on public.reports(reporter_id);
create index if not exists idx_reports_resolved_by on public.reports(resolved_by);
create index if not exists idx_app_settings_updated_by on public.app_settings(updated_by);
create index if not exists idx_audit_logs_actor_id on public.audit_logs(actor_id);

grant insert, update, delete on public.reviews to authenticated;
grant insert, update, delete on public.inspiration_items to authenticated;

drop policy if exists "Authenticated users create reviews" on public.reviews;
create policy "Authenticated users create reviews" on public.reviews
for insert
to authenticated
with check (
  reviewer_id = (select auth.uid())
  and is_hidden = false
  and moderation_status in ('pending', 'approved')
);

drop policy if exists "Users update own reviews" on public.reviews;
create policy "Users update own reviews" on public.reviews
for update
to authenticated
using (reviewer_id = (select auth.uid()))
with check (
  reviewer_id = (select auth.uid())
  and moderation_status in ('pending', 'approved')
);

drop policy if exists "Users delete own reviews" on public.reviews;
create policy "Users delete own reviews" on public.reviews
for delete
to authenticated
using (reviewer_id = (select auth.uid()));

drop policy if exists "Authenticated users create inspiration posts" on public.inspiration_items;
create policy "Authenticated users create inspiration posts" on public.inspiration_items
for insert
to authenticated
with check (
  author_id = (select auth.uid())
  and is_user_post = true
  and is_active = true
);

drop policy if exists "Users update own inspiration posts" on public.inspiration_items;
create policy "Users update own inspiration posts" on public.inspiration_items
for update
to authenticated
using (author_id = (select auth.uid()) and is_user_post = true)
with check (
  author_id = (select auth.uid())
  and is_user_post = true
);

drop policy if exists "Users delete own inspiration posts" on public.inspiration_items;
create policy "Users delete own inspiration posts" on public.inspiration_items
for delete
to authenticated
using (author_id = (select auth.uid()) and is_user_post = true);

create or replace function private.refresh_stylist_review_stats(target_stylist_id text)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.stylists stylist
  set reviews_count = stats.review_count,
      rating = stats.rating
  from (
    select
      count(*)::int as review_count,
      coalesce(round(avg(stars)::numeric, 1), 0)::double precision as rating
    from public.reviews
    where stylist_id = target_stylist_id
      and is_hidden = false
      and moderation_status = 'approved'
  ) stats
  where stylist.id = target_stylist_id;
$$;

create or replace function private.handle_review_stats()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected_stylist_id text;
begin
  affected_stylist_id := coalesce(new.stylist_id, old.stylist_id);
  perform private.refresh_stylist_review_stats(affected_stylist_id);
  return coalesce(new, old);
end;
$$;

revoke all on function private.refresh_stylist_review_stats(text) from public;
revoke all on function private.handle_review_stats() from public;

drop trigger if exists refresh_stylist_review_stats_after_change on public.reviews;
create trigger refresh_stylist_review_stats_after_change
after insert or update or delete on public.reviews
for each row execute function private.handle_review_stats();
