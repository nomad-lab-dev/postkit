import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .home
        var isOnboardingPresented = false
        var dashboard = DashboardFeature.State()
        var classify = ClassificationQueueFeature.State()
        var create = PostAssemblyEntryFeature.State()
        var settings = SettingsFeature.State()
        var homePath = StackState<HomePath.State>()
        var classifyPath = StackState<ClassifyPath.State>()
        var createPath = StackState<CreatePath.State>()
    }

    enum Tab: Equatable, Hashable, Sendable {
        case home, classify, create, settings
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case appLaunched
        case tabSelected(Tab)
        case dashboard(DashboardFeature.Action)
        case classify(ClassificationQueueFeature.Action)
        case create(PostAssemblyEntryFeature.Action)
        case settings(SettingsFeature.Action)
        case homePath(StackAction<HomePath.State, HomePath.Action>)
        case classifyPath(StackAction<ClassifyPath.State, ClassifyPath.Action>)
        case createPath(StackAction<CreatePath.State, CreatePath.Action>)
    }

    @Dependency(\.userDefaults) var userDefaults

    var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.dashboard, action: \.dashboard) { DashboardFeature() }
        Scope(state: \.classify, action: \.classify) { ClassificationQueueFeature() }
        Scope(state: \.create, action: \.create) { PostAssemblyEntryFeature() }
        Scope(state: \.settings, action: \.settings) { SettingsFeature() }

        Reduce { state, action in
            switch action {
            case .appLaunched:
                if !userDefaults.boolForKey("onboardingComplete") {
                    state.isOnboardingPresented = true
                }
                return .none

            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            case .binding, .dashboard, .classify, .create, .settings,
                 .homePath, .classifyPath, .createPath:
                return .none
            }
        }
        .forEach(\.homePath, action: \.homePath)
        .forEach(\.classifyPath, action: \.classifyPath)
        .forEach(\.createPath, action: \.createPath)
    }
}
