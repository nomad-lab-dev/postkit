# 16 — Development Programme · PostKit

**Stack:** SwiftUI · iOS 18+ · Xcode 16+ · Swift 6
**Pattern:** TCA (The Composable Architecture, Point-Free) + SwiftData + Swift Concurrency
**Goal:** Ship MVP Phase 1 in vertical slices. One complete flow per session, each shipped with a `TestStore`.

---

## Architecture Blueprint

### Why this architecture reads as senior-level

- **TCA** — unidirectional flow, value-type state, side effects as first-class values, fully testable without UI
- **`@Reducer` + `@ObservableState`** macros (TCA 1.7+) — native Observation framework integration, no `@Published`
- **`@DependencyClient`** struct-of-closures for every external dep — swap live/preview/test via `withDependencies`
- **Swift 6 `Sendable`** + actor-isolated clients where state is mutable
- **Effects** for all async work (`Effect.run`) — cancellable scan via `cancellable(id:)`
- **`StackState` navigation** — typed, deep-linkable, programmatic
- **SwiftData** wrapped in a `PersistenceClient` dependency (testable, mockable, swappable)
- **Hybrid classifier**: Core ML on-device → Gemini Flash fallback at < 70% confidence
- **`TestStore` per feature** — proves the logic without a simulator

---

## Layer Map

```
PostKit/
├── App/
│   ├── PostKitApp.swift           ← @main, ModelContainer + StoreOf<AppFeature>
│   └── AppFeature.swift           ← root Reducer: TabState + Path stacks per tab
├── Models/                        ← SwiftData @Model classes (untouched by TCA)
│   ├── Pillar.swift
│   ├── ClassifiedPhoto.swift
│   └── GeneratedPost.swift
├── Features/                      ← one folder per feature
│   ├── Onboarding/
│   │   ├── OnboardingFeature.swift   (Reducer + State + Action)
│   │   └── OnboardingView.swift      (StoreOf<OnboardingFeature>)
│   ├── Dashboard/
│   ├── Classification/
│   │   ├── ClassificationQueueFeature.swift
│   │   ├── ClassificationFeature.swift
│   │   └── views…
│   ├── Explore/
│   ├── PostAssembly/
│   ├── PillarEditor/
│   └── Settings/
├── Dependencies/                  ← @DependencyClient struct + live + test
│   ├── PhotoLibraryClient.swift
│   ├── ImageClassifierClient.swift
│   ├── PersistenceClient.swift
│   └── PostGeneratorClient.swift
├── Navigation/
│   └── AppFeature+Path.swift      ← Path enum reducer per tab stack
├── Shared/                        ← reusable views (PillarRowView, ConfidenceBadge…)
└── Utilities/
    └── AppStrings.swift

PostKitTests/
├── OnboardingFeatureTests.swift
├── DashboardFeatureTests.swift
├── ClassificationFeatureTests.swift
└── …
```

---

## Data Models (SwiftData — unchanged)

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
    var platform: SocialPlatform
    var status: PostStatus             // draft | ready | published
    var createdAt: Date
}

enum SocialPlatform: String, Codable, CaseIterable, Sendable {
    case instagram, linkedin, twitter
    var displayName: String { rawValue.capitalized }
    var characterLimit: Int {
        switch self { case .instagram: 2200; case .linkedin: 3000; case .twitter: 280 }
    }
}

enum PillarTone: String, Codable, CaseIterable, Sendable {
    case casual, technical, inspirational
}
```

`@Model` classes stay reference-typed but they live behind `PersistenceClient`. Reducers only ever see value-typed DTOs (e.g. `PillarSnapshot`) when state needs to be `Equatable`.

```swift
// Equatable value-type projection of the @Model — lives in State
struct PillarSnapshot: Equatable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var emoji: String
    var photoCount: Int
    var postsPerWeek: Int
    var colorHex: String

    init(_ pillar: Pillar) {
        self.id = pillar.id
        self.name = pillar.name
        self.emoji = pillar.emoji
        self.photoCount = pillar.photos.count
        self.postsPerWeek = pillar.postsPerWeek
        self.colorHex = pillar.colorHex
    }
}
```

---

## Dependencies — `@DependencyClient` (struct-of-closures)

Every external boundary is a struct of `@Sendable` closures. No protocols. Live impl is built once; test/preview overrides happen via `withDependencies`.

### PhotoLibraryClient

```swift
import Dependencies
import DependenciesMacros
import Photos

@DependencyClient
struct PhotoLibraryClient: Sendable {
    var requestAuthorization: @Sendable () async -> PHAuthorizationStatus = { .notDetermined }
    var fetchRecentPhotos: @Sendable (_ limit: Int) async throws -> [PHAsset]
    var fetchAllPhotos: @Sendable (_ batchSize: Int) -> AsyncStream<[PHAsset]> = { _ in .finished }
    var image: @Sendable (_ asset: PHAsset, _ size: CGSize) async throws -> UIImage
}

extension PhotoLibraryClient: DependencyKey {
    static let liveValue = PhotoLibraryClient(
        requestAuthorization: {
            await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        },
        fetchRecentPhotos: { limit in
            let opts = PHFetchOptions()
            opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            opts.fetchLimit = limit
            let result = PHAsset.fetchAssets(with: .image, options: opts)
            return (0..<result.count).map { result.object(at: $0) }
        },
        fetchAllPhotos: { batchSize in
            AsyncStream { continuation in
                Task {
                    let opts = PHFetchOptions()
                    opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                    let result = PHAsset.fetchAssets(with: .image, options: opts)
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
        },
        image: { asset, size in
            try await withCheckedThrowingContinuation { cont in
                let opts = PHImageRequestOptions()
                opts.deliveryMode = .highQualityFormat
                opts.isSynchronous = false
                PHImageManager.default().requestImage(
                    for: asset, targetSize: size, contentMode: .aspectFit, options: opts
                ) { image, info in
                    if let image { cont.resume(returning: image) }
                    else { cont.resume(throwing: PhotoLibraryError.imageFetchFailed) }
                }
            }
        }
    )

    static let testValue = PhotoLibraryClient()   // unimplemented closures by default
    static let previewValue = PhotoLibraryClient(
        requestAuthorization: { .authorized },
        fetchRecentPhotos: { _ in [] },
        fetchAllPhotos: { _ in .finished },
        image: { _, _ in UIImage(systemName: "photo")! }
    )
}

extension DependencyValues {
    var photoLibrary: PhotoLibraryClient {
        get { self[PhotoLibraryClient.self] }
        set { self[PhotoLibraryClient.self] = newValue }
    }
}
```

### ImageClassifierClient

```swift
@DependencyClient
struct ImageClassifierClient: Sendable {
    var classify: @Sendable (_ image: UIImage) async throws -> ClassificationResult
}

struct ClassificationResult: Equatable, Sendable {
    let pillarName: String
    let confidence: Float
    let suggestedTags: [String]
    let source: ClassificationSource
}

enum ClassificationSource: Sendable, Equatable { case coreML, gemini }

extension ImageClassifierClient: DependencyKey {
    static let liveValue: ImageClassifierClient = {
        let actor = HybridClassifierActor()       // see Hybrid Classifier section
        return ImageClassifierClient(
            classify: { image in try await actor.classify(image) }
        )
    }()

    static let testValue = ImageClassifierClient()
    static let previewValue = ImageClassifierClient(
        classify: { _ in
            ClassificationResult(
                pillarName: ["Automotive", "Travel", "Food"].randomElement()!,
                confidence: .random(in: 0.65...0.95),
                suggestedTags: [],
                source: .coreML
            )
        }
    )
}

extension DependencyValues {
    var imageClassifier: ImageClassifierClient {
        get { self[ImageClassifierClient.self] }
        set { self[ImageClassifierClient.self] = newValue }
    }
}
```

### PersistenceClient (wraps SwiftData)

```swift
@DependencyClient
struct PersistenceClient: Sendable {
    var savePillar: @Sendable (_ pillar: Pillar) async throws -> Void
    var fetchPillars: @Sendable () async throws -> [PillarSnapshot] = { [] }
    var deletePillar: @Sendable (_ id: UUID) async throws -> Void
    var savePhoto: @Sendable (_ photo: ClassifiedPhoto) async throws -> Void
    var fetchPhotos: @Sendable (_ status: ClassifiedPhoto.PhotoStatus?) async throws -> [ClassifiedPhoto] = { _ in [] }
    var savePost: @Sendable (_ post: GeneratedPost) async throws -> Void
    var fetchPosts: @Sendable (_ pillarID: UUID) async throws -> [GeneratedPost] = { _ in [] }
}

extension PersistenceClient: DependencyKey {
    static let liveValue = PersistenceClient.live(container: .shared)
    static let testValue = PersistenceClient()
    static let previewValue = PersistenceClient.live(container: .preview)

    private static func live(container: ModelContainer) -> PersistenceClient {
        // ModelContext is not Sendable — hop to MainActor for writes,
        // or use an actor wrapper.
        PersistenceClient(
            savePillar: { pillar in
                try await MainActor.run {
                    container.mainContext.insert(pillar)
                    try container.mainContext.save()
                }
            },
            fetchPillars: {
                try await MainActor.run {
                    let descriptor = FetchDescriptor<Pillar>(sortBy: [SortDescriptor(\.createdAt)])
                    return try container.mainContext.fetch(descriptor).map(PillarSnapshot.init)
                }
            },
            // …
        )
    }
}

extension DependencyValues {
    var persistence: PersistenceClient {
        get { self[PersistenceClient.self] }
        set { self[PersistenceClient.self] = newValue }
    }
}
```

### PostGeneratorClient (Gemini Flash)

```swift
@DependencyClient
struct PostGeneratorClient: Sendable {
    var generateCaption: @Sendable (
        _ images: [UIImage],
        _ pillar: PillarSnapshot,
        _ platform: SocialPlatform
    ) async throws -> String

    var generateHashtags: @Sendable (
        _ caption: String,
        _ pillar: PillarSnapshot,
        _ platform: SocialPlatform
    ) async throws -> [String]
}

// liveValue uses GoogleGenerativeAI.GenerativeModel("gemini-1.5-flash")
// with structured-output (JSON mode) for reliable parsing.
```

---

## Reducer Pattern — Generic Example

Every feature follows the same shape: `State` (struct, `@ObservableState`, `Equatable`), `Action` (enum), `body` (composing `Reduce` + child reducers).

```swift
import ComposableArchitecture

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var step: Step = .welcome
        var scanProgress: Double = 0
        var scannedCount: Int = 0
        var totalToScan: Int = 20
        var suggestions: IdentifiedArrayOf<PillarSuggestion> = []
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Step: Equatable { case welcome, scanning, suggestions }

    enum Action {
        case getStartedTapped
        case authorizationResponse(PHAuthorizationStatus)
        case scanProgressed(ClassificationResult, asset: PHAsset)
        case scanFinished
        case suggestionToggled(PillarSuggestion.ID)
        case startPostKitTapped
        case persistResponse(Result<Void, Error>)
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {
            case openSettingsTapped
        }
    }

    @Dependency(\.photoLibrary) var photoLibrary
    @Dependency(\.imageClassifier) var classifier
    @Dependency(\.persistence) var persistence
    @Dependency(\.openURL) var openURL

    private enum CancelID { case quickScan }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .getStartedTapped:
                return .run { send in
                    let status = await photoLibrary.requestAuthorization()
                    await send(.authorizationResponse(status))
                }

            case .authorizationResponse(.authorized), .authorizationResponse(.limited):
                state.step = .scanning
                return .run { [limit = state.totalToScan] send in
                    let assets = try await photoLibrary.fetchRecentPhotos(limit: limit)
                    try await withThrowingTaskGroup(of: (PHAsset, ClassificationResult).self) { group in
                        for asset in assets {
                            group.addTask {
                                let img = try await photoLibrary.image(
                                    for: asset, size: CGSize(width: 299, height: 299)
                                )
                                let result = try await classifier.classify(img)
                                return (asset, result)
                            }
                        }
                        for try await (asset, result) in group {
                            await send(.scanProgressed(result, asset: asset))
                        }
                    }
                    await send(.scanFinished)
                }
                .cancellable(id: CancelID.quickScan)

            case .authorizationResponse:
                state.alert = .photoAccessDenied
                return .none

            case let .scanProgressed(result, _):
                state.scannedCount += 1
                state.scanProgress = Double(state.scannedCount) / Double(state.totalToScan)
                state.suggestions = state.suggestions.upserting(
                    PillarSuggestion(name: result.pillarName, increment: 1)
                )
                return .none

            case .scanFinished:
                state.step = .suggestions
                return .none

            case let .suggestionToggled(id):
                state.suggestions[id: id]?.isSelected.toggle()
                return .none

            case .startPostKitTapped:
                let selected = state.suggestions.filter(\.isSelected)
                return .run { send in
                    do {
                        for suggestion in selected {
                            try await persistence.savePillar(
                                Pillar(name: suggestion.name, emoji: suggestion.emoji)
                            )
                        }
                        await send(.persistResponse(.success(())))
                    } catch {
                        await send(.persistResponse(.failure(error)))
                    }
                }

            case .persistResponse(.success):
                return .none   // parent dismisses the sheet on this signal

            case .persistResponse(.failure):
                state.alert = .saveFailed
                return .none

            case .alert(.presented(.openSettingsTapped)):
                return .run { _ in
                    await openURL(URL(string: UIApplication.openSettingsURLString)!)
                }

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// Alerts as static factories
extension AlertState where Action == OnboardingFeature.Action.Alert {
    static let photoAccessDenied = AlertState<OnboardingFeature.Action.Alert> {
        TextState("Photo access required")
    } actions: {
        ButtonState(action: .openSettingsTapped) { TextState("Open Settings") }
        ButtonState(role: .cancel) { TextState("Cancel") }
    } message: {
        TextState("PostKit needs access to your camera roll to classify photos.")
    }

    static let saveFailed = AlertState<OnboardingFeature.Action.Alert> {
        TextState("Couldn't save pillars")
    } actions: {
        ButtonState(role: .cancel) { TextState("OK") }
    }
}
```

### View consumption

```swift
struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        Group {
            switch store.step {
            case .welcome:
                WelcomeStep { store.send(.getStartedTapped) }
            case .scanning:
                ScanningStep(progress: store.scanProgress, count: store.scannedCount)
            case .suggestions:
                SuggestionsStep(
                    suggestions: store.suggestions,
                    onToggle: { store.send(.suggestionToggled($0)) },
                    onConfirm: { store.send(.startPostKitTapped) }
                )
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}
```

Zero logic in the view — only `switch store.step` for rendering and direct `store.send` for intents.

---

## Navigation Architecture — `AppFeature` root

One root reducer composes the whole tree. Each tab owns its own `StackState<Path.State>`.

```swift
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .home
        var onboarding: OnboardingFeature.State?   // present as sheet if not onboarded
        var dashboard = DashboardFeature.State()
        var classify = ClassificationQueueFeature.State()
        var create = PostAssemblyEntryFeature.State()
        var settings = SettingsFeature.State()
        var homePath = StackState<HomePath.State>()
        var classifyPath = StackState<ClassifyPath.State>()
        var createPath = StackState<CreatePath.State>()
    }

    enum Tab: Equatable { case home, classify, create, settings }

    enum Action {
        case appLaunched
        case onboardingFinished
        case tabSelected(Tab)
        case onboarding(OnboardingFeature.Action)
        case dashboard(DashboardFeature.Action)
        case classify(ClassificationQueueFeature.Action)
        case create(PostAssemblyEntryFeature.Action)
        case settings(SettingsFeature.Action)
        case homePath(StackAction<HomePath.State, HomePath.Action>)
        case classifyPath(StackAction<ClassifyPath.State, ClassifyPath.Action>)
        case createPath(StackAction<CreatePath.State, CreatePath.Action>)
    }

    @Dependency(\.persistence) var persistence
    @Dependency(\.userDefaults) var userDefaults

    var body: some ReducerOf<Self> {
        Scope(state: \.dashboard, action: \.dashboard) { DashboardFeature() }
        Scope(state: \.classify, action: \.classify) { ClassificationQueueFeature() }
        Scope(state: \.create, action: \.create) { PostAssemblyEntryFeature() }
        Scope(state: \.settings, action: \.settings) { SettingsFeature() }

        Reduce { state, action in
            switch action {
            case .appLaunched:
                if !userDefaults.bool(forKey: "onboardingComplete") {
                    state.onboarding = OnboardingFeature.State()
                }
                return .none

            case .onboarding(.persistResponse(.success)):
                state.onboarding = nil
                userDefaults.set(true, forKey: "onboardingComplete")
                return .send(.dashboard(.startFullScanRequested))

            case .onboardingFinished:
                state.onboarding = nil
                return .none

            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            case .dashboard(.pillarTapped(let snapshot)):
                state.createPath.append(.photoSelection(.init(pillar: snapshot)))
                state.selectedTab = .create
                return .none

            // forward child actions / handle navigation deltas …

            default:
                return .none
            }
        }
        .ifLet(\.onboarding, action: \.onboarding) { OnboardingFeature() }
        .forEach(\.homePath, action: \.homePath)
        .forEach(\.classifyPath, action: \.classifyPath)
        .forEach(\.createPath, action: \.createPath)
    }
}

// MARK: - Path enums (one per tab stack)

@Reducer
enum HomePath {
    case pillarDetail(PillarDetailFeature)
    case pillarEditor(PillarEditorFeature)
}

@Reducer
enum ClassifyPath {
    case classify(ClassificationFeature)
}

@Reducer
enum CreatePath {
    case photoSelection(PostAssemblyFeature)
    case platformExport(PlatformExportFeature)
}
```

### Root view

```swift
struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            NavigationStack(
                path: $store.scope(state: \.homePath, action: \.homePath)
            ) {
                DashboardView(store: store.scope(state: \.dashboard, action: \.dashboard))
            } destination: { store in
                switch store.case {
                case let .pillarDetail(s): PillarDetailView(store: s)
                case let .pillarEditor(s): PillarEditorView(store: s)
                }
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(AppFeature.Tab.home)

            // Classify tab, Create tab, Settings tab — same shape
        }
        .sheet(item: $store.scope(state: \.onboarding, action: \.onboarding)) { store in
            OnboardingView(store: store)
        }
        .task { await store.send(.appLaunched).finish() }
    }
}
```

---

## Hybrid Classifier — Actor inside the live client

The actor is an implementation detail of `ImageClassifierClient.liveValue`. The reducer only sees the dependency closure.

```swift
actor HybridClassifierActor {
    private let coreMLModel: VNCoreMLModel
    private let geminiClient: GenerativeModel
    private let confidenceThreshold: Float = 0.70

    init() {
        let config = MLModelConfiguration()
        let model = try! MobileNetV2(configuration: config).model
        self.coreMLModel = try! VNCoreMLModel(for: model)
        self.geminiClient = GenerativeModel(name: "gemini-1.5-flash", apiKey: Secrets.geminiKey)
    }

    func classify(_ image: UIImage) async throws -> ClassificationResult {
        let local = try await classifyOnDevice(image)
        if local.confidence >= confidenceThreshold {
            return local                      // fast path, free, private
        }
        return try await classifyWithGemini(image, hint: local)
    }

    private func classifyOnDevice(_ image: UIImage) async throws -> ClassificationResult {
        try await withCheckedThrowingContinuation { cont in
            guard let cgImage = image.cgImage else {
                cont.resume(throwing: ClassifierError.invalidImage); return
            }
            let request = VNCoreMLRequest(model: coreMLModel) { request, error in
                if let error { cont.resume(throwing: error); return }
                guard let results = request.results as? [VNClassificationObservation],
                      let top = results.first else {
                    cont.resume(throwing: ClassifierError.noResults); return
                }
                cont.resume(returning: ClassificationResult(
                    pillarName: PillarMapping.label(for: top.identifier),
                    confidence: top.confidence,
                    suggestedTags: results.prefix(3).map(\.identifier),
                    source: .coreML
                ))
            }
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }

    private func classifyWithGemini(_ image: UIImage, hint: ClassificationResult) async throws -> ClassificationResult {
        // Send base64 image + structured prompt. Use GenerationConfig(responseMIMEType: "application/json")
        // Parse {pillarName, confidence, tags} → ClassificationResult(source: .gemini)
        …
    }
}
```

---

## Full Scan — Cancellable Effect with structured concurrency

```swift
@Reducer
struct DashboardFeature {
    @ObservableState
    struct State: Equatable {
        var pillars: IdentifiedArrayOf<PillarSnapshot> = []
        var totalPhotosSorted: Int = 0
        var isScanning = false
        var scanProgress: Double = 0
    }

    enum Action {
        case onAppear
        case startFullScanRequested
        case cancelScanTapped
        case pillarTapped(PillarSnapshot)
        case addPillarTapped
        case batchProcessed(count: Int, perPillar: [String: Int])
        case scanFinished
        case pillarsLoaded([PillarSnapshot])
    }

    @Dependency(\.photoLibrary) var photoLibrary
    @Dependency(\.imageClassifier) var classifier
    @Dependency(\.persistence) var persistence

    private enum CancelID { case fullScan }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let pillars = try await persistence.fetchPillars()
                    await send(.pillarsLoaded(pillars))
                }

            case .startFullScanRequested:
                state.isScanning = true
                state.scanProgress = 0
                return .run { send in
                    for await batch in photoLibrary.fetchAllPhotos(batchSize: 30) {
                        try Task.checkCancellation()
                        let perPillar = try await withThrowingTaskGroup(of: ClassificationResult.self) { group in
                            for asset in batch {
                                group.addTask {
                                    let img = try await photoLibrary.image(
                                        for: asset, size: CGSize(width: 299, height: 299)
                                    )
                                    return try await classifier.classify(img)
                                }
                            }
                            var counts: [String: Int] = [:]
                            for try await r in group { counts[r.pillarName, default: 0] += 1 }
                            return counts
                        }
                        await send(.batchProcessed(count: batch.count, perPillar: perPillar))
                    }
                    await send(.scanFinished)
                }
                .cancellable(id: CancelID.fullScan)

            case .cancelScanTapped:
                state.isScanning = false
                return .cancel(id: CancelID.fullScan)

            case let .batchProcessed(count, perPillar):
                state.totalPhotosSorted += count
                for (pillarName, n) in perPillar {
                    if let i = state.pillars.firstIndex(where: { $0.name == pillarName }) {
                        state.pillars[i].photoCount += n
                    }
                }
                return .none

            case .scanFinished:
                state.isScanning = false
                return .none

            case let .pillarsLoaded(pillars):
                state.pillars = IdentifiedArray(uniqueElements: pillars)
                return .none

            case .pillarTapped, .addPillarTapped:
                return .none   // handled by AppFeature parent
            }
        }
    }
}
```

---

## TestStore Pattern — proves logic without UI

```swift
import ComposableArchitecture
import XCTest

@MainActor
final class OnboardingFeatureTests: XCTestCase {
    func test_quickScan_classifiesPhotos_andEmitsSuggestions() async {
        let asset1 = PHAsset()   // (mock factory in real code)
        let asset2 = PHAsset()

        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        } withDependencies: {
            $0.photoLibrary.requestAuthorization = { .authorized }
            $0.photoLibrary.fetchRecentPhotos = { _ in [asset1, asset2] }
            $0.photoLibrary.image = { _, _ in UIImage() }
            $0.imageClassifier.classify = { _ in
                ClassificationResult(
                    pillarName: "Automotive", confidence: 0.9,
                    suggestedTags: [], source: .coreML
                )
            }
        }

        await store.send(.getStartedTapped)
        await store.receive(\.authorizationResponse) { state in
            state.step = .scanning
        }
        await store.receive(\.scanProgressed) { state in
            state.scannedCount = 1
            state.scanProgress = 0.05
            state.suggestions = [PillarSuggestion(name: "Automotive", increment: 1)]
        }
        await store.receive(\.scanProgressed) { state in
            state.scannedCount = 2
            state.scanProgress = 0.10
            state.suggestions[0].count = 2
        }
        await store.receive(\.scanFinished) { state in
            state.step = .suggestions
        }
    }
}
```

This is the interview superpower: you can demo the entire onboarding flow without launching the app, no mocks framework, no waiting for a simulator.

---

## Build Order — Vertical Slices

Each slice = `Feature` (Reducer + State + Action) + View + Dependencies wiring + at least one TestStore for non-trivial logic.

```
Slice 0 │ Foundation       │ TCA SPM, AppFeature shell, RootView with TabView, empty Path enums
Slice 1 │ Onboarding       │ OnboardingFeature + view, PhotoLibrary + ImageClassifier (stub)
Slice 2 │ Dashboard        │ DashboardFeature + full scan Effect, real Core ML, Gemini fallback
Slice 3 │ Classification   │ ClassificationQueueFeature + ClassificationFeature (Stack child)
Slice 4 │ Explore          │ ExploreFeature with filtering, lazy thumbnail loading
Slice 5 │ Post Assembly    │ PostAssemblyFeature + PostGeneratorClient (Gemini structured output)
Slice 6 │ Pillar Editor    │ PillarEditorFeature (stack child of Home)
Slice 7 │ Settings + Pro   │ SettingsFeature + StoreKitClient + PaywallFeature
```

---

## Screen Wireframes

### SLICE 0 — App Shell

```
┌─────────────────────────────┐
│  PostKitApp                 │
│  ┌───────────────────────┐  │
│  │  AppView              │  │
│  │  ┌─────────────────┐  │  │
│  │  │  TabView        │  │  │
│  │  │  ┌───┬───┬───┐  │  │  │
│  │  │  │ 🏠│ 📸│ ✍️│  │  │  │
│  │  │  └───┴───┴───┘  │  │  │
│  │  └─────────────────┘  │  │
│  └───────────────────────┘  │
└─────────────────────────────┘

Entry condition: !userDefaults.onboardingComplete → onboarding sheet
Entry condition: pillars exist → Dashboard
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

Feature: OnboardingFeature
State.step: .welcome
Action: .getStartedTapped → request photo permission
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
│  │      14 / 20         │    │  ← scannedCount / totalToScan
│  └──────────────────────┘    │
│                              │
│  ┌─────────────────────────┐ │
│  │ [Live thumbnail grid]   │ │  ← 3-col grid, photos appear
│  │  🚗 🌍 ☕ 💼 🏋️ 📸   │ │    via .scanProgressed
│  │  🚗 🌍 ☕ 💼 🏋️ 📸   │ │
│  └─────────────────────────┘ │
│                              │
│  PostKit is learning         │
│  your content style…         │  ← Subtitle
└──────────────────────────────┘

State.step: .scanning
Effect: cancellable(id: CancelID.quickScan), TaskGroup over 20 PHAssets
```

**Screen 3 · Pillar Suggestions**
```
┌──────────────────────────────┐
│   We found your pillars      │  ← Title
│   Confirm or adjust:         │
│                              │
│  ┌────────────────────────┐  │
│  │ 🚗 Automotive  [✓] [−] │  │  ← suggestionToggled(id)
│  │    47 photos            │  │
│  ├────────────────────────┤  │
│  │ 🌍 Travel      [✓] [−] │  │
│  │    32 photos            │  │
│  ├────────────────────────┤  │
│  │ ☕ Food        [✓] [−] │  │
│  │    18 photos            │  │
│  └────────────────────────┘  │
│                              │
│  ┌──────────────────────┐    │
│  │  Start PostKit  →    │    │  ← .startPostKitTapped
│  └──────────────────────┘    │
└──────────────────────────────┘

State.step: .suggestions
Action: .startPostKitTapped → persistence.savePillar(...) → AppFeature dismisses sheet
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
│  │ Photos    │ Active      │ │     state.totalPhotosSorted
│  │ sorted    │ Pillars     │ │     state.pillars.count
│  │ +12 today │ 3 ready     │ │
│  └───────────┴─────────────┘ │
│                              │
│  YOUR PILLARS                │
│  ┌────────────────────────┐  │
│  │ 🚗 Automotive    47 ↗  │  │  ← .pillarTapped(snapshot)
│  │ ████████░░ 84%  3/wk   │  │
│  ├────────────────────────┤  │
│  │ 🌍 Travel        32 ↗  │  │
│  │ ██████░░░░ 64%  2/wk   │  │
│  └────────────────────────┘  │
│                              │
│  [Scanning ░░░ 42%   ✕]      │  ← .cancelScanTapped → Effect.cancel(id:)
└──────────────────────────────┘

Feature: DashboardFeature
Parent (AppFeature) intercepts .pillarTapped → pushes CreatePath.photoSelection
```

---

### SLICE 3 — Classification

**Screen 3a · Queue View**
```
┌──────────────────────────────┐
│  Classify           Filter   │
├──────────────────────────────┤
│  38 photos to review         │
│  ┌─────┬─────┬─────┐         │
│  │[img]│[img]│[img]│         │  ← LazyVGrid
│  │ 🚗? │ 🌍? │  ?  │         │    pillar emoji = AI suggestion
│  ├─────┼─────┼─────┤         │
│  │[img]│[img]│[img]│         │
│  └─────┴─────┴─────┘         │
│                              │
│  [Classify All — Accept AI]  │  ← .acceptAllTapped (batch effect)
└──────────────────────────────┘

Feature: ClassificationQueueFeature
Tap photo → state.path.append(.classify(.init(asset:))) (StackState)
```

**Screen 3b · Classification Card (swipe)**
```
┌──────────────────────────────┐
│  ← Library  Classify  Filter │
│  🚗 Automotive  ████░░  7/38 │
│                              │
│  ┌──────────────────────┐    │
│  │   [Full photo]       │    │  ← swipe right = .confirm(pillar)
│  │                      │    │    swipe left  = .reject
│  │   AI 87% ✓           │    │
│  │  track day  porsche  │    │
│  │  📍 Barcelona        │    │
│  └──────────────────────┘    │
│                              │
│   [✕ Reject] [↩ Undo] [✓]   │
└──────────────────────────────┘

Feature: ClassificationFeature (child of Queue via StackState)
DragGesture offset stays in @State (UI-only), action fires on threshold
```

---

### SLICE 4 — Explore Grid

```
┌──────────────────────────────┐
│  Explore              Filter │
├──────────────────────────────┤
│  [All] [🚗] [🌍] [☕] [💼]   │  ← .pillarFilterChanged(id?)
├──────────────────────────────┤
│  ┌─────┬─────┬─────┐         │
│  │[img]│[img]│[img]│         │
│  │ 🚗  │ 🌍  │ 🚗  │         │
│  ├─────┼─────┼─────┤         │
│  │[img]│[img]│[img]│         │
│  └─────┴─────┴─────┘         │
│                              │
│  [Cadrage] [Lieu] [Moment]   │  ← .secondaryFilterChanged(...)
└──────────────────────────────┘

Feature: ExploreFeature
Effect: persistence.fetchPhotos with composed predicate
```

---

### SLICE 5 — Post Assembly (2 screens)

**Screen 5a · Photo + Caption**
```
┌──────────────────────────────┐
│  ← Automotive  Post Builder  │
│                       Save   │
├──────────────────────────────┤
│  [img✓][img ][img ][img ][+] │  ← .photoToggled(id)
├──────────────────────────────┤
│  Instagram  LinkedIn  Twitter│  ← .platformSelected(.x)
├──────────────────────────────┤
│  POST PREVIEW                │
│  ┌────────────────────────┐  │
│  │ [selected photo]       │  │
│  │ 🚗 Automotive          │  │
│  │ ✦ AI Generated         │  │
│  │ Track day at Circuit…  │  │  ← TextEditor bound to $store.caption
│  │ #automotive #trackday  │  │
│  │              218/2200  │  │
│  └────────────────────────┘  │
│  ┌──┐ ┌────────────────────┐ │
│  │🔄│ │ Post to Instagram  │ │  ← .regenerateTapped / .postTapped
│  └──┘ └────────────────────┘ │
└──────────────────────────────┘

Feature: PostAssemblyFeature
Caption Effect: .cancellable(id: GenerationID) — switching platform cancels in-flight
```

**Screen 5b · Platform Export**
```
┌──────────────────────────────┐
│  Share                  Done │
├──────────────────────────────┤
│  [Post mini preview]         │
│                              │
│  SHARE TO                    │
│  📸 Instagram    [ON  ●]    │
│  💼 LinkedIn     [ON  ●]    │
│  𝕏  Twitter      [off ○]   │
│                              │
│  [ Share Now  [2] ]          │  ← UIActivityViewController via .share
└──────────────────────────────┘
```

---

### SLICE 6 — Pillar Editor

```
┌──────────────────────────────┐
│  ← Dashboard  Edit Pillar    │
│                       Save   │
├──────────────────────────────┤
│         🚗                   │  ← .emojiPickerTapped (sheet)
│       Automotive             │
├──────────────────────────────┤
│  PILLAR NAME                 │
│  [Automotive          ]      │  ← $store.name
│  ABOUT THIS PILLAR           │
│  [Cars, track days…   ]      │
│  BRAND TONE                  │
│  [Casual][Technical✓][Insp.] │
│  TOPICS                      │
│  [#automotive][#trackday][+] │
│  POSTING FREQUENCY           │
│  Posts per week  [−] 3 [+]   │
├──────────────────────────────┤
│  [ 🚗 Save Pillar ]          │
└──────────────────────────────┘

Feature: PillarEditorFeature
State.mode: .create | .edit(PillarSnapshot)
```

---

### SLICE 7 — Settings + Paywall

```
┌──────────────────────────────┐
│  Settings                    │
├──────────────────────────────┤
│  ACCOUNT                     │
│  → PostKit Pro          Free │  ← .proRowTapped → sheet PaywallFeature
│  → Restore Purchases         │
├──────────────────────────────┤
│  LIBRARY                     │
│  → Photo Access      Full ›  │
│  → Re-scan Library       ›   │
│  → Clear All Data        ›   │
├──────────────────────────────┤
│  ABOUT                       │
│  → Privacy Policy        ›   │
│  → Rate PostKit          ›   │
│  → Version            1.0.0  │
└──────────────────────────────┘

Feature: SettingsFeature
@Presents var paywall: PaywallFeature.State?
StoreKitClient as @DependencyClient
```

---

## Reducer Signatures — Quick Reference

```swift
@Reducer struct OnboardingFeature {
    @ObservableState struct State: Equatable {
        var step: Step
        var scanProgress: Double
        var scannedCount: Int
        var totalToScan: Int
        var suggestions: IdentifiedArrayOf<PillarSuggestion>
        @Presents var alert: AlertState<Action.Alert>?
    }
    enum Action { case getStartedTapped, authorizationResponse(PHAuthorizationStatus),
                       scanProgressed(ClassificationResult, asset: PHAsset), scanFinished,
                       suggestionToggled(PillarSuggestion.ID), startPostKitTapped,
                       persistResponse(Result<Void, Error>), alert(PresentationAction<Alert>) }
}

@Reducer struct DashboardFeature {
    @ObservableState struct State: Equatable {
        var pillars: IdentifiedArrayOf<PillarSnapshot>
        var totalPhotosSorted: Int
        var isScanning: Bool
        var scanProgress: Double
    }
    enum Action { case onAppear, startFullScanRequested, cancelScanTapped,
                       pillarTapped(PillarSnapshot), addPillarTapped,
                       batchProcessed(count: Int, perPillar: [String: Int]),
                       scanFinished, pillarsLoaded([PillarSnapshot]) }
}

@Reducer struct ClassificationQueueFeature {
    @ObservableState struct State: Equatable {
        var pendingPhotos: IdentifiedArrayOf<ClassifiedPhotoSnapshot>
        var path = StackState<ClassificationFeature.State>()
    }
    enum Action { case onAppear, photoTapped(id: UUID), acceptAllTapped,
                       photosLoaded([ClassifiedPhotoSnapshot]),
                       path(StackAction<ClassificationFeature.State, ClassificationFeature.Action>) }
}

@Reducer struct ClassificationFeature {
    @ObservableState struct State: Equatable {
        var photo: ClassifiedPhotoSnapshot
        var image: UIImage?
        var aiSuggestion: ClassificationResult?
        var queueIndex: Int
        var queueTotal: Int
        var undoStack: [UndoEntry]
    }
    enum Action { case onAppear, imageLoaded(UIImage),
                       confirmTapped(pillarID: UUID), rejectTapped, undoTapped,
                       persistResponse(Result<Void, Error>) }
}

@Reducer struct ExploreFeature {
    @ObservableState struct State: Equatable {
        var photos: IdentifiedArrayOf<ClassifiedPhotoSnapshot>
        var pillars: IdentifiedArrayOf<PillarSnapshot>
        var selectedPillarID: UUID?
        var statusFilter: ClassifiedPhoto.PhotoStatus?
        var locationFilter: String?
    }
    enum Action { case onAppear, pillarFilterChanged(UUID?), statusFilterChanged(...),
                       photosLoaded([ClassifiedPhotoSnapshot]) }
}

@Reducer struct PostAssemblyFeature {
    @ObservableState struct State: Equatable {
        var pillar: PillarSnapshot
        var eligiblePhotos: IdentifiedArrayOf<ClassifiedPhotoSnapshot>
        var selectedAssetIDs: Set<String>
        var currentPlatform: SocialPlatform
        var caption: String
        var hashtags: [String]
        var isGenerating: Bool
    }
    enum Action { case onAppear, photosLoaded([ClassifiedPhotoSnapshot]),
                       photoToggled(String), platformSelected(SocialPlatform),
                       captionEdited(String), regenerateTapped,
                       captionGenerated(String), hashtagsGenerated([String]),
                       saveTapped, postTapped }
}
```

---

## Interview Showcase — Key Talking Points

| Topic | What to demo |
|-------|-------------|
| **TCA reducer pattern** | Pure value-typed State + Action enum + `body` composition. "I can replay any state by replaying actions." |
| **Effects + cancellation** | Full Scan via `Effect.run` with `.cancellable(id:)`, demo cancel mid-scan |
| **Dependencies** | `@DependencyClient` macro, swap `imageClassifier` for a stub at runtime via `withDependencies` |
| **TestStore** | Run the entire onboarding flow asserting every state transition, no UI, no real PhotoKit |
| **Navigation** | `StackState` per tab, `@Presents` for modals, type-safe stack pushes |
| **Swift 6 concurrency** | `@Sendable` closures everywhere, `actor HybridClassifierActor`, `withThrowingTaskGroup` inside Effects |
| **Hybrid AI** | Core ML on-device → Gemini Flash fallback at 70% confidence threshold |
| **AsyncStream → Effect** | `for await batch in photoLibrary.fetchAllPhotos(batchSize:)` inside `Effect.run` |
| **SwiftData behind a client** | `PersistenceClient` wraps `ModelContainer`, value-typed snapshots in State |
| **Zero logic in Views** | Views consume `StoreOf<Feature>`, dispatch actions, period |

---

## Session Startup Checklist

Each Claude Code session, paste this at the top:

```
Working on PostKit — iOS 18+ SwiftUI app using TCA (Point-Free).
CLAUDE.md is in the repo root — read it first.
Architecture brief: docs/briefs/16-dev-programme.md
Build guide: docs/briefs/17-build-guide.md

Current slice: [SLICE NUMBER + NAME]
Build vertical: Reducer + View + Dependencies wiring + at least one TestStore.
No scaffolding, no TODOs, no @Observable classes, no protocols for services.
```

---

*Phase 2 (post-MVP): StoreKit 2 paywall (`StoreKitClient`), AI caption fine-tuning, CloudKit sync (`CloudKitClient`), LinkedIn direct publish.*
