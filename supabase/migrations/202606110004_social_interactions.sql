create table if not exists public.inspiration_comments (
  id text primary key,
  inspiration_id text not null references public.inspiration_items(id) on delete cascade,
  parent_id text references public.inspiration_comments(id) on delete cascade,
  author_id uuid references public.profiles(id) on delete set null,
  author_name text not null,
  author_avatar text not null default '',
  body text not null,
  like_count integer not null default 0,
  is_creator boolean not null default false,
  is_hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.inspiration_reactions (
  id uuid primary key default gen_random_uuid(),
  inspiration_id text not null references public.inspiration_items(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  reaction_type text not null default 'like' check (reaction_type in ('like')),
  created_at timestamptz not null default now(),
  unique (inspiration_id, user_id, reaction_type)
);

create table if not exists public.inspiration_comment_reactions (
  id uuid primary key default gen_random_uuid(),
  comment_id text not null references public.inspiration_comments(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  reaction_type text not null default 'like' check (reaction_type in ('like')),
  created_at timestamptz not null default now(),
  unique (comment_id, user_id, reaction_type)
);

create table if not exists public.inspiration_shares (
  id uuid primary key default gen_random_uuid(),
  inspiration_id text not null references public.inspiration_items(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

drop trigger if exists touch_inspiration_comments_updated_at on public.inspiration_comments;
create trigger touch_inspiration_comments_updated_at
before update on public.inspiration_comments
for each row execute function public.touch_updated_at();

create index if not exists idx_inspiration_comments_item on public.inspiration_comments(inspiration_id, is_hidden, created_at desc);
create index if not exists idx_inspiration_comments_parent on public.inspiration_comments(parent_id, created_at);
create index if not exists idx_inspiration_reactions_user on public.inspiration_reactions(user_id, inspiration_id);
create index if not exists idx_inspiration_comment_reactions_user on public.inspiration_comment_reactions(user_id, comment_id);
create index if not exists idx_inspiration_shares_item on public.inspiration_shares(inspiration_id, created_at desc);

alter table public.inspiration_comments enable row level security;
alter table public.inspiration_reactions enable row level security;
alter table public.inspiration_comment_reactions enable row level security;
alter table public.inspiration_shares enable row level security;

grant select on public.inspiration_comments to anon, authenticated;
grant select, insert, update, delete on public.inspiration_comments to authenticated;
grant select, insert, delete on public.inspiration_reactions to authenticated;
grant select, insert, delete on public.inspiration_comment_reactions to authenticated;
grant insert on public.inspiration_shares to anon, authenticated;
grant select, insert, delete on public.inspiration_shares to authenticated;

drop policy if exists "Public reads visible inspiration comments" on public.inspiration_comments;
create policy "Public reads visible inspiration comments" on public.inspiration_comments
for select
to anon, authenticated
using (is_hidden = false);

drop policy if exists "Users create own inspiration comments" on public.inspiration_comments;
create policy "Users create own inspiration comments" on public.inspiration_comments
for insert
to authenticated
with check (
  author_id = (select auth.uid())
  and is_hidden = false
);

drop policy if exists "Users update own inspiration comments" on public.inspiration_comments;
create policy "Users update own inspiration comments" on public.inspiration_comments
for update
to authenticated
using (author_id = (select auth.uid()) or private.is_admin('moderator'))
with check (author_id = (select auth.uid()) or private.is_admin('moderator'));

drop policy if exists "Users delete own inspiration comments" on public.inspiration_comments;
create policy "Users delete own inspiration comments" on public.inspiration_comments
for delete
to authenticated
using (author_id = (select auth.uid()) or private.is_admin('moderator'));

drop policy if exists "Users read own inspiration reactions" on public.inspiration_reactions;
create policy "Users read own inspiration reactions" on public.inspiration_reactions
for select
to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "Users create own inspiration reactions" on public.inspiration_reactions;
create policy "Users create own inspiration reactions" on public.inspiration_reactions
for insert
to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "Users delete own inspiration reactions" on public.inspiration_reactions;
create policy "Users delete own inspiration reactions" on public.inspiration_reactions
for delete
to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "Users read own comment reactions" on public.inspiration_comment_reactions;
create policy "Users read own comment reactions" on public.inspiration_comment_reactions
for select
to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "Users create own comment reactions" on public.inspiration_comment_reactions;
create policy "Users create own comment reactions" on public.inspiration_comment_reactions
for insert
to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "Users delete own comment reactions" on public.inspiration_comment_reactions;
create policy "Users delete own comment reactions" on public.inspiration_comment_reactions
for delete
to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "Users create inspiration shares" on public.inspiration_shares;
create policy "Users create inspiration shares" on public.inspiration_shares
for insert
to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "Anon creates inspiration shares" on public.inspiration_shares;
create policy "Anon creates inspiration shares" on public.inspiration_shares
for insert
to anon
with check (user_id is null);

drop policy if exists "Users read own inspiration shares" on public.inspiration_shares;
create policy "Users read own inspiration shares" on public.inspiration_shares
for select
to authenticated
using (user_id = (select auth.uid()) or private.is_admin('moderator'));

create or replace function private.refresh_inspiration_counts(target_inspiration_id text)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.inspiration_items item
  set comment_count = (
        select count(*)::int
        from public.inspiration_comments comment
        where comment.inspiration_id = target_inspiration_id
          and comment.is_hidden = false
      ),
      like_count = (
        select count(*)::int
        from public.inspiration_reactions reaction
        where reaction.inspiration_id = target_inspiration_id
          and reaction.reaction_type = 'like'
      ),
      share_count = (
        select count(*)::int
        from public.inspiration_shares share
        where share.inspiration_id = target_inspiration_id
      )
  where item.id = target_inspiration_id;
$$;

create or replace function private.refresh_comment_like_count(target_comment_id text)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.inspiration_comments comment
  set like_count = (
        select count(*)::int
        from public.inspiration_comment_reactions reaction
        where reaction.comment_id = target_comment_id
          and reaction.reaction_type = 'like'
      )
  where comment.id = target_comment_id;
$$;

create or replace function private.handle_inspiration_comment_counts()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected_id text;
begin
  affected_id := coalesce(new.inspiration_id, old.inspiration_id);
  perform private.refresh_inspiration_counts(affected_id);
  return coalesce(new, old);
end;
$$;

create or replace function private.handle_inspiration_reaction_counts()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected_id text;
begin
  affected_id := coalesce(new.inspiration_id, old.inspiration_id);
  perform private.refresh_inspiration_counts(affected_id);
  return coalesce(new, old);
end;
$$;

create or replace function private.handle_comment_reaction_counts()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected_id text;
begin
  affected_id := coalesce(new.comment_id, old.comment_id);
  perform private.refresh_comment_like_count(affected_id);
  return coalesce(new, old);
end;
$$;

revoke all on function private.refresh_inspiration_counts(text) from public;
revoke all on function private.refresh_comment_like_count(text) from public;
revoke all on function private.handle_inspiration_comment_counts() from public;
revoke all on function private.handle_inspiration_reaction_counts() from public;
revoke all on function private.handle_comment_reaction_counts() from public;

drop trigger if exists refresh_inspiration_counts_after_comments on public.inspiration_comments;
create trigger refresh_inspiration_counts_after_comments
after insert or update or delete on public.inspiration_comments
for each row execute function private.handle_inspiration_comment_counts();

drop trigger if exists refresh_inspiration_counts_after_reactions on public.inspiration_reactions;
create trigger refresh_inspiration_counts_after_reactions
after insert or delete on public.inspiration_reactions
for each row execute function private.handle_inspiration_reaction_counts();

drop trigger if exists refresh_inspiration_counts_after_shares on public.inspiration_shares;
create trigger refresh_inspiration_counts_after_shares
after insert or delete on public.inspiration_shares
for each row execute function private.handle_inspiration_reaction_counts();

drop trigger if exists refresh_comment_likes_after_reactions on public.inspiration_comment_reactions;
create trigger refresh_comment_likes_after_reactions
after insert or delete on public.inspiration_comment_reactions
for each row execute function private.handle_comment_reaction_counts();
