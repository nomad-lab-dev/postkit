// MARK: - PostKit
// SettingsFeature.swift — Settings reducer: placeholder for future user preferences

import ComposableArchitecture

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {}

    enum Action {}

    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
