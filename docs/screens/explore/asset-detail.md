# Screen: Asset Detail (v0.1)

**Path:** `TabBar / Explore / Asset Detail`
**View:** `AssetDetailSheet`
**ViewModel:** `AssetDetailViewModel`
**Stories:** PB-036

---

## Purpose

Full view of a single asset. Slide-up sheet. All metadata editable inline. Mark non-pertinent.

## Specs

- **Presented as:** Sheet (slide-up, dismiss by swipe down)
- **Photo/video** at top (pinch to zoom, video plays)
- **Pillar badges:** tappable to remove, "+" to add
- **Tags:** tappable to remove, "+ tag" inline field to add
- **Location:** editable (tap to change)
- **Cadrage:** editable (tap to cycle: POV → Detail → Wide → Portrait)
- **Time of day:** display (auto from EXIF)
- **AI confidence:** display
- **Actions:**
  - "Add to Post" → post picker
  - "Mark non-pertinent" → moves to non-pertinent state
  - "Share" → Share Sheet
- **All edits auto-save**
- **Swipe left/right:** prev/next asset in current grid context

## Three Asset States

- **Active:** normal flow, visible everywhere
- **Non-pertinent:** excluded from grid/suggestions, accessible via filter
- **Used:** in a published post (post-MVP)

## Edge Cases

- **Video:** Player with controls
- **Not classified:** "Classify Now" button
- **Deleted photo:** Error state + cleanup
- **Restore from non-pertinent:** Action available in non-pertinent gallery

## Acceptance Criteria

- [ ] Sheet slide-up with swipe dismiss
- [ ] All metadata editable inline
- [ ] Auto-save on edit
- [ ] "Mark non-pertinent" works
- [ ] Swipe between assets
- [ ] Video playback
