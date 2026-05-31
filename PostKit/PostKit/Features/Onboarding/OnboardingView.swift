// MARK: - PostKit
// OnboardingView.swift — 5-step redesigned onboarding

import Combine
import ComposableArchitecture
import SwiftUI

// MARK: - Font helpers (Space Grotesk + Instrument Serif + Geist Mono)
// Font files must be added to Resources/Fonts/ and registered in Info.plist UIAppFonts.
// If not present, SwiftUI silently falls back to the system font.

private extension Font {
    static func obHeadline(_ size: CGFloat = 20) -> Font {
        .custom("SpaceGrotesk-Bold", size: size)
    }
    static func obEmphasis(_ size: CGFloat = 22) -> Font {
        .custom("InstrumentSerif-Italic", size: size)
    }
    static func obMono(_ size: CGFloat = 9) -> Font {
        .custom("GeistMono-SemiBold", size: size)
    }
    static func obBody(_ size: CGFloat = 14) -> Font {
        .custom("SpaceGrotesk-Medium", size: size)
    }
}

// MARK: - Pastel pillar colors

private let pillarAccents: [Color] = [
    Color(red: 0/255,   green: 122/255, blue: 255/255),  // blue
    Color(red: 255/255, green: 149/255, blue: 0/255),    // orange
    Color(red: 175/255, green: 82/255,  blue: 222/255),  // purple
    Color(red: 52/255,  green: 199/255, blue: 89/255),   // green
    Color(red: 255/255, green: 159/255, blue: 10/255),   // amber
    Color(red: 255/255, green: 45/255,  blue: 85/255),   // pink
    Color(red: 90/255,  green: 200/255, blue: 250/255),  // teal
]

private func pillarAccent(at index: Int) -> Color {
    pillarAccents[index % pillarAccents.count]
}

private let pillarGradientPairs: [(Color, Color)] = [
    (Color(red: 0/255, green: 122/255, blue: 255/255),   Color(red: 88/255, green: 86/255, blue: 214/255)),  // blue→indigo
    (Color(red: 255/255, green: 149/255, blue: 0/255),   Color(red: 255/255, green: 59/255, blue: 48/255)), // orange→red
    (Color(red: 52/255, green: 199/255, blue: 89/255),   Color(red: 50/255, green: 173/255, blue: 230/255)),// green→cyan
    (Color(red: 175/255, green: 82/255, blue: 222/255),  Color(red: 255/255, green: 45/255, blue: 85/255)), // purple→pink
    (Color(red: 255/255, green: 159/255, blue: 10/255),  Color(red: 255/255, green: 109/255, blue: 0/255)), // amber→orange
]

private func pillarGradient(at index: Int) -> LinearGradient {
    let (s, e) = pillarGradientPairs[index % pillarGradientPairs.count]
    return LinearGradient(colors: [s, e], startPoint: .leading, endPoint: .trailing)
}

// MARK: - Bundle image cache + preloader

private let _onboardingImageCache = NSCache<NSString, UIImage>()

func preloadOnboardingImages() {
    let names = [
        "gallery-auto-1", "gallery-auto-2", "gallery-auto-3", "gallery-auto-4",
        "gallery-food-1", "gallery-food-2", "gallery-food-3",
        "gallery-life-1", "gallery-life-2", "gallery-life-3",
        "gallery-nomad-1", "gallery-nomad-2", "gallery-nomad-3", "gallery-nomad-4",
        "gallery-dev-1", "gallery-dev-2", "gallery-dev-3",
    ]
    Task.detached(priority: .userInitiated) {
        await withTaskGroup(of: Void.self) { group in
            for name in names {
                group.addTask {
                    guard _onboardingImageCache.object(forKey: name as NSString) == nil,
                          let url = Bundle.main.url(forResource: name, withExtension: "webp"),
                          let data = try? Data(contentsOf: url),
                          let image = UIImage(data: data)
                    else { return }
                    _onboardingImageCache.setObject(image, forKey: name as NSString)
                }
            }
        }
    }
}

// MARK: - Bundle image helper

private struct BundleImage: View {
    let name: String
    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                Palette.surface
            }
        }
        .task(id: name) {
            if let cached = _onboardingImageCache.object(forKey: name as NSString) {
                uiImage = cached
                return
            }
            guard let url = Bundle.main.url(forResource: name, withExtension: "webp"),
                  let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data)
            else { return }
            _onboardingImageCache.setObject(image, forKey: name as NSString)
            uiImage = image
        }
    }
}

// MARK: - Demo data for Step 02

private struct DemoData: Equatable, Identifiable {
    let id: UUID
    let prompt: String
    let photoNames: [String]
    let caption: String

    static func make(_ chip: OnboardingFeature.DemoChip) -> DemoData {
        switch chip {
        case .italy:
            return DemoData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                prompt: "My weekend in Italy",
                photoNames: ["gallery-nomad-1", "gallery-nomad-2", "gallery-nomad-3", "gallery-nomad-4"],
                caption: "Three days, two cities, one road. Naples → Capri."
            )
        case .coffee:
            return DemoData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                prompt: "Coffee shops I keep coming back to",
                photoNames: ["gallery-food-1", "gallery-food-2", "gallery-food-3", "gallery-life-1"],
                caption: "Three rooms, one ritual. The flat white that started the day."
            )
        case .build:
            return DemoData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                prompt: "Build log · what shipped this week",
                photoNames: ["gallery-dev-1", "gallery-dev-2", "gallery-dev-3", "gallery-dev-1"],
                caption: "Three PRs, one feature, zero regressions. Subscription tier is live."
            )
        }
    }
}

// MARK: - Root

struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if store.photoAccessDenied {
                    PhotoAccessStep(onOpenSettings: { store.send(.openSettingsTapped) })
                } else {
                    switch store.step {
                    case .beforeAfter:
                        BeforeAfterStep(onContinue: { store.send(.beforeAfterContinueTapped) })
                    case .magicDemo:
                        MagicDemoStep(store: store)
                    case .pillars:
                        PillarsStep(store: store)
                    case .liveSort:
                        LiveSortStep(store: store)
                    case .yourTurn:
                        YourTurnStep(store: store)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.35), value: store.step)
            .animation(.easeInOut(duration: 0.3), value: store.photoAccessDenied)
            .navigationBarHidden(true)
        }
        .interactiveDismissDisabled()
        .alert($store.scope(state: \.alert, action: \.alert))
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { store.send(.sceneDidBecomeActive) }
        }
    }
}

// MARK: - Photo Access Required

private struct PhotoAccessStep: View {
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 72))
                .foregroundStyle(Palette.accent)
                .symbolEffect(.pulse, isActive: true)

            VStack(spacing: Spacing.sm) {
                Text(AppStrings.Onboarding.photoAccessTitle)
                    .font(Typography.title)
                    .multilineTextAlignment(.center)

                Text(AppStrings.Onboarding.photoAccessBody)
                    .font(Typography.body)
                    .foregroundStyle(Palette.text3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }

            VStack(spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "lock.shield").foregroundStyle(Palette.accent)
                    Text(AppStrings.Onboarding.photoAccessLock)
                        .font(Typography.subheadline).foregroundStyle(Palette.text2)
                }
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "eye.slash").foregroundStyle(Palette.accent)
                    Text(AppStrings.Onboarding.photoAccessEye)
                        .font(Typography.subheadline).foregroundStyle(Palette.text2)
                }
            }
            Spacer()

            Button {
                Haptics.tap()
                onOpenSettings()
            } label: {
                Label(AppStrings.Onboarding.photoAccessButton, systemImage: "gear")
            }
            .buttonStyle(PrimaryButton())
            .padding(.horizontal, Spacing.xl)

            Text(AppStrings.Onboarding.photoAccessSettings)
                .font(Typography.caption)
                .foregroundStyle(Palette.text4)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
        }
        .padding(Layout.Padding.screen)
    }
}

// MARK: - Step 01: Before / After

private struct BeforeAfterStep: View {
    let onContinue: () -> Void
    @State private var showSorted: Bool

    init(onContinue: @escaping () -> Void, startSorted: Bool = false) {
        self.onContinue = onContinue
        _showSorted = State(initialValue: startSorted)
    }

    // (photoName, rotationDegrees) — layout computed from container via GeometryReader
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

    // x/y fractions (0–1) of (containerSize - photoSize), giving a 3×3 scattered grid
    // col positions: 0%, 38%, 75% + row jitter
    // 3 cols at 0 / 50% / 100% with per-row jitter to fill the full panel width
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
            // ── Fixed header: eyebrow + headline + toggle ──────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                obEyebrow(AppStrings.Onboarding.step01Eyebrow, color: Palette.text4)
                    .padding(.top, Spacing.md)

                (Text(AppStrings.Onboarding.step01HeadlinePart1).font(.obHeadline(28))
                 + Text(AppStrings.Onboarding.step01HeadlinePart2).font(.obEmphasis(30))
                    .foregroundColor(Color(red: 1, green: 149/255, blue: 0)))
                .foregroundStyle(Palette.text)

                Picker("", selection: $showSorted) {
                    Text(AppStrings.Onboarding.step01SegWithout).tag(false)
                    Text(AppStrings.Onboarding.step01SegWith).tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.top, Spacing.xxs)
            }
            .padding(.horizontal, Layout.Padding.screen.leading)

            // ── Visual panel: fills ALL remaining space (CSS flex:1 equivalent) ─
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

            ctaBar {
                Button {
                    Haptics.tap()
                    onContinue()
                } label: {
                    Text(AppStrings.Onboarding.step01CTA)
                }
                .buttonStyle(PrimaryButton())
            }
        }
        .background(Palette.bg.ignoresSafeArea())
    }


    // ── Chaos: 3×3 grid of rotated photos spanning the full container ──────────
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

    // ── Sorted: 2×2 bento cards with photo heights that fill the panel ─────────
    private var sortedPane: some View {
        GeometryReader { geo in
            let gap:      CGFloat = 6
            let outerPad: CGFloat = 6
            let innerPad: CGFloat = 7
            let imgGap:   CGFloat = 5

            // cardH = total cell height per row (includes innerPad)
            // 2 rows × cardH + gap + 2×outerPad = geo.size.height
            let cardH = (geo.size.height - 2 * outerPad - gap) / 2
            // grid fills ~82% of card height; header label sits above it with tight padding
            let gridH = max(cardH * 0.82, 20)
            let imgH  = max((gridH - imgGap) / 2, 10)

            // Explicit VStack+HStack ensures identical dimensions for every cell
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

// MARK: - Step 02: Magic Demo

private struct MagicDemoStep: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        ZStack {
            // Gradient background — covers entire screen including CTA area
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0/255, green: 122/255, blue: 255/255), location: 0),
                        .init(color: Color(red: 88/255, green: 86/255, blue: 214/255), location: 0.5),
                        .init(color: Color(red: 175/255, green: 82/255, blue: 222/255), location: 1),
                    ],
                    startPoint: UnitPoint(x: 0, y: 0),
                    endPoint: UnitPoint(x: 0.7, y: 1)
                )
                RadialGradient(
                    colors: [Color(red: 1, green: 159/255, blue: 0).opacity(0.2), .clear],
                    center: UnitPoint(x: 0.85, y: 0),
                    startRadius: 0,
                    endRadius: 220
                )
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        obEyebrow(AppStrings.Onboarding.step02Eyebrow, color: .white.opacity(0.7))
                            .padding(.top, Spacing.md)

                        (Text(AppStrings.Onboarding.step02HeadlinePart1).font(.obHeadline(28))
                         + Text(AppStrings.Onboarding.step02HeadlineEmphasis).font(.obEmphasis(30)).foregroundColor(Color(red: 1, green: 174/255, blue: 66/255))
                         + Text(AppStrings.Onboarding.step02HeadlinePart2).font(.obHeadline(28)))
                        .foregroundStyle(.white)

                        // Chip row
                        HStack(spacing: Spacing.xs) {
                            ForEach(OnboardingFeature.DemoChip.allCases, id: \.self) { chip in
                                Button {
                                    Haptics.lightTap()
                                    store.send(.demoChipTapped(chip))
                                } label: {
                                    Text(chip.label)
                                        .font(.obBody(12))
                                        .foregroundStyle(store.activeDemoChip == chip ? Color(red: 0/255, green: 122/255, blue: 255/255) : .white)
                                        .padding(.horizontal, Spacing.sm)
                                        .padding(.vertical, 6)
                                        .background(
                                            store.activeDemoChip == chip ? .white : Color.white.opacity(0.18),
                                            in: Capsule()
                                        )
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(Color.white.opacity(store.activeDemoChip == chip ? 0 : 0.32), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                                .animation(.easeInOut(duration: 0.2), value: store.activeDemoChip)
                            }
                        }

                        // Animated demo card
                        MagicDemoCard(data: DemoData.make(store.activeDemoChip))
                            .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
                    }
                    .padding(.horizontal, Layout.Padding.screen.leading)
                    .padding(.bottom, Spacing.xxl)
                }

                // CTA area — transparent so gradient shows through uniformly
                Button {
                    Haptics.heavyTap()
                    store.send(.magicDemoContinueTapped)
                } label: {
                    Text(AppStrings.Onboarding.step02CTA)
                }
                .buttonStyle(PrimaryButton())
                .padding(.horizontal, Layout.Padding.screen.leading)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
    }
}

// MARK: - MagicDemoCard

private struct MagicDemoCard: View {
    let data: DemoData

    @State private var typedPrompt: String = ""
    @State private var showCursor: Bool = false
    @State private var showLoading: Bool = false
    @State private var showGrid: Bool = false
    @State private var revealedCount: Int = 0
    @State private var showCaption: Bool = false
    @State private var showShare: Bool = false
    @State private var showDemoAlert: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Chat bubble
            HStack {
                Spacer()
                HStack(spacing: 0) {
                    Text(typedPrompt.isEmpty ? " " : "\"\(typedPrompt)\"")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                    if showCursor {
                        Rectangle()
                            .fill(.white)
                            .frame(width: 2, height: 12)
                            .padding(.leading, 1)
                            .opacity(showCursor ? 1 : 0)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(red: 0/255, green: 122/255, blue: 255/255))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.bottom, 6)

            // Loading dots
            if showLoading {
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color(red: 0/255, green: 122/255, blue: 255/255))
                            .frame(width: 6, height: 6)
                            .scaleEffect(showLoading ? 1 : 0.6)
                            .animation(
                                .easeInOut(duration: 0.5)
                                    .repeatForever()
                                    .delay(Double(i) * 0.15),
                                value: showLoading
                            )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 10)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }

            // Photo 2×2 grid
            if showGrid {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)], spacing: 2) {
                    ForEach(0..<4) { i in
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(BundleImage(name: i < data.photoNames.count ? data.photoNames[i] : ""))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .scaleEffect(i < revealedCount ? 1 : 1.06)
                            .opacity(i < revealedCount ? 1 : 0)
                            .animation(.easeOut(duration: 0.35).delay(Double(i) * 0.01), value: revealedCount)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.bottom, 8)
                .transition(.opacity)
            }

            // Caption
            if showCaption {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Circle().fill(Palette.green).frame(width: 5, height: 5)
                        Text(AppStrings.Onboarding.step02GeneratedLabel)
                            .font(.obMono(7.5))
                            .foregroundStyle(Palette.green)
                            .tracking(0.6)
                    }
                    Text(data.caption)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Palette.text)
                        .lineLimit(3)
                }
                .padding(.bottom, showShare ? 8 : 0)
                .transition(.opacity)
            }

            // Share button
            if showShare {
                Button { showDemoAlert = true } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11))
                        Text(AppStrings.Onboarding.step02ShareLabel)
                            .font(.obBody(12))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.33, green: 0.36, blue: 0.84),
                                Color(red: 0.84, green: 0.16, blue: 0.46),
                                Color(red: 0.98, green: 0.49, blue: 0.12),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .shadow(color: Color(red: 0.84, green: 0.16, blue: 0.46).opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .padding(Spacing.md)
        .background(Color.white.opacity(0.97), in: RoundedRectangle(cornerRadius: 14))
        .task(id: data.id) {
            await playSequence()
        }
        .alert("Encore quelques étapes 👋", isPresented: $showDemoAlert) {
            Button("On y va !", role: .cancel) {}
        } message: {
            Text("Définis tes sujets et scanne ta galerie en 2 minutes — PostKit s'occupe ensuite de générer tes posts, prêts à partager.")
        }
    }

    @MainActor
    private func playSequence() async {
        // Reset
        withAnimation(.easeOut(duration: 0.15)) {
            typedPrompt = ""
            showCursor = false
            showLoading = false
            showGrid = false
            revealedCount = 0
            showCaption = false
            showShare = false
        }

        try? await Task.sleep(for: .milliseconds(200))

        if reduceMotion {
            // Instant reveal for reduce motion
            typedPrompt = data.prompt
            withAnimation(.easeOut(duration: 0.2)) {
                showGrid = true
                revealedCount = 4
                showCaption = true
                showShare = true
            }
            return
        }

        // Typing
        showCursor = true
        for char in data.prompt {
            guard !Task.isCancelled else { return }
            typedPrompt.append(char)
            try? await Task.sleep(for: .milliseconds(Int.random(in: 40...75)))
        }
        showCursor = false

        try? await Task.sleep(for: .milliseconds(280))

        // Loading dots
        withAnimation { showLoading = true }
        try? await Task.sleep(for: .milliseconds(1400))
        withAnimation { showLoading = false }
        try? await Task.sleep(for: .milliseconds(120))

        // Photo grid appears
        withAnimation(.easeOut(duration: 0.3)) { showGrid = true }
        try? await Task.sleep(for: .milliseconds(180))

        // Photos reveal one by one
        for i in 1...4 {
            guard !Task.isCancelled else { return }
            revealedCount = i
            try? await Task.sleep(for: .milliseconds(220))
        }

        try? await Task.sleep(for: .milliseconds(200))

        // Caption
        withAnimation(.easeOut(duration: 0.4)) { showCaption = true }
        try? await Task.sleep(for: .milliseconds(400))

        // Share button
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showShare = true }
    }
}

// MARK: - Step 03: Pillars

private struct PillarsStep: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    @FocusState private var inputFocused: Bool
    @FocusState private var editingFocusID: OnboardingTopic.ID?

    private var ctaEnabled: Bool {
        store.topics.count >= 2 && store.topics.count <= 7
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Fixed header ───────────────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                obEyebrow(AppStrings.Onboarding.step03Eyebrow, color: Palette.text4)
                    .padding(.top, Spacing.md)

                (Text(AppStrings.Onboarding.step03HeadlinePart1).font(.obHeadline(26))
                 + Text(AppStrings.Onboarding.step03HeadlineEmphasis).font(.obEmphasis(28)).foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255))
                 + Text(AppStrings.Onboarding.step03HeadlinePart2).font(.obHeadline(26)))
                .foregroundStyle(Palette.text)

                Text(AppStrings.Onboarding.step03Body)
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.text3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Layout.Padding.screen.leading)
            .padding(.bottom, Spacing.md)

            // ── Pillar list + add row ──────────────────────────────────────
            VStack(spacing: 6) {
                ForEach(Array(store.topics.enumerated()), id: \.element.id) { idx, topic in
                    PillarRow(
                        topic: topic,
                        accentColor: pillarAccent(at: idx),
                        isEditing: store.editingTopicID == topic.id,
                        editingFocusID: $editingFocusID,
                        onTap: { store.send(.topicTapped(topic.id)) },
                        onNameChanged: { store.send(.topicNameEdited(topic.id, $0)) },
                        onEditDone: { store.send(.topicEditDone) },
                        onRemove: { store.send(.removeTopicTapped(topic.id)) }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.topics.count)

                // Add your own row
                if store.topics.count < 7 {
                    HStack(spacing: Spacing.sm) {
                        TextField(AppStrings.Onboarding.step03AddPlaceholder, text: $store.topicInput)
                            .font(.obBody(20))
                            .foregroundStyle(Palette.text)
                            .focused($inputFocused)
                            .onSubmit { store.send(.addTopicTapped) }

                        let hasInput = !store.topicInput.trimmingCharacters(in: .whitespaces).isEmpty
                        Button {
                            guard hasInput else { return }
                            Haptics.tap()
                            store.send(.addTopicTapped)
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(
                                    hasInput
                                        ? Color(red: 0/255, green: 122/255, blue: 255/255)
                                        : Color.black.opacity(0.18),
                                    in: Circle()
                                )
                        }
                        .animation(.easeInOut(duration: 0.15), value: hasInput)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.03), in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                Color.black.opacity(0.18),
                                style: StrokeStyle(lineWidth: 1, dash: [5])
                            )
                    )
                    .animation(.easeInOut(duration: 0.15), value: store.topicInput.isEmpty)
                }
            }
            .padding(.horizontal, Layout.Padding.screen.leading)

            Spacer()

            ctaBar {
                Button {
                    guard ctaEnabled else { return }
                    Haptics.heavyTap()
                    inputFocused = false
                    store.send(.pillarsContinueTapped)
                } label: {
                    if ctaEnabled {
                        Text(AppStrings.Onboarding.step03CTA(store.topics.count))
                    } else if store.topics.count < 2 {
                        Text(AppStrings.Onboarding.step03CTAMin)
                    } else {
                        Text(AppStrings.Onboarding.step03CTAMax)
                    }
                }
                .buttonStyle(PrimaryButton())
                .disabled(!ctaEnabled)
                .animation(.easeInOut(duration: 0.2), value: ctaEnabled)
            }
        }
        .background(Palette.bg.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: store.editingTopicID) { _, newID in
            editingFocusID = newID
        }
    }
}

private struct PillarRow: View {
    let topic: OnboardingTopic
    let accentColor: Color
    let isEditing: Bool
    var editingFocusID: FocusState<OnboardingTopic.ID?>.Binding
    let onTap: () -> Void
    let onNameChanged: (String) -> Void
    let onEditDone: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(topic.emoji)
                .font(.system(size: 20))

            if isEditing {
                TextField("", text: Binding(
                    get: { topic.name },
                    set: { onNameChanged($0) }
                ))
                .font(.obBody(20))
                .foregroundStyle(accentColor)
                .focused(editingFocusID, equals: topic.id)
                .onSubmit { onEditDone() }
            } else {
                Text(topic.name)
                    .font(.obBody(20))
                    .foregroundStyle(accentColor)
            }

            Spacer(minLength: 0)

            Button {
                Haptics.lightTap()
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(accentColor.opacity(0.6))
                    .frame(width: 18, height: 18)
                    .background(Color.black.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 100))
        .overlay(
            RoundedRectangle(cornerRadius: 100)
                .strokeBorder(accentColor.opacity(isEditing ? 0.5 : 0.18), lineWidth: isEditing ? 1.5 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { if !isEditing { onTap() } }
    }
}

// MARK: - Step 04: Live Sort

private struct LiveSortStep: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    @State private var statusIdx: Int = 0
    @State private var statusTimer = Timer.publish(every: 1.8, on: .main, in: .common).autoconnect()

    private let statusMessages: [LocalizedStringKey] = AppStrings.Onboarding.step04StatusMessages

    private var scanDone: Bool { store.scanProgress >= 1.0 }

    var body: some View {
        VStack(spacing: 0) {
            // ── Fixed header ───────────────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                obEyebrow(AppStrings.Onboarding.step04Eyebrow, color: Palette.text4)
                    .padding(.top, Spacing.md)

                (Text(AppStrings.Onboarding.step04HeadlinePart1).font(.obHeadline(28))
                 + Text(AppStrings.Onboarding.step04HeadlineEmphasis).font(.obEmphasis(30)).foregroundColor(Palette.accent)
                 + Text(AppStrings.Onboarding.step04HeadlinePart2).font(.obHeadline(28)))
                .foregroundStyle(Palette.text)
            }
            .padding(.horizontal, Layout.Padding.screen.leading)

            // ── Progress bars card ─────────────────────────────────────────
            VStack(spacing: Spacing.lg) {
                ForEach(Array(store.topics.enumerated()), id: \.element.id) { idx, topic in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(topic.emoji) \(topic.name)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Palette.text)
                            Spacer()
                            Text("\(topic.matchedPhotos)")
                                .font(.custom("SpaceGrotesk-Bold", size: 15))
                                .foregroundStyle(pillarAccent(at: idx))
                        }
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.black.opacity(0.06))
                                .frame(height: 6)
                            GeometryReader { geo in
                                Capsule()
                                    .fill(pillarGradient(at: idx))
                                    .frame(
                                        width: geo.size.width * min(Double(topic.matchedPhotos) / 20.0, 1.0),
                                        height: 6
                                    )
                                    .animation(.easeOut(duration: 0.3), value: topic.matchedPhotos)
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
            .padding(Spacing.lg)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Radius.card))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            .padding(.horizontal, Layout.Padding.screen.leading)
            .padding(.top, Spacing.lg)

            Spacer()

            // ── Status + counter ───────────────────────────────────────────
            VStack(spacing: Spacing.xs) {
                Text(scanDone ? AppStrings.Onboarding.step04StatusReady : statusMessages[statusIdx % statusMessages.count])
                    .font(.obMono(10))
                    .foregroundStyle(scanDone ? Palette.green : Palette.text4)
                    .tracking(0.4)
                    .animation(.easeInOut(duration: 0.3), value: statusIdx)
                    .animation(.easeInOut(duration: 0.3), value: scanDone)

                Text("\(store.scannedCount) of \(store.totalToScan) photos scanned")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text4)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.Padding.screen.leading)

            ctaBar {
                Button {
                    Haptics.heavyTap()
                    store.send(.liveSortContinueTapped)
                } label: {
                    Text(scanDone ? AppStrings.Onboarding.step04CTAReady : AppStrings.Onboarding.step04CTALoading)
                }
                .buttonStyle(PrimaryButton())
                .disabled(!scanDone)
                .overlay(scanDone ? readyPulse : nil)
                .animation(.easeInOut(duration: 0.3), value: scanDone)
            }
        }
        .background(Palette.bg.ignoresSafeArea())
        .onReceive(statusTimer) { _ in
            guard !scanDone else { return }
            statusIdx += 1
        }
    }

    @ViewBuilder
    private var readyPulse: some View {
        RoundedRectangle(cornerRadius: Radius.button)
            .strokeBorder(Palette.accent.opacity(0.4), lineWidth: 2)
            .scaleEffect(1.04)
            .opacity(0.6)
    }
}

// MARK: - Step 05: Your Turn

private struct YourTurnStep: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    @FocusState private var promptFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // ── Fixed header ───────────────────────────────────────────────
            let total = store.totalMatchedPhotos
            VStack(alignment: .leading, spacing: Spacing.sm) {
                obEyebrow(
                    total > 0 ? AppStrings.Onboarding.step05Eyebrow(total) : AppStrings.Onboarding.step05EyebrowEmpty,
                    color: Palette.green
                )
                .padding(.top, Spacing.md)

                (Text(AppStrings.Onboarding.step05HeadlinePart1).font(.obHeadline(28))
                 + Text(AppStrings.Onboarding.step05HeadlineEmphasis).font(.obEmphasis(30))
                    .foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255)))
                .foregroundStyle(Palette.text)
            }
            .padding(.horizontal, Layout.Padding.screen.leading)

            // ── Input card + pick pills ────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(AppStrings.Onboarding.step05InputLabel)
                        .font(.obMono(8))
                        .foregroundStyle(Palette.text4)
                        .tracking(0.8)

                    TextField(AppStrings.Onboarding.step05InputPlaceholder, text: $store.firstPromptText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Palette.text)
                        .focused($promptFocused)
                        .submitLabel(.done)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)

                if !store.topPillars.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(Array(store.topPillars.enumerated()), id: \.element.id) { idx, topic in
                            Button {
                                Haptics.lightTap()
                                promptFocused = false
                                store.send(.yourTurnPillarPillTapped(topic.id))
                            } label: {
                                HStack(spacing: Spacing.sm) {
                                    Text(topic.emoji).font(.system(size: 14))
                                    Text(topic.name).font(.obBody(12))
                                    if topic.matchedPhotos > 0 {
                                        Text(AppStrings.Onboarding.step05PhotosCount(topic.matchedPhotos))
                                            .font(Typography.caption)
                                            .foregroundStyle(Palette.text4)
                                    }
                                    Spacer()
                                }
                                .foregroundStyle(store.selectedPillarPillID == topic.id ? pillarAccent(at: idx) : Palette.text)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    store.selectedPillarPillID == topic.id
                                        ? pillarAccent(at: idx).opacity(0.08)
                                        : Color.black.opacity(0.04),
                                    in: RoundedRectangle(cornerRadius: 100)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 100)
                                        .strokeBorder(
                                            store.selectedPillarPillID == topic.id
                                                ? pillarAccent(at: idx).opacity(0.3)
                                                : .clear,
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.2), value: store.selectedPillarPillID)
                        }
                    }
                }

                // Cloud AI toggle
                HStack(spacing: Spacing.sm) {
                    Image(systemName: store.cloudAIEnabled ? "cloud.bolt.fill" : "iphone")
                        .font(.system(size: 14))
                        .foregroundStyle(store.cloudAIEnabled ? Palette.accent : Palette.text3)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(AppStrings.Onboarding.step05CloudAITitle)
                            .font(Typography.subheadline)
                            .foregroundStyle(Palette.text2)
                        Text(store.cloudAIEnabled ? AppStrings.Onboarding.step05CloudAIOnBody : AppStrings.Onboarding.step05CloudAIOffBody)
                            .font(Typography.caption)
                            .foregroundStyle(Palette.text4)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { store.cloudAIEnabled },
                        set: { _ in store.send(.cloudAIToggled) }
                    ))
                    .labelsHidden()
                    .tint(Palette.accent)
                }
                .padding(Spacing.md)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
                .padding(.top, Spacing.xxs)
            }
            .padding(.horizontal, Layout.Padding.screen.leading)
            .padding(.top, Spacing.lg)

            Spacer()

            ctaBar {
                Button {
                    Haptics.success()
                    promptFocused = false
                    store.send(.generateFirstPostTapped)
                } label: {
                    if store.isSaving {
                        ProgressView().tint(Palette.onAccent)
                    } else {
                        Text(AppStrings.Onboarding.step05CTA)
                    }
                }
                .buttonStyle(PrimaryButton())
                .disabled(store.isSaving || store.firstPromptText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .background(Palette.bg.ignoresSafeArea())
    }
}

// MARK: - Shared layout helpers

private func obEyebrow(_ text: LocalizedStringKey, color: Color) -> some View {
    Text(text)
        .font(.obMono(9))
        .foregroundStyle(color)
        .tracking(0.54)
        .textCase(.uppercase)
}

private func ctaBar<Content: View>(dark: Bool = false, @ViewBuilder content: () -> Content) -> some View {
    VStack(spacing: 0) {
        content()
            .padding(.horizontal, Layout.Padding.screen.leading)
            .padding(.bottom, Spacing.xxl)
            .padding(.top, Spacing.md)
            .background(dark ? Color.black.opacity(0.25) : Palette.bg)
    }
}

// MARK: - Previews

#Preview("01 · Before / After") {
    BeforeAfterStep(onContinue: {})
}

#Preview("01 · Sorted State") {
    BeforeAfterStep(onContinue: {}, startSorted: true)
}

#Preview("02 · Magic Demo") {
    MagicDemoStep(store: Store(
        initialState: OnboardingFeature.State(step: .magicDemo),
        reducer: { OnboardingFeature() }
    ))
}

#Preview("03 · Pillars") {
    PillarsStep(store: Store(
        initialState: OnboardingFeature.State(
            step: .pillars,
            topics: IdentifiedArray(uniqueElements: [
                OnboardingTopic(id: UUID(), name: "Cars", emoji: "🚗", about: ""),
                OnboardingTopic(id: UUID(), name: "Food & Coffee", emoji: "☕", about: ""),
                OnboardingTopic(id: UUID(), name: "Build in public", emoji: "💼", about: ""),
                OnboardingTopic(id: UUID(), name: "Travel", emoji: "🌍", about: ""),
            ])
        ),
        reducer: { OnboardingFeature() }
    ))
}

#Preview("04 · Live Sort") {
    LiveSortStep(store: Store(
        initialState: OnboardingFeature.State(
            step: .liveSort,
            topics: IdentifiedArray(uniqueElements: [
                OnboardingTopic(id: UUID(), name: "Cars", emoji: "🚗", about: "", matchedPhotos: 11),
                OnboardingTopic(id: UUID(), name: "Food & Coffee", emoji: "☕", about: "", matchedPhotos: 7),
                OnboardingTopic(id: UUID(), name: "Travel", emoji: "🌍", about: "", matchedPhotos: 14),
            ]),
            scanProgress: 0.6,
            scannedCount: 12,
            totalToScan: 20
        ),
        reducer: { OnboardingFeature() }
    ))
}

#Preview("05 · Your Turn") {
    YourTurnStep(store: Store(
        initialState: OnboardingFeature.State(
            step: .yourTurn,
            topics: IdentifiedArray(uniqueElements: [
                OnboardingTopic(id: UUID(), name: "Travel", emoji: "🌍", about: "", matchedPhotos: 14),
                OnboardingTopic(id: UUID(), name: "Cars", emoji: "🚗", about: "", matchedPhotos: 11),
                OnboardingTopic(id: UUID(), name: "Food & Coffee", emoji: "☕", about: "", matchedPhotos: 7),
            ]),
            scanProgress: 1.0,
            scannedCount: 20,
            totalToScan: 20,
            firstPromptText: "A post about travel",
            selectedPillarPillID: nil
        ),
        reducer: { OnboardingFeature() }
    ))
}
