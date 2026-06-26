-- Enable Supabase Realtime for Hairmap tables that drive live customer/stylist UX.
do $$
declare
  live_table text;
  live_tables text[] := array[
    'profiles',
    'stylists',
    'salons',
    'services',
    'portfolio_works',
    'salon_portfolio_works',
    'reviews',
    'bookings',
    'messages',
    'blocked_slots',
    'conversation_blocks',
    'inspiration_items',
    'inspiration_comments',
    'inspiration_reactions',
    'inspiration_comment_reactions',
    'inspiration_shares',
    'stylist_applications',
    'salon_applications',
    'ranking_overrides'
  ];
begin
  foreach live_table in array live_tables loop
    if exists (
      select 1
      from information_schema.tables
      where table_schema = 'public'
        and table_name = live_table
    ) and not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = live_table
    ) then
      execute format('alter publication supabase_realtime add table public.%I', live_table);
    end if;
  end loop;
end $$;
