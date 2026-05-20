// MARK: - PostKit
// SlotFillerFeature.swift — Slot filler reducer: photo filtering by pillar, cadrage, and location

import ComposableArchitecture
import Foundation

@Reducer
struct SlotFillerFeature {
    @ObservableState
    struct State: Equatable {
        let slotID: UUID
        let slotName: String
        let constrainedPillarIDs: [UUID]
        let constrainedCadrages: [Cadrage]
        let constrainedLocations: [String]
        var photos: [ClassifiedPhotoSnapshot] = []
        var pillars: [PillarSnapshot] = []
        var activePillarIDs: Set<UUID> = []
        var activeCadrages: Set<Cadrage> = []
        var activeLocations: Set<String> = []
        var selectedPhotoIDs: Set<String> = []
        var isLoading: Bool = false

        var filteredPhotos: [ClassifiedPhotoSnapshot] {
            photos.filter { photo in
                let matchesPillar: Bool
                if activePillarIDs.isEmpty {
                    matchesPillar = true
                } else if let pid = photo.pillarID {
                    matchesPillar = activePillarIDs.contains(pid)
                } else {
                    matchesPillar = false
                }

                let matchesCadrage: Bool
                if activeCadrages.isEmpty {
                    matchesCadrage = true
                } else if let cadrage = photo.cadrage {
                    matchesCadrage = activeCadrages.contains(cadrage)
                } else {
                    matchesCadrage = false
                }

                let matchesLocation: Bool
                if activeLocations.isEmpty {
                    matchesLocation = true
                } else if let location = photo.location {
                    matchesLocation = activeLocations.contains(location)
                } else {
                    matchesLocation = false
                }

                return matchesPillar && matchesCadrage && matchesLocation
            }
        }

        var displayPillars: [PillarSnapshot] {
            guard !constrainedPillarIDs.isEmpty else { return pillars }
            let ids = Set(constrainedPillarIDs)
            let constrained = pillars.filter { ids.contains($0.id) }
            let others = pillars.filter { !ids.contains($0.id) }
            return constrained + others
        }

        var uniqueLocations: [String] {
            let all = Set(photos.compactMap(\.location))
            let constrainedSet = Set(constrainedLocations)
            let constrained = all.filter { constrainedSet.contains($0) }.sorted()
            let others = all.subtracting(constrainedSet).sorted()
            return constrained + others
        }

        init(
            slotID: UUID,
            slotName: String,
            constrainedPillarIDs: [UUID] = [],
            constrainedCadrages: [Cadrage] = [],
            constrainedLocations: [String] = [],
            preselectedPhotoIDs: Set<String> = []
        ) {
            self.slotID = slotID
            self.slotName = slotName
            self.constrainedPillarIDs = constrainedPillarIDs
            self.constrainedCadrages = constrainedCadrages
            self.constrainedLocations = constrainedLocations
            self.selectedPhotoIDs = preselectedPhotoIDs
            self.activePillarIDs = Set(constrainedPillarIDs)
            self.activeCadrages = Set(constrainedCadrages)
            self.activeLocations = Set(constrainedLocations)
        }
    }

    enum Action {
        case onAppear
        case dataLoaded(pillars: [PillarSnapshot], photos: [ClassifiedPhotoSnapshot])
        case pillarFilterToggled(UUID)
        case cadrageFilterToggled(Cadrage)
        case locationFilterToggled(String)
        case photoToggled(String)
        case confirmTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case didConfirm(slotID: UUID, photoIDs: Set<String>, locationLabel: String?)
        }
    }

    @Dependency(\.persistence) var persistence
    @Dependency(\.dismiss) var dismiss

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
                return .none

            case let .pillarFilterToggled(id):
                if state.activePillarIDs.contains(id) {
                    state.activePillarIDs.remove(id)
                } else {
                    state.activePillarIDs.insert(id)
                }
                return .none

            case let .cadrageFilterToggled(cadrage):
                if state.activeCadrages.contains(cadrage) {
                    state.activeCadrages.remove(cadrage)
                } else {
                    state.activeCadrages.insert(cadrage)
                }
                return .none

            case let .locationFilterToggled(location):
                if state.activeLocations.contains(location) {
                    state.activeLocations.remove(location)
                } else {
                    state.activeLocations.insert(location)
                }
                return .none

            case let .photoToggled(assetID):
                if state.selectedPhotoIDs.contains(assetID) {
                    state.selectedPhotoIDs.remove(assetID)
                } else {
                    state.selectedPhotoIDs.insert(assetID)
                }
                return .none

            case .confirmTapped:
                let slotID = state.slotID
                let photoIDs = state.selectedPhotoIDs
                let locationLabel = state.photos
                    .first { state.selectedPhotoIDs.contains($0.assetLocalIdentifier) }?.location
                return .run { send in
                    await send(.delegate(.didConfirm(slotID: slotID, photoIDs: photoIDs, locationLabel: locationLabel)))
                    await dismiss()
                }

            case .delegate:
                return .none
            }
        }
    }
}
