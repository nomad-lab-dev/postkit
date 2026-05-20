// MARK: - PostKit
// PostAssemblyView.swift — Post assembly UI: pillar picker, photo picker, caption editor steps

import ComposableArchitecture
@preconcurrency import Photos
import SwiftUI

struct PostAssemblyView: View {
    @Bindable var store: StoreOf<PostAssemblyEntryFeature>

    var body: some View {
        Group {
            switch store.step {
            case .pickPillar:
                pillarPicker
            case .pickPhotos:
                photoPicker
            case .editCaption:
                captionEditor
            }
        }
        .background(Palette.bg)
        .navigationTitle(AppStrings.PostAssembly.title)
        .alert($store.scope(state: \.alert, action: \.alert))
        .task { await store.send(.onAppear).finish() }
    }

    // MARK: - Step 1: Pick Pillar

    private var pillarPicker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Choose a pillar")
                    .font(Typography.headline)

                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.xxl)
                } else if store.pillars.isEmpty {
                    EmptyStateView(
                        icon: "📌",
                        title: "No pillars",
                        message: "Run a scan from the Dashboard first."
                    )
                } else {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(store.pillars) { pillar in
                            Button {
                                Haptics.tap()
                                store.send(.pillarSelected(pillar))
                            } label: {
                                PillarRowView(pillar: pillar)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .screenPadding()
        }
    }

    // MARK: - Step 2: Pick Photos

    private var photoPicker: some View {
        VStack(spacing: 0) {
            if let pillar = store.selectedPillar {
                HStack {
                    Text("\(pillar.emoji) \(pillar.name)")
                        .font(Typography.subheadline)
                        .foregroundStyle(Palette.text2)
                    Spacer()
                    Text("\(store.selectedPhotoIDs.count) selected")
                        .font(Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Palette.accent)
                }
                .padding(.horizontal, Layout.Padding.screen.leading)
                .padding(.vertical, Spacing.sm)
            }

            if store.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if store.photos.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "📷",
                    title: "No photos",
                    message: "This pillar has no classified photos yet."
                )
                .screenPadding()
                Spacer()
            } else {
                ScrollView {
                    let columns = Array(
                        repeating: GridItem(.flexible(), spacing: Layout.Grid.photoGrid),
                        count: 3
                    )
                    LazyVGrid(columns: columns, spacing: Layout.Grid.photoGrid) {
                        ForEach(store.photos) { photo in
                            SelectablePhotoCell(
                                assetIdentifier: photo.assetLocalIdentifier,
                                isSelected: store.selectedPhotoIDs.contains(photo.assetLocalIdentifier)
                            ) {
                                Haptics.selection()
                                store.send(.photoToggled(photo.assetLocalIdentifier))
                            }
                        }
                    }
                    .padding(.horizontal, Layout.Padding.screen.leading)
                }
            }

            if store.canGenerate {
                Button {
                    Haptics.tap()
                    store.send(.continueToCaption)
                } label: {
                    Text("Generate Caption")
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Palette.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.button))
                }
                .padding(Layout.Padding.screen)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") { store.send(.startOverTapped) }
            }
        }
    }

    // MARK: - Step 3: Edit Caption

    private var captionEditor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Platform picker
                HStack(spacing: Spacing.xs) {
                    ForEach(SocialPlatform.allCases, id: \.self) { platform in
                        Button {
                            Haptics.lightTap()
                            store.send(.platformChanged(platform))
                        } label: {
                            Text(platform.displayName)
                                .font(Typography.subheadline)
                                .fontWeight(store.platform == platform ? .semibold : .regular)
                                .foregroundStyle(
                                    store.platform == platform ? Palette.onAccent : Palette.text2
                                )
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs + 2)
                                .background(
                                    store.platform == platform ? Palette.accent : Palette.glassStrong,
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Photo preview strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(Array(store.selectedPhotoIDs), id: \.self) { assetID in
                            MiniThumbnail(assetIdentifier: assetID)
                        }
                    }
                }
                .frame(height: 72)

                // Caption
                if store.isGenerating {
                    HStack(spacing: Spacing.sm) {
                        ProgressView()
                        Text("Generating caption...")
                            .font(Typography.subheadline)
                            .foregroundStyle(Palette.text3)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.xl)
                } else {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Caption")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.text3)

                        TextEditor(text: $store.caption)
                            .font(Typography.body)
                            .frame(minHeight: 140)
                            .scrollContentBackground(.hidden)
                            .padding(Spacing.sm)
                            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.input))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.input)
                                    .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                            )

                        Text("\(store.caption.count)/\(store.platform.characterLimit)")
                            .font(Typography.caption2)
                            .foregroundStyle(
                                store.caption.count > store.platform.characterLimit
                                    ? Palette.red : Palette.text3
                            )
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    // Hashtags
                    if !store.hashtags.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Hashtags")
                                .font(Typography.caption)
                                .foregroundStyle(Palette.text3)

                            Text(store.hashtags.joined(separator: " "))
                                .font(Typography.footnote)
                                .foregroundStyle(Palette.accent)
                                .padding(Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.input))
                        }
                    }
                }

                // Actions
                if !store.isGenerating {
                    VStack(spacing: Spacing.sm) {
                        Button {
                            Haptics.success()
                            store.send(.exportTapped)
                        } label: {
                            Label("Copy to Clipboard", systemImage: "doc.on.doc")
                                .font(Typography.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(Palette.onAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.button))
                        }

                        HStack(spacing: Spacing.sm) {
                            Button {
                                Haptics.tap()
                                store.send(.regenerateTapped)
                            } label: {
                                Label("Regenerate", systemImage: "arrow.clockwise")
                                    .font(Typography.subheadline)
                                    .foregroundStyle(Palette.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.xs)
                                    .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.button))
                            }

                            Button {
                                Haptics.success()
                                store.send(.saveTapped)
                            } label: {
                                Label("Save Draft", systemImage: "square.and.arrow.down")
                                    .font(Typography.subheadline)
                                    .foregroundStyle(Palette.text2)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.xs)
                                    .background(Palette.glassStrong, in: RoundedRectangle(cornerRadius: Radius.button))
                            }
                        }
                    }
                }
            }
            .screenPadding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") { store.send(.startOverTapped) }
            }
        }
    }
}

// MARK: - Selectable Photo Cell

private struct SelectablePhotoCell: View {
    let assetIdentifier: String
    let isSelected: Bool
    let action: () -> Void

    @State private var image: UIImage?

    private static let thumbnailPx: CGFloat = {
        let screen = UIScreen.main.bounds.width
        let cellPt = (screen - 2 * Layout.Padding.screen.leading - 2 * Layout.Grid.photoGrid) / 3
        return ceil(cellPt * UIScreen.main.scale)
    }()

    var body: some View {
        Button(action: action) {
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
                            .font(Typography.title3)
                            .foregroundStyle(Palette.accent)
                            .background(Circle().fill(Palette.onAccent).padding(2))
                            .padding(Spacing.xxs)
                    }
                }
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: Radius.tile)
                            .strokeBorder(Palette.accent, lineWidth: Layout.Border.regular)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Radius.tile))
        }
        .buttonStyle(.plain)
        .task(id: assetIdentifier) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [assetIdentifier], options: nil
        )
        guard let asset = fetchResult.firstObject else { return }
        let size = CGSize(width: Self.thumbnailPx, height: Self.thumbnailPx)
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
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

// MARK: - Mini Thumbnail

private struct MiniThumbnail: View {
    let assetIdentifier: String
    @State private var image: UIImage?

    var body: some View {
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
            .task(id: assetIdentifier) {
                let fetchResult = PHAsset.fetchAssets(
                    withLocalIdentifiers: [assetIdentifier], options: nil
                )
                guard let asset = fetchResult.firstObject else { return }
                let options = PHImageRequestOptions()
                options.deliveryMode = .fastFormat
                options.isNetworkAccessAllowed = false
                PHImageManager.default().requestImage(
                    for: asset, targetSize: CGSize(width: 216, height: 216),
                    contentMode: .aspectFill, options: options
                ) { result, _ in
                    guard let result else { return }
                    Task { @MainActor in self.image = result }
                }
            }
    }
}
