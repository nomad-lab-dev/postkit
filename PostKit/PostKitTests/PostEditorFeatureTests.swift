import ComposableArchitecture
import Foundation
import XCTest
@testable import PostKit

@MainActor
final class PostEditorFeatureTests: XCTestCase {

    let template = TemplateSnapshot(
        id: UUID(0),
        name: "Carousel",
        slots: [
            TemplateSlotData(id: UUID(1), name: "Hero", cadrage: .wide, pillarNames: ["Travel"]),
            TemplateSlotData(id: UUID(2), name: "Detail", cadrage: .detail),
        ]
    )

    func test_init_createsEmptyFilledSlots() {
        let state = PostEditorFeature.State(template: template)
        XCTAssertEqual(state.filledSlots.count, 2)
        XCTAssertTrue(state.filledSlots[0].isEmpty)
        XCTAssertTrue(state.filledSlots[1].isEmpty)
        XCTAssertEqual(state.filledSlots[0].slotData.name, "Hero")
        XCTAssertFalse(state.allSlotsFilled)
    }

    func test_slotTapped_opensFillerWithConstraints() async {
        let store = TestStore(
            initialState: PostEditorFeature.State(template: template)
        ) {
            PostEditorFeature()
        }

        await store.send(.slotTapped(UUID(1))) {
            $0.slotFiller = SlotFillerFeature.State(
                slotID: UUID(1),
                slotName: "Hero",
                constrainedPillarNames: ["Travel"]
            )
        }
    }

    func test_slotTapped_unconstrainedSlot_opensFillerWithNoConstraints() async {
        let store = TestStore(
            initialState: PostEditorFeature.State(template: template)
        ) {
            PostEditorFeature()
        }

        await store.send(.slotTapped(UUID(2))) {
            $0.slotFiller = SlotFillerFeature.State(
                slotID: UUID(2),
                slotName: "Detail",
                constrainedPillarNames: []
            )
        }
    }

    func test_fillerConfirm_fillsSlot() async {
        var state = PostEditorFeature.State(template: template)
        state.slotFiller = SlotFillerFeature.State(
            slotID: UUID(1),
            slotName: "Hero",
            constrainedPillarNames: ["Travel"]
        )

        let store = TestStore(initialState: state) {
            PostEditorFeature()
        }

        await store.send(.slotFiller(.presented(.delegate(.didConfirm(
            slotID: UUID(1),
            photoIDs: ["a1", "a2"]
        ))))) {
            $0.filledSlots[0].photoIDs = ["a1", "a2"]
        }

        await store.send(.slotFiller(.dismiss)) {
            $0.slotFiller = nil
        }

        XCTAssertFalse(store.state.filledSlots[0].isEmpty)
        XCTAssertEqual(store.state.totalPhotoCount, 2)
    }

    func test_clearSlot_removesPhotos() async {
        var state = PostEditorFeature.State(template: template)
        state.filledSlots[0].photoIDs = ["a1", "a2"]

        let store = TestStore(initialState: state) {
            PostEditorFeature()
        }

        await store.send(.clearSlotTapped(UUID(1))) {
            $0.filledSlots[0].photoIDs = []
        }
    }

    func test_allSlotsFilled_whenAllHavePhotos() {
        var state = PostEditorFeature.State(template: template)
        XCTAssertFalse(state.allSlotsFilled)

        state.filledSlots[0].photoIDs = ["a1"]
        XCTAssertFalse(state.allSlotsFilled)

        state.filledSlots[1].photoIDs = ["a2"]
        XCTAssertTrue(state.allSlotsFilled)
    }
}

@MainActor
final class SlotFillerFeatureTests: XCTestCase {

    let pillars = [
        PillarSnapshot(id: UUID(0), name: "Travel", emoji: "✈️"),
        PillarSnapshot(id: UUID(1), name: "Food", emoji: "🍽️"),
    ]

    let photos = [
        ClassifiedPhotoSnapshot(
            assetLocalIdentifier: "a1", pillarID: UUID(0), status: .classified
        ),
        ClassifiedPhotoSnapshot(
            assetLocalIdentifier: "a2", pillarID: UUID(1), status: .classified
        ),
        ClassifiedPhotoSnapshot(
            assetLocalIdentifier: "a3", pillarID: UUID(0), status: .classified
        ),
    ]

    func test_onAppear_unconstrained_loadsAllPhotos() async {
        let store = TestStore(
            initialState: SlotFillerFeature.State(
                slotID: UUID(10), slotName: "Hero"
            )
        ) {
            SlotFillerFeature()
        } withDependencies: {
            $0.persistence.fetchPillars = { [pillars] in pillars }
            $0.persistence.fetchPhotos = { [photos] _ in photos }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.dataLoaded) {
            $0.pillars = self.pillars
            $0.photos = self.photos
            $0.isLoading = false
        }
    }

    func test_onAppear_constrained_filtersPhotosAndAutoSelectsFilter() async {
        let store = TestStore(
            initialState: SlotFillerFeature.State(
                slotID: UUID(10),
                slotName: "Hero",
                constrainedPillarNames: ["Travel"]
            )
        ) {
            SlotFillerFeature()
        } withDependencies: {
            $0.persistence.fetchPillars = { [pillars] in pillars }
            $0.persistence.fetchPhotos = { [photos] _ in photos }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        let travelPhotos = [photos[0], photos[2]]
        await store.receive(\.dataLoaded) {
            $0.pillars = self.pillars
            $0.photos = travelPhotos
            $0.isLoading = false
            $0.selectedFilter = .pillar(UUID(0))
        }
    }

    func test_photoToggle_selectsAndDeselects() async {
        var state = SlotFillerFeature.State(slotID: UUID(10), slotName: "Hero")
        state.photos = photos
        state.pillars = pillars

        let store = TestStore(initialState: state) {
            SlotFillerFeature()
        }

        await store.send(.photoToggled("a1")) {
            $0.selectedPhotoIDs = ["a1"]
        }

        await store.send(.photoToggled("a3")) {
            $0.selectedPhotoIDs = ["a1", "a3"]
        }

        await store.send(.photoToggled("a1")) {
            $0.selectedPhotoIDs = ["a3"]
        }
    }

    func test_filterSelected_changesFilter() async {
        var state = SlotFillerFeature.State(slotID: UUID(10), slotName: "Hero")
        state.photos = photos
        state.pillars = pillars

        let store = TestStore(initialState: state) {
            SlotFillerFeature()
        }

        await store.send(.filterSelected(.pillar(UUID(0)))) {
            $0.selectedFilter = .pillar(UUID(0))
        }

        XCTAssertEqual(store.state.filteredPhotos.count, 2)
    }

    func test_preselectedPhotos_preserved() async {
        let state = SlotFillerFeature.State(
            slotID: UUID(10),
            slotName: "Hero",
            preselectedPhotoIDs: ["a1", "a3"]
        )

        XCTAssertEqual(state.selectedPhotoIDs, ["a1", "a3"])
    }
}
