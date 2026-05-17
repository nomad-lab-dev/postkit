import ComposableArchitecture
@preconcurrency import Photos
import SwiftUI

struct PostEditorView: View {
    @Bindable var store: StoreOf<PostEditorFeature>

    private var columns: [GridItem] {
        let count = min(store.filledSlots.count, 3)
        return Array(
            repeating: GridItem(.flexible(), spacing: Layout.Grid.photoGrid),
            count: max(count, 2)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(store.template.name)
                        .font(Typography.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Palette.text)

                    if !store.template.about.isEmpty {
                        Text(store.template.about)
                            .font(Typography.footnote)
                            .foregroundStyle(Palette.text2)
                    }

                    HStack(spacing: Spacing.sm) {
                        Label(
                            "\(store.filledSlots.filter { !$0.isEmpty }.count)/\(store.filledSlots.count) filled",
                            systemImage: "square.grid.2x2"
                        )
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)

                        if store.totalPhotoCount > 0 {
                            Label(
                                "\(store.totalPhotoCount) photo\(store.totalPhotoCount == 1 ? "" : "s")",
                                systemImage: "photo"
                            )
                            .font(Typography.caption)
                            .foregroundStyle(Palette.text3)
                        }
                    }
                    .padding(.top, Spacing.xxs)
                }

                LazyVGrid(columns: columns, spacing: Layout.Grid.photoGrid) {
                    ForEach(store.filledSlots) { slot in
                        SlotCardView(slot: slot) {
                            store.send(.slotTapped(slot.id))
                        } onClear: {
                            store.send(.clearSlotTapped(slot.id))
                        }
                    }
                }
            }
            .screenPadding()
        }
        .background(Palette.bg)
        .navigationTitle("Post Editor")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $store.scope(state: \.slotFiller, action: \.slotFiller)) { fillerStore in
            NavigationStack {
                SlotFillerView(store: fillerStore)
            }
            .presentationDetents([.large])
        }
    }
}

// MARK: - Slot Card

private struct SlotCardView: View {
    let slot: FilledSlot
    let onTap: () -> Void
    let onClear: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                if slot.isEmpty {
                    emptyContent
                } else {
                    filledContent
                }

                slotLabel
            }
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .strokeBorder(
                        slot.isEmpty ? Palette.border : Palette.accent.opacity(0.3),
                        lineWidth: Layout.Border.thin,
                        antialiased: true
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !slot.isEmpty {
                Button(role: .destructive) {
                    onClear()
                } label: {
                    Label("Clear Slot", systemImage: "xmark.circle")
                }
            }
        }
    }

    private var emptyContent: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: Typography.IconSize.lg))
                .foregroundStyle(Palette.text4)

            Text(slot.slotData.cadrage.displayName)
                .font(Typography.caption2)
                .foregroundStyle(Palette.text3)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(slot.slotData.cadrage == .portrait ? 3/4 : 4/3, contentMode: .fit)
    }

    private var filledContent: some View {
        ZStack {
            if let firstID = slot.photoIDs.first {
                SlotThumbnail(assetIdentifier: firstID)
            }

            if slot.photoIDs.count > 1 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("+\(slot.photoIDs.count - 1)")
                            .font(Typography.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(Palette.onDark)
                            .padding(.horizontal, Spacing.xxs + 2)
                            .padding(.vertical, 2)
                            .background(Palette.scrim, in: Capsule())
                            .padding(Spacing.xxs)
                    }
                }
            }
        }
        .aspectRatio(slot.slotData.cadrage == .portrait ? 3/4 : 4/3, contentMode: .fit)
        .clipped()
    }

    private var slotLabel: some View {
        HStack(spacing: Spacing.xxs) {
            Text(slot.slotData.name)
                .font(Typography.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Palette.text2)
                .lineLimit(1)

            Spacer(minLength: 0)

            if !slot.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .font(Typography.caption2)
                    .foregroundStyle(Palette.green)
            }
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
    }
}

// MARK: - Slot Thumbnail

private struct SlotThumbnail: View {
    let assetIdentifier: String
    @State private var image: UIImage?

    private static let thumbnailPx: CGFloat = {
        let screen = UIScreen.main.bounds.width
        let cellPt = (screen - 2 * Layout.Padding.screen.leading - Layout.Grid.photoGrid) / 2
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
}
