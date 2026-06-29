alter table public.stylists
  add column if not exists instagram_url text not null default '';

alter table public.salons
  add column if not exists instagram_url text not null default '';

alter table public.stylist_applications
  add column if not exists instagram_url text not null default '';

alter table public.salon_applications
  add column if not exists instagram_url text not null default '';

update public.stylists
set instagram_url = ''
where instagram_url is null;

update public.salons
set instagram_url = ''
where instagram_url is null;

update public.stylist_applications
set instagram_url = ''
where instagram_url is null;

update public.salon_applications
set instagram_url = ''
where instagram_url is null;
