#!/usr/bin/env bash
# Extract all 10 scene begin+end stills × 3 locales = 30 PNGs at iPhone 6.5".
# Output: out/frames/en/, out/frames/fr/, out/frames/es/ (1242×2688 each).

set -eu

cd "$(dirname "${BASH_SOURCE[0]}")/.."

FRAMES="16:01-hook-begin
134:01-hook-end
150:02-demo-begin
282:02-demo-end
299:03-pillars-begin
386:03-pillars-end
403:04-sort-begin
490:04-sort-end
507:05-turn-begin
594:05-turn-end"

render_locale () {
  local locale="$1"
  local comp="$2"
  local outdir="out/frames/$locale"
  mkdir -p "$outdir"
  echo "▶︎ [$locale] · composition $comp · output $outdir/"
  echo "$FRAMES" | while IFS=':' read -r frame name; do
    echo "  · frame $frame → $name.png"
    npx remotion still "$comp" "$outdir/$name.png" --frame="$frame" 2>&1 | tail -1
  done
}

render_locale en AppStore65EN
render_locale fr AppStore65FR
render_locale es AppStore65ES

echo ""
echo "✓ Done."
for locale in en fr es; do
  count=$(ls "out/frames/$locale" 2>/dev/null | wc -l | xargs)
  echo "  /$locale/ ($count frames)"
done
