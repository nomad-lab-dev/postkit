// MARK: - PostKit
// ClassificationQueueFeature.swift — Classification queue reducer: pending photos, accept-all, cadrage backfill

import ComposableArchitecture
import Foundation

@Reducer
struct ClassificationQueueFeature {
    @ObservableState
    struct State: Equatable {
        var pendingPhotos: [ClassifiedPhotoSnapshot] = []
        var pillars: [PillarSnapshot] = []
        var isLoading: Bool = false
        @Presents var card: ClassificationCardFeature.State?
    }

    enum Action {
        case onAppear
        case dataLoaded(photos: [ClassifiedPhotoSnapshot], pillars: [PillarSnapshot])
        case cadrageBackfilled(assetID: String, cadrage: Cadrage)
        case photoTapped(Int)
        case acceptAllTapped
        case acceptAllCompleted
        case card(PresentationAction<ClassificationCardFeature.Action>)
    }

    @Dependency(\.persistence) var persistence
    @Dependency(\.photoLibrary) var photoLibrary
    @Dependency(\.imageClassifier) var imageClassifier

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    let photos = try await persistence.fetchPhotos(.pending)
                    let pillars = try await persistence.fetchPillars()
                    await send(.dataLoaded(photos: photos, pillars: pillars))
                }

            case let .dataLoaded(photos, pillars):
                state.pendingPhotos = photos
                state.pillars = pillars
                state.isLoading = false
                let missing = photos.filter { $0.cadrage == nil }.map(\.assetLocalIdentifier)
                guard !missing.isEmpty else { return .none }
                let fetchImage = photoLibrary.image
                let detectCadrage = imageClassifier.detectCadrage
                return .run { send in
                    for assetID in missing {
                        guard let img = try? await fetchImage(assetID, Layout.ImageSize.classification) else { continue }
                        let cadrage = (try? await detectCadrage(img)) ?? .wide
                        await send(.cadrageBackfilled(assetID: assetID, cadrage: cadrage))
                        await Task.yield()
                    }
                }

            case let .cadrageBackfilled(assetID, cadrage):
                if let idx = state.pendingPhotos.firstIndex(where: { $0.assetLocalIdentifier == assetID }) {
                    state.pendingPhotos[idx].cadrage = cadrage
                    let photo = state.pendingPhotos[idx]
                    return .run { _ in
                        try? await persistence.savePhoto(photo)
                    }
                }
                return .none

            case let .photoTapped(index):
                guard index < state.pendingPhotos.count else { return .none }
                state.card = ClassificationCardFeature.State(
                    photos: state.pendingPhotos,
                    currentIndex: index,
                    pillars: state.pillars
                )
                return .none

            case .acceptAllTapped:
                let photos = state.pendingPhotos
                state.pendingPhotos = []
                return .run { send in
                    for var photo in photos {
                        photo.status = .classified
                        try await persistence.savePhoto(photo)
                    }
                    await send(.acceptAllCompleted)
                }

            case .acceptAllCompleted:
                return .none

            case .card(.presented(.delegate(.didComplete))),
                 .card(.dismiss):
                state.card = nil
                return .run { send in
                    let photos = try await persistence.fetchPhotos(.pending)
                    let pillars = try await persistence.fetchPillars()
                    await send(.dataLoaded(photos: photos, pillars: pillars))
                }

            case .card:
                return .none
            }
        }
        .ifLet(\.$card, action: \.card) {
            ClassificationCardFeature()
        }
    }
}
