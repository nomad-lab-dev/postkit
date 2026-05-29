// MARK: - PostKit
// SlotMachineFeature.swift — Slot machine reducer: auto-fills template slots with random matching photos

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
        var reshufflingSlotID: UUID?

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
        case slotReshuffled(slotID: UUID, photos: Set<String>, pillarID: UUID?, locationLabel: String?)
        case editTapped
        case keepTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case openEditor(TemplateSnapshot, [FilledSlot])
            case dismissed
        }
    }

    @Dependency(\.gallery) var gallery
    @Dependency(\.persistence) var persistence
    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.phase = .loading
                let slots = state.template.slots
                return .run { [gallery] send in
                    let classifiedPhotos = (try? await gallery.photos(.classified)) ?? []
                    var pool: [UUID: [String]] = [:]
                    for slot in slots {
                        let allPhotos: [ClassifiedPhotoSnapshot]
                        if slot.pillarIDs.isEmpty {
                            allPhotos = classifiedPhotos
                        } else {
                            let pillarSet = Set(slot.pillarIDs)
                            allPhotos = classifiedPhotos.filter { photo in
                                photo.pillarIDs.contains(where: { pillarSet.contains($0) })
                            }
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
                return .run { [gallery] send in
                    let classifiedPhotos = (try? await gallery.photos(.classified)) ?? []
                    var pool: [UUID: [String]] = [:]
                    for slot in slots {
                        let allPhotos: [ClassifiedPhotoSnapshot]
                        if slot.pillarIDs.isEmpty {
                            allPhotos = classifiedPhotos
                        } else {
                            let pillarSet = Set(slot.pillarIDs)
                            allPhotos = classifiedPhotos.filter { photo in
                                photo.pillarIDs.contains(where: { pillarSet.contains($0) })
                            }
                        }
                        pool[slot.id] = allPhotos.map(\.assetLocalIdentifier)
                    }
                    await send(.photosLoaded(pool))
                }

            case let .reshuffleSlotTapped(slotID):
                guard let slot = state.filledSlots.first(where: { $0.id == slotID }) else {
                    return .none
                }
                state.reshufflingSlotID = slotID
                let currentPhotoIDs = slot.photoIDs
                let currentPillarID = slot.activePillarID
                let currentLocationLabel = slot.locationLabel
                let slotData = slot.slotData
                let excludeIDs = slot.photoIDs.union(
                    Set(state.filledSlots.filter { $0.id != slotID }.flatMap { Array($0.photoIDs) })
                )
                return .run { [persistence] send in
                    let options = SlotFiller.Options(
                        excludeIDs: excludeIDs,
                        fallbackToAny: true
                    )
                    let filled = try await SlotFiller.fillOne(
                        slot: slotData, using: persistence, options: options
                    )
                    await send(.slotReshuffled(
                        slotID: slotID,
                        photos: filled.isEmpty ? currentPhotoIDs : filled.photoIDs,
                        pillarID: filled.isEmpty ? currentPillarID : filled.activePillarID,
                        locationLabel: filled.isEmpty ? currentLocationLabel : filled.locationLabel
                    ))
                } catch: { _, send in
                    await send(.slotReshuffled(
                        slotID: slotID,
                        photos: currentPhotoIDs,
                        pillarID: currentPillarID,
                        locationLabel: currentLocationLabel
                    ))
                }

            case let .slotReshuffled(slotID, photos, pillarID, locationLabel):
                state.reshufflingSlotID = nil
                if let index = state.filledSlots.firstIndex(where: { $0.id == slotID }) {
                    state.filledSlots[index].photoIDs = photos
                    state.filledSlots[index].activePillarID = pillarID
                    state.filledSlots[index].locationLabel = locationLabel
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
