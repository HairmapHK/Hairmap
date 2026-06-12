-- Hairmap staging-only cleanup.
-- Run this only on a disposable staging Supabase project before/after public beta tests.
-- Do not run this on the production project.

begin;

delete from public.blocked_slots;
delete from public.messages;
delete from public.bookings;
delete from public.inspiration_comment_reactions;
delete from public.inspiration_comments;
delete from public.inspiration_reactions;
delete from public.inspiration_items where id like 'shared-%' or id like 'look-%';
delete from public.reviews where reviewer_name in ('訪客', 'Hairmap Guest') or created_at > now() - interval '90 days';
delete from public.stylist_applications;
delete from public.salon_applications;
delete from public.reports;

commit;
