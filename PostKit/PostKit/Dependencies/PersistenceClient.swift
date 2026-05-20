import ComposableArchitecture
import Foundation
import SwiftData

@DependencyClient
struct PersistenceClient: Sendable {
    var savePillar: @Sendable (_ snapshot: PillarSnapshot) async throws -> Void
    var fetchPillars: @Sendable () async throws -> [PillarSnapshot]
    var deletePillar: @Sendable (_ id: UUID) async throws -> Void
    var savePhoto: @Sendable (_ snapshot: ClassifiedPhotoSnapshot) async throws -> Void
    var fetchPhotos: @Sendable (_ status: ClassifiedPhoto.PhotoStatus?) async throws -> [ClassifiedPhotoSnapshot]
    var fetchPhotosForPillar: @Sendable (_ pillarID: UUID) async throws -> [ClassifiedPhotoSnapshot]
    var countPhotosPerPillar: @Sendable () async throws -> [UUID: Int]
    var fetchClassifiedAssetIDs: @Sendable () async throws -> Set<String>
    var batchSavePhotos: @Sendable (_ snapshots: [ClassifiedPhotoSnapshot]) async throws -> Void
    var savePost: @Sendable (_ snapshot: GeneratedPostSnapshot) async throws -> Void
    var fetchPosts: @Sendable (_ pillarID: UUID?) async throws -> [GeneratedPostSnapshot]
    var deletePost: @Sendable (_ id: UUID) async throws -> Void
    var saveTemplate: @Sendable (_ snapshot: TemplateSnapshot) async throws -> Void
    var fetchTemplates: @Sendable () async throws -> [TemplateSnapshot]
    var deleteTemplate: @Sendable (_ id: UUID) async throws -> Void
    var updateTemplateLastPostedAt: @Sendable (_ templateID: UUID, _ date: Date) async throws -> Void
}

extension PersistenceClient: DependencyKey {
    static let liveValue = PersistenceClient()
    static let previewValue = PersistenceClient()

    static func live(container: ModelContainer) -> PersistenceClient {
        PersistenceClient(
            savePillar: { snapshot in
                try await MainActor.run {
                    let context = container.mainContext
                    let pillar = Pillar(name: snapshot.name, emoji: snapshot.emoji)
                    context.insert(pillar)
                    try context.save()
                }
            },
            fetchPillars: {
                try await MainActor.run {
                    let context = container.mainContext
                    var descriptor = FetchDescriptor<Pillar>(
                        sortBy: [SortDescriptor(\.createdAt)]
                    )
                    descriptor.fetchLimit = 100
                    let pillars = try context.fetch(descriptor)
                    return pillars.map { PillarSnapshot($0) }
                }
            },
            deletePillar: { id in
                try await MainActor.run {
                    let context = container.mainContext
                    var descriptor = FetchDescriptor<Pillar>(
                        predicate: #Predicate { $0.id == id }
                    )
                    descriptor.fetchLimit = 1
                    if let pillar = try context.fetch(descriptor).first {
                        context.delete(pillar)
                        try context.save()
                    }
                }
            },
            savePhoto: { snapshot in
                try await MainActor.run {
                    let context = container.mainContext
                    let assetID = snapshot.assetLocalIdentifier
                    var descriptor = FetchDescriptor<ClassifiedPhoto>(
                        predicate: #Predicate { $0.assetLocalIdentifier == assetID }
                    )
                    descriptor.fetchLimit = 1
                    if let existing = try context.fetch(descriptor).first {
                        existing.pillarID = snapshot.pillarID
                        existing.pillarIDs = snapshot.pillarIDs
                        existing.confidence = snapshot.confidence
                        existing.classifiedByAI = snapshot.classifiedByAI
                        existing.tags = snapshot.tags
                        existing.location = snapshot.location
                        existing.capturedAt = snapshot.capturedAt
                        existing.status = snapshot.status
                        existing.cadrage = snapshot.cadrage
                    } else {
                        let photo = ClassifiedPhoto(
                            assetLocalIdentifier: snapshot.assetLocalIdentifier,
                            pillarID: snapshot.pillarID,
                            pillarIDs: snapshot.pillarIDs,
                            confidence: snapshot.confidence,
                            classifiedByAI: snapshot.classifiedByAI,
                            tags: snapshot.tags,
                            location: snapshot.location,
                            capturedAt: snapshot.capturedAt,
                            status: snapshot.status,
                            cadrage: snapshot.cadrage
                        )
                        context.insert(photo)
                    }
                    try context.save()
                }
            },
            fetchPhotos: { status in
                try await MainActor.run {
                    let context = container.mainContext
                    var descriptor: FetchDescriptor<ClassifiedPhoto>
                    if let status {
                        let rawStatus = status.rawValue
                        descriptor = FetchDescriptor<ClassifiedPhoto>(
                            predicate: #Predicate { $0.statusRaw == rawStatus }
                        )
                    } else {
                        descriptor = FetchDescriptor<ClassifiedPhoto>()
                    }
                    let photos = try context.fetch(descriptor)
                    return photos.map { ClassifiedPhotoSnapshot($0) }
                }
            },
            fetchPhotosForPillar: { pillarID in
                try await MainActor.run {
                    let context = container.mainContext
                    let descriptor = FetchDescriptor<ClassifiedPhoto>(
                        predicate: #Predicate { $0.pillarID == pillarID }
                    )
                    let photos = try context.fetch(descriptor)
                    return photos.map { ClassifiedPhotoSnapshot($0) }
                }
            },
            countPhotosPerPillar: {
                try await MainActor.run {
                    let context = container.mainContext
                    let descriptor = FetchDescriptor<ClassifiedPhoto>(
                        predicate: #Predicate { $0.pillarID != nil }
                    )
                    let photos = try context.fetch(descriptor)
                    var counts: [UUID: Int] = [:]
                    for photo in photos {
                        if let pid = photo.pillarID {
                            counts[pid, default: 0] += 1
                        }
                    }
                    return counts
                }
            },
            fetchClassifiedAssetIDs: {
                try await MainActor.run {
                    let context = container.mainContext
                    let descriptor = FetchDescriptor<ClassifiedPhoto>()
                    let photos = try context.fetch(descriptor)
                    return Set(photos.map(\.assetLocalIdentifier))
                }
            },
            batchSavePhotos: { snapshots in
                guard !snapshots.isEmpty else { return }
                try await MainActor.run {
                    let context = container.mainContext
                    for snapshot in snapshots {
                        let assetID = snapshot.assetLocalIdentifier
                        var descriptor = FetchDescriptor<ClassifiedPhoto>(
                            predicate: #Predicate { $0.assetLocalIdentifier == assetID }
                        )
                        descriptor.fetchLimit = 1
                        if let existing = try context.fetch(descriptor).first {
                            existing.pillarID = snapshot.pillarID
                            existing.pillarIDs = snapshot.pillarIDs
                            existing.confidence = snapshot.confidence
                            existing.classifiedByAI = snapshot.classifiedByAI
                            existing.tags = snapshot.tags
                            existing.location = snapshot.location
                            existing.capturedAt = snapshot.capturedAt
                            existing.status = snapshot.status
                            existing.cadrage = snapshot.cadrage
                        } else {
                            let photo = ClassifiedPhoto(
                                assetLocalIdentifier: snapshot.assetLocalIdentifier,
                                pillarID: snapshot.pillarID,
                                pillarIDs: snapshot.pillarIDs,
                                confidence: snapshot.confidence,
                                classifiedByAI: snapshot.classifiedByAI,
                                tags: snapshot.tags,
                                location: snapshot.location,
                                capturedAt: snapshot.capturedAt,
                                status: snapshot.status,
                                cadrage: snapshot.cadrage
                            )
                            context.insert(photo)
                        }
                    }
                    try context.save()
                }
            },
            savePost: { snapshot in
                try await MainActor.run {
                    let context = container.mainContext
                    let post = GeneratedPost(
                        title: snapshot.title,
                        pillarID: snapshot.pillarID,
                        templateID: snapshot.templateID,
                        photoIDs: snapshot.photoIDs,
                        caption: snapshot.caption,
                        hashtags: snapshot.hashtags,
                        platform: snapshot.platform,
                        status: snapshot.status,
                        isAutoGenerated: snapshot.isAutoGenerated
                    )
                    context.insert(post)
                    try context.save()
                }
            },
            fetchPosts: { pillarID in
                try await MainActor.run {
                    let context = container.mainContext
                    var descriptor: FetchDescriptor<GeneratedPost>
                    if let pillarID {
                        descriptor = FetchDescriptor<GeneratedPost>(
                            predicate: #Predicate { $0.pillarID == pillarID },
                            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                        )
                    } else {
                        descriptor = FetchDescriptor<GeneratedPost>(
                            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                        )
                    }
                    let posts = try context.fetch(descriptor)
                    return posts.map { GeneratedPostSnapshot($0) }
                }
            },
            deletePost: { id in
                try await MainActor.run {
                    let context = container.mainContext
                    var descriptor = FetchDescriptor<GeneratedPost>(
                        predicate: #Predicate { $0.id == id }
                    )
                    descriptor.fetchLimit = 1
                    if let post = try context.fetch(descriptor).first {
                        context.delete(post)
                        try context.save()
                    }
                }
            },
            saveTemplate: { snapshot in
                try await MainActor.run {
                    let context = container.mainContext
                    let id = snapshot.id
                    var descriptor = FetchDescriptor<PostTemplate>(
                        predicate: #Predicate { $0.id == id }
                    )
                    descriptor.fetchLimit = 1
                    if let existing = try context.fetch(descriptor).first {
                        existing.name = snapshot.name
                        existing.about = snapshot.about
                        existing.slots = snapshot.slots
                        existing.locations = snapshot.locations
                        existing.schedule = snapshot.schedule
                        existing.lastPostedAt = snapshot.lastPostedAt
                    } else {
                        let template = PostTemplate(
                            name: snapshot.name,
                            about: snapshot.about,
                            slots: snapshot.slots,
                            locations: snapshot.locations,
                            schedule: snapshot.schedule
                        )
                        context.insert(template)
                    }
                    try context.save()
                }
            },
            fetchTemplates: {
                try await MainActor.run {
                    let context = container.mainContext
                    let descriptor = FetchDescriptor<PostTemplate>(
                        sortBy: [SortDescriptor(\.createdAt)]
                    )
                    let templates = try context.fetch(descriptor)
                    return templates.map { TemplateSnapshot($0) }
                }
            },
            deleteTemplate: { id in
                try await MainActor.run {
                    let context = container.mainContext
                    var descriptor = FetchDescriptor<PostTemplate>(
                        predicate: #Predicate { $0.id == id }
                    )
                    descriptor.fetchLimit = 1
                    if let template = try context.fetch(descriptor).first {
                        context.delete(template)
                        try context.save()
                    }
                }
            },
            updateTemplateLastPostedAt: { templateID, date in
                try await MainActor.run {
                    let context = container.mainContext
                    var descriptor = FetchDescriptor<PostTemplate>(
                        predicate: #Predicate { $0.id == templateID }
                    )
                    descriptor.fetchLimit = 1
                    if let template = try context.fetch(descriptor).first {
                        template.lastPostedAt = date
                        try context.save()
                    }
                }
            }
        )
    }
}

extension DependencyValues {
    var persistence: PersistenceClient {
        get { self[PersistenceClient.self] }
        set { self[PersistenceClient.self] = newValue }
    }
}
