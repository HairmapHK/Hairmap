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

revoke all on function private.refresh_salon_review_stats(text) from public;

update public.salons salon
set reviews_count = stats.review_count,
    rating = case when stats.review_count > 0 then stats.rating else 5 end
from (
  select
    salon.id as salon_id,
    count(review.id)::int as review_count,
    coalesce(round(avg(review.stars)::numeric, 1), 5)::double precision as rating
  from public.salons salon
  left join public.reviews review
    on review.salon_id = salon.id
   and review.is_hidden = false
   and review.moderation_status = 'approved'
  group by salon.id
) stats
where salon.id = stats.salon_id;
