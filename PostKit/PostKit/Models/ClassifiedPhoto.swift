import Foundation
import SwiftData

@Model
final class ClassifiedPhoto {
    var id: UUID
    var assetLocalIdentifier: String
    var pillarID: UUID?
    var confidence: Float
    var classifiedByAI: Bool
    var tags: [String]
    var location: String?
    var capturedAt: Date?
    var status: PhotoStatus

    enum PhotoStatus: String, Codable, Sendable {
        case pending, classified, rejected
    }

    init(
        assetLocalIdentifier: String,
        pillarID: UUID? = nil,
        confidence: Float = 0,
        classifiedByAI: Bool = true,
        tags: [String] = [],
        location: String? = nil,
        capturedAt: Date? = nil,
        status: PhotoStatus = .pending
    ) {
        self.id = UUID()
        self.assetLocalIdentifier = assetLocalIdentifier
        self.pillarID = pillarID
        self.confidence = confidence
        self.classifiedByAI = classifiedByAI
        self.tags = tags
        self.location = location
        self.capturedAt = capturedAt
        self.status = status
    }
}
