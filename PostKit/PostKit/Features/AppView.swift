import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        TabView(selection: $store.selectedTab) {
            NavigationStack(path: $store.scope(state: \.homePath, action: \.homePath)) {
                Text(AppStrings.Dashboard.title)
                    .font(.largeTitle)
            } destination: { store in
                switch store.case {
                case .pillarDetail:
                    Text("Pillar Detail")
                case .pillarEditor:
                    Text("Pillar Editor")
                }
            }
            .tabItem { Label(AppStrings.Tab.dashboard, systemImage: "house") }
            .tag(AppFeature.Tab.home)

            NavigationStack(path: $store.scope(state: \.classifyPath, action: \.classifyPath)) {
                Text(AppStrings.Classification.queueTitle)
                    .font(.largeTitle)
            } destination: { store in
                switch store.case {
                case .classify:
                    Text("Classify Photo")
                }
            }
            .tabItem { Label(AppStrings.Tab.classify, systemImage: "photo.stack") }
            .tag(AppFeature.Tab.classify)

            NavigationStack(path: $store.scope(state: \.createPath, action: \.createPath)) {
                Text(AppStrings.PostAssembly.title)
                    .font(.largeTitle)
            } destination: { store in
                switch store.case {
                case .photoSelection:
                    Text("Photo Selection")
                case .platformExport:
                    Text("Platform Export")
                }
            }
            .tabItem { Label(AppStrings.Tab.create, systemImage: "square.and.pencil") }
            .tag(AppFeature.Tab.create)

            Text(AppStrings.Settings.title)
                .font(.largeTitle)
                .tabItem { Label(AppStrings.Tab.settings, systemImage: "gearshape") }
                .tag(AppFeature.Tab.settings)
        }
        .sheet(isPresented: $store.isOnboardingPresented) {
            Text("Onboarding (Slice 1)")
        }
        .task { await store.send(.appLaunched).finish() }
    }
}
