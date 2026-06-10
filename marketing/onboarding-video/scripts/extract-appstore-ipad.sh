#!/usr/bin/env bash
# Extract all 10 scene begin+end stills × 3 locales = 30 JPEGs at iPad 12.9" / 13".
# Output: out/frames-ipad/en/, out/frames-ipad/fr/, out/frames-ipad/es/ (2064×2752 each).

set -eu

# Locate node from Homebrew if not in PATH
if ! command -v node &>/dev/null; then
  for candidate in /opt/homebrew/opt/node/bin /opt/homebrew/opt/node@20/bin /opt/homebrew/bin; do
    if [ -x "$candidate/node" ]; then
      export PATH="$candidate:$PATH"
      break
    fi
  done
fi

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
  local outdir="out/frames-ipad/$locale"
  mkdir -p "$outdir"
  echo "▶︎ [$locale] · composition $comp · output $outdir/"
  echo "$FRAMES" | while IFS=':' read -r frame name; do
    echo "  · frame $frame → $name.jpg"
    ./node_modules/.bin/remotion still "$comp" "$outdir/$name.jpg" --frame="$frame" 2>&1 | tail -1
  done
}

render_locale en AppStore129EN
render_locale fr AppStore129FR
render_locale es AppStore129ES

echo ""
echo "✓ Done."
for locale in en fr es; do
  count=$(ls "out/frames-ipad/$locale" 2>/dev/null | wc -l | xargs)
  echo "  /$locale/ ($count frames)"
done
