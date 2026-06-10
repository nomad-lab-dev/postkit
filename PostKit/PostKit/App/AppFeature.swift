// MARK: - PostKit
// AppFeature.swift — Root app reducer: tab routing, onboarding presentation, child feature composition

import ComposableArchitecture
import Foundation

enum AppTab: Int, Sendable {
    case home, explore, smartPost, create, settings
}

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: AppTab = .home
        @Presents var onboarding: OnboardingFeature.State?
        var dashboard = DashboardFeature.State()
        var explore = ExploreFeature.State()
        var smartPost = SmartPostFeature.State()
        var create = CreateHubFeature.State()
        var settings = SettingsFeature.State()
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case appLaunched
        case tabSelected(AppTab)
        case onboarding(PresentationAction<OnboardingFeature.Action>)
        case dashboard(DashboardFeature.Action)
        case explore(ExploreFeature.Action)
        case smartPost(SmartPostFeature.Action)
        case create(CreateHubFeature.Action)
        case settings(SettingsFeature.Action)
    }

    @Dependency(\.userDefaults) var userDefaults

    var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.dashboard, action: \.dashboard) { DashboardFeature() }
        Scope(state: \.explore, action: \.explore) { ExploreFeature() }
        Scope(state: \.smartPost, action: \.smartPost) { SmartPostFeature() }
        Scope(state: \.create, action: \.create) { CreateHubFeature() }
        Scope(state: \.settings, action: \.settings) { SettingsFeature() }

        Reduce { state, action in
            switch action {
            case .appLaunched:
                return .none

            case .onboarding(.presented(.delegate(.startFirstPost(let prompt)))):
                state.onboarding = nil
                state.selectedTab = .smartPost
                let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    state.smartPost.inputText = trimmed
                }
                return .run { [userDefaults] send in
                    userDefaults.setBool(true, "onboardingComplete")
                    await send(.dashboard(.onAppear))
                }

            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            case let .dashboard(.pillarTapped(pillar)):
                state.selectedTab = .explore
                state.explore.selectedFilter = .pillar(pillar.id)
                state.explore.photos = []
                state.explore.currentOffset = 0
                return .none

            case .dashboard(.browsePhotosTapped):
                state.selectedTab = .explore
                return .none

            case .dashboard(.composePostTapped):
                state.selectedTab = .smartPost
                return .none

            case .dashboard(.newTemplateTapped):
                state.selectedTab = .create
                return .none

            case .smartPost(.delegate(.didSavePost)):
                return .send(.create(.onAppear))

            case .binding, .dashboard, .explore, .smartPost, .create, .settings, .onboarding:
                return .none
            }
        }
        .ifLet(\.$onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
    }
}
