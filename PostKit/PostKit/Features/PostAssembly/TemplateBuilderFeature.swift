import ComposableArchitecture
import Foundation

@Reducer
struct TemplateBuilderFeature {
    @ObservableState
    struct State: Equatable {
        var templateID: UUID?
        var name: String = ""
        var about: String = ""
        var slots: [TemplateSlotData] = []
        var availablePillars: [PillarSnapshot] = []
        var isLoading: Bool = false
        @Presents var slotEditor: SlotEditorFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        var canSave: Bool {
            !name.trimmingCharacters(in: .whitespaces).isEmpty && !slots.isEmpty
        }

        var snapshot: TemplateSnapshot {
            TemplateSnapshot(
                id: templateID ?? UUID(),
                name: name.trimmingCharacters(in: .whitespaces),
                about: about.trimmingCharacters(in: .whitespaces),
                slots: slots
            )
        }

        init(existing: TemplateSnapshot? = nil) {
            if let existing {
                self.templateID = existing.id
                self.name = existing.name
                self.about = existing.about
                self.slots = existing.slots
            }
        }
    }

    enum Action: BindableAction {
        case onAppear
        case pillarsLoaded([PillarSnapshot])
        case addSlotTapped
        case slotTapped(TemplateSlotData)
        case deleteSlot(IndexSet)
        case moveSlot(IndexSet, Int)
        case saveTapped
        case saved
        case slotEditor(PresentationAction<SlotEditorFeature.Action>)
        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)
        case delegate(Delegate)

        enum Alert: Equatable {}
        enum Delegate: Equatable {
            case didSave(TemplateSnapshot)
        }
    }

    @Dependency(\.persistence) var persistence
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.availablePillars.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    let pillars = try await persistence.fetchPillars()
                    await send(.pillarsLoaded(pillars))
                }

            case let .pillarsLoaded(pillars):
                state.availablePillars = pillars
                state.isLoading = false
                return .none

            case .addSlotTapped:
                let index = state.slots.count + 1
                let newSlot = TemplateSlotData(name: "Slot \(index)")
                state.slotEditor = SlotEditorFeature.State(
                    slot: newSlot,
                    availablePillars: state.availablePillars
                )
                return .none

            case let .slotTapped(slot):
                state.slotEditor = SlotEditorFeature.State(
                    slot: slot,
                    availablePillars: state.availablePillars
                )
                return .none

            case let .deleteSlot(indices):
                if state.slots.count == 1 && indices.contains(0) {
                    state.alert = AlertState {
                        TextState("Delete Last Slot?")
                    } actions: {
                        ButtonState(role: .cancel) { TextState("Cancel") }
                    } message: {
                        TextState("A template needs at least one slot.")
                    }
                    return .none
                }
                state.slots.remove(atOffsets: indices)
                return .none

            case let .moveSlot(source, destination):
                state.slots.move(fromOffsets: source, toOffset: destination)
                return .none

            case .saveTapped:
                guard state.canSave else { return .none }
                let snapshot = state.snapshot
                return .run { send in
                    try await persistence.saveTemplate(snapshot)
                    await send(.saved)
                }

            case .saved:
                let snapshot = state.snapshot
                return .run { send in
                    await send(.delegate(.didSave(snapshot)))
                    await dismiss()
                }

            case .slotEditor(.presented(.delegate(.didSave(let slot)))):
                if let index = state.slots.firstIndex(where: { $0.id == slot.id }) {
                    state.slots[index] = slot
                } else {
                    state.slots.append(slot)
                }
                return .none

            case .slotEditor, .alert, .binding, .delegate:
                return .none
            }
        }
        .ifLet(\.$slotEditor, action: \.slotEditor) {
            SlotEditorFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

@Reducer
struct SlotEditorFeature {
    @ObservableState
    struct State: Equatable {
        var slot: TemplateSlotData
        var availablePillars: [PillarSnapshot] = []
        var tagInput: String = ""
    }

    enum Action: BindableAction {
        case cadragePicked(Cadrage)
        case pillarToggled(String)
        case addTagTapped
        case removeTag(String)
        case saveTapped
        case binding(BindingAction<State>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case didSave(TemplateSlotData)
        }
    }

    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case let .cadragePicked(cadrage):
                state.slot.cadrage = cadrage
                return .none

            case let .pillarToggled(name):
                if let index = state.slot.pillarNames.firstIndex(of: name) {
                    state.slot.pillarNames.remove(at: index)
                } else {
                    state.slot.pillarNames.append(name)
                }
                return .none

            case .addTagTapped:
                let tag = state.tagInput.trimmingCharacters(in: .whitespaces)
                guard !tag.isEmpty, !state.slot.tags.contains(tag) else { return .none }
                state.slot.tags.append(tag)
                state.tagInput = ""
                return .none

            case let .removeTag(tag):
                state.slot.tags.removeAll { $0 == tag }
                return .none

            case .saveTapped:
                return .run { [slot = state.slot] send in
                    await send(.delegate(.didSave(slot)))
                    await dismiss()
                }

            case .binding, .delegate:
                return .none
            }
        }
    }
}
