#!/bin/bash
# Pornește cel mai nou iPhone Pro Max din simulator și instalează aplicația. Scrie UDID în $OUT_DIR/udid.
set -e
OUT_DIR="${OUT_DIR:-$PWD/ci-out}"
APP=$(find "$OUT_DIR/dd/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name "*.app" | head -1)
UDID=$(xcrun simctl list devices available -j | python3 -c "
import sys, json, re
d = json.load(sys.stdin)['devices']
best = None
for rt, devs in d.items():
    m = re.search(r'iOS-(\d+)-(\d+)', rt)
    if not m: continue
    ver = (int(m.group(1)), int(m.group(2)))
    for dv in devs:
        if 'Pro Max' in dv['name'] and (best is None or ver > best[0]):
            best = (ver, dv['udid'], dv['name'])
print(best[1]); print(best[2], best[0], file=sys.stderr)")
xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl install "$UDID" "$APP"
echo "$UDID" > "$OUT_DIR/udid"
