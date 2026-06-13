#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "Preflight failed: $*" >&2
  exit 1
}

expect_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

expect_setting() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(setting "$key")"
  [[ "$actual" == "$expected" ]] || fail "$key expected '$expected' but got '$actual'"
}

setting() {
  sed -n "s/^[[:space:]]*$1 = //p" "$BUILD_SETTINGS_FILE" | head -n 1
}

plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$2" "$1"
}

echo "== Hairmap Release Preflight =="

expect_file Config/Info.plist
expect_file Config/ExportOptions-TestFlight.plist
expect_file Hairmap/PrivacyInfo.xcprivacy
expect_file Hairmap/Assets.xcassets/AppIcon.appiconset/Contents.json
expect_file supabase/migrations/202606080001_hairmap_schema.sql
expect_file supabase/migrations/202606110001_admin_ops_schema.sql
expect_file supabase/migrations/202606120001_catalog_applications.sql
expect_file APP_STORE_RELEASE_CHECKLIST.md
expect_file TESTFLIGHT_RELEASE_GUIDE.md
expect_file docs/APP_STORE_METADATA_DRAFT.md
expect_file docs/BETA_OPERATIONS_PLAYBOOK.md
expect_file docs/index.html
expect_file docs/privacy.html
expect_file docs/terms.html
expect_file docs/support.html
expect_file docs/GITHUB_PAGES_SETUP.md
expect_file docs/RELEASE_NOTES_DRAFT.md
expect_file .github/workflows/pages.yml
expect_file tools/prepare_submission_package.sh

plutil -lint Config/Info.plist Config/ExportOptions-TestFlight.plist Hairmap/PrivacyInfo.xcprivacy >/dev/null

BUILD_SETTINGS_FILE="$(mktemp /tmp/hairmap-release-settings.XXXXXX)"
trap 'rm -f "$BUILD_SETTINGS_FILE"' EXIT

xcodebuild \
  -project Hairmap.xcodeproj \
  -scheme Hairmap \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -showBuildSettings > "$BUILD_SETTINGS_FILE"

expect_setting PRODUCT_BUNDLE_IDENTIFIER com.involution.Hairmap
expect_setting APP_ENVIRONMENT production
expect_setting SUPABASE_URL https://khmeqbcevlkwvgehvuni.supabase.co
expect_setting SUPABASE_REDIRECT_URL hairmap://auth-callback
expect_setting TARGETED_DEVICE_FAMILY 1
expect_setting SUPPORTS_MACCATALYST NO
expect_setting DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER NO

marketing_version="$(setting MARKETING_VERSION)"
current_project_version="$(setting CURRENT_PROJECT_VERSION)"
deployment_target="$(setting IPHONEOS_DEPLOYMENT_TARGET)"
supported_platforms="$(setting SUPPORTED_PLATFORMS)"
publishable_key="$(setting SUPABASE_PUBLISHABLE_KEY)"

[[ "$marketing_version" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]] || fail "MARKETING_VERSION should look like 1.0 or 1.0.0"
[[ "$current_project_version" =~ ^[0-9]+$ ]] || fail "CURRENT_PROJECT_VERSION should be numeric"
[[ "$deployment_target" == "17.0" ]] || fail "IPHONEOS_DEPLOYMENT_TARGET expected 17.0 but got $deployment_target"
[[ "$supported_platforms" == *iphoneos* && "$supported_platforms" == *iphonesimulator* ]] || fail "SUPPORTED_PLATFORMS must include iphoneos and iphonesimulator"
[[ "$publishable_key" == sb_publishable_* ]] || fail "SUPABASE_PUBLISHABLE_KEY must be a Supabase publishable key"

export_bundle_id="$(plist_value Config/ExportOptions-TestFlight.plist distributionBundleIdentifier)"
export_method="$(plist_value Config/ExportOptions-TestFlight.plist method)"
export_destination="$(plist_value Config/ExportOptions-TestFlight.plist destination)"
export_team="$(plist_value Config/ExportOptions-TestFlight.plist teamID)"
uses_encryption="$(plist_value Config/Info.plist ITSAppUsesNonExemptEncryption)"
privacy_tracking="$(plist_value Hairmap/PrivacyInfo.xcprivacy NSPrivacyTracking)"

[[ "$export_bundle_id" == "com.involution.Hairmap" ]] || fail "ExportOptions bundle id mismatch"
[[ "$export_method" == "app-store-connect" ]] || fail "ExportOptions method must be app-store-connect"
[[ "$export_destination" == "upload" ]] || fail "ExportOptions destination must be upload"
[[ "$export_team" == "MXV8VYWG8W" ]] || fail "ExportOptions teamID mismatch"
[[ "$uses_encryption" == "false" ]] || fail "ITSAppUsesNonExemptEncryption should remain false unless encryption usage changes"
[[ "$privacy_tracking" == "false" ]] || fail "Privacy manifest says tracking is enabled; update ATT/App Privacy before release"

migration_count="$(find supabase/migrations -maxdepth 1 -name '*.sql' | wc -l | tr -d ' ')"
[[ "$migration_count" -ge 7 ]] || fail "expected at least 7 Supabase migrations, found $migration_count"

echo "Release preflight passed: Hairmap ${marketing_version} (${current_project_version}) -> production."
