// MARK: - PostKit
// TemplateListFeature.swift — Template list reducer: CRUD operations, builder and editor presentation

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct TemplateListFeature {
    @ObservableState
    struct State: Equatable {
        var templates: [TemplateSnapshot] = []
        var isLoading: Bool = false
        @Presents var builder: TemplateBuilderFeature.State?
        @Presents var editor: PostEditorFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action {
        case onAppear
        case templatesLoaded([TemplateSnapshot])
        case newTemplateTapped
        case templateTapped(TemplateSnapshot)
        case editTemplateTapped(TemplateSnapshot)
        case deleteTemplate(IndexSet)
        case deleted
        case builder(PresentationAction<TemplateBuilderFeature.Action>)
        case editor(PresentationAction<PostEditorFeature.Action>)
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {}
    }

    @Dependency(\.gallery) var gallery
    @Dependency(\.persistence) var persistence

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { [gallery] send in
                    let templates = try await gallery.templates()
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
                state.editor = PostEditorFeature.State(template: template)
                return .none

            case let .editTemplateTapped(template):
                state.builder = TemplateBuilderFeature.State(existing: template)
                return .none

            case let .deleteTemplate(indices):
                let idsToDelete = indices.map { state.templates[$0].id }
                state.templates.remove(atOffsets: indices)
                return .run { [gallery] send in
                    for id in idsToDelete {
                        try await persistence.deleteTemplate(id)
                    }
                    await gallery.invalidateTemplates()
                    await send(.deleted)
                }

            case .deleted:
                return .none

            case .builder(.presented(.delegate(.didSave))):
                return .run { [gallery] send in
                    await gallery.invalidateTemplates()
                    let templates = try await gallery.templates()
                    await send(.templatesLoaded(templates))
                }

            case .builder, .editor, .alert:
                return .none
            }
        }
        .ifLet(\.$builder, action: \.builder) {
            TemplateBuilderFeature()
        }
        .ifLet(\.$editor, action: \.editor) {
            PostEditorFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
