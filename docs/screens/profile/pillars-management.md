# Screen: Pillars Management

**Path:** `TabBar / Profile / Pillars`
**View:** `PillarsManagementView`
**ViewModel:** `PillarsManagementViewModel`
**Stories:** PB-016

---

## Purpose

Full CRUD for content pillars. Create, edit, reorder, delete pillars with custom colors and icons.

## Specs

- **Pillar list:** Ordered list of all pillars
  - Each row: icon + color dot + name + asset count
  - Drag handles for reorder
  - Tap → edit mode (inline or sheet)
- **Edit pillar (sheet):**
  - Name field
  - Color picker (system color grid)
  - SF Symbol picker (search + categories)
  - "Delete pillar" (red, at bottom)
- **"Add Pillar" button** → same sheet but empty
- **Nudge banner** when > 10 pillars: "Fewer pillars = stronger brand focus"
- **Reorder:** Drag to reorder, order persisted

## Interactions

| Action | Result |
|--------|--------|
| Tap "Add Pillar" | Open empty edit sheet |
| Tap pillar row | Open edit sheet with current values |
| Drag pillar row | Reorder, persist order |
| Edit name in sheet | Live update |
| Tap color | Select color |
| Tap SF Symbol | Select icon |
| Tap "Delete" in sheet | Confirmation: "Delete '{name}'? X assets will be untagged." → delete |
| Tap "Save" in sheet | Persist changes, dismiss sheet |

## Edge Cases

- **Delete pillar with assets:** Assets lose that pillar tag. Confirmation shows count. Assets NOT deleted.
- **Duplicate pillar name:** Show inline error "A pillar with this name already exists"
- **Empty pillar name:** Don't allow save, show error
- **Last pillar deleted:** Allowed. Home shows "Create your first pillar" state.
- **11th pillar created:** Show nudge banner (dismissible)
- **Very long pillar name:** Max 30 chars enforced in field
- **Reorder + iCloud sync (future):** Last-write-wins for order field
- **Color picker on macOS vs iOS:** Use system ColorPicker (adaptive)

## Acceptance Criteria

- [ ] CRUD operations work
- [ ] Color picker works on both platforms
- [ ] SF Symbol picker works with search
- [ ] Reorder persists
- [ ] Delete removes pillar from assets (not assets themselves)
- [ ] Delete confirmation shows asset count
- [ ] Duplicate name prevented
- [ ] > 10 nudge shown
- [ ] Empty name prevented
