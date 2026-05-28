// MARK: - PostKit
// SmartPostFeatureTests.swift — SmartPost reducer tests: data load, AI chat, slot filling, editor handoff

import ComposableArchitecture
import Foundation
import XCTest
@testable import PostKit

@MainActor
final class SmartPostFeatureTests: XCTestCase {

    private let testDate = Date(timeIntervalSince1970: 1_700_000_000)

    let pillars = [
        PillarSnapshot(id: UUID(0), name: "Travel", emoji: "✈️", photoCount: 10),
        PillarSnapshot(id: UUID(1), name: "Food", emoji: "🍽️", photoCount: 5),
    ]

    // MARK: - Data Loading

    func test_onAppear_loadsPillarsAndLocations() async {
        let store = TestStore(
            initialState: SmartPostFeature.State()
        ) {
            SmartPostFeature()
        } withDependencies: {
            $0.gallery.pillars = { [pillars] in pillars }
            $0.gallery.photos = { _ in [] }
        }

        await store.send(.onAppear)

        await store.receive(\.dataLoaded) {
            $0.pillars = self.pillars
            $0.locationClusters = ""
            $0.isLoadingData = false
        }
    }

    func test_onAppear_skipsIfAlreadyLoaded() async {
        var state = SmartPostFeature.State()
        state.pillars = pillars

        let store = TestStore(initialState: state) {
            SmartPostFeature()
        }

        await store.send(.onAppear)
    }

    func test_onAppear_handlesError_loadsEmpty() async {
        struct LoadError: Error {}

        let store = TestStore(
            initialState: SmartPostFeature.State()
        ) {
            SmartPostFeature()
        } withDependencies: {
            $0.gallery.pillars = { throw LoadError() }
            $0.gallery.photos = { _ in [] }
        }

        await store.send(.onAppear)

        await store.receive(\.dataLoaded) {
            $0.isLoadingData = false
        }
    }

    // MARK: - Send Message

    func test_sendMessage_appendsUserMessageAndCallsAI() async {
        let intent = AITemplateIntent(
            templateName: "Trip",
            slots: [],
            reply: "Got it! How many slides?",
            isComplete: false,
            quickReplies: ["3 slides", "5 slides"]
        )

        var state = SmartPostFeature.State()
        state.pillars = pillars
        state.isLoadingData = false
        state.inputText = "A travel carousel"

        let store = TestStore(initialState: state) {
            SmartPostFeature()
        } withDependencies: {
            $0.postGenerator.parseTemplateIntent = { _, _, _ in intent }
        }

        await store.send(.sendMessageTapped) {
            $0.inputText = ""
            $0.isAIThinking = true
            $0.quickReplies = []
            $0.messages.append(ChatMessage(role: .user, text: "A travel carousel"))
        }

        await store.receive(\.templateIntentReceived) {
            $0.isAIThinking = false
            $0.quickReplies = ["3 slides", "5 slides"]
            $0.messages.append(ChatMessage(role: .assistant, text: "Got it! How many slides?"))
        }
    }

    func test_sendMessage_emptyText_doesNothing() async {
        var state = SmartPostFeature.State()
        state.inputText = "   "

        let store = TestStore(initialState: state) {
            SmartPostFeature()
        }

        await store.send(.sendMessageTapped)
    }

    func test_sendMessage_aiError_showsErrorMessage() async {
        struct AIError: Error, LocalizedError {
            var errorDescription: String? { "Rate limited" }
        }

        var state = SmartPostFeature.State()
        state.pillars = pillars
        state.inputText = "test"

        let store = TestStore(initialState: state) {
            SmartPostFeature()
        } withDependencies: {
            $0.postGenerator.parseTemplateIntent = { _, _, _ in throw AIError() }
        }

        await store.send(.sendMessageTapped) {
            $0.inputText = ""
            $0.isAIThinking = true
            $0.quickReplies = []
            $0.messages.append(ChatMessage(role: .user, text: "test"))
        }

        await store.receive(\.aiError) {
            $0.isAIThinking = false
            $0.messages.append(
                ChatMessage(role: .assistant, text: "Something went wrong: Rate limited. Try again?")
            )
        }
    }

    // MARK: - Quick Reply

    func test_quickReply_setsInputAndSends() async {
        let intent = AITemplateIntent(
            templateName: "", slots: [], reply: "OK!", isComplete: false, quickReplies: []
        )

        var state = SmartPostFeature.State()
        state.pillars = pillars

        let store = TestStore(initialState: state) {
            SmartPostFeature()
        } withDependencies: {
            $0.postGenerator.parseTemplateIntent = { _, _, _ in intent }
        }

        await store.send(.quickReplyTapped("3 slides")) {
            $0.inputText = "3 slides"
        }

        await store.receive(\.sendMessageTapped) {
            $0.inputText = ""
            $0.isAIThinking = true
            $0.quickReplies = []
            $0.messages.append(ChatMessage(role: .user, text: "3 slides"))
        }

        await store.receive(\.templateIntentReceived) {
            $0.isAIThinking = false
            $0.messages.append(ChatMessage(role: .assistant, text: "OK!"))
        }
    }

    // MARK: - Template Generation

    func test_templateIntentComplete_generatesTemplate() async {
        let intent = AITemplateIntent(
            templateName: "Travel Carousel",
            slots: [
                AISlotDefinition(
                    name: "Hero", pillarNames: ["Travel"], cadrageNames: ["wide"],
                    locations: ["Paris"], about: "Main shot", startDate: nil, endDate: nil
                ),
                AISlotDefinition(
                    name: "Detail", pillarNames: [], cadrageNames: ["detail"],
                    locations: [], about: "Close-up", startDate: nil, endDate: nil
                ),
            ],
            reply: "Here's your template!",
            isComplete: true,
            quickReplies: []
        )

        var state = SmartPostFeature.State()
        state.pillars = pillars
        state.inputText = "travel carousel with 2 slides"

        let store = TestStore(initialState: state) {
            SmartPostFeature()
        } withDependencies: {
            $0.postGenerator.parseTemplateIntent = { _, _, _ in intent }
            $0.uuid = .incrementing
            $0.date = .constant(self.testDate)
        }

        await store.send(.sendMessageTapped) {
            $0.inputText = ""
            $0.isAIThinking = true
            $0.quickReplies = []
            $0.messages.append(ChatMessage(role: .user, text: "travel carousel with 2 slides"))
        }

        // UUID order: slot1 → UUID(0), slot2 → UUID(1), template → UUID(2)
        await store.receive(\.templateIntentReceived) {
            $0.isAIThinking = false
            $0.messages.append(ChatMessage(role: .assistant, text: "Here's your template!"))
            $0.generatedTemplate = TemplateSnapshot(
                id: UUID(2),
                name: "Travel Carousel",
                slots: [
                    TemplateSlotData(
                        id: UUID(0), name: "Hero", cadrages: [.wide],
                        pillarIDs: [UUID(0)], locations: ["Paris"], about: "Main shot"
                    ),
                    TemplateSlotData(
                        id: UUID(1), name: "Detail", cadrages: [.detail],
                        pillarIDs: [], locations: [], about: "Close-up"
                    ),
                ],
                locations: ["Paris"],
                createdAt: self.testDate
            )
        }
    }

    func test_templateIntentComplete_emptySlotsShowsError() async {
        let intent = AITemplateIntent(
            templateName: "Empty",
            slots: [],
            reply: "Done!",
            isComplete: true,
            quickReplies: []
        )

        var state = SmartPostFeature.State()
        state.pillars = pillars
        state.inputText = "something vague"

        let store = TestStore(initialState: state) {
            SmartPostFeature()
        } withDependencies: {
            $0.postGenerator.parseTemplateIntent = { _, _, _ in intent }
        }

        await store.send(.sendMessageTapped) {
            $0.inputText = ""
            $0.isAIThinking = true
            $0.quickReplies = []
            $0.messages.append(ChatMessage(role: .user, text: "something vague"))
        }

        await store.receive(\.templateIntentReceived) {
            $0.isAIThinking = false
            $0.messages.append(ChatMessage(role: .assistant, text: "Done!"))
            $0.messages.append(
                ChatMessage(role: .assistant, text: "I couldn't generate slots from that. Could you be more specific about what photos you want?")
            )
        }
    }

    // MARK: - Create Post & Editor Handoff

    func test_createPost_fillsSlotsAndOpensEditor() async {
        let template = TemplateSnapshot(
            id: UUID(0),
            name: "Test",
            slots: [TemplateSlotData(id: UUID(1), name: "Hero", cadrages: [.wide])]
        )
        let filledSlot = FilledSlot(
            slotData: template.slots[0],
            photoIDs: ["a1"],
            activePillarID: UUID(0),
            locationLabel: nil
        )

        var state = SmartPostFeature.State()
        state.pillars = pillars
        state.generatedTemplate = template

        let store = TestStore(initialState: state) {
            SmartPostFeature()
        } withDependencies: {
            $0.persistence.fetchPhotos = { _ in
                [ClassifiedPhotoSnapshot(assetLocalIdentifier: "a1", pillarID: UUID(0), status: .classified)]
            }
            $0.persistence.fetchPhotosForPillar = { _ in
                [ClassifiedPhotoSnapshot(assetLocalIdentifier: "a1", pillarID: UUID(0), status: .classified)]
            }
        }

        await store.send(.createPostTapped) {
            $0.isFillingSlots = true
        }

        await store.receive(\.slotsFilled) {
            $0.isFillingSlots = false
            let filledSlot = FilledSlot(
                slotData: template.slots[0],
                photoIDs: ["a1"],
                activePillarID: UUID(0),
                locationLabel: nil
            )
            var editorState = PostEditorFeature.State(
                template: template,
                filledSlots: [filledSlot]
            )
            editorState.availablePillars = self.pillars
            editorState.isAutoGenerated = true
            $0.editor = editorState
        }

        XCTAssertTrue(store.state.editor?.isAutoGenerated == true)
    }

    func test_createPost_withoutTemplate_doesNothing() async {
        var state = SmartPostFeature.State()
        state.generatedTemplate = nil

        let store = TestStore(initialState: state) {
            SmartPostFeature()
        }

        await store.send(.createPostTapped)
    }

    // MARK: - Editor Delegate

    func test_editorDidSave_offersTemplateAndSendsDelegate() async {
        let template = TemplateSnapshot(id: UUID(0), name: "Saved Template", slots: [])

        var state = SmartPostFeature.State()
        state.pillars = pillars
        state.generatedTemplate = template
        state.editor = PostEditorFeature.State(template: template)

        let store = TestStore(initialState: state) {
            SmartPostFeature()
        }

        await store.send(.editor(.presented(.delegate(.didSave)))) {
            $0.lastSavedTemplate = template
            $0.generatedTemplate = nil
            $0.showSaveAsTemplate = true
            $0.messages.append(
                ChatMessage(
                    role: .assistant,
                    text: "Post saved! Want to save this as a reusable template? You can schedule it for specific days."
                )
            )
        }

        await store.receive(\.delegate.didSavePost)
    }

    // MARK: - Save As Template

    func test_saveAsTemplate_persistsAndConfirms() async {
        let template = TemplateSnapshot(id: UUID(0), name: "My Template", slots: [])

        var state = SmartPostFeature.State()
        state.lastSavedTemplate = template
        state.showSaveAsTemplate = true

        let store = TestStore(initialState: state) {
            SmartPostFeature()
        } withDependencies: {
            $0.persistence.saveTemplate = { _ in }
        }

        await store.send(.saveAsTemplateTapped) {
            $0.showSaveAsTemplate = false
        }

        await store.receive(\.templateSaved) {
            $0.lastSavedTemplate = nil
            $0.messages.append(
                ChatMessage(
                    role: .assistant,
                    text: "Template \"My Template\" saved! Find it in the Create tab to schedule it for specific days."
                )
            )
        }
    }

    func test_dismissSaveAsTemplate_clearsState() async {
        var state = SmartPostFeature.State()
        state.showSaveAsTemplate = true
        state.lastSavedTemplate = TemplateSnapshot(id: UUID(0), name: "T", slots: [])

        let store = TestStore(initialState: state) {
            SmartPostFeature()
        }

        await store.send(.dismissSaveAsTemplate) {
            $0.showSaveAsTemplate = false
            $0.lastSavedTemplate = nil
        }
    }

    // MARK: - Reset

    func test_startOver_keepsHistoryButClearsTemplate() async {
        var state = SmartPostFeature.State()
        state.generatedTemplate = TemplateSnapshot(id: UUID(0), name: "T", slots: [])
        state.quickReplies = ["a", "b"]

        let store = TestStore(initialState: state) {
            SmartPostFeature()
        }

        await store.send(.startOverTapped) {
            $0.generatedTemplate = nil
            $0.quickReplies = []
            $0.messages.append(
                ChatMessage(role: .assistant, text: "Fresh start! What kind of post do you want to create?")
            )
        }
    }

    func test_resetChat_clearsEverything() async {
        var state = SmartPostFeature.State()
        state.generatedTemplate = TemplateSnapshot(id: UUID(0), name: "T", slots: [])
        state.quickReplies = ["a"]
        state.inputText = "partial input"
        state.messages.append(ChatMessage(role: .user, text: "old message"))

        let store = TestStore(initialState: state) {
            SmartPostFeature()
        }

        await store.send(.resetChatTapped) {
            $0.generatedTemplate = nil
            $0.quickReplies = []
            $0.inputText = ""
            $0.messages = [
                ChatMessage(
                    role: .assistant,
                    text: "Chat reset! Describe the post you want: topic, number of slides, locations."
                )
            ]
        }
    }
}
