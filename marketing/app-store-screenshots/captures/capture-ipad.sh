#!/usr/bin/env bash
# capture-ipad.sh — Capture iPad App Store screenshots (2064×2752px) from the seeded simulator.
# Uses iPad Pro 13-inch (M5) simulator for exact App Store dimensions.
#
# Usage: ./capture-ipad.sh
set -euo pipefail

CAPTURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IPAD_UDID="127A02F1-C145-4EEF-B1C9-F16B27E91838"
BUNDLE_ID="lucchettan.postkit"

# Find the app build — prefer ipad simulator build, fall back to iphone simulator
find_app_path() {
  local derived="$HOME/Library/Developer/Xcode/DerivedData"
  local candidates
  candidates=$(find "$derived" -name "PostKit.app" -path "*/Debug-iphonesimulator/*" 2>/dev/null | head -1)
  echo "$candidates"
}

APP_PATH=$(find_app_path)
if [ -z "$APP_PATH" ]; then
  echo "❌ No simulator build found. Build PostKit for a simulator in Xcode first."
  exit 1
fi
echo "📦 Using app: $APP_PATH"

# Boot the iPad if not already booted
STATUS=$(xcrun simctl list devices | grep "$IPAD_UDID" | grep -o "(Booted\|Shutdown)" | tr -d '()')
if [ "$STATUS" != "Booted" ]; then
  echo "🔄 Booting iPad Pro 13\" simulator..."
  xcrun simctl boot "$IPAD_UDID"
  sleep 5
fi

dismiss_popup() {
  osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
tell application "Simulator" to activate
delay 0.4
tell application "System Events" to tell process "Simulator"
  try
    click button "Ne pas autoriser" of window 1
  on error
    try
      click button "Don't Allow" of window 1
    end try
  end try
end tell
APPLESCRIPT
  sleep 0.6
}

launch_and_shoot() {
  local name="$1"
  local tab="$2"
  xcrun simctl terminate "$IPAD_UDID" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl uninstall "$IPAD_UDID" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl install "$IPAD_UDID" "$APP_PATH" >/dev/null
  xcrun simctl launch "$IPAD_UDID" "$BUNDLE_ID" -MarketingSeed 1 -MarketingTab "$tab" >/dev/null
  sleep 4
  dismiss_popup
  sleep 1.5
  xcrun simctl io "$IPAD_UDID" screenshot "$CAPTURE_DIR/ipad-$name.png" >/dev/null 2>&1
  echo "📸 ipad-$name.png"
}

launch_and_shoot "01-dashboard"        "home"
launch_and_shoot "03a-smartpost-chat"  "smartPost"
launch_and_shoot "03b-italian-template" "italianTemplate"
launch_and_shoot "04-pillars-bento"    "home"

echo "✅ Done. Files in $CAPTURE_DIR:"
ls -lh "$CAPTURE_DIR"/ipad-*.png 2>/dev/null
