// MARK: - PostKit
// Cadrage.swift — Cadrage enum, Weekday, TemplateSchedule, PostTemplate SwiftData model, and TemplateSlotData

import Foundation
import SwiftData

enum Cadrage: String, Codable, CaseIterable, Sendable {
    case any, wide, detail, portrait, pov, screenshot

    var displayName: String {
        switch self {
        case .any: "Any"
        case .wide: "Wide"
        case .detail: "Detail"
        case .portrait: "Portrait"
        case .pov: "POV"
        case .screenshot: "Screenshot"
        }
    }

    var initial: String {
        switch self {
        case .any: "?"
        case .wide: "W"
        case .detail: "D"
        case .portrait: "P"
        case .pov: "POV"
        case .screenshot: "SS"
        }
    }

    static var detectableCases: [Cadrage] {
        [.wide, .detail, .portrait, .pov, .screenshot]
    }
}

enum Weekday: Int, Codable, CaseIterable, Identifiable, Sendable, Comparable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        case .sunday: "Sun"
        }
    }

    var initial: String {
        String(shortName.prefix(1))
    }

    /// Maps `Calendar.component(.weekday)` (1=Sun…7=Sat) to our enum (1=Mon…7=Sun).
    static func current(from date: Date, calendar: Calendar = .current) -> Weekday {
        let w = calendar.component(.weekday, from: date)
        let mondayBased = w == 1 ? 7 : w - 1
        return Weekday(rawValue: mondayBased) ?? .monday
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct TemplateSchedule: Codable, Equatable, Sendable {
    var weekdays: Set<Weekday>
    var reminderEnabled: Bool

    var isEmpty: Bool { weekdays.isEmpty }

    init(weekdays: Set<Weekday> = [], reminderEnabled: Bool = true) {
        self.weekdays = weekdays
        self.reminderEnabled = reminderEnabled
    }
}

@Model
final class PostTemplate {
    var id: UUID
    var name: String
    var about: String
    var slotsData: Data?
    var locationsData: Data?
    var scheduleData: Data?
    var lastPostedAt: Date?
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

    var locations: [String] {
        get {
            guard let data = locationsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            locationsData = try? JSONEncoder().encode(newValue)
        }
    }

    var schedule: TemplateSchedule {
        get {
            guard let data = scheduleData else { return TemplateSchedule() }
            return (try? JSONDecoder().decode(TemplateSchedule.self, from: data)) ?? TemplateSchedule()
        }
        set {
            scheduleData = try? JSONEncoder().encode(newValue)
        }
    }

    init(name: String, about: String = "", slots: [TemplateSlotData] = [], locations: [String] = [], schedule: TemplateSchedule = TemplateSchedule()) {
        self.id = UUID()
        self.name = name
        self.about = about
        self.slotsData = try? JSONEncoder().encode(slots)
        self.locationsData = try? JSONEncoder().encode(locations)
        self.scheduleData = try? JSONEncoder().encode(schedule)
        self.createdAt = .now
    }
}

struct TemplateSlotData: Equatable, Identifiable, Sendable, Codable {
    var id: UUID
    var name: String
    var cadrages: [Cadrage]
    var pillarIDs: [UUID]
    var locations: [String]
    var about: String
    var startDate: Date?
    var endDate: Date?

    var preferredAspectRatio: CGFloat {
        cadrages == [.portrait] ? 3.0 / 4.0 : 4.0 / 3.0
    }

    init(
        id: UUID = UUID(),
        name: String = "Slot",
        cadrages: [Cadrage] = [],
        pillarIDs: [UUID] = [],
        locations: [String] = [],
        about: String = "",
        startDate: Date? = nil,
        endDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.cadrages = cadrages
        self.pillarIDs = pillarIDs
        self.locations = locations
        self.about = about
        self.startDate = startDate
        self.endDate = endDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        cadrages = try container.decode([Cadrage].self, forKey: .cadrages)
        pillarIDs = try container.decode([UUID].self, forKey: .pillarIDs)
        locations = try container.decodeIfPresent([String].self, forKey: .locations) ?? []
        about = try container.decode(String.self, forKey: .about)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
    }
}
