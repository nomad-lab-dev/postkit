import ComposableArchitecture
import Foundation
@preconcurrency import Photos
import UIKit
import XCTest
@testable import PostKit

@MainActor
final class AppFeatureTests: XCTestCase {
    func test_onboarding_presentedWhenStateHasIt() async {
        var state = AppFeature.State()
        state.onboarding = OnboardingFeature.State()

        let store = TestStore(initialState: state) {
            AppFeature()
        }

        await store.send(.appLaunched)
        XCTAssertNotNil(store.state.onboarding)
    }
}

@MainActor
final class OnboardingFeatureTests: XCTestCase {

    func test_getStarted_whenAuthorized_showsPillarSetup() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.photoLibrary.requestAuthorization = { .authorized }
        }

        await store.send(.getStartedTapped)

        await store.receive(\.authorizationResponse) {
            $0.step = .pillarSetup
            $0.availablePillars = IdentifiedArrayOf(
                uniqueElements: OnboardingFeature.defaultPillars.enumerated().map { index, p in
                    PillarOption(
                        id: UUID(index),
                        name: p.name,
                        emoji: p.emoji,
                        isSelected: false
                    )
                }
            )
        }
    }

    func test_pillarSetup_scan_andComplete() async {
        let autoID = UUID(0)
        var state = OnboardingFeature.State()
        state.step = .pillarSetup
        state.availablePillars = [
            PillarOption(id: autoID, name: "Automotive", emoji: "🚗", isSelected: true),
            PillarOption(id: UUID(1), name: "Travel", emoji: "✈️", isSelected: false),
        ]

        let store = TestStore(initialState: state) {
            OnboardingFeature()
        } withDependencies: {
            $0.photoLibrary.fetchRecentPhotos = { _ in
                [PhotoAsset(localIdentifier: "a1"), PhotoAsset(localIdentifier: "a2")]
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
        }

        await store.send(.startScanTapped) {
            $0.step = .scanning
            $0.scannedCount = 0
            $0.scanProgress = 0
        }

        await store.receive(\.scanStarted) {
            $0.totalToScan = 2
        }

        await store.receive(\.scanProgressed) {
            $0.scannedCount = 1
            $0.scanProgress = 0.5
            $0.availablePillars[id: autoID]?.matchedPhotos = 1
        }

        await store.receive(\.scanProgressed) {
            $0.scannedCount = 2
            $0.scanProgress = 1.0
            $0.availablePillars[id: autoID]?.matchedPhotos = 2
        }

        await store.receive(\.scanFinished) {
            $0.step = .scanComplete
        }
    }

    func test_getStarted_whenDenied_setsPhotoAccessDenied() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        } withDependencies: {
            $0.photoLibrary.requestAuthorization = { .denied }
        }

        await store.send(.getStartedTapped)

        await store.receive(\.authorizationResponse) {
            $0.photoAccessDenied = true
        }
    }

    func test_startPostKit_persistsSelectedPillars() async {
        let savedNames = LockIsolated<[String]>([])

        var state = OnboardingFeature.State()
        state.step = .scanComplete
        state.availablePillars = [
            PillarOption(id: UUID(), name: "Travel", emoji: "✈️", isSelected: true, matchedPhotos: 5),
            PillarOption(id: UUID(), name: "Food", emoji: "🍽️", isSelected: false, matchedPhotos: 0),
            PillarOption(id: UUID(), name: "Fitness", emoji: "💪", isSelected: true, matchedPhotos: 2),
        ]

        let store = TestStore(initialState: state) {
            OnboardingFeature()
        } withDependencies: {
            $0.persistence.savePillar = { snapshot in
                savedNames.withValue { $0.append(snapshot.name) }
            }
        }

        await store.send(.startPostKitTapped)

        await store.receive(\.persistResponse)

        XCTAssertEqual(savedNames.value, ["Travel", "Fitness"])
    }
}
