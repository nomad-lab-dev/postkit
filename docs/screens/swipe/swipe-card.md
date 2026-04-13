# Screen: Swipe — Card Editor (v0.1)

**Path:** `TabBar / Swipe / {Pillar Name}`
**View:** `SwipeCardView`
**ViewModel:** `SwipeViewModel`
**Stories:** PB-017, PB-018

---

## Purpose

Full-screen classification AND editing. Each card is a micro-editor: validate/reject for pillar while enriching metadata.

## Specs

- **Header:** Pillar icon + name + "X / Y remaining" counter
- **Progress bar** at top
- **Full-screen photo** with overlays:
  - AI confidence badge (top-right)
  - Tags overlay (bottom, tappable to remove)
  - "+ tag" button to add
  - Location (editable, tap to change)
  - Cadrage badge (editable, tap to cycle)
- **Swipe gestures:**
  - Right = YES (belongs to pillar) → green flash
  - Left = NO → red flash
- **Buttons** (accessibility):
  - Reject (left) / Undo (center) / Accept (right)
- **Undo:** 1-level, restores last card
- **Exit:** tap Back or pillar name anytime
- **Done state:** "All done!" → pick another pillar or explore

## Interactions

| Action | Result |
|--------|--------|
| Swipe right | Tag with pillar + save edits, green flash, next |
| Swipe left | Skip/untag + save edits, red flash, next |
| Tap tag | Remove tag |
| Tap "+ tag" | Add tag inline |
| Tap location | Edit location |
| Tap cadrage | Cycle type |
| Tap undo | Restore last card |
| Tap card | Full-screen zoom |

## Edge Cases

- **Video:** First frame + play icon, tap to preview
- **Undo at first card:** Button disabled
- **Fast swiping:** Batch SwiftData write every 10 swipes
- **App killed:** All previous swipes + edits saved
- **AI override:** User decision always wins
- **0 assets to review:** Don't enter card mode

## Acceptance Criteria

- [ ] Photo + score + tags overlay
- [ ] Tags editable (add/remove) during swipe
- [ ] Location editable
- [ ] Cadrage editable
- [ ] Swipe gestures with animation
- [ ] Undo works
- [ ] Batch save every 10
- [ ] Edits persist on swipe
