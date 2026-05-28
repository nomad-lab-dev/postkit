// MARK: - PostKit
// ActionTile.swift — Reusable tappable tile with icon, title, and subtitle

import SwiftUI

struct ActionTile: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: Radius.input))

                Spacer(minLength: Spacing.xs)

                Text(title)
                    .font(Typography.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.text)

                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .padding(Layout.Padding.card)
            .cardStyle()
        }
        .buttonStyle(.scaling)
        .accessibilityElement(children: .combine)
    }
}
