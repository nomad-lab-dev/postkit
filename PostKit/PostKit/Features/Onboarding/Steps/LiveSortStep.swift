import Combine
import ComposableArchitecture
import SwiftUI

struct LiveSortStep: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    @FocusState private var promptFocused: Bool
    @State private var statusIdx: Int = 0
    @State private var statusTimer = Timer.publish(every: 1.8, on: .main, in: .common).autoconnect()
    @State private var phase: Int = 0

    private let statusMessages: [LocalizedStringKey] = AppStrings.Onboarding.step04StatusMessages
    private var scanDone: Bool { store.scanProgress >= 1.0 }
    private var total: Int { store.totalMatchedPhotos }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Group {
                    if scanDone {
                        TypewriterText(
                            text: total > 0 ? "DONE · \(total) PHOTOS SORTED" : localizedString(for: AppStrings.Onboarding.step05EyebrowEmpty),
                            font: .obMono(9), color: Palette.green, show: scanDone
                        )
                    } else {
                        TypewriterText(
                            text: localizedString(for: AppStrings.Onboarding.step04Eyebrow),
                            font: .obMono(9), color: Palette.text4, show: phase >= 1,
                            onFinished: { phase = 2 }
                        )
                    }
                }
                .padding(.top, Spacing.md)
                .animation(.easeInOut(duration: 0.4), value: scanDone)

                if scanDone {
                    TypewriterHeadline(
                        segments: [
                            HeadlineSegment(text: localizedString(for: AppStrings.Onboarding.step05HeadlinePart1), font: .obHeadline(28), color: Palette.text),
                            HeadlineSegment(text: localizedString(for: AppStrings.Onboarding.step05HeadlineEmphasis), font: .obEmphasis(30), color: Color(red: 0/255, green: 122/255, blue: 255/255)),
                        ],
                        show: scanDone
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    TypewriterHeadline(
                        segments: [
                            HeadlineSegment(text: localizedString(for: AppStrings.Onboarding.step04HeadlinePart1), font: .obHeadline(28), color: Palette.text),
                            HeadlineSegment(text: localizedString(for: AppStrings.Onboarding.step04HeadlineEmphasis), font: .obEmphasis(30), color: Palette.accent),
                            HeadlineSegment(text: localizedString(for: AppStrings.Onboarding.step04HeadlinePart2), font: .obHeadline(28), color: Palette.text),
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
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, Layout.Padding.screen.leading)
            .animation(.spring(response: 0.5, dampingFraction: 0.82), value: scanDone)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Relative progress bars — tappable post-scan to select a pillar
                    let maxMatched = max(store.maxMatchedPhotos, 1)
                    VStack(spacing: Spacing.lg) {
                        ForEach(Array(store.topics.enumerated()), id: \.element.id) { idx, topic in
                            let isSelected = scanDone && store.selectedPillarPillID == topic.id
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("\(topic.emoji) \(topic.name)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(isSelected ? pillarAccent(at: idx) : Palette.text)
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
                                                width: geo.size.width * min(Double(topic.matchedPhotos) / Double(maxMatched), 1.0),
                                                height: 6
                                            )
                                            .animation(.easeOut(duration: 0.3), value: topic.matchedPhotos)
                                    }
                                    .frame(height: 6)
                                }
                            }
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                isSelected ? pillarAccent(at: idx).opacity(0.06) : .clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isSelected)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard scanDone else { return }
                                Haptics.lightTap()
                                store.send(.yourTurnPillarPillTapped(topic.id))
                            }
                        }
                    }
                    .padding(Spacing.lg)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: Radius.card))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                    if !scanDone {
                        VStack(spacing: Spacing.xs) {
                            Text(statusMessages[statusIdx % statusMessages.count])
                                .font(.obMono(10))
                                .foregroundStyle(Palette.text4)
                                .tracking(0.4)
                                .animation(.easeInOut(duration: 0.3), value: statusIdx)
                            Text("\(store.scannedCount) of \(store.totalToScan) photos scanned")
                                .font(Typography.caption)
                                .foregroundStyle(Palette.text4)
                        }
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                    } else {
                        yourTurnContent
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, Layout.Padding.screen.leading)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .animation(.spring(response: 0.55, dampingFraction: 0.82), value: scanDone)
            .obEntrance(show: phase >= 3)

            ctaBar {
                Button {
                    guard scanDone else { return }
                    Haptics.success()
                    promptFocused = false
                    store.send(.generateFirstPostTapped)
                } label: {
                    if store.isSaving {
                        ProgressView().tint(Palette.onAccent)
                    } else {
                        Text(scanDone ? AppStrings.Onboarding.step05CTA : AppStrings.Onboarding.step04CTALoading)
                    }
                }
                .buttonStyle(PrimaryButton())
                .disabled(!scanDone || store.isSaving)
                .animation(.easeInOut(duration: 0.3), value: scanDone)
            }
            .obCTAEntrance(show: phase >= 4)
        }
        .background(Palette.bg.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onReceive(statusTimer) { _ in
            guard !scanDone else { return }
            statusIdx += 1
        }
        .task {
            try? await Task.sleep(for: .milliseconds(80))
            phase = 1
        }
    }

    @ViewBuilder
    private var yourTurnContent: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
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
    }
}
