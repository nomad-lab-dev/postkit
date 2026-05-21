// MARK: - PostKit
// PillarsBentoSection.swift — Two-column bento grid of pillar cards with photo thumbnails

import ComposableArchitecture
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

    private let thumbColumns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
    ]

    var body: some View {
        ZStack {
            if snapshot.topPhotoAssetIDs.isEmpty {
                Palette.surface
            } else {
                LazyVGrid(columns: thumbColumns, spacing: 2) {
                    ForEach(snapshot.topPhotoAssetIDs.prefix(4), id: \.self) { assetID in
                        BentoThumbnail(assetIdentifier: assetID)
                    }
                }
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
        .frame(minHeight: 120)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(Palette.border)
        )
    }
}

private struct BentoThumbnail: View {
    let assetIdentifier: String
    @State private var image: UIImage?

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fill)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.systemGray5)
                }
            }
            .clipped()
            .task(id: assetIdentifier) {
                let fetchResult = PHAsset.fetchAssets(
                    withLocalIdentifiers: [assetIdentifier], options: nil
                )
                guard let asset = fetchResult.firstObject else { return }
                let options = PHImageRequestOptions()
                options.deliveryMode = .fastFormat
                options.isNetworkAccessAllowed = false
                PHImageManager.default().requestImage(
                    for: asset, targetSize: CGSize(width: 120, height: 120),
                    contentMode: .aspectFill, options: options
                ) { result, _ in
                    guard let result else { return }
                    Task { @MainActor in self.image = result }
                }
            }
    }
}
