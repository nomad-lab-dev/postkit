import ComposableArchitecture
import Foundation

@Reducer
struct SlotMachineFeature {
    @ObservableState
    struct State: Equatable {
        let template: TemplateSnapshot
        var pillars: [PillarSnapshot] = []
        var filledSlots: [FilledSlot] = []
        var phase: Phase = .loading
        var shuffleCount: Int = 0

        enum Phase: Equatable {
            case loading, shuffling, revealed, noPhotos
        }

        var allSlotsFilled: Bool {
            filledSlots.allSatisfy { !$0.isEmpty }
        }

        init(template: TemplateSnapshot, pillars: [PillarSnapshot] = []) {
            self.template = template
            self.pillars = pillars
            self.filledSlots = template.slots.map { FilledSlot(slotData: $0, photoIDs: []) }
        }
    }

    enum Action {
        case onAppear
        case photosLoaded([UUID: [String]])
        case shuffleCompleted
        case remixTapped
        case reshuffleSlotTapped(UUID)
        case slotReshuffled(slotID: UUID, photoID: String)
        case editTapped
        case keepTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case openEditor(TemplateSnapshot, [FilledSlot])
            case dismissed
        }
    }

    @Dependency(\.persistence) var persistence
    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.phase = .loading
                let slots = state.template.slots
                return .run { send in
                    var pool: [UUID: [String]] = [:]
                    for slot in slots {
                        let allPhotos: [ClassifiedPhotoSnapshot]
                        if slot.pillarIDs.isEmpty {
                            allPhotos = try await persistence.fetchPhotos(.classified)
                        } else {
                            var photos: [ClassifiedPhotoSnapshot] = []
                            for pillarID in slot.pillarIDs {
                                let pillarPhotos = try await persistence.fetchPhotosForPillar(pillarID)
                                photos.append(contentsOf: pillarPhotos)
                            }
                            allPhotos = photos
                        }
                        pool[slot.id] = allPhotos.map(\.assetLocalIdentifier)
                    }
                    await send(.photosLoaded(pool))
                }

            case let .photosLoaded(pool):
                var hasAny = false
                for i in state.filledSlots.indices {
                    let slotID = state.filledSlots[i].id
                    if let candidates = pool[slotID], let picked = candidates.randomElement() {
                        state.filledSlots[i].photoIDs = [picked]
                        hasAny = true
                    }
                }
                if !hasAny {
                    state.phase = .noPhotos
                    return .none
                }
                state.phase = .shuffling
                state.shuffleCount += 1
                return .run { send in
                    try await clock.sleep(for: .seconds(1.5))
                    await send(.shuffleCompleted)
                }

            case .shuffleCompleted:
                state.phase = .revealed
                return .none

            case .remixTapped:
                state.phase = .loading
                let slots = state.template.slots
                return .run { send in
                    var pool: [UUID: [String]] = [:]
                    for slot in slots {
                        let allPhotos: [ClassifiedPhotoSnapshot]
                        if slot.pillarIDs.isEmpty {
                            allPhotos = try await persistence.fetchPhotos(.classified)
                        } else {
                            var photos: [ClassifiedPhotoSnapshot] = []
                            for pillarID in slot.pillarIDs {
                                let pillarPhotos = try await persistence.fetchPhotosForPillar(pillarID)
                                photos.append(contentsOf: pillarPhotos)
                            }
                            allPhotos = photos
                        }
                        pool[slot.id] = allPhotos.map(\.assetLocalIdentifier)
                    }
                    await send(.photosLoaded(pool))
                }

            case let .reshuffleSlotTapped(slotID):
                guard let slot = state.filledSlots.first(where: { $0.id == slotID }) else {
                    return .none
                }
                let currentIDs = slot.photoIDs
                let otherUsedIDs = Set(state.filledSlots.filter { $0.id != slotID }.flatMap { Array($0.photoIDs) })
                let pillarIDs = slot.slotData.pillarIDs
                return .run { send in
                    let allPhotos: [ClassifiedPhotoSnapshot]
                    if pillarIDs.isEmpty {
                        allPhotos = try await persistence.fetchPhotos(.classified)
                    } else {
                        var photos: [ClassifiedPhotoSnapshot] = []
                        for pillarID in pillarIDs {
                            photos.append(contentsOf: try await persistence.fetchPhotosForPillar(pillarID))
                        }
                        allPhotos = photos
                    }
                    let available = allPhotos.filter {
                        !otherUsedIDs.contains($0.assetLocalIdentifier) &&
                        !currentIDs.contains($0.assetLocalIdentifier)
                    }
                    if let picked = available.randomElement() {
                        await send(.slotReshuffled(slotID: slotID, photoID: picked.assetLocalIdentifier))
                    } else if let fallback = allPhotos.filter({ !otherUsedIDs.contains($0.assetLocalIdentifier) }).randomElement() {
                        await send(.slotReshuffled(slotID: slotID, photoID: fallback.assetLocalIdentifier))
                    }
                }

            case let .slotReshuffled(slotID, photoID):
                if let index = state.filledSlots.firstIndex(where: { $0.id == slotID }) {
                    state.filledSlots[index].photoIDs = [photoID]
                }
                return .none

            case .editTapped:
                return .send(.delegate(.openEditor(state.template, state.filledSlots)))

            case .keepTapped:
                return .send(.delegate(.openEditor(state.template, state.filledSlots)))

            case .delegate:
                return .none
            }
        }
    }
}
