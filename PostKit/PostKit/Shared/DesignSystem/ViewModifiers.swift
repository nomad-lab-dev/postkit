import SwiftUI

extension View {
    func cardStyle() -> some View { modifier(AccessibleCardModifier()) }

    func floatingStyle() -> some View {
        self
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sheet))
            .shadow(color: .black.opacity(0.12), radius: 28, y: 8)
    }

    func eyebrow() -> some View {
        self.font(Typography.caption)
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(Palette.text3)
    }

    func screenPadding() -> some View { padding(Layout.Padding.screen) }
    func cardPadding() -> some View { padding(Layout.Padding.card) }
    func shimmer() -> some View { modifier(ShimmerModifier()) }

    /// Staggered fade-up entrance for vertically stacked sections.
    /// `index` controls the delay (0 = first, 1 = next, …). Respects Reduce Motion.
    func revealStep(_ index: Int, appeared: Bool, reduceMotion: Bool) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 12)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.2)
                    : .spring(response: 0.55, dampingFraction: 0.86)
                        .delay(Double(index) * 0.06),
                value: appeared
            )
    }
}

// MARK: - Shimmer

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.35),
                            .clear,
                        ],
                        startPoint: .init(x: phase, y: 0.5),
                        endPoint: .init(x: phase + 0.8, y: 0.5)
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width * 0.5)
                }
                .clipped()
            }
            .task {
                // Wait one tick so the tab-switch transition has settled before
                // starting the repeat animation — otherwise the active transition
                // transaction swallows the repeatForever and the shimmer freezes.
                try? await Task.sleep(for: .milliseconds(50))
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 2
                }
            }
    }
}

// MARK: - Skeleton Shapes

struct SkeletonRect: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var radius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Palette.placeholder)
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct SkeletonCircle: View {
    var size: CGFloat = 32

    var body: some View {
        Circle()
            .fill(Palette.placeholder)
            .frame(width: size, height: size)
            .shimmer()
    }
}

