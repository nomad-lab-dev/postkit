# Screen: Classification Stats

**Path:** `TabBar / Profile / Stats`
**View:** `ClassificationStatsView`
**ViewModel:** `ClassificationStatsViewModel`
**Stories:** PB-012

---

## Purpose

Analytics dashboard showing classification coverage, pillar distribution, and usage stats.

## Specs

- **Overview ring chart:** Classified vs Unclassified (percentage)
- **Pillar distribution bar chart:** Horizontal bars showing asset count per pillar, sorted by count
- **Framing distribution:** POV / Detail / Wide / Portrait breakdown (pie or bar)
- **Timeline chart:** Assets per month (when were your photos taken?)
- **Top locations:** Top 5 cities by asset count
- **Time of day distribution:** Morning / Afternoon / Evening / Night
- **Meta stats:**
  - Total assets
  - Total classified
  - Total posts created
  - API calls made (lifetime)
  - Last scan date/duration

## Interactions

| Action | Result |
|--------|--------|
| Tap pillar bar | Navigate to Explore filtered by that pillar |
| Tap location | Navigate to Explore filtered by that location |
| Pull to refresh | Recalculate stats |

## Edge Cases

- **No classified assets:** All charts empty, show "Scan your library to see stats"
- **Single pillar:** Bar chart still renders (single bar)
- **No location data:** "Top locations" section hidden
- **Very skewed distribution:** Chart scales appropriately (no overflow)

## Acceptance Criteria

- [ ] All charts render correctly
- [ ] Data is live from SwiftData queries
- [ ] Tapping bars/segments navigates to Explore
- [ ] Empty state for no data
- [ ] Charts adapt to both platforms
- [ ] Refreshable
