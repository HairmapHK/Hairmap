#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

tools/release_preflight.sh

OUTPUT_DIR="${1:-build/submission}"
mkdir -p "$OUTPUT_DIR"

BUILD_SETTINGS_FILE="$(mktemp /tmp/hairmap-submission-settings.XXXXXX)"
trap 'rm -f "$BUILD_SETTINGS_FILE"' EXIT

xcodebuild \
  -project Hairmap.xcodeproj \
  -scheme Hairmap \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -showBuildSettings > "$BUILD_SETTINGS_FILE"

setting() {
  sed -n "s/^[[:space:]]*$1 = //p" "$BUILD_SETTINGS_FILE" | head -n 1
}

version="$(setting MARKETING_VERSION)"
build="$(setting CURRENT_PROJECT_VERSION)"
bundle_id="$(setting PRODUCT_BUNDLE_IDENTIFIER)"
team_id="$(/usr/libexec/PlistBuddy -c 'Print :teamID' Config/ExportOptions-TestFlight.plist)"
supabase_url="$(setting SUPABASE_URL)"
environment="$(setting APP_ENVIRONMENT)"

cat > "$OUTPUT_DIR/APP_STORE_CONNECT_FIELDS.md" <<EOF
# Hairmap App Store Connect Submission Package

Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Build Identity

- App name: Hairmap
- Bundle ID: \`${bundle_id}\`
- Team ID: \`${team_id}\`
- Version: \`${version}\`
- Build: \`${build}\`
- Release environment: \`${environment}\`
- Supabase URL: \`${supabase_url}\`
- Minimum iOS: \`17.0\`
- Device family: iPhone only

## App Store Information

- Subtitle: Discover stylists and book salon appointments
- Primary category: Lifestyle
- Secondary category: Business
- Content rights: Hairmap owns or has permission to use bundled screenshots, app icons, and in-app demo assets.

## URLs

- Support URL: https://kelvinfung398398-sudo.github.io/Hairmap/support.html
- Privacy Policy URL: https://kelvinfung398398-sudo.github.io/Hairmap/privacy.html
- Terms URL: https://kelvinfung398398-sudo.github.io/Hairmap/terms.html
- Marketing URL: https://kelvinfung398398-sudo.github.io/Hairmap/

## Promotional Text

Find standout Hong Kong hair stylists, explore real hairstyle inspiration, and book salon appointments with a premium mobile experience.

## Description

Hairmap is a high-end hairstyle discovery and appointment platform for Hong Kong customers, stylists, and salons.

Customers can browse featured stylists, compare salons, explore hairstyle inspiration, upload their own looks, chat with stylists, and manage bookings in one place. Stylist profiles include portfolio photos, services, prices, reviews, languages, and salon details so customers can choose with confidence.

Stylists can manage booking requests, customer messages, available time slots, and their public profile from a dedicated dashboard. Salon and stylist submissions can be reviewed by platform admins before becoming public.

Key features:
- Discover stylists, salons, and rankings
- Browse fixed-size hairstyle portfolios and inspiration cards
- Book appointments with selectable services, dates, and times
- Chat one-on-one with stylists
- Upload photos for inspiration posts and reviews
- Manage customer bookings and stylist schedules
- Admin approval flow for new stylists and salons

## Keywords

hair,salon,stylist,haircut,hair color,booking,beauty,Hong Kong,髮型,髮型師,沙龍,剪髮,染髮,預約,香港

## Release Notes

Hairmap launches as a premium hairstyle discovery and salon booking app for Hong Kong.

Included in this build:
- Customer onboarding with email, Google, Apple, and guest flows
- Stylist and salon discovery
- District, style, price, and rating filters
- Stylist profiles with portfolios, services, and reviews
- Salon profiles with location, service highlights, and portfolio galleries
- Inspiration feed with uploads, media carousel, likes, comments, replies, and sharing counters
- Booking flow with stylist selection, service selection, date/time selection, and confirmation
- Customer profile and booking history
- One-on-one customer-stylist messages
- Stylist dashboard for bookings, messages, schedule, and profile editing
- Admin approval workflow for stylist and salon submissions

## Reviewer Notes Template

Create dedicated review accounts before submission. Do not use your personal email for Apple review.

\`\`\`text
Customer reviewer account:
Email: REVIEW_CUSTOMER_EMAIL
Password: REVIEW_CUSTOMER_PASSWORD

Stylist reviewer account:
Email: REVIEW_STYLIST_EMAIL
Password: REVIEW_STYLIST_PASSWORD

Admin reviewer account, only if Apple needs admin access:
Email: REVIEW_ADMIN_EMAIL
Password: REVIEW_ADMIN_PASSWORD
\`\`\`

Suggested review path:
1. Log in as a customer.
2. Open Discovery and view stylist, salon, and ranking tabs.
3. Open Inspiration, view a post, like/comment, and test upload.
4. Create a booking with Master Leo.
5. Log out and log in as the stylist reviewer.
6. Confirm the booking appears in the stylist dashboard.
7. Send a message back to the customer.

## Before Upload

- Enable GitHub Pages and confirm every URL above loads.
- Run \`tools/ci_check.sh\`.
- Run \`tools/release_preflight.sh\`.
- Confirm Supabase production data contains only approved real records.
- Confirm Apple, Google, and email auth providers are ready for production.
- Prepare iPhone screenshots listed in \`docs/APP_STORE_METADATA_DRAFT.md\`.
EOF

cp docs/RELEASE_NOTES_DRAFT.md "$OUTPUT_DIR/RELEASE_NOTES_DRAFT.md"
cp docs/APP_STORE_METADATA_DRAFT.md "$OUTPUT_DIR/APP_STORE_METADATA_DRAFT.md"

echo "Submission package written to: $OUTPUT_DIR"
