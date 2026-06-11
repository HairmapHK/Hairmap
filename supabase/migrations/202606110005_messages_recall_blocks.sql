alter table public.messages
  add column if not exists is_recalled boolean not null default false,
  add column if not exists recalled_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

drop trigger if exists touch_messages_updated_at on public.messages;
create trigger touch_messages_updated_at
before update on public.messages
for each row execute function public.touch_updated_at();

grant update on public.messages to authenticated;

drop policy if exists "Participants recall own messages" on public.messages;
create policy "Participants recall own messages" on public.messages
for update to authenticated
using (
  (
    sender_role = 'customer'
    and customer_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.stylists stylist
    where stylist.id = messages.stylist_id
      and stylist.owner_id = (select auth.uid())
      and messages.sender_role = 'stylist'
  )
)
with check (
  (
    sender_role = 'customer'
    and customer_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.stylists stylist
    where stylist.id = messages.stylist_id
      and stylist.owner_id = (select auth.uid())
      and messages.sender_role = 'stylist'
  )
);

create table if not exists public.conversation_blocks (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete cascade,
  stylist_id text not null references public.stylists(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (customer_id, stylist_id)
);

drop trigger if exists touch_conversation_blocks_updated_at on public.conversation_blocks;
create trigger touch_conversation_blocks_updated_at
before update on public.conversation_blocks
for each row execute function public.touch_updated_at();

create index if not exists idx_conversation_blocks_customer on public.conversation_blocks(customer_id, stylist_id);
create index if not exists idx_conversation_blocks_stylist on public.conversation_blocks(stylist_id);

alter table public.conversation_blocks enable row level security;

grant select, insert, update, delete on public.conversation_blocks to authenticated;

drop policy if exists "Customers manage own conversation blocks" on public.conversation_blocks;
create policy "Customers manage own conversation blocks" on public.conversation_blocks
for all to authenticated
using (customer_id = (select auth.uid()))
with check (customer_id = (select auth.uid()));

drop policy if exists "Stylists read blocks involving them" on public.conversation_blocks;
create policy "Stylists read blocks involving them" on public.conversation_blocks
for select to authenticated
using (
  exists (
    select 1
    from public.stylists stylist
    where stylist.id = conversation_blocks.stylist_id
      and stylist.owner_id = (select auth.uid())
  )
);
