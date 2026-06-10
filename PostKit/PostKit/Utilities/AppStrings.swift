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
        // Legacy keys (kept for any remaining references)
        static let welcomeTitle: LocalizedStringKey = "Welcome to PostKit"
        static let welcomeSubtitle: LocalizedStringKey = "Turn your photo library into a content engine."
        static let scanTitle: LocalizedStringKey = "Quick Scan"
        static let topicsTitle: LocalizedStringKey = "Your Topics"

        // Photo Access
        static let photoAccessTitle: LocalizedStringKey = "Full Photo Access Required"
        static let photoAccessBody: LocalizedStringKey = "PostKit needs to browse your entire photo library to classify and organize your content."
        static let photoAccessLock: LocalizedStringKey = "Your photos never leave your device"
        static let photoAccessEye: LocalizedStringKey = "We only store references, not copies"
        static let photoAccessSettings: LocalizedStringKey = "Settings → PostKit → Photos → Full Access"
        static let photoAccessButton: LocalizedStringKey = "Open Settings"

        // Step 01 – Before / After
        static let step01Eyebrow: LocalizedStringKey = "STEP 01 · BEFORE / AFTER"
        static let step01HeadlinePart1: LocalizedStringKey = "Your photos."
        static let step01HeadlinePart2: LocalizedStringKey = "Your content."
        static let step01SegWithout: LocalizedStringKey = "Actuellement"
        static let step01SegWith: LocalizedStringKey = "Avec PostKit"
        static let step01CTAReveal: LocalizedStringKey = "Ta galerie est déjà pleine de posts →"
        static let step01CTA: LocalizedStringKey = "Montre-moi comment ça marche →"

        // Step 02 – Magic Demo
        static let step02Eyebrow: LocalizedStringKey = "STEP 02 · SMART POST"
        static let step02HeadlinePart1: LocalizedStringKey = "Type a sentence.\n"
        static let step02HeadlineEmphasis: LocalizedStringKey = "Get"
        static let step02HeadlinePart2: LocalizedStringKey = " a post."
        static let step02CTA: LocalizedStringKey = "Choisir mes sujets →"
        static let step02GeneratedLabel: LocalizedStringKey = "GENERATED · 2.1 S"
        static let step02ShareLabel: LocalizedStringKey = "Share on Instagram"

        // Step 02 — Demo chips
        static let step02ChipItaly: LocalizedStringKey = "🌍 Italy"
        static let step02ChipCoffee: LocalizedStringKey = "☕ Coffee"
        static let step02ChipBuild: LocalizedStringKey = "💼 Build"

        // Step 02 — Demo card prompts + captions
        static let step02ItalyPrompt: LocalizedStringKey = "My weekend in Italy"
        static let step02ItalyCaption: LocalizedStringKey = "Three days, two cities, one road. Naples → Capri."
        static let step02CoffeePrompt: LocalizedStringKey = "Coffee shops I keep coming back to"
        static let step02CoffeeCaption: LocalizedStringKey = "Three rooms, one ritual. The flat white that started the day."
        static let step02BuildPrompt: LocalizedStringKey = "Build log · what shipped this week"
        static let step02BuildCaption: LocalizedStringKey = "Three PRs, one feature, zero regressions. Subscription tier is live."

        // Step 03 — Default topics
        static let defaultTopic1: LocalizedStringKey = "Cars"
        static let defaultTopic2: LocalizedStringKey = "Food & Coffee"
        static let defaultTopic3: LocalizedStringKey = "Build in public"
        static let defaultTopic4: LocalizedStringKey = "Travel"

        // Step 05 — First prompt prefix
        static let step05FirstPromptPrefix: LocalizedStringKey = "A post about"

        // Step 03 – Pillars
        static let step03Eyebrow: LocalizedStringKey = "YOUR TURN"
        static let step03HeadlinePart1: LocalizedStringKey = "What do "
        static let step03HeadlineEmphasis: LocalizedStringKey = "you"
        static let step03HeadlinePart2: LocalizedStringKey = " post about?"
        static let step03Body: LocalizedStringKey = "Pick or write 2–7 topics. Edit anytime."
        static let step03AddPlaceholder: LocalizedStringKey = "Add a topic"
        static let step03CTAMin: LocalizedStringKey = "Choisis au moins 2 sujets"
        static let step03CTAMax: LocalizedStringKey = "7 sujets maximum"
        static let step03CTAContinue: LocalizedStringKey = "Scanner mes photos →"

        // Step 04 – Live Sort
        static let step04Eyebrow: LocalizedStringKey = "AI SCAN"
        static let step04HeadlinePart1: LocalizedStringKey = "On cherche tes piliers\ndans "
        static let step04HeadlineEmphasis: LocalizedStringKey = "tes photos"
        static let step04HeadlinePart2: LocalizedStringKey = "."
        static let step04StatusReady: LocalizedStringKey = "✓ Analyse terminée."
        static let step04CTALoading: LocalizedStringKey = "Scan en cours…"
        static let step04CTAReady: LocalizedStringKey = "Continuer · galerie prête →"
        static let step04StatusMessages: [LocalizedStringKey] = [
            "Lecture de tes photos…",
            "Analyse IA en cours…",
            "Identification des sujets…",
            "Super shot trouvé ✦",
            "Encore quelques secondes…",
            "Finalisation…",
        ]

        // Step 05 – Your Turn
        static let step05EyebrowEmpty: LocalizedStringKey = "ALMOST READY"
        static let step05HeadlinePart1: LocalizedStringKey = "Génère ton\n"
        static let step05HeadlineEmphasis: LocalizedStringKey = "premier post."
        static let step05InputLabel: LocalizedStringKey = "TYPE OR PICK"
        static let step05InputPlaceholder: LocalizedStringKey = "A post about…"
        static let step05CTA: LocalizedStringKey = "Générer mes premiers posts →"
        static let step05CloudAITitle: LocalizedStringKey = "Cloud AI Enhancement"
        static let step05CloudAIOnBody: LocalizedStringKey = "Better accuracy · uses Google Gemini"
        static let step05CloudAIOffBody: LocalizedStringKey = "100% on-device · fully private"
        static func step05Eyebrow(_ total: Int) -> LocalizedStringKey {
            "DONE · \(total) PHOTOS SORTED"
        }
        static func step05PhotosCount(_ count: Int) -> LocalizedStringKey {
            "· \(count) photos"
        }
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
