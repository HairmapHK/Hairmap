# Hairmap Supabase Environments

Hairmap now reads `APP_ENVIRONMENT`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, and `SUPABASE_REDIRECT_URL` from the app bundle. The admin panel shows the active environment so you can see whether a build is using staging or production before approving records.

## Recommended Setup

Use two Supabase projects:

- `Hairmap Staging`: for simulator, personal device testing, TestFlight, meme/UGC experiments, and destructive reset scripts.
- `Hairmap Production`: for App Store users and real salon/stylist records.

The current connected project can stay as production until a staging project is created:

```text
https://khmeqbcevlkwvgehvuni.supabase.co
```

## Create Staging

1. Create a new Supabase project named `Hairmap Staging`.
2. Apply every SQL file in `supabase/migrations/` in filename order.
3. Create the `hairmap-media` Storage bucket.
4. Add these Auth redirect URLs:
   - `hairmap://auth-callback`
   - the Supabase callback URL required by Google OAuth
5. Enable the same Auth providers as production.
6. Add your own user to `public.admin_users` as `super_admin`.

## Xcode Config

Copy the examples and fill in the real values:

```sh
cp Config/Supabase-Staging.xcconfig.example Config/Supabase-Staging.xcconfig
cp Config/Supabase-Production.xcconfig.example Config/Supabase-Production.xcconfig
```

Do not commit the filled `.xcconfig` files if you later add private keys or non-public service settings. The iOS app only needs publishable keys.

For now the project still has the existing production publishable key in build settings, so builds continue to work. After staging exists, point Debug/TestFlight builds at the staging values and keep App Store Release builds on production.

## Import Real Catalog Data

Fill these CSV templates:

- `templates/salon_import_template.csv`
- `templates/stylist_import_template.csv`

Generate SQL:

```sh
python3 tools/generate_catalog_seed_sql.py \
  --salons templates/salon_import_template.csv \
  --stylists templates/stylist_import_template.csv > /tmp/hairmap_seed.sql
```

Review `/tmp/hairmap_seed.sql`, then run it in Supabase SQL Editor for the target project. The script uses `insert ... on conflict` so rerunning it updates the same salon/stylist/service/portfolio IDs.

## Reset Public Test Data

Only on staging, run:

```text
supabase/maintenance/reset_staging_test_data.sql
```

This clears beta bookings, messages, applications, reports, guest reviews, and uploaded shared inspiration records. Never run it on production.
