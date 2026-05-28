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
                TemplateSlotData(name: "Hero", cadrages: [.wide]),
                TemplateSlotData(name: "Detail", cadrages: [.detail]),
            ]
        ),
        TemplateSnapshot(id: UUID(1), name: "Story", slots: [TemplateSlotData()]),
    ]

    func test_onAppear_loadsTemplates() async {
        let store = TestStore(initialState: TemplateListFeature.State()) {
            TemplateListFeature()
        } withDependencies: {
            $0.gallery.templates = { [templates] in templates }
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

    func test_templateTapped_opensEditor() async {
        var state = TemplateListFeature.State()
        state.templates = templates

        let store = TestStore(initialState: state) {
            TemplateListFeature()
        }

        await store.send(.templateTapped(templates[0])) {
            $0.editor = PostEditorFeature.State(template: self.templates[0])
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
            $0.gallery.invalidateTemplates = {}
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

    func test_onAppear_loadsPillarsAndLocations() async {
        let store = TestStore(initialState: TemplateBuilderFeature.State()) {
            TemplateBuilderFeature()
        } withDependencies: {
            $0.gallery.pillars = { [pillars] in pillars }
            $0.gallery.photos = { _ in
                [
                    ClassifiedPhotoSnapshot(assetLocalIdentifier: "a1", pillarID: UUID(0), location: "Paris, France", status: .classified),
                    ClassifiedPhotoSnapshot(assetLocalIdentifier: "a2", pillarID: UUID(1), location: "Tokyo, Japan", status: .classified),
                ]
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.dataLoaded) {
            $0.availablePillars = self.pillars
            $0.availableLocations = ["Paris, France", "Tokyo, Japan"]
            $0.isLoading = false
        }
    }

    func test_addSlot_opensEditorSheet() async {
        var state = TemplateBuilderFeature.State()
        state.availablePillars = pillars

        let store = TestStore(initialState: state) {
            TemplateBuilderFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }

        await store.send(.addSlotTapped) {
            $0.slotEditor = SlotEditorFeature.State(
                slot: TemplateSlotData(id: UUID(0), name: "Slot 1"),
                availablePillars: self.pillars,
                isNew: true
            )
        }
    }

    func test_locationSelected_addsToSelectedLocations() async {
        var state = TemplateBuilderFeature.State()
        state.availableLocations = ["Paris, France", "Tokyo, Japan", "Bangkok, Thailand"]

        let store = TestStore(initialState: state) {
            TemplateBuilderFeature()
        }

        await store.send(.locationSelected("Paris, France")) {
            $0.selectedLocations = ["Paris, France"]
        }

        await store.send(.locationSelected("Tokyo, Japan")) {
            $0.selectedLocations = ["Paris, France", "Tokyo, Japan"]
        }
    }

    func test_locationRemoved_removesFromSelectedLocations() async {
        var state = TemplateBuilderFeature.State()
        state.selectedLocations = ["Paris, France", "Tokyo, Japan"]

        let store = TestStore(initialState: state) {
            TemplateBuilderFeature()
        }

        await store.send(.locationRemoved("Paris, France")) {
            $0.selectedLocations = ["Tokyo, Japan"]
        }
    }

    func test_suggestedLocations_filtersCorrectly() {
        var state = TemplateBuilderFeature.State()
        state.availableLocations = ["Paris, France", "Bangkok, Thailand", "Bang Na, Thailand"]
        state.selectedLocations = ["Bangkok, Thailand"]

        state.locationQuery = "ban"
        XCTAssertEqual(state.suggestedLocations, ["Bang Na, Thailand"])

        state.locationQuery = ""
        XCTAssertEqual(state.suggestedLocations, [])
    }

    func test_slotEditorSave_addsSlot() async {
        var state = TemplateBuilderFeature.State()
        state.availablePillars = pillars
        let slotID = UUID(42)
        let newSlot = TemplateSlotData(id: slotID, name: "Hero", cadrages: [.wide], pillarIDs: [UUID(0)])
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
        let originalSlot = TemplateSlotData(id: slotID, name: "Slot 1")
        var state = TemplateBuilderFeature.State()
        state.slots = [originalSlot]
        state.availablePillars = pillars
        let updatedSlot = TemplateSlotData(id: slotID, name: "Hero Shot", cadrages: [.wide], pillarIDs: [UUID(0)])
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

    func test_cadrageToggled_updatesSlot() async {
        let store = TestStore(
            initialState: SlotEditorFeature.State(slot: TemplateSlotData())
        ) {
            SlotEditorFeature()
        }

        await store.send(.cadrageToggled(.portrait)) {
            $0.slot.cadrages = [.portrait]
        }

        await store.send(.cadrageToggled(.wide)) {
            $0.slot.cadrages = [.portrait, .wide]
        }

        await store.send(.cadrageToggled(.portrait)) {
            $0.slot.cadrages = [.wide]
        }
    }

    func test_pillarToggle_addsAndRemoves() async {
        let store = TestStore(
            initialState: SlotEditorFeature.State(slot: TemplateSlotData())
        ) {
            SlotEditorFeature()
        }

        await store.send(.pillarToggled(UUID(0))) {
            $0.slot.pillarIDs = [UUID(0)]
        }

        await store.send(.pillarToggled(UUID(1))) {
            $0.slot.pillarIDs = [UUID(0), UUID(1)]
        }

        await store.send(.pillarToggled(UUID(0))) {
            $0.slot.pillarIDs = [UUID(1)]
        }
    }


}
