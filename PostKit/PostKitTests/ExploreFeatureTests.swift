import ComposableArchitecture
import Foundation
import XCTest
@testable import PostKit

@MainActor
final class ExploreFeatureTests: XCTestCase {

    private let pillars = [
        PillarSnapshot(id: UUID(0), name: "Travel", emoji: "✈️"),
        PillarSnapshot(id: UUID(1), name: "Food", emoji: "🍽️"),
    ]

    private func makePhotos(count: Int, prefix: String = "a", pillarID: UUID? = nil, cadrage: Cadrage? = .wide) -> [ClassifiedPhotoSnapshot] {
        (0..<count).map {
            ClassifiedPhotoSnapshot(
                assetLocalIdentifier: "\(prefix)\($0)",
                pillarID: pillarID,
                confidence: 0.9,
                status: .classified,
                cadrage: cadrage
            )
        }
    }

    // MARK: - Initial Load

    func test_onAppear_loadsPaginatedPhotosAndPillars() async {
        let photos = makePhotos(count: 3, pillarID: UUID(0))

        let store = TestStore(initialState: ExploreFeature.State()) {
            ExploreFeature()
        } withDependencies: {
            $0.gallery.pillars = { self.pillars }
            $0.gallery.photos = { _ in photos }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.initialLoaded) {
            $0.pillars = self.pillars
            $0.photos = photos
            $0.totalCount = 3
            $0.currentOffset = 3
            $0.isLoading = false
        }
    }

    func test_onAppear_doesNotReloadIfAlreadyLoaded() async {
        var state = ExploreFeature.State()
        state.photos = makePhotos(count: 1)

        let store = TestStore(initialState: state) {
            ExploreFeature()
        }

        await store.send(.onAppear)
    }

    func test_onAppear_backfillsCadrageForPhotosMissingIt() async {
        let photos = [
            ClassifiedPhotoSnapshot(assetLocalIdentifier: "a0", status: .classified, cadrage: nil),
        ]

        let store = TestStore(initialState: ExploreFeature.State()) {
            ExploreFeature()
        } withDependencies: {
            $0.gallery.pillars = { [] }
            $0.gallery.photos = { _ in photos }
            $0.photoLibrary.image = { _, _ in UIImage() }
            $0.imageClassifier.detectCadrage = { _ in .portrait }
            $0.persistence.savePhoto = { _ in }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.initialLoaded) {
            $0.photos = photos
            $0.totalCount = 1
            $0.currentOffset = 1
            $0.isLoading = false
        }

        await store.receive(\.cadrageBackfilled) {
            $0.photos[0].cadrage = .portrait
        }
    }

    // MARK: - Pagination

    func test_loadMore_fetchesNextPage() async {
        var state = ExploreFeature.State()
        state.photos = makePhotos(count: 60, prefix: "page1-")
        state.currentOffset = 60
        state.totalCount = 120

        let page2 = makePhotos(count: 60, prefix: "page2-")

        let store = TestStore(initialState: state) {
            ExploreFeature()
        } withDependencies: {
            $0.persistence.fetchPhotosPaginated = { _, limit, offset in
                XCTAssertEqual(offset, 60)
                XCTAssertEqual(limit, ExploreFeature.pageSize)
                return page2
            }
        }

        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }

        await store.receive(\.pageLoaded) {
            $0.isLoadingMore = false
            $0.photos.append(contentsOf: page2)
            $0.currentOffset = 120
        }
    }

    func test_loadMore_deduplicatesPhotos() async {
        let existing = makePhotos(count: 3, prefix: "dup-")
        var state = ExploreFeature.State()
        state.photos = existing
        state.currentOffset = 3
        state.totalCount = 10

        let overlapping = [
            existing[2],
            ClassifiedPhotoSnapshot(assetLocalIdentifier: "new1", status: .classified, cadrage: .wide),
        ]

        let store = TestStore(initialState: state) {
            ExploreFeature()
        } withDependencies: {
            $0.persistence.fetchPhotosPaginated = { _, _, _ in overlapping }
        }

        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }

        await store.receive(\.pageLoaded) {
            $0.isLoadingMore = false
            $0.photos.append(contentsOf: [overlapping[1]])
            $0.currentOffset = 5
        }
    }

    func test_loadMore_stopsWhenNoMorePages() async {
        var state = ExploreFeature.State()
        state.photos = makePhotos(count: 5)
        state.currentOffset = 5
        state.totalCount = 5

        let store = TestStore(initialState: state) {
            ExploreFeature()
        }

        await store.send(.loadMore)
    }

    func test_loadMore_doesNotFireWhileAlreadyLoading() async {
        var state = ExploreFeature.State()
        state.photos = makePhotos(count: 60)
        state.currentOffset = 60
        state.totalCount = 120
        state.isLoadingMore = true

        let store = TestStore(initialState: state) {
            ExploreFeature()
        }

        await store.send(.loadMore)
    }

    func test_loadMore_capsCountWhenServerReturnsEmpty() async {
        var state = ExploreFeature.State()
        state.photos = makePhotos(count: 60)
        state.currentOffset = 60
        state.totalCount = 120

        let store = TestStore(initialState: state) {
            ExploreFeature()
        } withDependencies: {
            $0.persistence.fetchPhotosPaginated = { _, _, _ in [] }
        }

        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }

        await store.receive(\.pageLoaded) {
            $0.isLoadingMore = false
            $0.totalCount = 60
        }
    }

    // MARK: - Filters

    func test_filterByPillar_filtersCorrectly() async {
        var state = ExploreFeature.State()
        state.pillars = pillars
        state.photos = [
            ClassifiedPhotoSnapshot(assetLocalIdentifier: "a1", pillarID: UUID(0), status: .classified, cadrage: .wide),
            ClassifiedPhotoSnapshot(assetLocalIdentifier: "a2", pillarID: UUID(1), status: .classified, cadrage: .portrait),
            ClassifiedPhotoSnapshot(assetLocalIdentifier: "a3", status: .classified, cadrage: .detail),
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

    func test_statusFilter_filtersCorrectly() async {
        var state = ExploreFeature.State()
        state.photos = [
            ClassifiedPhotoSnapshot(assetLocalIdentifier: "c1", status: .classified, cadrage: .wide),
            ClassifiedPhotoSnapshot(assetLocalIdentifier: "p1", status: .pending),
            ClassifiedPhotoSnapshot(assetLocalIdentifier: "r1", status: .rejected, cadrage: .detail),
        ]

        let store = TestStore(initialState: state) {
            ExploreFeature()
        }

        await store.send(.statusFilterSelected(.pending)) {
            $0.statusFilter = .pending
        }
        XCTAssertEqual(store.state.filteredPhotos.count, 1)
        XCTAssertEqual(store.state.filteredPhotos.first?.assetLocalIdentifier, "p1")

        await store.send(.statusFilterSelected(nil)) {
            $0.statusFilter = nil
        }
        XCTAssertEqual(store.state.filteredPhotos.count, 3)
    }

    // MARK: - Photo Tapped

    func test_photoTapped_pendingOpensCard() async {
        let pending = ClassifiedPhotoSnapshot(assetLocalIdentifier: "p1", pillarID: UUID(0), status: .pending)
        var state = ExploreFeature.State()
        state.photos = [pending]
        state.pillars = pillars

        let store = TestStore(initialState: state) {
            ExploreFeature()
        }

        await store.send(.photoTapped(pending)) {
            $0.card = ClassificationCardFeature.State(
                photos: [pending],
                currentIndex: 0,
                pillars: self.pillars
            )
        }
    }

    func test_photoTapped_classifiedOpensDetail() async {
        let classified = ClassifiedPhotoSnapshot(assetLocalIdentifier: "c1", pillarID: UUID(0), status: .classified, cadrage: .wide)
        var state = ExploreFeature.State()
        state.photos = [classified]
        state.pillars = pillars

        let store = TestStore(initialState: state) {
            ExploreFeature()
        }

        await store.send(.photoTapped(classified)) {
            $0.photoDetail = PhotoDetailFeature.State(
                photo: classified,
                pillars: self.pillars
            )
        }
    }

    // MARK: - Computed Properties

    func test_hasMore_reflectsOffsetVsTotal() {
        var state = ExploreFeature.State()
        state.currentOffset = 60
        state.totalCount = 120
        XCTAssertTrue(state.hasMore)

        state.currentOffset = 120
        XCTAssertFalse(state.hasMore)
    }
}
