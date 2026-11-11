#!/bin/bash
# Build pentru simulator (fără semnare). Folosește OUT_DIR (implicit ./ci-out).
set -o pipefail
OUT_DIR="${OUT_DIR:-$PWD/ci-out}"; mkdir -p "$OUT_DIR"
xcodebuild -project ScratchSmile.xcodeproj -scheme ScratchSmile -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$OUT_DIR/dd" \
  CODE_SIGNING_ALLOWED=NO build 2>&1 | tee "$OUT_DIR/build.log" | grep -E "error:|warning: unre|BUILD (SUCCEEDED|FAILED)" \
|| true
grep -q "BUILD SUCCEEDED" "$OUT_DIR/build.log" || {
  echo "===== ERORI ====="; grep -E "error:" "$OUT_DIR/build.log" | sort -u | head -100; exit 1; }
# Verificare: limbile și iconița au ajuns în aplicație.
APP="$OUT_DIR/dd/Build/Products/Debug-iphonesimulator/ScratchSmile.app"
echo "Limbi în aplicație: $(ls "$APP" | grep '\.lproj' | sed 's/\.lproj//' | tr '\n' ' ')"
echo "Avertismente de compilare: $(grep -c 'warning:' "$OUT_DIR/build.log" || true)"
grep 'warning:' "$OUT_DIR/build.log" | sed 's/.*warning: //' | sort | uniq -c | sort -rn | head -15 || true
