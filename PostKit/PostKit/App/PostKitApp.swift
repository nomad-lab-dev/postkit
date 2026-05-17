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
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        self.store = Store(initialState: AppFeature.State()) {
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
