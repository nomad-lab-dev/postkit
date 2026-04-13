# PostKit — Product Roadmap

**Version:** 1.0 · **Date:** April 13, 2026

---

## Timeline

### Phase 1 — MVP (April 14-18, 2026)

**Ship target : vendredi 18 avril**

Core features :
- [ ] Projet Xcode multiplateforme (iOS + macOS)
- [ ] SwiftData models + PersistenceService protocol
- [ ] PhotoKit service (read assets, EXIF, create albums)
- [ ] Core ML on-device classification
- [ ] Gemini Flash cloud classification (behind protocol)
- [ ] Batch scan pipeline (30-day windows, incremental)
- [ ] Pillar CRUD (bento grid, emoji auto-suggest)
- [ ] Classification queue (bento selector)
- [ ] Classification view (swipe mode)
- [ ] Explore grid (rich filters)
- [ ] Post assembly (multi-select → name → save)
- [ ] Export post as Photos album
- [ ] Onboarding 5 etapes
- [ ] TestFlight build + App Store submission

### Phase 2 — Monetisation (April 21-30, 2026)

**Target : premieres conversions**

- [ ] Template builder (slot-based)
- [ ] AI auto-fill templates
- [ ] AI hook + caption generation
- [ ] Brand brainstorming (30 questions, stacked cards)
- [ ] Persona synthesis
- [ ] Paywall Pro (StoreKit 2)
- [ ] In-app subscription management

### Phase 3 — Growth (May 2026)

- [ ] LinkedIn API integration (1st platform)
- [ ] Instagram posting (Share Sheet fallback)
- [ ] Tone per platform in persona editor
- [ ] iCloud sync (CloudKit)
- [ ] Landing page publique
- [ ] Product Hunt launch
- [ ] ASO iteration #1

### Phase 4 — WWDC Ready (June 2026)

- [ ] Adopt new Apple AI features (Core ML, Vision)
- [ ] Gemma on Hetzner (zero-cost classification)
- [ ] Apple Notes integration
- [ ] Multi-platform direct posting
- [ ] Grid mode in classification view
- [ ] Asset detail sheet (full editor)
- [ ] Advanced search (natural language)

---

## Scope Check Reminder

**Mercredi 16 avril** : faire le point dev. Qu'est-ce qui est fait, qu'est-ce qu'on coupe pour shipper vendredi.

---

## Technical Dependencies

| Dependency | Purpose | Status |
|-----------|---------|--------|
| Xcode 16+ | Build | Ready |
| iOS 18+ / macOS 15+ | Target | Ready |
| Google Generative AI SDK | Gemini Flash | To install |
| PhotoKit (PHPhotoLibrary) | Photo access | Native |
| Core ML + Vision | On-device AI | Native |
| StoreKit 2 | Subscriptions | Phase 2 |
| CloudKit | iCloud sync | Phase 3 |

## Skills to install before dev

```bash
npx skills add https://github.com/avdlee/swiftui-agent-skill --skill swiftui-expert-skill
npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro
```
