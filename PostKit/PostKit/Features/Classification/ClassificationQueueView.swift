// MARK: - PostKit
// ClassificationQueueView.swift — Classification queue UI: photo grid with accept-all and per-photo review

import ComposableArchitecture
@preconcurrency import Photos
import SwiftUI

struct ClassificationQueueView: View {
    @Bindable var store: StoreOf<ClassificationQueueFeature>

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Layout.Grid.photoGrid),
        count: 3
    )

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.pendingPhotos.isEmpty {
                EmptyStateView(
                    icon: "✅",
                    title: "All caught up",
                    message: "No photos waiting for review. Run a scan from Dashboard to classify more."
                )
                .padding(.horizontal, Spacing.lg)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("\(store.pendingPhotos.count) photos to review")
                                .font(Typography.footnote)
                                .foregroundStyle(Palette.text3)

                            Spacer()

                            Button {
                                Haptics.heavyTap()
                                store.send(.acceptAllTapped)
                            } label: {
                                Label("Accept All", systemImage: "checkmark.circle")
                                    .font(Typography.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.horizontal, Layout.Padding.screen.leading)

                        LazyVGrid(columns: columns, spacing: Layout.Grid.photoGrid) {
                            ForEach(
                                Array(store.pendingPhotos.enumerated()),
                                id: \.element.id
                            ) { index, photo in
                                Button {
                                    Haptics.tap()
                                    store.send(.photoTapped(index))
                                } label: {
                                    QueueThumbnailCell(photo: photo)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Layout.Padding.screen.leading)
                    }
                    .padding(.top, Spacing.sm)
                }
            }
        }
        .background(Palette.bg)
        .navigationTitle(AppStrings.Classification.queueTitle)
        .task { await store.send(.onAppear).finish() }
        .navigationDestination(
            item: $store.scope(state: \.card, action: \.card)
        ) { cardStore in
            ClassificationCardView(store: cardStore)
        }
    }
}

// MARK: - Queue Thumbnail Cell

private struct QueueThumbnailCell: View {
    let photo: ClassifiedPhotoSnapshot
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
            .overlay(alignment: .bottomLeading) {
                if let cadrage = photo.cadrage, cadrage != .any {
                    CadrageTag(cadrage: cadrage)
                        .padding(3)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.tile))
        .task(id: photo.assetLocalIdentifier) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [photo.assetLocalIdentifier], options: nil
        )
        guard let asset = fetchResult.firstObject else { return }

        let scale = UIScreen.main.scale
        let cellWidth = (UIScreen.main.bounds.width - 40 - 8) / 3
        let size = CGSize(width: cellWidth * scale, height: cellWidth * scale)
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
