import SwiftUI

extension View {
    func cardStyle() -> some View { modifier(AccessibleCardModifier()) }

    func floatingStyle() -> some View {
        self
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sheet))
            .shadow(color: .black.opacity(0.12), radius: 28, y: 8)
    }

    func eyebrow() -> some View {
        self.font(Typography.caption)
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(Palette.text3)
    }

    func screenPadding() -> some View { padding(Layout.Padding.screen) }
    func cardPadding() -> some View { padding(Layout.Padding.card) }
}
