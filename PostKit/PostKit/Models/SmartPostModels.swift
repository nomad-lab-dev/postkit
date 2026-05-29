// MARK: - PostKit
// SmartPostModels.swift — AI intent models and template resolution for smart post creation

import Foundation

struct ChatMessage: Equatable, Identifiable, Sendable {
    let id: UUID
    let role: Role
    let text: String
    let timestamp: Date

    enum Role: Equatable, Sendable {
        case user
        case assistant
    }

    init(id: UUID = UUID(), role: Role, text: String, timestamp: Date = .now) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }

    // Equality based on content, not identity — id is for SwiftUI ForEach, timestamp for display.
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.role == rhs.role && lhs.text == rhs.text
    }
}

struct PostFilters: Equatable, Sendable {
    var pillarNames: [String] = []
    var locations: [String] = []
    var startDate: Date? = nil
    var endDate: Date? = nil
    var count: Int? = nil
    var mood: String? = nil
}

struct AIPostIntent: Equatable, Sendable {
    let filters: PostFilters
    let reply: String
    let isComplete: Bool
}

// MARK: - Template Intent (SmartPost refactor)

struct AISlotDefinition: Equatable, Sendable {
    let name: String
    let pillarNames: [String]
    let cadrageNames: [String]
    let locations: [String]
    let about: String
    let startDate: String?
    let endDate: String?
}

struct AITemplateIntent: Equatable, Sendable {
    let templateName: String
    let slots: [AISlotDefinition]
    let reply: String
    let isComplete: Bool
    let quickReplies: [String]
}

func resolveTemplateIntent(
    _ intent: AITemplateIntent,
    pillars: [PillarSnapshot],
    availableLocations: [String] = [],
    uuidGenerator: () -> UUID,
    createdAt: Date = .now
) -> TemplateSnapshot {
    let pillarLookup = Dictionary(
        pillars.map { ($0.name.lowercased(), $0.id) },
        uniquingKeysWith: { first, _ in first }
    )
    let locationAllowlist = availableLocations.isEmpty ? nil : Set(availableLocations)

    var allLocations: [String] = []
    let slots = intent.slots.map { slot in
        let pillarIDs = slot.pillarNames.compactMap { name -> UUID? in
                let cleaned = name.unicodeScalars
                    .drop(while: { !CharacterSet.letters.contains($0) })
                    .reduce(into: "") { $0.unicodeScalars.append($1) }
                    .trimmingCharacters(in: .whitespaces)
                return pillarLookup[cleaned.lowercased()] ?? pillarLookup[name.lowercased()]
            }
        let cadrages = slot.cadrageNames.compactMap { Cadrage(rawValue: $0.lowercased()) }
        // Only keep locations the user actually has photos for
        let locations = locationAllowlist == nil
            ? slot.locations
            : slot.locations.filter { locationAllowlist!.contains($0) }
        allLocations.append(contentsOf: locations)

        return TemplateSlotData(
            id: uuidGenerator(),
            name: slot.name,
            cadrages: cadrages,
            pillarIDs: pillarIDs,
            locations: locations,
            about: slot.about,
            startDate: nil,
            endDate: nil
        )
    }

    return TemplateSnapshot(
        id: uuidGenerator(),
        name: intent.templateName,
        slots: slots,
        locations: Array(Set(allLocations)).sorted(),
        createdAt: createdAt
    )
}
