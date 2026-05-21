import Foundation
import SwiftData
import XCTest
@testable import PostKit

@MainActor
final class PersistenceClientTests: XCTestCase {

    private func makeClient() throws -> PersistenceClient {
        let schema = Schema([Pillar.self, ClassifiedPhoto.self, GeneratedPost.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return .live(container: container)
    }

    func test_savePillar_persistsToSwiftData() async throws {
        let client = try makeClient()

        try await client.savePillar(PillarSnapshot(name: "Travel", emoji: "✈️"))
        try await client.savePillar(PillarSnapshot(name: "Food", emoji: "🍽️"))

        let pillars = try await client.fetchPillars()
        XCTAssertEqual(pillars.count, 2)
        XCTAssertEqual(pillars[0].name, "Travel")
        XCTAssertEqual(pillars[1].name, "Food")
    }

    func test_deletePillar_removesFromSwiftData() async throws {
        let client = try makeClient()

        try await client.savePillar(PillarSnapshot(name: "Fitness", emoji: "💪"))
        let before = try await client.fetchPillars()
        XCTAssertEqual(before.count, 1)

        try await client.deletePillar(before[0].id)
        let after = try await client.fetchPillars()
        XCTAssertEqual(after.count, 0)
    }

    func test_fetchPillars_sortsByCreatedAt() async throws {
        let client = try makeClient()

        try await client.savePillar(PillarSnapshot(name: "A", emoji: "🅰️"))
        try await client.savePillar(PillarSnapshot(name: "B", emoji: "🅱️"))
        try await client.savePillar(PillarSnapshot(name: "C", emoji: "©️"))

        let pillars = try await client.fetchPillars()
        XCTAssertEqual(pillars.map(\.name), ["A", "B", "C"])
    }
}
