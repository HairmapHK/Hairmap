alter table public.profiles
  add column if not exists avatar_url text not null default '';

alter table public.reviews
  add column if not exists review_photo_url text;

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name, email, role, stylist_id, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1), 'Hairmap User'),
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'role', 'customer'),
    nullif(new.raw_user_meta_data ->> 'stylist_id', ''),
    coalesce(new.raw_user_meta_data ->> 'avatar_url', new.raw_user_meta_data ->> 'picture', '')
  )
  on conflict (id) do update set
    email = excluded.email,
    display_name = coalesce(nullif(public.profiles.display_name, ''), excluded.display_name),
    role = coalesce(nullif(public.profiles.role, ''), excluded.role),
    stylist_id = coalesce(public.profiles.stylist_id, excluded.stylist_id),
    avatar_url = coalesce(nullif(public.profiles.avatar_url, ''), excluded.avatar_url);
  return new;
end;
$$ language plpgsql security definer;
