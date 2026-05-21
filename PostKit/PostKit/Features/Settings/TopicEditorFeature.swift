// MARK: - PostKit
// TopicEditorFeature.swift — Topic editor reducer: create and edit topics with AI enrichment

import ComposableArchitecture
import Foundation
import PhotosUI
import UIKit

@Reducer
struct TopicEditorFeature {
    @ObservableState
    struct State: Equatable {
        var existingPillarID: UUID?
        var name: String = ""
        var emoji: String = ""
        var about: String = ""
        var tone: PillarTone = .casual
        var topics: [String] = []
        var topicInput: String = ""
        var colorHex: String = "#8b5cf6"
        var referencePhotoIDs: [String] = []
        var referenceTags: [String] = []
        var isEnriching: Bool = false
        var enrichmentApplied: Bool = false
        var isSaving: Bool = false
        var isExtractingTags: Bool = false
        var showRescanAlert: Bool = false
        @Presents var alert: AlertState<Action.Alert>?

        var originalSnapshot: PillarSnapshot?

        var isEditing: Bool { existingPillarID != nil }
        var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

        var hasClassificationChanges: Bool {
            guard let original = originalSnapshot else { return true }
            return name != original.name
                || about != original.about
                || topics != original.topics
                || referenceTags != original.referenceTags
                || referencePhotoIDs != original.referencePhotoIDs
        }

        init() {}

        init(pillar: PillarSnapshot) {
            self.existingPillarID = pillar.id
            self.name = pillar.name
            self.emoji = pillar.emoji
            self.about = pillar.about
            self.tone = pillar.tone
            self.topics = pillar.topics
            self.colorHex = pillar.colorHex
            self.referencePhotoIDs = pillar.referencePhotoIDs
            self.referenceTags = pillar.referenceTags
            self.enrichmentApplied = true
            self.originalSnapshot = pillar
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case enrichRequested
        case enrichmentLoaded(TopicSuggestion)
        case enrichmentFailed
        case addTopicTapped
        case removeTopicTapped(String)
        case photosPicked([String])
        case removeReferencPhoto(String)
        case extractTagsFromPhotos
        case extractTagsCompleted([String])
        case saveTapped
        case confirmRescanTapped
        case saved
        case deleteTapped
        case deleted
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert: Equatable {
            case confirmRescan
            case confirmDelete
        }

        enum Delegate: Equatable {
            case didSave
            case didDelete(UUID)
        }
    }

    @Dependency(\.persistence) var persistence
    @Dependency(\.postGenerator) var postGenerator
    @Dependency(\.photoLibrary) var photoLibrary
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .enrichRequested:
                let input = state.name.trimmingCharacters(in: .whitespaces)
                guard !input.isEmpty else { return .none }
                state.isEnriching = true
                return .run { send in
                    let suggestion = try await postGenerator.enrichTopic(input)
                    await send(.enrichmentLoaded(suggestion))
                } catch: { _, send in
                    await send(.enrichmentFailed)
                }

            case let .enrichmentLoaded(suggestion):
                state.isEnriching = false
                state.enrichmentApplied = true
                state.name = suggestion.name
                state.emoji = suggestion.emoji
                state.about = suggestion.about
                return .none

            case .enrichmentFailed:
                state.isEnriching = false
                return .none

            case .addTopicTapped:
                let topic = state.topicInput.trimmingCharacters(in: .whitespaces)
                guard !topic.isEmpty, !state.topics.contains(topic) else { return .none }
                state.topics.append(topic)
                state.topicInput = ""
                return .none

            case let .removeTopicTapped(topic):
                state.topics.removeAll { $0 == topic }
                return .none

            case let .photosPicked(assetIDs):
                let newIDs = assetIDs.filter { !state.referencePhotoIDs.contains($0) }
                state.referencePhotoIDs.append(contentsOf: newIDs)
                guard !newIDs.isEmpty else { return .none }
                state.isExtractingTags = true
                let fetchImage = photoLibrary.image
                let extractTags = postGenerator.extractImageTags
                return .run { send in
                    var allTags: [String] = []
                    for id in newIDs {
                        if let img = try? await fetchImage(id, Layout.ImageSize.classification) {
                            let tags = (try? await extractTags(img)) ?? []
                            allTags.append(contentsOf: tags)
                        }
                    }
                    await send(.extractTagsCompleted(allTags))
                }

            case let .removeReferencPhoto(id):
                state.referencePhotoIDs.removeAll { $0 == id }
                return .none

            case .extractTagsFromPhotos:
                guard !state.referencePhotoIDs.isEmpty else { return .none }
                state.isExtractingTags = true
                let photoIDs = state.referencePhotoIDs
                let fetchImage = photoLibrary.image
                let extractTags = postGenerator.extractImageTags
                return .run { send in
                    var allTags: [String] = []
                    for id in photoIDs {
                        if let img = try? await fetchImage(id, Layout.ImageSize.classification) {
                            let tags = (try? await extractTags(img)) ?? []
                            allTags.append(contentsOf: tags)
                        }
                    }
                    await send(.extractTagsCompleted(allTags))
                }

            case let .extractTagsCompleted(newTags):
                state.isExtractingTags = false
                let merged = Set(state.referenceTags + newTags)
                state.referenceTags = Array(merged).sorted()
                return .none

            case .saveTapped:
                if state.isEditing && state.hasClassificationChanges {
                    state.alert = .rescanConfirmation
                    return .none
                }
                return saveAndDismiss(state: &state)

            case .confirmRescanTapped:
                return saveAndDismiss(state: &state)

            case .saved:
                return .merge(
                    .send(.delegate(.didSave)),
                    .run { _ in await dismiss() }
                )

            case .deleteTapped:
                state.alert = .deleteConfirmation
                return .none

            case .deleted:
                guard let id = state.existingPillarID else { return .none }
                return .run { send in
                    try await persistence.deletePillar(id)
                    await send(.delegate(.didDelete(id)))
                    await dismiss()
                }

            case .alert(.presented(.confirmRescan)):
                return saveAndDismiss(state: &state)

            case .alert(.presented(.confirmDelete)):
                return .send(.deleted)

            case .alert, .delegate, .binding:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    private func saveAndDismiss(state: inout State) -> Effect<Action> {
        state.isSaving = true
        var snapshot = PillarSnapshot(
            id: state.existingPillarID ?? UUID(),
            name: state.name.trimmingCharacters(in: .whitespaces),
            emoji: state.emoji.isEmpty ? "📌" : state.emoji,
            about: state.about,
            tone: state.tone,
            topics: state.topics,
            referenceTags: state.referenceTags,
            referencePhotoIDs: state.referencePhotoIDs,
            colorHex: state.colorHex
        )
        let needsKeywords = snapshot.referenceTags.isEmpty && snapshot.referencePhotoIDs.isEmpty
        return .run { [postGenerator] send in
            if needsKeywords {
                let keywords = (try? await postGenerator.generatePillarKeywords(
                    snapshot.name, snapshot.about, snapshot.topics
                )) ?? []
                if !keywords.isEmpty {
                    snapshot.referenceTags = keywords
                }
            }
            try await persistence.savePillar(snapshot)
            await send(.saved)
        }
    }
}

extension AlertState where Action == TopicEditorFeature.Action.Alert {
    static let rescanConfirmation = AlertState {
        TextState("Rescan Photos?")
    } actions: {
        ButtonState(action: .confirmRescan) {
            TextState("Save & Rescan")
        }
        ButtonState(role: .cancel) {
            TextState("Cancel")
        }
    } message: {
        TextState("Updating this topic will rescan your library to reclassify photos based on the new criteria.")
    }

    static let deleteConfirmation = AlertState {
        TextState("Delete Topic?")
    } actions: {
        ButtonState(role: .destructive, action: .confirmDelete) {
            TextState("Delete")
        }
        ButtonState(role: .cancel) {
            TextState("Cancel")
        }
    } message: {
        TextState("Photos classified under this topic will become unclassified.")
    }
}
