// MARK: - PostKit
// PostAssemblyEntryFeature.swift — Post assembly reducer: pillar pick, photo selection, caption generation

import ComposableArchitecture
import SwiftUI
import UIKit

@Reducer
struct PostAssemblyEntryFeature {
    @ObservableState
    struct State: Equatable {
        var step: Step = .pickPillar
        var pillars: [PillarSnapshot] = []
        var selectedPillar: PillarSnapshot?
        var photos: [ClassifiedPhotoSnapshot] = []
        var selectedPhotoIDs: Set<String> = []
        var isLoading: Bool = false
        var platform: SocialPlatform = .instagram
        var caption: String = ""
        var hashtags: [String] = []
        var isGenerating: Bool = false
        @Presents var alert: AlertState<Action.Alert>?

        var canGenerate: Bool {
            !selectedPhotoIDs.isEmpty
        }

        enum Step: Equatable {
            case pickPillar, pickPhotos, editCaption
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case pillarsLoaded([PillarSnapshot])
        case pillarSelected(PillarSnapshot)
        case photosLoaded([ClassifiedPhotoSnapshot])
        case photoToggled(String)
        case continueToCaption
        case captionGenerated(caption: String, hashtags: [String])
        case captionGenerationFailed
        case platformChanged(SocialPlatform)
        case regenerateTapped
        case exportTapped
        case saveTapped
        case saved
        case startOverTapped
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {}
    }

    @Dependency(\.persistence) var persistence
    @Dependency(\.postGenerator) var postGenerator
    @Dependency(\.photoLibrary) var photoLibrary

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.pillars.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    let pillars = try await persistence.fetchPillars()
                    await send(.pillarsLoaded(pillars))
                }

            case let .pillarsLoaded(pillars):
                state.pillars = pillars
                state.isLoading = false
                return .none

            case let .pillarSelected(pillar):
                state.selectedPillar = pillar
                state.selectedPhotoIDs = []
                state.isLoading = true
                state.step = .pickPhotos
                let pillarID = pillar.id
                return .run { send in
                    let photos = try await persistence.fetchPhotosForPillar(pillarID)
                    await send(.photosLoaded(photos))
                }

            case let .photosLoaded(photos):
                state.photos = photos
                state.isLoading = false
                return .none

            case let .photoToggled(assetID):
                if state.selectedPhotoIDs.contains(assetID) {
                    state.selectedPhotoIDs.remove(assetID)
                } else {
                    state.selectedPhotoIDs.insert(assetID)
                }
                return .none

            case .continueToCaption:
                state.step = .editCaption
                state.isGenerating = true
                return generateCaption(state: state)

            case let .captionGenerated(caption, hashtags):
                state.caption = caption
                state.hashtags = hashtags
                state.isGenerating = false
                return .none

            case .captionGenerationFailed:
                state.isGenerating = false
                state.caption = ""
                state.hashtags = []
                return .none

            case let .platformChanged(platform):
                state.platform = platform
                return .none

            case .regenerateTapped:
                state.isGenerating = true
                return generateCaption(state: state)

            case .exportTapped:
                UIPasteboard.general.string = state.caption
                    + (state.hashtags.isEmpty ? "" : "\n\n" + state.hashtags.joined(separator: " "))
                return .none

            case .saveTapped:
                guard let pillar = state.selectedPillar else { return .none }
                let snapshot = GeneratedPostSnapshot(
                    pillarID: pillar.id,
                    photoIDs: Array(state.selectedPhotoIDs),
                    caption: state.caption,
                    hashtags: state.hashtags,
                    platform: state.platform,
                    status: .draft
                )
                return .run { send in
                    try await persistence.savePost(snapshot)
                    await send(.saved)
                }

            case .saved:
                state.alert = AlertState {
                    TextState("Saved")
                } actions: {
                    ButtonState(role: .cancel) { TextState("OK") }
                } message: {
                    TextState("Draft saved successfully.")
                }
                return .none

            case .startOverTapped:
                state.step = .pickPillar
                state.selectedPillar = nil
                state.photos = []
                state.selectedPhotoIDs = []
                state.caption = ""
                state.hashtags = []
                state.isGenerating = false
                return .none

            case .binding, .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    private func generateCaption(state: State) -> Effect<Action> {
        guard let pillar = state.selectedPillar else { return .none }
        let photoIDs = Array(state.selectedPhotoIDs)
        let platform = state.platform
        let fetchImage = photoLibrary.image
        let generateCaption = postGenerator.generateCaption
        let generateHashtags = postGenerator.generateHashtags
        return .run { send in
            let images = try await withThrowingTaskGroup(of: UIImage.self) { group in
                for id in photoIDs {
                    group.addTask {
                        try await fetchImage(id, Layout.ImageSize.caption)
                    }
                }
                var results: [UIImage] = []
                for try await img in group { results.append(img) }
                return results
            }
            let caption = try await generateCaption(images, pillar, platform)
            let hashtags = try await generateHashtags(caption, pillar, platform)
            await send(.captionGenerated(caption: caption, hashtags: hashtags))
        } catch: { _, send in
            await send(.captionGenerationFailed)
        }
    }
}
