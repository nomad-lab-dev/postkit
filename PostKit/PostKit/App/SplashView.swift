// MARK: - PostKit
// SplashView.swift — Animated launch splash: gradient, tile bounce, wordmark reveal

import SwiftUI

struct SplashView: View {
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Phase = .empty
    @State private var gradientVisible = false

    private enum Phase: Int, Equatable {
        case empty, tile1, tile2, tile3, tile4, wordmark
    }

    private struct TileData {
        let opacity: Double
        let fromAngleX: CGFloat
        let fromAngleY: CGFloat
        let fromRotation: Double
    }

    private let tiles: [TileData] = [
        .init(opacity: 0.95, fromAngleX: -0.85, fromAngleY: -1.05, fromRotation: -12),
        .init(opacity: 0.65, fromAngleX:  1.05, fromAngleY: -0.85, fromRotation:  15),
        .init(opacity: 0.75, fromAngleX: -0.95, fromAngleY:  1.05, fromRotation: -18),
        .init(opacity: 0.95, fromAngleX:  0.95, fromAngleY:  0.95, fromRotation:  12),
    ]

    var body: some View {
        GeometryReader { geo in
            let base = min(geo.size.width, geo.size.height)
            let gridSize = base * 0.40
            let tileGap = base * 0.016
            let tileSize = (gridSize - tileGap) / 2
            let tileRadius = tileSize * 0.12
            let tileShadowRadius = base * 0.015
            let wordmarkSize = base * 0.085
            let wordmarkBottomPad = base * 0.18
            let radialEndRadius = base * 0.55

            ZStack {
                background(radialEndRadius: radialEndRadius)

                tileGrid(
                    tileSize: tileSize,
                    gap: tileGap,
                    radius: tileRadius,
                    shadowRadius: tileShadowRadius
                )

                wordmark(fontSize: wordmarkSize, bottomPadding: wordmarkBottomPad)
            }
        }
        .ignoresSafeArea()
        .task {
            preloadOnboardingImages()
            await runAnimation()
        }
    }

    private func background(radialEndRadius: CGFloat) -> some View {
        ZStack {
            Color(hex: "007aff")

            LinearGradient(
                colors: [Color(hex: "007aff"), Color(hex: "af52de")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(gradientVisible ? 1 : 0)

            RadialGradient(
                gradient: Gradient(colors: [.white.opacity(0.25), .clear]),
                center: UnitPoint(x: 0.2, y: 0.15),
                startRadius: 0,
                endRadius: radialEndRadius
            )
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
            .opacity(gradientVisible ? 1 : 0)
        }
    }

    private func tileGrid(
        tileSize: CGFloat,
        gap: CGFloat,
        radius: CGFloat,
        shadowRadius: CGFloat
    ) -> some View {
        VStack(spacing: gap) {
            HStack(spacing: gap) {
                tile(index: 0, size: tileSize, radius: radius, shadowRadius: shadowRadius)
                tile(index: 1, size: tileSize, radius: radius, shadowRadius: shadowRadius)
            }
            HStack(spacing: gap) {
                tile(index: 2, size: tileSize, radius: radius, shadowRadius: shadowRadius)
                tile(index: 3, size: tileSize, radius: radius, shadowRadius: shadowRadius)
            }
        }
    }

    private func tile(
        index: Int,
        size: CGFloat,
        radius: CGFloat,
        shadowRadius: CGFloat
    ) -> some View {
        let data = tiles[index]
        let isVisible = phase.rawValue > index

        return RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(.white.opacity(data.opacity))
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.25), radius: shadowRadius, y: shadowRadius)
            .offset(x: isVisible ? 0 : size * data.fromAngleX, y: isVisible ? 0 : size * data.fromAngleY)
            .scaleEffect(isVisible ? 1 : 0.5)
            .rotationEffect(.degrees(isVisible ? 0 : data.fromRotation))
            .opacity(isVisible ? 1 : 0)
    }

    private func wordmark(fontSize: CGFloat, bottomPadding: CGFloat) -> some View {
        let visible = phase == .wordmark
        return VStack {
            Spacer()
            Text("PostKit")
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.15), radius: fontSize * 0.3, y: 2)
                .opacity(visible ? 1 : 0)
                .blur(radius: visible ? 0 : 8)
                .padding(.bottom, bottomPadding)
        }
    }

    @MainActor
    private func runAnimation() async {
        if reduceMotion {
            gradientVisible = true
            withAnimation(.easeInOut(duration: 0.4)) { phase = .wordmark }
            try? await Task.sleep(for: .seconds(1.0))
            onComplete()
            return
        }

        withAnimation(.easeOut(duration: 0.4)) { gradientVisible = true }

        let spring = Animation.interpolatingSpring(stiffness: 200, damping: 14)
        let sequence: [(Phase, UIImpactFeedbackGenerator.FeedbackStyle)] = [
            (.tile1, .light),
            (.tile2, .light),
            (.tile3, .light),
            (.tile4, .medium),
        ]

        try? await Task.sleep(for: .seconds(0.12))
        for (p, h) in sequence {
            withAnimation(spring) { phase = p }
            UIImpactFeedbackGenerator(style: h).impactOccurred()
            try? await Task.sleep(for: .seconds(0.12))
        }

        try? await Task.sleep(for: .seconds(0.25))
        withAnimation(.easeOut(duration: 0.6)) { phase = .wordmark }

        try? await Task.sleep(for: .seconds(0.7))
        onComplete()
    }
}

#Preview("iPhone — Splash") {
    SplashView(onComplete: {})
}

#Preview("iPad Pro 13") {
    SplashView(onComplete: {})
        .previewDevice("iPad Pro 13-inch (M4)")
}

#Preview("iPad — Landscape") {
    SplashView(onComplete: {})
        .previewDevice("iPad Pro 11-inch (M4)")
        .previewInterfaceOrientation(.landscapeLeft)
}
