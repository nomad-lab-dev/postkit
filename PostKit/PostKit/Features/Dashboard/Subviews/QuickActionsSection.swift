// MARK: - PostKit
// QuickActionsSection.swift — Dashboard quick actions: compose a post or create a new template

import SwiftUI

struct QuickActionsSection: View {
    let onCompose: () -> Void
    let onNewTemplate: () -> Void
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick actions").eyebrow()

            if compact {
                VStack(spacing: Spacing.xs) {
                    ActionTile(
                        icon: "sparkles",
                        title: "Smart Post",
                        subtitle: "AI builds your post",
                        tint: Palette.accent,
                        compact: true,
                        action: onCompose
                    )
                    ActionTile(
                        icon: "rectangle.stack",
                        title: "From template",
                        subtitle: "Pick a saved format",
                        tint: Palette.purple,
                        compact: true,
                        action: onNewTemplate
                    )
                }
            } else {
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
}
