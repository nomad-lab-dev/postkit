// MARK: - PostKit
// PillarsBentoSection.swift — Two-column bento grid of pillar cards with photo thumbnails

import ComposableArchitecture
import os
import Photos
import SwiftUI

struct PillarsBentoSection: View {
    let pillars: IdentifiedArrayOf<PillarSnapshot>
    let onTap: (PillarSnapshot) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Your topics").eyebrow()

            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(pillars) { pillar in
                    Button { onTap(pillar) } label: {
                        PillarBentoCard(snapshot: pillar)
                    }
                    .buttonStyle(.scaling)
                }
            }
        }
    }
}

private struct PillarBentoCard: View {
    let snapshot: PillarSnapshot

    private var displayIDs: [String] {
        let ids = snapshot.topPhotoAssetIDs
        switch ids.count {
        case 0: return []
        case 1: return Array(ids.prefix(1))
        case 2, 3: return Array(ids.prefix(2))
        default: return Array(ids.prefix(4))
        }
    }

    var body: some View {
        ZStack {
            if displayIDs.isEmpty {
                Palette.surface
            } else {
                thumbnailLayout
            }

            Color.black.opacity(0.55)

            VStack(spacing: Spacing.xxs) {
                Text(snapshot.emoji)
                    .font(.system(size: 32))

                Text(snapshot.name)
                    .font(Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("\(snapshot.photoCount) photo\(snapshot.photoCount == 1 ? "" : "s")")
                    .font(Typography.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .aspectRatio(1.2, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(Palette.border)
        )
        .animation(.easeInOut(duration: 0.3), value: displayIDs.count)
    }

    @ViewBuilder
    private var thumbnailLayout: some View {
        let ids = displayIDs
        switch ids.count {
        case 1:
            BentoThumbnail(assetIdentifier: ids[0])
        case 2:
            HStack(spacing: 2) {
                BentoThumbnail(assetIdentifier: ids[0])
                BentoThumbnail(assetIdentifier: ids[1])
            }
        default:
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    BentoThumbnail(assetIdentifier: ids[0])
                    BentoThumbnail(assetIdentifier: ids[1])
                }
                HStack(spacing: 2) {
                    BentoThumbnail(assetIdentifier: ids[2])
                    BentoThumbnail(assetIdentifier: ids[3])
                }
            }
        }
    }
}

private struct BentoThumbnail: View {
    let assetIdentifier: String
    @State private var image: UIImage?
    @State private var requestID: PHImageRequestID?

    var body: some View {
        Color(.systemGray5)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipped()
            .task(id: assetIdentifier) {
                let fetchResult = PHAsset.fetchAssets(
                    withLocalIdentifiers: [assetIdentifier], options: nil
                )
                guard let asset = fetchResult.firstObject else { return }
                let scale = UIScreen.main.scale
                let side = ceil(100 * scale)
                let options = PHImageRequestOptions()
                options.deliveryMode = .fastFormat
                options.isNetworkAccessAllowed = false
                let loaded = await loadImage(asset: asset, size: CGSize(width: side, height: side), options: options)
                guard !Task.isCancelled, let loaded else { return }
                withAnimation(.easeInOut(duration: 0.35)) {
                    self.image = loaded
                }
            }
            .onDisappear {
                if let id = requestID {
                    PHImageManager.default().cancelImageRequest(id)
                    requestID = nil
                }
            }
    }

    @MainActor
    private func loadImage(asset: PHAsset, size: CGSize, options: PHImageRequestOptions) async -> UIImage? {
        let resumed = OSAllocatedUnfairLock(initialState: false)
        return await withCheckedContinuation { continuation in
            let id = PHImageManager.default().requestImage(
                for: asset, targetSize: size,
                contentMode: .aspectFill, options: options
            ) { result, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if isDegraded { return }
                let alreadyResumed = resumed.withLock { val in
                    let was = val; val = true; return was
                }
                guard !alreadyResumed else { return }
                continuation.resume(returning: result)
            }
            self.requestID = id
        }
    }
}
