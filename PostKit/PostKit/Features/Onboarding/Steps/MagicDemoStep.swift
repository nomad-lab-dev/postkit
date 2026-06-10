import ComposableArchitecture
import SwiftUI

struct MagicDemoStep: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    @State private var phase: Int = 0

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            TypewriterText(
                                text: localizedString(for: AppStrings.Onboarding.step02Eyebrow),
                                font: .obMono(9), color: Palette.text4, show: phase >= 1
                            )
                            .padding(.top, Spacing.md)

                            TypewriterHeadline(
                                segments: [
                                    HeadlineSegment(text: localizedString(for: AppStrings.Onboarding.step02HeadlinePart1), font: .obHeadline(28), color: Palette.text),
                                    HeadlineSegment(text: localizedString(for: AppStrings.Onboarding.step02HeadlineEmphasis), font: .obEmphasis(30), color: Color(red: 1, green: 149/255, blue: 0)),
                                    HeadlineSegment(text: localizedString(for: AppStrings.Onboarding.step02HeadlinePart2), font: .obHeadline(28), color: Palette.text),
                                ],
                                show: phase >= 1,
                                onFinished: {
                                    Task { @MainActor in
                                        try? await Task.sleep(for: .milliseconds(120))
                                        phase = 3
                                    }
                                }
                            )

                            HStack(spacing: Spacing.xs) {
                                ForEach(OnboardingFeature.DemoChip.allCases, id: \.self) { chip in
                                    Button {
                                        Haptics.lightTap()
                                        store.send(.demoChipTapped(chip))
                                    } label: {
                                        Text(chip.label)
                                            .font(.obBody(12))
                                            .foregroundStyle(store.activeDemoChip == chip ? Color(red: 0/255, green: 122/255, blue: 255/255) : Palette.text2)
                                            .padding(.horizontal, Spacing.sm)
                                            .padding(.vertical, 6)
                                            .background(
                                                store.activeDemoChip == chip ? Color(red: 0/255, green: 122/255, blue: 255/255).opacity(0.1) : Color.black.opacity(0.04),
                                                in: Capsule()
                                            )
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(store.activeDemoChip == chip ? Color(red: 0/255, green: 122/255, blue: 255/255).opacity(0.35) : Color.black.opacity(0.1), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.easeInOut(duration: 0.2), value: store.activeDemoChip)
                                }
                            }
                            .obEntrance(show: phase >= 3)

                            MagicDemoCard(data: DemoData.make(store.activeDemoChip), onShareVisible: {
                                phase = 4
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    proxy.scrollTo("demoBottom", anchor: .bottom)
                                }
                            })
                            .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
                            .obEntrance(show: phase >= 3)

                            Color.clear.frame(height: 1).id("demoBottom")
                        }
                        .padding(.horizontal, Layout.Padding.screen.leading)
                        .padding(.bottom, 28)
                    }
                    .scrollClipDisabled()
                }

                ctaBar {
                    Button {
                        Haptics.heavyTap()
                        store.send(.magicDemoContinueTapped)
                    } label: {
                        Text(AppStrings.Onboarding.step02CTA)
                    }
                    .buttonStyle(PrimaryButton())
                }
                .obCTAEntrance(show: phase >= 4)
            }
            .task {
                try? await Task.sleep(for: .milliseconds(80))
                phase = 1
            }
        }
    }
}

// MARK: - Magic Demo Card

struct MagicDemoCard: View {
    let data: DemoData
    var onShareVisible: (() -> Void)? = nil

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
            // Chat bubble — typewriter prompt fill
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
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(red: 0/255, green: 122/255, blue: 255/255))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.bottom, 6)

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
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
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
            typedPrompt = data.prompt
            withAnimation(.easeOut(duration: 0.2)) {
                showGrid = true
                revealedCount = 4
                showCaption = true
                showShare = true
            }
            onShareVisible?()
            return
        }

        showCursor = true
        for char in data.prompt {
            guard !Task.isCancelled else { return }
            typedPrompt.append(char)
            try? await Task.sleep(for: .milliseconds(Int.random(in: 40...75)))
        }
        showCursor = false

        try? await Task.sleep(for: .milliseconds(280))

        withAnimation { showLoading = true }
        try? await Task.sleep(for: .milliseconds(1400))
        withAnimation { showLoading = false }
        try? await Task.sleep(for: .milliseconds(120))

        withAnimation(.easeOut(duration: 0.3)) { showGrid = true }
        try? await Task.sleep(for: .milliseconds(180))

        for i in 1...4 {
            guard !Task.isCancelled else { return }
            revealedCount = i
            try? await Task.sleep(for: .milliseconds(220))
        }

        try? await Task.sleep(for: .milliseconds(200))

        withAnimation(.easeOut(duration: 0.4)) { showCaption = true }
        try? await Task.sleep(for: .milliseconds(400))

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showShare = true }
        onShareVisible?()
    }
}
