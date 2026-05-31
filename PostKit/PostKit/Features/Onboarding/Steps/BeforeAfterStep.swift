import SwiftUI

struct BeforeAfterStep: View {
    let onContinue: () -> Void
    @State private var showSorted: Bool
    @State private var phase: Int = 0

    init(onContinue: @escaping () -> Void, startSorted: Bool = false) {
        self.onContinue = onContinue
        _showSorted = State(initialValue: startSorted)
    }

    // (photoName, rotationDegrees)
    private let chaosPhotos: [(String, Double)] = [
        ("gallery-nomad-1", -8),
        ("gallery-food-1",   4),
        ("gallery-auto-1",  -3),
        ("gallery-life-1",   7),
        ("gallery-dev-1",   -6),
        ("gallery-nomad-2",  9),
        ("gallery-auto-2",  -5),
        ("gallery-food-2",   8),
        ("gallery-nomad-3", -9),
    ]

    // x/y fractions (0–1) of (containerSize - photoSize), 3×3 scattered grid
    private let xFracs: [CGFloat] = [0.00, 0.50, 1.00, 0.03, 0.52, 0.97, 0.01, 0.50, 0.99]
    private let yFracs: [CGFloat] = [0.02, 0.04, 0.00, 0.38, 0.36, 0.40, 0.72, 0.70, 0.74]

    private let bentoItems: [(emoji: String, name: String, count: Int, photos: [String])] = [
        ("🚗", "Cars",   47, ["gallery-auto-1",  "gallery-auto-2",  "gallery-auto-3",  "gallery-auto-4"]),
        ("☕", "Coffee", 32, ["gallery-food-1",  "gallery-food-2",  "gallery-food-3",  "gallery-life-1"]),
        ("🌍", "Travel", 89, ["gallery-nomad-1", "gallery-nomad-2", "gallery-nomad-3", "gallery-nomad-4"]),
        ("💼", "Build",  23, ["gallery-dev-1",   "gallery-dev-2",   "gallery-dev-3",   "gallery-life-2"]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                TypewriterText(
                    text: localizedString(for: AppStrings.Onboarding.step01Eyebrow),
                    font: .obMono(9), color: Palette.text4, show: phase >= 1,
                    onFinished: { phase = 2 }
                )
                .padding(.top, Spacing.md)

                TypewriterHeadline(
                    segments: [
                        HeadlineSegment(text: localizedString(for: AppStrings.Onboarding.step01HeadlinePart1), font: .obHeadline(28), color: Palette.text),
                        HeadlineSegment(text: "\n", font: .obHeadline(28), color: Palette.text),
                        HeadlineSegment(text: localizedString(for: AppStrings.Onboarding.step01HeadlinePart2), font: .obEmphasis(30), color: Color(red: 1, green: 149/255, blue: 0)),
                    ],
                    show: phase >= 2,
                    onFinished: {
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(120))
                            phase = 3
                            try? await Task.sleep(for: .milliseconds(450))
                            phase = 4
                        }
                    }
                )

                Picker("", selection: $showSorted) {
                    Text(AppStrings.Onboarding.step01SegWithout).tag(false)
                    Text(AppStrings.Onboarding.step01SegWith).tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.top, Spacing.xxs)
                .obEntrance(show: phase >= 3)
            }
            .padding(.horizontal, Layout.Padding.screen.leading)

            ZStack {
                chaosPane
                    .opacity(showSorted ? 0 : 1)
                    .scaleEffect(showSorted ? 1.03 : 1)
                sortedPane
                    .opacity(showSorted ? 1 : 0)
                    .scaleEffect(showSorted ? 1 : 0.97)
            }
            .padding(.horizontal, Layout.Padding.screen.leading)
            .padding(.top, Spacing.sm)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)
            .animation(.easeInOut(duration: 0.45), value: showSorted)
            .obEntrance(show: phase >= 3)

            ctaBar {
                Button {
                    if !showSorted {
                        Haptics.tap()
                        withAnimation(.easeInOut(duration: 0.45)) { showSorted = true }
                    } else {
                        Haptics.tap()
                        onContinue()
                    }
                } label: {
                    Text(showSorted ? AppStrings.Onboarding.step01CTA : AppStrings.Onboarding.step01CTAReveal)
                        .animation(.easeInOut(duration: 0.2), value: showSorted)
                }
                .buttonStyle(PrimaryButton())
                .animation(.easeInOut(duration: 0.2), value: showSorted)
            }
            .obCTAEntrance(show: phase >= 4)
        }
        .background(Palette.bg.ignoresSafeArea())
        .task {
            try? await Task.sleep(for: .milliseconds(80))
            phase = 1
        }
    }

    private var chaosPane: some View {
        GeometryReader { geo in
            let sz: CGFloat = 100
            let rangeX = max(geo.size.width  - sz, 1)
            let rangeY = max(geo.size.height - sz, 1)
            ZStack(alignment: .topLeading) {
                Color.clear
                ForEach(chaosPhotos.indices, id: \.self) { i in
                    BundleImage(name: chaosPhotos[i].0)
                        .frame(width: sz, height: sz)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.26), radius: 7, y: 4)
                        .rotationEffect(.degrees(chaosPhotos[i].1))
                        .offset(x: xFracs[i] * rangeX, y: yFracs[i] * rangeY)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sortedPane: some View {
        GeometryReader { geo in
            let gap:      CGFloat = 6
            let outerPad: CGFloat = 6
            let innerPad: CGFloat = 7
            let imgGap:   CGFloat = 5

            // 2 rows × cardH + gap + 2×outerPad = geo.size.height
            let cardH = (geo.size.height - 2 * outerPad - gap) / 2
            let gridH = max(cardH * 0.82, 20)
            let imgH  = max((gridH - imgGap) / 2, 10)

            VStack(spacing: gap) {
                ForEach([0, 2], id: \.self) { row in
                    HStack(alignment: .top, spacing: gap) {
                        ForEach([row, row + 1], id: \.self) { i in
                            let item = bentoItems[i]
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 2) {
                                    Text("\(item.emoji) \(item.name)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(Palette.text)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(item.count)")
                                        .font(.custom("SpaceGrotesk-Bold", size: 10))
                                        .foregroundStyle(Palette.text4)
                                }
                                .padding(.vertical, Spacing.xxs)
                                .frame(maxHeight: .infinity)
                                VStack(spacing: imgGap) {
                                    HStack(spacing: imgGap) {
                                        bentoPhoto(item.photos[0], height: imgH)
                                        bentoPhoto(item.photos[1], height: imgH)
                                    }
                                    HStack(spacing: imgGap) {
                                        bentoPhoto(item.photos[2], height: imgH)
                                        bentoPhoto(item.photos[3], height: imgH)
                                    }
                                }
                                .frame(height: gridH)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                            .padding(innerPad)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        }
                    }
                }
            }
            .padding(outerPad)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Color.clear base ensures the frame drives layout, never the image aspect ratio
    @ViewBuilder
    private func bentoPhoto(_ name: String, height: CGFloat) -> some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(BundleImage(name: name))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}
