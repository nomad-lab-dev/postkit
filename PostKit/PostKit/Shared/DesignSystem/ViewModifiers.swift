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
            .onAppear {
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

