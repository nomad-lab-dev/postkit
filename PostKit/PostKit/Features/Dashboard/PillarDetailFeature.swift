// MARK: - PostKit
// PillarDetailFeature.swift — Pillar detail reducer: loads and displays photos for a single pillar

import ComposableArchitecture
import Foundation

@Reducer
struct PillarDetailFeature {
    @ObservableState
    struct State: Equatable {
        var pillar: PillarSnapshot
        var photos: [ClassifiedPhotoSnapshot] = []
        var isLoading: Bool = false
        @Presents var topicEditor: TopicEditorFeature.State?
        @Presents var photoDetail: PhotoDetailFeature.State?
    }

    enum Action {
        case onAppear
        case photosLoaded([ClassifiedPhotoSnapshot])
        case photoTapped(ClassifiedPhotoSnapshot)
        case editTapped
        case topicEditor(PresentationAction<TopicEditorFeature.Action>)
        case photoDetail(PresentationAction<PhotoDetailFeature.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case pillarUpdated
            case pillarDeleted(UUID)
        }
    }

    @Dependency(\.gallery) var gallery
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.photos.isEmpty else { return .none }
                state.isLoading = true
                let pillarID = state.pillar.id
                return .run { [gallery] send in
                    let allPhotos = (try? await gallery.photos(.classified)) ?? []
                    let photos = allPhotos.filter { $0.pillarIDs.contains(pillarID) }
                    await send(.photosLoaded(photos))
                }

            case let .photosLoaded(photos):
                state.photos = photos
                state.isLoading = false
                return .none

            case let .photoTapped(photo):
                state.photoDetail = PhotoDetailFeature.State(
                    photo: photo,
                    pillar: state.pillar
                )
                return .none

            case .editTapped:
                state.topicEditor = TopicEditorFeature.State(pillar: state.pillar)
                return .none

            case .topicEditor(.presented(.delegate(.didSave))):
                return .merge(
                    .send(.delegate(.pillarUpdated)),
                    .run { send in
                        await send(.onAppear)
                    }
                )

            case let .topicEditor(.presented(.delegate(.didDelete(id)))):
                return .merge(
                    .send(.delegate(.pillarDeleted(id))),
                    .run { _ in await dismiss() }
                )

            case .topicEditor, .photoDetail, .delegate:
                return .none
            }
        }
        .ifLet(\.$topicEditor, action: \.topicEditor) {
            TopicEditorFeature()
        }
        .ifLet(\.$photoDetail, action: \.photoDetail) {
            PhotoDetailFeature()
        }
    }
}
