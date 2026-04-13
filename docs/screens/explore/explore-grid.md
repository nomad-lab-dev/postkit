# Screen: Explore Grid (v0.1)

**Path:** `TabBar / Explore`
**View:** `ExploreView`
**ViewModel:** `ExploreViewModel`
**Stories:** PB-013

---

## Purpose

Main asset browser. Flat grid with rich filters. Multi-select to create posts.

## Specs

- **Search bar** at top
- **Filter categories:**
  - Pillars: chips toggle
  - Cadrage: POV / Detail / Wide / Portrait chips
  - Location: picker menu populated from gallery cities (EXIF)
  - Moment: Morning / Afternoon / Evening / Night chips
  - Media: Photo / Video
  - Status: Active / Non-pertinent
- **Asset grid:** LazyVGrid, 3 cols iPhone, 4-5 Mac
- **Rich cards:** thumbnail + pillar badge + cadrage icon
- **Multi-select:** long press → select → 2 action buttons at bottom (Create Post + TBD)
- **Pagination:** 50 per page, scroll to load

## Edge Cases

- **15K+ assets:** LazyVGrid + pagination
- **Zero results:** "No assets found. Try different filters."
- **Deleted photo:** Placeholder + cleanup offer
- **Multi-select + tab switch:** Exit multi-select
- **Scan running:** New assets appear in real-time

## Acceptance Criteria

- [ ] All filter types functional
- [ ] Location picker populated from EXIF data
- [ ] Smooth with 1000+ items
- [ ] Multi-select → 2 action buttons
- [ ] 3-second rule
