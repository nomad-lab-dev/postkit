// MARK: - PostKit
// Pillar.swift — Pillar SwiftData model and PillarTone enum

import Foundation
import SwiftData

enum PillarTone: String, Codable, CaseIterable, Sendable {
    case casual, technical, inspirational
}

@Model
final class Pillar {
    var id: UUID
    var name: String
    var emoji: String
    var about: String
    var tone: PillarTone
    var topicsData: Data?
    var postsPerWeek: Int
    var colorHex: String
    var createdAt: Date

    var topics: [String] {
        get {
            guard let data = topicsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            topicsData = try? JSONEncoder().encode(newValue)
        }
    }

    init(name: String, emoji: String) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.about = ""
        self.tone = .casual
        self.topicsData = nil
        self.postsPerWeek = 3
        self.colorHex = "#8b5cf6"
        self.createdAt = .now
    }
}
