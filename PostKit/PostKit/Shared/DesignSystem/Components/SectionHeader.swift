import SwiftUI

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title).eyebrow()
            Spacer()
            if let actionTitle, let onAction {
                Button(actionTitle, action: onAction)
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.accent)
            }
        }
    }
}

#Preview("Section Headers") {
    VStack(spacing: 20) {
        SectionHeader(title: "Your Pillars", actionTitle: "See all", onAction: {})
        SectionHeader(title: "Ready to post", actionTitle: "Filter", onAction: {})
        SectionHeader(title: "Recently classified")
    }
    .padding()
}
