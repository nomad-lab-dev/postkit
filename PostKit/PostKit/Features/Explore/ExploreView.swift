import ComposableArchitecture
@preconcurrency import Photos
import SwiftUI

struct ExploreView: View {
    @Bindable var store: StoreOf<ExploreFeature>

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
                    message: emptyMessage
                )
                .screenPadding()
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("\(store.filteredCount) photos")
                            .font(Typography.footnote)
                            .foregroundStyle(Palette.text3)
                            .padding(.horizontal, Layout.Padding.screen.leading)

                        LazyVGrid(columns: columns, spacing: Layout.Grid.photoGrid) {
                            ForEach(store.filteredPhotos) { photo in
                                Button {
                                    store.send(.photoTapped(photo))
                                } label: {
                                    ExploreThumbnailCell(
                                        assetIdentifier: photo.assetLocalIdentifier
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Layout.Padding.screen.leading)
                    }
                }
            }
        }
        .background(Palette.bg)
        .navigationTitle(AppStrings.Explore.title)
        .task { await store.send(.onAppear).finish() }
    }

    private var emptyMessage: String {
        switch store.selectedFilter {
        case .all:
            return "Run a scan from the Dashboard to classify your photos."
        case .pillar:
            return "No photos match this pillar yet."
        case .uncategorized:
            return "All your photos have been classified into pillars."
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                FilterChip(
                    label: "All",
                    isSelected: store.selectedFilter == .all
                ) {
                    store.send(.filterSelected(.all))
                }

                ForEach(store.pillars) { pillar in
                    FilterChip(
                        label: "\(pillar.emoji) \(pillar.name)",
                        isSelected: store.selectedFilter == .pillar(pillar.id)
                    ) {
                        store.send(.filterSelected(.pillar(pillar.id)))
                    }
                }

                FilterChip(
                    label: "❓ Uncategorized",
                    isSelected: store.selectedFilter == .uncategorized
                ) {
                    store.send(.filterSelected(.uncategorized))
                }
            }
            .padding(.horizontal, Layout.Padding.screen.leading)
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
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

// MARK: - Thumbnail Cell

private struct ExploreThumbnailCell: View {
    let assetIdentifier: String
    @State private var image: UIImage?

    private static let thumbnailSize: CGFloat = {
        let screen = UIScreen.main.bounds.width
        let cellWidth = (screen - 40 - 8) / 3
        return cellWidth * UIScreen.main.scale
    }()

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Palette.placeholder
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fill)
        .clipped()
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

        let size = CGSize(width: Self.thumbnailSize, height: Self.thumbnailSize)
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = false

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            guard let result else { return }
            Task { @MainActor in
                self.image = result
            }
        }
    }
}
