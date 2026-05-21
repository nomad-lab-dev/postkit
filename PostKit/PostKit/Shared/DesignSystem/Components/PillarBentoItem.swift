import Foundation
import SwiftUI
import UIKit

struct PillarSuggestion: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var emoji: String
    var count: Int
    var isSelected: Bool
}

struct PillarBentoItem: View {
    let suggestion: PillarSuggestion
    let previews: [UIImage]
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.Stack.tight) {
            Text(suggestion.emoji).font(.system(size: 28))
            Text(suggestion.name).font(Typography.subheadline)
            Text("\(suggestion.count) assets")
                .font(Typography.caption2)
                .foregroundStyle(Palette.text3)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                ForEach(previews.prefix(3), id: \.self) { img in
                    Image(uiImage: img).resizable().aspectRatio(1, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.tile))
                }
            }
            .padding(.top, Layout.Stack.tight)
        }
        .padding(Layout.Padding.card)
        .cardStyle()
        .onTapGesture(perform: onTap)
    }
}

#Preview("Pillar Bento") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Layout.Grid.bento) {
        PillarBentoItem(
            suggestion: PillarSuggestion(id: UUID(), name: "Automotive", emoji: "🚗", count: 124, isSelected: true),
            previews: [],
            onTap: {}
        )
        PillarBentoItem(
            suggestion: PillarSuggestion(id: UUID(), name: "Travel", emoji: "🌍", count: 79, isSelected: false),
            previews: [],
            onTap: {}
        )
    }
    .padding()
    .background(Palette.bg)
}
