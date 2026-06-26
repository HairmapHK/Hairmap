# Hairmap Supabase Environments

Hairmap now reads `APP_ENVIRONMENT`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, and `SUPABASE_REDIRECT_URL` from the app bundle. The admin panel shows the active environment so you can see whether a build is using staging or production before approving records.

## Recommended Setup

Use two Supabase projects:

- `Hairmap Staging`: for simulator, personal device testing, TestFlight, meme/UGC experiments, and destructive reset scripts.
- `Hairmap Production`: for App Store users and real salon/stylist records.

Current mapping:

```text
STAGING / TESTFLIGHT
Project: existing beta project
URL: https://khmeqbcevlkwvgehvuni.supabase.co
Purpose: simulator, TestFlight, public beta, UGC/meme testing

PRODUCTION / APP STORE
Project: Hairmap Production
Ref: hdywclmsnfegaqtgndva
URL: https://hdywclmsnfegaqtgndva.supabase.co
Purpose: App Store users and approved real catalog data only
```

Production is intentionally clean at creation time. Do not point App Store builds at production until migrations, Auth providers, Storage, admin user, and real catalog data are configured.

## Create / Maintain Staging

1. Use the existing beta project `khmeqbcevlkwvgehvuni`.
2. Keep TestFlight and public beta builds on this project.
3. Apply new SQL files in `supabase/migrations/` in filename order when schema changes.
4. Keep the `hairmap-media` Storage bucket available.
5. Add Auth redirect URLs:
   - `hairmap://auth-callback`
   - the Supabase callback URL required by Google OAuth
6. Enable the same Auth providers as production.
7. Keep your own user in `public.admin_users` as `super_admin`.

## Prepare Production

1. Use project `hdywclmsnfegaqtgndva`.
2. Apply the production schema without demo catalog seed data.
3. Create or verify the `hairmap-media` Storage bucket and media policies.
4. Add these Auth redirect URLs:
   - `hairmap://auth-callback`
   - the Supabase callback URL required by Google OAuth
5. Enable Email, Google, and Apple Auth providers.
6. Sign in once with the owner admin email in production, then add that user to `public.admin_users` as `super_admin`.
7. Import only approved real stylists and salons.
8. Run security advisors and smoke test auth, bookings, messages, storage uploads, admin approvals, reports, and realtime before App Store release.

## Xcode Config

Copy the examples and fill in the real values:

```sh
cp Config/Supabase-Staging.xcconfig.example Config/Supabase-Staging.xcconfig
cp Config/Supabase-Production.xcconfig.example Config/Supabase-Production.xcconfig
```

Do not commit the filled `.xcconfig` files if you later add private keys or non-public service settings. The iOS app only needs publishable keys.

For now the project still has the existing production publishable key in build settings, so builds continue to work. After staging exists, point Debug/TestFlight builds at the staging values and keep App Store Release builds on production.

## Admin Web Config

The admin web panel also uses environment-specific Supabase values:

```sh
cd admin-web
cp .env.staging.example .env.local
```

For production deployment:

```sh
cp .env.production.example .env.local
```

When deploying to Vercel/Netlify/Cloudflare Pages, set the same variables in the host dashboard instead of relying on local `.env.local`:

```text
VITE_SUPABASE_URL
VITE_SUPABASE_PUBLISHABLE_KEY
```

Never place a Supabase service-role key in the admin web app.

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
