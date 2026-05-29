import ComposableArchitecture
import Foundation
import UIKit
import XCTest
@testable import PostKit

@MainActor
final class PostAssemblyFeatureTests: XCTestCase {

    let pillars = [
        PillarSnapshot(id: UUID(0), name: "Travel", emoji: "✈️"),
        PillarSnapshot(id: UUID(1), name: "Food", emoji: "🍽️"),
    ]

    func test_onAppear_loadsPillars() async {
        let store = TestStore(initialState: PostAssemblyEntryFeature.State()) {
            PostAssemblyEntryFeature()
        } withDependencies: {
            $0.gallery.pillars = { [pillars] in pillars }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.pillarsLoaded) {
            $0.pillars = self.pillars
            $0.isLoading = false
        }
    }

    func test_pillarSelected_loadsPhotosAndAdvancesStep() async {
        let photos = [
            ClassifiedPhotoSnapshot(
                assetLocalIdentifier: "a1", pillarID: UUID(0), pillarIDs: [UUID(0)], status: .classified
            ),
        ]

        var state = PostAssemblyEntryFeature.State()
        state.pillars = pillars

        let store = TestStore(initialState: state) {
            PostAssemblyEntryFeature()
        } withDependencies: {
            $0.gallery.photos = { _ in photos }
        }

        await store.send(.pillarSelected(pillars[0])) {
            $0.selectedPillar = self.pillars[0]
            $0.step = .pickPhotos
            $0.isLoading = true
        }

        await store.receive(\.photosLoaded) {
            $0.photos = photos
            $0.isLoading = false
        }
    }

    func test_photoToggle_selectsAndDeselects() async {
        var state = PostAssemblyEntryFeature.State()
        state.pillars = pillars
        state.selectedPillar = pillars[0]
        state.step = .pickPhotos
        state.photos = [
            ClassifiedPhotoSnapshot(assetLocalIdentifier: "a1", status: .classified),
        ]

        let store = TestStore(initialState: state) {
            PostAssemblyEntryFeature()
        }

        await store.send(.photoToggled("a1")) {
            $0.selectedPhotoIDs = ["a1"]
        }

        await store.send(.photoToggled("a1")) {
            $0.selectedPhotoIDs = []
        }
    }

    func test_continueToCaption_generatesCaption() async {
        var state = PostAssemblyEntryFeature.State()
        state.pillars = pillars
        state.selectedPillar = pillars[0]
        state.selectedPhotoIDs = ["a1"]
        state.step = .pickPhotos

        let store = TestStore(initialState: state) {
            PostAssemblyEntryFeature()
        } withDependencies: {
            $0.photoLibrary.image = { _, _ in UIImage() }
            $0.postGenerator.generateCaption = { _, _, _ in "Great travel shot!" }
            $0.postGenerator.generateHashtags = { _, _, _ in ["#travel", "#wanderlust"] }
        }

        await store.send(.continueToCaption) {
            $0.step = .editCaption
            $0.isGenerating = true
        }

        await store.receive(\.captionGenerated) {
            $0.caption = "Great travel shot!"
            $0.hashtags = ["#travel", "#wanderlust"]
            $0.isGenerating = false
        }
    }

    func test_saveTapped_persistsPost() async {
        let savedPosts = LockIsolated<[GeneratedPostSnapshot]>([])

        var state = PostAssemblyEntryFeature.State()
        state.selectedPillar = pillars[0]
        state.selectedPhotoIDs = ["a1"]
        state.caption = "Test caption"
        state.hashtags = ["#test"]
        state.platform = .instagram
        state.step = .editCaption

        let store = TestStore(initialState: state) {
            PostAssemblyEntryFeature()
        } withDependencies: {
            $0.persistence.savePost = { snapshot in
                savedPosts.withValue { $0.append(snapshot) }
            }
        }

        await store.send(.saveTapped)

        await store.receive(\.saved) {
            $0.alert = AlertState {
                TextState("Saved")
            } actions: {
                ButtonState(role: .cancel) { TextState("OK") }
            } message: {
                TextState("Draft saved successfully.")
            }
        }

        XCTAssertEqual(savedPosts.value.count, 1)
        XCTAssertEqual(savedPosts.value.first?.caption, "Test caption")
        XCTAssertEqual(savedPosts.value.first?.pillarID, UUID(0))
    }

    func test_startOver_resetsState() async {
        var state = PostAssemblyEntryFeature.State()
        state.selectedPillar = pillars[0]
        state.selectedPhotoIDs = ["a1"]
        state.caption = "Some caption"
        state.hashtags = ["#tag"]
        state.step = .editCaption

        let store = TestStore(initialState: state) {
            PostAssemblyEntryFeature()
        }

        await store.send(.startOverTapped) {
            $0.selectedPillar = nil
            $0.photos = []
            $0.selectedPhotoIDs = []
            $0.caption = ""
            $0.hashtags = []
            $0.step = .pickPillar
        }
    }
}
