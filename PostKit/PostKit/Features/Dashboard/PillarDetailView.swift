import ComposableArchitecture
@preconcurrency import Photos
import SwiftUI

struct PillarDetailView: View {
    @Bindable var store: StoreOf<PillarDetailFeature>


    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Layout.Grid.photoGrid),
        count: 3
    )

    var body: some View {
        ScrollView {
            if store.isLoading {
                ProgressView()
                    .padding(.top, Spacing.xxl)
            } else if store.photos.isEmpty {
                EmptyStateView(
                    icon: store.pillar.emoji,
                    title: "No photos yet",
                    message: "Photos classified as \(store.pillar.name) will appear here after a scan."
                )
                .padding(.top, Spacing.xxl)
                .screenPadding()
            } else {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("\(store.photos.count) photos")
                        .font(Typography.footnote)
                        .foregroundStyle(Palette.text3)

                    LazyVGrid(columns: columns, spacing: Layout.Grid.photoGrid) {
                        ForEach(store.photos) { photo in
                            Button {
                                store.send(.photoTapped(photo))
                            } label: {
                                ThumbnailCell(assetIdentifier: photo.assetLocalIdentifier)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .screenPadding()
            }
        }
        .background(Palette.bg)
        .navigationTitle("\(store.pillar.emoji) \(store.pillar.name)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.editTapped)
                } label: {
                    Image(systemName: "pencil.circle")
                }
            }
        }
        .sheet(item: $store.scope(state: \.topicEditor, action: \.topicEditor)) { editorStore in
            NavigationStack {
                TopicEditorView(store: editorStore)
            }
        }
        .task { await store.send(.onAppear).finish() }
        .navigationDestination(
            item: $store.scope(state: \.photoDetail, action: \.photoDetail)
        ) { detailStore in
            PhotoDetailView(store: detailStore)
        }
    }
}

private struct ThumbnailCell: View {
    let assetIdentifier: String
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } else {
                Palette.placeholder
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: Radius.tile))
        .task(id: assetIdentifier) {
            image = try? await loadThumbnail()
        }
    }

    private func loadThumbnail() async throws -> UIImage {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [assetIdentifier], options: nil
        )
        guard let asset = fetchResult.firstObject else {
            throw PhotoLibraryError.assetNotFound
        }
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isNetworkAccessAllowed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 200, height: 200),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                if let image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: PhotoLibraryError.imageRequestFailed)
                }
            }
        }
    }
}
