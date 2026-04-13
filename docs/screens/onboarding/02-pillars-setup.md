# Screen: Pillars Setup (v0.1)

**Path:** `Onboarding / Step 2 of 5`
**View:** `OnboardingPillarsView`
**ViewModel:** `OnboardingViewModel`
**Story:** PB-022, PB-016

---

## Purpose

User creates their content pillars. Foundation of the entire classification system. REQUIRED step (only mandatory step).

## Specs

- Title: "What do you create content about?"
- Subtitle: "Define your content pillars."
- **Bento grid** of suggested pillars (2 columns):
  - Each card: emoji icon + pillar name + 1-line description
  - Tap = toggle on/off (visual state change)
  - Suggestions: Developer, AI/Tech, Entrepreneur, Digital Nomad, Travel, Food, Automotive, Fitness
- **"+ Add custom"** button → inline textfield
  - On textfield exit/validation: emoji auto-suggested via AI (micro-animation slide-in)
  - Tap emoji to open native iOS emoji picker and override
  - If no override, AI suggestion stays
- Minimum 1 pillar to proceed (Next disabled at 0)
- Nudge when > 10: "Pro tip: fewer pillars = stronger brand"
- Progress: step dots 2/5
- Fixed nav: Back + Next (shows count: "Next (4 selected)")

## Interactions

| Action | Result |
|--------|--------|
| Tap bento card | Toggle on/off with animation |
| Tap "+ Add custom" | Inline textfield, keyboard up |
| Exit custom textfield | Emoji auto-suggested (slide-in animation) |
| Tap auto-suggested emoji | Open native emoji picker |
| Submit custom pillar | New card added to grid, auto-selected |
| Tap Next (>= 1) | Save pillars, go to Step 3 |
| Tap Next (0) | Disabled state |
| Tap Back | Return to Step 1, selections preserved |

## Edge Cases

- **Duplicate custom name:** Inline error "This pillar already exists"
- **Empty custom name:** Ignore, don't create
- **Long name (>30 chars):** Truncate in card, full name stored
- **11+ pillars:** Nudge banner but don't block
- **Back then Forward:** Selections preserved in ViewModel
- **AI emoji suggestion fails:** Default to generic icon (star)

## Acceptance Criteria

- [ ] Bento grid renders 2 columns
- [ ] Toggle on/off with visual feedback
- [ ] Custom pillar: textfield + emoji auto-suggest on exit
- [ ] Native emoji picker opens on tap
- [ ] Micro-animation for emoji slide-in
- [ ] Min 1 enforced (button state)
- [ ] > 10 nudge shown
- [ ] Fixed nav position matches all other steps
