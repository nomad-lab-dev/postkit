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
    var referencePhotoIDsData: Data?
    var referenceTagsData: Data?

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

    var referencePhotoIDs: [String] {
        get {
            guard let data = referencePhotoIDsData else { return [] }
            do { return try JSONDecoder().decode([String].self, from: data) }
            catch { modelLogger.error("Pillar.referencePhotoIDs decode failed: \(error)"); return [] }
        }
        set {
            referencePhotoIDsData = try? JSONEncoder().encode(newValue)
        }
    }

    var referenceTags: [String] {
        get {
            guard let data = referenceTagsData else { return [] }
            do { return try JSONDecoder().decode([String].self, from: data) }
            catch { modelLogger.error("Pillar.referenceTags decode failed: \(error)"); return [] }
        }
        set {
            referenceTagsData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        name: String,
        emoji: String,
        about: String = "",
        tone: PillarTone = .casual,
        topics: [String] = [],
        referencePhotoIDs: [String] = [],
        referenceTags: [String] = [],
        colorHex: String = "#8b5cf6"
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.about = about
        self.tone = tone
        self.topicsData = try? JSONEncoder().encode(topics)
        self.referencePhotoIDsData = try? JSONEncoder().encode(referencePhotoIDs)
        self.referenceTagsData = try? JSONEncoder().encode(referenceTags)
        self.postsPerWeek = 3
        self.colorHex = colorHex
        self.createdAt = .now
    }
}
