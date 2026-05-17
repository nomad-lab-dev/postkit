import ComposableArchitecture
import UIKit

@DependencyClient
struct PostGeneratorClient: Sendable {
    var generateCaption: @Sendable (
        _ images: [UIImage],
        _ pillar: PillarSnapshot,
        _ platform: SocialPlatform
    ) async throws -> String

    var generateHashtags: @Sendable (
        _ caption: String,
        _ pillar: PillarSnapshot,
        _ platform: SocialPlatform
    ) async throws -> [String]
}

extension PostGeneratorClient: DependencyKey {
    static let liveValue = PostGeneratorClient()

    static let previewValue = PostGeneratorClient(
        generateCaption: { _, pillar, _ in
            "Check out this amazing \(pillar.name.lowercased()) content! ✨"
        },
        generateHashtags: { _, pillar, _ in
            ["#\(pillar.name.lowercased())", "#postkit", "#content"]
        }
    )
}

extension DependencyValues {
    var postGenerator: PostGeneratorClient {
        get { self[PostGeneratorClient.self] }
        set { self[PostGeneratorClient.self] = newValue }
    }
}
