// MARK: - PostKit
// SmartPostFeature.swift — SmartPost reducer: AI chat, template generation, slot filling

import ComposableArchitecture
import Foundation

@Reducer
struct SmartPostFeature {

    @ObservableState
    struct State: Equatable {
        var pillars: [PillarSnapshot] = []
        var locationClusters: String = ""
        var messages: [ChatMessage] = []
        var inputText: String = ""
        var isAIThinking: Bool = false
        var isLoadingData: Bool = true
        var isFillingSlots: Bool = false
        var generatedTemplate: TemplateSnapshot?
        var showSaveAsTemplate: Bool = false
        var lastSavedTemplate: TemplateSnapshot?
        @Presents var editor: PostEditorFeature.State?

        var galleryContext: String {
            var lines: [String] = []
            let pillarSummary = pillars
                .filter { $0.photoCount > 0 }
                .map { "\($0.emoji) \($0.name) (\($0.photoCount) photos)" }
                .joined(separator: ", ")
            if !pillarSummary.isEmpty { lines.append("PILLARS: \(pillarSummary)") }
            lines.append("CADRAGES: \(Cadrage.allCases.map(\.rawValue).joined(separator: ", "))")
            if !locationClusters.isEmpty { lines.append("LOCATION CLUSTERS:\n\(locationClusters)") }
            return lines.joined(separator: "\n")
        }
    }

    enum Action: BindableAction {
        case onAppear
        case dataLoaded(pillars: [PillarSnapshot], locationClusters: String)
        case sendMessageTapped
        case templateIntentReceived(AITemplateIntent)
        case aiError(String)
        case createPostTapped
        case slotsFilled([FilledSlot])
        case startOverTapped
        case resetChatTapped
        case saveAsTemplateTapped
        case templateSaved(TemplateSnapshot)
        case dismissSaveAsTemplate
        case binding(BindingAction<State>)
        case editor(PresentationAction<PostEditorFeature.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case didSavePost
        }
    }

    @Dependency(\.persistence) var persistence
    @Dependency(\.postGenerator) var postGenerator
    @Dependency(\.uuid) var uuid

    private enum CancelID: Hashable { case aiCall }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.pillars.isEmpty else { return .none }
                state.isLoadingData = true
                state.messages = [
                    ChatMessage(
                        role: .assistant,
                        text: "Hey! Describe the post you want — topic, vibe, number of slides, locations. I'll build a template from your photo library."
                    )
                ]
                return .run { send in
                    let pillars = try await persistence.fetchPillars()
                    let photos = try await persistence.fetchPhotos(.classified)
                    let clusters = Self.buildLocationClusters(photos: photos, pillars: pillars)
                    await send(.dataLoaded(pillars: pillars, locationClusters: clusters))
                }

            case let .dataLoaded(pillars, locationClusters):
                state.pillars = pillars
                state.locationClusters = locationClusters
                state.isLoadingData = false
                return .none

            case .sendMessageTapped:
                let text = state.inputText.trimmingCharacters(in: .whitespaces)
                guard !text.isEmpty else { return .none }

                state.messages.append(ChatMessage(role: .user, text: text))
                state.inputText = ""
                state.isAIThinking = true

                if state.generatedTemplate != nil {
                    state.generatedTemplate = nil
                }

                let history = state.messages
                let context = state.galleryContext

                return .run { send in
                    let intent = try await postGenerator.parseTemplateIntent(
                        text, history, context
                    )
                    await send(.templateIntentReceived(intent))
                } catch: { error, send in
                    await send(.aiError(error.localizedDescription))
                }
                .cancellable(id: CancelID.aiCall, cancelInFlight: true)

            case let .templateIntentReceived(intent):
                state.isAIThinking = false
                state.messages.append(ChatMessage(role: .assistant, text: intent.reply))

                if intent.isComplete && !intent.slots.isEmpty {
                    state.generatedTemplate = resolveTemplateIntent(
                        intent,
                        pillars: state.pillars,
                        uuidGenerator: { uuid() }
                    )
                } else if intent.isComplete && intent.slots.isEmpty {
                    state.messages.append(
                        ChatMessage(
                            role: .assistant,
                            text: "I couldn't generate slots from that. Could you be more specific about what photos you want?"
                        )
                    )
                }
                return .none

            case let .aiError(message):
                state.isAIThinking = false
                state.messages.append(
                    ChatMessage(role: .assistant, text: "Something went wrong: \(message). Try again?")
                )
                return .none

            case .createPostTapped:
                guard let template = state.generatedTemplate else { return .none }
                state.isFillingSlots = true
                let slots = template.slots
                return .run { send in
                    let filledSlots = try await SlotFiller.fill(slots: slots, using: persistence)
                    await send(.slotsFilled(filledSlots))
                }

            case let .slotsFilled(filledSlots):
                state.isFillingSlots = false
                guard let template = state.generatedTemplate else { return .none }
                var editorState = PostEditorFeature.State(template: template, filledSlots: filledSlots)
                editorState.availablePillars = state.pillars
                state.editor = editorState
                return .none

            case .startOverTapped:
                state.generatedTemplate = nil
                state.messages.append(
                    ChatMessage(role: .assistant, text: "Fresh start! What kind of post do you want to create?")
                )
                return .none

            case .resetChatTapped:
                state.generatedTemplate = nil
                state.messages = [
                    ChatMessage(
                        role: .assistant,
                        text: "Chat reset! Describe the post you want — topic, vibe, number of slides, locations."
                    )
                ]
                state.inputText = ""
                return .none

            case .editor(.presented(.delegate(.didSave))):
                state.lastSavedTemplate = state.generatedTemplate
                state.generatedTemplate = nil
                state.showSaveAsTemplate = state.lastSavedTemplate != nil
                state.messages.append(
                    ChatMessage(
                        role: .assistant,
                        text: state.showSaveAsTemplate
                            ? "Post saved! Want to save this as a reusable template? You can schedule it for specific days."
                            : "Post saved! Want to create another one?"
                    )
                )
                return .send(.delegate(.didSavePost))

            case .saveAsTemplateTapped:
                guard let template = state.lastSavedTemplate else { return .none }
                state.showSaveAsTemplate = false
                return .run { send in
                    try await persistence.saveTemplate(template)
                    await send(.templateSaved(template))
                }

            case let .templateSaved(template):
                state.lastSavedTemplate = nil
                state.messages.append(
                    ChatMessage(
                        role: .assistant,
                        text: "Template \"\(template.name)\" saved! Find it in the Create tab to schedule it for specific days."
                    )
                )
                return .none

            case .dismissSaveAsTemplate:
                state.showSaveAsTemplate = false
                state.lastSavedTemplate = nil
                return .none

            case .editor, .binding, .delegate:
                return .none
            }
        }
        .ifLet(\.$editor, action: \.editor) {
            PostEditorFeature()
        }
    }

    static func buildLocationClusters(
        photos: [ClassifiedPhotoSnapshot],
        pillars: [PillarSnapshot]
    ) -> String {
        let pillarLookup = Dictionary(
            pillars.map { ($0.id, $0.name) },
            uniquingKeysWith: { first, _ in first }
        )
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM yyyy"

        struct ClusterKey: Hashable {
            let location: String
            let monthYear: String
        }

        var clusters: [ClusterKey: (count: Int, pillarNames: Set<String>)] = [:]
        for photo in photos {
            guard let location = photo.location, let date = photo.capturedAt else { continue }
            let key = ClusterKey(location: location, monthYear: fmt.string(from: date))
            var entry = clusters[key] ?? (count: 0, pillarNames: [])
            entry.count += 1
            for pid in photo.pillarIDs {
                if let name = pillarLookup[pid] { entry.pillarNames.insert(name) }
            }
            clusters[key] = entry
        }

        let grouped = Dictionary(grouping: clusters) { $0.key.location }
        var lines: [String] = []
        for (location, entries) in grouped.sorted(by: { $0.key < $1.key }) {
            let periods = entries
                .sorted { $0.key.monthYear > $1.key.monthYear }
                .prefix(5)
                .map { entry in
                    let pillars = entry.value.pillarNames.sorted().joined(separator: "/")
                    let pillarSuffix = pillars.isEmpty ? "" : " [\(pillars)]"
                    return "\(entry.key.monthYear) (\(entry.value.count) photos\(pillarSuffix))"
                }
                .joined(separator: ", ")
            lines.append("- \(location): \(periods)")
        }
        return lines.joined(separator: "\n")
    }
}
