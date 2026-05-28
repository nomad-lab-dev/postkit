// MARK: - PostKit
// SlotFillerFeature.swift — Slot filler reducer: photo filtering by pillar, cadrage, location, and date

import ComposableArchitecture
import Foundation

@Reducer
struct SlotFillerFeature {
    @ObservableState
    struct State: Equatable {
        let slotID: UUID
        let slotName: String
        let slotAbout: String
        let constrainedPillarIDs: [UUID]
        let constrainedCadrages: [Cadrage]
        let constrainedLocations: [String]
        let constrainedStartDate: Date?
        let constrainedEndDate: Date?
        var photos: [ClassifiedPhotoSnapshot] = []
        var pillars: [PillarSnapshot] = []
        var activePillarIDs: Set<UUID> = []
        var activeCadrages: Set<Cadrage> = []
        var activeLocations: Set<String> = []
        var activeStartDate: Date?
        var activeEndDate: Date?
        var selectedPhotoIDs: Set<String> = []
        var isLoading: Bool = false

        var filteredPhotos: [ClassifiedPhotoSnapshot] {
            photos.filter { photo in
                let matchesPillar: Bool
                if activePillarIDs.isEmpty {
                    matchesPillar = true
                } else {
                    var photoAllPillarIDs = Set(photo.pillarIDs)
                    if let pid = photo.pillarID { photoAllPillarIDs.insert(pid) }
                    matchesPillar = !activePillarIDs.isDisjoint(with: photoAllPillarIDs)
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

                let matchesDate: Bool
                if activeStartDate == nil && activeEndDate == nil {
                    matchesDate = true
                } else if let captured = photo.capturedAt {
                    let afterStart = activeStartDate.map { captured >= $0 } ?? true
                    let beforeEnd = activeEndDate.map { captured <= $0 } ?? true
                    matchesDate = afterStart && beforeEnd
                } else {
                    // Photos without EXIF date are always included — don't penalise missing metadata
                    matchesDate = true
                }

                return matchesPillar && matchesCadrage && matchesLocation && matchesDate
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

        var hasActiveConstraints: Bool {
            !constrainedPillarIDs.isEmpty || !constrainedCadrages.isEmpty
                || !constrainedLocations.isEmpty || constrainedStartDate != nil
                || constrainedEndDate != nil || !slotAbout.isEmpty
        }

        init(
            slotID: UUID,
            slotName: String,
            slotAbout: String = "",
            constrainedPillarIDs: [UUID] = [],
            constrainedCadrages: [Cadrage] = [],
            constrainedLocations: [String] = [],
            constrainedStartDate: Date? = nil,
            constrainedEndDate: Date? = nil,
            preselectedPhotoIDs: Set<String> = []
        ) {
            self.slotID = slotID
            self.slotName = slotName
            self.slotAbout = slotAbout
            self.constrainedPillarIDs = constrainedPillarIDs
            self.constrainedCadrages = constrainedCadrages
            self.constrainedLocations = constrainedLocations
            self.constrainedStartDate = constrainedStartDate
            self.constrainedEndDate = constrainedEndDate
            self.selectedPhotoIDs = preselectedPhotoIDs
            self.activePillarIDs = Set(constrainedPillarIDs)
            self.activeCadrages = Set(constrainedCadrages)
            self.activeLocations = Set(constrainedLocations)
            self.activeStartDate = constrainedStartDate
            self.activeEndDate = constrainedEndDate
        }
    }

    enum Action {
        case onAppear
        case dataLoaded(pillars: [PillarSnapshot], photos: [ClassifiedPhotoSnapshot])
        case pillarFilterToggled(UUID)
        case cadrageFilterToggled(Cadrage)
        case locationFilterToggled(String)
        case startDateChanged(Date?)
        case endDateChanged(Date?)
        case clearDatesTapped
        case photoToggled(String)
        case confirmTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case didConfirm(slotID: UUID, photoIDs: Set<String>, locationLabel: String?, updatedSlotData: TemplateSlotData)
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
                return .run { [gallery] send in
                    async let pillarsTask = gallery.pillars()
                    async let photosTask = gallery.photos(nil)
                    let pillars = try await pillarsTask
                    let photos = (try? await photosTask) ?? []
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

            case let .startDateChanged(date):
                state.activeStartDate = date
                return .none

            case let .endDateChanged(date):
                state.activeEndDate = date
                return .none

            case .clearDatesTapped:
                state.activeStartDate = nil
                state.activeEndDate = nil
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

                let updatedSlot = TemplateSlotData(
                    id: state.slotID,
                    name: state.slotName,
                    cadrages: Array(state.activeCadrages),
                    pillarIDs: Array(state.activePillarIDs),
                    locations: Array(state.activeLocations),
                    about: state.slotAbout,
                    startDate: state.activeStartDate,
                    endDate: state.activeEndDate
                )

                return .run { send in
                    await send(.delegate(.didConfirm(
                        slotID: slotID,
                        photoIDs: photoIDs,
                        locationLabel: locationLabel,
                        updatedSlotData: updatedSlot
                    )))
                    await dismiss()
                }

            case .delegate:
                return .none
            }
        }
    }
}
