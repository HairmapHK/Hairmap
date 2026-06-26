# Hairmap TestFlight Release Guide

## Current Build State

- Bundle ID: `com.involution.Hairmap`
- Team ID: `9AY6FR5JDC`
- Version: `1.0`
- Current local build: `18`
- Minimum iOS: `17.0`
- Device family: iPhone only
- Supabase project currently configured: `https://khmeqbcevlkwvgehvuni.supabase.co`
- Upload status: `Hairmap 1.0 (18)` uploaded to App Store Connect/TestFlight on 2026-06-19.
- Next target: prepare App Store submission and pre-order setup.

## Verified Locally

- Release simulator build passes.
- Unsigned generic iOS archive passes.
- Xcode archive and App Store Connect upload succeeded for `Hairmap 1.0 (1)`.
- App bundle includes `PrivacyInfo.xcprivacy`.
- Customer-facing screens now force the light color scheme so secondary labels remain legible on real devices using Dark Mode.
- Native Sign in with Apple is enabled through AuthenticationServices and the app entitlement.

## Current TestFlight Status

The latest TestFlight candidate `1.0 (18)` is uploaded. App Store Connect may take several minutes to process uploaded builds before they appear under:

```text
App Store Connect > Hairmap > TestFlight > iOS Builds
```

If App Store Connect asks for export compliance, this app currently uses standard HTTPS/Supabase networking and no custom encryption. Answer according to Apple's current prompt and mark it as exempt/non-custom encryption where applicable.

## Completed Upload Path

1. Open `/Users/kelvinfung398/Documents/Hairmap/Hairmap.xcodeproj` in Xcode.
2. Select target `Hairmap`.
3. Go to `Signing & Capabilities`.
4. Confirm:
   - Team: `9AY6FR5JDC`
   - Bundle Identifier: `com.involution.Hairmap`
   - Automatically manage signing: enabled
5. In App Store Connect, create the app record:
   - Name: `Hairmap`
   - Bundle ID: `com.involution.Hairmap`
   - Platform: iOS
6. In Xcode, select `Any iOS Device`.
7. Run `Product > Archive`.
8. When Organizer opens, choose `Distribute App`.
9. Select `App Store Connect`.
10. Upload to TestFlight. Latest completed upload is build `18`.

## Next App Store Connect Steps

1. Wait for build `1.0 (18)` to finish App Store Connect processing.
2. Add yourself as an Internal Tester and install Hairmap from TestFlight on a real iPhone.
3. Run the internal smoke test:
   - Customer Google/Apple/email sign in
   - Customer booking creation
   - Stylist dashboard receives the booking
   - Customer/stylist chat message round trip
   - Photo upload flows for inspiration, stylist profile, and salon profile
   - Admin approval flow for pending stylist/salon submissions
4. After internal testing passes, prepare the External Testing public link and submit the build for Beta App Review.
5. Keep external testing on staging data before the public Threads campaign.

## Pre-Order Direction

The current plan is to submit a production-ready build for App Review, set it as an App Store pre-order after approval, and use the pre-order window to collect real stylist/salon records.

Pre-order safe changes:

- Add, approve, reject, hide, rank, and edit Supabase stylist/salon/inspiration data.
- Clean test bookings, messages, comments, demo profiles, and demo media before launch.
- Update App Store marketing copy and screenshots if App Store Connect allows the edit for the current state.

Changes that require a new build and another review:

- Swift/SwiftUI code changes.
- Auth provider changes that require entitlements or callback behavior changes.
- Schema assumptions that the app binary depends on.
- New SDKs, analytics, payments, tracking, or push notification behavior.

## App Store Connect URLs

If GitHub Pages is enabled from the `/docs` folder:

```text
Support URL: https://kelvinfung398398-sudo.github.io/Hairmap/support.html
Privacy Policy URL: https://kelvinfung398398-sudo.github.io/Hairmap/privacy.html
Terms URL: https://kelvinfung398398-sudo.github.io/Hairmap/terms.html
Marketing URL: https://kelvinfung398398-sudo.github.io/Hairmap/
```

## External Test Plan

Use a staged rollout:

- Internal self-test: install from TestFlight on your own iPhone.
- Closed beta: 10-20 trusted testers.
- Public beta: External Testing public link, capped at 100 testers.
- End test: expire the public build and close the public link.

## Data Safety

Before the public Threads campaign, create a separate Supabase staging project. TestFlight/public meme testing should point to staging, not production.

For this launch phase, the existing Supabase project is being treated as a "quasi-production" project. Before App Store release, clean test records and keep only the admin account plus approved real stylists, salons, services, portfolio works, bookings, and reviews.

## Useful Commands

Full local CI check:

```sh
tools/ci_check.sh
```

Release preflight only:

```sh
tools/release_preflight.sh
```

Generate the App Store Connect submission package:

```sh
tools/prepare_submission_package.sh
```

Release simulator build:

```sh
xcodebuild -quiet -scheme Hairmap -configuration Release -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Unsigned iOS archive smoke test:

```sh
xcodebuild -quiet -scheme Hairmap -configuration Release -destination 'generic/platform=iOS' -archivePath build/Hairmap-unsigned.xcarchive CODE_SIGNING_ALLOWED=NO archive
```

Upload options file:

```text
Config/ExportOptions-TestFlight.plist
```
