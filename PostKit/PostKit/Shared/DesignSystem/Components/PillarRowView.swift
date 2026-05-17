import SwiftUI

struct PillarRowView: View {
    @Environment(\.dynamicTypeSize) var dynamicType
    @Environment(\.colorSchemeContrast) var contrast
    let pillar: PillarSnapshot

    var body: some View {
        if dynamicType.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Layout.Stack.cozy) { content }
                .padding(Layout.Padding.card)
                .cardStyle()
        } else {
            HStack(spacing: Layout.Stack.comfy) { content }
                .padding(Layout.Padding.card)
                .cardStyle()
        }
    }

    @ViewBuilder var content: some View {
        Text(pillar.emoji).font(.system(size: 28))

        VStack(alignment: .leading, spacing: Layout.Stack.tight) {
            Text(pillar.name).font(Typography.headline)
            ProgressView(value: pillar.coverage)
                .tint(Palette.color(forHex: pillar.colorHex))
            HStack(spacing: Layout.Stack.cozy) {
                Text("\(pillar.coveragePct)% coverage")
                Text("\(pillar.postsPerWeek) / week")
            }
            .font(Typography.footnote)
            .foregroundStyle(Palette.secondaryText(contrast))
        }

        VStack(alignment: .trailing, spacing: 0) {
            Text("\(pillar.photoCount)").font(Typography.title3)
            Text("photos").font(Typography.caption).foregroundStyle(Palette.text3)
        }
    }
}

#Preview("Pillar Rows") {
    VStack(spacing: 12) {
        PillarRowView(pillar: PillarSnapshot(
            name: "Automotive", emoji: "🚗", colorHex: "#007aff",
            photoCount: 47, coverage: 0.84
        ))
        PillarRowView(pillar: PillarSnapshot(
            name: "Travel", emoji: "🌍", colorHex: "#af52de",
            photoCount: 32, coverage: 0.64
        ))
    }
    .padding()
    .background(Palette.bg)
}
