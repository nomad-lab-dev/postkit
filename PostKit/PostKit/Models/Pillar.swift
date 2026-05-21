// MARK: - PostKit
// Pillar.swift — Pillar SwiftData model and PillarTone enum

import Foundation
import os
import SwiftData

private let modelLogger = Logger(subsystem: "PostKit", category: "Models")

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
            do { return try JSONDecoder().decode([String].self, from: data) }
            catch { modelLogger.error("Pillar.topics decode failed: \(error)"); return [] }
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
