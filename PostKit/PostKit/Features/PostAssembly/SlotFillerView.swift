import ComposableArchitecture
@preconcurrency import Photos
import SwiftUI

struct SlotFillerView: View {
    @Bindable var store: StoreOf<SlotFillerFeature>

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Layout.Grid.photoGrid),
        count: 3
    )

    var body: some View {
        VStack(spacing: 0) {
            filterBar
                .padding(.bottom, Spacing.sm)

            if store.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if store.filteredPhotos.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "📷",
                    title: "No photos found",
                    message: store.constrainedPillarNames.isEmpty
                        ? "Run a scan from the Dashboard to classify your photos."
                        : "No photos match this slot's pillar requirements."
                )
                .screenPadding()
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("\(store.filteredPhotos.count) photos")
                            .font(Typography.footnote)
                            .foregroundStyle(Palette.text3)
                            .padding(.horizontal, Layout.Padding.screen.leading)

                        LazyVGrid(columns: columns, spacing: Layout.Grid.photoGrid) {
                            ForEach(store.filteredPhotos) { photo in
                                Button {
                                    store.send(.photoToggled(photo.assetLocalIdentifier))
                                } label: {
                                    FillerThumbnailCell(
                                        assetIdentifier: photo.assetLocalIdentifier,
                                        isSelected: store.selectedPhotoIDs.contains(
                                            photo.assetLocalIdentifier
                                        )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Layout.Padding.screen.leading)
                    }
                }
            }

            if !store.selectedPhotoIDs.isEmpty {
                confirmBar
            }
        }
        .background(Palette.bg)
        .navigationTitle(store.slotName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !store.selectedPhotoIDs.isEmpty {
                    Text("\(store.selectedPhotoIDs.count) selected")
                        .font(Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Palette.accent)
                }
            }
        }
        .task { await store.send(.onAppear).finish() }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                if store.constrainedPillarNames.isEmpty {
                    FilterChipView(
                        label: "All",
                        isSelected: store.selectedFilter == .all
                    ) {
                        store.send(.filterSelected(.all))
                    }
                }

                ForEach(store.displayPillars) { pillar in
                    FilterChipView(
                        label: "\(pillar.emoji) \(pillar.name)",
                        isSelected: store.selectedFilter == .pillar(pillar.id)
                    ) {
                        store.send(.filterSelected(.pillar(pillar.id)))
                    }
                }

                if store.constrainedPillarNames.isEmpty {
                    FilterChipView(
                        label: "❓ Uncategorized",
                        isSelected: store.selectedFilter == .uncategorized
                    ) {
                        store.send(.filterSelected(.uncategorized))
                    }
                }
            }
            .padding(.horizontal, Layout.Padding.screen.leading)
        }
    }

    private var confirmBar: some View {
        Button {
            store.send(.confirmTapped)
        } label: {
            Text("Use \(store.selectedPhotoIDs.count) photo\(store.selectedPhotoIDs.count == 1 ? "" : "s")")
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

// MARK: - Filter Chip (reusable)

struct FilterChipView: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Typography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Palette.onAccent : Palette.text2)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs + 2)
                .background(
                    isSelected ? Palette.accent : Palette.glassStrong,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : Palette.border,
                            lineWidth: Layout.Border.thin
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Thumbnail with Selection

private struct FillerThumbnailCell: View {
    let assetIdentifier: String
    let isSelected: Bool
    @State private var image: UIImage?

    private static let thumbnailPx: CGFloat = {
        let screen = UIScreen.main.bounds.width
        let cellPt = (screen - 2 * Layout.Padding.screen.leading - 2 * Layout.Grid.photoGrid) / 3
        return ceil(cellPt * UIScreen.main.scale)
    }()

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
