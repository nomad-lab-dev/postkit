# Screen: Welcome (v0.1)

**Path:** `Onboarding / Step 1 of 5`
**View:** `OnboardingWelcomeView`
**ViewModel:** `OnboardingViewModel`
**Story:** PB-022

---

## Purpose

First screen. Sets the value proposition with a visual before/after (chaotic gallery → organized by pillars).

## Specs

- App logo/icon
- App name "PillarBox"
- Before/after visual: left side = chaotic photo grid, right side = same photos organized with pillar badges
- "Get Started" CTA button
- "Skip" secondary (small) — goes to Home with empty persona
- Progress: step dots 1/5

## Navigation (fixed position — all onboarding screens)

- Bottom-pinned nav bar: Back (left) + Next/CTA (right)
- Step 1: no Back button, only CTA
- Position, size, and padding identical across all 5 steps

## Interactions

| Action | Result |
|--------|--------|
| Tap "Get Started" | Navigate to Step 2 (Pillars) |
| Tap "Skip" | Home with empty persona, badge on Profile |

## Edge Cases

- **App killed during onboarding:** Resume at last completed step (UserDefaults)
- **Skip pressed:** Persona empty, app usable. Profile shows "Complete setup" nudge
- **VoiceOver:** Full labels, CTA is default focus

## Acceptance Criteria

- [ ] Before/after visual renders on both platforms
- [ ] Step dots show 1/5
- [ ] Skip → Home with badge
- [ ] Onboarding state persisted
- [ ] Nav pinned at bottom, no Back on step 1
