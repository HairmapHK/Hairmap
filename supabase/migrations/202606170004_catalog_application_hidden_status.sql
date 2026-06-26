alter table public.stylist_applications
  drop constraint if exists stylist_applications_status_check;

alter table public.stylist_applications
  add constraint stylist_applications_status_check
  check (status in ('pending', 'approved', 'rejected', 'hidden'));

alter table public.salon_applications
  drop constraint if exists salon_applications_status_check;

alter table public.salon_applications
  add constraint salon_applications_status_check
  check (status in ('pending', 'approved', 'rejected', 'hidden'));
