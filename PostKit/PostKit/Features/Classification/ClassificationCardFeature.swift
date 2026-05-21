// MARK: - PostKit
// ClassificationCardFeature.swift — Classification card reducer: swipe-to-classify with undo stack

import ComposableArchitecture
import UIKit

@Reducer
struct ClassificationCardFeature {
    @ObservableState
    struct State: Equatable {
        var photos: [ClassifiedPhotoSnapshot]
        var currentIndex: Int
        var currentImage: UIImage?
        var pillars: [PillarSnapshot]
        var undoStack: [UndoEntry] = []
        var isLoadingImage: Bool = false
        var selectedPillarIDs: Set<UUID> = []

        var currentPhoto: ClassifiedPhotoSnapshot? {
            guard currentIndex < photos.count else { return nil }
            return photos[currentIndex]
        }

        var suggestedPillar: PillarSnapshot? {
            guard let photo = currentPhoto,
                  let pillarID = photo.pillarID else { return nil }
            return pillars.first { $0.id == pillarID }
        }

        var selectedPillars: [PillarSnapshot] {
            pillars.filter { selectedPillarIDs.contains($0.id) }
        }

        var canConfirm: Bool { !selectedPillarIDs.isEmpty }

        var remainingCount: Int {
            max(photos.count - currentIndex, 0)
        }

        var canUndo: Bool { !undoStack.isEmpty }
        var isComplete: Bool { currentIndex >= photos.count }
    }

    struct UndoEntry: Equatable {
        let photo: ClassifiedPhotoSnapshot
        let restoredIndex: Int
    }

    enum Action {
        case onAppear
        case imageLoaded(UIImage)
        case cadrageDetected(Cadrage)
        case pillarSelected(UUID)
        case confirmTapped
        case rejectTapped
        case undoTapped
        case photoSaved
        case delegate(Delegate)

        enum Delegate: Equatable {
            case didComplete
        }
    }

    @Dependency(\.photoLibrary) var photoLibrary
    @Dependency(\.imageClassifier) var imageClassifier
    @Dependency(\.persistence) var persistence

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoadingImage = true
                if let pillarID = state.currentPhoto?.pillarID {
                    state.selectedPillarIDs = [pillarID]
                } else {
                    state.selectedPillarIDs = []
                }
                return loadCurrentImage(state: state)

            case let .imageLoaded(image):
                state.currentImage = image
                state.isLoadingImage = false
                let needsCadrage = state.currentPhoto?.cadrage == nil
                let detectCadrage = imageClassifier.detectCadrage
                guard needsCadrage else { return .none }
                return .run { send in
                    let cadrage = (try? await detectCadrage(image)) ?? .wide
                    await send(.cadrageDetected(cadrage))
                }

            case let .cadrageDetected(cadrage):
                guard state.currentIndex < state.photos.count else { return .none }
                state.photos[state.currentIndex].cadrage = cadrage
                let photo = state.photos[state.currentIndex]
                return .run { _ in
                    try? await persistence.savePhoto(photo)
                }


            case let .pillarSelected(id):
                if state.selectedPillarIDs.contains(id) {
                    state.selectedPillarIDs.remove(id)
                } else {
                    state.selectedPillarIDs.insert(id)
                }
                return .none

            case .confirmTapped:
                guard var photo = state.currentPhoto,
                      let pillarID = state.selectedPillarIDs.first else { return .none }
                state.undoStack.append(UndoEntry(photo: photo, restoredIndex: state.currentIndex))
                photo.pillarID = pillarID
                photo.pillarIDs = Array(state.selectedPillarIDs)
                photo.status = .classified
                state.photos[state.currentIndex] = photo
                return saveAndAdvance(photo: photo, state: &state)

            case .rejectTapped:
                guard var photo = state.currentPhoto else { return .none }
                state.undoStack.append(UndoEntry(photo: photo, restoredIndex: state.currentIndex))
                photo.status = .rejected
                state.photos[state.currentIndex] = photo
                return saveAndAdvance(photo: photo, state: &state)

            case .undoTapped:
                guard let entry = state.undoStack.popLast() else { return .none }
                state.currentIndex = entry.restoredIndex
                state.photos[entry.restoredIndex] = entry.photo
                state.currentImage = nil
                state.isLoadingImage = true
                return .merge(
                    .run { [photo = entry.photo] _ in
                        try await persistence.savePhoto(photo)
                    },
                    loadCurrentImage(state: state)
                )

            case .photoSaved:
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private func saveAndAdvance(photo: ClassifiedPhotoSnapshot, state: inout State) -> Effect<Action> {
        state.currentIndex += 1
        state.currentImage = nil
        if let pillarID = state.currentPhoto?.pillarID {
            state.selectedPillarIDs = [pillarID]
        } else {
            state.selectedPillarIDs = []
        }

        if state.isComplete {
            return .merge(
                .run { _ in try await persistence.savePhoto(photo) },
                .send(.delegate(.didComplete))
            )
        }

        state.isLoadingImage = true
        return .merge(
            .run { send in
                try await persistence.savePhoto(photo)
                await send(.photoSaved)
            },
            loadCurrentImage(state: state)
        )
    }

    private func loadCurrentImage(state: State) -> Effect<Action> {
        guard let photo = state.currentPhoto else { return .none }
        let id = photo.assetLocalIdentifier
        let fetchImage = photoLibrary.image
        return .run { send in
            let scale = await UIScreen.main.scale
            let screenWidth = await UIScreen.main.bounds.width
            let size = screenWidth * scale
            let image = try await fetchImage(id, CGSize(width: size, height: size))
            await send(.imageLoaded(image))
        }
    }
}
