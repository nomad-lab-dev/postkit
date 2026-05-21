// MARK: - PostKit
// TopicEditorView.swift — Topic editor UI: AI-enriched topic creation and editing

import ComposableArchitecture
@preconcurrency import Photos
import SwiftUI

struct TopicEditorView: View {
    @Bindable var store: StoreOf<TopicEditorFeature>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                nameSection
                if store.enrichmentApplied {
                    suggestionCard
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                descriptionSection
                toneSection
                topicsSection
                referencePhotosSection
                tagsSection

                if store.isEditing {
                    deleteSection
                }

                Spacer(minLength: Spacing.xxl)
            }
            .padding(.horizontal, Layout.Padding.screen.leading)
            .padding(.top, Spacing.md)
        }
        .background(Palette.bg)
        .navigationTitle(store.isEditing ? "Edit Topic" : "New Topic")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.success()
                    store.send(.saveTapped)
                } label: {
                    if store.isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(!store.canSave || store.isSaving)
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .animation(.easeInOut(duration: 0.3), value: store.enrichmentApplied)
    }

    // MARK: - Name + Enrich

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("What do you post about?")
                .font(Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Palette.text)

            HStack(spacing: Spacing.sm) {
                TextField("e.g. cars, travel, food...", text: $store.name)
                    .font(Typography.body)
                    .textFieldStyle(.plain)
                    .padding(Spacing.sm)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.input))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.input)
                            .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                    )
                    .onSubmit {
                        store.send(.enrichRequested)
                    }

                Button {
                    Haptics.tap()
                    store.send(.enrichRequested)
                } label: {
                    Group {
                        if store.isEnriching {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.input))
                    .foregroundStyle(Palette.onAccent)
                }
                .disabled(store.name.trimmingCharacters(in: .whitespaces).isEmpty || store.isEnriching)
            }

            Text("Tap the sparkle to let AI suggest a name, emoji, and description")
                .font(Typography.caption)
                .foregroundStyle(Palette.text4)
        }
    }

    // MARK: - Suggestion Card

    private var suggestionCard: some View {
        HStack(spacing: Spacing.md) {
            Text(store.emoji.isEmpty ? "📌" : store.emoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(store.name)
                    .font(Typography.headline)
                    .foregroundStyle(Palette.text)

                if !store.about.isEmpty {
                    Text(store.about)
                        .font(Typography.footnote)
                        .foregroundStyle(Palette.text3)
                }
            }

            Spacer()
        }
        .padding(Layout.Padding.card)
        .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(Palette.accent.opacity(0.3), lineWidth: Layout.Border.thin)
        )
    }

    // MARK: - Emoji + Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Emoji")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)
                    TextField("📌", text: $store.emoji)
                        .font(.system(size: 28))
                        .frame(width: 56, height: 44)
                        .multilineTextAlignment(.center)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.input))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.input)
                                .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                        )
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Description")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)
                    TextField("What kind of photos fit this topic?", text: $store.about)
                        .font(Typography.body)
                        .padding(Spacing.sm)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.input))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.input)
                                .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                        )
                }
            }
        }
    }

    // MARK: - Tone

    private var toneSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Tone")
                .font(Typography.caption)
                .foregroundStyle(Palette.text3)

            HStack(spacing: Spacing.xs) {
                ForEach(PillarTone.allCases, id: \.self) { tone in
                    Button {
                        store.tone = tone
                    } label: {
                        Text(tone.rawValue.capitalized)
                            .font(Typography.subheadline)
                            .fontWeight(store.tone == tone ? .semibold : .regular)
                            .foregroundStyle(store.tone == tone ? Palette.onAccent : Palette.text2)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs + 2)
                            .background(
                                store.tone == tone ? Palette.accent : Palette.glassStrong,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        store.tone == tone ? Color.clear : Palette.border,
                                        lineWidth: Layout.Border.thin
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Topics / Keywords

    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Keywords")
                .font(Typography.caption)
                .foregroundStyle(Palette.text3)

            HStack(spacing: Spacing.xs) {
                TextField("Add a keyword...", text: $store.topicInput)
                    .font(Typography.body)
                    .textFieldStyle(.plain)
                    .padding(Spacing.sm)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.input))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.input)
                            .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                    )
                    .onSubmit { store.send(.addTopicTapped) }

                Button {
                    store.send(.addTopicTapped)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Palette.accent)
                }
                .disabled(store.topicInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if !store.topics.isEmpty {
                FlowLayout(spacing: Spacing.xs) {
                    ForEach(store.topics, id: \.self) { topic in
                        HStack(spacing: 4) {
                            Text(topic)
                                .font(Typography.subheadline)
                            Button {
                                store.send(.removeTopicTapped(topic))
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                        }
                        .foregroundStyle(Palette.accent)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs + 2)
                        .background(Palette.accentTint, in: Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Reference Photos

    private var referencePhotosSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("Example Photos")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)
                Spacer()
                if store.isExtractingTags {
                    HStack(spacing: Spacing.xxs) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Analyzing...")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.text3)
                    }
                }
            }

            Text("Pick photos that represent this topic — AI will learn from them")
                .font(Typography.caption)
                .foregroundStyle(Palette.text4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    PhotoPickerButton { assetIDs in
                        store.send(.photosPicked(assetIDs))
                    }

                    ForEach(store.referencePhotoIDs, id: \.self) { assetID in
                        ReferencePhotoCell(assetIdentifier: assetID) {
                            store.send(.removeReferencPhoto(assetID))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tags

    @ViewBuilder
    private var tagsSection: some View {
        if !store.referenceTags.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Visual Tags (AI-extracted)")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)

                FlowLayout(spacing: Spacing.xxs) {
                    ForEach(store.referenceTags.prefix(20), id: \.self) { tag in
                        Text(tag)
                            .font(Typography.caption)
                            .foregroundStyle(Palette.text2)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 3)
                            .background(Palette.surface, in: Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Delete

    private var deleteSection: some View {
        Button(role: .destructive) {
            store.send(.deleteTapped)
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Topic")
            }
            .font(Typography.subheadline)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: Radius.button))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Photo Picker Button

private struct PhotoPickerButton: View {
    let onPicked: ([String]) -> Void

    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker = true
        } label: {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 24))
                Text("Add")
                    .font(Typography.caption2)
            }
            .foregroundStyle(Palette.accent)
            .frame(width: 72, height: 72)
            .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.tile))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.tile)
                    .strokeBorder(Palette.accent.opacity(0.3), lineWidth: Layout.Border.thin)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            LibraryPickerView(onPicked: onPicked)
        }
    }
}

// MARK: - Library Picker (simple grid)

private struct LibraryPickerView: View {
    let onPicked: ([String]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var assets: [PHAsset] = []
    @State private var selectedIDs: Set<String> = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(assets, id: \.localIdentifier) { asset in
                        Button {
                            let id = asset.localIdentifier
                            if selectedIDs.contains(id) {
                                selectedIDs.remove(id)
                            } else if selectedIDs.count < 5 {
                                selectedIDs.insert(id)
                            }
                        } label: {
                            PickerThumbnail(
                                asset: asset,
                                isSelected: selectedIDs.contains(asset.localIdentifier)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Pick Examples")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add \(selectedIDs.count)") {
                        onPicked(Array(selectedIDs))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedIDs.isEmpty)
                }
            }
            .task { await loadAssets() }
        }
    }

    private func loadAssets() async {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 200
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var fetched: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            fetched.append(asset)
        }
        assets = fetched
    }
}

private struct PickerThumbnail: View {
    let asset: PHAsset
    let isSelected: Bool
    @State private var image: UIImage?

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Palette.placeholder
                }
            }
            .clipped()
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Palette.accent)
                        .background(Circle().fill(.white).padding(2))
                        .padding(4)
                }
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(Palette.accent, lineWidth: 3)
                }
            }
            .task(id: asset.localIdentifier) {
                let size = CGSize(width: 200, height: 200)
                let options = PHImageRequestOptions()
                options.deliveryMode = .fastFormat
                options.isNetworkAccessAllowed = false
                PHImageManager.default().requestImage(
                    for: asset, targetSize: size,
                    contentMode: .aspectFill, options: options
                ) { result, _ in
                    guard let result else { return }
                    Task { @MainActor in self.image = result }
                }
            }
    }
}

// MARK: - Reference Photo Cell

private struct ReferencePhotoCell: View {
    let assetIdentifier: String
    let onRemove: () -> Void
    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
                .frame(width: 72, height: 72)
                .overlay {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Palette.placeholder
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Radius.tile))

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)).padding(1))
            }
            .offset(x: 4, y: -4)
        }
        .task(id: assetIdentifier) {
            let fetchResult = PHAsset.fetchAssets(
                withLocalIdentifiers: [assetIdentifier], options: nil
            )
            guard let asset = fetchResult.firstObject else { return }
            let size = CGSize(width: 200, height: 200)
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            PHImageManager.default().requestImage(
                for: asset, targetSize: size,
                contentMode: .aspectFill, options: options
            ) { result, _ in
                guard let result else { return }
                Task { @MainActor in self.image = result }
            }
        }
    }
}
