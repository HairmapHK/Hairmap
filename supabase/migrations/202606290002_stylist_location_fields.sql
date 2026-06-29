alter table public.stylists
  add column if not exists location text not null default '';

alter table public.stylist_applications
  add column if not exists location text not null default '';

update public.stylist_applications as application
set location = candidate.location
from (
  select
    id,
    trim(coalesce(
      nullif(substring(admin_note from '工作室 / 服務地址：([^[:cntrl:]]+)'), ''),
      nullif(substring(admin_note from '工作室 / 沙龍：([^[:cntrl:]]+)'), ''),
      ''
    )) as location
  from public.stylist_applications
) as candidate
where application.id = candidate.id
  and application.location = ''
  and candidate.location not in ('', '未提供');

update public.stylists as stylist
set location = application.location
from public.stylist_applications as application
where stylist.id = application.stylist_id
  and stylist.location = ''
  and application.location <> ''
  and application.status = 'approved';

update public.stylists as stylist
set location = salon.location
from public.salons as salon
where stylist.salon_id = salon.id
  and stylist.location = ''
  and salon.location <> ''
  and salon.location <> '香港';
