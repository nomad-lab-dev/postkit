import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        NavigationStack {
            Group {
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
            .animation(.easeInOut(duration: 0.3), value: store.step)
            .navigationTitle(AppStrings.Onboarding.welcomeTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
        .alert($store.scope(state: \.alert, action: \.alert))
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

            Button("Get Started", action: onGetStarted)
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

                Button("Scan My Library", action: onScan)
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
        Button(action: onTap) {
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

            Button("Start PostKit", action: onStart)
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
