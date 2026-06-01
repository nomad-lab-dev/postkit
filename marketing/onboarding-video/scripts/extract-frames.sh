#!/usr/bin/env bash
# Extract begin + end still frames of every scene as PNGs for marketing reuse.
# Renders at 1080x1920 (the OnboardingShowcase composition).
#
# Frame math (CROSSFADE_FRAMES = 16):
#   Scene 1 Hook       — sequence [0, 150),   visible [16, 134]
#   Scene 2 Demo       — sequence [134, 299), visible [150, 282]
#   Scene 3 Pillars    — sequence [283, 403), visible [299, 386]
#   Scene 4 Sort       — sequence [387, 507), visible [403, 490]
#   Scene 5 Turn       — sequence [491, 611), visible [507, 610]

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
mkdir -p out/frames

COMP="OnboardingShowcase"

declare -a FRAMES=(
  "16:01-hook-begin"
  "134:01-hook-end"
  "150:02-demo-begin"
  "282:02-demo-end"
  "299:03-pillars-begin"
  "386:03-pillars-end"
  "403:04-sort-begin"
  "490:04-sort-end"
  "507:05-turn-begin"
  "610:05-turn-end"
)

echo "▶︎ Rendering ${#FRAMES[@]} stills (1080×1920)…"
for entry in "${FRAMES[@]}"; do
  frame="${entry%%:*}"
  name="${entry##*:}"
  echo "  · frame $frame → $name.png"
  npx remotion still "$COMP" "out/frames/$name.png" --frame="$frame" 2>&1 | tail -1
done

echo ""
echo "✓ Done. Frames in: $(pwd)/out/frames"
ls -la out/frames
