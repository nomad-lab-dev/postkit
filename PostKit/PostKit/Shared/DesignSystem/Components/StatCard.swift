import SwiftUI

struct StatCard: View {
    let value: Int
    let label: String
    let delta: String?
    var tint: Color = Palette.accent

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.Stack.tight) {
            Text("\(value)").font(Typography.largeTitle).foregroundStyle(tint)
            Text(label).eyebrow()
            if let delta {
                Text(delta).font(Typography.footnote).foregroundStyle(Palette.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.Padding.card)
        .cardStyle()
    }
}

#Preview("Stat Cards") {
    HStack(spacing: 12) {
        StatCard(value: 155, label: "Photos sorted", delta: "+12 today")
        StatCard(value: 6, label: "Active pillars", delta: "3 ready", tint: Palette.purple)
    }
    .padding()
    .background(Palette.bg)
}
