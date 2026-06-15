# Hairmap App Store Release Checklist

## Current Status - 2026-06-16

- Local simulator build launches successfully on iPhone 17 Pro.
- User has confirmed the current in-app screens are suitable to continue App Store preparation.
- Screenshot capture is deferred to the user; no App Store screenshot files are stored in this repo right now.
- `tools/release_preflight.sh` passes for Hairmap `1.0 (1)` with production configuration.
- `Hairmap 1.0 (1)` has been archived and uploaded to App Store Connect.
- Current next step: wait for TestFlight build processing, add an Internal Tester, and install on a real iPhone.
- External TestFlight/public link should wait until internal smoke testing passes and Beta App Review is approved.
- Recent product changes in this preparation checkpoint include the admin approval flow fix, commercialization memory document, and TestFlight upload readiness notes.

## App Identity

- Bundle ID: `com.involution.Hairmap`
- Apple Team ID: `9AY6FR5JDC`
- Display name: `Hairmap`
- Version: `1.0`
- Build: `1`
- Minimum iOS version: `17.0`
- Primary category: Lifestyle
- Secondary category: Business or Social Networking

## Apple Developer / App Store Connect

- Create the App Store Connect app record for `Hairmap`. Completed for bundle `com.involution.Hairmap`.
- Confirm the bundle ID has Sign in with Apple enabled.
- Add Google OAuth redirect settings for Supabase if Google login is enabled.
- Add a support URL.
- Add a privacy policy URL.
- Add terms of service URL if available.
- Enable GitHub Pages from `/docs` or replace the draft URLs with your own domain.
- Complete age rating questionnaire.
- Prepare review notes with a test customer account and a test stylist account.
- Prepare screenshots for iPhone 6.9-inch first. Add other iPhone sizes only if App Store Connect requests them. No iPad screenshots are needed while the app remains iPhone-only.

## Privacy

- Confirm the privacy manifest matches production data collection.
- Confirm App Store privacy nutrition labels match Supabase/Auth/Storage usage.
- Confirm no advertising tracking is enabled unless ATT is implemented.
- Confirm uploaded photos, messages, reviews, bookings, name, email, and phone usage are disclosed.

## Supabase Production Readiness

- Verify RLS is enabled on production tables.
- Verify public read/write policies only expose intended data.
- Verify Storage buckets have size and MIME restrictions.
- Verify Google and Apple auth providers are configured.
- Verify email SMTP rate limits and templates are production ready.
- Verify `Kelvinfung398398@gmail.com` remains `super_admin`.

## Final Build

- Run `tools/release_preflight.sh`.
- Run `tools/ci_check.sh`.
- Run a Release build from Xcode.
- Archive with a physical or generic iOS device destination.
- Validate the archive in Xcode Organizer.
- Upload to TestFlight. Completed for `Hairmap 1.0 (1)`.
- Run a smoke test on TestFlight:
  - Customer Google/Apple/email sign in
  - Customer booking
  - Stylist booking inbox
  - Chat message send/recall/block
  - Inspiration upload/comment/photo preview
  - Profile booking management
  - Admin dashboard flows when available

## Current Apple References

- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
