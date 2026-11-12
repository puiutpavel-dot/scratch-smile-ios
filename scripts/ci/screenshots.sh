#!/bin/bash
# Pornește aplicația în simulator și face capturi de ecran, ca să poată fi verificată grafica.
# Capturile sunt salvate în OUT_DIR și scrise în jurnal, micșorate, în base64.
set -eo pipefail
OUT_DIR="${OUT_DIR:-$PWD/ci-out}"
APP="$OUT_DIR/dd/Build/Products/Debug-iphonesimulator/ScratchSmile.app"
BUNDLE="${BUNDLE_ID:-ro.draghicioiu.scratchsmile}"

DEV=$(xcrun simctl list devices available | grep -E "^ +iPhone" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
echo "Simulator: $(xcrun simctl list devices available | grep "$DEV" | sed -E 's/ \(.*//')"
xcrun simctl boot "$DEV" || true
xcrun simctl bootstatus "$DEV" -b >/dev/null
xcrun simctl install "$DEV" "$APP"

shot() {
  local name=$1; shift
  xcrun simctl launch "$DEV" "$BUNDLE" "$@" >/dev/null
  sleep 7
  xcrun simctl io "$DEV" screenshot "$OUT_DIR/$name.png" >/dev/null 2>&1
  xcrun simctl terminate "$DEV" "$BUNDLE" || true
  sips -Z 1000 -s format jpeg -s formatOptions 50 "$OUT_DIR/$name.png" --out "$OUT_DIR/$name.jpg" >/dev/null
  echo "===SHOT $name BEGIN==="
  base64 -i "$OUT_DIR/$name.jpg" | fold -w 180
  echo "===SHOT $name END==="
}

# Lobby (sărind peste lozul de bun-venit), apoi lozul de bun-venit de la prima pornire.
shot lobby -skipGameCenter YES -didOnboard YES -AppleLanguages "(ro)"
shot ticket -skipGameCenter YES -AppleLanguages "(ro)"
xcrun simctl shutdown "$DEV" || true
