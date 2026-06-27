update public.stylist_applications as application
set contact_email = lower(trim(profile.email))
from public.profiles as profile
where application.contact_email = ''
  and profile.id = coalesce(application.owner_id, application.submitted_by)
  and coalesce(profile.email, '') <> '';

update public.stylist_applications
set contact_email = lower(trim(substring(admin_note from '([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,})')))
where contact_email = ''
  and admin_note ~ '([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,})';
