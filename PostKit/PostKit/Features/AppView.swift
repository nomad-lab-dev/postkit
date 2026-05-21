// MARK: - PostKit
// AppView.swift — Root tab bar: dashboard, explore, smart post, create, and settings tabs

import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>
    @State private var splashFinished = false

    var body: some View {
        ZStack {
            if splashFinished {
                mainContent.transition(.opacity)
            } else {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        splashFinished = true
                    }
                }
                .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        TabView(selection: $store.selectedTab) {
            NavigationStack {
                DashboardView(store: store.scope(state: \.dashboard, action: \.dashboard))
            }
            .tabItem { Label(AppStrings.Tab.dashboard, systemImage: "house") }
            .tag(AppTab.home)

            NavigationStack {
                ExploreView(store: store.scope(state: \.explore, action: \.explore))
            }
            .tabItem { Label(AppStrings.Tab.explore, systemImage: "magnifyingglass") }
            .tag(AppTab.explore)

            NavigationStack {
                SmartPostView(store: store.scope(state: \.smartPost, action: \.smartPost))
            }
            .tabItem { Label("Smart Post", systemImage: "sparkles") }
            .tag(AppTab.smartPost)

            NavigationStack {
                CreateHubView(store: store.scope(state: \.create, action: \.create))
            }
            .tabItem { Label(AppStrings.Tab.create, systemImage: "square.and.pencil") }
            .tag(AppTab.create)

            NavigationStack {
                SettingsView(store: store.scope(state: \.settings, action: \.settings))
            }
            .tabItem { Label(AppStrings.Tab.settings, systemImage: "gearshape") }
            .tag(AppTab.settings)
        }
        .sheet(item: $store.scope(state: \.onboarding, action: \.onboarding)) { onboardingStore in
            OnboardingView(store: onboardingStore)
        }
        .task { await store.send(.appLaunched).finish() }
    }
}
