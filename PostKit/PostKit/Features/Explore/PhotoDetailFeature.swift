// MARK: - PostKit
// PhotoDetailFeature.swift — Full-screen photo viewer: metadata display and copy action

import ComposableArchitecture
import UIKit

@Reducer
struct PhotoDetailFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        var id: UUID { photo.id }
        var photo: ClassifiedPhotoSnapshot
        var pillar: PillarSnapshot?
    }

    enum Action {
        case copyTapped
        case copied
    }

    @Dependency(\.photoLibrary) var photoLibrary

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
            }
        }
    }
}
