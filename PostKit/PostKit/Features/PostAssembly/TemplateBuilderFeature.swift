// MARK: - PostKit
// TemplateBuilderFeature.swift — Template builder reducer with slot editor and notifications

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct TemplateBuilderFeature {
    @ObservableState
    struct State: Equatable {
        var templateID: UUID?
        var name: String = ""
        var about: String = ""
        var slots: [TemplateSlotData] = []
        var selectedLocations: [String] = []
        var locationQuery: String = ""
        var schedule: TemplateSchedule = TemplateSchedule()
        var availablePillars: [PillarSnapshot] = []
        var availableLocations: [String] = []
        var mapSearchResults: [String] = []
        var isLoading: Bool = false
        @Presents var slotEditor: SlotEditorFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        var canSave: Bool {
            !name.trimmingCharacters(in: .whitespaces).isEmpty && !slots.isEmpty
        }

        var suggestedLocations: [String] {
            let query = locationQuery.trimmingCharacters(in: .whitespaces).lowercased()
            guard !query.isEmpty else { return [] }
            let galleryMatches = availableLocations.filter {
                $0.lowercased().contains(query) && !selectedLocations.contains($0)
            }
            let mapMatches = mapSearchResults.filter { result in
                !selectedLocations.contains(result) && !galleryMatches.contains(result)
            }
            return galleryMatches + mapMatches
        }

        var snapshot: TemplateSnapshot {
            TemplateSnapshot(
                id: templateID ?? UUID(),
                name: name.trimmingCharacters(in: .whitespaces),
                about: about.trimmingCharacters(in: .whitespaces),
                slots: slots,
                locations: selectedLocations,
                schedule: schedule
            )
        }

        init(existing: TemplateSnapshot? = nil) {
            if let existing {
                self.templateID = existing.id
                self.name = existing.name
                self.about = existing.about
                self.slots = existing.slots
                self.selectedLocations = existing.locations
                self.schedule = existing.schedule
            }
        }
    }

    enum Action: BindableAction {
        case onAppear
        case dataLoaded(pillars: [PillarSnapshot], locations: [String])
        case addSlotTapped
        case slotTapped(TemplateSlotData)
        case deleteSlotByID(UUID)
        case deleteSlot(IndexSet)
        case moveSlot(IndexSet, Int)
        case locationSelected(String)
        case locationRemoved(String)
        case locationSearchResults([String])
        case weekdayToggled(Weekday)
        case reminderToggled
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
    @Dependency(\.uuid) var uuid
    @Dependency(\.locationSearch) var locationSearch
    @Dependency(\.notification) var notification

    private enum CancelID: Hashable { case locationSearch }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.availablePillars.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    let pillars = try await persistence.fetchPillars()
                    let photos = (try? await persistence.fetchPhotos(.classified)) ?? []
                    let locations = Array(Set(photos.compactMap(\.location))).sorted()
                    await send(.dataLoaded(pillars: pillars, locations: locations))
                }

            case let .dataLoaded(pillars, locations):
                state.availablePillars = pillars
                state.availableLocations = locations
                state.isLoading = false
                return .none

            case .addSlotTapped:
                let index = state.slots.count + 1
                let newSlot = TemplateSlotData(id: uuid(), name: "Slot \(index)")
                state.slotEditor = SlotEditorFeature.State(
                    slot: newSlot,
                    availablePillars: state.availablePillars,
                    isNew: true
                )
                return .none

            case let .slotTapped(slot):
                state.slotEditor = SlotEditorFeature.State(
                    slot: slot,
                    availablePillars: state.availablePillars
                )
                return .none

            case let .locationSelected(location):
                if !state.selectedLocations.contains(location) {
                    state.selectedLocations.append(location)
                }
                state.locationQuery = ""
                state.mapSearchResults = []
                return .cancel(id: CancelID.locationSearch)

            case let .locationRemoved(location):
                state.selectedLocations.removeAll { $0 == location }
                return .none

            case let .locationSearchResults(results):
                state.mapSearchResults = results
                return .none

            case let .deleteSlotByID(id):
                state.slots.removeAll { $0.id == id }
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

            case let .weekdayToggled(day):
                if state.schedule.weekdays.contains(day) {
                    state.schedule.weekdays.remove(day)
                } else {
                    state.schedule.weekdays.insert(day)
                }
                return .none

            case .reminderToggled:
                state.schedule.reminderEnabled.toggle()
                if state.schedule.reminderEnabled {
                    return .run { [notification] _ in
                        _ = try? await notification.requestAuthorization()
                    }
                }
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
                return .run { [notification] send in
                    let allIDs = Weekday.allCases.map { "template-\(snapshot.id)-\($0.rawValue)" }
                    await notification.removePending(allIDs)

                    if snapshot.schedule.reminderEnabled && !snapshot.schedule.isEmpty {
                        for day in snapshot.schedule.weekdays {
                            // Convert Monday-based enum (1=Mon…7=Sun) to Calendar weekday (1=Sun…7=Sat)
                            let calWeekday = day == .sunday ? 1 : day.rawValue + 1
                            try? await notification.scheduleWeekly(
                                "template-\(snapshot.id)-\(day.rawValue)",
                                calWeekday, 9, 0,
                                "Your \(day.shortName) \(snapshot.name) is ready",
                                "Tap to assemble your post from fresh photos"
                            )
                        }
                    }

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

            case .binding(\.locationQuery):
                let query = state.locationQuery.trimmingCharacters(in: .whitespaces)
                guard query.count >= 2 else {
                    state.mapSearchResults = []
                    return .cancel(id: CancelID.locationSearch)
                }
                return .run { send in
                    try await Task.sleep(for: .milliseconds(300))
                    let results = await locationSearch.search(query)
                    await send(.locationSearchResults(results))
                }
                .cancellable(id: CancelID.locationSearch, cancelInFlight: true)

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
        var isNew: Bool = false
    }

    enum Action: BindableAction {
        case cadrageToggled(Cadrage)
        case pillarToggled(UUID)
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
            case let .cadrageToggled(cadrage):
                if let index = state.slot.cadrages.firstIndex(of: cadrage) {
                    state.slot.cadrages.remove(at: index)
                } else {
                    state.slot.cadrages.append(cadrage)
                }
                return .none

            case let .pillarToggled(pillarID):
                if let index = state.slot.pillarIDs.firstIndex(of: pillarID) {
                    state.slot.pillarIDs.remove(at: index)
                } else {
                    state.slot.pillarIDs.append(pillarID)
                }
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
