# Hairmap Beta Operations Playbook

This playbook is for the period before App Store launch.

## Current Constraint

Without an active Apple Developer Program membership, Hairmap can continue to be built and tested on Simulator, but TestFlight and App Store upload remain blocked.

## Environments

Use separate Supabase projects before public testing:

- Staging: TestFlight, Threads beta campaigns, meme/UGC experiments, destructive cleanup.
- Production: real customer/stylist/salon records for App Store launch.

The admin panel shows the active app environment. Debug builds currently label themselves as `development`; Release builds label themselves as `production`.

## Private Device Test

When Apple membership is available:

1. Create the App Store Connect app record.
2. Archive and upload build `1`.
3. Test on your own iPhone first.
4. Verify Google/Apple/email login.
5. Create a customer booking.
6. Confirm the stylist dashboard receives the booking.
7. Send stylist-to-customer and customer-to-stylist messages.
8. Upload inspiration media and review photos.
9. Approve/reject a stylist and salon submission from admin.

## Public TestFlight Campaign

Recommended rollout:

- Wave 1: 10 trusted testers
- Wave 2: 30-50 testers
- Wave 3: public link capped at 100 testers

Keep meme/UGC seed data on staging only. Before App Store launch, expire the external testing build and close the public link.

## Feedback Form Fields

Collect feedback with a simple form:

- Tester name or handle
- Device model
- iOS version
- Login method used
- Which screen failed
- What they expected
- What happened
- Screenshot/video upload
- Would they use this for real booking?
- Are they a customer, stylist, or salon owner?

## Stylist Data Collection

For real launch inventory, collect:

- Stylist display name
- Salon name
- District
- Title/specialty
- Languages
- Experience
- Service list and prices
- Portfolio photos
- Avatar/headshot
- Instagram/portfolio URL
- Consent to publish on Hairmap

Import cleaned records with:

```sh
python3 tools/generate_catalog_seed_sql.py \
  --salons templates/salon_import_template.csv \
  --stylists templates/stylist_import_template.csv > /tmp/hairmap_seed.sql
```

Run the generated SQL in the target Supabase project only after reviewing it.

## Staging Cleanup

Run `supabase/maintenance/reset_staging_test_data.sql` only on staging. Never run it on production.
