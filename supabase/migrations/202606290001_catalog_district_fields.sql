alter table public.salons
  add column if not exists district text not null default '';

alter table public.stylists
  add column if not exists district text not null default '';

alter table public.stylist_applications
  add column if not exists district text not null default '';

alter table public.salon_applications
  add column if not exists district text not null default '';

create index if not exists idx_salons_district
  on public.salons (district)
  where district <> '';

create index if not exists idx_stylists_district
  on public.stylists (district)
  where district <> '';

create index if not exists idx_stylist_applications_district_status
  on public.stylist_applications (district, status)
  where district <> '';

create index if not exists idx_salon_applications_district_status
  on public.salon_applications (district, status)
  where district <> '';

do $$
declare
  districts text[] := array[
    '堅尼地城', '西營盤', '上環', '中環', '金鐘', '灣仔', '銅鑼灣', '天后',
    '北角', '鰂魚涌', '太古', '西灣河', '筲箕灣', '柴灣', '香港仔', '黃竹坑',
    '鴨脷洲', '赤柱',
    '尖沙咀', '佐敦', '油麻地', '旺角', '太子', '深水埗', '長沙灣', '荔枝角',
    '九龍塘', '石硤尾', '何文田', '土瓜灣', '紅磡', '黃埔', '九龍城', '樂富',
    '黃大仙', '鑽石山', '彩虹', '九龍灣', '牛頭角', '觀塘', '藍田', '油塘',
    '荃灣', '葵芳', '青衣', '沙田', '大圍', '火炭', '馬鞍山', '大埔',
    '粉嶺', '上水', '元朗', '天水圍', '屯門', '將軍澳', '坑口', '寶琳',
    '西貢', '清水灣',
    '東涌', '愉景灣', '迪士尼', '長洲', '坪洲', '南丫島', '梅窩', '大澳'
  ];
begin
  update public.salon_applications as application
  set district = coalesce(
    (
      select candidate
      from unnest(districts) as district_name(candidate)
      where application.location like '%' || candidate || '%'
         or application.admin_note like '%' || candidate || '%'
      order by length(candidate) desc
      limit 1
    ),
    district
  )
  where application.district = '';

  update public.stylist_applications as application
  set district = coalesce(
    (
      select candidate
      from unnest(districts) as district_name(candidate)
      where application.admin_note like '%' || candidate || '%'
      order by length(candidate) desc
      limit 1
    ),
    district
  )
  where application.district = '';

  update public.salons as salon
  set district = coalesce(
    (
      select candidate
      from unnest(districts) as district_name(candidate)
      where salon.location like '%' || candidate || '%'
      order by length(candidate) desc
      limit 1
    ),
    salon.district
  )
  where salon.district = '';

  update public.salons as salon
  set district = application.district
  from public.salon_applications as application
  where salon.id = application.salon_id
    and salon.district = ''
    and application.district <> ''
    and application.status = 'approved';

  update public.stylists as stylist
  set district = application.district
  from public.stylist_applications as application
  where stylist.id = application.stylist_id
    and stylist.district = ''
    and application.district <> ''
    and application.status = 'approved';

  update public.stylists as stylist
  set district = salon.district
  from public.salons as salon
  where stylist.salon_id = salon.id
    and stylist.district = ''
    and salon.district <> '';
end $$;
