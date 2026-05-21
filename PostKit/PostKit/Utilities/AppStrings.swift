import Foundation

enum AppStrings {
    enum Tab {
        static let dashboard = String(localized: "Dashboard")
        static let classify = String(localized: "Classify")
        static let explore = String(localized: "Explore")
        static let create = String(localized: "Create")
        static let settings = String(localized: "Settings")
    }

    enum Onboarding {
        static let welcomeTitle = String(localized: "Welcome to PostKit")
        static let welcomeSubtitle = String(localized: "Turn your photo library into a content engine.")
        static let scanTitle = String(localized: "Quick Scan")
        static let topicsTitle = String(localized: "Your Topics")
    }

    enum Dashboard {
        static let title = String(localized: "Dashboard")
    }

    enum Classification {
        static let queueTitle = String(localized: "Classify")
    }

    enum Explore {
        static let title = String(localized: "Explore")
    }

    enum PostAssembly {
        static let title = String(localized: "Create Post")
    }

    enum Settings {
        static let title = String(localized: "Settings")
    }
}
