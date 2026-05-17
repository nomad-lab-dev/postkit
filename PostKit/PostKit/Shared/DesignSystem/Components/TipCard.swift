import SwiftUI

struct TipCard: View {
    let icon: String
    let emphasis: String
    let message: String
    var tint: Color = Palette.purple

    var body: some View {
        HStack(spacing: Layout.Stack.cozy) {
            Text(icon).font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                (Text(emphasis).bold().foregroundColor(tint) + Text(" ") + Text(message))
                    .font(Typography.callout)
            }
        }
        .padding(Layout.Padding.card)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: Radius.input))
        .overlay(RoundedRectangle(cornerRadius: Radius.input).stroke(tint.opacity(0.15)))
    }
}

#Preview("Tip Cards") {
    VStack(spacing: 12) {
        TipCard(
            icon: "✦",
            emphasis: "Tip:",
            message: "Your next post is already in your gallery. Tap \"Compose\" to start."
        )
        TipCard(
            icon: "🎉",
            emphasis: "All set:",
            message: "342 assets classified.",
            tint: Palette.green
        )
    }
    .padding()
}
