// MARK: - PostKit
// ImageClassifierClient.swift — Core ML + Vision image classification dependency

import ComposableArchitecture
import GoogleGenerativeAI
import os
import UIKit
import Vision

struct ClassificationResult: Equatable, Sendable {
    let pillarName: String
    let confidence: Float
    let suggestedTags: [String]
    let source: ClassificationSource
}

enum ClassificationSource: Sendable, Equatable {
    case coreML, gemini
}

@DependencyClient
struct ImageClassifierClient: Sendable {
    var classify: @Sendable (_ image: UIImage, _ pillarNames: [String]) async throws -> [ClassificationResult]
    var detectCadrage: @Sendable (_ image: UIImage) async throws -> Cadrage
}

extension ImageClassifierClient: DependencyKey {
    private static let highConfidence: Float = 0.70
    private static let minConfidence: Float = 0.55
    private static let geminiFloor: Float = 0.30

    static let liveValue = ImageClassifierClient(
        classify: { image, pillarNames in
            let visionResults = (try? await VisionClassifier.classifyAll(image, pillarNames: Set(pillarNames))) ?? []

            let confidentResults = visionResults.filter { $0.confidence >= highConfidence }
            if !confidentResults.isEmpty {
                return confidentResults
            }

            let bestVision = visionResults.max(by: { $0.confidence < $1.confidence })
            if let bestVision, bestVision.confidence >= geminiFloor,
               let apiKey = Bundle.main.infoDictionary?["GeminiAPIKey"] as? String,
               !apiKey.isEmpty,
               let geminiResults = try? await GeminiClassifier.classifyAll(
                   image, pillarNames: pillarNames, apiKey: apiKey
               ) {
                let valid = geminiResults.filter { $0.confidence >= minConfidence }
                if !valid.isEmpty { return valid }
            }

            let viable = visionResults.filter { $0.confidence >= minConfidence }
            return viable
        },
        detectCadrage: { image in
            try await CadrageDetector.detect(image)
        }
    )

    static let previewValue = ImageClassifierClient(
        classify: { _, pillarNames in
            let count = Int.random(in: 1...min(2, pillarNames.count))
            return pillarNames.shuffled().prefix(count).map {
                ClassificationResult(
                    pillarName: $0,
                    confidence: .random(in: 0.65...0.95),
                    suggestedTags: [],
                    source: .coreML
                )
            }
        },
        detectCadrage: { _ in
            Cadrage.detectableCases.randomElement() ?? .wide
        }
    )
}

extension DependencyValues {
    var imageClassifier: ImageClassifierClient {
        get { self[ImageClassifierClient.self] }
        set { self[ImageClassifierClient.self] = newValue }
    }
}

// MARK: - Vision (Core ML on-device)

private enum VisionClassifier {
    static func classifyAll(_ image: UIImage, pillarNames: Set<String>) async throws -> [ClassificationResult] {
        guard let cgImage = image.cgImage else { return [] }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = (request.results as? [VNClassificationObservation]) ?? []
                continuation.resume(returning: mapToAllPillars(observations, validPillars: pillarNames))
            }

            do {
                try VNImageRequestHandler(cgImage: cgImage).perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private static let pillarKeywords: [(pillar: String, terms: [String])] = [
        ("Automotive", [
            "car", "vehicle", "auto", "truck", "motor", "road", "wheel",
            "race", "driv", "sedan", "suv", "coupe", "garage", "highway",
        ]),
        ("Travel", [
            "beach", "mountain", "ocean", "landscape", "sunset", "sunrise",
            "bridge", "city", "airplane", "boat", "train", "outdoor",
            "nature", "forest", "lake", "river", "tower", "monument",
            "temple", "palace", "island", "coast", "waterfall", "desert",
        ]),
        ("Food", [
            "food", "fruit", "vegetable", "cook", "meal", "dessert",
            "drink", "coffee", "wine", "beer", "restaurant", "kitchen",
            "bread", "cake", "pizza", "sushi", "pasta", "salad", "brunch",
        ]),
        ("Business", [
            "laptop", "computer", "office", "keyboard", "desk", "document",
            "book", "screen", "monitor", "workspace", "presentation",
        ]),
        ("Fitness", [
            "exercise", "gym", "running", "swim", "yoga", "sport",
            "bicycle", "tennis", "basket", "soccer", "football", "hik",
            "climb", "fitness", "athlet", "cycl", "marathon", "surf",
        ]),
        ("Behind the Scenes", [
            "camera", "studio", "microphone", "film", "video", "production",
            "cinema", "record", "lighting", "tripod",
        ]),
    ]

    private static func mapToAllPillars(
        _ observations: [VNClassificationObservation],
        validPillars: Set<String>
    ) -> [ClassificationResult] {
        var scores: [String: Float] = [:]
        var tags: [String: [String]] = [:]

        for obs in observations where obs.confidence > 0.01 {
            let id = obs.identifier.lowercased()
            for (pillar, terms) in pillarKeywords where validPillars.contains(pillar) {
                if terms.contains(where: { id.contains($0) }) {
                    scores[pillar, default: 0] += obs.confidence
                    tags[pillar, default: []].append(obs.identifier)
                }
            }
        }

        return scores
            .sorted { $0.value > $1.value }
            .map { pillar, score in
                ClassificationResult(
                    pillarName: pillar,
                    confidence: min(score, 1.0),
                    suggestedTags: Array((tags[pillar] ?? []).prefix(5)),
                    source: .coreML
                )
            }
    }
}

// MARK: - Gemini Flash (cloud fallback)

private enum GeminiClassifier {
    private static let cache = OSAllocatedUnfairLock<(model: GenerativeModel, key: String)?>(initialState: nil)

    private static func model(apiKey: String) -> GenerativeModel {
        cache.withLock { cached in
            if let cached, cached.key == apiKey { return cached.model }
            let model = GenerativeModel(name: "gemini-2.0-flash", apiKey: apiKey)
            cached = (model, apiKey)
            return model
        }
    }

    static func classifyAll(
        _ image: UIImage,
        pillarNames: [String],
        apiKey: String
    ) async throws -> [ClassificationResult] {
        let model = model(apiKey: apiKey)

        let pillarList = pillarNames.joined(separator: ", ")
        let prompt = """
        Classify this photo into ALL matching content pillars from this list:
        \(pillarList).

        A photo can match multiple pillars. Only include pillars that genuinely fit.
        If the photo does not match any pillar, return an empty array.

        Reply ONLY with a JSON array (no markdown, no explanation):
        [{"pillarName": "...", "confidence": 0.XX, "tags": ["tag1", "tag2"]}]
        """

        let response: GenerateContentResponse
        do {
            response = try await model.generateContent(prompt, image)
        } catch {
            try await Task.sleep(for: .milliseconds(500))
            response = try await model.generateContent(prompt, image)
        }

        guard let text = response.text else {
            throw ClassificationError.noResponse
        }

        return try parseAll(text, validPillars: Set(pillarNames))
    }

    private static func parseAll(_ text: String, validPillars: Set<String>) throws -> [ClassificationResult] {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw ClassificationError.invalidResponse
        }

        if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return array.compactMap { json -> ClassificationResult? in
                guard let name = json["pillarName"] as? String,
                      validPillars.contains(name) else { return nil }
                return ClassificationResult(
                    pillarName: name,
                    confidence: (json["confidence"] as? NSNumber)?.floatValue ?? 0.85,
                    suggestedTags: (json["tags"] as? [String]) ?? [],
                    source: .gemini
                )
            }
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let name = json["pillarName"] as? String,
           validPillars.contains(name) {
            return [ClassificationResult(
                pillarName: name,
                confidence: (json["confidence"] as? NSNumber)?.floatValue ?? 0.85,
                suggestedTags: (json["tags"] as? [String]) ?? [],
                source: .gemini
            )]
        }

        throw ClassificationError.invalidResponse
    }
}

// MARK: - Cadrage Detection (on-device)

private enum CadrageDetector {
    static func detect(_ image: UIImage) async throws -> Cadrage {
        if isScreenshot(image) { return .screenshot }

        guard let cgImage = image.cgImage else { return .wide }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = (request.results as? [VNClassificationObservation]) ?? []
                continuation.resume(returning: mapToCadrage(observations, image: image))
            }

            do {
                try VNImageRequestHandler(cgImage: cgImage).perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private static func isScreenshot(_ image: UIImage) -> Bool {
        let w = image.size.width * image.scale
        let h = image.size.height * image.scale
        let ratio = max(w, h) / max(min(w, h), 1)
        let phoneRatios: [ClosedRange<CGFloat>] = [
            2.1...2.25,   // Modern iPhones (19.5:9 ≈ 2.167)
            1.75...1.80,  // Older iPhones (16:9 = 1.778)
        ]
        let isPhoneRatio = phoneRatios.contains { $0.contains(ratio) }
        let isExactWidth = [750, 1080, 1125, 1170, 1179, 1242, 1284, 1290, 1320].contains(Int(min(w, h)))
        return isPhoneRatio && isExactWidth
    }

    private static let cadrageTerms: [(cadrage: Cadrage, terms: [String], weight: Float)] = [
        (.portrait, ["face", "portrait", "selfie", "person", "head", "profile", "people"], 1.0),
        (.wide, ["landscape", "sky", "beach", "mountain", "panoram", "outdoor", "aerial", "scenic", "horizon", "field", "ocean", "lake", "cityscape"], 1.0),
        (.detail, ["close", "macro", "food", "flower", "texture", "jewelry", "insect", "leaf", "fruit", "vegetable", "dessert"], 1.0),
        (.pov, ["hand", "holding", "desk", "table", "keyboard", "screen", "laptop", "book"], 0.6),
    ]

    private static func mapToCadrage(_ observations: [VNClassificationObservation], image: UIImage) -> Cadrage {
        var scores: [Cadrage: Float] = [:]

        for obs in observations where obs.confidence > 0.02 {
            let id = obs.identifier.lowercased()
            for (cadrage, terms, weight) in cadrageTerms {
                if terms.contains(where: { id.contains($0) }) {
                    scores[cadrage, default: 0] += obs.confidence * weight
                }
            }
        }

        guard let best = scores.max(by: { $0.value < $1.value }), best.value > 0.05 else {
            return inferFromAspectRatio(image)
        }
        return best.key
    }

    private static func inferFromAspectRatio(_ image: UIImage) -> Cadrage {
        let w = image.size.width * image.scale
        let h = image.size.height * image.scale
        let ratio = h / max(w, 1)
        if ratio > 1.3 { return .portrait }
        if ratio < 0.7 { return .wide }
        return .wide
    }
}

private enum ClassificationError: Error {
    case noResponse, invalidResponse
}
