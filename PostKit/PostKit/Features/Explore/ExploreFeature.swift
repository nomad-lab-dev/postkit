// MARK: - PostKit
// ExploreFeature.swift — Explore reducer: paginated photo browsing with pillar and status filters

import ComposableArchitecture
import Foundation
import os
import UIKit

private let log = Logger(subsystem: "PostKit", category: "Explore")

enum PillarFilter: Equatable, Sendable {
    case all
    case pillar(UUID)
    case uncategorized
}

@Reducer
struct ExploreFeature {
    static let pageSize = 60

    @ObservableState
    struct State: Equatable {
        var photos: [ClassifiedPhotoSnapshot] = []
        var pillars: [PillarSnapshot] = []
        var selectedFilter: PillarFilter = .all
        var statusFilter: ClassifiedPhoto.PhotoStatus? = nil
        var isLoading: Bool = false
        var isLoadingMore: Bool = false
        var currentOffset: Int = 0
        var totalCount: Int = 0
        @Presents var card: ClassificationCardFeature.State?
        @Presents var photoDetail: PhotoDetailFeature.State?

        var hasMore: Bool { currentOffset < totalCount }

        var filteredPhotos: [ClassifiedPhotoSnapshot] {
            var result = photos
            switch selectedFilter {
            case .all: break
            case let .pillar(id):
                result = result.filter { $0.pillarID == id || $0.pillarIDs.contains(id) }
            case .uncategorized:
                result = result.filter { $0.pillarID == nil && $0.pillarIDs.isEmpty }
            }
            if let statusFilter {
                result = result.filter { $0.status == statusFilter }
            }
            return result.sorted { ($0.capturedAt ?? .distantPast) > ($1.capturedAt ?? .distantPast) }
        }

        var filteredCount: Int { filteredPhotos.count }

    }

    enum Action {
        case onAppear
        case initialLoaded(pillars: [PillarSnapshot], photos: [ClassifiedPhotoSnapshot], totalCount: Int)
        case loadMore
        case pageLoaded([ClassifiedPhotoSnapshot])
        case cadrageBackfilled(assetID: String, cadrage: Cadrage)
        case filterSelected(PillarFilter)
        case statusFilterSelected(ClassifiedPhoto.PhotoStatus?)
        case photoTapped(ClassifiedPhotoSnapshot)
        case copyPhotoTapped(String)
        case removePillarFromPhoto(ClassifiedPhotoSnapshot)
        case addPhotoToPillar(ClassifiedPhotoSnapshot, UUID)
        case declassifyPhoto(ClassifiedPhotoSnapshot)
        case photoUpdateSaved(ClassifiedPhotoSnapshot)
        case card(PresentationAction<ClassificationCardFeature.Action>)
        case photoDetail(PresentationAction<PhotoDetailFeature.Action>)
    }

    @Dependency(\.gallery) var gallery
    @Dependency(\.persistence) var persistence
    @Dependency(\.photoLibrary) var photoLibrary
    @Dependency(\.imageClassifier) var imageClassifier

    private enum CancelID: Hashable { case cadrageBackfill }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.photos.isEmpty else {
                    let count = state.photos.count
                    log.info("⏭️ onAppear skipped — already have \(count) photos")
                    return .none
                }
                state.isLoading = true
                log.info("⏳ onAppear — starting initial load")
                return .run(priority: .userInitiated) { [gallery] send in
                    log.info("⏳ gallery.pillars + gallery.photos start")
                    async let pillarsTask = gallery.pillars()
                    async let photosTask = gallery.photos(nil)
                    let pillars = try await pillarsTask
                    log.info("✅ gallery.pillars done — \(pillars.count) pillars")
                    let allPhotos = (try? await photosTask) ?? []
                    log.info("✅ gallery.photos done — \(allPhotos.count) total photos")
                    await send(.initialLoaded(pillars: pillars, photos: allPhotos, totalCount: allPhotos.count))
                } catch: { error, send in
                    log.error("❌ Explore initial load FAILED: \(error)")
                    await send(.initialLoaded(pillars: [], photos: [], totalCount: 0))
                }

            case let .initialLoaded(pillars, photos, totalCount):
                log.info("✅ initialLoaded — \(pillars.count) pillars, \(photos.count) photos, total=\(totalCount)")
                state.pillars = pillars
                state.photos = photos
                state.totalCount = totalCount
                state.currentOffset = photos.count
                state.isLoading = false
                let missing = photos.filter { $0.cadrage == nil }.map(\.assetLocalIdentifier)
                guard !missing.isEmpty else { return .none }
                return backfillCadrages(for: missing)

            case .loadMore:
                guard state.hasMore, !state.isLoadingMore, !state.isLoading else {
                    let hasMore = state.hasMore
                    let isLoadingMore = state.isLoadingMore
                    log.info("⏭️ loadMore skipped — hasMore=\(hasMore), isLoadingMore=\(isLoadingMore)")
                    return .none
                }
                state.isLoadingMore = true
                let offset = state.currentOffset
                log.info("⏳ loadMore — offset=\(offset)")
                return .run { send in
                    let photos = try await persistence.fetchPhotosPaginated(nil, ExploreFeature.pageSize, offset)
                    log.info("✅ loadMore done — \(photos.count) photos fetched")
                    await send(.pageLoaded(photos))
                }

            case let .pageLoaded(newPhotos):
                state.isLoadingMore = false
                guard !newPhotos.isEmpty else {
                    state.totalCount = state.photos.count
                    return .none
                }
                let existingIDs = Set(state.photos.map(\.assetLocalIdentifier))
                let deduplicated = newPhotos.filter { !existingIDs.contains($0.assetLocalIdentifier) }
                state.photos.append(contentsOf: deduplicated)
                state.currentOffset += newPhotos.count
                let missing = deduplicated.filter { $0.cadrage == nil }.map(\.assetLocalIdentifier)
                guard !missing.isEmpty else { return .none }
                return backfillCadrages(for: missing)

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
                if photo.status == .pending {
                    let pendingPhotos = state.photos.filter { $0.status == .pending }
                    let index = pendingPhotos.firstIndex(where: { $0.id == photo.id }) ?? 0
                    state.card = ClassificationCardFeature.State(
                        photos: pendingPhotos,
                        currentIndex: index,
                        pillars: state.pillars
                    )
                } else {
                    state.photoDetail = PhotoDetailFeature.State(
                        photo: photo,
                        pillars: state.pillars
                    )
                }
                return .none

            case var .removePillarFromPhoto(photo):
                guard let pillarID = photo.pillarID else { return .none }
                photo.pillarIDs.removeAll { $0 == pillarID }
                photo.pillarID = photo.pillarIDs.first
                if photo.pillarIDs.isEmpty { photo.status = .pending }
                return savePhotoUpdate(photo)

            case var .addPhotoToPillar(photo, pillarID):
                if !photo.pillarIDs.contains(pillarID) {
                    photo.pillarIDs.append(pillarID)
                }
                if photo.pillarID == nil { photo.pillarID = pillarID }
                photo.status = .classified
                return savePhotoUpdate(photo)

            case var .declassifyPhoto(photo):
                photo.pillarIDs = []
                photo.pillarID = nil
                photo.status = .pending
                return savePhotoUpdate(photo)

            case let .photoUpdateSaved(photo):
                if let idx = state.photos.firstIndex(where: { $0.id == photo.id }) {
                    state.photos[idx] = photo
                }
                return .none

            case let .photoDetail(.presented(.delegate(.didUpdatePhoto(photo)))):
                if let idx = state.photos.firstIndex(where: { $0.id == photo.id }) {
                    state.photos[idx] = photo
                }
                return .none

            case .card(.presented(.delegate(.didComplete))),
                 .card(.dismiss):
                state.card = nil
                state.photos = []
                state.currentOffset = 0
                return .run { [gallery] send in
                    await gallery.invalidatePhotos()
                    await send(.onAppear)
                }

            case .card, .photoDetail:
                return .none
            }
        }
        .ifLet(\.$card, action: \.card) {
            ClassificationCardFeature()
        }
        .ifLet(\.$photoDetail, action: \.photoDetail) {
            PhotoDetailFeature()
        }
    }

    private func savePhotoUpdate(_ photo: ClassifiedPhotoSnapshot) -> Effect<Action> {
        .run { [persistence, gallery] send in
            try? await persistence.savePhoto(photo)
            await gallery.invalidatePhotos()
            await send(.photoUpdateSaved(photo))
        }
    }

    private func backfillCadrages(for assetIDs: [String]) -> Effect<Action> {
        let fetchImage = photoLibrary.image
        let detectCadrage = imageClassifier.detectCadrage
        return .run { send in
            for assetID in assetIDs {
                try Task.checkCancellation()
                guard let img = try? await fetchImage(assetID, Layout.ImageSize.classification) else { continue }
                let cadrage = (try? await detectCadrage(img)) ?? .wide
                await send(.cadrageBackfilled(assetID: assetID, cadrage: cadrage))
            }
        }
        .cancellable(id: CancelID.cadrageBackfill)
    }
}
