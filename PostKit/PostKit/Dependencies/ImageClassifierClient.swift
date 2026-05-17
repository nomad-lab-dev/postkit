import ComposableArchitecture
import GoogleGenerativeAI
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
    var classify: @Sendable (_ image: UIImage, _ pillarNames: [String]) async throws -> ClassificationResult
}

extension ImageClassifierClient: DependencyKey {
    static let liveValue = ImageClassifierClient(
        classify: { image, pillarNames in
            // 1. Core ML (Vision) — free, fast, on-device
            let visionResult = try? await VisionClassifier.classify(image, pillarNames: Set(pillarNames))
            if let visionResult, visionResult.confidence >= 0.70 {
                return visionResult
            }

            // 2. Gemini Flash fallback — Vision unavailable (simulator) or low confidence
            if let apiKey = Bundle.main.infoDictionary?["GeminiAPIKey"] as? String,
               !apiKey.isEmpty,
               let geminiResult = try? await GeminiClassifier.classify(
                   image, pillarNames: pillarNames, apiKey: apiKey
               ) {
                return geminiResult
            }

            // 3. Return best Vision result or uncategorized
            return visionResult ?? ClassificationResult(
                pillarName: "Uncategorized", confidence: 0, suggestedTags: [], source: .coreML
            )
        }
    )

    static let previewValue = ImageClassifierClient(
        classify: { _, pillarNames in
            ClassificationResult(
                pillarName: pillarNames.randomElement() ?? "Uncategorized",
                confidence: .random(in: 0.65...0.95),
                suggestedTags: [],
                source: .coreML
            )
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
    static func classify(_ image: UIImage, pillarNames: Set<String>) async throws -> ClassificationResult {
        guard let cgImage = image.cgImage else {
            return ClassificationResult(pillarName: "Uncategorized", confidence: 0, suggestedTags: [], source: .coreML)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = (request.results as? [VNClassificationObservation]) ?? []
                continuation.resume(returning: mapToPillar(observations, validPillars: pillarNames))
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

    private static func mapToPillar(
        _ observations: [VNClassificationObservation],
        validPillars: Set<String>
    ) -> ClassificationResult {
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

        if let best = scores.max(by: { $0.value < $1.value }) {
            return ClassificationResult(
                pillarName: best.key,
                confidence: min(best.value, 1.0),
                suggestedTags: Array((tags[best.key] ?? []).prefix(5)),
                source: .coreML
            )
        }

        return ClassificationResult(
            pillarName: "Uncategorized",
            confidence: 0,
            suggestedTags: observations.prefix(3).map(\.identifier),
            source: .coreML
        )
    }
}

// MARK: - Gemini Flash (cloud fallback)

private enum GeminiClassifier {
    static func classify(
        _ image: UIImage,
        pillarNames: [String],
        apiKey: String
    ) async throws -> ClassificationResult {
        let model = GenerativeModel(name: "gemini-2.0-flash", apiKey: apiKey)

        let pillarList = pillarNames.joined(separator: ", ")
        let prompt = """
        Classify this photo into exactly ONE of these content pillars:
        \(pillarList).

        If the photo does not clearly match any pillar, use "Uncategorized".

        Reply ONLY with a JSON object (no markdown, no explanation):
        {"pillarName": "...", "confidence": 0.XX, "tags": ["tag1", "tag2", "tag3"]}
        """

        let response = try await model.generateContent(prompt, image)

        guard let text = response.text else {
            throw ClassificationError.noResponse
        }

        return try parse(text, validPillars: Set(pillarNames))
    }

    private static func parse(_ text: String, validPillars: Set<String>) throws -> ClassificationResult {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pillarName = json["pillarName"] as? String else {
            throw ClassificationError.invalidResponse
        }

        let finalName = validPillars.contains(pillarName) ? pillarName : "Uncategorized"

        return ClassificationResult(
            pillarName: finalName,
            confidence: (json["confidence"] as? NSNumber)?.floatValue ?? 0.85,
            suggestedTags: (json["tags"] as? [String]) ?? [],
            source: .gemini
        )
    }
}

private enum ClassificationError: Error {
    case noResponse, invalidResponse
}
