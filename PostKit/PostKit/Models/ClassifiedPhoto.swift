// MARK: - PostKit
// ClassifiedPhoto.swift — ClassifiedPhoto SwiftData model

import Foundation
import os
import SwiftData

private let modelLogger = Logger(subsystem: "PostKit", category: "Models")

@Model
final class ClassifiedPhoto {
    var id: UUID
    var assetLocalIdentifier: String
    var pillarID: UUID?
    var pillarIDsData: Data?
    var confidence: Float
    var classifiedByAI: Bool
    var tagsData: Data?
    var location: String?
    var capturedAt: Date?
    var statusRaw: String
    var cadrageRaw: String? = nil

    var pillarIDs: [UUID] {
        get {
            guard let data = pillarIDsData else { return [] }
            do { return try JSONDecoder().decode([UUID].self, from: data) }
            catch { modelLogger.error("ClassifiedPhoto.pillarIDs decode failed: \(error)"); return [] }
        }
        set {
            pillarIDsData = try? JSONEncoder().encode(newValue)
        }
    }

    var tags: [String] {
        get {
            guard let data = tagsData else { return [] }
            do { return try JSONDecoder().decode([String].self, from: data) }
            catch { modelLogger.error("ClassifiedPhoto.tags decode failed: \(error)"); return [] }
        }
        set {
            tagsData = try? JSONEncoder().encode(newValue)
        }
    }

    var status: PhotoStatus {
        get { PhotoStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var cadrage: Cadrage? {
        get { cadrageRaw.flatMap { Cadrage(rawValue: $0) } }
        set { cadrageRaw = newValue?.rawValue }
    }

    enum PhotoStatus: String, Codable, Sendable {
        case pending, classified, rejected
    }

    init(
        assetLocalIdentifier: String,
        pillarID: UUID? = nil,
        pillarIDs: [UUID] = [],
        confidence: Float = 0,
        classifiedByAI: Bool = true,
        tags: [String] = [],
        location: String? = nil,
        capturedAt: Date? = nil,
        status: PhotoStatus = .pending,
        cadrage: Cadrage? = nil
    ) {
        self.id = UUID()
        self.assetLocalIdentifier = assetLocalIdentifier
        self.pillarID = pillarID
        self.pillarIDsData = try? JSONEncoder().encode(pillarIDs)
        self.confidence = confidence
        self.classifiedByAI = classifiedByAI
        self.tagsData = try? JSONEncoder().encode(tags)
        self.location = location
        self.capturedAt = capturedAt
        self.statusRaw = status.rawValue
        self.cadrageRaw = cadrage?.rawValue
    }
}
