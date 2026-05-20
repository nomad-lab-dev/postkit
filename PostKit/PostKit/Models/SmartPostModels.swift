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
}

func resolveTemplateIntent(
    _ intent: AITemplateIntent,
    pillars: [PillarSnapshot],
    uuidGenerator: () -> UUID
) -> TemplateSnapshot {
    let pillarLookup = Dictionary(
        pillars.map { ($0.name.lowercased(), $0.id) },
        uniquingKeysWith: { first, _ in first }
    )

    let iso = ISO8601DateFormatter()
    var allLocations: [String] = []
    let slots = intent.slots.map { slot in
        let pillarIDs = slot.pillarNames.compactMap { pillarLookup[$0.lowercased()] }
        let cadrages = slot.cadrageNames.compactMap { Cadrage(rawValue: $0.lowercased()) }
        allLocations.append(contentsOf: slot.locations)

        return TemplateSlotData(
            id: uuidGenerator(),
            name: slot.name,
            cadrages: cadrages,
            pillarIDs: pillarIDs,
            locations: slot.locations,
            about: slot.about,
            startDate: slot.startDate.flatMap { iso.date(from: $0) },
            endDate: slot.endDate.flatMap { iso.date(from: $0) }
        )
    }

    return TemplateSnapshot(
        id: uuidGenerator(),
        name: intent.templateName,
        slots: slots,
        locations: Array(Set(allLocations)).sorted()
    )
}
