import ComposableArchitecture
import Foundation
import UIKit
import XCTest
@testable import PostKit

@MainActor
final class DashboardFeatureTests: XCTestCase {

    private let testDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let travelID = UUID(0)
    private let foodID = UUID(1)

    private func makePillars() -> [PillarSnapshot] {
        [
            PillarSnapshot(id: travelID, name: "Travel", emoji: "✈️", referenceTags: ["travel"]),
            PillarSnapshot(id: foodID, name: "Food", emoji: "🍽️", referenceTags: ["food"]),
        ]
    }

    private func makePhotos() -> [ClassifiedPhotoSnapshot] {
        let travel = (0..<10).map {
            ClassifiedPhotoSnapshot(
                assetLocalIdentifier: "t\($0)", pillarID: travelID, pillarIDs: [travelID], status: .classified
            )
        }
        let food = (0..<5).map {
            ClassifiedPhotoSnapshot(
                assetLocalIdentifier: "f\($0)", pillarID: foodID, pillarIDs: [foodID], status: .classified
            )
        }
        return travel + food
    }

    // MARK: - onAppear

    func test_onAppear_loadsPillarsWithCounts() async {
        let pillars = makePillars()
        let allPhotos = makePhotos()

        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        } withDependencies: {
            $0.gallery.pillars = { pillars }
            $0.gallery.photos = { _ in allPhotos }
            $0.gallery.templates = { [] }
            $0.photoLibrary.countAllPhotos = { 100 }
            $0.userDefaults.boolForKey = { _ in true }
            $0.userDefaults.doubleForKey = { _ in 0 }
            $0.date = .constant(self.testDate)
        }

        await store.send(.onAppear)

        await store.receive(\.dashboardLoaded) {
            $0.isInitialLoading = false
            $0.pillars = IdentifiedArrayOf(uniqueElements: [
                PillarSnapshot(
                    id: self.travelID, name: "Travel", emoji: "✈️",
                    referenceTags: ["travel"], photoCount: 10,
                    topPhotoAssetIDs: ["t0", "t1", "t2", "t3"]
                ),
                PillarSnapshot(
                    id: self.foodID, name: "Food", emoji: "🍽️",
                    referenceTags: ["food"], photoCount: 5,
                    topPhotoAssetIDs: ["f0", "f1", "f2", "f3"]
                ),
            ])
            $0.totalPhotosSorted = 15
            $0.hasCompletedInitialScan = true
            $0.lastScanCompletedAt = self.testDate
            $0.totalLibraryCount = 100
            $0.classifiedAssetCount = 15
        }

        await store.receive(\.scheduledTemplatesLoaded)
    }

    // MARK: - Full Scan

    func test_startFullScan_processesBatches_andUpdatesPillars() async {
        let batch1 = [PhotoAsset(localIdentifier: "a1"), PhotoAsset(localIdentifier: "a2")]
        let batch2 = [PhotoAsset(localIdentifier: "b1"), PhotoAsset(localIdentifier: "b2")]
        let pillars = makePillars()

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
            $0.photoLibrary.fetchAllAssetIDs = { [] }
            $0.photoLibrary.image = { _, _ in UIImage() }
            $0.imageClassifier.classifyWithCadrage = { _, _ in
                ClassificationOutput(
                    results: [ClassificationResult(
                        pillarName: "Travel", confidence: 0.9, suggestedTags: [], source: .coreML
                    )],
                    cadrage: .wide
                )
            }
            $0.persistence.batchSavePhotos = { _ in }
            $0.persistence.fetchClassifiedAssetIDs = { [] }
            $0.persistence.deletePhotosByAssetIDs = { _ in }
            $0.gallery.invalidatePhotos = {}
            $0.gallery.invalidateAll = {}
            $0.gallery.photos = { _ in [] }
            $0.geocoder.reverseGeocode = { _ in nil }
            $0.userDefaults.setBool = { _, _ in }
            $0.userDefaults.setDouble = { _, _ in }
            $0.date = .constant(self.testDate)
        }

        await store.send(.startFullScanRequested) {
            $0.isScanning = true
        }

        await store.receive(\.pillarsEnriched) {
            $0.scanStartedAt = self.testDate
        }

        await store.receive(\.batchProcessed) {
            $0.totalPhotosSorted = 2
            $0.classifiedAssetCount = 2
            $0.pillars[id: self.travelID]?.photoCount = 2
            $0.pillars[id: self.travelID]?.topPhotoAssetIDs = ["a2", "a1"]
        }

        await store.receive(\.batchProcessed) {
            $0.totalPhotosSorted = 4
            $0.classifiedAssetCount = 4
            $0.pillars[id: self.travelID]?.photoCount = 4
            $0.pillars[id: self.travelID]?.topPhotoAssetIDs = ["b2", "b1", "a2", "a1"]
        }

        await store.receive(\.scanFinished) {
            $0.isScanning = false
            $0.hasCompletedInitialScan = true
            $0.scanProgress = 1
            $0.showScanCompleteToast = true
            $0.lastScanCompletedAt = self.testDate
        }

        await store.receive(\.resolveLocations)

        await store.receive(\.scanCompleteToastDismissed, timeout: .seconds(5)) {
            $0.showScanCompleteToast = false
        }
    }

    func test_cancelScan_cancelsEffect() async {
        let pillars = makePillars()

        var state = DashboardFeature.State()
        state.isInitialLoading = false
        state.pillars = IdentifiedArrayOf(uniqueElements: pillars)

        let store = TestStore(initialState: state) {
            DashboardFeature()
        } withDependencies: {
            $0.photoLibrary.fetchAllPhotos = { _ in AsyncStream { _ in } }
            $0.photoLibrary.fetchAllAssetIDs = { [] }
            $0.photoLibrary.image = { _, _ in UIImage() }
            $0.imageClassifier.classifyWithCadrage = { _, _ in
                ClassificationOutput(results: [], cadrage: .wide)
            }
            $0.persistence.batchSavePhotos = { _ in }
            $0.persistence.fetchClassifiedAssetIDs = { [] }
            $0.persistence.deletePhotosByAssetIDs = { _ in }
            $0.gallery.invalidatePhotos = {}
            $0.date = .constant(self.testDate)
        }

        await store.send(.startFullScanRequested) {
            $0.isScanning = true
        }

        await store.receive(\.pillarsEnriched) {
            $0.scanStartedAt = self.testDate
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

    func test_derivedStatus_newItems_whenNewPhotosExist() {
        var state = DashboardFeature.State()
        state.pendingReviewCount = 7
        state.newPhotoCount = 3
        XCTAssertEqual(state.derivedStatus, .newItems(count: 3))
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
        }

        await store.send(.statusPrimaryTapped)
        await store.receive(\.cancelScanTapped) {
            $0.isScanning = false
        }
    }

    func test_statusPrimaryTapped_whileIdle_emitsStartFullScan() async {
        let pillars = makePillars()

        var state = DashboardFeature.State()
        state.isInitialLoading = false
        state.pillars = IdentifiedArrayOf(uniqueElements: pillars)

        let store = TestStore(initialState: state) {
            DashboardFeature()
        } withDependencies: {
            $0.photoLibrary.fetchAllPhotos = { _ in AsyncStream { $0.finish() } }
            $0.photoLibrary.fetchAllAssetIDs = { [] }
            $0.photoLibrary.image = { _, _ in UIImage() }
            $0.imageClassifier.classifyWithCadrage = { _, _ in
                ClassificationOutput(results: [], cadrage: .wide)
            }
            $0.persistence.fetchClassifiedAssetIDs = { [] }
            $0.persistence.batchSavePhotos = { _ in }
            $0.persistence.deletePhotosByAssetIDs = { _ in }
            $0.gallery.invalidatePhotos = {}
            $0.gallery.invalidateAll = {}
            $0.gallery.photos = { _ in [] }
            $0.geocoder.reverseGeocode = { _ in nil }
            $0.userDefaults.setBool = { _, _ in }
            $0.userDefaults.setDouble = { _, _ in }
            $0.date = .constant(self.testDate)
        }

        await store.send(.statusPrimaryTapped)
        await store.receive(\.startFullScanRequested) {
            $0.isScanning = true
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
        await store.receive(\.resolveLocations)
        await store.receive(\.scanCompleteToastDismissed, timeout: .seconds(5)) {
            $0.showScanCompleteToast = false
        }
    }

    func test_statusPrimaryTapped_whenPaused_emitsStartFullScan() async {
        let pillars = makePillars()

        var state = DashboardFeature.State()
        state.isInitialLoading = false
        state.totalLibraryCount = 500
        state.classifiedAssetCount = 200
        state.pillars = IdentifiedArrayOf(uniqueElements: pillars)

        let store = TestStore(initialState: state) {
            DashboardFeature()
        } withDependencies: {
            $0.photoLibrary.fetchAllPhotos = { _ in AsyncStream { $0.finish() } }
            $0.photoLibrary.fetchAllAssetIDs = { [] }
            $0.photoLibrary.image = { _, _ in UIImage() }
            $0.imageClassifier.classifyWithCadrage = { _, _ in
                ClassificationOutput(results: [], cadrage: .wide)
            }
            $0.persistence.fetchClassifiedAssetIDs = { [] }
            $0.persistence.batchSavePhotos = { _ in }
            $0.persistence.deletePhotosByAssetIDs = { _ in }
            $0.gallery.invalidatePhotos = {}
            $0.gallery.invalidateAll = {}
            $0.gallery.photos = { _ in [] }
            $0.geocoder.reverseGeocode = { _ in nil }
            $0.userDefaults.setBool = { _, _ in }
            $0.userDefaults.setDouble = { _, _ in }
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
        await store.receive(\.resolveLocations)
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
        let pillars = makePillars()

        var state = DashboardFeature.State()
        state.isInitialLoading = false

        let store = TestStore(initialState: state) {
            DashboardFeature()
        } withDependencies: {
            $0.gallery.pillars = { pillars }
            $0.gallery.photos = { _ in [] }
            $0.gallery.templates = { [] }
            $0.gallery.invalidateAll = {}
            $0.photoLibrary.countAllPhotos = { 0 }
            $0.userDefaults.boolForKey = { _ in true }
            $0.userDefaults.doubleForKey = { _ in 0 }
            $0.date = .constant(self.testDate)
        }

        await store.send(.pullToRefresh)
        await store.receive(\.onAppear)
        await store.receive(\.dashboardLoaded) {
            $0.pillars = IdentifiedArrayOf(uniqueElements: pillars.map { p in
                var m = p; m.photoCount = 0; return m
            })
            $0.hasCompletedInitialScan = true
            $0.lastScanCompletedAt = self.testDate
        }
        await store.receive(\.scheduledTemplatesLoaded)
    }
}
