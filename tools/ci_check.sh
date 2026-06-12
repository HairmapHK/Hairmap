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

echo "Hairmap CI checks passed."
