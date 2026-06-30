alter table public.portfolio_works
  add column if not exists media_kind text not null default 'photo',
  add column if not exists video_url text not null default '',
  add column if not exists thumbnail_url text not null default '';

alter table public.salon_portfolio_works
  add column if not exists media_kind text not null default 'photo',
  add column if not exists video_url text not null default '',
  add column if not exists thumbnail_url text not null default '';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'portfolio_works_media_kind_check'
      and conrelid = 'public.portfolio_works'::regclass
  ) then
    alter table public.portfolio_works
      add constraint portfolio_works_media_kind_check
      check (media_kind in ('photo', 'video'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'salon_portfolio_works_media_kind_check'
      and conrelid = 'public.salon_portfolio_works'::regclass
  ) then
    alter table public.salon_portfolio_works
      add constraint salon_portfolio_works_media_kind_check
      check (media_kind in ('photo', 'video'));
  end if;
end $$;

update public.portfolio_works
set thumbnail_url = image_url
where thumbnail_url = ''
  and image_url <> '';

update public.salon_portfolio_works
set thumbnail_url = image_url
where thumbnail_url = ''
  and image_url <> '';
