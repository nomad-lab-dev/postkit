// MARK: - PostKit
// ExploreView.swift — Explore UI: filterable photo grid with pillar and status chips

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
            pillarFilterBar
            statusFilterBar
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.sm)

            if store.isLoading {
                exploreSkeleton
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
                                    Haptics.tap()
                                    store.send(.photoTapped(photo))
                                } label: {
                                    ExploreThumbnailCell(photo: photo)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    if let pillarID = photo.pillarID,
                                       let pillar = store.pillars.first(where: { $0.id == pillarID }) {
                                        Label("\(pillar.emoji) \(pillar.name)", systemImage: "circle.fill")
                                            .disabled(true)
                                    }
                                    if let cadrage = photo.cadrage, cadrage != .any {
                                        Label(cadrage.rawValue.capitalized, systemImage: "camera.viewfinder")
                                            .disabled(true)
                                    }
                                    if let location = photo.location {
                                        Label(location, systemImage: "mappin")
                                            .disabled(true)
                                    }
                                    if let date = photo.capturedAt {
                                        Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                            .disabled(true)
                                    }
                                    Divider()
                                    if photo.status == .pending {
                                        Button {
                                            store.send(.photoTapped(photo))
                                        } label: {
                                            Label("Classify", systemImage: "tag")
                                        }
                                    }
                                    Button {
                                        store.send(.copyPhotoTapped(photo.assetLocalIdentifier))
                                    } label: {
                                        Label("Copy Photo", systemImage: "doc.on.doc")
                                    }
                                } preview: {
                                    ExploreThumbnailCell(photo: photo)
                                        .frame(width: 280, height: 280)
                                }
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
        .navigationDestination(
            item: $store.scope(state: \.card, action: \.card)
        ) { cardStore in
            ClassificationCardView(store: cardStore)
        }
    }

    private var emptyMessage: String {
        if store.statusFilter != nil || store.selectedFilter != .all {
            return "No photos match the current filters."
        }
        return "Run a scan from the Dashboard to classify your photos."
    }

    // MARK: - Pillar Filter

    private var pillarFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                FilterChip(
                    label: "All",
                    isSelected: store.selectedFilter == .all
                ) {
                    Haptics.lightTap()
                    store.send(.filterSelected(.all))
                }

                ForEach(store.pillars) { pillar in
                    FilterChip(
                        label: "\(pillar.emoji) \(pillar.name)",
                        isSelected: store.selectedFilter == .pillar(pillar.id)
                    ) {
                        Haptics.lightTap()
                        store.send(.filterSelected(.pillar(pillar.id)))
                    }
                }

                FilterChip(
                    label: "❓ Uncategorized",
                    isSelected: store.selectedFilter == .uncategorized
                ) {
                    Haptics.lightTap()
                    store.send(.filterSelected(.uncategorized))
                }
            }
            .padding(.horizontal, Layout.Padding.screen.leading)
        }
    }

    // MARK: - Skeleton

    private var exploreSkeleton: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SkeletonRect(width: 60, height: 12)
                    .padding(.horizontal, Layout.Padding.screen.leading)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: Layout.Grid.photoGrid), count: 3),
                    spacing: Layout.Grid.photoGrid
                ) {
                    ForEach(0..<12, id: \.self) { _ in
                        SkeletonRect(radius: Radius.tile)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(.horizontal, Layout.Padding.screen.leading)
            }
        }
    }

    // MARK: - Status Filter

    private var statusFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                StatusChip(label: "All", isSelected: store.statusFilter == nil) {
                    Haptics.lightTap()
                    store.send(.statusFilterSelected(nil))
                }
                StatusChip(label: "✓ Classified", isSelected: store.statusFilter == .classified) {
                    Haptics.lightTap()
                    store.send(.statusFilterSelected(.classified))
                }
                StatusChip(label: "? Pending", isSelected: store.statusFilter == .pending) {
                    Haptics.lightTap()
                    store.send(.statusFilterSelected(.pending))
                }
                StatusChip(label: "✗ Rejected", isSelected: store.statusFilter == .rejected) {
                    Haptics.lightTap()
                    store.send(.statusFilterSelected(.rejected))
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

// MARK: - Status Chip

private struct StatusChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Typography.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Palette.onAccent : Palette.text3)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(
                    isSelected ? Palette.accent.opacity(0.85) : Palette.glassStrong,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Thumbnail Cell

private struct ExploreThumbnailCell: View {
    let photo: ClassifiedPhotoSnapshot
    @State private var image: UIImage?

    private static let thumbnailSize: CGFloat = {
        let screen = UIScreen.main.bounds.width
        let cellWidth = (screen - 40 - 8) / 3
        return cellWidth * UIScreen.main.scale
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
            .overlay(alignment: .bottomLeading) {
                if let cadrage = photo.cadrage, cadrage != .any {
                    CadrageTag(cadrage: cadrage)
                        .padding(3)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                statusBadge
                    .padding(3)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.tile))
        .task(id: photo.assetLocalIdentifier) {
            await loadThumbnail()
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch photo.status {
        case .classified:
            EmptyView()
        case .pending:
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.orange)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        case .rejected:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Palette.red)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        }
    }

    private func loadThumbnail() async {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [photo.assetLocalIdentifier], options: nil
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
