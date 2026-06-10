// MARK: - PostKit
// ActionTile.swift — Reusable tappable tile with icon, title, and subtitle

import SwiftUI

struct ActionTile: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let tint: Color
    var compact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if compact {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(tint)
                        .frame(width: 32, height: 32)
                        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: Radius.input))
                    Text(title)
                        .font(Typography.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.text)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .cardStyle()
            } else {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(tint)
                        .frame(width: 40, height: 40)
                        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: Radius.input))

                    Text(title)
                        .font(Typography.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.text)

                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(Layout.Padding.card)
                .cardStyle()
            }
        }
        .buttonStyle(.scaling)
        .accessibilityElement(children: .combine)
    }
}
