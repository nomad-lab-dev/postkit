# Screen: Swipe — Pillar Selector (v0.1)

**Path:** `TabBar / Swipe`
**View:** `SwipeView`
**ViewModel:** `SwipeViewModel`
**Story:** PB-017

---

## Purpose

Entry point for swipe classification. Bento grid showing each pillar with preview thumbnails and quantity to review.

## Specs

- Title: "Swipe to classify"
- **Bento grid** (2 columns) per pillar:
  - Emoji icon + pillar name
  - Mini thumbnail grid (3-4 assets to review)
  - Overlay badge: quantity to review
  - Tap → enter swipe mode for that pillar
- Pillar with 0 to review: green checkmark "All reviewed!"
- Counts update live during scan

## Edge Cases

- **No pillars:** "Create your first pillar" CTA
- **All reviewed:** Celebration "All caught up!"
- **Scan running:** Counts update in real-time

## Acceptance Criteria

- [ ] Bento grid with thumbnails per pillar
- [ ] Quantity overlay badge
- [ ] Tap enters swipe mode
- [ ] Live count updates
- [ ] 3-second rule
