# Screen: Platforms + Tone (v0.1)

**Path:** `Onboarding / Step 3 of 5` (multi-step: 3.1 → 3.x)
**View:** `OnboardingPlatformsView`, `OnboardingToneView`
**ViewModel:** `OnboardingViewModel`
**Story:** PB-022, PB-035

---

## Purpose

User selects platforms and assigns 1-3 tones per platform. Merged from two separate screens (v0.0). OPTIONAL step.

## Specs — Step 3.1: Platform Selection

- Title: "Where do you post?"
- **Bento grid** of platforms (2 columns):
  - Instagram, TikTok, LinkedIn, X/Twitter, YouTube, Blog
  - Tap = toggle on/off
- Multi-select
- "Next" always enabled (0 platforms = skip tones entirely)
- Progress: step dots 3/5

## Specs — Steps 3.2+: Tone per Platform

For each selected platform, a sub-step:

- Header: platform icon + name
- Sub-progress dots (e.g., 1/3 platforms)
- Title: "How do you talk on {platform}?"
- **5 tone cards** (no "Mix" option):
  - Professional & Sharp — example phrase
  - Casual & Fun — same phrase in this tone
  - Inspirational & Bold — same phrase
  - Minimal & Clean — same phrase
  - Storyteller — same phrase
- **Same phrase** rewritten in each tone for direct comparison
  - e.g., "Just shipped a new feature from a Bangkok rooftop"
- Multi-select: 1-3 max
- Tooltip at 3: "A strong brand speaks in 2-3 voices max."
- Fixed nav: Back + Next

## Interactions

| Action | Result |
|--------|--------|
| 3.1: Tap platform card | Toggle selection |
| 3.1: Tap Next (0 selected) | Skip all tone steps, go to Step 4 |
| 3.1: Tap Next (N selected) | Go to 3.2 (first platform tone) |
| 3.x: Tap tone card | Toggle (max 3) |
| 3.x: Tap 4th tone | Blocked, tooltip "2-3 max" |
| 3.x: Tap Next | Save tones for this platform, next platform or Step 4 |
| 3.x: Tap Back | Previous platform or 3.1 |

## Edge Cases

- **0 platforms selected:** Skip tone entirely, go to Step 4
- **1 platform:** Only one tone sub-step
- **0 tones for a platform:** Allowed, AI defaults to Professional
- **Back from 3.3 → 3.2:** Previous platform's selections preserved
- **Large Dynamic Type:** Tone cards stack vertically, scroll

## Acceptance Criteria

- [ ] Platform bento grid works
- [ ] Skip if 0 platforms
- [ ] Tone sub-step per platform with same-phrase examples
- [ ] Multi-select 1-3 enforced
- [ ] Tooltip at 3
- [ ] Sub-progress dots
- [ ] Fixed nav position
- [ ] "Mix" option removed
