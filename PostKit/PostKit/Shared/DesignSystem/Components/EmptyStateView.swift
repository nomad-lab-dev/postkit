import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Layout.Stack.cozy) {
            Text(icon).font(.system(size: 40)).opacity(0.5)
            Text(title).font(Typography.headline)
            Text(message).font(Typography.footnote)
                .foregroundStyle(Palette.text3).multilineTextAlignment(.center)
            if let actionTitle, let onAction {
                Button(actionTitle, action: onAction).buttonStyle(PrimaryButton())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Layout.Padding.sheet)
        .background(Palette.glassStrong, in: RoundedRectangle(cornerRadius: Radius.card))
    }
}

#Preview("Empty States") {
    VStack(spacing: 20) {
        EmptyStateView(
            icon: "📭",
            title: "No photos match",
            message: "Try adjusting your filters or scanning more of your library."
        )
        EmptyStateView(
            icon: "📸",
            title: "Queue cleared",
            message: "All photos have been classified.",
            actionTitle: "Scan more",
            onAction: {}
        )
    }
    .padding()
    .background(Palette.bg)
}
