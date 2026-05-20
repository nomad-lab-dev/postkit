import ComposableArchitecture
@preconcurrency import Photos
import SwiftUI

struct PostEditorView: View {
    @Bindable var store: StoreOf<PostEditorFeature>

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Spacing.xs),
        count: 2
    )

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                slotsGrid
                    .padding(.horizontal, Spacing.xs)

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    captionSection
                    hashtagsSection
                    shareSection
                }
                .padding(.horizontal, Layout.Padding.screen.leading)
            }
            .padding(.vertical, Layout.Padding.screen.top)
        }
        .background(Palette.bg)
        .navigationTitle(store.template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    store.send(.closeTapped)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.success()
                    store.send(.saveDraftTapped)
                } label: {
                    Text("Save")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(item: $store.scope(state: \.slotFiller, action: \.slotFiller)) { fillerStore in
            NavigationStack {
                SlotFillerView(store: fillerStore)
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: Binding(
            get: { store.shareImages != nil },
            set: { if !$0 { store.send(.shareDismissed) } }
        )) {
            if let images = store.shareImages {
                ShareSheet(items: images)
            }
        }
    }

    // MARK: - Slots Grid

    private var slotsGrid: some View {
        VStack(spacing: Spacing.sm) {
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(store.filledSlots) { slot in
                    VStack(spacing: Spacing.xxs) {
                        SlotCardView(slot: slot, pillars: store.availablePillars) {
                            store.send(.slotTapped(slot.id))
                        } onClear: {
                            store.send(.clearSlotTapped(slot.id))
                        } onReshuffle: {
                            Haptics.tap()
                            store.send(.reshuffleSlotTapped(slot.id))
                        }

                        HStack(spacing: Spacing.xxs) {
                            Text(slot.slotData.name)
                                .font(Typography.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(Palette.text2)
                                .lineLimit(1)

                            if let location = slot.locationLabel ?? slot.slotData.locations.first {
                                Text("·")
                                    .foregroundStyle(Palette.text4)
                                HStack(spacing: 2) {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 8))
                                    Text(location)
                                        .font(Typography.caption2)
                                }
                                .foregroundStyle(Palette.text3)
                                .lineLimit(1)
                            }

                            Spacer()
                        }
                    }
                }
            }

            if store.filledSlots.contains(where: \.isEmpty) {
                dateFilterRow

                Button {
                    Haptics.tap()
                    store.send(.autoFillTapped)
                } label: {
                    Label("Auto-fill from library", systemImage: "dice")
                        .font(Typography.subheadline)
                        .foregroundStyle(Palette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.button))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Date Filter

    @ViewBuilder
    private var dateFilterRow: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.accent)

                DatePicker(
                    "From",
                    selection: Binding(
                        get: { store.filterStartDate ?? .now },
                        set: { store.send(.filterStartDateChanged($0)) }
                    ),
                    displayedComponents: .date
                )
                .font(Typography.caption)
                .labelsHidden()

                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Palette.text4)

                DatePicker(
                    "To",
                    selection: Binding(
                        get: { store.filterEndDate ?? .now },
                        set: { store.send(.filterEndDateChanged($0)) }
                    ),
                    displayedComponents: .date
                )
                .font(Typography.caption)
                .labelsHidden()

                if store.filterStartDate != nil || store.filterEndDate != nil {
                    Button {
                        store.send(.filterStartDateChanged(nil))
                        store.send(.filterEndDateChanged(nil))
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Palette.text4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.button)
                    .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
            )
        }
    }

    // MARK: - Caption

    @ViewBuilder
    private var captionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Caption")
                    .font(Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.text)
                Spacer()
                if store.totalPhotoCount > 0 && !store.isGenerating {
                    Button {
                        Haptics.tap()
                        store.send(.generateCaptionTapped)
                    } label: {
                        Label("Generate", systemImage: "sparkles")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.accent)
                    }
                }
            }

            if store.isGenerating {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                    Text("Generating…")
                        .font(Typography.subheadline)
                        .foregroundStyle(Palette.text3)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, Spacing.xl)
            } else {
                TextEditor(text: $store.caption)
                    .font(Typography.body)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(Spacing.sm)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.input))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.input)
                            .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                    )
            }
        }
    }

    // MARK: - Hashtags

    @ViewBuilder
    private var hashtagsSection: some View {
        if !store.hashtags.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Hashtags")
                    .font(Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.text)

                Text(store.hashtags.joined(separator: " "))
                    .font(Typography.footnote)
                    .foregroundStyle(Palette.accent)
                    .padding(Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.input))
            }
        }
    }

    // MARK: - Share

    private var shareSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Share")
                .font(Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Palette.text)

            HStack(spacing: Spacing.sm) {
                Button {
                    Haptics.tap()
                    store.send(.shareTapped)
                } label: {
                    HStack(spacing: Spacing.xs) {
                        if store.isLoadingShare {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(Palette.onAccent)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(store.isLoadingShare ? "Preparing..." : "Share Photos")
                    }
                    .font(Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm + 2)
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.button))
                }
                .buttonStyle(.plain)
                .disabled(store.allPhotoIDs.isEmpty || store.isLoadingShare)

                Button {
                    Haptics.tap()
                    store.send(.copyTapped)
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Text")
                    }
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm + 2)
                    .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.button))
                }
                .buttonStyle(.plain)
                .disabled(store.caption.isEmpty && store.hashtags.isEmpty)
            }

            if !store.caption.isEmpty || !store.hashtags.isEmpty {
                Text("Caption & hashtags are copied to clipboard when sharing")
                    .font(Typography.caption2)
                    .foregroundStyle(Palette.text4)
            }
        }
    }
}

// MARK: - Slot Card

private struct SlotCardView: View {
    let slot: FilledSlot
    let pillars: [PillarSnapshot]
    let onTap: () -> Void
    let onClear: () -> Void
    let onReshuffle: () -> Void

    @State private var currentPage: Int = 0

    private var matchedPillars: [PillarSnapshot] {
        pillars.filter { slot.slotData.pillarIDs.contains($0.id) }
    }

    private var activePillar: PillarSnapshot? {
        if let activeID = slot.activePillarID {
            return pillars.first { $0.id == activeID }
        }
        return matchedPillars.first
    }

    private var sortedPhotoIDs: [String] {
        slot.photoIDs.sorted()
    }

    var body: some View {
        ZStack {
            if slot.isEmpty {
                emptyContent
            } else {
                filledContent
            }

            // Overlays for filled slots
            if !slot.isEmpty {
                VStack {
                    // Top row: reshuffle + delete
                    HStack {
                        Button {
                            onReshuffle()
                        } label: {
                            Image(systemName: "shuffle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(Palette.accent, in: Circle())
                                .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                        }

                        Spacer()

                        Button {
                            Haptics.lightTap()
                            onClear()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.black.opacity(0.55), in: Circle())
                                .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                        }
                    }

                    Spacer()

                    // Bottom row: pillar emoji + location + cadrage tag
                    HStack(spacing: Spacing.xxs) {
                        if let pillar = activePillar {
                            Text(pillar.emoji)
                                .font(.system(size: 14))
                                .frame(width: 26, height: 26)
                                .background(.ultraThinMaterial, in: Circle())
                        }

                        if let location = slot.locationLabel {
                            HStack(spacing: 2) {
                                Image(systemName: "mappin")
                                    .font(.system(size: 8, weight: .semibold))
                                Text(location)
                                    .font(.system(size: 9, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial, in: Capsule())
                            .lineLimit(1)
                        }

                        Spacer()

                        if let cadrage = slot.slotData.cadrages.first {
                            Text(cadrage.displayName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                }
                .padding(Spacing.xs)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(
                    slot.isEmpty ? Palette.border : Color.clear,
                    lineWidth: Layout.Border.thin
                )
        )
        .onTapGesture { onTap() }
    }

    private var emptyContent: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                VStack(spacing: Spacing.sm) {
                    HStack(spacing: -6) {
                        ForEach(matchedPillars.prefix(3)) { pillar in
                            Text(pillar.emoji)
                                .font(.system(size: 22))
                                .frame(width: 36, height: 36)
                                .background(Palette.surface, in: Circle())
                                .overlay(Circle().strokeBorder(Palette.border, lineWidth: 0.5))
                        }

                        if matchedPillars.isEmpty {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 28))
                                .foregroundStyle(Palette.text4)
                        }
                    }

                    if !slot.slotData.cadrages.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(slot.slotData.cadrages, id: \.self) { cadrage in
                                Text(cadrage.displayName)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Palette.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Palette.accentTint, in: Capsule())
                            }
                        }
                    }

                    Text("Tap to fill")
                        .font(Typography.caption2)
                        .foregroundStyle(Palette.text4)
                }
            }
            .background(Palette.surface)
    }

    private var filledContent: some View {
        ZStack(alignment: .bottom) {
            let ids = sortedPhotoIDs
            if ids.count == 1 {
                SlotThumbnail(assetIdentifier: ids[0])
            } else {
                TabView(selection: $currentPage) {
                    ForEach(Array(ids.enumerated()), id: \.element) { index, assetID in
                        SlotThumbnail(assetIdentifier: assetID)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            if ids.count > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<ids.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.45))
                            .frame(width: 5, height: 5)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, Spacing.xs)
                .background(Palette.scrim, in: Capsule())
                .padding(.bottom, Spacing.sm + 26)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
    }
}

// MARK: - Slot Thumbnail

private struct SlotThumbnail: View {
    let assetIdentifier: String
    @State private var image: UIImage?

    private static let targetPx: CGFloat = {
        let screen = UIScreen.main.bounds.width
        let cellPt = (screen - 3 * Spacing.xs) / 2
        return ceil(cellPt * UIScreen.main.scale)
    }()

    var body: some View {
        Color.clear
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
            .task(id: assetIdentifier) {
                let fetchResult = PHAsset.fetchAssets(
                    withLocalIdentifiers: [assetIdentifier], options: nil
                )
                guard let asset = fetchResult.firstObject else { return }
                let px = Self.targetPx
                let size = CGSize(width: px, height: px)
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.resizeMode = .exact
                options.isNetworkAccessAllowed = true
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

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
