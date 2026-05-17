import SwiftUI

struct ConfidenceBadge: View {
    let result: ClassificationResult

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text("AI \(Int(result.confidence * 100))%")
            Image(systemName: result.confidence >= 0.70 ? "checkmark" : "cloud")
        }
        .font(Typography.caption)
        .padding(Layout.Padding.chip)
        .background(tint.opacity(0.12), in: Capsule())
        .foregroundStyle(tint)
    }

    var tint: Color { result.confidence >= 0.70 ? Palette.green : Palette.yellow }
}

#Preview("Confidence Badges") {
    HStack(spacing: 12) {
        ConfidenceBadge(result: ClassificationResult(
            pillarName: "Automotive", confidence: 0.87, suggestedTags: [], source: .coreML
        ))
        ConfidenceBadge(result: ClassificationResult(
            pillarName: "Travel", confidence: 0.64, suggestedTags: [], source: .gemini
        ))
    }
    .padding()
}
