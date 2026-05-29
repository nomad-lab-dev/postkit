// MARK: - PostKit
// OnboardingView.swift — Onboarding UI: welcome, AI topic setup, scanning progress, completion

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
                    case .topicSetup:
                        TopicSetupStep(store: store)
                    case .scanning:
                        ScanningStep(
                            progress: store.scanProgress,
                            scannedCount: store.scannedCount,
                            totalToScan: store.totalToScan
                        )
                    case .scanComplete:
                        ScanCompleteStep(
                            topics: Array(store.topics),
                            totalMatched: store.totalMatchedPhotos,
                            emptyGallery: store.emptyGallery,
                            isSaving: store.isSaving,
                            cloudAIEnabled: store.cloudAIEnabled,
                            onCloudAIToggled: { store.send(.cloudAIToggled) },
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

                Text("PostKit needs to browse your entire photo library to classify and organize your content. Without full access, we can't scan your photos.")
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

// MARK: - Topic Setup

private struct TopicSetupStep: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    @FocusState private var inputFocused: Bool
    @FocusState private var editingFocusedID: OnboardingTopic.ID?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("What do you post about?")
                            .font(Typography.title2)
                            .fontWeight(.bold)

                        Text("Add the topics you create content around. Tap a topic to rename it.")
                            .font(Typography.subheadline)
                            .foregroundStyle(Palette.text3)
                    }
                    .padding(.top, Spacing.lg)

                    HStack(spacing: Spacing.sm) {
                        TextField("e.g. cars, travel, food...", text: $store.topicInput)
                            .font(Typography.body)
                            .textFieldStyle(.plain)
                            .padding(Spacing.sm)
                            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.input))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.input)
                                    .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                            )
                            .focused($inputFocused)
                            .onSubmit {
                                store.send(.addTopicTapped)
                            }

                        Button {
                            Haptics.tap()
                            store.send(.addTopicTapped)
                        } label: {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                                .frame(width: 44, height: 44)
                                .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.input))
                                .foregroundStyle(Palette.onAccent)
                        }
                        .disabled(store.topicInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    if !store.topics.isEmpty {
                        VStack(spacing: Spacing.sm) {
                            ForEach(store.topics) { topic in
                                OnboardingTopicCard(
                                    topic: topic,
                                    isEditing: store.editingTopicID == topic.id,
                                    editingFocusedID: $editingFocusedID,
                                    onTap: { store.send(.topicTapped(topic.id)) },
                                    onNameChanged: { store.send(.topicNameEdited(topic.id, $0)) },
                                    onEditDone: { store.send(.topicEditDone) },
                                    onRemove: { store.send(.removeTopicTapped(topic.id)) }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .opacity
                                ))
                            }
                        }
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.topics.count)
                    }

                    VStack(spacing: Spacing.sm) {
                        Button {
                            Haptics.tap()
                            let hasText = !store.topicInput.trimmingCharacters(in: .whitespaces).isEmpty
                            if hasText {
                                store.send(.addTopicTapped)
                            } else {
                                inputFocused = true
                            }
                        } label: {
                            Label("Add another topic", systemImage: "plus")
                                .font(Typography.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(Palette.onAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.button))
                        }
                        .buttonStyle(.plain)

                        Button {
                            Haptics.heavyTap()
                            inputFocused = false
                            store.send(.startScanTapped)
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Text(store.topics.isEmpty
                                     ? "Scan My Library"
                                     : "Continue with \(store.topics.count) topic\(store.topics.count == 1 ? "" : "s")")
                                if !store.topics.isEmpty {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .font(Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(store.topics.isEmpty ? Palette.text4 : Palette.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                store.topics.isEmpty ? Palette.surface : Palette.accentTint,
                                in: RoundedRectangle(cornerRadius: Radius.button)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.button)
                                    .strokeBorder(
                                        store.topics.isEmpty ? Palette.border.opacity(0.5) : Palette.accent.opacity(0.3),
                                        lineWidth: store.topics.isEmpty ? Layout.Border.thin : 1.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(store.topics.isEmpty)
                        .animation(.easeInOut(duration: 0.25), value: store.topics.isEmpty)
                    }
                    .padding(.top, Spacing.lg)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .onAppear { inputFocused = true }
        .onChange(of: store.editingTopicID) { _, newID in
            editingFocusedID = newID
        }
    }
}

private struct OnboardingTopicCard: View {
    let topic: OnboardingTopic
    let isEditing: Bool
    var editingFocusedID: FocusState<OnboardingTopic.ID?>.Binding
    let onTap: () -> Void
    let onNameChanged: (String) -> Void
    let onEditDone: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(topic.emoji)
                .font(.system(size: 28))
                .frame(width: 36)

            if isEditing {
                TextField("Topic name", text: Binding(
                    get: { topic.name },
                    set: { onNameChanged($0) }
                ))
                .font(Typography.headline)
                .foregroundStyle(Palette.text)
                .focused(editingFocusedID, equals: topic.id)
                .onSubmit { onEditDone() }
            } else {
                Text(topic.name)
                    .font(Typography.headline)
                    .foregroundStyle(Palette.text)
            }

            Spacer(minLength: 0)

            Button {
                Haptics.lightTap()
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Palette.text4)
            }
            .buttonStyle(.plain)
        }
        .padding(Layout.Padding.card)
        .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(
                    isEditing ? Palette.accent : Palette.accent.opacity(0.3),
                    lineWidth: isEditing ? Layout.Border.regular : Layout.Border.thin
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing { onTap() }
        }
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

// MARK: - Previews

#Preview("Welcome") {
    WelcomeStep(onGetStarted: {})
}

#Preview("Topic Setup") {
    TopicSetupStep(store: Store(
        initialState: OnboardingFeature.State(
            step: .topicSetup,
            topics: [
                OnboardingTopic(id: UUID(), name: "Food & Coffee", emoji: "☕️", about: ""),
                OnboardingTopic(id: UUID(), name: "Tech & Dev", emoji: "💻", about: ""),
                OnboardingTopic(id: UUID(), name: "Travel", emoji: "✈️", about: "")
            ]
        ),
        reducer: { OnboardingFeature() }
    ))
}

#Preview("Scanning") {
    ScanningStep(progress: 0.6, scannedCount: 12, totalToScan: 20)
}

#Preview("Scan Complete") {
    ScanCompleteStep(
        topics: [
            OnboardingTopic(id: UUID(), name: "Food & Coffee", emoji: "☕️", about: "", matchedPhotos: 47),
            OnboardingTopic(id: UUID(), name: "Tech & Dev", emoji: "💻", about: "", matchedPhotos: 23),
            OnboardingTopic(id: UUID(), name: "Travel", emoji: "✈️", about: "", matchedPhotos: 61)
        ],
        totalMatched: 131,
        emptyGallery: false,
        isSaving: false,
        cloudAIEnabled: true,
        onCloudAIToggled: {},
        onStart: {}
    )
}

// MARK: - Scan Complete

private struct ScanCompleteStep: View {
    let topics: [OnboardingTopic]
    let totalMatched: Int
    let emptyGallery: Bool
    let isSaving: Bool
    let cloudAIEnabled: Bool
    let onCloudAIToggled: () -> Void
    let onStart: () -> Void

    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: emptyGallery ? "photo.on.rectangle.angled" : "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(emptyGallery ? Palette.text3 : Palette.green)
                .scaleEffect(showCheckmark ? 1 : 0.3)
                .opacity(showCheckmark ? 1 : 0)

            VStack(spacing: Spacing.sm) {
                Text(emptyGallery ? "No Photos Yet" : "Library Scanned!")
                    .font(Typography.title)

                Text(subtitle)
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.text3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }

            if !emptyGallery && !topics.isEmpty {
                VStack(spacing: Spacing.sm) {
                    ForEach(topics) { topic in
                        HStack(spacing: Layout.Stack.comfy) {
                            Text(topic.emoji).font(.system(size: 24))
                            Text(topic.name).font(Typography.headline)
                            Spacer()
                            Text("\(topic.matchedPhotos)")
                                .font(Typography.title3)
                                .foregroundStyle(topic.matchedPhotos > 0 ? Palette.accent : Palette.text4)
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
            }

            if totalMatched == 0 && !emptyGallery && !topics.isEmpty {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Palette.accent)
                    Text("The full scan will classify your entire library — this was just a quick preview.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)
                }
                .padding(.horizontal, Spacing.xl)
            }

            cloudAICard
                .padding(.horizontal, Spacing.lg)

            Spacer()

            Button {
                Haptics.success()
                onStart()
            } label: {
                if isSaving {
                    ProgressView()
                        .tint(Palette.onAccent)
                } else {
                    Text("Start PostKit")
                }
            }
            .buttonStyle(PrimaryButton())
            .disabled(isSaving)
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .task {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCheckmark = true
            }
        }
    }

    private var subtitle: LocalizedStringKey {
        if emptyGallery {
            return "Your photo library is empty. Add some photos and PostKit will classify them for you."
        }
        if totalMatched == 0 && !topics.isEmpty {
            return "No matches in the quick scan — don't worry, the full scan will find more."
        }
        return "\(totalMatched) photos matched across your topics"
    }

    private var cloudAICard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "cloud.bolt")
                    .font(.system(size: 20))
                    .foregroundStyle(Palette.accent)
                Text("Cloud AI Enhancement")
                    .font(Typography.headline)
                    .foregroundStyle(Palette.text)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { cloudAIEnabled },
                    set: { _ in onCloudAIToggled() }
                ))
                .labelsHidden()
                .tint(Palette.accent)
            }

            Text(cloudAIEnabled
                 ? "When on-device classification isn't confident, photos are sent to Google Gemini for better accuracy. Photos are processed but never stored."
                 : "All photo classification stays on your device. You can enable Cloud AI later in Settings.")
                .font(Typography.caption)
                .foregroundStyle(Palette.text3)

            HStack(spacing: Spacing.sm) {
                Image(systemName: cloudAIEnabled ? "antenna.radiowaves.left.and.right" : "lock.shield")
                    .font(Typography.caption)
                    .foregroundStyle(cloudAIEnabled ? Palette.yellow : Palette.green)
                Text(cloudAIEnabled ? "Better accuracy, requires internet" : "100% private, on-device only")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text2)
            }
        }
        .padding(Layout.Padding.card)
        .cardStyle()
        .animation(.easeInOut(duration: 0.2), value: cloudAIEnabled)
    }
}
