// MARK: - PostKit
// SmartPostView.swift — SmartPost UI: chat bubbles, template preview, input bar

import ComposableArchitecture
import SwiftUI

struct SmartPostView: View {
    @Bindable var store: StoreOf<SmartPostFeature>
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(store.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }

                        if let template = store.generatedTemplate {
                            TemplatePreviewCard(template: template, pillars: store.pillars)
                                .padding(.horizontal, Spacing.xs)
                                .id("templatePreview")

                            HStack(spacing: Spacing.sm) {
                                Button {
                                    Haptics.success()
                                    store.send(.createPostTapped)
                                } label: {
                                    HStack(spacing: Spacing.xs) {
                                        if store.isFillingSlots {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(Palette.onAccent)
                                        }
                                        Text(store.isFillingSlots ? "Filling slots..." : "Create Post")
                                    }
                                    .font(Typography.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Palette.onAccent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.sm + 2)
                                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.button))
                                }
                                .buttonStyle(.plain)
                                .disabled(store.isFillingSlots)

                                Button {
                                    Haptics.tap()
                                    store.send(.startOverTapped)
                                } label: {
                                    Text("Start Over")
                                        .font(Typography.subheadline)
                                        .foregroundStyle(Palette.text2)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, Spacing.sm + 2)
                                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.button))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Radius.button)
                                                .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                                        )
                                }
                                .buttonStyle(.plain)
                                .disabled(store.isFillingSlots)
                            }
                            .padding(.horizontal, Spacing.md)

                            Color.clear
                                .frame(height: Spacing.lg)
                                .id("templateActions")
                        }

                        if store.showSaveAsTemplate {
                            HStack(spacing: Spacing.sm) {
                                Button {
                                    Haptics.success()
                                    store.send(.saveAsTemplateTapped)
                                } label: {
                                    Label("Save as Template", systemImage: "square.grid.2x2")
                                        .font(Typography.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Palette.onAccent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, Spacing.sm + 2)
                                        .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.button))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    Haptics.tap()
                                    store.send(.dismissSaveAsTemplate)
                                } label: {
                                    Text("Skip")
                                        .font(Typography.subheadline)
                                        .foregroundStyle(Palette.text2)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, Spacing.sm + 2)
                                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.button))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Radius.button)
                                                .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, Spacing.md)
                            .id("saveTemplate")
                        }

                        if store.isAIThinking {
                            HStack(spacing: Spacing.xs) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Thinking...")
                                    .font(Typography.caption)
                                    .foregroundStyle(Palette.text3)
                            }
                            .padding(.horizontal, Spacing.md)
                            .id("thinking")
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .onChange(of: store.messages.count) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        if store.generatedTemplate != nil {
                            proxy.scrollTo("templateActions", anchor: .bottom)
                        } else if store.isAIThinking {
                            proxy.scrollTo("thinking", anchor: .bottom)
                        } else if let last = store.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: store.generatedTemplate != nil) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("templateActions", anchor: .bottom)
                    }
                }
            }

            Divider()

            if !store.quickReplies.isEmpty {
                quickRepliesBar
            }

            chatInputBar
        }
        .background(Palette.bg)
        .navigationTitle("Smart Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    store.send(.resetChatTapped)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                }
                .disabled(store.messages.count <= 1)
            }
        }
        .sheet(item: $store.scope(state: \.editor, action: \.editor)) { editorStore in
            NavigationStack {
                PostEditorView(store: editorStore)
            }
        }
        .onAppear { store.send(.onAppear) }
    }

    // MARK: - Quick Replies

    private var quickRepliesBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(store.quickReplies, id: \.self) { reply in
                    Button {
                        Haptics.lightTap()
                        store.send(.quickReplyTapped(reply))
                    } label: {
                        Text(reply)
                            .font(Typography.subheadline)
                            .foregroundStyle(Palette.accent)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Palette.accentTint, in: Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Palette.accent.opacity(0.3), lineWidth: Layout.Border.thin)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, Spacing.xs)
        .background(Palette.surface)
    }

    // MARK: - Chat Input Bar

    private var chatInputBar: some View {
        HStack(spacing: Spacing.sm) {
            if isInputFocused {
                Button {
                    isInputFocused = false
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.system(size: 18))
                        .foregroundStyle(Palette.text3)
                }
                .buttonStyle(.plain)
            }

            TextField("Describe your post...", text: $store.inputText)
                .font(Typography.body)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    isInputFocused = false
                    store.send(.sendMessageTapped)
                }

            Button {
                Haptics.tap()
                isInputFocused = false
                store.send(.sendMessageTapped)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        store.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Palette.text4 : Palette.accent
                    )
            }
            .disabled(store.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Palette.surface)
    }
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            Text(message.text)
                .font(Typography.subheadline)
                .foregroundStyle(message.role == .user ? Palette.onAccent : Palette.text)
                .padding(.horizontal, Spacing.sm + 2)
                .padding(.vertical, Spacing.xs + 2)
                .background(
                    message.role == .user ? Palette.accent : Palette.surface,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay(
                    message.role == .assistant
                        ? RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                        : nil
                )

            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }
}

// MARK: - Template Preview Card

private struct TemplatePreviewCard: View {
    let template: TemplateSnapshot
    let pillars: [PillarSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "doc.text.image")
                    .font(.system(size: 16))
                    .foregroundStyle(Palette.accent)
                Text(template.name)
                    .font(Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.text)
                Spacer()
                Text("\(template.slots.count) slide\(template.slots.count == 1 ? "" : "s")")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)
            }

            ForEach(template.slots) { slot in
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(Palette.accent.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay {
                            Text("\(slotIndex(slot) + 1)")
                                .font(Typography.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(Palette.accent)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(slot.name)
                            .font(Typography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Palette.text)

                        HStack(spacing: Spacing.xs) {
                            let matched = matchedPillars(for: slot)
                            if !matched.isEmpty {
                                ForEach(matched.prefix(3)) { pillar in
                                    Text(pillar.emoji)
                                        .font(.system(size: 12))
                                }
                            }

                            if !slot.locations.isEmpty {
                                Text("📍 \(slot.locations.first ?? "")")
                                    .font(Typography.caption2)
                                    .foregroundStyle(Palette.text3)
                            }
                        }
                    }

                    Spacer()
                }
            }
        }
        .padding(Layout.Padding.card)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
        )
    }

    private func slotIndex(_ slot: TemplateSlotData) -> Int {
        template.slots.firstIndex(where: { $0.id == slot.id }) ?? 0
    }

    private func matchedPillars(for slot: TemplateSlotData) -> [PillarSnapshot] {
        pillars.filter { slot.pillarIDs.contains($0.id) }
    }
}
