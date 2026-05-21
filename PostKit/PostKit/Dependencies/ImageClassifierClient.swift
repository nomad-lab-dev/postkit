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

struct PillarDefinition: Equatable, Sendable {
    let name: String
    let about: String
    let referenceTags: [String]
}

struct ClassificationOutput: Equatable, Sendable {
    let results: [ClassificationResult]
    let cadrage: Cadrage
}

@DependencyClient
struct ImageClassifierClient: Sendable {
    var classify: @Sendable (_ image: UIImage, _ pillars: [PillarDefinition]) async throws -> [ClassificationResult]
    var detectCadrage: @Sendable (_ image: UIImage) async throws -> Cadrage
    var classifyWithCadrage: @Sendable (_ image: UIImage, _ pillars: [PillarDefinition]) async throws -> ClassificationOutput
}

extension ImageClassifierClient: DependencyKey {
    private static let highConfidence: Float = 0.70
    private static let minConfidence: Float = 0.55
    private static let geminiFloor: Float = 0.30

    private static func classifyWithVisionAndGemini(
        image: UIImage,
        pillars: [PillarDefinition],
        observations: [VNClassificationObservation]
    ) async -> [ClassificationResult] {
        let visionResults = VisionClassifier.mapToAllPillars(observations, pillars: pillars)

        let confidentResults = visionResults.filter { $0.confidence >= highConfidence }
        if !confidentResults.isEmpty {
            return confidentResults
        }

        let cloudAIEnabled = UserDefaults.standard.bool(forKey: "cloudAIEnabled")
        let bestVision = visionResults.max(by: { $0.confidence < $1.confidence })
        if cloudAIEnabled,
           let bestVision, bestVision.confidence >= geminiFloor,
           let apiKey = Bundle.main.infoDictionary?["GeminiAPIKey"] as? String,
           !apiKey.isEmpty,
           let geminiResults = try? await GeminiClassifier.classifyAll(
               image, pillars: pillars, apiKey: apiKey
           ) {
            let valid = geminiResults.filter { $0.confidence >= minConfidence }
            if !valid.isEmpty { return valid }
        }

        let viable = visionResults.filter { $0.confidence >= minConfidence }
        return viable
    }

    static let liveValue = ImageClassifierClient(
        classify: { image, pillars in
            let observations = (try? await VisionClassifier.runClassification(image)) ?? []
            return await classifyWithVisionAndGemini(image: image, pillars: pillars, observations: observations)
        },
        detectCadrage: { image in
            try await CadrageDetector.detect(image)
        },
        classifyWithCadrage: { image, pillars in
            let retainedImage = image
            let observations = try await VisionClassifier.runClassification(retainedImage)
            let results = await classifyWithVisionAndGemini(image: retainedImage, pillars: pillars, observations: observations)
            let cadrage = CadrageDetector.isScreenshot(retainedImage)
                ? .screenshot
                : CadrageDetector.mapToCadrage(observations, image: retainedImage)
            let _ = retainedImage
            return ClassificationOutput(results: results, cadrage: cadrage)
        }
    )

    static let previewValue = ImageClassifierClient(
        classify: { _, pillars in
            let names = pillars.map(\.name)
            let count = Int.random(in: 1...min(2, names.count))
            return names.shuffled().prefix(count).map {
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
        },
        classifyWithCadrage: { _, pillars in
            let names = pillars.map(\.name)
            let count = Int.random(in: 1...min(2, names.count))
            let results = names.shuffled().prefix(count).map {
                ClassificationResult(
                    pillarName: $0,
                    confidence: .random(in: 0.65...0.95),
                    suggestedTags: [],
                    source: .coreML
                )
            }
            return ClassificationOutput(
                results: results,
                cadrage: Cadrage.detectableCases.randomElement() ?? .wide
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
    static func deepCopyCGImage(_ image: UIImage) -> CGImage? {
        guard let source = image.cgImage else { return nil }
        let w = source.width, h = source.height
        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }
        ctx.draw(source, in: CGRect(x: 0, y: 0, width: w, height: h))
        return ctx.makeImage()
    }

    static func runClassification(_ image: UIImage) async throws -> [VNClassificationObservation] {
        guard let ownedCG = deepCopyCGImage(image) else { return [] }

        return try await withCheckedThrowingContinuation { continuation in
            let resumed = OSAllocatedUnfairLock(initialState: false)
            func resumeOnce(with result: Result<[VNClassificationObservation], Error>) {
                let alreadyResumed = resumed.withLock { val in
                    let was = val; val = true; return was
                }
                guard !alreadyResumed else { return }
                continuation.resume(with: result)
            }

            let request = VNClassifyImageRequest { request, error in
                if let error {
                    resumeOnce(with: .failure(error))
                    return
                }
                let observations = (request.results as? [VNClassificationObservation]) ?? []
                resumeOnce(with: .success(observations))
            }

            do {
                try VNImageRequestHandler(cgImage: ownedCG).perform([request])
            } catch {
                resumeOnce(with: .failure(error))
            }
        }
    }

    private static let fallbackKeywords: [String: [String]] = [
        "automotive": ["car", "vehicle", "auto", "truck", "motor", "road", "wheel", "race", "driv", "sedan", "suv", "coupe", "garage", "highway"],
        "travel": ["beach", "mountain", "ocean", "landscape", "sunset", "sunrise", "bridge", "city", "airplane", "boat", "train", "outdoor", "nature", "forest", "lake", "river", "tower", "monument", "temple", "palace", "island", "coast", "waterfall", "desert"],
        "food": ["food", "fruit", "vegetable", "cook", "meal", "dessert", "drink", "coffee", "wine", "beer", "restaurant", "kitchen", "bread", "cake", "pizza", "sushi", "pasta", "salad", "brunch"],
        "business": ["laptop", "computer", "office", "keyboard", "desk", "document", "book", "screen", "monitor", "workspace", "presentation"],
        "fitness": ["exercise", "gym", "running", "swim", "yoga", "sport", "bicycle", "tennis", "basket", "soccer", "football", "hik", "climb", "fitness", "athlet", "cycl", "marathon", "surf"],
        "behind the scenes": ["camera", "studio", "microphone", "film", "video", "production", "cinema", "record", "lighting", "tripod"],
    ]

    private static func keywords(for pillar: PillarDefinition) -> [String] {
        var terms: [String] = []

        // Reference tags from example photos (highest signal)
        for tag in pillar.referenceTags {
            terms.append(contentsOf: tag.lowercased().split(separator: " ").map(String.init))
        }

        // Description keywords
        if !pillar.about.isEmpty {
            let words = pillar.about.lowercased()
                .components(separatedBy: .alphanumerics.inverted)
                .filter { $0.count > 3 }
            terms.append(contentsOf: words)
        }

        // Fallback to hardcoded keywords for known categories
        let nameLower = pillar.name.lowercased()
        for (category, categoryTerms) in fallbackKeywords {
            if nameLower.contains(category) || category.contains(nameLower) {
                terms.append(contentsOf: categoryTerms)
            }
        }

        // Always include the name itself
        terms.append(contentsOf: nameLower.split(separator: " ").map(String.init))

        return Array(Set(terms))
    }

    static func mapToAllPillars(
        _ observations: [VNClassificationObservation],
        pillars: [PillarDefinition]
    ) -> [ClassificationResult] {
        var scores: [String: Float] = [:]
        var tags: [String: [String]] = [:]

        let pillarTerms = pillars.map { (pillar: $0, terms: keywords(for: $0)) }

        for obs in observations where obs.confidence > 0.01 {
            let id = obs.identifier.lowercased()
            let tokens = Set(id.split(separator: "_").map(String.init))
            for (pillar, terms) in pillarTerms {
                let matched = terms.contains { term in
                    tokens.contains { token in
                        token == term || (term.count >= 4 && token.hasPrefix(term))
                    }
                }
                if matched {
                    scores[pillar.name, default: 0] += obs.confidence
                    tags[pillar.name, default: []].append(obs.identifier)
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
            let model = GenerativeModel(name: "gemini-2.5-flash", apiKey: apiKey)
            cached = (model, apiKey)
            return model
        }
    }

    static func classifyAll(
        _ image: UIImage,
        pillars: [PillarDefinition],
        apiKey: String
    ) async throws -> [ClassificationResult] {
        let model = model(apiKey: apiKey)

        let pillarDescriptions = pillars.map { pillar in
            var desc = "- \(pillar.name)"
            if !pillar.about.isEmpty { desc += ": \(pillar.about)" }
            if !pillar.referenceTags.isEmpty { desc += " (visual style: \(pillar.referenceTags.prefix(8).joined(separator: ", ")))" }
            return desc
        }.joined(separator: "\n")

        let prompt = """
        Classify this photo into ALL matching content topics:
        \(pillarDescriptions)

        A photo can match multiple topics. Only include topics that genuinely fit.
        If the photo does not match any topic, return an empty array.

        Reply ONLY with a JSON array (no markdown, no explanation):
        [{"pillarName": "...", "confidence": 0.XX, "tags": ["tag1", "tag2"]}]
        """

        let response: GenerateContentResponse
        do {
            response = try await model.generateContent(prompt, image)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            try await Task.sleep(for: .milliseconds(500))
            response = try await model.generateContent(prompt, image)
        }

        guard let text = response.text else {
            throw ClassificationError.noResponse
        }

        return try parseAll(text, validPillars: Set(pillars.map(\.name)))
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

        guard let ownedCG = VisionClassifier.deepCopyCGImage(image) else { return .wide }

        return try await withCheckedThrowingContinuation { continuation in
            let resumed = OSAllocatedUnfairLock(initialState: false)
            func resumeOnce(with result: Result<Cadrage, Error>) {
                let alreadyResumed = resumed.withLock { val in
                    let was = val; val = true; return was
                }
                guard !alreadyResumed else { return }
                continuation.resume(with: result)
            }

            let request = VNClassifyImageRequest { request, error in
                if let error {
                    resumeOnce(with: .failure(error))
                    return
                }
                let observations = (request.results as? [VNClassificationObservation]) ?? []
                resumeOnce(with: .success(mapToCadrage(observations, image: image)))
            }

            do {
                try VNImageRequestHandler(cgImage: ownedCG).perform([request])
            } catch {
                resumeOnce(with: .failure(error))
            }
        }
    }

    static func isScreenshot(_ image: UIImage) -> Bool {
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

    static func mapToCadrage(_ observations: [VNClassificationObservation], image: UIImage) -> Cadrage {
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
