import ComposableArchitecture

// MARK: - Path Feature Stubs (replaced in later slices)

@Reducer
struct PillarDetailFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action {}
    var body: some ReducerOf<Self> { Reduce { _, _ in .none } }
}

@Reducer
struct PillarEditorFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action {}
    var body: some ReducerOf<Self> { Reduce { _, _ in .none } }
}

@Reducer
struct ClassificationFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action {}
    var body: some ReducerOf<Self> { Reduce { _, _ in .none } }
}

@Reducer
struct PostAssemblyFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action {}
    var body: some ReducerOf<Self> { Reduce { _, _ in .none } }
}

@Reducer
struct PlatformExportFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action {}
    var body: some ReducerOf<Self> { Reduce { _, _ in .none } }
}

// MARK: - Path Enums (one per tab stack)

@Reducer
enum HomePath {
    case pillarDetail(PillarDetailFeature)
    case pillarEditor(PillarEditorFeature)
}

@Reducer
enum ClassifyPath {
    case classify(ClassificationFeature)
}

@Reducer
enum CreatePath {
    case photoSelection(PostAssemblyFeature)
    case platformExport(PlatformExportFeature)
}
