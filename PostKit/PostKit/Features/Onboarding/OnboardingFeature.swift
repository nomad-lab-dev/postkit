// MARK: - PostKit
// OnboardingFeature.swift — 5-step onboarding: before/after → magic demo → pillars → live sort → your turn

import ComposableArchitecture
import Foundation
@preconcurrency import Photos
import UIKit

struct OnboardingTopic: Equatable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var emoji: String
    var about: String
    var matchedPhotos: Int = 0
}

@Reducer
struct OnboardingFeature {

    // MARK: - Demo chip (Step 02)

    enum DemoChip: String, Equatable, CaseIterable, Sendable {
        case italy, coffee, build

        var label: String {
            switch self {
            case .italy:  "🌍 Italy"
            case .coffee: "☕ Coffee"
            case .build:  "💼 Build"
            }
        }
    }

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var step: Step = .beforeAfter
        var activeDemoChip: DemoChip = .italy

        // Step 03 — Pillars
        var topicInput: String = ""
        var editingTopicID: OnboardingTopic.ID?
        var topics: IdentifiedArrayOf<OnboardingTopic> = []

        // Step 04 — Live Sort
        var scanProgress: Double = 0
        var scannedCount: Int = 0
        var totalToScan: Int = 20
        var photoAccessDenied: Bool = false
        var emptyGallery: Bool = false

        // Step 05 — Your Turn
        var firstPromptText: String = ""
        var selectedPillarPillID: OnboardingTopic.ID?
        var cloudAIEnabled: Bool = false
        var isSaving: Bool = false

        @Presents var alert: AlertState<Action.Alert>?

        var totalMatchedPhotos: Int {
            topics.reduce(0) { $0 + $1.matchedPhotos }
        }

        /// All pillars sorted by matched photo count, for the pick-pills in step 05.
        var topPillars: [OnboardingTopic] {
            topics.sorted { $0.matchedPhotos > $1.matchedPhotos }
        }

        enum Step: Equatable {
            case beforeAfter, magicDemo, pillars, liveSort, yourTurn
        }
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)

        // Step 01 — Before/After
        case beforeAfterContinueTapped

        // Step 02 — Magic Demo
        case demoChipTapped(DemoChip)
        case magicDemoContinueTapped

        // Photo permission (requested on step 02 → 03 transition)
        case openSettingsTapped
        case sceneDidBecomeActive
        case authorizationResponse(PHAuthorizationStatus)

        // Step 03 — Pillars
        case addTopicTapped
        case topicTapped(OnboardingTopic.ID)
        case topicNameEdited(OnboardingTopic.ID, String)
        case topicEditDone
        case removeTopicTapped(OnboardingTopic.ID)
        case emojiResolved(OnboardingTopic.ID, String)
        case pillarsContinueTapped

        // Step 04 — Live Sort
        case scanStarted(totalPhotos: Int)
        case scanProgressed([ClassificationResult], assetIdentifier: String)
        case scanFinished
        case liveSortContinueTapped

        // Step 05 — Your Turn
        case cloudAIToggled
        case yourTurnPillarPillTapped(OnboardingTopic.ID)
        case generateFirstPostTapped

        // Shared
        case persistResponse(Result<Void, Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert: Equatable {
            case openSettingsTapped
            case retrySaveTapped
        }

        @CasePathable
        enum Delegate: Equatable {
            case startFirstPost(String)
        }
    }

    // MARK: - Dependencies

    @Dependency(\.photoLibrary) var photoLibrary
    @Dependency(\.imageClassifier) var imageClassifier
    @Dependency(\.postGenerator) var postGenerator
    @Dependency(\.persistence) var persistence
    @Dependency(\.gallery) var gallery
    @Dependency(\.userDefaults) var userDefaults
    @Dependency(\.openURL) var openURL
    @Dependency(\.uuid) var uuid

    private enum CancelID: Hashable, Sendable { case quickScan, emojiResolution }

    // MARK: - Reducer

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {

            // ─── Step 01 ───────────────────────────────────────────────────────
            case .beforeAfterContinueTapped:
                state.step = .magicDemo
                return .none

            // ─── Step 02 ───────────────────────────────────────────────────────
            case let .demoChipTapped(chip):
                state.activeDemoChip = chip
                return .none

            case .magicDemoContinueTapped:
                return .run { send in
                    let status = await photoLibrary.requestAuthorization()
                    await send(.authorizationResponse(status))
                }

            // ─── Photo permission ──────────────────────────────────────────────
            case .openSettingsTapped:
                return openSettings()

            case .sceneDidBecomeActive:
                guard state.photoAccessDenied else { return .none }
                let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                if currentStatus == .authorized {
                    return .send(.authorizationResponse(.authorized))
                }
                return .none

            case let .authorizationResponse(status):
                switch status {
                case .authorized:
                    state.photoAccessDenied = false
                    state.step = .pillars
                    if state.topics.isEmpty {
                        state.topics = makeDefaultTopics()
                    }
                    return .none

                case .limited, .denied, .restricted:
                    state.photoAccessDenied = true
                    return .none

                case .notDetermined:
                    return .none

                @unknown default:
                    return .none
                }

            // ─── Step 03 ───────────────────────────────────────────────────────
            case .addTopicTapped:
                let input = state.topicInput.trimmingCharacters(in: .whitespaces)
                guard !input.isEmpty, state.topics.count < 7 else { return .none }
                state.editingTopicID = nil
                state.topics.append(
                    OnboardingTopic(id: uuid(), name: input.capitalized, emoji: "✨", about: "")
                )
                state.topicInput = ""
                return .none

            case let .topicTapped(id):
                state.editingTopicID = id
                return .none

            case let .topicNameEdited(id, name):
                state.topics[id: id]?.name = name
                return .none

            case .topicEditDone:
                if let id = state.editingTopicID,
                   let topic = state.topics[id: id],
                   topic.name.trimmingCharacters(in: .whitespaces).isEmpty {
                    state.topics.remove(id: id)
                }
                state.editingTopicID = nil
                return .none

            case let .removeTopicTapped(id):
                if state.editingTopicID == id { state.editingTopicID = nil }
                state.topics.remove(id: id)
                return .none

            case let .emojiResolved(id, emoji):
                state.topics[id: id]?.emoji = emoji
                return .none

            case .pillarsContinueTapped:
                guard state.topics.count >= 2 else { return .none }
                state.editingTopicID = nil
                state.step = .liveSort
                state.scannedCount = 0
                state.scanProgress = 0
                return startQuickScan(state: state)

            // ─── Step 04 ───────────────────────────────────────────────────────
            case let .scanStarted(totalPhotos):
                state.emptyGallery = totalPhotos == 0
                state.totalToScan = max(totalPhotos, 1)
                return .none

            case let .scanProgressed(results, _):
                state.scannedCount += 1
                state.scanProgress = Double(state.scannedCount) / Double(state.totalToScan)
                for result in results {
                    if let index = state.topics.firstIndex(where: { $0.name == result.pillarName }) {
                        state.topics[index].matchedPhotos += 1
                    }
                }
                return .none

            case .scanFinished:
                state.scanProgress = 1.0
                return .none

            case .liveSortContinueTapped:
                let sorted = state.topics.sorted { $0.matchedPhotos > $1.matchedPhotos }
                if let top = sorted.first {
                    state.firstPromptText = "A post about \(top.name.lowercased())"
                    state.selectedPillarPillID = top.id
                } else if let first = state.topics.first {
                    state.firstPromptText = "A post about \(first.name.lowercased())"
                    state.selectedPillarPillID = first.id
                }
                state.step = .yourTurn
                return .none

            // ─── Step 05 ───────────────────────────────────────────────────────
            case .cloudAIToggled:
                state.cloudAIEnabled.toggle()
                userDefaults.setBool(state.cloudAIEnabled, "cloudAIEnabled")
                return .none

            case let .yourTurnPillarPillTapped(id):
                guard let topic = state.topics[id: id] else { return .none }
                state.selectedPillarPillID = id
                state.firstPromptText = "A post about \(topic.name.lowercased())"
                return .none

            case .generateFirstPostTapped:
                guard !state.isSaving else { return .none }
                state.isSaving = true
                let topics = state.topics
                return .run { [persistence, gallery] send in
                    let existing = try await persistence.fetchPillars()
                    let existingByName = Dictionary(
                        existing.map { ($0.name.lowercased(), $0) },
                        uniquingKeysWith: { first, _ in first }
                    )
                    for topic in topics {
                        if var match = existingByName[topic.name.lowercased()] {
                            match.emoji = topic.emoji
                            match.about = topic.about
                            try await persistence.savePillar(match)
                        } else {
                            try await persistence.savePillar(
                                PillarSnapshot(name: topic.name, emoji: topic.emoji, about: topic.about, referenceTags: [])
                            )
                        }
                    }
                    await gallery.invalidateAll()
                    await send(.persistResponse(.success(())))
                } catch: { error, send in
                    await send(.persistResponse(.failure(error)))
                }

            // ─── Shared ────────────────────────────────────────────────────────
            case .persistResponse(.success):
                state.isSaving = false
                return .send(.delegate(.startFirstPost(state.firstPromptText)))

            case .persistResponse(.failure):
                state.isSaving = false
                state.alert = .saveFailed
                return .none

            case .alert(.presented(.openSettingsTapped)):
                return openSettings()

            case .alert(.presented(.retrySaveTapped)):
                return .send(.generateFirstPostTapped)

            case .alert, .binding, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    // MARK: - Helpers

    private func makeDefaultTopics() -> IdentifiedArrayOf<OnboardingTopic> {
        let defaults: [(String, String)] = [
            ("Cars", "🚗"),
            ("Food & Coffee", "☕"),
            ("Build in public", "💼"),
            ("Travel", "🌍"),
        ]
        return IdentifiedArray(uniqueElements: defaults.map { name, emoji in
            OnboardingTopic(id: uuid(), name: name, emoji: emoji, about: "")
        })
    }

    private func startQuickScan(state: State) -> Effect<Action> {
        let pillarDefs = state.topics.map {
            PillarDefinition(name: $0.name, about: $0.about, referenceTags: [])
        }
        let topicsToResolve = state.topics.elements
        let fetchRecent = photoLibrary.fetchRecentPhotos
        let fetchImage = photoLibrary.image
        let classify = imageClassifier.classify
        let enrichTopic = postGenerator.enrichTopic

        return .merge(
            .run { send in
                let assets = try await fetchRecent(20)
                if assets.isEmpty {
                    await send(.scanStarted(totalPhotos: 0))
                    await send(.scanFinished)
                    return
                }
                await send(.scanStarted(totalPhotos: assets.count))
                try await withThrowingTaskGroup(of: ([ClassificationResult], String)?.self) { group in
                    var inFlight = 0
                    let maxConcurrent = 4
                    for asset in assets {
                        try Task.checkCancellation()
                        if inFlight >= maxConcurrent {
                            if let result = try await group.next(), let (results, assetID) = result {
                                await send(.scanProgressed(results, assetIdentifier: assetID))
                            }
                            inFlight -= 1
                        }
                        group.addTask {
                            let image: UIImage
                            do { image = try await fetchImage(asset.localIdentifier, Layout.ImageSize.classification) }
                            catch is CancellationError { throw CancellationError() }
                            catch { return ([], asset.localIdentifier) }
                            let results: [ClassificationResult]
                            do { results = try await classify(image, pillarDefs) }
                            catch is CancellationError { throw CancellationError() }
                            catch { return ([], asset.localIdentifier) }
                            return (results, asset.localIdentifier)
                        }
                        inFlight += 1
                    }
                    for try await result in group {
                        if let (results, assetID) = result {
                            await send(.scanProgressed(results, assetIdentifier: assetID))
                        }
                    }
                }
                await send(.scanFinished)
            } catch: { _, send in
                await send(.scanFinished)
            }
            .cancellable(id: CancelID.quickScan),

            .run { send in
                await withTaskGroup(of: (OnboardingTopic.ID, String)?.self) { group in
                    for topic in topicsToResolve {
                        group.addTask {
                            guard let suggestion = try? await enrichTopic(topic.name) else { return nil }
                            return (topic.id, suggestion.emoji)
                        }
                    }
                    for await result in group {
                        if let (id, emoji) = result {
                            await send(.emojiResolved(id, emoji))
                        }
                    }
                }
            }
            .cancellable(id: CancelID.emojiResolution)
        )
    }

    private func openSettings() -> Effect<Action> {
        .run { [openURL] _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            await openURL(url)
        }
    }
}

// MARK: - AlertState

extension AlertState where Action == OnboardingFeature.Action.Alert {
    static let saveFailed = AlertState {
        TextState("Save Failed")
    } actions: {
        ButtonState(action: .retrySaveTapped) { TextState("Try Again") }
        ButtonState(role: .cancel) { TextState("Cancel") }
    } message: {
        TextState("Could not save your topics. Please try again.")
    }
}
