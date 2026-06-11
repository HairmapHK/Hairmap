# Hairmap App Store Release Checklist

## App Identity

- Bundle ID: `com.involution.Hairmap`
- Display name: `Hairmap`
- Version: `1.0`
- Build: `1`
- Minimum iOS version: `17.0`
- Primary category: Lifestyle
- Secondary category: Business or Social Networking

## Apple Developer / App Store Connect

- Create the App Store Connect app record for `Hairmap`.
- Confirm the bundle ID has Sign in with Apple enabled.
- Add Google OAuth redirect settings for Supabase if Google login is enabled.
- Add a support URL.
- Add a privacy policy URL.
- Add terms of service URL if available.
- Complete age rating questionnaire.
- Prepare review notes with a test customer account and a test stylist account.
- Prepare screenshots for iPhone 6.9-inch, iPhone 6.5-inch/6.7-inch if requested, and iPad if the app remains universal.

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

- Run a Release build from Xcode.
- Archive with a physical or generic iOS device destination.
- Validate the archive in Xcode Organizer.
- Upload to TestFlight.
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
