// MARK: - PostKit
// PhotoDetailFeature.swift — Full-screen photo viewer with pillar editing and copy action

import ComposableArchitecture
import UIKit

@Reducer
struct PhotoDetailFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        var id: UUID { photo.id }
        var photo: ClassifiedPhotoSnapshot
        var pillars: [PillarSnapshot]
        var showPillarPicker: Bool = false

        var assignedPillars: [PillarSnapshot] {
            pillars.filter { photo.pillarIDs.contains($0.id) }
        }

        var availablePillars: [PillarSnapshot] {
            pillars.filter { !photo.pillarIDs.contains($0.id) }
        }
    }

    enum Action {
        case copyTapped
        case copied
        case removePillarTapped(UUID)
        case addPillarTapped(UUID)
        case declassifyTapped
        case pillarPickerToggled
        case photoSaved
        case delegate(Delegate)

        enum Delegate: Equatable {
            case didUpdatePhoto(ClassifiedPhotoSnapshot)
        }
    }

    @Dependency(\.photoLibrary) var photoLibrary
    @Dependency(\.persistence) var persistence
    @Dependency(\.gallery) var gallery

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .copyTapped:
                let assetID = state.photo.assetLocalIdentifier
                let fetchImage = photoLibrary.image
                return .run { send in
                    if let image = try? await fetchImage(assetID, Layout.ImageSize.export) {
                        await MainActor.run {
                            UIPasteboard.general.image = image
                        }
                    }
                    await send(.copied)
                }

            case .copied:
                return .none

            case let .removePillarTapped(pillarID):
                state.photo.pillarIDs.removeAll { $0 == pillarID }
                if state.photo.pillarID == pillarID {
                    state.photo.pillarID = state.photo.pillarIDs.first
                }
                if state.photo.pillarIDs.isEmpty {
                    state.photo.status = .pending
                }
                return saveAndNotify(state.photo)

            case let .addPillarTapped(pillarID):
                if !state.photo.pillarIDs.contains(pillarID) {
                    state.photo.pillarIDs.append(pillarID)
                }
                if state.photo.pillarID == nil {
                    state.photo.pillarID = pillarID
                }
                state.photo.status = .classified
                state.showPillarPicker = false
                return saveAndNotify(state.photo)

            case .declassifyTapped:
                state.photo.pillarIDs = []
                state.photo.pillarID = nil
                state.photo.status = .pending
                return saveAndNotify(state.photo)

            case .pillarPickerToggled:
                state.showPillarPicker.toggle()
                return .none

            case .photoSaved:
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private func saveAndNotify(_ photo: ClassifiedPhotoSnapshot) -> Effect<Action> {
        .run { [persistence, gallery] send in
            try? await persistence.savePhoto(photo)
            await gallery.invalidatePhotos()
            await send(.delegate(.didUpdatePhoto(photo)))
            await send(.photoSaved)
        }
    }
}
