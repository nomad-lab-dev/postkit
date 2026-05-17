import ComposableArchitecture
import Foundation

@Reducer
struct TemplateListFeature {
    @ObservableState
    struct State: Equatable {
        var templates: [TemplateSnapshot] = []
        var isLoading: Bool = false
        @Presents var builder: TemplateBuilderFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action {
        case onAppear
        case templatesLoaded([TemplateSnapshot])
        case newTemplateTapped
        case templateTapped(TemplateSnapshot)
        case deleteTemplate(IndexSet)
        case deleted
        case builder(PresentationAction<TemplateBuilderFeature.Action>)
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {}
    }

    @Dependency(\.persistence) var persistence

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    let templates = try await persistence.fetchTemplates()
                    await send(.templatesLoaded(templates))
                }

            case let .templatesLoaded(templates):
                state.templates = templates
                state.isLoading = false
                return .none

            case .newTemplateTapped:
                state.builder = TemplateBuilderFeature.State()
                return .none

            case let .templateTapped(template):
                state.builder = TemplateBuilderFeature.State(existing: template)
                return .none

            case let .deleteTemplate(indices):
                let idsToDelete = indices.map { state.templates[$0].id }
                state.templates.remove(atOffsets: indices)
                return .run { send in
                    for id in idsToDelete {
                        try await persistence.deleteTemplate(id)
                    }
                    await send(.deleted)
                }

            case .deleted:
                return .none

            case .builder(.presented(.delegate(.didSave))):
                return .run { send in
                    let templates = try await persistence.fetchTemplates()
                    await send(.templatesLoaded(templates))
                }

            case .builder, .alert:
                return .none
            }
        }
        .ifLet(\.$builder, action: \.builder) {
            TemplateBuilderFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
