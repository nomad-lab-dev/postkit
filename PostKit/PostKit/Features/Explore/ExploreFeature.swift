import ComposableArchitecture

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

        var filteredCount: Int { filteredPhotos.count }
    }

    enum Action {
        case onAppear
        case dataLoaded(pillars: [PillarSnapshot], photos: [ClassifiedPhotoSnapshot])
        case filterSelected(PillarFilter)
        case photoTapped(ClassifiedPhotoSnapshot)
    }

    @Dependency(\.persistence) var persistence

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

            case let .filterSelected(filter):
                state.selectedFilter = filter
                return .none

            case .photoTapped:
                return .none
            }
        }
    }
}
