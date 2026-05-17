import ComposableArchitecture
import Foundation
import UIKit
import XCTest
@testable import PostKit

@MainActor
final class DashboardFeatureTests: XCTestCase {

    func test_onAppear_loadsPillars() async {
        let pillars = [
            PillarSnapshot(name: "Travel", emoji: "✈️", photoCount: 10),
            PillarSnapshot(name: "Food", emoji: "🍽️", photoCount: 5),
        ]

        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        } withDependencies: {
            $0.persistence.fetchPillars = { pillars }
        }

        await store.send(.onAppear)

        await store.receive(\.pillarsLoaded) {
            $0.pillars = IdentifiedArrayOf(uniqueElements: pillars)
        }
    }

    func test_startFullScan_processesBatches_andUpdatesPillars() async {
        let batch1 = [PhotoAsset(localIdentifier: "a1"), PhotoAsset(localIdentifier: "a2")]
        let batch2 = [PhotoAsset(localIdentifier: "b1"), PhotoAsset(localIdentifier: "b2")]
        let pillars = [
            PillarSnapshot(id: UUID(0), name: "Automotive", emoji: "🚗"),
            PillarSnapshot(id: UUID(1), name: "Travel", emoji: "✈️"),
        ]

        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        } withDependencies: {
            $0.persistence.fetchPillars = { pillars }
            $0.photoLibrary.fetchAllPhotos = { _ in
                AsyncStream { continuation in
                    continuation.yield(batch1)
                    continuation.yield(batch2)
                    continuation.finish()
                }
            }
            $0.photoLibrary.image = { _, _ in UIImage() }
            $0.imageClassifier.classify = { _ in
                ClassificationResult(
                    pillarName: "Automotive",
                    confidence: 0.9,
                    suggestedTags: [],
                    source: .coreML
                )
            }
        }

        await store.send(.startFullScanRequested) {
            $0.isScanning = true
        }

        await store.receive(\.pillarsLoaded) {
            $0.pillars = IdentifiedArrayOf(uniqueElements: pillars)
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
            $0.scanProgress = 1
            $0.showScanCompleteToast = true
        }

        await store.receive(\.scanCompleteToastDismissed, timeout: .seconds(5)) {
            $0.showScanCompleteToast = false
        }
    }

    func test_cancelScan_cancelsEffect() async {
        let store = TestStore(initialState: DashboardFeature.State()) {
            DashboardFeature()
        } withDependencies: {
            $0.persistence.fetchPillars = { [] }
            $0.photoLibrary.fetchAllPhotos = { _ in
                AsyncStream { _ in }
            }
            $0.photoLibrary.image = { _, _ in UIImage() }
            $0.imageClassifier.classify = { _ in
                ClassificationResult(
                    pillarName: "Travel",
                    confidence: 0.8,
                    suggestedTags: [],
                    source: .coreML
                )
            }
        }

        await store.send(.startFullScanRequested) {
            $0.isScanning = true
        }

        // pillarsLoaded arrives before any batch
        await store.receive(\.pillarsLoaded)

        await store.send(.cancelScanTapped) {
            $0.isScanning = false
        }
    }
}
