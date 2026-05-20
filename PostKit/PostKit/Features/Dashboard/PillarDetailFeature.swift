// MARK: - PostKit
// PillarDetailFeature.swift — Pillar detail reducer: loads and displays photos for a single pillar

import ComposableArchitecture

@Reducer
struct PillarDetailFeature {
    @ObservableState
    struct State: Equatable {
        let pillar: PillarSnapshot
        var photos: [ClassifiedPhotoSnapshot] = []
        var isLoading: Bool = false
    }

    enum Action {
        case onAppear
        case photosLoaded([ClassifiedPhotoSnapshot])
        case photoTapped(ClassifiedPhotoSnapshot)
    }

    @Dependency(\.persistence) var persistence

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.photos.isEmpty else { return .none }
                state.isLoading = true
                let pillarID = state.pillar.id
                return .run { send in
                    let photos = try await persistence.fetchPhotosForPillar(pillarID)
                    await send(.photosLoaded(photos))
                }

            case let .photosLoaded(photos):
                state.photos = photos
                state.isLoading = false
                return .none

            case .photoTapped:
                return .none
            }
        }
    }
}
