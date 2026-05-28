// MARK: - PostKit
// SlotFillerView.swift — Slot filler UI: photo grid with pillar, cadrage, and location filters

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
            if !store.slotAbout.isEmpty {
                Text(store.slotAbout)
                    .font(Typography.footnote)
                    .foregroundStyle(Palette.text2)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Layout.Padding.screen.leading)
                    .padding(.top, Spacing.xs)
            }

            filterBar
                .padding(.bottom, Spacing.sm)
                .zIndex(1)

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
                        : "No photos match this slot's topic requirements."
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

            locationSection
                .zIndex(1)
            dateFilterRow
        }
    }

    // MARK: - Location Section

    @ViewBuilder
    private var locationSection: some View {
        if !store.activeLocations.isEmpty {
            // Active chips only — text field hidden until location is removed
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(store.activeLocations.sorted(), id: \.self) { location in
                        Button {
                            Haptics.lightTap()
                            store.send(.locationRemoved(location))
                        } label: {
                            HStack(spacing: 4) {
                                Text("📍 \(location)")
                                    .font(Typography.subheadline)
                                    .fontWeight(.semibold)
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(Palette.onAccent)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs + 2)
                            .background(Palette.accent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Layout.Padding.screen.leading)
            }
        } else {
            // Text field with floating autocomplete overlay
            HStack(spacing: Spacing.xs) {
                Image(systemName: "mappin")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.text3)
                    .padding(.leading, Spacing.sm)

                TextField("Add a location…", text: $store.locationQuery)
                    .font(Typography.body)
                    .onSubmit { commitLocation() }
                    .submitLabel(.done)

                if !store.locationQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button { commitLocation() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Palette.accent)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, Spacing.sm)
                }
            }
            .padding(.vertical, Spacing.xs)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.input))
            .overlay(RoundedRectangle(cornerRadius: Radius.input).stroke(Palette.border))
            .overlay(alignment: .bottom) {
                if !store.suggestedLocations.isEmpty {
                    locationDropdown
                        // positions dropdown top at input bottom + gap
                        .alignmentGuide(.bottom) { $0[.top] - Spacing.xxs }
                }
            }
            .padding(.horizontal, Layout.Padding.screen.leading)
        }
    }

    private var locationDropdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(store.suggestedLocations.prefix(5).enumerated()), id: \.element) { index, location in
                let isFromGallery = store.uniqueLocations.contains(location)
                Button {
                    Haptics.lightTap()
                    store.send(.locationSelected(location))
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: isFromGallery ? "photo.circle.fill" : "mappin.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(isFromGallery ? Palette.accent : Palette.text3)
                        Text(location)
                            .font(Typography.subheadline)
                            .foregroundStyle(Palette.text)
                        Spacer()
                        if isFromGallery {
                            Text("gallery")
                                .font(Typography.caption2)
                                .foregroundStyle(Palette.accent)
                        }
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)

                if index < min(5, store.suggestedLocations.count) - 1 {
                    Divider().padding(.leading, Spacing.xl)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
        )
    }

    private func commitLocation() {
        let trimmed = store.locationQuery.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Haptics.lightTap()
        if let match = store.suggestedLocations.first {
            store.send(.locationSelected(match))
        } else {
            store.send(.locationSelected(trimmed))
        }
    }

    private var hasActiveDates: Bool {
        store.activeStartDate != nil || store.activeEndDate != nil
    }

    @ViewBuilder
    private var dateFilterRow: some View {
        if hasActiveDates {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "calendar")
                    .foregroundStyle(Palette.accent)

                DatePicker(
                    "From",
                    selection: Binding(
                        get: { store.activeStartDate ?? .now },
                        set: { store.send(.startDateChanged($0)) }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()

                Image(systemName: "arrow.right")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)

                DatePicker(
                    "To",
                    selection: Binding(
                        get: { store.activeEndDate ?? .now },
                        set: { store.send(.endDateChanged($0)) }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()

                Button { store.send(.clearDatesTapped) } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.text3)
                }
            }
            .padding(.horizontal, Layout.Padding.screen.leading)
        } else {
            HStack {
                FilterChipView(label: "📅 Add dates", isSelected: false) {
                    store.send(.startDateChanged(Calendar.current.date(byAdding: .month, value: -1, to: .now)!))
                }
                Spacer()
            }
            .padding(.horizontal, Layout.Padding.screen.leading)
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
