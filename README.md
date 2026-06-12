# Hairmap iOS

SwiftUI rewrite of the AI Studio Hairmap web app. The iOS version keeps the same dual-role flow:

- Customer: onboarding, discovery, inspiration, stylist profile, salon profile, booking, chat, profile/history.
- Stylist: bookings, messages, schedule, profile card editor.
- Supabase: Auth magic link, PostgREST persistence, RLS migration, seed catalog.

## Run

Open `Hairmap.xcodeproj` in Xcode 26.2 or newer and run the `Hairmap` scheme.

Without Supabase settings, the app runs in local seed-data mode so the full UX is still testable.

Run the local validation/build check:

```sh
tools/ci_check.sh
```

## Supabase Setup

1. Create a Supabase project.
2. Run `supabase/migrations/202606080001_hairmap_schema.sql` in SQL Editor or via the Supabase CLI.
3. In Supabase Auth settings, add this redirect URL:

```text
hairmap://auth-callback
```

4. In Xcode, add these user-defined build settings to the `Hairmap` target, or pass them as environment variables in the scheme:

```text
SUPABASE_URL = https://YOUR_PROJECT_REF.supabase.co
SUPABASE_PUBLISHABLE_KEY = sb_publishable_YOUR_KEY
SUPABASE_REDIRECT_URL = hairmap://auth-callback
```

`Config/Config.xcconfig.example` contains the same keys as a copyable template.

For staging/production separation, see `SUPABASE_ENVIRONMENTS.md`.

## Release Prep

- `APP_STORE_RELEASE_CHECKLIST.md`: App Store readiness checklist.
- `TESTFLIGHT_RELEASE_GUIDE.md`: TestFlight upload path and signing blocker notes.
- `docs/APP_STORE_METADATA_DRAFT.md`: App Store Connect copy, privacy labels, and reviewer notes draft.
- `docs/BETA_OPERATIONS_PLAYBOOK.md`: staged beta testing and real stylist data collection workflow.

## Notes

- The SwiftUI store performs optimistic local updates first, then writes to Supabase.
- RLS allows public catalog reads, customer-owned bookings/messages, and owner-only stylist profile/schedule updates.
- The original ZIP source is preserved in `web-source/` for comparison.
