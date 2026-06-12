#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "== Hairmap CI: plist validation =="
plutil -lint \
  Config/Info.plist \
  Config/ExportOptions-TestFlight.plist \
  Hairmap/PrivacyInfo.xcprivacy

echo "== Hairmap CI: catalog import tool =="
python3 -m py_compile tools/generate_catalog_seed_sql.py
python3 tools/generate_catalog_seed_sql.py \
  --salons templates/salon_import_template.csv \
  --stylists templates/stylist_import_template.csv > /tmp/hairmap_seed.sql
test -s /tmp/hairmap_seed.sql

echo "== Hairmap CI: package resolution =="
xcodebuild -resolvePackageDependencies \
  -project Hairmap.xcodeproj \
  -scheme Hairmap

echo "== Hairmap CI: Debug simulator build =="
xcodebuild -quiet \
  -project Hairmap.xcodeproj \
  -scheme Hairmap \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build

echo "== Hairmap CI: Release simulator build =="
xcodebuild -quiet \
  -project Hairmap.xcodeproj \
  -scheme Hairmap \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build

echo "== Hairmap CI: unit tests =="
if [[ -z "${IOS_TEST_DESTINATION:-}" ]]; then
  SIMULATOR_ID="$(xcrun simctl list devices available | sed -n '/iPhone/{s/.*(\([0-9A-Fa-f-]\{36\}\)) (.*/\1/p; q;}')"
  if [[ -z "$SIMULATOR_ID" ]]; then
    echo "No available iPhone simulator found." >&2
    exit 1
  fi
  IOS_TEST_DESTINATION="id=$SIMULATOR_ID"
fi

xcodebuild -quiet \
  -project Hairmap.xcodeproj \
  -scheme Hairmap \
  -configuration Debug \
  -destination "$IOS_TEST_DESTINATION" \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:HairmapTests \
  test

echo "Hairmap CI checks passed."
