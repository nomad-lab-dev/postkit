import SwiftUI

struct Badge: View {
    let text: String
    var style: Style = .accent

    enum Style { case accent, purple, green, yellow, orange, red, cyan, neutral }

    var body: some View {
        Text(text)
            .font(Typography.caption)
            .foregroundStyle(fg)
            .padding(Layout.Padding.chip)
            .background(bg, in: Capsule())
    }

    var fg: Color {
        switch style {
        case .accent:  Palette.accent
        case .purple:  Palette.purple
        case .green:   Palette.green
        case .yellow:  Palette.yellow
        case .orange:  Palette.orange
        case .red:     Palette.red
        case .cyan:    Palette.cyan
        case .neutral: Palette.text2
        }
    }

    var bg: Color {
        switch style {
        case .accent:  Palette.accentTint
        case .purple:  Palette.purpleTint
        case .green:   Palette.greenTint
        case .yellow:  Palette.yellowTint
        case .orange:  Palette.orangeTint
        case .red:     Palette.redTint
        case .cyan:    Palette.cyanTint
        case .neutral: Color.black.opacity(0.05)
        }
    }
}

#Preview("Badges") {
    VStack(spacing: 12) {
        HStack {
            Badge(text: "8 photos", style: .accent)
            Badge(text: "✦ AI Generated", style: .purple)
            Badge(text: "✓ Classified", style: .green)
        }
        HStack {
            Badge(text: "? Pending", style: .yellow)
            Badge(text: "✗ Rejected", style: .red)
            Badge(text: "Instagram", style: .cyan)
        }
        HStack {
            Badge(text: "LinkedIn", style: .orange)
            Badge(text: "Twitter", style: .neutral)
        }
    }
    .padding()
}
