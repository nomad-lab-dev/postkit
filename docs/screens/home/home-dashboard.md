# Screen: Home Dashboard (v0.1)

**Path:** `TabBar / Home`
**View:** `HomeView`
**ViewModel:** `HomeViewModel`
**Stories:** PB-012, PB-015

---

## Purpose

Command center. Smart scan status, pillar overview with thumbnails, and quick actions.

## Specs

### 1. Scan Status Card (conditional, top)

4 states:
- **Scanning:** Progress bar + "342/1,204" + estimated time + Pause button
- **Idle:** "Last scan 14:32 — All good" (discreet)
- **New items:** "47 new photos to classify" + "Scan Now" CTA
- **Items to review:** "12 classified items to review" + CTA → Swipe
- **All validated:** "12 items validated" + green checkmark

### 2. Pillars Section (bento grid)

Per pillar card:
- Emoji icon + pillar name
- Asset count in inline tag
- **Mini thumbnail grid** (3-4 most recent classified assets) below
- Tap → Explore filtered by this pillar

### 3. Quick Actions (bento grid)

- **"Review classifications"** → Swipe tab
- **"Compose a post"** → Posts tab, new post flow
- **"Create template"** → Template builder screen

(Rescan integrated in scan status card. Stats removed from dashboard.)

## Interactions

| Action | Result |
|--------|--------|
| Tap pillar card | Explore tab filtered by pillar |
| Tap "Scan Now" | Start scan, card → progress state |
| Tap Pause | Pause scan, button → Resume |
| Tap quick action | Navigate to corresponding feature |
| Pull to refresh | Check for new assets |

## Edge Cases

- **First launch (scan running):** Scan prominent, placeholder thumbnails in pillars
- **No pillars (skipped onboarding):** "Set up your brand" CTA
- **Zero assets:** Empty state illustration
- **Scan paused + app killed:** "Resume?" on relaunch
- **All classified, no posts:** Nudge to create first post

## Acceptance Criteria

- [ ] Scan card reflects correct state (4 variants)
- [ ] Pillar cards show real thumbnails (SwiftData query)
- [ ] Bento grid layout (no horizontal scroll)
- [ ] Quick actions navigate correctly
- [ ] Pull to refresh works
- [ ] 3-second rule respected
