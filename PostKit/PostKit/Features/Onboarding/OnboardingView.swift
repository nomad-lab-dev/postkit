// MARK: - PostKit
// OnboardingView.swift — Root container + photo access gate

import ComposableArchitecture
import SwiftUI

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
                    }
                }
            }
            .animation(.easeInOut(duration: 0.35), value: store.step)
            .animation(.easeInOut(duration: 0.3), value: store.photoAccessDenied)
            .navigationBarHidden(true)
            .gesture(
                DragGesture(minimumDistance: 40)
                    .onEnded { value in
                        let isRightSwipe = value.translation.width > 80
                        let isHorizontal = abs(value.translation.width) > abs(value.translation.height) * 1.5
                        if isRightSwipe && isHorizontal && !store.photoAccessDenied {
                            Haptics.lightTap()
                            store.send(.goBackTapped)
                        }
                    }
            )
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

#Preview("04 · Live Sort — Scanning") {
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

#Preview("04 · Live Sort — Your Turn") {
    let travelID = UUID()
    return LiveSortStep(store: Store(
        initialState: OnboardingFeature.State(
            step: .liveSort,
            topics: IdentifiedArray(uniqueElements: [
                OnboardingTopic(id: travelID, name: "Travel", emoji: "🌍", about: "", matchedPhotos: 14),
                OnboardingTopic(id: UUID(), name: "Cars", emoji: "🚗", about: "", matchedPhotos: 11),
                OnboardingTopic(id: UUID(), name: "Food & Coffee", emoji: "☕", about: "", matchedPhotos: 7),
            ]),
            scanProgress: 1.0,
            scannedCount: 20,
            totalToScan: 20,
            firstPromptText: "A post about travel",
            selectedPillarPillID: travelID
        ),
        reducer: { OnboardingFeature() }
    ))
}
