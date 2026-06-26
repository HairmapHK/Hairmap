alter table public.stylists
  add column if not exists phone text not null default '';

alter table public.stylist_applications
  add column if not exists phone text not null default '';

update public.stylists
set phone = ''
where phone is null;

update public.stylist_applications
set phone = ''
where phone is null;
