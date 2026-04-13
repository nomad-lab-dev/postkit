# PillarBox — Design Specification

**Date:** 2026-04-12
**Author:** Nicolas Lucchetta
**Status:** Approved
**Platform:** macOS + iOS (SwiftUI multiplateforme)

---

## 1. Vision

PillarBox is a native Apple app that helps creators organize their photo/video library around personal branding pillars. It scans assets using hybrid AI (on-device + cloud), classifies them by content pillars and descriptive tags, and enables fast content assembly for social media publishing.

**Triple objective:**
1. Personal tool — useful from day one for daily content creation
2. iCloud-ready architecture — sync between Mac and iPhone
3. Portfolio piece — clean MVVM architecture for iOS job interviews

## 2. Architecture

### 2.1 Pattern: MVVM + Protocols + Dependency Injection

```
View (SwiftUI) → ViewModel (@Observable) → Service (Protocol) → Implementation
```

- **Views** are purely declarative, no business logic
- **ViewModels** hold state and logic via @Observable / @Published
- **Services** are defined as protocols, injected via environment or init
- **Implementations** are swappable (test mocks, alternative backends)

### 2.2 Key Protocols

```swift
protocol ImageClassifier {
    func classify(image: Data, pillars: [Pillar]) async throws -> ClassificationResult
}

protocol PersistenceService {
    func savePillar(_ pillar: Pillar) async throws
    func fetchAssets(matching: AssetQuery) async throws -> [Asset]
    func savePost(_ post: Post) async throws
    // ...
}

protocol PhotoLibraryService {
    func requestAccess() async -> Bool
    func fetchAssets(dateRange: DateRange?) async -> [PHAsset]
    func createAlbum(name: String, assets: [PHAsset]) async throws
}

protocol ContentSuggestionService {
    func suggestHook(for assets: [Asset], persona: Persona) async throws -> String
    func suggestCaption(for assets: [Asset], persona: Persona) async throws -> String
}
```

### 2.3 Data Layer

- **SwiftData** as primary implementation of `PersistenceService`
- Protocol abstraction allows Core Data swap (interview talking point)
- iCloud sync via CloudKit (post-MVP, architecture-ready)

### 2.4 Classification Pipeline

```
PhotoKit (metadata: date, location, faces)
    ↓
Core ML (on-device: objects, scene, framing type)
    ↓
Gemini Flash API (cloud: pillar assignment, semantic tags, mood)
    ↓
SwiftData (persist classification results)
```

- **Batch processing:** 30-day windows, most recent first
- **Incremental:** tracks classified vs. unclassified assets
- **On-app-launch:** auto-detects new unclassified assets
- **Manual retrigger:** available anytime
- **Target:** 15,000 assets in 15-30 minutes
- **Confidence routing:** high-confidence (>90%) = auto-save, low = cloud API

## 3. Data Model

### 3.1 Pillar
- `id: UUID`
- `name: String`
- `color: Color` (for UI chips/overlay)
- `icon: String` (SF Symbol name)
- `createdAt: Date`
- `sortOrder: Int`

### 3.2 Tag
- `id: UUID`
- `name: String`
- `type: TagType` (location, timeOfDay, mood, framing, custom)
- `autoDetected: Bool`

### 3.3 Asset
- `id: UUID`
- `phAssetIdentifier: String` (reference to PhotoKit)
- `mediaType: MediaType` (photo, video)
- `pillars: [Pillar]` (many-to-many)
- `tags: [Tag]` (many-to-many)
- `framingType: FramingType?` (pov, detail, wide, portrait)
- `classificationConfidence: Double`
- `classifiedAt: Date?`
- `isClassified: Bool`
- `isUsed: Bool`
- `captureDate: Date`
- `location: String?`
- `timeOfDay: TimeOfDay?` (morning, afternoon, evening, night — from EXIF)

### 3.4 Post
- `id: UUID`
- `name: String`
- `description: String?`
- `status: PostStatus` (draft, ready, published)
- `assets: [Asset]` (ordered, copied into post storage)
- `hook: String?`
- `caption: String?`
- `createdAt: Date`
- `updatedAt: Date`

### 3.5 Persona
- `id: UUID`
- `name: String`
- `bio: String`
- `voiceTone: String`
- `pillars: [Pillar]`
- `targetPlatforms: [String]`
- `onboardingAnswers: [String: String]` (brainstorming Q&A stored)

## 4. UI Structure

### 4.1 Navigation: TabBar (5 tabs)

| Tab | Name | Purpose |
|-----|------|---------|
| 1 | Home | Dashboard: unclassified count, scan progress, quick actions |
| 2 | Explore | Search bar + filters + cards grid with tag overlays |
| 3 | Swipe | Tinder-style classification by pillar |
| 4 | Posts | List of assembled posts with status badges |
| 5 | Profile | Persona settings, pillars management, scan settings |

### 4.2 Key Screens

**Home:**
- Unclassified assets count + progress bar
- "Scan new assets" button
- Quick pillar overview (count per pillar)
- Background scan indicator

**Explore:**
- Search bar (free text + structured filters)
- Filter chips: pillars, tags, framing, date range, location
- Grid of rich cards (thumbnail + pillar badges + tags overlay)
- Multi-select mode → "Create Post" action

**Swipe Mode:**
- Pillar selector at top
- Full-screen asset card
- Swipe right = belongs to pillar, left = doesn't
- Shows AI suggestion badge (correction mode)
- Counter: X / Y remaining

**Post Builder:**
- Post name + description fields
- Ordered asset grid (drag to reorder)
- Status picker (draft / ready / published)
- "Suggest" button → AI-generated hook + caption
- "Export to Album" button → creates Photos album

**Profile/Settings:**
- Persona editor (from onboarding flow)
- Pillars CRUD (create, reorder, edit color/icon, delete)
- Scan settings (batch size, cloud API toggle)
- Classification stats

### 4.3 Design

- Apple native (SF Symbols, system colors, HIG compliant)
- Subtle PillarBox branding: custom accent color, app icon identity
- Liquid Glass ready (iOS 26 / macOS 26)
- Adaptive layout: sidebar on Mac, tab bar on iPhone

## 5. Onboarding Flow

Step-by-step guided flow at first launch:

1. Welcome screen — app purpose
2. "What do you create content about?" → pillar creation
3. "Describe yourself in a few words" → bio/persona seed
4. "What's your tone?" → voice calibration (casual/pro/mix)
5. "Which platforms?" → target platforms
6. Summary → persona card preview
7. "Let's scan your library" → permission request + first scan trigger

## 6. Classification Prompt (Semantic)

The cloud classification prompt must understand context, not just objects:

```
You are classifying photos for a personal branding content library.

The user's persona: {persona}
Their content pillars: {pillars with descriptions}

For this image, determine:
1. Which pillars apply (can be multiple, can be none)
2. Descriptive tags: mood, activity, setting
3. Framing type: POV (first person view), detail (close-up), wide (landscape/environment), portrait (person-focused)
4. A brief content note (what makes this image interesting for content)

Important: Think beyond literal objects. A whiteboard full of post-its is about entrepreneurship/work, not about "office supplies". A laptop in a café is about digital nomad lifestyle, not about "electronics".
```

## 7. MVP Scope (Day 1)

### Must-have:
- [ ] Project setup (SwiftUI multiplatform, SwiftData, MVVM)
- [ ] Persistence protocol + SwiftData implementation
- [ ] PhotoKit integration (read assets, metadata, create albums)
- [ ] Core ML on-device pre-classification
- [ ] Gemini Flash API classifier (behind protocol)
- [ ] Batch scan pipeline (30-day windows, incremental)
- [ ] Pillar CRUD
- [ ] Swipe mode (per-pillar classification/correction)
- [ ] Basic asset grid with pillar/tag overlays
- [ ] Post assembly (multi-select → name → save)
- [ ] Export post as Photos album
- [ ] Onboarding flow
- [ ] Scan progress UI (dedicated + background indicator)

### Post-MVP:
- [ ] Post builder with AI "Suggest" button
- [ ] Advanced search (free text + filters)
- [ ] Apple Notes integration
- [ ] iCloud sync (CloudKit)
- [ ] Content suggestions bank
- [ ] Multiple post templates
- [ ] Asset usage tracking (don't re-suggest)
- [ ] Instagram/TikTok API export
- [ ] Gemma on Hetzner (replace Gemini Flash)
- [ ] Performance tracking (engagement analytics)

## 8. Technical Dependencies

- **Xcode 16+** (SwiftUI, SwiftData)
- **iOS 18+ / macOS 15+** target
- **PhotoKit** (PHPhotoLibrary, PHAsset, PHAssetCollection)
- **Core ML** + **Vision** framework (on-device classification)
- **Google Generative AI SDK** (Gemini Flash API)
- **Swift Concurrency** (async/await, TaskGroup for batch processing)
