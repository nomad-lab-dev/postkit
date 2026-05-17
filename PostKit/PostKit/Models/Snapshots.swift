import Foundation

struct PillarSnapshot: Equatable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var emoji: String
    var photoCount: Int
    var postsPerWeek: Int
    var colorHex: String

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        colorHex: String = "#8b5cf6",
        photoCount: Int = 0,
        postsPerWeek: Int = 3
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.photoCount = photoCount
        self.postsPerWeek = postsPerWeek
    }

    init(_ pillar: Pillar, photoCount: Int = 0) {
        self.id = pillar.id
        self.name = pillar.name
        self.emoji = pillar.emoji
        self.photoCount = photoCount
        self.postsPerWeek = pillar.postsPerWeek
        self.colorHex = pillar.colorHex
    }
}

struct ClassifiedPhotoSnapshot: Equatable, Identifiable, Sendable {
    let id: UUID
    var assetLocalIdentifier: String
    var pillarID: UUID?
    var confidence: Float
    var classifiedByAI: Bool
    var tags: [String]
    var location: String?
    var capturedAt: Date?
    var status: ClassifiedPhoto.PhotoStatus

    init(
        id: UUID = UUID(),
        assetLocalIdentifier: String,
        pillarID: UUID? = nil,
        confidence: Float = 0,
        classifiedByAI: Bool = true,
        tags: [String] = [],
        location: String? = nil,
        capturedAt: Date? = nil,
        status: ClassifiedPhoto.PhotoStatus = .pending
    ) {
        self.id = id
        self.assetLocalIdentifier = assetLocalIdentifier
        self.pillarID = pillarID
        self.confidence = confidence
        self.classifiedByAI = classifiedByAI
        self.tags = tags
        self.location = location
        self.capturedAt = capturedAt
        self.status = status
    }

    init(_ photo: ClassifiedPhoto) {
        self.id = photo.id
        self.assetLocalIdentifier = photo.assetLocalIdentifier
        self.pillarID = photo.pillarID
        self.confidence = photo.confidence
        self.classifiedByAI = photo.classifiedByAI
        self.tags = photo.tags
        self.location = photo.location
        self.capturedAt = photo.capturedAt
        self.status = photo.status
    }
}

struct GeneratedPostSnapshot: Equatable, Identifiable, Sendable {
    let id: UUID
    var pillarID: UUID
    var photoIDs: [String]
    var caption: String
    var hashtags: [String]
    var platform: SocialPlatform
    var status: PostStatus
    var createdAt: Date

    init(
        id: UUID = UUID(),
        pillarID: UUID,
        photoIDs: [String] = [],
        caption: String = "",
        hashtags: [String] = [],
        platform: SocialPlatform = .instagram,
        status: PostStatus = .draft,
        createdAt: Date = .now
    ) {
        self.id = id
        self.pillarID = pillarID
        self.photoIDs = photoIDs
        self.caption = caption
        self.hashtags = hashtags
        self.platform = platform
        self.status = status
        self.createdAt = createdAt
    }

    init(_ post: GeneratedPost) {
        self.id = post.id
        self.pillarID = post.pillarID
        self.photoIDs = post.photoIDs
        self.caption = post.caption
        self.hashtags = post.hashtags
        self.platform = post.platform
        self.status = post.status
        self.createdAt = post.createdAt
    }
}
