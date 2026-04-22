# 16 — Development Programme · PostKit

**Stack:** SwiftUI · iOS 18+ · Xcode 16+ · Swift 6  
**Pattern:** MVVM + Protocol DI + `@Observable` + SwiftData + Swift Concurrency  
**Goal:** Ship MVP Phase 1 in vertical slices. One complete flow per session.

---

## Architecture Blueprint

### Why this architecture reads as senior-level

- `@Observable` macro (Swift 5.9+) — not `ObservableObject`/`@Published`
- `@Entry` macro for EnvironmentValues (not EnvironmentObject)
- Protocol-first services — every external dependency behind an interface
- Swift 6 `Sendable` + `@MainActor` isolation throughout
- `AsyncStream` for live scan updates — no Combine, no callbacks
- SwiftData — not CoreData
- Hybrid classifier: Core ML on-device → Gemini Flash fallback at < 70% confidence
- Zero business logic in Views

---

## Layer Map

```
PostKitApp
├── AppContainer          ← bootstraps ModelContainer + live services
├── Models/               ← SwiftData @Model classes
│   ├── Pillar
│   ├── ClassifiedPhoto
│   └── GeneratedPost
├── Services/             ← protocol + live impl + mock impl
│   ├── PhotoLibraryService
│   ├── ImageClassifierService
│   ├── PersistenceService
│   └── PostGeneratorService
├── ViewModels/           ← @Observable @MainActor, one per screen
├── Views/                ← zero logic, read state + fire intents
└── AppStrings            ← all user-facing strings (i18n-ready)
```

---

## Data Models

```swift
// MARK: - SwiftData Models

@Model
final class Pillar {
    var id: UUID
    var name: String
    var emoji: String
    var about: String
    var tone: PillarTone          // enum: casual | technical | inspirational
    var topics: [String]          // #automotive #trackday …
    var postsPerWeek: Int
    var colorHex: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade)
    var photos: [ClassifiedPhoto]

    init(name: String, emoji: String) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.about = ""
        self.tone = .casual
        self.topics = []
        self.postsPerWeek = 3
        self.colorHex = "#8b5cf6"
        self.createdAt = .now
        self.photos = []
    }
}

@Model
final class ClassifiedPhoto {
    var id: UUID
    var assetLocalIdentifier: String   // PHAsset identifier
    var pillarID: UUID?
    var confidence: Float              // 0.0 – 1.0
    var classifiedByAI: Bool           // false = user override
    var tags: [String]
    var location: String?
    var capturedAt: Date?
    var status: PhotoStatus            // pending | classified | rejected

    enum PhotoStatus: String, Codable {
        case pending, classified, rejected
    }
}

@Model
final class GeneratedPost {
    var id: UUID
    var pillarID: UUID
    var photoIDs: [String]             // assetLocalIdentifiers
    var caption: String
    var hashtags: [String]
    var platform: SocialPlatform       // enum
    var status: PostStatus             // draft | ready | published
    var createdAt: Date
}

enum SocialPlatform: String, Codable, CaseIterable {
    case instagram, linkedin, twitter
    var displayName: String { rawValue.capitalized }
    var characterLimit: Int {
        switch self { case .instagram: 2200; case .linkedin: 3000; case .twitter: 280 }
    }
}

enum PillarTone: String, Codable, CaseIterable {
    case casual, technical, inspirational
}
```

---

## Service Protocols

```swift
// MARK: - PhotoLibraryService

protocol PhotoLibraryService: Sendable {
    func requestAuthorization() async -> PHAuthorizationStatus
    func fetchRecentPhotos(limit: Int) async throws -> [PHAsset]
    func fetchAllPhotos(batchSize: Int) -> AsyncStream<[PHAsset]>
    func image(for asset: PHAsset, targetSize: CGSize) async throws -> UIImage
}

// MARK: - ImageClassifierService

struct ClassificationResult: Sendable {
    let pillarName: String
    let confidence: Float
    let suggestedTags: [String]
    let source: ClassificationSource   // .coreML | .gemini
}

enum ClassificationSource: Sendable { case coreML, gemini }

protocol ImageClassifierService: Sendable {
    func classify(_ image: UIImage) async throws -> ClassificationResult
    // Hybrid: Core ML first, Gemini fallback if confidence < 0.70
}

// MARK: - PersistenceService

protocol PersistenceService: Sendable {
    func save(_ pillar: Pillar) async throws
    func fetchPillars() async throws -> [Pillar]
    func deletePillar(_ pillar: Pillar) async throws
    func save(_ photo: ClassifiedPhoto) async throws
    func fetchPhotos(status: ClassifiedPhoto.PhotoStatus) async throws -> [ClassifiedPhoto]
    func save(_ post: GeneratedPost) async throws
    func fetchPosts(for pillarID: UUID) async throws -> [GeneratedPost]
}

// MARK: - PostGeneratorService

protocol PostGeneratorService: Sendable {
    func generateCaption(
        for images: [UIImage],
        pillar: Pillar,
        platform: SocialPlatform
    ) async throws -> String

    func generateHashtags(
        caption: String,
        pillar: Pillar,
        platform: SocialPlatform
    ) async throws -> [String]
}
```

---

## Dependency Injection — @Entry + @Environment

```swift
// MARK: - EnvironmentValues extensions (iOS 18 @Entry macro)

extension EnvironmentValues {
    @Entry var photoLibraryService: any PhotoLibraryService = LivePhotoLibraryService()
    @Entry var classifierService: any ImageClassifierService = HybridClassifierService()
    @Entry var persistenceService: any PersistenceService = LivePersistenceService()
    @Entry var postGeneratorService: any PostGeneratorService = GeminiPostGeneratorService()
}

// MARK: - App entry point

@main
struct PostKitApp: App {
    let container: ModelContainer = {
        let schema = Schema([Pillar.self, ClassifiedPhoto.self, GeneratedPost.self])
        let config = ModelConfiguration("PostKit", schema: schema)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
                // Override services here for previews / testing:
                // .environment(\.classifierService, MockClassifierService())
        }
    }
}

// MARK: - Consuming in a ViewModel

@Observable
@MainActor
final class ClassificationViewModel {
    private let classifier: any ImageClassifierService
    private let persistence: any PersistenceService

    init(
        classifier: any ImageClassifierService,
        persistence: any PersistenceService
    ) {
        self.classifier = classifier
        self.persistence = persistence
    }
}

// MARK: - Consuming in a View (zero logic, just wiring)

struct ClassificationView: View {
    @Environment(\.classifierService) private var classifier
    @Environment(\.persistenceService) private var persistence

    var body: some View {
        ClassificationContent(
            viewModel: ClassificationViewModel(
                classifier: classifier,
                persistence: persistence
            )
        )
    }
}
```

---

## Navigation Architecture

```swift
// Tab-based root with NavigationStack per tab (iOS 18 pattern)

enum AppTab: Hashable { case home, classify, create, settings }

@Observable
@MainActor
final class AppRouter {
    var selectedTab: AppTab = .home
    var homeStack: [HomeRoute] = []
    var classifyStack: [ClassifyRoute] = []
    var createStack: [CreateRoute] = []
}

enum HomeRoute: Hashable {
    case pillarDetail(Pillar)
    case pillarEditor(Pillar?)     // nil = new pillar
}

enum ClassifyRoute: Hashable {
    case queue
    case classify(PHAsset)
}

enum CreateRoute: Hashable {
    case photoSelection(Pillar)
    case postPreview(GeneratedPost)
    case platformExport(GeneratedPost)
}

// Usage in RootView:
struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.homeStack) {
                DashboardView()
                    .navigationDestination(for: HomeRoute.self) { route in
                        switch route {
                        case .pillarDetail(let p): PillarDetailView(pillar: p)
                        case .pillarEditor(let p): PillarEditorView(pillar: p)
                        }
                    }
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(AppTab.home)
            // … other tabs
        }
        .environment(\.appRouter, router)
    }
}
```

---

## Hybrid Classifier — Core ML + Gemini

```swift
// Interview showcase: actor isolation + structured concurrency + fallback chain

actor HybridClassifierService: ImageClassifierService {
    private let coreMLModel: VNCoreMLModel
    private let geminiClient: GenerativeModel
    private let confidenceThreshold: Float = 0.70

    func classify(_ image: UIImage) async throws -> ClassificationResult {
        // Step 1: try on-device first
        let localResult = try await classifyOnDevice(image)

        if localResult.confidence >= confidenceThreshold {
            return localResult                    // fast path, free, private
        }

        // Step 2: fallback to Gemini Flash
        return try await classifyWithGemini(image, hint: localResult)
    }

    private func classifyOnDevice(_ image: UIImage) async throws -> ClassificationResult {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: ClassifierError.invalidImage)
                return
            }
            let request = VNCoreMLRequest(model: coreMLModel) { request, error in
                if let error { continuation.resume(throwing: error); return }
                guard let results = request.results as? [VNClassificationObservation],
                      let top = results.first else {
                    continuation.resume(throwing: ClassifierError.noResults)
                    return
                }
                continuation.resume(returning: ClassificationResult(
                    pillarName: top.identifier,
                    confidence: top.confidence,
                    suggestedTags: results.prefix(3).map(\.identifier),
                    source: .coreML
                ))
            }
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }
}
```

---

## Full Scan — AsyncStream (live Dashboard updates)

```swift
// Interview showcase: AsyncStream + structured concurrency + batch processing

extension LivePhotoLibraryService {
    func fetchAllPhotos(batchSize: Int) -> AsyncStream<[PHAsset]> {
        AsyncStream { continuation in
            Task {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [
                    NSSortDescriptor(key: "creationDate", ascending: false)
                ]
                let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)

                var batch: [PHAsset] = []
                result.enumerateObjects { asset, _, _ in
                    batch.append(asset)
                    if batch.count == batchSize {
                        continuation.yield(batch)
                        batch = []
                    }
                }
                if !batch.isEmpty { continuation.yield(batch) }
                continuation.finish()
            }
        }
    }
}

// Consuming in DashboardViewModel:
func startFullScan() {
    scanTask = Task {
        for await batch in photoLibraryService.fetchAllPhotos(batchSize: 30) {
            let results = try await withThrowingTaskGroup(of: ClassificationResult.self) { group in
                for asset in batch {
                    group.addTask { [weak self] in
                        guard let self else { throw CancellationError() }
                        let image = try await self.photoLibraryService.image(
                            for: asset,
                            targetSize: CGSize(width: 299, height: 299)  // MobileNet input
                        )
                        return try await self.classifier.classify(image)
                    }
                }
                return try await group.reduce(into: []) { $0.append($1) }
            }
            await updatePillars(with: results)
        }
    }
}
```

---

## Build Order — Vertical Slices

Each slice = View + ViewModel + Service impl, fully functional end to end.

```
Slice 0 │ Foundation       │ AppContainer, protocols, empty screens, navigation skeleton
Slice 1 │ Onboarding       │ Welcome → Photo permission → Quick Scan → Pillar suggestions
Slice 2 │ Dashboard        │ Pillar cards, metrics, scan progress, full scan trigger
Slice 3 │ Classification   │ Queue grid → Swipe card → confirm/reject → update pillar
Slice 4 │ Explore          │ Full grid, filter by pillar/date/location/status
Slice 5 │ Post Assembly    │ Photo select → AI caption → platform tabs → export
Slice 6 │ Pillar Editor    │ Create/edit pillar, tone, topics, frequency
Slice 7 │ Settings + Pro   │ Account, Pro paywall (StoreKit 2), privacy
```

---

## Screen Wireframes

### SLICE 0 — App Shell

```
┌─────────────────────────────┐
│  PostKitApp                 │
│  ┌───────────────────────┐  │
│  │  RootView             │  │
│  │  ┌─────────────────┐  │  │
│  │  │  TabView        │  │  │
│  │  │  ┌───┬───┬───┐  │  │  │
│  │  │  │ 🏠│ 📸│ ✍️│  │  │  │
│  │  │  └───┴───┴───┘  │  │  │
│  │  └─────────────────┘  │  │
│  └───────────────────────┘  │
└─────────────────────────────┘

Entry condition: no pillars → show Onboarding sheet
Entry condition: pillars exist → show Dashboard
```

---

### SLICE 1 — Onboarding (3 screens)

**Screen 1 · Welcome**
```
┌──────────────────────────────┐
│  [Status bar]                │
│                              │
│         PostKit              │  ← App logo / icon
│                              │
│   Turn your camera roll      │
│   into daily content.        │  ← Headline
│                              │
│  ┌────────────────────────┐  │
│  │ 📸  Camera Roll        │  │  ← Animated feature bullet
│  │ 🧠  AI Classification  │  │
│  │ 🎯  Content Pillars    │  │
│  │ ✦   Ready to Post      │  │
│  └────────────────────────┘  │
│                              │
│  ┌──────────────────────┐    │
│  │   Get Started  →     │    │  ← Primary CTA
│  └──────────────────────┘    │
│                              │
│  Already have an account?    │  ← Secondary link (Phase 2)
└──────────────────────────────┘

ViewModel: OnboardingViewModel
State: none
Action: .getStarted → request photo permission
```

**Screen 2 · Quick Scan (scanning state)**
```
┌──────────────────────────────┐
│  [Status bar]                │
│                              │
│   Scanning your photos…      │  ← Title
│                              │
│  ┌──────────────────────┐    │
│  │  [Progress ring 68%] │    │  ← Animated circular progress
│  │      68 / 20         │    │  ← "X photos scanned"
│  └──────────────────────┘    │
│                              │
│  ┌─────────────────────────┐ │
│  │ [Live thumbnail grid]   │ │  ← 3-col grid, photos appear
│  │  🚗 🌍 ☕ 💼 🏋️ 📸   │ │    as classified
│  │  🚗 🌍 ☕ 💼 🏋️ 📸   │ │
│  └─────────────────────────┘ │
│                              │
│  PostKit is learning         │
│  your content style…         │  ← Subtitle
└──────────────────────────────┘

Scans: last 20 PHAssets via PhotoLibraryService
Classifier: HybridClassifierService
State: .scanning(progress) | .done([PillarSuggestion])
```

**Screen 3 · Pillar Suggestions**
```
┌──────────────────────────────┐
│  [Status bar]                │
│                              │
│   We found your pillars      │  ← Title
│   Confirm or adjust:         │
│                              │
│  ┌────────────────────────┐  │
│  │ 🚗 Automotive  [✓] [−] │  │  ← Suggested pillar rows
│  │    47 photos            │  │    checkmark = confirm
│  ├────────────────────────┤  │    minus = remove
│  │ 🌍 Travel      [✓] [−] │  │
│  │    32 photos            │  │
│  ├────────────────────────┤  │
│  │ ☕ Food        [✓] [−] │  │
│  │    18 photos            │  │
│  ├────────────────────────┤  │
│  │ + Add a pillar          │  │  ← Optional manual add
│  └────────────────────────┘  │
│                              │
│  ┌──────────────────────┐    │
│  │  Start PostKit  →    │    │  ← Saves pillars → Dashboard
│  └──────────────────────┘    │
└──────────────────────────────┘

Action: .confirm → PersistenceService.save(pillars) → dismiss to Dashboard
```

---

### SLICE 2 — Dashboard

```
┌──────────────────────────────┐
│  9:41          ···  [+]      │  ← Nav: title + add pillar
│  Dashboard                   │
├──────────────────────────────┤
│  ┌───────────┬─────────────┐ │
│  │ 155       │ 6           │ │  ← Metric cards
│  │ Photos    │ Active      │ │
│  │ sorted    │ Pillars     │ │
│  │ +12 today │ 3 ready     │ │
│  └───────────┴─────────────┘ │
│                              │
│  YOUR PILLARS                │  ← Section header
│  ┌────────────────────────┐  │
│  │ 🚗 Automotive    47 ↗  │  │  ← Pillar row (tap → PillarDetail)
│  │ ████████░░ 84%  3/wk   │  │
│  ├────────────────────────┤  │
│  │ 🌍 Travel        32 ↗  │  │
│  │ ██████░░░░ 64%  2/wk   │  │
│  ├────────────────────────┤  │
│  │ ☕ Food & Coffee  28 ↗ │  │
│  │ █████░░░░░ 56%  2/wk   │  │
│  └────────────────────────┘  │
│                              │
│  [Scan in progress ░░░ 42%]  │  ← Full scan live indicator
│                              │
├──────────────────────────────┤
│  🏠    📸    ✍️    ⚙️         │  ← Tab bar
└──────────────────────────────┘

ViewModel: DashboardViewModel
Key state: pillars[], scanProgress: Double, isScanning: Bool
Action: tap row → push HomeRoute.pillarDetail(pillar)
Action: [+] → push HomeRoute.pillarEditor(nil)
```

---

### SLICE 3 — Classification

**Screen 3a · Queue View**
```
┌──────────────────────────────┐
│  ← Back    Classify  Filter  │
├──────────────────────────────┤
│  38 photos to review         │  ← Count header
│                              │
│  ┌─────┬─────┬─────┐         │
│  │[img]│[img]│[img]│         │  ← 3-col grid of unclassified photos
│  │ 🚗? │ 🌍? │  ?  │         │    ? = pending, emoji = AI suggestion
│  ├─────┼─────┼─────┤         │
│  │[img]│[img]│[img]│         │
│  │  ?  │ ☕? │  ?  │         │
│  └─────┴─────┴─────┘         │
│                              │
│  [Classify All ↓]            │  ← Accept all AI suggestions
│                              │
├──────────────────────────────┤
│  🏠    📸    ✍️    ⚙️         │
└──────────────────────────────┘

ViewModel: ClassificationViewModel
Tap photo → push ClassifyRoute.classify(asset)
```

**Screen 3b · Classification Card (swipe UI)**
```
┌──────────────────────────────┐
│  ← Library  Classify  Filter │
│  ┌──────────────────────┐    │
│  │ 🚗 Automotive  7/38  │    │  ← Pillar + progress bar
│  │ ████████░░░░░░░░░░░  │    │
│  └──────────────────────┘    │
│                              │
│  ┌──────────────────────┐    │
│  │                      │    │
│  │   [Full photo]       │    │  ← Photo card (swipe L/R gesture)
│  │                      │    │
│  │   AI 87% ✓           │    │  ← Confidence badge
│  │                      │    │
│  │  track day  porsche  │    │  ← AI-suggested tags (editable)
│  │  📍 Barcelona        │    │
│  └──────────────────────┘    │
│                              │
│     ✕       ↩       ✓        │  ← Reject | Undo | Confirm
│    [red]  [gray]  [green]    │
└──────────────────────────────┘

Gesture: swipe right = confirm, swipe left = reject
ViewModel action: .confirm(asset, pillar) → PersistenceService.save(photo)
ViewModel action: .reject(asset) → photo.status = .rejected
```

---

### SLICE 4 — Explore Grid

```
┌──────────────────────────────┐
│  Explore              Filter │
├──────────────────────────────┤
│  ┌──────────────────────┐    │
│  │ [All] [🚗] [🌍] [☕] │    │  ← Pillar filter pills (horizontal scroll)
│  └──────────────────────┘    │
│                              │
│  ┌─────┬─────┬─────┐         │
│  │[img]│[img]│[img]│         │  ← 3-col masonry grid
│  │ 🚗  │ 🌍  │ 🚗  │         │    emoji overlay = pillar
│  ├─────┼─────┼─────┤         │
│  │[img]│[img]│[img]│         │
│  │ ☕  │ 💼  │ 🌍  │         │
│  └─────┴─────┴─────┘         │
│                              │
│  [Secondary filters row]     │  ← Cadrage | Lieu | Moment | Statut
│                              │
├──────────────────────────────┤
│  🏠    📸    ✍️    ⚙️         │
└──────────────────────────────┘

ViewModel: ExploreViewModel
Key state: selectedPillar: Pillar?, photos: [ClassifiedPhoto]
Filtering: .filter(pillar:, framing:, location:, date:, status:) → requery SwiftData
```

---

### SLICE 5 — Post Assembly (3 screens)

**Screen 5a · Photo Selection**
```
┌──────────────────────────────┐
│  ← Automotive  Post Builder  │
│                   Save       │
├──────────────────────────────┤
│  ┌────────────────────────┐  │
│  │ [img✓][img ][img ][img]│  │  ← Photo strip (tap to select, max 10)
│  │  ✓checked             │  │
│  └────────────────────────┘  │
├──────────────────────────────┤
│  Instagram  LinkedIn  Twitter│  ← Platform tabs
├──────────────────────────────┤
│  POST PREVIEW                │
│  ┌────────────────────────┐  │
│  │ [selected photo]       │  │
│  │ 🚗 Automotive          │  │
│  │                        │  │
│  │ ✦ AI Generated         │  │
│  │ Track day at Circuit…  │  │  ← AI caption (editable textarea)
│  │                        │  │
│  │ #automotive #trackday  │  │  ← Hashtags
│  │              218/2200  │  │
│  └────────────────────────┘  │
│                              │
│  ┌──┐ ┌───────────────────┐  │
│  │🔄│ │  Post to Instagram│  │
│  └──┘ └───────────────────┘  │
└──────────────────────────────┘

ViewModel: PostAssemblyViewModel
Action: 🔄 → regenerate caption via PostGeneratorService
Action: Post → push CreateRoute.platformExport(post)
```

**Screen 5b · Platform Export**
```
┌──────────────────────────────┐
│  ← Post Builder    Share     │
│                      Done    │
├──────────────────────────────┤
│  ┌────────────────────────┐  │
│  │ [photo]  🚗 Automotive │  │  ← Post mini preview
│  │ Track day at Circuit…  │  │
│  └────────────────────────┘  │
│                              │
│  SHARE TO                    │  ← 2 of 4 selected
│  ┌────────────────────────┐  │
│  │ 📸 Instagram   [ON ●] │  │
│  │    Feed Post · 1:1     │  │
│  ├────────────────────────┤  │
│  │ 💼 LinkedIn    [ON ●] │  │
│  │    Article · adapted   │  │
│  ├────────────────────────┤  │
│  │ 𝕏  Twitter    [off ○] │  │
│  │    280 chars           │  │
│  └────────────────────────┘  │
│                              │
│  ┌──────────────────────┐    │
│  │  Share Now  [2]      │    │  ← Triggers iOS share sheet
│  └──────────────────────┘    │
└──────────────────────────────┘
```

---

### SLICE 6 — Pillar Editor

```
┌──────────────────────────────┐
│  ← Dashboard  Edit Pillar    │
│                       Save   │
├──────────────────────────────┤
│         🚗                   │  ← Big emoji (tap to change)
│       Automotive             │
│    47 photos · 84%           │
├──────────────────────────────┤
│  PILLAR NAME                 │
│  ┌────────────────────────┐  │
│  │ Automotive             │  │
│  └────────────────────────┘  │
│  ABOUT THIS PILLAR           │
│  ┌────────────────────────┐  │
│  │ Cars, track days…      │  │
│  └────────────────────────┘  │
│  BRAND TONE                  │
│  [Casual] [Technical✓] [Insp]│
│  TOPICS                      │
│  ┌────────────────────────┐  │
│  │ #automotive #trackday  │  │  ← Chip input
│  │ #porsche + Add         │  │
│  └────────────────────────┘  │
│  POSTING FREQUENCY           │
│  Posts per week  [−] 3 [+]   │
├──────────────────────────────┤
│  [ 🚗 Save Pillar ]          │
└──────────────────────────────┘
```

---

### SLICE 7 — Settings

```
┌──────────────────────────────┐
│  Settings                    │
├──────────────────────────────┤
│  ACCOUNT                     │
│  → PostKit Pro               │  ← Paywall trigger (Phase 2)
│  → Restore Purchases         │
├──────────────────────────────┤
│  LIBRARY                     │
│  → Photo Access      Full ›  │  ← Deep link to iOS Settings
│  → Re-scan Library       ›   │
│  → Clear All Data        ›   │
├──────────────────────────────┤
│  ABOUT                       │
│  → Privacy Policy        ›   │
│  → Rate PostKit          ›   │
│  → Version            1.0.0  │
└──────────────────────────────┘
```

---

## ViewModel Interfaces — Quick Reference

```swift
// All ViewModels: @Observable @MainActor

@Observable @MainActor final class OnboardingViewModel {
    var step: OnboardingStep = .welcome        // .welcome | .scanning | .suggestions
    var scanProgress: Double = 0
    var pillarSuggestions: [PillarSuggestion] = []
    var isLoading = false
    func startQuickScan() async { … }
    func confirmPillars(_ selected: [PillarSuggestion]) async { … }
}

@Observable @MainActor final class DashboardViewModel {
    var pillars: [Pillar] = []
    var isScanning = false
    var scanProgress: Double = 0
    var postsReadyCount: Int = 0
    func startFullScan() { … }          // → AsyncStream
    func cancelScan() { … }
}

@Observable @MainActor final class ClassificationViewModel {
    var queue: [PHAsset] = []
    var currentIndex: Int = 0
    var currentResult: ClassificationResult?
    var isClassifying = false
    func loadNext() async { … }
    func confirm(pillar: Pillar) async { … }
    func reject() async { … }
    func undo() { … }
}

@Observable @MainActor final class ExploreViewModel {
    var photos: [ClassifiedPhoto] = []
    var selectedPillar: Pillar?
    var statusFilter: ClassifiedPhoto.PhotoStatus?
    func applyFilter() async { … }     // requery SwiftData
}

@Observable @MainActor final class PostAssemblyViewModel {
    var selectedAssets: [PHAsset] = []
    var currentPlatform: SocialPlatform = .instagram
    var caption: String = ""
    var hashtags: [String] = []
    var isGenerating = false
    func generateCaption() async throws { … }
    func regenerate() async throws { … }
    func savePost() async throws -> GeneratedPost { … }
}
```

---

## Interview Showcase — Key Talking Points

| Topic | What to demo |
|-------|-------------|
| Swift 6 concurrency | Actor-isolated `HybridClassifierService`, `@Sendable` protocols, structured concurrency in Full Scan |
| `@Observable` | All ViewModels, no `@Published`, no Combine |
| `@Entry` DI | Service injection via EnvironmentValues, mock swap for previews |
| SwiftData | `@Model` with relationships, `ModelContainer`, async fetch |
| AsyncStream | Full Scan live updates → Dashboard real-time refresh |
| Protocol-oriented | Every service behind protocol → 100% testable, mockable |
| Hybrid AI | Core ML first, Gemini fallback — on-device privacy + cloud accuracy |
| Navigation | `NavigationStack` + typed routes enum, programmatic push/pop |
| Zero logic in Views | Every `if` lives in ViewModel, Views are pure render functions |

---

## Session Startup Checklist

Each Claude Code session, paste this at the top:

```
Working on PostKit — iOS 18+ SwiftUI app.
CLAUDE.md is in the repo root — read it first.
Current slice: [SLICE NUMBER + NAME]
Build vertical: View + ViewModel + Service impl, all functional.
No scaffolding, no TODOs, no stubs unless explicitly noted.
```

---

*Phase 2 (post-MVP): StoreKit 2 paywall, AI caption fine-tuning, CloudKit sync, LinkedIn direct publish.*
