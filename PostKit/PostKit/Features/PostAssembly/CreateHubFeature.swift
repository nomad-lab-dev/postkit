import ComposableArchitecture
import Foundation

enum PostFilter: String, CaseIterable, Sendable {
    case all, draft, ready, published

    var displayName: String { rawValue.capitalized }
}

@Reducer
struct CreateHubFeature {
    @ObservableState
    struct State: Equatable {
        var templates: [TemplateSnapshot] = []
        var pillars: [PillarSnapshot] = []
        var posts: [GeneratedPostSnapshot] = []
        var postFilter: PostFilter = .all
        var isLoading: Bool = false
        @Presents var builder: TemplateBuilderFeature.State?
        @Presents var slotMachine: SlotMachineFeature.State?
        @Presents var editor: PostEditorFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        var filteredPosts: [GeneratedPostSnapshot] {
            switch postFilter {
            case .all: posts
            case .draft: posts.filter { $0.status == .draft }
            case .ready: posts.filter { $0.status == .ready }
            case .published: posts.filter { $0.status == .published }
            }
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case dataLoaded(templates: [TemplateSnapshot], pillars: [PillarSnapshot], posts: [GeneratedPostSnapshot])
        case newTemplateTapped
        case editTemplateTapped(TemplateSnapshot)
        case deleteTemplateTapped(TemplateSnapshot)
        case templateDeleted
        case templateSelected(TemplateSnapshot)
        case postTapped(GeneratedPostSnapshot)
        case deletePostTapped(GeneratedPostSnapshot)
        case postDeleted
        case filterChanged(PostFilter)
        case builder(PresentationAction<TemplateBuilderFeature.Action>)
        case slotMachine(PresentationAction<SlotMachineFeature.Action>)
        case editor(PresentationAction<PostEditorFeature.Action>)
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {}
    }

    @Dependency(\.persistence) var persistence
    @Dependency(\.notification) var notification

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    let templates = try await persistence.fetchTemplates()
                    let pillars = try await persistence.fetchPillars()
                    let posts = try await persistence.fetchPosts(nil)
                    await send(.dataLoaded(templates: templates, pillars: pillars, posts: posts))
                }

            case let .dataLoaded(templates, pillars, posts):
                state.templates = templates
                state.pillars = pillars
                state.posts = posts
                state.isLoading = false
                return .none

            case .newTemplateTapped:
                state.builder = TemplateBuilderFeature.State()
                return .none

            case let .editTemplateTapped(template):
                state.builder = TemplateBuilderFeature.State(existing: template)
                return .none

            case let .deleteTemplateTapped(template):
                let id = template.id
                state.templates.removeAll { $0.id == id }
                return .run { [notification] send in
                    try await persistence.deleteTemplate(id)
                    let notifIDs = Weekday.allCases.map { "template-\(id)-\($0.rawValue)" }
                    await notification.removePending(notifIDs)
                    await send(.templateDeleted)
                }

            case .templateDeleted:
                return .none

            case let .templateSelected(template):
                var editorState = PostEditorFeature.State(template: template)
                editorState.availablePillars = state.pillars
                state.editor = editorState
                return .none

            case let .postTapped(post):
                let template = state.templates.first { $0.id == post.templateID }
                    ?? TemplateSnapshot(name: "Post", slots: [TemplateSlotData(name: "Photo")])
                var filledSlots = template.slots.map { FilledSlot(slotData: $0, photoIDs: []) }
                for (index, photoID) in post.photoIDs.enumerated() where index < filledSlots.count {
                    filledSlots[index].photoIDs.insert(photoID)
                }
                var editorState = PostEditorFeature.State(template: template, filledSlots: filledSlots)
                editorState.availablePillars = state.pillars
                editorState.caption = post.caption
                editorState.hashtags = post.hashtags
                state.editor = editorState
                return .none

            case let .deletePostTapped(postToDelete):
                let id = postToDelete.id
                state.posts.removeAll { $0.id == id }
                return .run { send in
                    try await persistence.deletePost(id)
                    await send(.postDeleted)
                }

            case .postDeleted:
                return .none

            case let .filterChanged(filter):
                state.postFilter = filter
                return .none

            case .builder(.presented(.delegate(.didSave))):
                return .run { send in
                    let templates = try await persistence.fetchTemplates()
                    let pillars = try await persistence.fetchPillars()
                    let posts = try await persistence.fetchPosts(nil)
                    await send(.dataLoaded(templates: templates, pillars: pillars, posts: posts))
                }

            case let .slotMachine(.presented(.delegate(.openEditor(template, filledSlots)))):
                state.slotMachine = nil
                var editorState = PostEditorFeature.State(template: template, filledSlots: filledSlots)
                editorState.availablePillars = state.pillars
                state.editor = editorState
                return .none

            case .editor(.presented(.delegate(.didSave))):
                return .run { send in
                    let templates = try await persistence.fetchTemplates()
                    let pillars = try await persistence.fetchPillars()
                    let posts = try await persistence.fetchPosts(nil)
                    await send(.dataLoaded(templates: templates, pillars: pillars, posts: posts))
                }

            case .builder, .slotMachine, .editor, .alert, .binding:
                return .none
            }
        }
        .ifLet(\.$builder, action: \.builder) {
            TemplateBuilderFeature()
        }
        .ifLet(\.$slotMachine, action: \.slotMachine) {
            SlotMachineFeature()
        }
        .ifLet(\.$editor, action: \.editor) {
            PostEditorFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
