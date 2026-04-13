# Screen: First Scan Trigger (v0.1)

**Path:** `Onboarding / Step 5 of 5`
**View:** `OnboardingFirstScanView`
**ViewModel:** `OnboardingViewModel`
**Story:** PB-022, PB-023

---

## Purpose

Request photo library permission and start first scan. Shows inline persona recap before launching.

## Specs

- **Persona recap card** (compact, inline):
  - Shows what was configured: pillars chips, tone badges per platform, bio snippet (or "No persona set")
  - "Edit" link → goes back to relevant step
  - Collapsed by default if everything is set, prominent if something was skipped
- **Scan section:**
  - Illustration (photos being sorted)
  - "PillarBox needs access to your photo library. Nothing leaves your device without your permission."
  - "Scan My Library" CTA
  - "Maybe Later" secondary
- Progress: step dots 5/5
- Fixed nav: Back + Scan My Library

## Interactions

| Action | Result |
|--------|--------|
| Tap "Scan My Library" | System permission dialog |
| Permission granted (full) | Dismiss onboarding, Home, start scan |
| Permission granted (limited) | Explain, proceed with subset |
| Permission denied | "Open Settings" link |
| Tap "Maybe Later" | Home, "Scan pending" badge |
| Tap "Edit" on recap | Navigate back to that step |

## Edge Cases

- **Permission already granted:** Skip dialog, start scan
- **Previously denied:** Show "Open Settings" immediately
- **Empty library:** "Take some photos and come back!"
- **Everything skipped (only pillars set):** Recap shows "Pillars: 4 set. No tone. No persona."
- **App killed during first scan:** Resumes on next launch

## Acceptance Criteria

- [ ] Persona recap shows all configured items
- [ ] "Edit" navigates back correctly
- [ ] Permission request with pre-explanation
- [ ] Full/limited/denied all handled
- [ ] "Maybe Later" → Home with badge
- [ ] Fixed nav position
