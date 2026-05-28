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

        #if DEBUG
        // -MarketingSeed 1 → populate demo data and stub PhotoKit with bundled assets.
        // Used to capture App Store screenshots from a clean simulator install.
        let isMarketingCapture = ProcessInfo.processInfo.arguments.contains("-MarketingSeed")
            && ProcessInfo.processInfo.arguments.contains("1")
        if isMarketingCapture {
            MainActor.assumeIsolated {
                DemoDataSeeder.seedIfNeeded(container: container)
            }
        }
        #else
        let isMarketingCapture = false
        #endif

        var initialState = AppFeature.State()
        if !isMarketingCapture && !UserDefaults.standard.bool(forKey: "onboardingComplete") {
            initialState.onboarding = OnboardingFeature.State()
        }
        #if DEBUG
        if isMarketingCapture {
            initialState.smartPost.messages = DemoDataSeeder.italianChatMessages
            initialState.smartPost.isLoadingData = false

            // -MarketingTab <home|explore|smartPost|create|settings> → land directly on a tab.
            // Lets us capture each screen with a clean relaunch (no UI taps needed).
            if let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-MarketingTab"),
               i + 1 < ProcessInfo.processInfo.arguments.count {
                let tabArg = ProcessInfo.processInfo.arguments[i + 1]
                switch tabArg {
                case "home":      initialState.selectedTab = .home
                case "explore":   initialState.selectedTab = .explore
                case "smartPost": initialState.selectedTab = .smartPost
                case "create":    initialState.selectedTab = .create
                case "settings":  initialState.selectedTab = .settings
                default: break
                }
            }
        }
        #endif

        let persistence = PersistenceClient.live(container: container)
        self.store = Store(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.persistence = persistence
            $0.gallery = .live(persistence: persistence)
            #if DEBUG
            if isMarketingCapture {
                $0.photoLibrary = .marketingCapture()
            }
            #endif
        }
    }

    private static let isTesting = ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil

    @AppStorage("appLanguage") private var appLanguage: String = ""

    private var resolvedLocale: Locale {
        appLanguage.isEmpty ? .autoupdatingCurrent : Locale(identifier: appLanguage)
    }

    var body: some Scene {
        WindowGroup {
            if Self.isTesting {
                Color.clear
            } else {
                AppView(store: store)
                    .environment(\.locale, resolvedLocale)
            }
        }
    }
}
