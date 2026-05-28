import SwiftUI

enum AppStrings {
    enum Tab {
        static let dashboard: LocalizedStringKey = "Dashboard"
        static let classify: LocalizedStringKey = "Classify"
        static let explore: LocalizedStringKey = "Explore"
        static let create: LocalizedStringKey = "Create"
        static let settings: LocalizedStringKey = "Settings"
        static let smartPost: LocalizedStringKey = "Smart Post"
    }

    enum Onboarding {
        static let welcomeTitle: LocalizedStringKey = "Welcome to PostKit"
        static let welcomeSubtitle: LocalizedStringKey = "Turn your photo library into a content engine."
        static let scanTitle: LocalizedStringKey = "Quick Scan"
        static let topicsTitle: LocalizedStringKey = "Your Topics"
    }

    enum Dashboard {
        static let title: LocalizedStringKey = "Dashboard"
    }

    enum Classification {
        static let queueTitle: LocalizedStringKey = "Classify"
    }

    enum Explore {
        static let title: LocalizedStringKey = "Explore"
    }

    enum PostAssembly {
        static let title: LocalizedStringKey = "Create Post"
    }

    enum Settings {
        static let title: LocalizedStringKey = "Settings"
    }
}
