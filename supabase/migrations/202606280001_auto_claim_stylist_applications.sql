alter table public.stylist_applications
  add column if not exists contact_email text not null default '',
  add column if not exists claimed_by uuid references public.profiles(id) on delete set null,
  add column if not exists claimed_at timestamptz;

update public.stylist_applications
set contact_email = lower(trim(substring(admin_note from 'Email：([^[:cntrl:]]+)')))
where contact_email = ''
  and admin_note ~ 'Email：';

create index if not exists idx_stylist_applications_contact_email_status
  on public.stylist_applications (lower(trim(contact_email)), status)
  where contact_email <> '';

create index if not exists idx_stylist_applications_claimed_by
  on public.stylist_applications (claimed_by)
  where claimed_by is not null;

drop policy if exists "Public creates pending stylist applications" on public.stylist_applications;
create policy "Public creates pending stylist applications" on public.stylist_applications
for insert
to anon
with check (
  submitted_by is null
  and owner_id is null
  and claimed_by is null
  and claimed_at is null
  and status = 'pending'
  and coalesce(name, '') <> ''
  and coalesce(title, '') <> ''
  and coalesce(avatar_url, '') <> ''
  and coalesce(contact_email, '') <> ''
);

create or replace function public.claim_approved_stylist_application()
returns table (
  claim_status text,
  application_id text,
  stylist_id text
)
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  current_user_id uuid := auth.uid();
  current_email text;
  match_count integer;
  application_row public.stylist_applications%rowtype;
begin
  if current_user_id is null then
    return query select 'not_authenticated'::text, null::text, null::text;
    return;
  end if;

  select lower(trim(users.email))
    into current_email
  from auth.users as users
  where users.id = current_user_id
    and users.email_confirmed_at is not null;

  if current_email is null or current_email = '' then
    return query select 'email_unavailable'::text, null::text, null::text;
    return;
  end if;

  if not exists (
    select 1
    from public.profiles as profile
    where profile.id = current_user_id
      and profile.role = 'stylist'
  ) then
    return query select 'wrong_role'::text, null::text, null::text;
    return;
  end if;

  select count(*)
    into match_count
  from public.stylist_applications as application
  where application.status = 'approved'
    and application.owner_id is null
    and application.claimed_by is null
    and lower(trim(application.contact_email)) = current_email;

  if match_count = 0 then
    return query select 'no_match'::text, null::text, null::text;
    return;
  end if;

  if match_count > 1 then
    return query select 'ambiguous'::text, null::text, null::text;
    return;
  end if;

  select *
    into application_row
  from public.stylist_applications as application
  where application.status = 'approved'
    and application.owner_id is null
    and application.claimed_by is null
    and lower(trim(application.contact_email)) = current_email
  for update;

  if not found then
    return query select 'no_match'::text, null::text, null::text;
    return;
  end if;

  if exists (
    select 1
    from public.stylists as stylist
    where stylist.id = application_row.stylist_id
      and stylist.owner_id is not null
      and stylist.owner_id <> current_user_id
  ) then
    return query select 'already_owned'::text, application_row.id, application_row.stylist_id;
    return;
  end if;

  update public.stylist_applications
  set
    submitted_by = coalesce(submitted_by, current_user_id),
    owner_id = current_user_id,
    claimed_by = current_user_id,
    claimed_at = now(),
    updated_at = now()
  where id = application_row.id
    and owner_id is null
    and claimed_by is null;

  update public.stylists
  set
    owner_id = current_user_id,
    updated_at = now()
  where id = application_row.stylist_id
    and (owner_id is null or owner_id = current_user_id);

  update public.profiles
  set
    display_name = application_row.name,
    role = 'stylist',
    stylist_id = application_row.stylist_id,
    avatar_url = application_row.avatar_url,
    updated_at = now()
  where id = current_user_id;

  return query select 'claimed'::text, application_row.id, application_row.stylist_id;
end;
$$;

revoke all on function public.claim_approved_stylist_application() from public;
revoke all on function public.claim_approved_stylist_application() from anon;
grant execute on function public.claim_approved_stylist_application() to authenticated;
