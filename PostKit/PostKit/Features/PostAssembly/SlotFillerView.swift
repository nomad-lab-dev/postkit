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
                    message: store.constrainedPillarIDs.isEmpty
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
                                    Haptics.selection()
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
        VStack(spacing: Spacing.xs) {
            if !store.displayPillars.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(store.displayPillars) { pillar in
                            FilterChipView(
                                label: "\(pillar.emoji) \(pillar.name)",
                                isSelected: store.activePillarIDs.contains(pillar.id),
                                isConfigured: store.constrainedPillarIDs.contains(pillar.id)
                            ) {
                                store.send(.pillarFilterToggled(pillar.id))
                            }
                        }
                    }
                    .padding(.horizontal, Layout.Padding.screen.leading)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(Cadrage.detectableCases, id: \.self) { cadrage in
                        FilterChipView(
                            label: cadrage.displayName,
                            isSelected: store.activeCadrages.contains(cadrage),
                            isConfigured: store.constrainedCadrages.contains(cadrage)
                        ) {
                            store.send(.cadrageFilterToggled(cadrage))
                        }
                    }
                }
                .padding(.horizontal, Layout.Padding.screen.leading)
            }

            if !store.uniqueLocations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(store.uniqueLocations, id: \.self) { location in
                            FilterChipView(
                                label: "📍 \(location)",
                                isSelected: store.activeLocations.contains(location),
                                isConfigured: store.constrainedLocations.contains(location)
                            ) {
                                store.send(.locationFilterToggled(location))
                            }
                        }
                    }
                    .padding(.horizontal, Layout.Padding.screen.leading)
                }
            }
        }
    }

    private var confirmBar: some View {
        Button {
            Haptics.success()
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
    var isConfigured: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Typography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs + 2)
                .background(backgroundColor, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(borderColor, lineWidth: Layout.Border.thin)
                )
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        if isSelected { return Palette.onAccent }
        if isConfigured { return Palette.accent }
        return Palette.text2
    }

    private var backgroundColor: Color {
        if isSelected { return Palette.accent }
        return Palette.glassStrong
    }

    private var borderColor: Color {
        if isSelected { return Color.clear }
        if isConfigured { return Palette.accent.opacity(0.5) }
        return Palette.border
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
