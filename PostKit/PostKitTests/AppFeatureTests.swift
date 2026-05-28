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

    func test_getStarted_whenAuthorized_showsTopicSetup() async {
        let store = TestStore(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        } withDependencies: {
            $0.photoLibrary.requestAuthorization = { .authorized }
        }

        await store.send(.getStartedTapped)

        await store.receive(\.authorizationResponse) {
            $0.step = .topicSetup
        }
    }

    func test_topicSetup_scan_andComplete() async {
        var state = OnboardingFeature.State()
        state.step = .topicSetup
        state.topics = [
            OnboardingTopic(id: UUID(0), name: "Automotive", emoji: "🚗", about: "Cars and vehicles"),
            OnboardingTopic(id: UUID(1), name: "Travel", emoji: "✈️", about: "Travel photography"),
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
            $0.postGenerator.enrichTopic = { _ in throw CancellationError() }
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
            $0.topics[id: UUID(0)]?.matchedPhotos = 1
        }

        await store.receive(\.scanProgressed) {
            $0.scannedCount = 2
            $0.scanProgress = 1.0
            $0.topics[id: UUID(0)]?.matchedPhotos = 2
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

    func test_startPostKit_persistsAllTopics() async {
        let savedNames = LockIsolated<[String]>([])

        var state = OnboardingFeature.State()
        state.step = .scanComplete
        state.topics = [
            OnboardingTopic(id: UUID(0), name: "Travel", emoji: "✈️", about: "Travel photography", matchedPhotos: 5),
            OnboardingTopic(id: UUID(1), name: "Fitness", emoji: "💪", about: "Workout content", matchedPhotos: 2),
        ]

        let store = TestStore(initialState: state) {
            OnboardingFeature()
        } withDependencies: {
            $0.persistence.fetchPillars = { [] }
            $0.persistence.savePillar = { snapshot in
                savedNames.withValue { $0.append(snapshot.name) }
            }
            $0.gallery.invalidateAll = {}
        }

        await store.send(.startPostKitTapped) {
            $0.isSaving = true
        }

        await store.receive(\.persistResponse) {
            $0.isSaving = false
        }

        XCTAssertEqual(savedNames.value, ["Travel", "Fitness"])
    }

    func test_addTopic_addsTopicToList() async {
        let store = TestStore(initialState: OnboardingFeature.State(step: .topicSetup)) {
            OnboardingFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }

        await store.send(.set(\.topicInput, "cars")) {
            $0.topicInput = "cars"
        }

        await store.send(.addTopicTapped) {
            $0.topicInput = ""
            $0.topics = [
                OnboardingTopic(id: UUID(0), name: "Cars", emoji: "📌", about: ""),
            ]
        }
    }
}
