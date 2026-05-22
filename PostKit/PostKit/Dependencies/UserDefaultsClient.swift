// MARK: - PostKit
// UserDefaultsClient.swift — UserDefaults key-value dependency

import ComposableArchitecture
import Foundation

@DependencyClient
struct UserDefaultsClient: Sendable {
    var boolForKey: @Sendable (_ key: String) -> Bool = { _ in false }
    var setBool: @Sendable (_ value: Bool, _ forKey: String) -> Void
    var doubleForKey: @Sendable (_ key: String) -> Double = { _ in 0 }
    var setDouble: @Sendable (_ value: Double, _ forKey: String) -> Void
    var intForKey: @Sendable (_ key: String) -> Int = { _ in 0 }
    var setInt: @Sendable (_ value: Int, _ forKey: String) -> Void
}

extension UserDefaultsClient: DependencyKey {
    static let liveValue = UserDefaultsClient(
        boolForKey: { UserDefaults.standard.bool(forKey: $0) },
        setBool: { UserDefaults.standard.set($0, forKey: $1) },
        doubleForKey: { UserDefaults.standard.double(forKey: $0) },
        setDouble: { UserDefaults.standard.set($0, forKey: $1) },
        intForKey: { UserDefaults.standard.integer(forKey: $0) },
        setInt: { UserDefaults.standard.set($0, forKey: $1) }
    )

    static let previewValue = UserDefaultsClient(
        boolForKey: { _ in true },
        setBool: { _, _ in },
        doubleForKey: { _ in 0 },
        setDouble: { _, _ in },
        intForKey: { _ in 0 },
        setInt: { _, _ in }
    )
}

extension DependencyValues {
    var userDefaults: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}
