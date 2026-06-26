alter table public.inspiration_items
  add column if not exists author_avatar text not null default '';

update public.inspiration_items item
set author_avatar = coalesce(profile.avatar_url, '')
from public.profiles profile
where item.author_id = profile.id
  and coalesce(item.author_avatar, '') = '';
