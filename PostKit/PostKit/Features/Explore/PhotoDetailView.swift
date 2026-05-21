// MARK: - PostKit
// PhotoDetailView.swift — Full-screen photo viewer with metadata and copy action

import ComposableArchitecture
@preconcurrency import Photos
import SwiftUI

struct PhotoDetailView: View {
    let store: StoreOf<PhotoDetailFeature>

    @State private var image: UIImage?
    @State private var showCopied = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                } else {
                    ProgressView()
                        .tint(.white)
                }

                VStack {
                    Spacer()
                    metadataOverlay
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    store.send(.copyTapped)
                    withAnimation { showCopied = true }
                } label: {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .foregroundStyle(.white)
                }
            }
        }
        .task {
            await loadFullImage()
        }
        .onChange(of: showCopied) { _, show in
            if show {
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation { showCopied = false }
                }
            }
        }
    }

    private var metadataOverlay: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let pillar = store.pillar {
                HStack(spacing: Spacing.xxs) {
                    Text(pillar.emoji)
                    Text(pillar.name)
                        .fontWeight(.semibold)
                }
                .font(Typography.subheadline)
                .foregroundStyle(.white)
            }

            HStack(spacing: Spacing.md) {
                if let cadrage = store.photo.cadrage, cadrage != .any {
                    Label(cadrage.rawValue.capitalized, systemImage: "camera.viewfinder")
                }
                if let location = store.photo.location {
                    Label(location, systemImage: "mappin")
                }
                if let date = store.photo.capturedAt {
                    Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                }
            }
            .font(Typography.caption)
            .foregroundStyle(.white.opacity(0.7))

            if !store.photo.tags.isEmpty {
                FlowLayout(spacing: Spacing.xxs) {
                    ForEach(store.photo.tags.prefix(8), id: \.self) { tag in
                        Text(tag)
                            .font(Typography.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(.white.opacity(0.15), in: Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.Padding.screen)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func loadFullImage() async {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [store.photo.assetLocalIdentifier], options: nil
        )
        guard let asset = fetchResult.firstObject else { return }
        let size = CGSize(
            width: UIScreen.main.bounds.width * UIScreen.main.scale,
            height: UIScreen.main.bounds.height * UIScreen.main.scale
        )
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(
            for: asset, targetSize: size,
            contentMode: .aspectFit, options: options
        ) { result, _ in
            guard let result else { return }
            Task { @MainActor in self.image = result }
        }
    }
}
