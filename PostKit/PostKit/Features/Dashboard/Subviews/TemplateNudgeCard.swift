import SwiftUI

struct TemplateNudgeCard: View {
    let onTap: () -> Void
    @State private var shimmer = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 40, height: 40)
                    .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.input))

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Your next post is already in your gallery")
                        .font(Typography.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.text)
                        .multilineTextAlignment(.leading)
                    Text("Tap to assemble it from a template")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Palette.accent)
                    .offset(x: shimmer && !reduceMotion ? 3 : 0)
            }
            .padding(Layout.Padding.card)
            .background(
                LinearGradient(
                    colors: [Palette.accentTint, Color.clear, Palette.purple.opacity(0.06)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: Radius.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(Palette.accent.opacity(0.15), lineWidth: 0.5)
            )
        }
        .buttonStyle(.scaling)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
        .accessibilityHint("Compose your next post from suggested photos")
    }
}
