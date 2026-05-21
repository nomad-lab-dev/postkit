// MARK: - PostKit
// ReminderSetupFeature.swift — Posting cadence reminder setup: day picker, time, notification scheduling

import ComposableArchitecture
import Foundation

@Reducer
struct ReminderSetupFeature {
    @ObservableState
    struct State: Equatable {
        var selectedDays: Set<Int> = [2, 4, 6] // Mon, Wed, Fri
        var hour: Int = 9
        var minute: Int = 0
        var isScheduling: Bool = false

        var reminderTime: Date {
            get {
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                return Calendar.current.date(from: components) ?? .now
            }
            set {
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                hour = components.hour ?? 9
                minute = components.minute ?? 0
            }
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case dayToggled(Int)
        case confirmTapped
        case skipTapped
        case scheduled
        case delegate(Delegate)

        enum Delegate: Equatable {
            case completed
            case skipped
        }
    }

    @Dependency(\.notification) var notification
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case let .dayToggled(day):
                if state.selectedDays.contains(day) {
                    state.selectedDays.remove(day)
                } else {
                    state.selectedDays.insert(day)
                }
                return .none

            case .confirmTapped:
                guard !state.selectedDays.isEmpty else { return .none }
                state.isScheduling = true
                let days = state.selectedDays
                let hour = state.hour
                let minute = state.minute
                return .run { send in
                    _ = try? await notification.requestAuthorization()
                    for day in days.sorted() {
                        try? await notification.scheduleWeekly(
                            "postkit.reminder.\(day)",
                            day,
                            hour,
                            minute,
                            "Time to post!",
                            "Your photo library has content ready — open PostKit and create something."
                        )
                    }
                    await send(.scheduled)
                }

            case .scheduled:
                state.isScheduling = false
                return .merge(
                    .send(.delegate(.completed)),
                    .run { _ in await dismiss() }
                )

            case .skipTapped:
                return .merge(
                    .send(.delegate(.skipped)),
                    .run { _ in await dismiss() }
                )

            case .binding, .delegate:
                return .none
            }
        }
    }
}
