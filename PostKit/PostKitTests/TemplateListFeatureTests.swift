import ComposableArchitecture
import Foundation
import XCTest
@testable import PostKit

@MainActor
final class TemplateListFeatureTests: XCTestCase {

    let templates = [
        TemplateSnapshot(
            id: UUID(0),
            name: "Carousel 4",
            slots: [
                TemplateSlotData(name: "Hero", cadrage: .wide),
                TemplateSlotData(name: "Detail", cadrage: .detail),
            ]
        ),
        TemplateSnapshot(id: UUID(1), name: "Story", slots: [TemplateSlotData()]),
    ]

    func test_onAppear_loadsTemplates() async {
        let store = TestStore(initialState: TemplateListFeature.State()) {
            TemplateListFeature()
        } withDependencies: {
            $0.persistence.fetchTemplates = { [templates] in templates }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.templatesLoaded) {
            $0.templates = self.templates
            $0.isLoading = false
        }
    }

    func test_newTemplateTapped_opensBuilder() async {
        let store = TestStore(initialState: TemplateListFeature.State()) {
            TemplateListFeature()
        }

        await store.send(.newTemplateTapped) {
            $0.builder = TemplateBuilderFeature.State()
        }
    }

    func test_templateTapped_opensBuilderWithExisting() async {
        var state = TemplateListFeature.State()
        state.templates = templates

        let store = TestStore(initialState: state) {
            TemplateListFeature()
        }

        await store.send(.templateTapped(templates[0])) {
            $0.builder = TemplateBuilderFeature.State(existing: self.templates[0])
        }
    }

    func test_deleteTemplate_removesAndPersists() async {
        var state = TemplateListFeature.State()
        state.templates = templates

        let deletedIDs = LockIsolated<[UUID]>([])

        let store = TestStore(initialState: state) {
            TemplateListFeature()
        } withDependencies: {
            $0.persistence.deleteTemplate = { id in
                deletedIDs.withValue { $0.append(id) }
            }
        }

        await store.send(.deleteTemplate(IndexSet(integer: 0))) {
            $0.templates = [self.templates[1]]
        }

        await store.receive(\.deleted)

        XCTAssertEqual(deletedIDs.value, [UUID(0)])
    }
}

@MainActor
final class TemplateBuilderFeatureTests: XCTestCase {

    let pillars = [
        PillarSnapshot(id: UUID(0), name: "Travel", emoji: "✈️"),
        PillarSnapshot(id: UUID(1), name: "Food", emoji: "🍽️"),
    ]

    func test_onAppear_loadsPillars() async {
        let store = TestStore(initialState: TemplateBuilderFeature.State()) {
            TemplateBuilderFeature()
        } withDependencies: {
            $0.persistence.fetchPillars = { [pillars] in pillars }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.pillarsLoaded) {
            $0.availablePillars = self.pillars
            $0.isLoading = false
        }
    }

    func test_addSlot_opensEditorWithNewSlot() async {
        var state = TemplateBuilderFeature.State()
        state.availablePillars = pillars

        let store = TestStore(initialState: state) {
            TemplateBuilderFeature()
        }

        await store.send(.addSlotTapped) {
            $0.slotEditor = SlotEditorFeature.State(
                slot: TemplateSlotData(name: "Slot 1"),
                availablePillars: self.pillars
            )
        }
    }

    func test_slotEditorSave_addsSlot() async {
        var state = TemplateBuilderFeature.State()
        state.availablePillars = pillars
        let slotID = UUID(42)
        let newSlot = TemplateSlotData(id: slotID, name: "Hero", cadrage: .wide, pillarNames: ["Travel"])
        state.slotEditor = SlotEditorFeature.State(
            slot: newSlot,
            availablePillars: pillars
        )

        let store = TestStore(initialState: state) {
            TemplateBuilderFeature()
        }

        await store.send(.slotEditor(.presented(.delegate(.didSave(newSlot))))) {
            $0.slots = [newSlot]
        }

        await store.send(.slotEditor(.dismiss)) {
            $0.slotEditor = nil
        }
    }

    func test_slotEditorSave_updatesExistingSlot() async {
        let slotID = UUID(42)
        let originalSlot = TemplateSlotData(id: slotID, name: "Slot 1", cadrage: .any)
        var state = TemplateBuilderFeature.State()
        state.slots = [originalSlot]
        state.availablePillars = pillars
        let updatedSlot = TemplateSlotData(id: slotID, name: "Hero Shot", cadrage: .wide, pillarNames: ["Travel"])
        state.slotEditor = SlotEditorFeature.State(
            slot: updatedSlot,
            availablePillars: pillars
        )

        let store = TestStore(initialState: state) {
            TemplateBuilderFeature()
        }

        await store.send(.slotEditor(.presented(.delegate(.didSave(updatedSlot))))) {
            $0.slots = [updatedSlot]
        }

        await store.send(.slotEditor(.dismiss)) {
            $0.slotEditor = nil
        }
    }

    func test_deleteLastSlot_showsAlert() async {
        var state = TemplateBuilderFeature.State()
        state.slots = [TemplateSlotData(name: "Only")]

        let store = TestStore(initialState: state) {
            TemplateBuilderFeature()
        }

        await store.send(.deleteSlot(IndexSet(integer: 0))) {
            $0.alert = AlertState {
                TextState("Delete Last Slot?")
            } actions: {
                ButtonState(role: .cancel) { TextState("Cancel") }
            } message: {
                TextState("A template needs at least one slot.")
            }
        }

        XCTAssertEqual(store.state.slots.count, 1)
    }

    func test_moveSlot_reorders() async {
        var state = TemplateBuilderFeature.State()
        let slot1 = TemplateSlotData(id: UUID(1), name: "First")
        let slot2 = TemplateSlotData(id: UUID(2), name: "Second")
        state.slots = [slot1, slot2]

        let store = TestStore(initialState: state) {
            TemplateBuilderFeature()
        }

        await store.send(.moveSlot(IndexSet(integer: 1), 0)) {
            $0.slots = [slot2, slot1]
        }
    }

    func test_canSave_requiresNameAndSlots() async {
        var state = TemplateBuilderFeature.State()
        XCTAssertFalse(state.canSave)

        state.name = "My Template"
        XCTAssertFalse(state.canSave)

        state.slots = [TemplateSlotData(name: "Slot 1")]
        XCTAssertTrue(state.canSave)

        state.name = "   "
        XCTAssertFalse(state.canSave)
    }
}

@MainActor
final class SlotEditorFeatureTests: XCTestCase {

    func test_cadragePicked_updatesSlot() async {
        let store = TestStore(
            initialState: SlotEditorFeature.State(slot: TemplateSlotData())
        ) {
            SlotEditorFeature()
        }

        await store.send(.cadragePicked(.portrait)) {
            $0.slot.cadrage = .portrait
        }
    }

    func test_pillarToggle_addsAndRemoves() async {
        let store = TestStore(
            initialState: SlotEditorFeature.State(slot: TemplateSlotData())
        ) {
            SlotEditorFeature()
        }

        await store.send(.pillarToggled("Travel")) {
            $0.slot.pillarNames = ["Travel"]
        }

        await store.send(.pillarToggled("Food")) {
            $0.slot.pillarNames = ["Travel", "Food"]
        }

        await store.send(.pillarToggled("Travel")) {
            $0.slot.pillarNames = ["Food"]
        }
    }

    func test_addTag_appendsAndClearsInput() async {
        var state = SlotEditorFeature.State(slot: TemplateSlotData())
        state.tagInput = "urban"

        let store = TestStore(initialState: state) {
            SlotEditorFeature()
        }

        await store.send(.addTagTapped) {
            $0.slot.tags = ["urban"]
            $0.tagInput = ""
        }
    }

    func test_addTag_ignoresDuplicates() async {
        var state = SlotEditorFeature.State(slot: TemplateSlotData(tags: ["urban"]))
        state.tagInput = "urban"

        let store = TestStore(initialState: state) {
            SlotEditorFeature()
        }

        await store.send(.addTagTapped)
    }

    func test_removeTag_deletesTag() async {
        let store = TestStore(
            initialState: SlotEditorFeature.State(
                slot: TemplateSlotData(tags: ["urban", "night"])
            )
        ) {
            SlotEditorFeature()
        }

        await store.send(.removeTag("urban")) {
            $0.slot.tags = ["night"]
        }
    }
}
