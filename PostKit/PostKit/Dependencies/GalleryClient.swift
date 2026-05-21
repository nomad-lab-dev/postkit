// MARK: - PostKit
// GalleryClient.swift — Actor-cached read layer over PersistenceClient

import ComposableArchitecture
import Foundation
import os

private let log = Logger(subsystem: "PostKit", category: "Gallery")

@DependencyClient
struct GalleryClient: Sendable {
    var pillars: @Sendable () async throws -> [PillarSnapshot]
    var photos: @Sendable (_ status: ClassifiedPhoto.PhotoStatus?) async throws -> [ClassifiedPhotoSnapshot]
    var templates: @Sendable () async throws -> [TemplateSnapshot]
    var posts: @Sendable (_ pillarID: UUID?) async throws -> [GeneratedPostSnapshot]

    var invalidatePillars: @Sendable () async -> Void
    var invalidatePhotos: @Sendable () async -> Void
    var invalidateTemplates: @Sendable () async -> Void
    var invalidatePosts: @Sendable () async -> Void
    var invalidateAll: @Sendable () async -> Void
}

// MARK: - Cache Actor

private actor GalleryCache {
    private var cachedPillars: [PillarSnapshot]?
    private var cachedPhotos: [ClassifiedPhotoSnapshot]?
    private var cachedTemplates: [TemplateSnapshot]?
    private var cachedPosts: [GeneratedPostSnapshot]?

    private let persistence: PersistenceClient

    init(persistence: PersistenceClient) {
        self.persistence = persistence
    }

    func pillars() async throws -> [PillarSnapshot] {
        if let cached = cachedPillars {
            log.info("📦 pillars cache hit — \(cached.count)")
            return cached
        }
        log.info("⏳ pillars cache miss — loading from DB")
        let loaded = try await persistence.fetchPillars()
        cachedPillars = loaded
        log.info("✅ pillars cached — \(loaded.count)")
        return loaded
    }

    func photos(_ status: ClassifiedPhoto.PhotoStatus?) async throws -> [ClassifiedPhotoSnapshot] {
        if cachedPhotos == nil {
            log.info("⏳ photos cache miss — loading ALL from DB")
            cachedPhotos = try await persistence.fetchPhotos(nil)
            log.info("✅ photos cached — \(self.cachedPhotos?.count ?? 0)")
        }
        guard let all = cachedPhotos else { return [] }
        if let status {
            let filtered = all.filter { $0.status == status }
            log.info("📦 photos(\(status.rawValue)) — \(filtered.count) from cache")
            return filtered
        }
        return all
    }

    func templates() async throws -> [TemplateSnapshot] {
        if let cached = cachedTemplates {
            log.info("📦 templates cache hit — \(cached.count)")
            return cached
        }
        log.info("⏳ templates cache miss — loading from DB")
        let loaded = try await persistence.fetchTemplates()
        cachedTemplates = loaded
        log.info("✅ templates cached — \(loaded.count)")
        return loaded
    }

    func posts(_ pillarID: UUID?) async throws -> [GeneratedPostSnapshot] {
        if cachedPosts == nil {
            log.info("⏳ posts cache miss — loading from DB")
            cachedPosts = try await persistence.fetchPosts(nil)
            log.info("✅ posts cached — \(self.cachedPosts?.count ?? 0)")
        }
        guard let all = cachedPosts else { return [] }
        if let pillarID {
            return all.filter { $0.pillarID == pillarID }
        }
        return all
    }

    func invalidatePillars() {
        log.info("🗑️ pillars cache invalidated")
        cachedPillars = nil
    }

    func invalidatePhotos() {
        log.info("🗑️ photos cache invalidated")
        cachedPhotos = nil
    }

    func invalidateTemplates() {
        log.info("🗑️ templates cache invalidated")
        cachedTemplates = nil
    }

    func invalidatePosts() {
        log.info("🗑️ posts cache invalidated")
        cachedPosts = nil
    }

    func invalidateAll() {
        log.info("🗑️ ALL caches invalidated")
        cachedPillars = nil
        cachedPhotos = nil
        cachedTemplates = nil
        cachedPosts = nil
    }
}

// MARK: - DependencyKey

extension GalleryClient: DependencyKey {
    static let liveValue = GalleryClient()
    static let previewValue = GalleryClient(
        pillars: { [] },
        photos: { _ in [] },
        templates: { [] },
        posts: { _ in [] },
        invalidatePillars: {},
        invalidatePhotos: {},
        invalidateTemplates: {},
        invalidatePosts: {},
        invalidateAll: {}
    )

    static func live(persistence: PersistenceClient) -> GalleryClient {
        let cache = GalleryCache(persistence: persistence)
        return GalleryClient(
            pillars: { try await cache.pillars() },
            photos: { try await cache.photos($0) },
            templates: { try await cache.templates() },
            posts: { try await cache.posts($0) },
            invalidatePillars: { await cache.invalidatePillars() },
            invalidatePhotos: { await cache.invalidatePhotos() },
            invalidateTemplates: { await cache.invalidateTemplates() },
            invalidatePosts: { await cache.invalidatePosts() },
            invalidateAll: { await cache.invalidateAll() }
        )
    }
}

extension DependencyValues {
    var gallery: GalleryClient {
        get { self[GalleryClient.self] }
        set { self[GalleryClient.self] = newValue }
    }
}
