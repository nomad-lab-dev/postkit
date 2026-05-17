import Foundation
import SwiftData

enum SocialPlatform: String, Codable, CaseIterable, Sendable {
    case instagram, linkedin, twitter

    var displayName: String { rawValue.capitalized }

    var characterLimit: Int {
        switch self {
        case .instagram: 2200
        case .linkedin: 3000
        case .twitter: 280
        }
    }
}

enum PostStatus: String, Codable, CaseIterable, Sendable {
    case draft, ready, published
}

@Model
final class GeneratedPost {
    var id: UUID
    var pillarID: UUID
    var photoIDs: [String]
    var caption: String
    var hashtags: [String]
    var platform: SocialPlatform
    var status: PostStatus
    var createdAt: Date

    init(
        pillarID: UUID,
        photoIDs: [String],
        caption: String = "",
        hashtags: [String] = [],
        platform: SocialPlatform = .instagram,
        status: PostStatus = .draft,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.pillarID = pillarID
        self.photoIDs = photoIDs
        self.caption = caption
        self.hashtags = hashtags
        self.platform = platform
        self.status = status
        self.createdAt = createdAt
    }
}
