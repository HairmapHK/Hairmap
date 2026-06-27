create table if not exists public.message_read_receipts (
  id uuid primary key default gen_random_uuid(),
  message_id text not null references public.messages(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  read_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (message_id, profile_id)
);

drop trigger if exists touch_message_read_receipts_updated_at on public.message_read_receipts;
create trigger touch_message_read_receipts_updated_at
before update on public.message_read_receipts
for each row execute function public.touch_updated_at();

create index if not exists idx_message_read_receipts_profile on public.message_read_receipts(profile_id);
create index if not exists idx_message_read_receipts_message on public.message_read_receipts(message_id);

alter table public.message_read_receipts enable row level security;

grant select, insert, update on public.message_read_receipts to authenticated;

drop policy if exists "Users read own message read receipts" on public.message_read_receipts;
create policy "Users read own message read receipts" on public.message_read_receipts
for select
to authenticated
using (profile_id = (select auth.uid()));

drop policy if exists "Users insert own message read receipts" on public.message_read_receipts;
create policy "Users insert own message read receipts" on public.message_read_receipts
for insert
to authenticated
with check (
  profile_id = (select auth.uid())
  and exists (
    select 1
    from public.messages as message
    where message.id = message_read_receipts.message_id
      and (
        message.customer_id = (select auth.uid())
        or exists (
          select 1
          from public.stylists as stylist
          where stylist.id = message.stylist_id
            and stylist.owner_id = (select auth.uid())
        )
      )
  )
);

drop policy if exists "Users update own message read receipts" on public.message_read_receipts;
create policy "Users update own message read receipts" on public.message_read_receipts
for update
to authenticated
using (profile_id = (select auth.uid()))
with check (
  profile_id = (select auth.uid())
  and exists (
    select 1
    from public.messages as message
    where message.id = message_read_receipts.message_id
      and (
        message.customer_id = (select auth.uid())
        or exists (
          select 1
          from public.stylists as stylist
          where stylist.id = message.stylist_id
            and stylist.owner_id = (select auth.uid())
        )
      )
  )
);
