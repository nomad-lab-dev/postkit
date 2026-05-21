// MARK: - PostKit
// SettingsFeature.swift — Settings reducer: topics management, notifications toggle, about

import ComposableArchitecture

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        var pillars: [PillarSnapshot] = []
        var isLoading: Bool = false
        var notificationsEnabled: Bool = false
        var cloudAIEnabled: Bool = false
        @Presents var topicEditor: TopicEditorFeature.State?
    }

    enum Action {
        case onAppear
        case pillarsLoaded([PillarSnapshot])
        case notificationStatusLoaded(Bool)
        case topicTapped(PillarSnapshot)
        case notificationToggled
        case cloudAIToggled
        case topicEditor(PresentationAction<TopicEditorFeature.Action>)
    }

    @Dependency(\.gallery) var gallery
    @Dependency(\.persistence) var persistence
    @Dependency(\.notification) var notification
    @Dependency(\.userDefaults) var userDefaults

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.cloudAIEnabled = userDefaults.boolForKey("cloudAIEnabled")
                return .run { [gallery] send in
                    let pillars = try await gallery.pillars()
                    await send(.pillarsLoaded(pillars))
                    let authorized = (try? await notification.requestAuthorization()) ?? false
                    await send(.notificationStatusLoaded(authorized))
                }

            case let .pillarsLoaded(pillars):
                state.pillars = pillars
                state.isLoading = false
                return .none

            case let .notificationStatusLoaded(enabled):
                state.notificationsEnabled = enabled
                return .none

            case let .topicTapped(pillar):
                state.topicEditor = TopicEditorFeature.State(pillar: pillar)
                return .none

            case .notificationToggled:
                if !state.notificationsEnabled {
                    return .run { send in
                        let granted = (try? await notification.requestAuthorization()) ?? false
                        await send(.notificationStatusLoaded(granted))
                    }
                }
                return .none

            case .cloudAIToggled:
                state.cloudAIEnabled.toggle()
                let enabled = state.cloudAIEnabled
                userDefaults.setBool(enabled, "cloudAIEnabled")
                return .none

            case .topicEditor(.presented(.delegate(.didSave))):
                return .run { [gallery] send in
                    await gallery.invalidatePillars()
                    await send(.onAppear)
                }

            case .topicEditor(.presented(.delegate(.didDelete(_)))):
                return .run { [gallery] send in
                    await gallery.invalidatePillars()
                    await send(.onAppear)
                }

            case .topicEditor:
                return .none
            }
        }
        .ifLet(\.$topicEditor, action: \.topicEditor) {
            TopicEditorFeature()
        }
    }
}
