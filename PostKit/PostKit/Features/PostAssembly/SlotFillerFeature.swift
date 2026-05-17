import ComposableArchitecture
import Foundation

@Reducer
struct SlotFillerFeature {
    @ObservableState
    struct State: Equatable {
        let slotID: UUID
        let slotName: String
        let constrainedPillarNames: [String]
        var photos: [ClassifiedPhotoSnapshot] = []
        var pillars: [PillarSnapshot] = []
        var selectedFilter: PillarFilter = .all
        var selectedPhotoIDs: Set<String> = []
        var isLoading: Bool = false

        var filteredPhotos: [ClassifiedPhotoSnapshot] {
            switch selectedFilter {
            case .all:
                return photos
            case .pillar(let id):
                return photos.filter { $0.pillarID == id }
            case .uncategorized:
                return photos.filter { $0.pillarID == nil }
            }
        }

        var displayPillars: [PillarSnapshot] {
            if constrainedPillarNames.isEmpty {
                return pillars
            }
            return pillars.filter { constrainedPillarNames.contains($0.name) }
        }

        init(
            slotID: UUID,
            slotName: String,
            constrainedPillarNames: [String] = [],
            preselectedPhotoIDs: Set<String> = []
        ) {
            self.slotID = slotID
            self.slotName = slotName
            self.constrainedPillarNames = constrainedPillarNames
            self.selectedPhotoIDs = preselectedPhotoIDs
        }
    }

    enum Action {
        case onAppear
        case dataLoaded(pillars: [PillarSnapshot], photos: [ClassifiedPhotoSnapshot])
        case filterSelected(PillarFilter)
        case photoToggled(String)
        case confirmTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case didConfirm(slotID: UUID, photoIDs: Set<String>)
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
                let constrainedNames = state.constrainedPillarNames
                return .run { send in
                    let pillars = try await persistence.fetchPillars()
                    let allPhotos = try await persistence.fetchPhotos(nil)
                    let photos: [ClassifiedPhotoSnapshot]
                    if constrainedNames.isEmpty {
                        photos = allPhotos
                    } else {
                        let allowedIDs = Set(
                            pillars
                                .filter { constrainedNames.contains($0.name) }
                                .map(\.id)
                        )
                        photos = allPhotos.filter { photo in
                            guard let pid = photo.pillarID else { return false }
                            return allowedIDs.contains(pid)
                        }
                    }
                    await send(.dataLoaded(pillars: pillars, photos: photos))
                }

            case let .dataLoaded(pillars, photos):
                state.pillars = pillars
                state.photos = photos
                state.isLoading = false
                if !state.constrainedPillarNames.isEmpty,
                   let firstPillar = state.displayPillars.first {
                    state.selectedFilter = .pillar(firstPillar.id)
                }
                return .none

            case let .filterSelected(filter):
                state.selectedFilter = filter
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
                return .run { send in
                    await send(.delegate(.didConfirm(slotID: slotID, photoIDs: photoIDs)))
                    await dismiss()
                }

            case .delegate:
                return .none
            }
        }
    }
}
