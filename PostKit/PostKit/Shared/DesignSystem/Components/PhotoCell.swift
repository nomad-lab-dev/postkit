import SwiftUI
import UIKit

struct PhotoCell: View {
    let snapshot: ClassifiedPhotoSnapshot
    let image: UIImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let image {
                Image(uiImage: image)
                    .resizable().aspectRatio(1, contentMode: .fill)
            } else {
                Color(.systemGray5)
            }

            if let emoji = snapshot.pillarEmoji {
                Text("\(emoji) \(snapshot.pillarName ?? "")")
                    .font(Typography.caption2)
                    .foregroundStyle(.white)
                    .padding(Layout.Padding.chip)
                    .background(.black.opacity(0.55), in: Capsule())
                    .padding(Spacing.xxs)
            }

            StatusDot(status: snapshot.status)
                .padding(Spacing.xxs)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .aspectRatio(1, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: Radius.tile))
    }
}

struct StatusDot: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiate
    let status: ClassifiedPhoto.PhotoStatus

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 14, height: 14)
            .overlay(Text(symbol).font(.system(size: 8, weight: .bold)).foregroundStyle(.white))
            .overlay(differentiate ? Circle().stroke(.white, lineWidth: 1.5) : nil)
    }

    var color: Color {
        switch status {
        case .classified: Palette.green
        case .pending:    Palette.yellow
        case .rejected:   Palette.red
        }
    }

    var symbol: String {
        switch status { case .classified: "✓"; case .pending: "?"; case .rejected: "✗" }
    }
}

#Preview("Photo Cells") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Layout.Grid.photoGrid), count: 3), spacing: Layout.Grid.photoGrid) {
        PhotoCell(snapshot: ClassifiedPhotoSnapshot(
            assetLocalIdentifier: "1", pillarName: "Automotive", pillarEmoji: "🚗",
            status: .classified
        ), image: nil)
        PhotoCell(snapshot: ClassifiedPhotoSnapshot(
            assetLocalIdentifier: "2", pillarName: "Travel", pillarEmoji: "🌍",
            status: .pending
        ), image: nil)
        PhotoCell(snapshot: ClassifiedPhotoSnapshot(
            assetLocalIdentifier: "3", status: .rejected
        ), image: nil)
    }
    .padding()
}
