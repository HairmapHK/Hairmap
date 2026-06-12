# Hairmap TestFlight Release Guide

## Current Build State

- Bundle ID: `com.involution.Hairmap`
- Team ID: `MXV8VYWG8W`
- Version: `1.0`
- Build: `1`
- Minimum iOS: `17.0`
- Device family: iPhone only
- Supabase project currently configured: `https://khmeqbcevlkwvgehvuni.supabase.co`

## Verified Locally

- Release simulator build passes.
- Unsigned generic iOS archive passes.
- App bundle includes `PrivacyInfo.xcprivacy`.
- The remaining blocker for TestFlight upload is Apple provisioning/signing.

## Signing Blocker Found

Command-line archive cannot create a signed archive yet because Xcode cannot find a provisioning profile for:

```text
com.involution.Hairmap
```

The automatic provisioning retry also reported that the team has no registered devices for a development profile. For TestFlight, use an App Store / Apple Distribution signing flow rather than a development profile.

## Recommended Upload Path

1. Open `/Users/kelvinfung398/Documents/Hairmap/Hairmap.xcodeproj` in Xcode.
2. Select target `Hairmap`.
3. Go to `Signing & Capabilities`.
4. Confirm:
   - Team: `MXV8VYWG8W`
   - Bundle Identifier: `com.involution.Hairmap`
   - Automatically manage signing: enabled
5. In App Store Connect, create the app record if it does not exist:
   - Name: `Hairmap`
   - Bundle ID: `com.involution.Hairmap`
   - Platform: iOS
6. In Xcode, select `Any iOS Device`.
7. Run `Product > Archive`.
8. When Organizer opens, choose `Distribute App`.
9. Select `App Store Connect`.
10. Upload to TestFlight.

## External Test Plan

Use a staged rollout:

- Internal self-test: install from TestFlight on your own iPhone.
- Closed beta: 10-20 trusted testers.
- Public beta: External Testing public link, capped at 100 testers.
- End test: expire the public build and close the public link.

## Data Safety

Before the public Threads campaign, create a separate Supabase staging project. TestFlight/public meme testing should point to staging, not production.

Production should only contain approved real stylists, salons, services, portfolio works, bookings, and reviews.

## Useful Commands

Full local CI check:

```sh
tools/ci_check.sh
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
