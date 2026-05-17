import ComposableArchitecture
import Foundation
import XCTest
@testable import PostKit

@MainActor
final class ExploreFeatureTests: XCTestCase {

    func test_onAppear_loadsPhotosAndPillars() async {
        let pillars = [
            PillarSnapshot(id: UUID(0), name: "Travel", emoji: "✈️"),
            PillarSnapshot(id: UUID(1), name: "Food", emoji: "🍽️"),
        ]
        let photos = [
            ClassifiedPhotoSnapshot(
                assetLocalIdentifier: "a1", pillarID: UUID(0),
                pillarName: "Travel", confidence: 0.9, status: .classified
            ),
            ClassifiedPhotoSnapshot(
                assetLocalIdentifier: "a2", pillarID: UUID(1),
                pillarName: "Food", confidence: 0.85, status: .classified
            ),
            ClassifiedPhotoSnapshot(
                assetLocalIdentifier: "a3",
                pillarName: "Uncategorized", confidence: 0.3, status: .classified
            ),
        ]

        let store = TestStore(initialState: ExploreFeature.State()) {
            ExploreFeature()
        } withDependencies: {
            $0.persistence.fetchPillars = { pillars }
            $0.persistence.fetchPhotos = { _ in photos }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.dataLoaded) {
            $0.pillars = pillars
            $0.photos = photos
            $0.isLoading = false
        }
    }

    func test_filterByPillar_filtersCorrectly() async {
        var state = ExploreFeature.State()
        state.pillars = [
            PillarSnapshot(id: UUID(0), name: "Travel", emoji: "✈️"),
        ]
        state.photos = [
            ClassifiedPhotoSnapshot(
                assetLocalIdentifier: "a1", pillarID: UUID(0), status: .classified
            ),
            ClassifiedPhotoSnapshot(
                assetLocalIdentifier: "a2", pillarID: UUID(1), status: .classified
            ),
            ClassifiedPhotoSnapshot(
                assetLocalIdentifier: "a3", status: .classified
            ),
        ]

        let store = TestStore(initialState: state) {
            ExploreFeature()
        }

        await store.send(.filterSelected(.pillar(UUID(0)))) {
            $0.selectedFilter = .pillar(UUID(0))
        }
        XCTAssertEqual(store.state.filteredPhotos.count, 1)
        XCTAssertEqual(store.state.filteredPhotos.first?.assetLocalIdentifier, "a1")

        await store.send(.filterSelected(.uncategorized)) {
            $0.selectedFilter = .uncategorized
        }
        XCTAssertEqual(store.state.filteredPhotos.count, 1)
        XCTAssertEqual(store.state.filteredPhotos.first?.assetLocalIdentifier, "a3")

        await store.send(.filterSelected(.all)) {
            $0.selectedFilter = .all
        }
        XCTAssertEqual(store.state.filteredPhotos.count, 3)
    }

    func test_onAppear_doesNotReloadIfAlreadyLoaded() async {
        var state = ExploreFeature.State()
        state.photos = [
            ClassifiedPhotoSnapshot(assetLocalIdentifier: "a1", status: .classified),
        ]

        let store = TestStore(initialState: state) {
            ExploreFeature()
        }

        await store.send(.onAppear)
    }
}
