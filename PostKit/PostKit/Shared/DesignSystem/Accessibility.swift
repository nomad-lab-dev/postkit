import SwiftUI

struct AccessibleCardModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background(
                reduceTransparency
                    ? AnyShapeStyle(Palette.surface)
                    : AnyShapeStyle(Palette.glassStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(Palette.border)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 2)
    }
}

extension View {
    func adaptiveTapTarget() -> some View {
        self
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }

    func capDynamicType(_ max: DynamicTypeSize = .accessibility3) -> some View {
        dynamicTypeSize(...max)
    }
}
