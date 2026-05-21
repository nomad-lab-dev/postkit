// MARK: - PostKit
// ScanCompleteToast.swift — Toast notification displayed when library scan finishes

import SwiftUI

struct ScanCompleteToast: View {
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Palette.green)

            Text("Library fully classified")
                .font(Typography.subheadline.weight(.semibold))
                .foregroundStyle(Palette.text)

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(Palette.green.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, y: 4)
    }
}
