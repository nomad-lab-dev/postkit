# Screen: Post Template Builder (v0.1)

**Path:** `TabBar / Posts / Templates or Home / Quick Action`
**View:** `TemplateBuilderView`
**ViewModel:** `TemplateBuilderViewModel`
**Story:** PB-037

---

## Purpose

Define reusable post templates with slot requirements. Guides post assembly.

## Specs

- Template name field
- **Slot list** (add/remove/reorder):
  - Per slot:
    - Cadrage type (picker: POV / Detail / Wide / Portrait / Any)
    - Required pillar(s) (multi-select from user's pillars, optional)
    - Required tags (free text, optional)
    - Description (what this slot is for, optional)
- **"+ Add slot"** button
- **Drag to reorder** slots
- **Save** → template available in "Create Post" flow
- **Delete** (red, confirmation)
- **Preview:** mini visual of what the post will look like (slots as boxes)

## Interactions

| Action | Result |
|--------|--------|
| Tap "+" | Add new slot with default settings |
| Configure slot fields | Auto-save |
| Drag slot | Reorder |
| Tap delete on slot | Remove slot (confirm if last) |
| Tap Save | Persist template |
| Tap Delete template | Confirmation → remove |

## Edge Cases

- **0 slots:** Can't save (min 1)
- **Duplicate template name:** Allowed (unique IDs)
- **Very many slots (10+):** Scrollable, no limit

## Acceptance Criteria

- [ ] CRUD for templates
- [ ] Per-slot configuration (cadrage, pillar, tags, description)
- [ ] Drag reorder
- [ ] Preview visual
- [ ] Templates accessible from Create Post flow
