// MARK: - PostKit
// SettingsView.swift — Settings UI: topics list, notifications toggle, about section

import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        List {
            subscriptionSection
            topicsSection
            privacySection
            notificationsSection
            aboutSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(AppStrings.Settings.title)
        .task { await store.send(.onAppear).finish() }
        .sheet(item: $store.scope(state: \.topicEditor, action: \.topicEditor)) { editorStore in
            NavigationStack {
                TopicEditorView(store: editorStore)
            }
        }
        .sheet(item: $store.scope(state: \.paywall, action: \.paywall)) { paywallStore in
            PaywallView(store: paywallStore)
                .presentationDetents([.large])
        }
    }

    private var subscriptionSection: some View {
        Section {
            if store.isProUser {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Palette.accent)
                    Text("PostKit Pro")
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Palette.text)
                    Spacer()
                    Text("Active")
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Palette.green)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 2)
                        .background(Palette.green.opacity(0.15), in: Capsule())
                }
                .listRowBackground(Palette.surface)
            } else {
                Button {
                    store.send(.upgradeToProTapped)
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Palette.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Pro")
                                .font(Typography.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(Palette.text)
                            Text("Unlimited AI posts, scanning & templates")
                                .font(Typography.caption)
                                .foregroundStyle(Palette.text3)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.text3)
                    }
                }
                .listRowBackground(Palette.surface)
            }
        } header: {
            Text("Subscription")
        }
    }

    private var topicsSection: some View {
        Section {
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Palette.surface)
            } else if store.pillars.isEmpty {
                Text("No topics yet")
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.text3)
                    .listRowBackground(Palette.surface)
            } else {
                let pillars = store.pillars
                ForEach(pillars) { pillar in
                    Button {
                        store.send(.topicTapped(pillar))
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Text(pillar.emoji)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pillar.name)
                                    .font(Typography.body)
                                    .foregroundStyle(Palette.text)
                                if !pillar.about.isEmpty {
                                    Text(pillar.about)
                                        .font(Typography.caption)
                                        .foregroundStyle(Palette.text3)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(Typography.caption)
                                .foregroundStyle(Palette.text3)
                        }
                    }
                    .listRowBackground(Palette.surface)
                }
            }
        } header: {
            Text("My topics")
        }
    }

    private var privacySection: some View {
        Section {
            HStack {
                Label("Cloud AI Enhancement", systemImage: "cloud.bolt")
                    .foregroundStyle(Palette.text)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { store.cloudAIEnabled },
                    set: { _ in store.send(.cloudAIToggled) }
                ))
                .labelsHidden()
                .tint(Palette.accent)
            }
            .listRowBackground(Palette.surface)

            if store.cloudAIEnabled {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Label("Photos may be sent to Google Gemini for better classification when on-device AI isn't confident enough.", systemImage: "info.circle")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)
                    Text("Photos are processed but never stored by Google.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)
                }
                .listRowBackground(Palette.surface)
            } else {
                Label("All classification stays on your device. No photos are sent to the cloud.", systemImage: "lock.shield")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)
                    .listRowBackground(Palette.surface)
            }
        } header: {
            Text("Privacy")
        }
    }

    private var notificationsSection: some View {
        Section {
            HStack {
                Label("Notifications", systemImage: "bell.badge")
                    .foregroundStyle(Palette.text)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { store.notificationsEnabled },
                    set: { _ in store.send(.notificationToggled) }
                ))
                .labelsHidden()
                .tint(Palette.accent)
            }
            .listRowBackground(Palette.surface)

            if store.notificationsEnabled {
                Text("Schedule reminders on individual posts and templates")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)
                    .listRowBackground(Palette.surface)
            } else {
                Text("Enable to receive posting reminders")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)
                    .listRowBackground(Palette.surface)
            }
        } header: {
            Text("Notifications")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundStyle(Palette.text)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(Palette.text3)
            }
            .listRowBackground(Palette.surface)
        } header: {
            Text("About")
        }
    }
}
