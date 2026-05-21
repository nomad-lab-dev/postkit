// MARK: - PostKit
// ExploreFeature.swift — Explore reducer: photo browsing with pillar and status filters

import ComposableArchitecture
import Foundation
import UIKit

enum PillarFilter: Equatable, Sendable {
    case all
    case pillar(UUID)
    case uncategorized
}

@Reducer
struct ExploreFeature {
    @ObservableState
    struct State: Equatable {
        var photos: [ClassifiedPhotoSnapshot] = []
        var pillars: [PillarSnapshot] = []
        var selectedFilter: PillarFilter = .all
        var statusFilter: ClassifiedPhoto.PhotoStatus? = nil
        var isLoading: Bool = false
        @Presents var card: ClassificationCardFeature.State?

        var filteredPhotos: [ClassifiedPhotoSnapshot] {
            var result = photos
            switch selectedFilter {
            case .all: break
            case let .pillar(id): result = result.filter { $0.pillarID == id }
            case .uncategorized: result = result.filter { $0.pillarID == nil }
            }
            if let statusFilter {
                result = result.filter { $0.status == statusFilter }
            }
            return result
        }

        var filteredCount: Int { filteredPhotos.count }

        func pillar(for photo: ClassifiedPhotoSnapshot) -> PillarSnapshot? {
            guard let pillarID = photo.pillarID else { return nil }
            return pillars.first { $0.id == pillarID }
        }
    }

    enum Action {
        case onAppear
        case dataLoaded(pillars: [PillarSnapshot], photos: [ClassifiedPhotoSnapshot])
        case cadrageBackfilled(assetID: String, cadrage: Cadrage)
        case filterSelected(PillarFilter)
        case statusFilterSelected(ClassifiedPhoto.PhotoStatus?)
        case photoTapped(ClassifiedPhotoSnapshot)
        case copyPhotoTapped(String)
        case card(PresentationAction<ClassificationCardFeature.Action>)
    }

    @Dependency(\.persistence) var persistence
    @Dependency(\.photoLibrary) var photoLibrary
    @Dependency(\.imageClassifier) var imageClassifier

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.photos.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    let pillars = try await persistence.fetchPillars()
                    let photos = try await persistence.fetchPhotos(nil)
                    await send(.dataLoaded(pillars: pillars, photos: photos))
                }

            case let .dataLoaded(pillars, photos):
                state.pillars = pillars
                state.photos = photos
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
                if let idx = state.photos.firstIndex(where: { $0.assetLocalIdentifier == assetID }) {
                    state.photos[idx].cadrage = cadrage
                    let photo = state.photos[idx]
                    return .run { _ in
                        try? await persistence.savePhoto(photo)
                    }
                }
                return .none

            case let .filterSelected(filter):
                state.selectedFilter = filter
                return .none

            case let .statusFilterSelected(status):
                state.statusFilter = status
                return .none

            case let .copyPhotoTapped(assetID):
                let fetchImage = photoLibrary.image
                return .run { _ in
                    if let image = try? await fetchImage(assetID, Layout.ImageSize.export) {
                        await MainActor.run {
                            UIPasteboard.general.image = image
                        }
                    }
                }

            case let .photoTapped(photo):
                guard photo.status == .pending else { return .none }
                let pendingPhotos = state.photos.filter { $0.status == .pending }
                let index = pendingPhotos.firstIndex(where: { $0.id == photo.id }) ?? 0
                state.card = ClassificationCardFeature.State(
                    photos: pendingPhotos,
                    currentIndex: index,
                    pillars: state.pillars
                )
                return .none

            case .card(.presented(.delegate(.didComplete))),
                 .card(.dismiss):
                state.card = nil
                return .run { send in
                    let pillars = try await persistence.fetchPillars()
                    let photos = try await persistence.fetchPhotos(nil)
                    await send(.dataLoaded(pillars: pillars, photos: photos))
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
