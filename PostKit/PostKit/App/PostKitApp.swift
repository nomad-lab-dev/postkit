// MARK: - PostKit
// PostKitApp.swift — App entry point: SwiftData container setup and TCA store initialization

import ComposableArchitecture
import SwiftData
import SwiftUI

@main
struct PostKitApp: App {
    let store: StoreOf<AppFeature>

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: Pillar.self, ClassifiedPhoto.self, GeneratedPost.self, PostTemplate.self
            )
        } catch {
            print("⚠️ SwiftData migration failed — resetting store: \(error)")
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                for name in ["default.store", "default.store-wal", "default.store-shm"] {
                    try? FileManager.default.removeItem(at: appSupport.appending(path: name))
                }
            }
            UserDefaults.standard.removeObject(forKey: "onboardingComplete")
            UserDefaults.standard.removeObject(forKey: "fullScanComplete")
            UserDefaults.standard.removeObject(forKey: "fullScanCancelled")
            do {
                container = try ModelContainer(
                    for: Pillar.self, ClassifiedPhoto.self, GeneratedPost.self, PostTemplate.self
                )
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }

        var initialState = AppFeature.State()
        if !UserDefaults.standard.bool(forKey: "onboardingComplete") {
            initialState.onboarding = OnboardingFeature.State()
        }

        let persistence = PersistenceClient.live(container: container)
        self.store = Store(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.persistence = persistence
            $0.gallery = .live(persistence: persistence)
        }
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
