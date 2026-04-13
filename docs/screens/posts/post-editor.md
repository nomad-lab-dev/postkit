# Screen: Post Editor (v0.1)

**Path:** `TabBar / Posts / {Post Name}`
**View:** `PostEditorView`
**ViewModel:** `PostEditorViewModel`
**Stories:** PB-021, PB-024, PB-038

---

## Purpose

Slot-based post assembly. Each slot shows requirements from template. Tap to fill via contextual explorer.

## Specs

- Post name + description (editable, auto-save)
- **Slot grid:**
  - **Empty slot:** Shows template requirements (cadrage, pillar, tags). Dotted border.
  - **Filled slot:** Asset thumbnail + tags/loc/cadrage overlay around it
  - **Tap empty slot:** Opens contextual asset explorer pre-filtered by slot requirements
  - **Tap filled slot:** Replace (re-opens explorer)
  - **Long press filled slot:** Remove, asset returns to "non-utilise"
- **Contextual Explorer:**
  - Opens with slot requirements as active filters
  - Filters are editable (user can broaden/narrow)
  - Search bar available for free exploration
  - Tap asset → fills slot, return to editor
- **Actions:**
  - "Publish" → mark as published
  - "Cancel" → delete post, all assets → non-utilise
  - "Export to Album" → native Photos album
  - "Suggest Hook & Caption" (post-MVP) → AI button
- **Status:** Draft / Ready / Published
- **Delete:** red, with confirmation

## Edge Cases

- **No template:** Free-form, "+" to add slots manually
- **Slot requirements match 0 assets:** Explorer shows empty state, filters editable
- **All assets removed:** Can't publish (min 1)
- **Export album exists:** Update, don't duplicate
- **Permission denied:** Settings link

## Acceptance Criteria

- [ ] Slots show requirements or filled asset
- [ ] Contextual explorer opens pre-filtered
- [ ] Filters editable in explorer
- [ ] Tags/loc visible on filled slots
- [ ] Publish/Cancel flow works
- [ ] Export to Album works
- [ ] Auto-save on edits
