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
    var savePost: @Sendable (_ snapshot: GeneratedPostSnapshot) async throws -> Void
    var fetchPosts: @Sendable (_ pillarID: UUID?) async throws -> [GeneratedPostSnapshot]
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
            }
            // savePhoto, fetchPhotos, savePost, fetchPosts: TODO Slice 2 / Slice 5
        )
    }
}

extension DependencyValues {
    var persistence: PersistenceClient {
        get { self[PersistenceClient.self] }
        set { self[PersistenceClient.self] = newValue }
    }
}
