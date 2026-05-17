import Foundation
import SwiftData

enum Cadrage: String, Codable, CaseIterable, Sendable {
    case any, wide, detail, portrait, pov

    var displayName: String {
        switch self {
        case .any: "Any"
        case .wide: "Wide"
        case .detail: "Detail"
        case .portrait: "Portrait"
        case .pov: "POV"
        }
    }

    var initial: String {
        switch self {
        case .any: "?"
        case .wide: "W"
        case .detail: "D"
        case .portrait: "P"
        case .pov: "POV"
        }
    }
}

@Model
final class PostTemplate {
    var id: UUID
    var name: String
    var about: String
    var slotsData: Data?
    var createdAt: Date

    var slots: [TemplateSlotData] {
        get {
            guard let data = slotsData else { return [] }
            return (try? JSONDecoder().decode([TemplateSlotData].self, from: data)) ?? []
        }
        set {
            slotsData = try? JSONEncoder().encode(newValue)
        }
    }

    init(name: String, about: String = "", slots: [TemplateSlotData] = []) {
        self.id = UUID()
        self.name = name
        self.about = about
        self.slotsData = try? JSONEncoder().encode(slots)
        self.createdAt = .now
    }
}

struct TemplateSlotData: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var cadrage: Cadrage
    var pillarName: String?
    var about: String

    init(
        id: UUID = UUID(),
        name: String = "Slot",
        cadrage: Cadrage = .any,
        pillarName: String? = nil,
        about: String = ""
    ) {
        self.id = id
        self.name = name
        self.cadrage = cadrage
        self.pillarName = pillarName
        self.about = about
    }
}
