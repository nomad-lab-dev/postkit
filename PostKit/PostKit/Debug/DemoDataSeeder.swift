// MARK: - PostKit
// DemoDataSeeder.swift — DEBUG seed for App Store marketing capture.
// Activated via the `-MarketingSeed 1` launch arg. Idempotent: only seeds
// once if no pillars exist, so re-launching the app doesn't compound data.

#if DEBUG

import Foundation
import SwiftData

enum DemoDataSeeder {

    // Deterministic UUIDs so cross-feature lookups (Smart Post → Pillars) stay stable.
    static let automotiveID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let foodID       = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let travelID     = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    static let buildID      = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!

    /// Asset prefix used by MarketingPhotoLibraryClient to serve bundled images.
    static let assetPrefix = "marketing:"

    /// Pre-baked Italian Summer conversation for slide 03A (Smart Post chat).
    static let italianChatMessages: [ChatMessage] = [
        ChatMessage(
            role: .assistant,
            text: "Hey! Describe the post you want: topic, number of slides, locations... I'll build a template from your photo library."
        ),
        ChatMessage(
            role: .user,
            text: "J'aimerais un post avec 6 photos de mes vacances en Italie — mix portraits, food, paysages, et la voiture de loc"
        ),
        ChatMessage(
            role: .assistant,
            text: "Excellent choix ! J'ai créé un template avec 6 emplacements distincts, un par ville. Tour du monde italien 🇮🇹\n\n1️⃣ Naples — portrait golden hour\n2️⃣ Rome — Cacio e pepe close-up\n3️⃣ Positano — coastline at sunset\n4️⃣ Florence — Fiat 500 yellow\n5️⃣ Capri — sunset boat POV\n6️⃣ Milan — espresso bar interior\n\nTap 'Create post' to fill the slots with your real photos."
        )
    ]

    /// Seed if the store is empty. Safe to call on every launch.
    @MainActor
    static func seedIfNeeded(container: ModelContainer) {
        let context = container.mainContext
        let existing = (try? context.fetch(FetchDescriptor<Pillar>())) ?? []
        guard existing.isEmpty else { return }

        // MARK: Pillars
        let pillars: [(UUID, String, String, String, [String])] = [
            (automotiveID, "Automotive",       "🚗", "#007AFF", ["auto-1","auto-2","auto-3","auto-4"]),
            (foodID,       "Food",             "🍽️", "#FF9F0A", ["food-1","food-2","food-3","life-1"]),
            (travelID,     "Travel",           "🌍", "#34C759", ["nomad-1","nomad-2","nomad-3","nomad-4"]),
            (buildID,      "Build in public",  "💼", "#AF52DE", ["dev-1","dev-2","dev-3","life-3"])
        ]

        for (id, name, emoji, color, _) in pillars {
            let pillar = Pillar(name: name, emoji: emoji)
            pillar.id = id
            pillar.colorHex = color
            pillar.tone = .casual
            pillar.about = "Marketing demo content"
            pillar.postsPerWeek = name == "Travel" ? 4 : (name == "Automotive" ? 3 : (name == "Food" ? 2 : 1))
            context.insert(pillar)
        }

        // MARK: Classified photos — round-robin across the pillar's bundled images.
        // Counts match what the marketing slides reference (47 / 32 / 89 / 23).
        let now = Date()
        let counts: [(UUID, Int, [String])] = [
            (automotiveID, 47, ["auto-1","auto-2","auto-3","auto-4"]),
            (foodID,       32, ["food-1","food-2","food-3","life-1","life-2"]),
            (travelID,     89, ["nomad-1","nomad-2","nomad-3","nomad-4"]),
            (buildID,      23, ["dev-1","dev-2","dev-3","life-3"])
        ]

        for (pillarID, count, slugs) in counts {
            for i in 0..<count {
                let slug = slugs[i % slugs.count]
                let photo = ClassifiedPhoto(
                    assetLocalIdentifier: "\(assetPrefix)\(slug)-\(i)",
                    pillarID: pillarID,
                    pillarIDs: [pillarID],
                    confidence: 0.92,
                    classifiedByAI: true,
                    tags: tagsFor(slug: slug),
                    location: locationFor(slug: slug, index: i),
                    capturedAt: now.addingTimeInterval(-Double(i) * 86_400),
                    status: .classified,
                    cadrage: cadrageFor(slug: slug, index: i)
                )
                context.insert(photo)
            }
        }

        // MARK: PostTemplate — "Italian Summer"
        let italyTemplate = PostTemplate(
            name: "Italian Summer",
            about: "6 photos, 6 villes, un tour du monde italien",
            slots: [
                TemplateSlotData(name: "Naples",   cadrages: [.portrait], pillarIDs: [travelID],     locations: ["Naples, IT"],   about: "Portrait golden hour"),
                TemplateSlotData(name: "Rome",     cadrages: [.detail],  pillarIDs: [foodID],       locations: ["Rome, IT"],     about: "Cacio e pepe close-up"),
                TemplateSlotData(name: "Positano", cadrages: [.wide],     pillarIDs: [travelID],     locations: ["Positano, IT"], about: "Coastline at sunset"),
                TemplateSlotData(name: "Florence", cadrages: [.portrait], pillarIDs: [automotiveID], locations: ["Florence, IT"], about: "Fiat 500 yellow"),
                TemplateSlotData(name: "Capri",    cadrages: [.wide],     pillarIDs: [travelID],     locations: ["Capri, IT"],    about: "Capri sunset boat POV"),
                TemplateSlotData(name: "Milan",    cadrages: [.detail],  pillarIDs: [foodID],       locations: ["Milan, IT"],    about: "Espresso bar interior")
            ],
            locations: ["Naples, IT", "Rome, IT", "Positano, IT", "Florence, IT", "Capri, IT", "Milan, IT"],
            schedule: TemplateSchedule(weekdays: [.monday, .wednesday, .friday])
        )
        context.insert(italyTemplate)

        try? context.save()

        // Mark fake scan as complete so Dashboard shows "All caught up" not "scan needed".
        UserDefaults.standard.set(true, forKey: "fullScanComplete")
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
    }

    // MARK: - Helpers

    private static func tagsFor(slug: String) -> [String] {
        if slug.hasPrefix("auto")  { return ["cars", "automotive", "design"] }
        if slug.hasPrefix("food")  { return ["food", "restaurant", "culinary"] }
        if slug.hasPrefix("nomad") { return ["travel", "landscape", "italy"] }
        if slug.hasPrefix("dev")   { return ["work", "code", "setup"] }
        return ["lifestyle"]
    }

    private static func locationFor(slug: String, index: Int) -> String? {
        if slug.hasPrefix("nomad") {
            let cities = ["Naples, IT", "Rome, IT", "Positano, IT", "Florence, IT", "Capri, IT", "Milan, IT"]
            return cities[index % cities.count]
        }
        if slug.hasPrefix("auto") {
            return ["Paris, FR", "Florence, IT", "Munich, DE", "Modena, IT"][index % 4]
        }
        if slug.hasPrefix("food") {
            return ["Rome, IT", "Naples, IT", "Milan, IT", "Bangkok, TH"][index % 4]
        }
        return nil
    }

    private static func cadrageFor(slug: String, index: Int) -> Cadrage {
        if slug.hasPrefix("nomad") { return [.wide, .portrait, .wide][index % 3] }
        if slug.hasPrefix("food")  { return [.detail, .detail, .wide][index % 3] }
        if slug.hasPrefix("auto")  { return [.wide, .portrait, .detail][index % 3] }
        return .wide
    }
}

#endif
