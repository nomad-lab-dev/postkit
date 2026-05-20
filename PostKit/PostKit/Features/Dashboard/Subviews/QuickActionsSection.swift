import SwiftUI

struct QuickActionsSection: View {
    let onCompose: () -> Void
    let onNewTemplate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick actions").eyebrow()

            HStack(spacing: Spacing.sm) {
                ActionTile(
                    icon: "square.and.pencil",
                    title: "Compose",
                    subtitle: "Build a post",
                    tint: Palette.accent,
                    action: onCompose
                )
                ActionTile(
                    icon: "square.grid.2x2",
                    title: "New format",
                    subtitle: "Design a template",
                    tint: Palette.purple,
                    action: onNewTemplate
                )
            }
        }
    }
}
