import ComposableArchitecture
import GoogleGenerativeAI
import UIKit

@DependencyClient
struct PostGeneratorClient: Sendable {
    var generateCaption: @Sendable (
        _ images: [UIImage],
        _ pillar: PillarSnapshot,
        _ platform: SocialPlatform
    ) async throws -> String

    var generateHashtags: @Sendable (
        _ caption: String,
        _ pillar: PillarSnapshot,
        _ platform: SocialPlatform
    ) async throws -> [String]

    var parsePostIntent: @Sendable (
        _ message: String,
        _ history: [ChatMessage],
        _ galleryContext: String
    ) async throws -> AIPostIntent

    var parseTemplateIntent: @Sendable (
        _ message: String,
        _ history: [ChatMessage],
        _ galleryContext: String
    ) async throws -> AITemplateIntent
}

// MARK: - Live

extension PostGeneratorClient: DependencyKey {
    static let liveValue = PostGeneratorClient(
        generateCaption: { images, pillar, platform in
            let model = try PostGemini.textModel()
            let prompt = """
            Write a short, engaging \(platform.displayName) caption for a \(pillar.name) post.
            Keep it under 200 characters. Use a natural, authentic tone.
            Do NOT use markdown. Return only the caption text.
            """
            if let first = images.first {
                let response = try await model.generateContent(prompt, first)
                return response.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            }
            let response = try await model.generateContent(prompt)
            return response.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        },
        generateHashtags: { caption, pillar, platform in
            let model = try PostGemini.textModel()
            let prompt = """
            Generate 5-8 relevant hashtags for this \(platform.displayName) post.
            Caption: "\(caption)"
            Pillar: \(pillar.name)
            Return ONLY a JSON array of strings like ["#tag1", "#tag2"].
            No markdown, no explanation.
            """
            let response = try await model.generateContent(prompt)
            guard let text = response.text else { return [] }
            return PostGemini.parseStringArray(text) ?? ["#\(pillar.name.lowercased())", "#postkit"]
        },
        parsePostIntent: { message, history, galleryContext in
            let systemPrompt = """
            You are a creative assistant helping a content creator build social media posts \
            from their photo library.

            PHOTO LIBRARY:
            \(galleryContext)

            YOUR JOB:
            - Understand what kind of post the user wants
            - Ask clarifying questions if needed (pillar/category, photo count, mood, location, date range)
            - When you have enough info, set isComplete to true so the app auto-selects matching photos

            RULES:
            - Be concise and friendly (1-2 sentences max)
            - Only reference pillars, locations, and dates that exist in the library context
            - If the request is clear enough to select photos, set isComplete: true
            - If you need more info, set isComplete: false and ask ONE question
            - pillarNames must match exactly the names from the library context
            - Dates use ISO 8601 (e.g. "2025-01-15T00:00:00Z") or null
            """

            let model = try PostGemini.chatModel(systemInstruction: systemPrompt)
            let priorMessages = history.dropLast()
            let chat = model.startChat(history: PostGemini.buildHistory(from: Array(priorMessages)))

            do {
                let response = try await chat.sendMessage(message)
                guard let text = response.text else {
                    throw PostGeneratorError.noResponse
                }
                return try PostGemini.parsePostIntent(text)
            } catch let error as GenerateContentError {
                throw PostGeneratorError.geminiError(PostGemini.describeError(error))
            } catch {
                throw PostGeneratorError.geminiError(error.localizedDescription)
            }
        },
        parseTemplateIntent: { message, history, galleryContext in
            let systemPrompt = """
            You are Smart Post, the AI assistant inside PostKit — an iOS app for content creators \
            who organize their photo library by "pillars" (themes like Food, Travel, Cars, etc.) \
            and create social media posts from those photos.

            YOUR ROLE: Help the user build a post template by chatting naturally. You design a \
            set of "slots" — each slot will be auto-filled with a matching photo from their library.

            THE USER'S PHOTO LIBRARY:
            \(galleryContext)

            HOW SLOT MATCHING WORKS:
            - Each slot has constraints: pillarNames, locations, cadrageNames, date range
            - The app picks a random photo that matches ALL constraints for each slot
            - Slots with different locations will get photos from different places
            - Slots with date ranges will only get photos from that period
            - If you want variety (e.g. "6 different countries"), assign different locations per slot

            PILLAR MATCHING:
            - pillarNames must match EXACTLY the pillar names from the context above
            - But interpret the user loosely: "food pics" → Food, "my rides" → Cars, etc.
            - If unsure which pillar, ask

            DATE RANGE MATCHING:
            - Use startDate/endDate (ISO 8601) per slot when the user mentions a time period
            - If a location appears multiple times in the clusters (e.g. Bangkok in Mar 2024 AND Dec 2025), \
            ASK which trip the user means and show the available date clusters
            - Only set dates when the user specifies or confirms a period

            DISAMBIGUATION:
            - If the user's request is ambiguous (multiple trips to same place, vague pillar), \
            set isComplete: false, slots: [], and ask ONE clarifying question
            - Reference the actual data: "I see Bangkok photos from Mar 2024 (23 photos) and Dec 2025 \
            (45 photos) — which trip?"

            RULES:
            - Be concise and friendly (1-2 sentences max)
            - cadrageNames from: any, wide, detail, portrait, pov, screenshot
            - locations must match locations from the context above
            - Give each slot a creative, descriptive name
            - The "about" field describes what the photo should show
            - startDate/endDate are ISO 8601 strings or null

            RESPONSE FORMAT (strict JSON):
            {
              "templateName": "string",
              "slots": [
                {
                  "name": "string",
                  "pillarNames": ["string"],
                  "cadrageNames": ["string"],
                  "locations": ["string"],
                  "about": "string",
                  "startDate": "ISO8601 or null",
                  "endDate": "ISO8601 or null"
                }
              ],
              "reply": "string",
              "isComplete": bool
            }
            """

            let model = try PostGemini.chatModel(systemInstruction: systemPrompt)
            let priorMessages = history.dropLast()
            let chat = model.startChat(history: PostGemini.buildTemplateHistory(from: Array(priorMessages)))

            do {
                let response = try await chat.sendMessage(message)
                guard let text = response.text else {
                    throw PostGeneratorError.noResponse
                }
                return try PostGemini.parseTemplateIntent(text)
            } catch let error as GenerateContentError {
                throw PostGeneratorError.geminiError(PostGemini.describeError(error))
            } catch {
                throw PostGeneratorError.geminiError(error.localizedDescription)
            }
        }
    )

    static let previewValue = PostGeneratorClient(
        generateCaption: { _, pillar, _ in
            "Check out this amazing \(pillar.name.lowercased()) content!"
        },
        generateHashtags: { _, pillar, _ in
            ["#\(pillar.name.lowercased())", "#postkit", "#content"]
        },
        parsePostIntent: { message, _, _ in
            try await Task.sleep(for: .milliseconds(600))
            let numbers = message.lowercased()
                .components(separatedBy: .decimalDigits.inverted)
                .compactMap(Int.init)
            let count = numbers.first

            if let count {
                return AIPostIntent(
                    filters: PostFilters(count: count),
                    reply: "Got it! I'll select \(count) photos for you.",
                    isComplete: true
                )
            } else {
                return AIPostIntent(
                    filters: PostFilters(),
                    reply: "How many photos do you want in this post?",
                    isComplete: false
                )
            }
        },
        parseTemplateIntent: { message, _, _ in
            try await Task.sleep(for: .milliseconds(600))
            let numbers = message.lowercased()
                .components(separatedBy: .decimalDigits.inverted)
                .compactMap(Int.init)
            let count = numbers.first ?? 3

            return AITemplateIntent(
                templateName: "Preview Template",
                slots: (1...count).map { i in
                    AISlotDefinition(
                        name: "Slide \(i)",
                        pillarNames: [],
                        cadrageNames: ["any"],
                        locations: [],
                        about: "Photo \(i) of the post",
                        startDate: nil,
                        endDate: nil
                    )
                },
                reply: "Here's a \(count)-slide template for you!",
                isComplete: true
            )
        }
    )
}

extension DependencyValues {
    var postGenerator: PostGeneratorClient {
        get { self[PostGeneratorClient.self] }
        set { self[PostGeneratorClient.self] = newValue }
    }
}

// MARK: - Gemini Helpers

private enum PostGemini {

    static func apiKey() throws -> String {
        guard let key = Bundle.main.infoDictionary?["GeminiAPIKey"] as? String,
              !key.isEmpty else {
            throw PostGeneratorError.missingAPIKey
        }
        return key
    }

    static func textModel() throws -> GenerativeModel {
        GenerativeModel(name: "gemini-2.5-flash", apiKey: try apiKey())
    }

    static func chatModel(systemInstruction: String) throws -> GenerativeModel {
        GenerativeModel(
            name: "gemini-2.5-flash",
            apiKey: try apiKey(),
            generationConfig: GenerationConfig(responseMIMEType: "application/json"),
            systemInstruction: systemInstruction
        )
    }

    static func buildHistory(from messages: [ChatMessage]) -> [ModelContent] {
        let relevant = messages.drop(while: { $0.role == .assistant })
        var contents: [ModelContent] = []
        for msg in relevant {
            let role = msg.role == .user ? "user" : "model"
            let text: String
            if msg.role == .assistant {
                text = """
                {"filters":{"pillarNames":[],"locations":[],"startDate":null,"endDate":null,\
                "count":null,"mood":null},"reply":"\(msg.text.replacingOccurrences(of: "\"", with: "\\\""))","isComplete":false}
                """
            } else {
                text = msg.text
            }
            contents.append(ModelContent(role: role, parts: [.text(text)]))
        }
        return contents
    }

    static func buildTemplateHistory(from messages: [ChatMessage]) -> [ModelContent] {
        let relevant = messages.drop(while: { $0.role == .assistant })
        var contents: [ModelContent] = []
        for msg in relevant {
            let role = msg.role == .user ? "user" : "model"
            let text: String
            if msg.role == .assistant {
                text = """
                {"templateName":"","slots":[],"reply":"\(msg.text.replacingOccurrences(of: "\"", with: "\\\""))","isComplete":false}
                """
            } else {
                text = msg.text
            }
            contents.append(ModelContent(role: role, parts: [.text(text)]))
        }
        return contents
    }

    static func parseTemplateIntent(_ text: String) throws -> AITemplateIntent {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PostGeneratorError.invalidResponse
        }

        let reply = json["reply"] as? String
            ?? "I'm not sure I understand. Could you describe the post you want?"
        let isComplete = json["isComplete"] as? Bool ?? false
        let templateName = json["templateName"] as? String ?? "Untitled"

        let rawSlots = json["slots"] as? [[String: Any]] ?? []
        let slots = rawSlots.map { s in
            AISlotDefinition(
                name: s["name"] as? String ?? "Slide",
                pillarNames: s["pillarNames"] as? [String] ?? [],
                cadrageNames: s["cadrageNames"] as? [String] ?? [],
                locations: s["locations"] as? [String] ?? [],
                about: s["about"] as? String ?? "",
                startDate: s["startDate"] as? String,
                endDate: s["endDate"] as? String
            )
        }

        return AITemplateIntent(
            templateName: templateName,
            slots: slots,
            reply: reply,
            isComplete: isComplete
        )
    }

    static func parsePostIntent(_ text: String) throws -> AIPostIntent {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PostGeneratorError.invalidResponse
        }

        let reply = json["reply"] as? String
            ?? "I'm not sure I understand. Could you describe the post you want?"
        let isComplete = json["isComplete"] as? Bool ?? false

        var filters = PostFilters()
        if let f = json["filters"] as? [String: Any] {
            filters.pillarNames = (f["pillarNames"] as? [String]) ?? []
            filters.locations = (f["locations"] as? [String]) ?? []
            filters.count = f["count"] as? Int
            filters.mood = f["mood"] as? String

            let iso = ISO8601DateFormatter()
            if let s = f["startDate"] as? String { filters.startDate = iso.date(from: s) }
            if let e = f["endDate"] as? String { filters.endDate = iso.date(from: e) }
        }

        return AIPostIntent(filters: filters, reply: reply, isComplete: isComplete)
    }

    static func parseStringArray(_ text: String) -> [String]? {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            return nil
        }
        return array
    }

    static func describeError(_ error: GenerateContentError) -> String {
        switch error {
        case .internalError(let underlying):
            "Internal error: \(underlying.localizedDescription)"
        case .promptBlocked:
            "Prompt was blocked by safety filters. Try rephrasing."
        case .responseStoppedEarly(let reason, _):
            "Response stopped early: \(reason)"
        case .promptImageContentError(let underlying):
            "Image error: \(underlying.localizedDescription)"
        case .invalidAPIKey(let message):
            "Invalid API key: \(message)"
        case .unsupportedUserLocation:
            "Gemini API is not available in your region."
        @unknown default:
            "Unknown Gemini error."
        }
    }
}

private enum PostGeneratorError: LocalizedError {
    case missingAPIKey
    case noResponse
    case invalidResponse
    case geminiError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: "Gemini API key not configured. Add it to Secrets.xcconfig."
        case .noResponse: "No response from Gemini."
        case .invalidResponse: "Couldn't parse Gemini's response."
        case .geminiError(let detail): detail
        }
    }
}
