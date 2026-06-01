import ComposableArchitecture
import SwiftUI

struct PillarsStep: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    @FocusState private var inputFocused: Bool
    @FocusState private var editingFocusID: OnboardingTopic.ID?
    @State private var phase: Int = 0

    private var ctaEnabled: Bool {
        store.topics.count >= 2 && store.topics.count <= 7
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                TypewriterText(
                    text: localizedString(for: AppStrings.Onboarding.step03Eyebrow),
                    font: .obMono(9), color: Palette.text4, show: phase >= 1
                )
                .padding(.top, Spacing.md)

                TypewriterHeadline(
                    segments: [
                        HeadlineSegment(text: localizedString(for: AppStrings.Onboarding.step03HeadlinePart1), font: .obHeadline(26), color: Palette.text),
                        HeadlineSegment(text: localizedString(for: AppStrings.Onboarding.step03HeadlineEmphasis), font: .obEmphasis(28), color: Color(red: 0/255, green: 122/255, blue: 255/255)),
                        HeadlineSegment(text: localizedString(for: AppStrings.Onboarding.step03HeadlinePart2), font: .obHeadline(26), color: Palette.text),
                    ],
                    show: phase >= 1,
                    onFinished: {
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(120))
                            phase = 3
                                try? await Task.sleep(for: .milliseconds(450))
                                phase = 4
                        }
                    }
                )

                Text(AppStrings.Onboarding.step03Body)
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.text3)
                    .fixedSize(horizontal: false, vertical: true)
                    .obEntrance(show: phase >= 3)
            }
            .padding(.horizontal, Layout.Padding.screen.leading)
            .padding(.bottom, Spacing.md)

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
            .obEntrance(show: phase >= 3)

            Spacer()

            ctaBar {
                Button {
                    guard ctaEnabled else { return }
                    Haptics.heavyTap()
                    inputFocused = false
                    store.send(.pillarsContinueTapped)
                } label: {
                    if ctaEnabled {
                        Text(AppStrings.Onboarding.step03CTAContinue)
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
            .obCTAEntrance(show: phase >= 4)
        }
        .background(Palette.bg.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: store.editingTopicID) { _, newID in
            editingFocusID = newID
        }
        .task {
            try? await Task.sleep(for: .milliseconds(80))
            phase = 1
        }
    }
}

// MARK: - Pillar row

struct PillarRow: View {
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
