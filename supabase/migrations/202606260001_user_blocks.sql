create table if not exists public.user_blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  source_entity_type text not null default 'profile'
    check (source_entity_type in ('stylist', 'salon', 'review', 'inspiration', 'message', 'profile')),
  source_entity_id text not null default '',
  reason text not null default '',
  details text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (blocker_id, blocked_id)
);

drop trigger if exists touch_user_blocks_updated_at on public.user_blocks;
create trigger touch_user_blocks_updated_at
before update on public.user_blocks
for each row execute function public.touch_updated_at();

create index if not exists idx_user_blocks_blocker on public.user_blocks(blocker_id, blocked_id);
create index if not exists idx_user_blocks_blocked on public.user_blocks(blocked_id);
create index if not exists idx_user_blocks_source on public.user_blocks(source_entity_type, source_entity_id);

alter table public.user_blocks enable row level security;

revoke all on public.user_blocks from anon;
revoke all on public.user_blocks from authenticated;
grant select, insert, update, delete on public.user_blocks to authenticated;

drop policy if exists "Users manage own user blocks" on public.user_blocks;
create policy "Users manage own user blocks" on public.user_blocks
for all to authenticated
using (blocker_id = (select auth.uid()))
with check (
  blocker_id = (select auth.uid())
  and blocked_id <> (select auth.uid())
);

drop policy if exists "Admins read user blocks" on public.user_blocks;
create policy "Admins read user blocks" on public.user_blocks
for select to authenticated
using (private.is_admin('moderator'));

do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'user_blocks'
  ) then
    alter publication supabase_realtime add table public.user_blocks;
  end if;
end $$;
