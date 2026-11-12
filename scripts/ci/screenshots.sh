#!/bin/bash
# Capturile App Store: 5 ecrane × 7 limbi pe iPhone 6.9" → fastlane/screenshots/<limbă>/NN_scratch.png
# SPECS și SHOTS pot restrânge limbile și ecranele (vezi workflow-ul).
set -e
OUT_DIR="${OUT_DIR:-$PWD/ci-out}"; BUNDLE_ID="${BUNDLE_ID:-ro.draghicioiu.scratchsmile}"
SHOTS="${SHOTS:-1 2 3 4 5}"
bash scripts/ci/simulator.sh
UDID=$(cat "$OUT_DIR/udid")
xcrun simctl ui "$UDID" appearance dark
xcrun simctl status_bar "$UDID" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
# Notificările de sistem de după prima pornire trec înainte de capturi.
xcrun simctl launch "$UDID" "$BUNDLE_ID" -didOnboard YES >/dev/null; sleep 45; xcrun simctl terminate "$UDID" "$BUNDLE_ID" || true

# Starea comună: a trecut de lozul de bun-venit, are monede și câteva mesaje descoperite.
COMMON=(-didOnboard YES -coins 12850 -seenMessages "0,1,3,4,6,10,11,13,15,17,19" -statTickets 148 -bonusStreak 4)
args_for() {
  case "$1" in
    1) echo "" ;;                 # lobby
    2) echo "-demo half" ;;       # Lozul de Aur, pe jumătate răzuit
    3) echo "-demo win" ;;        # Aventură Spațială, jackpot dezvăluit
    4) echo "-demo share" ;;      # bonusul de share
    5) echo "-demo messages" ;;   # colecția de mesaje
  esac
}

OUT="$PWD/fastlane/screenshots"; rm -rf "$OUT"; mkdir -p "$OUT_DIR/screenshots"
SPECS="${SPECS:-ro:ro:ro_RO en-US:en:en_US es-ES:es:es_ES fr-FR:fr:fr_FR de-DE:de:de_DE it:it:it_IT pt-BR:pt-BR:pt_BR}"
for SPEC in $SPECS; do
  IFS=: read -r DIR LANG REGION <<< "$SPEC"
  mkdir -p "$OUT/$DIR"
  I=0
  for N in $SHOTS; do
    I=$((I+1))
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
    # shellcheck disable=SC2046
    xcrun simctl launch "$UDID" "$BUNDLE_ID" "${COMMON[@]}" $(args_for "$N") -AppleLanguages "($LANG)" -AppleLocale "$REGION" >/dev/null
    sleep 8
    FILE="$OUT/$DIR/$(printf %02d $I)_scratch.png"
    xcrun simctl io "$UDID" screenshot "$FILE" >/dev/null 2>&1
    # O captură aproape goală (ecran negru: aplicația încă pornea) e mult mai mică; mai așteaptă și reia.
    for TRY in 1 2 3; do
      [ "$(stat -f%z "$FILE")" -gt 600000 ] && break
      echo "Captura $N ($DIR) pare goală, reiau (încercarea $TRY)"
      sleep 6
      xcrun simctl io "$UDID" screenshot "$FILE" >/dev/null 2>&1
    done
    [ "$(stat -f%z "$FILE")" -gt 600000 ] || { echo "::error::Captura $N ($DIR) a rămas goală"; exit 1; }
    # Dacă aplicația nu mai rulează la momentul capturii, a căzut: oprește tot, cu motivul.
    if ! xcrun simctl spawn "$UDID" launchctl list | grep -q "$BUNDLE_ID"; then
      echo "::error::Aplicația nu rula la captura $N ($DIR)"
      for r in ~/Library/Logs/DiagnosticReports/ScratchSmile*.ips; do
        [ -f "$r" ] && { echo "--- $r"; grep -m1 -A25 '"exception"' "$r" | cut -c1-300; grep -m1 -B2 -A30 '"faultingThread"' "$r" | grep -o '"symbol":"[^"]*"' | head -25; }
      done
      exit 1
    fi
  done
  for f in "$OUT/$DIR/"*.png; do cp "$f" "$OUT_DIR/screenshots/${DIR}_$(basename "$f")"; done
  echo "Capturi $DIR: $(ls "$OUT/$DIR" | wc -l)"
done
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
sips -g pixelWidth -g pixelHeight "$(ls "$OUT"/*/01_scratch.png | head -1)" | tail -2
