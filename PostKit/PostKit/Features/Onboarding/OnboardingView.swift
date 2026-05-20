import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if store.photoAccessDenied {
                    PhotoAccessStep(
                        onOpenSettings: { store.send(.openSettingsTapped) }
                    )
                } else {
                    switch store.step {
                    case .welcome:
                        WelcomeStep(onGetStarted: { store.send(.getStartedTapped) })
                    case .pillarSetup:
                        PillarSetupStep(
                            pillars: store.availablePillars,
                            selectedCount: store.selectedPillarCount,
                            onToggle: { store.send(.pillarToggled($0)) },
                            onScan: { store.send(.startScanTapped) }
                        )
                    case .scanning:
                        ScanningStep(
                            progress: store.scanProgress,
                            scannedCount: store.scannedCount,
                            totalToScan: store.totalToScan
                        )
                    case .scanComplete:
                        ScanCompleteStep(
                            pillars: store.availablePillars.filter(\.isSelected),
                            totalMatched: store.totalMatchedPhotos,
                            onStart: { store.send(.startPostKitTapped) }
                        )
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: store.step)
            .animation(.easeInOut(duration: 0.3), value: store.photoAccessDenied)
            .navigationTitle(AppStrings.Onboarding.welcomeTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
        .alert($store.scope(state: \.alert, action: \.alert))
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.send(.sceneDidBecomeActive)
            }
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
                Text("Full Photo Access Required")
                    .font(Typography.title)
                    .multilineTextAlignment(.center)

                Text("PostKit needs to browse your entire photo library to classify and organize your content by pillar. Without full access, we can't scan your photos.")
                    .font(Typography.body)
                    .foregroundStyle(Palette.text3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }

            VStack(spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(Palette.accent)
                    Text("Your photos never leave your device")
                        .font(Typography.subheadline)
                        .foregroundStyle(Palette.text2)
                }
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "eye.slash")
                        .foregroundStyle(Palette.accent)
                    Text("We only store references, not copies")
                        .font(Typography.subheadline)
                        .foregroundStyle(Palette.text2)
                }
            }

            Spacer()

            Button {
                Haptics.tap()
                onOpenSettings()
            } label: {
                Label("Open Settings", systemImage: "gear")
            }
            .buttonStyle(PrimaryButton())
            .padding(.horizontal, Spacing.xl)

            Text("Go to Settings > PostKit > Photos > Full Access")
                .font(Typography.caption)
                .foregroundStyle(Palette.text4)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
        }
    }
}

// MARK: - Welcome

private struct WelcomeStep: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()

            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            VStack(spacing: Spacing.sm) {
                Text(AppStrings.Onboarding.welcomeTitle)
                    .font(Typography.largeTitle)

                Text(AppStrings.Onboarding.welcomeSubtitle)
                    .font(Typography.body)
                    .foregroundStyle(Palette.text3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
            }

            Spacer()

            Button("Get Started") { Haptics.tap(); onGetStarted() }
                .buttonStyle(PrimaryButton())
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
        }
    }
}

// MARK: - Pillar Setup

private struct PillarSetupStep: View {
    let pillars: IdentifiedArrayOf<PillarOption>
    let selectedCount: Int
    let onToggle: (PillarOption.ID) -> Void
    let onScan: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.sm) {
                Text("Choose Your Pillars")
                    .font(Typography.title)

                Text("Select the content categories that match your brand.")
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.text3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            .padding(.top, Spacing.lg)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: Spacing.md
            ) {
                ForEach(pillars) { pillar in
                    PillarSetupCard(pillar: pillar) {
                        onToggle(pillar.id)
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            VStack(spacing: Spacing.sm) {
                if selectedCount > 0 {
                    Text("\(selectedCount) pillar\(selectedCount == 1 ? "" : "s") selected")
                        .font(Typography.footnote)
                        .foregroundStyle(Palette.text3)
                }

                Button("Scan My Library") { Haptics.heavyTap(); onScan() }
                    .buttonStyle(PrimaryButton())
                    .disabled(selectedCount == 0)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
    }
}

private struct PillarSetupCard: View {
    let pillar: PillarOption
    let onTap: () -> Void

    var body: some View {
        Button { Haptics.selection(); onTap() } label: {
            VStack(spacing: Spacing.sm) {
                Text(pillar.emoji).font(.system(size: 36))
                Text(pillar.name)
                    .font(Typography.headline)
                    .foregroundStyle(Palette.text)
            }
            .frame(maxWidth: .infinity)
            .padding(Layout.Padding.card)
            .background(pillar.isSelected ? Palette.accentTint : Palette.glassStrong)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(
                        pillar.isSelected ? Palette.accent : Palette.border,
                        lineWidth: pillar.isSelected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: pillar.isSelected)
    }
}

// MARK: - Scanning

private struct ScanningStep: View {
    let progress: Double
    let scannedCount: Int
    let totalToScan: Int

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()

            Image(systemName: "viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse, isActive: true)

            VStack(spacing: Spacing.sm) {
                Text(AppStrings.Onboarding.scanTitle)
                    .font(Typography.title)

                Text("\(scannedCount) / \(totalToScan) photos scanned")
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.text3)
            }

            ProgressBar(value: progress, gradient: true)
                .padding(.horizontal, Spacing.xxxl + Spacing.xs)

            Spacer()
        }
    }
}

// MARK: - Scan Complete

private struct ScanCompleteStep: View {
    let pillars: [PillarOption]
    let totalMatched: Int
    let onStart: () -> Void

    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Palette.green)
                .scaleEffect(showCheckmark ? 1 : 0.3)
                .opacity(showCheckmark ? 1 : 0)

            VStack(spacing: Spacing.sm) {
                Text("Library Scanned!")
                    .font(Typography.title)

                Text("\(totalMatched) photos matched across your pillars")
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.text3)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: Spacing.sm) {
                ForEach(pillars) { pillar in
                    HStack(spacing: Layout.Stack.comfy) {
                        Text(pillar.emoji).font(.system(size: 24))
                        Text(pillar.name).font(Typography.headline)
                        Spacer()
                        Text("\(pillar.matchedPhotos)")
                            .font(Typography.title3)
                            .foregroundStyle(pillar.matchedPhotos > 0 ? Palette.accent : Palette.text4)
                        Text("photos")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.text3)
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
            .padding(Layout.Padding.card)
            .cardStyle()
            .padding(.horizontal, Spacing.lg)

            Spacer()

            Button("Start PostKit") { Haptics.success(); onStart() }
                .buttonStyle(PrimaryButton())
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
        }
        .task {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCheckmark = true
            }
        }
    }
}
