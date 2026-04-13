# Screen: Persona Editor

**Path:** `TabBar / Profile / Persona`
**View:** `PersonaEditorView`
**ViewModel:** `PersonaEditorViewModel`
**Stories:** PB-022

---

## Purpose

Edit the persona created during onboarding. Change bio, tone, platforms anytime. This is the "redo onboarding" screen but inline, not step-by-step.

## Specs

- **Sections** (Form style):
  - **Bio:** Multiline text field, same 280 char limit
  - **Voice & Tone:** Same tone cards as onboarding (single select)
  - **Platforms:** Same platform chips (multi-select)
  - **Pillar summary:** Read-only list with "Manage Pillars" link → Pillars Management screen
- **Auto-save** on every change
- **"Redo Onboarding" button** at bottom → restarts the guided flow (resets onboarding flag)
- **Preview section:** "AI sees you as:" + short AI-generated persona summary based on current settings (local template, no API)

## Interactions

| Action | Result |
|--------|--------|
| Edit bio | Auto-save, preview updates |
| Tap tone card | Change tone, auto-save |
| Tap platform chip | Toggle, auto-save |
| Tap "Manage Pillars" | Navigate to Pillars Management |
| Tap "Redo Onboarding" | Confirmation → restart onboarding flow |

## Edge Cases

- **Empty bio (cleared):** Allowed, preview reflects "No bio set"
- **Redo Onboarding doesn't delete data:** It pre-fills the steps with current values
- **All platforms deselected:** Allowed, AI defaults to generic
- **Rapid edits:** Debounce auto-save (500ms)

## Acceptance Criteria

- [ ] All persona fields editable
- [ ] Auto-save works
- [ ] Preview reflects current state
- [ ] "Manage Pillars" navigates correctly
- [ ] "Redo Onboarding" works with confirmation
- [ ] No data loss on redo
