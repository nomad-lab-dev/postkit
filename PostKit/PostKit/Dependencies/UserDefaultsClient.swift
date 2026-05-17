import ComposableArchitecture
import Foundation

@DependencyClient
struct UserDefaultsClient: Sendable {
    var boolForKey: @Sendable (_ key: String) -> Bool = { _ in false }
    var setBool: @Sendable (_ value: Bool, _ forKey: String) -> Void
}

extension UserDefaultsClient: DependencyKey {
    static let liveValue = UserDefaultsClient(
        boolForKey: { UserDefaults.standard.bool(forKey: $0) },
        setBool: { UserDefaults.standard.set($0, forKey: $1) }
    )

    static let previewValue = UserDefaultsClient(
        boolForKey: { _ in true },
        setBool: { _, _ in }
    )
}

extension DependencyValues {
    var userDefaults: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}
