#!/usr/bin/env bash
# capture.sh — Capture App Store screenshots from the seeded simulator.
# Uses `-MarketingTab` launch arg to land on each screen directly — no UI taps.
#
# Usage: ./capture.sh
set -euo pipefail

CAPTURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="/Users/nicolaslucchetta/Library/Developer/Xcode/DerivedData/PostKit-edwazilrnwmfwgdatiaopwdharfy/Build/Products/Debug-iphonesimulator/PostKit.app"
BUNDLE_ID="lucchettan.postkit"

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
  xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl uninstall booted "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl install booted "$APP_PATH" >/dev/null
  xcrun simctl launch booted "$BUNDLE_ID" -MarketingSeed 1 -MarketingTab "$tab" >/dev/null
  sleep 4
  dismiss_popup
  sleep 1.5
  xcrun simctl io booted screenshot "$CAPTURE_DIR/$name.png" >/dev/null 2>&1
  echo "📸 $name.png"
}

launch_and_shoot "01-dashboard"        "home"
launch_and_shoot "03a-smartpost-chat"  "smartPost"
launch_and_shoot "04-pillars-bento"    "home"  # same as 01 — HTML composer will crop to bento region

echo "✅ Done."
ls -la "$CAPTURE_DIR"/*.png 2>/dev/null
