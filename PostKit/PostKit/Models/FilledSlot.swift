import ComposableArchitecture
import Foundation

struct FilledSlot: Equatable, Identifiable, Sendable {
    let slotData: TemplateSlotData
    var photoIDs: Set<String>

    var id: UUID { slotData.id }
    var isEmpty: Bool { photoIDs.isEmpty }
}

@Reducer
struct PostEditorFeature {
    @ObservableState
    struct State: Equatable {
        let template: TemplateSnapshot
        var filledSlots: [FilledSlot] = []
        @Presents var slotFiller: SlotFillerFeature.State?

        var allSlotsFilled: Bool {
            filledSlots.allSatisfy { !$0.isEmpty }
        }

        var totalPhotoCount: Int {
            filledSlots.reduce(0) { $0 + $1.photoIDs.count }
        }

        init(template: TemplateSnapshot) {
            self.template = template
            self.filledSlots = template.slots.map { FilledSlot(slotData: $0, photoIDs: []) }
        }
    }

    enum Action {
        case slotTapped(UUID)
        case clearSlotTapped(UUID)
        case slotFiller(PresentationAction<SlotFillerFeature.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case postReady(templateID: UUID, slotPhotos: [UUID: Set<String>])
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .slotTapped(slotID):
                guard let slot = state.filledSlots.first(where: { $0.id == slotID }) else {
                    return .none
                }
                state.slotFiller = SlotFillerFeature.State(
                    slotID: slotID,
                    slotName: slot.slotData.name,
                    constrainedPillarNames: slot.slotData.pillarNames,
                    preselectedPhotoIDs: slot.photoIDs
                )
                return .none

            case let .clearSlotTapped(slotID):
                if let index = state.filledSlots.firstIndex(where: { $0.id == slotID }) {
                    state.filledSlots[index].photoIDs = []
                }
                return .none

            case let .slotFiller(.presented(.delegate(.didConfirm(slotID, photoIDs)))):
                if let index = state.filledSlots.firstIndex(where: { $0.id == slotID }) {
                    state.filledSlots[index].photoIDs = photoIDs
                }
                return .none

            case .slotFiller, .delegate:
                return .none
            }
        }
        .ifLet(\.$slotFiller, action: \.slotFiller) {
            SlotFillerFeature()
        }
    }
}
