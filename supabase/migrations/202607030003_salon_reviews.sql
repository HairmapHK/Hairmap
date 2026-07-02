alter table public.salons
  add column if not exists reviews_count integer not null default 0;

alter table public.reviews
  alter column stylist_id drop not null,
  add column if not exists salon_id text references public.salons(id) on delete cascade;

create index if not exists idx_reviews_salon_id on public.reviews(salon_id);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'reviews_exactly_one_target_check'
      and conrelid = 'public.reviews'::regclass
  ) then
    alter table public.reviews
      add constraint reviews_exactly_one_target_check
      check (
        (stylist_id is not null and salon_id is null)
        or (stylist_id is null and salon_id is not null)
      );
  end if;
end $$;

create or replace function private.refresh_salon_review_stats(target_salon_id text)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.salons salon
  set reviews_count = stats.review_count,
      rating = case when stats.review_count > 0 then stats.rating else 5 end
  from (
    select
      count(*)::int as review_count,
      coalesce(round(avg(stars)::numeric, 1), 5)::double precision as rating
    from public.reviews
    where salon_id = target_salon_id
      and is_hidden = false
      and moderation_status = 'approved'
  ) stats
  where salon.id = target_salon_id;
$$;

create or replace function private.handle_review_stats()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  old_stylist_id text;
  new_stylist_id text;
  old_salon_id text;
  new_salon_id text;
begin
  old_stylist_id := case when tg_op in ('UPDATE', 'DELETE') then old.stylist_id else null end;
  new_stylist_id := case when tg_op in ('INSERT', 'UPDATE') then new.stylist_id else null end;
  old_salon_id := case when tg_op in ('UPDATE', 'DELETE') then old.salon_id else null end;
  new_salon_id := case when tg_op in ('INSERT', 'UPDATE') then new.salon_id else null end;

  if old_stylist_id is not null then
    perform private.refresh_stylist_review_stats(old_stylist_id);
  end if;

  if new_stylist_id is not null and new_stylist_id is distinct from old_stylist_id then
    perform private.refresh_stylist_review_stats(new_stylist_id);
  end if;

  if old_salon_id is not null then
    perform private.refresh_salon_review_stats(old_salon_id);
  end if;

  if new_salon_id is not null and new_salon_id is distinct from old_salon_id then
    perform private.refresh_salon_review_stats(new_salon_id);
  end if;

  return coalesce(new, old);
end;
$$;

revoke all on function private.refresh_salon_review_stats(text) from public;
revoke all on function private.handle_review_stats() from public;

update public.salons salon
set reviews_count = stats.review_count,
    rating = stats.rating
from (
  select
    salon_id,
    count(*)::int as review_count,
    coalesce(round(avg(stars)::numeric, 1), 5)::double precision as rating
  from public.reviews
  where salon_id is not null
    and is_hidden = false
    and moderation_status = 'approved'
  group by salon_id
) stats
where salon.id = stats.salon_id;
