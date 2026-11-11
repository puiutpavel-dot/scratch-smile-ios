#!/bin/bash
# Arhivă Release + export semnat în cloud (certificatul de distribuție îl gestionează Apple)
# + urcare în App Store Connect / TestFlight. Nu are nevoie de certificat sau profil local:
# doar de cheia App Store Connect API (rol Admin) din secretele GitHub.
set -e
OUT_DIR="${OUT_DIR:-$PWD/ci-out}"; mkdir -p "$OUT_DIR"
: "${ASC_KEY_ID:?lipsește secretul ASC_KEY_ID}" "${ASC_ISSUER_ID:?lipsește secretul ASC_ISSUER_ID}"
KEY="$OUT_DIR/AuthKey_$ASC_KEY_ID.p8"
printf '%s\n' "$ASC_PRIVATE_KEY" > "$KEY"
AUTH=(-allowProvisioningUpdates -authenticationKeyPath "$KEY" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
: "${TEAM_ID:?lipsește TEAM_ID}" "${BUILD_NUMBER:?lipsește BUILD_NUMBER}"
echo "Echipa $TEAM_ID, build $BUILD_NUMBER"

# Arhiva se semnează ad-hoc („-”), ca să păstreze drepturile (Game Center) pentru semnarea finală.
set -o pipefail
xcodebuild -project ScratchSmile.xcodeproj -scheme ScratchSmile -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$OUT_DIR/ScratchSmile.xcarchive" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- PROVISIONING_PROFILE_SPECIFIER= \
  archive 2>&1 | tee "$OUT_DIR/archive.log" | grep -E "error:|ARCHIVE (SUCCEEDED|FAILED)" || true
if ! grep -q "ARCHIVE SUCCEEDED" "$OUT_DIR/archive.log"; then
  echo "Semnarea ad-hoc n-a mers; arhivez nesemnat:"; grep -E "error:" "$OUT_DIR/archive.log" | sort -u | head -20
  rm -rf "$OUT_DIR/ScratchSmile.xcarchive"
  xcodebuild -project ScratchSmile.xcodeproj -scheme ScratchSmile -configuration Release \
    -destination 'generic/platform=iOS' -archivePath "$OUT_DIR/ScratchSmile.xcarchive" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" DEVELOPMENT_TEAM="$TEAM_ID" CODE_SIGNING_ALLOWED=NO \
    archive 2>&1 | tee "$OUT_DIR/archive.log" | grep -E "error:|ARCHIVE (SUCCEEDED|FAILED)" || true
  grep -q "ARCHIVE SUCCEEDED" "$OUT_DIR/archive.log" || { echo "Arhivarea a eșuat"; grep -E "error:" "$OUT_DIR/archive.log" | sort -u | head -50; exit 1; }
fi
APP="$OUT_DIR/ScratchSmile.xcarchive/Products/Applications/ScratchSmile.app"
# Arhiva nesemnată nu poartă drepturile (Game Center). Le punem cu o semnătură ad-hoc făcută direct cu codesign;
# la export, semnarea din cloud a Apple preia drepturile din aplicația arhivată.
if ! codesign -d --entitlements :- "$APP" 2>/dev/null | grep -q game-center; then
  ENT="$OUT_DIR/ent.plist"
  cp Config/ScratchSmile.entitlements "$ENT"
  /usr/libexec/PlistBuddy -c "Add :application-identifier string $TEAM_ID.${BUNDLE_ID:-ro.draghicioiu.scratchsmile}" "$ENT" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string $TEAM_ID" "$ENT" 2>/dev/null || true
  find "$APP" -depth \( -name "*.framework" -o -name "*.dylib" -o -name "*.appex" \) -exec codesign --force --sign - {} \; 2>/dev/null || true
  codesign --force --sign - --entitlements "$ENT" --generate-entitlement-der "$APP"
fi
echo "Drepturi în arhivă:"; codesign -d --entitlements :- "$APP" 2>/dev/null || true

cat > "$OUT_DIR/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>${EXPORT_DESTINATION:-upload}</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
PLIST
xcodebuild -exportArchive -archivePath "$OUT_DIR/ScratchSmile.xcarchive" -exportPath "$OUT_DIR/export" \
  -exportOptionsPlist "$OUT_DIR/ExportOptions.plist" "${AUTH[@]}" 2>&1 | tee "$OUT_DIR/export.log" | tail -40
grep -qE "EXPORT SUCCEEDED|Upload succeeded|Uploaded" "$OUT_DIR/export.log" || { echo "Exportul / urcarea a eșuat"; exit 1; }
rm -f "$KEY"
IPA=$(find "$OUT_DIR/export" -name "*.ipa" 2>/dev/null | head -1 || true)
if [ -n "$IPA" ]; then
  mkdir -p "$OUT_DIR/ipa" && (cd "$OUT_DIR/ipa" && unzip -q -o "$IPA")
  echo "Drepturi în build-ul final:"; codesign -d --entitlements :- "$OUT_DIR/ipa/Payload/ScratchSmile.app" 2>/dev/null | grep -A1 game-center || echo "ATENȚIE: fără Game Center"
fi
echo "Gata: build $BUILD_NUMBER urcat în App Store Connect (apare în TestFlight după procesare)."
