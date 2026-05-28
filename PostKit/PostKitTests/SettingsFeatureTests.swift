// MARK: - PostKit
// SettingsFeatureTests.swift — Settings reducer tests: data load, Pro status, paywall, topics

import ComposableArchitecture
import Foundation
import XCTest
@testable import PostKit

@MainActor
final class SettingsFeatureTests: XCTestCase {

    let pillars = [
        PillarSnapshot(id: UUID(0), name: "Travel", emoji: "✈️"),
        PillarSnapshot(id: UUID(1), name: "Food", emoji: "🍽️"),
    ]

    // MARK: - Data Loading

    func test_onAppear_loadsPillarsNotificationsAndProStatus() async {
        let store = TestStore(
            initialState: SettingsFeature.State()
        ) {
            SettingsFeature()
        } withDependencies: {
            $0.gallery.pillars = { [pillars] in pillars }
            $0.notification.requestAuthorization = { true }
            $0.subscription.isProUser = { false }
            $0.userDefaults.boolForKey = { _ in false }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.pillarsLoaded) {
            $0.pillars = self.pillars
            $0.isLoading = false
        }

        await store.receive(\.notificationStatusLoaded) {
            $0.notificationsEnabled = true
        }

        await store.receive(\.proStatusLoaded)
    }

    func test_onAppear_loadsCloudAIFromUserDefaults() async {
        let store = TestStore(
            initialState: SettingsFeature.State()
        ) {
            SettingsFeature()
        } withDependencies: {
            $0.gallery.pillars = { [pillars] in pillars }
            $0.notification.requestAuthorization = { false }
            $0.subscription.isProUser = { true }
            $0.userDefaults.boolForKey = { key in key == "cloudAIEnabled" }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.cloudAIEnabled = true
        }

        await store.receive(\.pillarsLoaded) {
            $0.pillars = self.pillars
            $0.isLoading = false
        }

        await store.receive(\.notificationStatusLoaded)

        await store.receive(\.proStatusLoaded) {
            $0.isProUser = true
        }
    }

    // MARK: - Pro Status & Paywall

    func test_upgradeToProTapped_presentsPaywall() async {
        let store = TestStore(
            initialState: SettingsFeature.State()
        ) {
            SettingsFeature()
        }

        await store.send(.upgradeToProTapped) {
            $0.paywall = PaywallFeature.State()
        }
    }

    func test_paywallDidPurchase_setsProAndDismisses() async {
        var state = SettingsFeature.State()
        state.paywall = PaywallFeature.State()

        let store = TestStore(initialState: state) {
            SettingsFeature()
        }

        await store.send(.paywall(.presented(.delegate(.didPurchase)))) {
            $0.paywall = nil
            $0.isProUser = true
        }
    }

    func test_paywallDismissed_closesPaywall() async {
        var state = SettingsFeature.State()
        state.paywall = PaywallFeature.State()

        let store = TestStore(initialState: state) {
            SettingsFeature()
        }

        await store.send(.paywall(.presented(.delegate(.dismissed)))) {
            $0.paywall = nil
        }
    }

    // MARK: - Cloud AI Toggle

    func test_cloudAIToggled_togglesAndPersists() async {
        var recorded: (Bool, String)?

        let store = TestStore(
            initialState: SettingsFeature.State()
        ) {
            SettingsFeature()
        } withDependencies: {
            $0.userDefaults.setBool = { value, key in recorded = (value, key) }
        }

        XCTAssertFalse(store.state.cloudAIEnabled)

        await store.send(.cloudAIToggled) {
            $0.cloudAIEnabled = true
        }

        XCTAssertEqual(recorded?.0, true)
        XCTAssertEqual(recorded?.1, "cloudAIEnabled")
    }

    func test_cloudAIToggled_offAndPersists() async {
        var recorded: (Bool, String)?

        var state = SettingsFeature.State()
        state.cloudAIEnabled = true

        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0.userDefaults.setBool = { value, key in recorded = (value, key) }
        }

        await store.send(.cloudAIToggled) {
            $0.cloudAIEnabled = false
        }

        XCTAssertEqual(recorded?.0, false)
    }

    // MARK: - Notifications

    func test_notificationToggled_whenOff_requestsAuthorization() async {
        var state = SettingsFeature.State()
        state.notificationsEnabled = false

        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0.notification.requestAuthorization = { true }
        }

        await store.send(.notificationToggled)

        await store.receive(\.notificationStatusLoaded) {
            $0.notificationsEnabled = true
        }
    }

    func test_notificationToggled_whenOn_doesNothing() async {
        var state = SettingsFeature.State()
        state.notificationsEnabled = true

        let store = TestStore(initialState: state) {
            SettingsFeature()
        }

        await store.send(.notificationToggled)
    }

    // MARK: - Topic Editor

    func test_topicTapped_opensEditor() async {
        var state = SettingsFeature.State()
        state.pillars = pillars

        let store = TestStore(initialState: state) {
            SettingsFeature()
        }

        await store.send(.topicTapped(pillars[0])) {
            $0.topicEditor = TopicEditorFeature.State(pillar: self.pillars[0])
        }
    }

    func test_topicEditorDidSave_refreshesPillars() async {
        var state = SettingsFeature.State()
        state.pillars = pillars
        state.topicEditor = TopicEditorFeature.State(pillar: pillars[0])

        let updatedPillars = [
            PillarSnapshot(id: UUID(0), name: "Travel Updated", emoji: "✈️"),
            PillarSnapshot(id: UUID(1), name: "Food", emoji: "🍽️"),
        ]

        let store = TestStore(initialState: state) {
            SettingsFeature()
        } withDependencies: {
            $0.gallery.invalidatePillars = {}
            $0.gallery.pillars = { updatedPillars }
            $0.notification.requestAuthorization = { false }
            $0.subscription.isProUser = { false }
            $0.userDefaults.boolForKey = { _ in false }
        }

        await store.send(.topicEditor(.presented(.delegate(.didSave))))

        await store.receive(\.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.pillarsLoaded) {
            $0.pillars = updatedPillars
            $0.isLoading = false
        }

        await store.receive(\.notificationStatusLoaded)
        await store.receive(\.proStatusLoaded)
    }
}
