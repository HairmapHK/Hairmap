update public.stylist_applications as application
set
  status = 'hidden',
  reviewed_at = coalesce(application.reviewed_at, now())
where application.status = 'approved'
  and exists (
    select 1
    from public.stylists as stylist
    where stylist.id = application.stylist_id
      and stylist.is_active = false
  );

update public.salon_applications as application
set
  status = 'hidden',
  reviewed_at = coalesce(application.reviewed_at, now())
where application.status = 'approved'
  and exists (
    select 1
    from public.salons as salon
    where salon.id = application.salon_id
      and salon.is_active = false
  );
