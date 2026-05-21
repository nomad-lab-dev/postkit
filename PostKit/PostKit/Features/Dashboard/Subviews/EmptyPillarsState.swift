// MARK: - PostKit
// EmptyPillarsState.swift — Placeholder view shown when no pillars are configured

import SwiftUI

struct EmptyPillarsState: View {
    let onAddPillar: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Palette.text3)

            Text("Set up your first topic")
                .font(Typography.headline)

            Text("Topics are the categories you want to post about.\nAutomotive, food, work, travel — your call.")
                .font(Typography.footnote)
                .foregroundStyle(Palette.text3)
                .multilineTextAlignment(.center)

            Button("Create a topic", action: onAddPillar)
                .buttonStyle(.borderedProminent)
                .tint(Palette.accent)
                .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(Layout.Padding.sheet)
        .cardStyle()
    }
}
