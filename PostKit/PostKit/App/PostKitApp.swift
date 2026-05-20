import ComposableArchitecture
import SwiftData
import SwiftUI

@main
struct PostKitApp: App {
    let store: StoreOf<AppFeature>

    init() {
        let schema = Schema([
            Pillar.self,
            ClassifiedPhoto.self,
            GeneratedPost.self,
            PostTemplate.self,
        ])
        let container: ModelContainer
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
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
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                container = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }

        var initialState = AppFeature.State()
        if !UserDefaults.standard.bool(forKey: "onboardingComplete") {
            initialState.onboarding = OnboardingFeature.State()
        }

        self.store = Store(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.persistence = .live(container: container)
        }
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
