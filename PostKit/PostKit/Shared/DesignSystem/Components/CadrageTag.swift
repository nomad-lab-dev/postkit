import SwiftUI

struct CadrageTag: View {
    let cadrage: Cadrage

    var body: some View {
        Text(cadrage.initial)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.white.opacity(0.2), in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(.white.opacity(0.3), lineWidth: 0.5)
            )
    }
}
