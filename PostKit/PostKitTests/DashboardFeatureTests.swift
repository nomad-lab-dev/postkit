import ComposableArchitecture
import Foundation
import UIKit
import XCTest
@testable import PostKit

@MainActor
final class DashboardFeatureTests: XCTestCase {

    private let testDate = Date(timeIntervalSince1970: 1_700_000_000)

    func test_onAppear_loadsPillarsWithCounts() async {
        let travelID = UUID(0)
        let foodID = UUID(1)
        let pillars = [
            PillarSnapshot(id: travelID, name: "Travel", emoji: "✈️"),
            PillarSnapshot(id: foodID, name: "Food", emoji: "🍽️"),
        ]

        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        } withDependencies: {
            $0.persistence.fetchPillars = { pillars }
            $0.persistence.countPhotosPerPillar = { [travelID: 10, foodID: 5] }
            $0.persistence.fetchPhotos = { _ in [] }
            $0.persistence.fetchPhotosForPillar = { _ in [] }
            $0.persistence.fetchClassifiedAssetIDs = { ["a1", "a2", "a3"] }
            $0.photoLibrary.countAllPhotos = { 100 }
            $0.userDefaults.boolForKey = { _ in true }
            $0.date = .constant(self.testDate)
        }

        await store.send(.onAppear)

        await store.receive(\.dashboardLoaded) {
            $0.isInitialLoading = false
            $0.pillars = IdentifiedArrayOf(uniqueElements: [
                PillarSnapshot(id: travelID, name: "Travel", emoji: "✈️", photoCount: 10),
                PillarSnapshot(id: foodID, name: "Food", emoji: "🍽️", photoCount: 5),
            ])
            $0.totalPhotosSorted = 15
            $0.hasCompletedInitialScan = true
            $0.lastScanCompletedAt = self.testDate
            $0.totalLibraryCount = 100
            $0.classifiedAssetCount = 3
        }
    }

    func test_startFullScan_processesBatches_andUpdatesPillars() async {
        let batch1 = [PhotoAsset(localIdentifier: "a1"), PhotoAsset(localIdentifier: "a2")]
        let batch2 = [PhotoAsset(localIdentifier: "b1"), PhotoAsset(localIdentifier: "b2")]
        let pillars = [
            PillarSnapshot(id: UUID(0), name: "Automotive", emoji: "🚗"),
            PillarSnapshot(id: UUID(1), name: "Travel", emoji: "✈️"),
        ]

        var state = DashboardFeature.State()
        state.isInitialLoading = false
        state.pillars = IdentifiedArrayOf(uniqueElements: pillars)

        let store = TestStore(initialState: state) {
            DashboardFeature()
        } withDependencies: {
            $0.photoLibrary.fetchAllPhotos = { _ in
                AsyncStream { continuation in
                    continuation.yield(batch1)
                    continuation.yield(batch2)
                    continuation.finish()
                }
            }
            $0.photoLibrary.image = { _, _ in UIImage() }
            $0.imageClassifier.classify = { _, _ in
                [ClassificationResult(
                    pillarName: "Automotive",
                    confidence: 0.9,
                    suggestedTags: [],
                    source: .coreML
                )]
            }
            $0.imageClassifier.detectCadrage = { _ in .wide }
            $0.persistence.batchSavePhotos = { _ in }
            $0.persistence.fetchClassifiedAssetIDs = { [] }
            $0.geocoder.reverseGeocode = { _ in nil }
            $0.userDefaults.setBool = { _, _ in }
            $0.date = .constant(self.testDate)
        }

        await store.send(.startFullScanRequested) {
            $0.isScanning = true
        }

        await store.receive(\.batchProcessed) {
            $0.totalPhotosSorted = 2
            $0.pillars[id: UUID(0)]?.photoCount = 2
        }

        await store.receive(\.batchProcessed) {
            $0.totalPhotosSorted = 4
            $0.pillars[id: UUID(0)]?.photoCount = 4
        }

        await store.receive(\.scanFinished) {
            $0.isScanning = false
            $0.hasCompletedInitialScan = true
            $0.scanProgress = 1
            $0.showScanCompleteToast = true
            $0.lastScanCompletedAt = self.testDate
        }

        await store.receive(\.scanCompleteToastDismissed, timeout: .seconds(5)) {
            $0.showScanCompleteToast = false
        }
    }

    func test_cancelScan_cancelsEffect() async {
        let pillars = [
            PillarSnapshot(id: UUID(0), name: "Travel", emoji: "✈️"),
        ]

        var state = DashboardFeature.State()
        state.isInitialLoading = false
        state.pillars = IdentifiedArrayOf(uniqueElements: pillars)

        let store = TestStore(initialState: state) {
            DashboardFeature()
        } withDependencies: {
            $0.photoLibrary.fetchAllPhotos = { _ in
                AsyncStream { _ in }
            }
            $0.photoLibrary.image = { _, _ in UIImage() }
            $0.imageClassifier.classify = { _, _ in
                [ClassificationResult(
                    pillarName: "Travel",
                    confidence: 0.8,
                    suggestedTags: [],
                    source: .coreML
                )]
            }
            $0.imageClassifier.detectCadrage = { _ in .wide }
            $0.persistence.batchSavePhotos = { _ in }
            $0.persistence.fetchClassifiedAssetIDs = { [] }
            $0.geocoder.reverseGeocode = { _ in nil }
            $0.userDefaults.setBool = { _, _ in }
            $0.date = .constant(self.testDate)
        }

        await store.send(.startFullScanRequested) {
            $0.isScanning = true
        }

        await store.send(.cancelScanTapped) {
            $0.isScanning = false
        }
    }

    // MARK: - derivedStatus Tests

    func test_derivedStatus_idle_whenNoCountsAndNotScanning() {
        let state = DashboardFeature.State()
        XCTAssertEqual(state.derivedStatus, .idle(lastScanAt: nil))
    }

    func test_derivedStatus_scanning_takesPrecedence() {
        var state = DashboardFeature.State()
        state.isScanning = true
        state.scanProgress = 0.5
        state.totalPhotosToScan = 100
        state.pendingReviewCount = 10
        state.newPhotoCount = 5
        XCTAssertEqual(state.derivedStatus, .scanning(progress: 0.5, processed: 50, total: 100, startedAt: nil))
    }

    func test_derivedStatus_reviewNeeded_beforeNewItems() {
        var state = DashboardFeature.State()
        state.pendingReviewCount = 7
        state.newPhotoCount = 3
        XCTAssertEqual(state.derivedStatus, .reviewNeeded(count: 7))
    }

    func test_derivedStatus_newItems_whenNoPending() {
        var state = DashboardFeature.State()
        state.newPhotoCount = 12
        XCTAssertEqual(state.derivedStatus, .newItems(count: 12))
    }

    func test_derivedStatus_idle_withLastScanDate() {
        var state = DashboardFeature.State()
        let date = Date(timeIntervalSince1970: 1_000_000)
        state.lastScanCompletedAt = date
        XCTAssertEqual(state.derivedStatus, .idle(lastScanAt: date))
    }

    func test_derivedStatus_paused_whenRemainingAndClassified() {
        var state = DashboardFeature.State()
        state.totalLibraryCount = 500
        state.classifiedAssetCount = 200
        XCTAssertEqual(state.derivedStatus, .paused(remaining: 300))
    }

    func test_derivedStatus_paused_notShown_whenNoClassified() {
        var state = DashboardFeature.State()
        state.totalLibraryCount = 500
        state.classifiedAssetCount = 0
        XCTAssertEqual(state.derivedStatus, .idle(lastScanAt: nil))
    }

    // MARK: - statusPrimaryTapped Routing

    func test_statusPrimaryTapped_whileScanning_emitsCancelScan() async {
        var state = DashboardFeature.State()
        state.isInitialLoading = false
        state.isScanning = true

        let store = TestStore(initialState: state) {
            DashboardFeature()
        } withDependencies: {
            $0.userDefaults.setBool = { _, _ in }
            $0.date = .constant(self.testDate)
        }

        await store.send(.statusPrimaryTapped)
        await store.receive(\.cancelScanTapped) {
            $0.isScanning = false
        }
    }

    func test_statusPrimaryTapped_whileIdle_emitsStartFullScan() async {
        var state = DashboardFeature.State()
        state.isInitialLoading = false
        state.pillars = IdentifiedArrayOf(uniqueElements: [
            PillarSnapshot(id: UUID(0), name: "Travel", emoji: "✈️"),
        ])

        let store = TestStore(initialState: state) {
            DashboardFeature()
        } withDependencies: {
            $0.photoLibrary.fetchAllPhotos = { _ in AsyncStream { $0.finish() } }
            $0.photoLibrary.image = { _, _ in UIImage() }
            $0.imageClassifier.classify = { _, _ in [] }
            $0.imageClassifier.detectCadrage = { _ in .wide }
            $0.persistence.fetchClassifiedAssetIDs = { [] }
            $0.persistence.batchSavePhotos = { _ in }
            $0.geocoder.reverseGeocode = { _ in nil }
            $0.userDefaults.setBool = { _, _ in }
            $0.date = .constant(self.testDate)
        }

        await store.send(.statusPrimaryTapped)
        await store.receive(\.startFullScanRequested) {
            $0.isScanning = true
        }
        await store.receive(\.scanFinished) {
            $0.isScanning = false
            $0.hasCompletedInitialScan = true
            $0.scanProgress = 1
            $0.showScanCompleteToast = true
            $0.lastScanCompletedAt = self.testDate
        }
        await store.receive(\.scanCompleteToastDismissed, timeout: .seconds(5)) {
            $0.showScanCompleteToast = false
        }
    }

    func test_statusPrimaryTapped_whenPaused_emitsStartFullScan() async {
        var state = DashboardFeature.State()
        state.isInitialLoading = false
        state.totalLibraryCount = 500
        state.classifiedAssetCount = 200
        state.pillars = IdentifiedArrayOf(uniqueElements: [
            PillarSnapshot(id: UUID(0), name: "Travel", emoji: "✈️"),
        ])

        let store = TestStore(initialState: state) {
            DashboardFeature()
        } withDependencies: {
            $0.photoLibrary.fetchAllPhotos = { _ in AsyncStream { $0.finish() } }
            $0.photoLibrary.image = { _, _ in UIImage() }
            $0.photoLibrary.fetchAllAssetIDs = { [] }
            $0.imageClassifier.classifyWithCadrage = { _, _ in
                ClassificationOutput(results: [], cadrage: .wide)
            }
            $0.persistence.fetchClassifiedAssetIDs = { [] }
            $0.persistence.batchSavePhotos = { _ in }
            $0.persistence.deletePhotosByAssetIDs = { _ in }
            $0.geocoder.reverseGeocode = { _ in nil }
            $0.gallery.invalidatePhotos = { }
            $0.gallery.invalidateAll = { }
            $0.userDefaults.setBool = { _, _ in }
            $0.date = .constant(self.testDate)
        }

        await store.send(.statusPrimaryTapped)
        await store.receive(\.startFullScanRequested) {
            $0.isScanning = true
            $0.scanProgress = 0
            $0.totalPhotosToScan = 300
        }
        await store.receive(\.pillarsEnriched) {
            $0.scanStartedAt = self.testDate
        }
        await store.receive(\.scanFinished) {
            $0.isScanning = false
            $0.hasCompletedInitialScan = true
            $0.scanProgress = 1
            $0.showScanCompleteToast = true
            $0.lastScanCompletedAt = self.testDate
        }
        await store.receive(\.scanCompleteToastDismissed, timeout: .seconds(5)) {
            $0.showScanCompleteToast = false
        }
    }

    func test_statusPrimaryTapped_whenReviewNeeded_emitsReviewPending() async {
        var state = DashboardFeature.State()
        state.isInitialLoading = false
        state.pendingReviewCount = 5

        let store = TestStore(initialState: state) {
            DashboardFeature()
        }

        await store.send(.statusPrimaryTapped)
        await store.receive(\.reviewPendingTapped) {
            $0.classificationQueue = ClassificationQueueFeature.State()
        }
    }

    func test_pullToRefresh_callsOnAppear() async {
        var state = DashboardFeature.State()
        state.isInitialLoading = false

        let store = TestStore(initialState: state) {
            DashboardFeature()
        } withDependencies: {
            $0.persistence.fetchPillars = { [] }
            $0.persistence.countPhotosPerPillar = { [:] }
            $0.persistence.fetchPhotos = { _ in [] }
            $0.persistence.fetchPhotosForPillar = { _ in [] }
            $0.persistence.fetchClassifiedAssetIDs = { [] }
            $0.photoLibrary.countAllPhotos = { 0 }
            $0.userDefaults.boolForKey = { _ in true }
            $0.date = .constant(self.testDate)
        }

        await store.send(.pullToRefresh)
        await store.receive(\.onAppear) {
            $0.isInitialLoading = true
        }
        await store.receive(\.dashboardLoaded) {
            $0.isInitialLoading = false
            $0.hasCompletedInitialScan = true
            $0.lastScanCompletedAt = self.testDate
        }
    }
}
