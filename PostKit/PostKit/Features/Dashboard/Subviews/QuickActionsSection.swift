// MARK: - PostKit
// QuickActionsSection.swift — Dashboard quick actions: compose a post or create a new template

import SwiftUI

struct QuickActionsSection: View {
    let onCompose: () -> Void
    let onNewTemplate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick actions").eyebrow()

            HStack(spacing: Spacing.sm) {
                ActionTile(
                    icon: "sparkles",
                    title: "Smart Post",
                    subtitle: "AI builds your post",
                    tint: Palette.accent,
                    action: onCompose
                )
                ActionTile(
                    icon: "rectangle.stack",
                    title: "From template",
                    subtitle: "Pick a saved format",
                    tint: Palette.purple,
                    action: onNewTemplate
                )
            }
        }
    }
}
