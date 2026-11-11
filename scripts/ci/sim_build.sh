#!/bin/bash
# Build pentru simulator (fără semnare). Folosește OUT_DIR (implicit ./ci-out).
set -o pipefail
OUT_DIR="${OUT_DIR:-$PWD/ci-out}"; mkdir -p "$OUT_DIR"
xcodebuild -project Lozuri.xcodeproj -scheme Lozuri -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$OUT_DIR/dd" \
  CODE_SIGNING_ALLOWED=NO build 2>&1 | tee "$OUT_DIR/build.log" | grep -E "error:|warning: unre|BUILD (SUCCEEDED|FAILED)" \
|| true
grep -q "BUILD SUCCEEDED" "$OUT_DIR/build.log" || {
  echo "===== ERORI ====="; grep -E "error:" "$OUT_DIR/build.log" | sort -u | head -100; exit 1; }
