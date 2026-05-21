// MARK: - PostKit
// PersistenceClient.swift — SwiftData persistence dependency client

import ComposableArchitecture
import Foundation
import os
import SwiftData

private let log = Logger(subsystem: "PostKit", category: "Persistence")

@DependencyClient
struct PersistenceClient: Sendable {
    var savePillar: @Sendable (_ snapshot: PillarSnapshot) async throws -> Void
    var fetchPillars: @Sendable () async throws -> [PillarSnapshot]
    var deletePillar: @Sendable (_ id: UUID) async throws -> Void
    var savePhoto: @Sendable (_ snapshot: ClassifiedPhotoSnapshot) async throws -> Void
    var fetchPhotos: @Sendable (_ status: ClassifiedPhoto.PhotoStatus?) async throws -> [ClassifiedPhotoSnapshot]
    var fetchPhotosPaginated: @Sendable (_ status: ClassifiedPhoto.PhotoStatus?, _ limit: Int, _ offset: Int) async throws -> [ClassifiedPhotoSnapshot]
    var countPhotos: @Sendable (_ status: ClassifiedPhoto.PhotoStatus?) async throws -> Int = { _ in 0 }
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

            // MARK: - Pillars (UI-driven, mainContext is fine)

            savePillar: { snapshot in
                try await MainActor.run {
                    let context = container.mainContext
                    let id = snapshot.id
                    var descriptor = FetchDescriptor<Pillar>(
                        predicate: #Predicate { $0.id == id }
                    )
                    descriptor.fetchLimit = 1
                    if let existing = try context.fetch(descriptor).first {
                        existing.name = snapshot.name
                        existing.emoji = snapshot.emoji
                        existing.about = snapshot.about
                        existing.tone = snapshot.tone
                        existing.topics = snapshot.topics
                        existing.referenceTags = snapshot.referenceTags
                        existing.referencePhotoIDs = snapshot.referencePhotoIDs
                        existing.colorHex = snapshot.colorHex
                        existing.postsPerWeek = snapshot.postsPerWeek
                    } else {
                        let pillar = Pillar(
                            name: snapshot.name,
                            emoji: snapshot.emoji,
                            about: snapshot.about,
                            tone: snapshot.tone,
                            topics: snapshot.topics,
                            referencePhotoIDs: snapshot.referencePhotoIDs,
                            referenceTags: snapshot.referenceTags,
                            colorHex: snapshot.colorHex
                        )
                        context.insert(pillar)
                    }
                    try context.save()
                }
            },
            fetchPillars: {
                log.info("⏳ fetchPillars — MainActor")
                return try await MainActor.run {
                    let context = container.mainContext
                    var descriptor = FetchDescriptor<Pillar>(
                        sortBy: [SortDescriptor(\.createdAt)]
                    )
                    descriptor.fetchLimit = 100
                    let pillars = try context.fetch(descriptor)
                    log.info("✅ fetchPillars — \(pillars.count) pillars")
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

            // MARK: - Photos (single save uses mainContext)

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
                log.info("⏳ fetchPhotos(status=\(status?.rawValue ?? "nil")) — background context")
                let context = ModelContext(container)
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
                log.info("✅ fetchPhotos(status=\(status?.rawValue ?? "nil")) — \(photos.count) photos")
                return photos.map { ClassifiedPhotoSnapshot($0) }
            },
            fetchPhotosPaginated: { status, limit, offset in
                log.info("⏳ fetchPhotosPaginated(status=\(status?.rawValue ?? "nil"), limit=\(limit), offset=\(offset))")
                let context = ModelContext(container)
                var descriptor: FetchDescriptor<ClassifiedPhoto>
                if let status {
                    let rawStatus = status.rawValue
                    descriptor = FetchDescriptor<ClassifiedPhoto>(
                        predicate: #Predicate { $0.statusRaw == rawStatus },
                        sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
                    )
                } else {
                    descriptor = FetchDescriptor<ClassifiedPhoto>(
                        sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
                    )
                }
                descriptor.fetchLimit = limit
                descriptor.fetchOffset = offset
                let photos = try context.fetch(descriptor)
                log.info("✅ fetchPhotosPaginated — \(photos.count) photos returned")
                return photos.map { ClassifiedPhotoSnapshot($0) }
            },
            countPhotos: { status in
                log.info("⏳ countPhotos(status=\(status?.rawValue ?? "nil"))")
                let context = ModelContext(container)
                var descriptor: FetchDescriptor<ClassifiedPhoto>
                if let status {
                    let rawStatus = status.rawValue
                    descriptor = FetchDescriptor<ClassifiedPhoto>(
                        predicate: #Predicate { $0.statusRaw == rawStatus }
                    )
                } else {
                    descriptor = FetchDescriptor<ClassifiedPhoto>()
                }
                let count = try context.fetchCount(descriptor)
                log.info("✅ countPhotos — \(count)")
                return count
            },
            fetchPhotosForPillar: { pillarID in
                let context = ModelContext(container)
                let classifiedRaw = ClassifiedPhoto.PhotoStatus.classified.rawValue
                let descriptor = FetchDescriptor<ClassifiedPhoto>(
                    predicate: #Predicate { $0.statusRaw == classifiedRaw }
                )
                let photos = try context.fetch(descriptor)
                return photos
                    .filter { $0.pillarID == pillarID || $0.pillarIDs.contains(pillarID) }
                    .map { ClassifiedPhotoSnapshot($0) }
            },

            // MARK: - Scan-heavy operations (background ModelContext)

            countPhotosPerPillar: {
                log.info("⏳ countPhotosPerPillar")
                let context = ModelContext(container)
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
                log.info("✅ countPhotosPerPillar — \(counts.count) pillars, \(photos.count) photos")
                return counts
            },
            fetchClassifiedAssetIDs: {
                log.info("⏳ fetchClassifiedAssetIDs")
                let context = ModelContext(container)
                var descriptor = FetchDescriptor<ClassifiedPhoto>()
                descriptor.propertiesToFetch = [\.assetLocalIdentifier]
                let photos = try context.fetch(descriptor)
                log.info("✅ fetchClassifiedAssetIDs — \(photos.count) IDs")
                return Set(photos.map(\.assetLocalIdentifier))
            },
            batchSavePhotos: { snapshots in
                guard !snapshots.isEmpty else { return }
                let context = ModelContext(container)
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
            },

            // MARK: - Posts (UI-driven, mainContext)

            savePost: { snapshot in
                try await MainActor.run {
                    let context = container.mainContext
                    let id = snapshot.id
                    var descriptor = FetchDescriptor<GeneratedPost>(
                        predicate: #Predicate { $0.id == id }
                    )
                    descriptor.fetchLimit = 1
                    if let existing = try context.fetch(descriptor).first {
                        existing.title = snapshot.title
                        existing.pillarID = snapshot.pillarID
                        existing.templateID = snapshot.templateID
                        existing.photoIDs = snapshot.photoIDs
                        existing.caption = snapshot.caption
                        existing.hashtags = snapshot.hashtags
                        existing.platform = snapshot.platform
                        existing.status = snapshot.status
                        existing.isAutoGenerated = snapshot.isAutoGenerated
                        existing.schedule = snapshot.schedule
                    } else {
                        let post = GeneratedPost(
                            title: snapshot.title,
                            pillarID: snapshot.pillarID,
                            templateID: snapshot.templateID,
                            photoIDs: snapshot.photoIDs,
                            caption: snapshot.caption,
                            hashtags: snapshot.hashtags,
                            platform: snapshot.platform,
                            status: snapshot.status,
                            isAutoGenerated: snapshot.isAutoGenerated,
                            schedule: snapshot.schedule
                        )
                        context.insert(post)
                    }
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

            // MARK: - Templates (UI-driven, mainContext)

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
